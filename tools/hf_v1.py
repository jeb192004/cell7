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
    def __init__(s, w, h, light=(-0.55, -0.65, 0.55)):
        s.w, s.h = w, h
        s.z = np.zeros((h, w)); s.col = np.zeros((h, w, 3)); s.alpha = np.zeros((h, w), bool)
        s.mat = np.zeros((h, w), int)          # 0 matte, 1 metal (specular), 2 glass (strong specular)
        s.emit = np.zeros((h, w), bool)        # self-lit pixels (lights, flames)
        s.groove = np.zeros((h, w), float)
        L = np.array(light, float); s.L = L / np.linalg.norm(L)

    def _mask(s, pts):
        im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in pts], fill=255)
        return np.array(im) > 127

    def add(s, pts, color, height=2.0, bevel=2.0, mat=0):
        m = s._mask(pts) if not isinstance(pts, np.ndarray) else pts
        if not m.any(): return m
        d = distance_transform_edt(m); p = np.clip(d / max(bevel, 0.01), 0, 1); p = p * p * (3 - 2 * p)
        s.z[m] += height * p[m]; s.col[m] = color; s.alpha[m] = True; s.mat[m] = mat; s.emit[m] = False
        return m

    def ellipse(s, cx, cy, rx, ry, color, height=2.0, bevel=None, mat=0):
        im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
        return s.add(np.array(im) > 127, color, height, bevel if bevel else min(rx, ry), mat)

    def paint(s, x, y, color, emit=False):
        if 0 <= x < s.w and 0 <= y < s.h:
            s.col[y, x] = color; s.alpha[y, x] = True; s.emit[y, x] = emit

    def rect(s, x0, y0, x1, y1, color, emit=False):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.paint(x, y, color, emit)

    def line(s, p0, p1, color=None, groove=1.0):
        """a panel line: carves the surface and darkens it."""
        im = Image.new('L', (s.w, s.h), 0); ImageDraw.Draw(im).line([p0, p1], fill=255)
        m = (np.array(im) > 0) & s.alpha
        s.groove[m] = groove
        if color is not None: s.col[m] = color

    def render(s, n=8, spec=0.55, dith=0.55, ao_k=0.9, shadow_k=0.35, outline=(14, 9, 26)):
        zs = gaussian_filter(s.z, 0.55) - gaussian_filter(s.groove, 0.5) * 0.8
        gy, gx = np.gradient(zs)
        k = 1.25
        nx, ny, nz = -gx * k, -gy * k, np.ones_like(zs)
        ln = np.sqrt(nx * nx + ny * ny + nz * nz); nx /= ln; ny /= ln; nz /= ln
        L = s.L
        lam = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
        hv = L + np.array([0, 0, 1.0]); hv /= np.linalg.norm(hv)
        sp = np.clip(nx * hv[0] + ny * hv[1] + nz * hv[2], 0, 1)
        specm = np.where(s.mat == 2, 1.0, np.where(s.mat == 1, 0.55, 0.0))
        spec_v = (sp ** 22) * specm * spec * 2.0 + (sp ** 6) * specm * 0.12
        # cast shadow: march toward the light across the height field
        shadow = np.zeros_like(zs)
        for step in range(1, 9):
            sh = ndshift(zs, (L[1] * step * 1.0, L[0] * step * 1.0), order=1, mode='nearest')   # sample the surface toward the light
            shadow = np.maximum(shadow, np.clip((sh - zs - step * 0.55) * 0.9, 0, 1))
        ao = np.clip((gaussian_filter(s.z, 3.0) - s.z) * 0.22, 0, 1)
        val = 0.30 + 0.62 * lam - shadow_k * shadow - ao_k * ao * 0.6 + spec_v
        out = np.zeros((s.h, s.w, 4), np.uint8)
        ramps = {}
        for y, x in zip(*np.nonzero(s.alpha)):
            c = tuple(int(v) for v in s.col[y, x])
            if s.emit[y, x]:
                out[y, x] = (*c, 255); continue
            if c not in ramps: ramps[c] = make_ramp(c, n)
            v = val[y, x] * (n - 1) + BAYER4[y % 4, x % 4] * dith
            if s.groove[y, x] > 0: v -= 1.6 * s.groove[y, x]
            out[y, x] = (*ramps[c][int(max(0, min(n - 1, round(v))))].astype(np.uint8), 255)
        # silhouette halo
        a = out[..., 3] > 0
        pa = np.pad(a, 1); grown = np.zeros_like(pa)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)): grown |= np.roll(np.roll(pa, dy, 0), dx, 1)
        ring = (grown & ~pa)[1:-1, 1:-1]
        out[ring] = (*outline, 255)
        return Image.fromarray(out, 'RGBA')


def plates(s, mask, x0, y0, x1, y1, palette, rng, minw=7, maxw=15, minh=6, maxh=12, height=1.6, bevel=1.0, mat=1):
    y = y0
    while y < y1:
        hh = rng.randint(minh, maxh); x = x0 + rng.randint(-5, 0)
        while x < x1:
            ww = rng.randint(minw, maxw)
            m = np.zeros_like(mask); m[max(y, 0):y + hh, max(x, 0):x + ww] = True; m &= mask
            if m.sum() > 5:
                col = rng.choice(palette); s.add(m, col, height + rng.uniform(-0.3, 0.4), bevel, mat)
                if m.sum() > 30 and rng.random() < 0.6:
                    ys, xs = np.nonzero(m)
                    for (px, py) in ((xs.min() + 1, ys.min() + 1), (xs.max() - 1, ys.min() + 1)):
                        if m[py, px]: s.paint(px, py, tuple(min(255, c + 45) for c in col))
            x += ww
        y += hh

