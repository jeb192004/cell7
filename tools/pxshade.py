"""Tiny shading toolkit for SNES-style sprites: polygon parts -> lit, dithered colour ramps + selective outline."""
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, gaussian_filter

SH, LI = 0.62, 0.55
DITH = 0.9
BAYER = np.array([[0, 2], [3, 1]]) / 4.0

def hexc(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))

def ramp(base, n=5):
    """dark->light ramp from a base colour: shadows shift cool/purple, lights shift warm."""
    b = np.array(base, float); out = []
    for i in range(n):
        f = i / (n - 1)
        if f < 0.5:
            k = (0.5 - f) / 0.5
            c = b * (1 - SH * k) + np.array([22, 14, 52]) * (SH * 0.45) * k
        else:
            k = (f - 0.5) / 0.5
            c = b + (np.array([255, 244, 214]) - b) * LI * k
        out.append(tuple(int(max(0, min(255, v))) for v in c))
    return out

class Canvas:
    def __init__(self, w, h, light=(-0.55, -0.8)):
        self.w, self.h = w, h; self.img = np.zeros((h, w, 4), np.uint8)
        l = np.array(light, float); self.light = l / np.linalg.norm(l)
        self.sil = np.zeros((h, w), bool)

    def mask(self, pts):
        m = Image.new('L', (self.w, self.h), 0); ImageDraw.Draw(m).polygon(pts, fill=255)
        return np.array(m) > 127

    def part(self, pts, base, bulge=3.0, n=5, outline=True, glow=None, rim=0.0):
        m = self.mask(pts) if not isinstance(pts, np.ndarray) else pts
        self.fill(m, base, bulge, n, outline, rim)
        return m

    def fill(self, m, base, bulge=3.0, n=5, outline=True, rim=0.0):
        rp = ramp(base, n)
        dist = distance_transform_edt(m)
        hgt = np.minimum(dist, bulge) / bulge            # 0 at edge .. 1 inside: a soft pillow
        hgt = gaussian_filter(hgt, 0.7)
        gy, gx = np.gradient(hgt)
        # surface tilts toward the light where the height rises away from it
        lit = -(gx * self.light[0] + gy * self.light[1]) * bulge * 1.6
        v = 0.46 + lit * 0.9 + (hgt - 0.5) * 0.12
        ys, xs = np.nonzero(m)
        for y, x in zip(ys, xs):
            val = v[y, x] * (n - 1) + (BAYER[y % 2, x % 2] - 0.5) * 0.9
            idx = int(max(0, min(n - 1, round(val))))
            self.img[y, x] = rp[idx] + (255,)
        # selective outline: darkest ramp colour, a touch lighter on the lit (top/left) edges
        edge = m & ~(distance_transform_edt(m) > 1.0)
        for y, x in zip(*np.nonzero(edge)):
            c = rp[0]
            if self.light[0] * -1 > 0 and (y > 0 and not m[y-1, x] or x > 0 and not m[y, x-1]):
                c = rp[1]
            self.img[y, x] = c + (255,)
        self.sil |= m

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h: self.img[y, x] = tuple(c) + (255,)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): self.px(x, y, c)

    def line(self, p0, p1, c):
        im = Image.fromarray(self.img); d = ImageDraw.Draw(im); d.line([p0, p1], fill=tuple(c) + (255,)); self.img = np.array(im)

    def outer_outline(self, c=(16, 10, 28)):
        """1px dark halo around the whole silhouette so sprites pop on any background."""
        a = self.img[..., 3] > 0
        grown = np.zeros_like(a)
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            grown |= np.roll(np.roll(a, dy, 0), dx, 1)
        ring = grown & ~a
        self.img[ring] = tuple(c) + (255,)

    def save(self, path): Image.fromarray(self.img, 'RGBA').save(path)


MINR = 5
def snesify(path_in, path_out, bulge=2.6, n=5, light=(-0.55, -0.8), halo=True, strength=1.0):
    """Upgrade an existing flat sprite: shade every colour region as a lit, rounded surface (cool shadows / warm lights),
    dither the shade steps, and add a dark halo. Dark line colours and tiny details are kept as drawn."""
    from scipy.ndimage import label
    src = np.array(Image.open(path_in).convert('RGBA'))
    h, w = src.shape[:2]
    cv = Canvas(w, h, light)
    cv.img = src.copy()
    opaque = src[..., 3] > 0
    cols = {}
    for y, x in zip(*np.nonzero(opaque)):
        cols.setdefault(tuple(src[y, x, :3]), []).append((y, x))
    for col, _ in cols.items():
        lum = 0.3 * col[0] + 0.59 * col[1] + 0.11 * col[2]
        if lum < 38: continue                       # keep outline / dark detail colours
        m = np.all(src[..., :3] == np.array(col), axis=2) & opaque
        lab, k = label(m)
        for i in range(1, k + 1):
            mi = lab == i
            if mi.sum() < MINR: continue
            rp = ramp(col, n)
            dist = distance_transform_edt(mi)
            b = min(bulge, max(1.2, dist.max()))
            hgt = gaussian_filter(np.minimum(dist, b) / b, 0.6)
            gy, gx = np.gradient(hgt)
            lit = -(gx * cv.light[0] + gy * cv.light[1]) * b * 1.6
            v = 0.5 + (lit * 0.9 + (hgt - 0.5) * 0.14) * strength
            for y, x in zip(*np.nonzero(mi)):
                val = v[y, x] * (n - 1) + (BAYER[y % 2, x % 2] - 0.5) * 0.85
                cv.img[y, x] = rp[int(max(0, min(n - 1, round(val))))] + (255,)
    if halo:
        pad = np.zeros((h + 2, w + 2, 4), np.uint8); pad[1:-1, 1:-1] = cv.img
        cv2 = Canvas(w + 2, h + 2, light); cv2.img = pad; cv2.outer_outline()
        out = cv2.img
    else:
        out = cv.img
    Image.fromarray(out, 'RGBA').save(path_out)
