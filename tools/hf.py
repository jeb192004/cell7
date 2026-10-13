"""Height-field sprite renderer for the SNES look: build a sprite from stacked, bevelled parts (a tiny 'pre-rendered' model),
then light it (diffuse + specular + cast shadow + ambient occlusion) and quantise to hue-shifted colour ramps with light dithering."""
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, gaussian_filter, shift as ndshift

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.5

def make_ramp(base, n=8, warm=(255, 240, 205), cool=(24, 14, 56)):
    b = np.array(base, float); out = []
    for i in range(n):
        f = i / (n - 1)
        if f < 0.64:
            k = (0.64 - f) / 0.64
            c = b * (1 - 0.70 * k) + np.array(cool) * 0.30 * k
        else:
            k = (f - 0.64) / 0.36
            c = b + (np.array(warm) - b) * 0.55 * k
        out.append(np.clip(c, 0, 255))
    return np.array(out)

class HF:
    """ss = supersample factor. All coordinates you pass are in final-sprite pixels; internally everything is ss times finer,
    and render() box-filters back down -> smooth, anti-aliased, pre-rendered (Donkey-Kong-Country-ish) shading instead of chunky dither."""
    def __init__(s, w, h, light=(-0.55, -0.65, 0.55), ss=1):
        s.ss = ss; s.W, s.H = w, h
        s.w, s.h = w * ss, h * ss
        s.z = np.zeros((s.h, s.w)); s.col = np.zeros((s.h, s.w, 3)); s.alpha = np.zeros((s.h, s.w), bool)
        s.mat = np.zeros((s.h, s.w), int)
        s.emit = np.zeros((s.h, s.w), bool)
        s.groove = np.zeros((s.h, s.w), float)
        L = np.array(light, float); s.L = L / np.linalg.norm(L)

    def _mask(s, pts):
        k = s.ss
        im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).polygon([(float(x) * k, float(y) * k) for x, y in pts], fill=255)
        return np.array(im) > 127

    def inmask(s, m, x, y):
        return bool(m[min(int(y * s.ss), s.h - 1), min(int(x * s.ss), s.w - 1)])

    def add(s, pts, color, height=2.0, bevel=2.0, mat=0):
        k = s.ss
        m = s._mask(pts) if not isinstance(pts, np.ndarray) else pts
        if not m.any(): return m
        d = distance_transform_edt(m); p = np.clip(d / max(bevel * k, 0.01), 0, 1); p = p * p * (3 - 2 * p)
        s.z[m] += height * k * p[m]; s.col[m] = color; s.alpha[m] = True; s.mat[m] = mat; s.emit[m] = False
        return m

    def ellipse(s, cx, cy, rx, ry, color, height=2.0, bevel=None, mat=0):
        k = s.ss
        im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).ellipse([(cx - rx) * k, (cy - ry) * k, (cx + rx) * k, (cy + ry) * k], fill=255)
        return s.add(np.array(im) > 127, color, height, bevel if bevel else min(rx, ry), mat)

    def paint(s, x, y, color, emit=False):
        k = s.ss
        if 0 <= x < s.W and 0 <= y < s.H:
            sl = (slice(int(y * k), int((y + 1) * k)), slice(int(x * k), int((x + 1) * k)))
            s.col[sl] = color; s.alpha[sl] = True; s.emit[sl] = emit
            if emit: s.z[sl] = s.z[sl]

    def rect(s, x0, y0, x1, y1, color, emit=False):
        k = s.ss
        sl = (slice(max(0, int(y0 * k)), min(s.h, int((y1 + 1) * k))), slice(max(0, int(x0 * k)), min(s.w, int((x1 + 1) * k))))
        s.col[sl] = color; s.alpha[sl] = True; s.emit[sl] = emit

    def line(s, p0, p1, color=None, groove=1.0):
        k = s.ss
        im = Image.new('L', (s.w, s.h), 0)
        ImageDraw.Draw(im).line([(p0[0] * k, p0[1] * k), (p1[0] * k, p1[1] * k)], fill=255, width=max(1, int(round(k * 0.9))))
        m = (np.array(im) > 0) & s.alpha
        s.groove[m] = groove
        if color is not None: s.col[m] = color

    def render(s, n=8, spec=0.55, dith=0.55, ao_k=0.9, shadow_k=0.35, outline=(14, 9, 26)):
        k = s.ss
        smooth = k > 1
        zs = gaussian_filter(s.z, 0.55 * k) - gaussian_filter(s.groove, 0.5 * k) * 0.8 * k
        gy, gx = np.gradient(zs)
        kk = 1.25 / k * k
        nx, ny, nz = -gx * 1.25, -gy * 1.25, np.ones_like(zs)
        ln = np.sqrt(nx * nx + ny * ny + nz * nz); nx /= ln; ny /= ln; nz /= ln
        L = s.L
        lam = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
        hv = L + np.array([0, 0, 1.0]); hv /= np.linalg.norm(hv)
        sp = np.clip(nx * hv[0] + ny * hv[1] + nz * hv[2], 0, 1)
        specm = np.where(s.mat == 2, 1.0, np.where(s.mat == 1, 0.55, 0.0))
        spec_v = (sp ** 22) * specm * spec * 2.0 + (sp ** 6) * specm * 0.12
        shadow = np.zeros_like(zs)
        for step in range(1, 9):
            sh = ndshift(zs, (L[1] * step * k, L[0] * step * k), order=1, mode='nearest')
            shadow = np.maximum(shadow, np.clip((sh - zs - step * 0.55 * k) * 0.9 / k, 0, 1))
        ao = np.clip((gaussian_filter(s.z, 3.0 * k) - s.z) * 0.22 / k, 0, 1)
        val = 0.30 + 0.62 * lam - shadow_k * shadow - ao_k * ao * 0.6 + spec_v
        out = np.zeros((s.h, s.w, 4), np.float32)
        nr = 32 if smooth else n
        ramps = {}
        ys, xs = np.nonzero(s.alpha)
        for y, x in zip(ys, xs):
            c = tuple(int(v) for v in s.col[y, x])
            if s.emit[y, x]:
                out[y, x] = (*c, 255); continue
            key = (c, nr)
            if key not in ramps: ramps[key] = make_ramp(c, nr)
            v = val[y, x] * (nr - 1)
            if not smooth: v += BAYER4[y % 4, x % 4] * dith
            if s.groove[y, x] > 0: v -= 1.6 * s.groove[y, x] * (nr / 8.0)
            v = max(0.0, min(nr - 1.0, v))
            i0 = int(v); i1 = min(nr - 1, i0 + 1); f = v - i0
            r = ramps[key]
            col = r[i0] * (1 - f) + r[i1] * f if smooth else r[int(round(v))]
            out[y, x] = (*col, 255)
        # dark halo around the silhouette, 1 final pixel wide
        a = out[..., 3] > 0
        ring = (distance_transform_edt(~a) <= k * 0.95) & ~a
        out[ring] = (*outline, 255)
        if k > 1:   # box-filter down, alpha-weighted
            al = out[..., 3] / 255.0
            pre = out[..., :3] * al[..., None]
            pre = pre.reshape(s.H, k, s.W, k, 3).mean(axis=(1, 3)); al2 = al.reshape(s.H, k, s.W, k).mean(axis=(1, 3))
            rgb = np.where(al2[..., None] > 0, pre / np.maximum(al2[..., None], 1e-6), 0)
            fin = np.dstack([rgb, al2 * 255]).clip(0, 255).astype(np.uint8)
            return Image.fromarray(fin, 'RGBA')
        return Image.fromarray(out.astype(np.uint8), 'RGBA')


def plates(s, mask, x0, y0, x1, y1, palette, rng, minw=7, maxw=15, minh=6, maxh=12, height=1.6, bevel=1.0, mat=1):
    """cover a region with riveted hull plates: irregular grid, each plate its own tint and slight height (coords in sprite pixels)."""
    k = s.ss
    y = y0
    while y < y1:
        hh = rng.randint(minh, maxh); x = x0 + rng.randint(-5, 0)
        while x < x1:
            ww = rng.randint(minw, maxw)
            m = np.zeros_like(mask); m[max(y, 0) * k:(y + hh) * k, max(x, 0) * k:(x + ww) * k] = True; m &= mask
            if m.sum() > 5 * k * k:
                col = rng.choice(palette); s.add(m, col, height + rng.uniform(-0.3, 0.4), bevel, mat)
                if m.sum() > 30 * k * k and rng.random() < 0.6:
                    ys, xs = np.nonzero(m)
                    for (px, py) in ((xs.min() // k + 1, ys.min() // k + 1), (xs.max() // k - 1, ys.min() // k + 1)):
                        if s.inmask(m, px, py): s.paint(px, py, tuple(min(255, c + 45) for c in col))
            x += ww
        y += hh
