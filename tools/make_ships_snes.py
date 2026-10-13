"""SNES-style ships for 1-5 (straight-down view): hero 'Freighter' (Vagabond-9) and the Warden Interceptor.
Built nose-up like the concept art, then rotated: hero faces right, interceptor faces left.  python3 tools/make_ships_snes.py"""
import sys, random; sys.path.insert(0, 'tools')
from hf import *

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

def hero(flames=False, seed=11):
    rng = random.Random(seed)
    W, H = 58, 86; cx = 29
    s = HF(W, H, light=(-0.6, 0.55, 0.55))        # rotated later -> light ends up top-left
    grey = [(124, 120, 116), (100, 98, 102), (112, 110, 112)]
    tan = [(150, 118, 86), (114, 86, 62), (134, 104, 76)]
    # engine block + nozzles
    s.add([(14, 62), (44, 62), (44, 80), (14, 80)], (70, 72, 88), 4, 5, 1)
    for nx in (21, 37):
        s.add([(nx - 6, 66), (nx + 6, 66), (nx + 7, 83), (nx - 7, 83)], (60, 62, 78), 5, 6, 1)
        s.add([(nx - 5, 80), (nx + 5, 80), (nx + 5, 85), (nx - 5, 85)], (30, 32, 44), 3, 2, 1)
        s.rect(nx - 3, 83, nx + 3, 84, (80, 140, 255), emit=True)
        for k in range(3): s.line((nx - 6, 70 + k * 4), (nx + 6, 70 + k * 4))
    # wings with tip thrusters
    for sgn in (-1, 1):
        px = lambda x: cx + sgn * x
        s.add([(px(14), 42), (px(28), 46), (px(28), 64), (px(14), 62)], (116, 84, 62), 3, 3, 1)
        s.add([(px(16), 46), (px(26), 49), (px(26), 60), (px(16), 58)], (136, 100, 72), 1.5, 2, 1)
        s.rect(px(28) - (1 if sgn > 0 else 0), 54, px(28) - (1 if sgn > 0 else 0), 62, (150, 150, 160))
        s.rect(px(27) - (1 if sgn > 0 else 0), 63, px(27) - (1 if sgn > 0 else 0), 64, (100, 170, 255), emit=True)
    # hull: narrow nose, wider midship
    hull = s._mask([(20, 6), (24, 1), (34, 1), (38, 6), (40, 22), (44, 34), (46, 44), (46, 66), (12, 66), (12, 44), (14, 34), (18, 22)])
    s.add(hull, (112, 108, 104), 4, 5, 1)
    plates(s, hull, 10, 0, 48, 70, grey * 2 + tan * 2, rng)
    # cockpit
    s.add([(23, 6), (35, 6), (37, 20), (21, 20)], (30, 36, 48), 2, 2, 1)
    s.add([(24, 7), (34, 7), (35, 18), (23, 18)], (96, 210, 224), 2, 2, 2)
    s.line((29, 7), (29, 18), (40, 70, 92)); s.line((24, 12), (34, 12), (40, 70, 92))
    s.rect(25, 8, 26, 9, (235, 255, 255), emit=True)
    # shoulder radar dishes
    for dxs in (-17, 17):
        s.ellipse(cx + dxs, 46, 8, 8, (58, 60, 74), 2, 3, 1); s.ellipse(cx + dxs, 46, 6, 6, (172, 176, 186), 3, 5, 1)
        s.rect(cx + dxs - 1, 45, cx + dxs + 1, 47, (120, 232, 255), emit=True)
    # central gun turret
    s.ellipse(cx, 44, 6, 8, (62, 64, 78), 2, 3, 1); s.ellipse(cx, 44, 4, 6, (140, 144, 156), 4, 5, 1)
    s.add([(cx - 1, 28), (cx + 2, 28), (cx + 2, 40), (cx - 1, 40)], (74, 76, 90), 3, 1.2, 1)
    s.rect(cx - 1, 27, cx + 1, 27, (255, 200, 110), emit=True)
    # trim lights
    s.rect(14, 36, 15, 37, (255, 80, 60), emit=True); s.rect(43, 36, 44, 37, (90, 255, 140), emit=True)
    for _ in range(25):
        x, y = rng.randint(14, 44), rng.randint(6, 64)
        if hull[y, x]: s.paint(x, y, (70, 58, 52))
    img = s.render(spec=0.3, dith=0.35, ao_k=1.5, shadow_k=0.55)
    return img.transpose(Image.ROTATE_270)              # nose up -> nose right

def interceptor(f=1.0, seed=3):
    W, H = int(60 * f) + 2, int(86 * f) + 2
    cx = W // 2
    s = HF(W, H, light=(0.6, -0.55, 0.55))        # rotated later -> top-left
    P = lambda pts: [(round(cx + x * f), round(y * f)) for x, y in pts]
    R = lambda x0, y0, x1, y1, col, e=True: s.rect(round(cx + x0 * f), round(y0 * f), max(round(cx + x1 * f), round(cx + x0 * f)), max(round(y1 * f), round(y0 * f)), col, e)
    metal = (64, 66, 84); dark = (40, 42, 56); mid = (84, 88, 108); red = (255, 60, 44)
    # delta blades from the needle tip down to the wings
    s.add(P([(-4, 8), (4, 8), (26, 58), (-26, 58)]), (46, 48, 64), 2, 3 * f, 1)               # dark interior plate
    for k in range(3): s.line(P([(-5 + k * 5, 14)])[0], P([(-14 + k * 14, 56)])[0], None)
    for sgn in (-1, 1):
        s.add(P([(sgn * 2, 4), (sgn * 7, 10), (sgn * 30, 62), (sgn * 24, 58)]), metal, 3, 3 * f, 1)
        s.add(P([(sgn * 3, 12), (sgn * 6, 14), (sgn * 24, 56), (sgn * 22, 54)]), mid, 1.5, 1.5 * f, 1)
        for k in range(4):
            y = 24 + k * 8; x = 8 + k * 4.5
            R(sgn * x - 1, y, sgn * x + 1, y, red)
    s.add(P([(-2, 0), (2, 0), (7, 54), (-7, 54)]), (60, 62, 82), 2.5, 2 * f, 1)             # centre needle
    # lower wings / side armour
    for sgn in (-1, 1):
        s.add(P([(sgn * 12, 54), (sgn * 28, 56), (sgn * 30, 68), (sgn * 12, 74)]), (70, 72, 92), 3, 3 * f, 1)
        s.add(P([(sgn * 14, 58), (sgn * 26, 60), (sgn * 27, 66), (sgn * 14, 70)]), (90, 94, 114), 1.2, 1.5 * f, 1)
        R(sgn * 22 - 1, 60, sgn * 22 + 1, 60, red); R(sgn * 20 - 1, 64, sgn * 20 + 1, 64, red)
    # pod
    s.add(P([(-12, 52), (12, 52), (14, 60), (14, 76), (10, 82), (-10, 82), (-14, 76), (-14, 60)]), (54, 58, 76), 5, 5 * f, 1)
    s.add(P([(-9, 56), (9, 56), (11, 62), (11, 76), (-11, 76), (-11, 62)]), (74, 78, 100), 1.5, 3 * f, 1)
    s.add(P([(-6, 58), (6, 58), (7, 62), (7, 72), (-7, 72), (-7, 62)]), (150, 44, 44), 1.2, 2 * f, 2)     # red canopy
    s.add(P([(-4, 60), (4, 60), (5, 64), (5, 70), (-5, 70), (-5, 64)]), (214, 62, 54), 0.6, 1 * f, 2)
    R(-2, 62, 2, 69, (255, 150, 120))
    R(-13, 62, -12, 74, red); R(12, 62, 13, 74, red)
    s.line(P([(-10, 56)])[0], P([(10, 56)])[0], None); s.line(P([(-14, 66)])[0], P([(14, 66)])[0], None)
    # three engine flames (tapered)
    for i, nx in enumerate((-7, 0, 7)):
        Ln = round((12 if i != 1 else 17) * f); y0 = round(82 * f)
        for j in range(Ln):
            w = max(0, round((3 - 3 * j / Ln) * max(f, 0.8)))
            col = (255, 235, 180) if j < Ln * 0.25 else ((255, 160, 80) if j < Ln * 0.6 else (255, 80, 50))
            s.rect(round(cx + nx * f) - w, min(H - 1, y0 + j), round(cx + nx * f) + w, min(H - 1, y0 + j), col, emit=True)
    img = s.render(spec=0.4, dith=0.35, ao_k=1.3, shadow_k=0.5)
    return img.transpose(Image.ROTATE_90)                # nose up -> nose left

A = "assets"
h = hero(); h.save(f'{A}/hero.png')
i1 = interceptor(0.72); i1.save(f'{A}/interceptor.png')
i2 = interceptor(1.5); i2.save(f'{A}/interceptor_big.png')
print(h.size, i1.size, i2.size)
sheet = Image.new('RGBA', (330, 120), (14, 12, 36, 255))
sheet.alpha_composite(h, (4, 30)); sheet.alpha_composite(i1, (100, 40)); sheet.alpha_composite(i2, (180, 10))
sheet.resize((sheet.width * 3, sheet.height * 3), 0).save('/tmp/ships_final.png')

def side_shrike(f=0.8):
    """Side view, nose left -- the Warden interceptor for the highway chase (1-4)."""
    W, H = int(146 * f), int(44 * f)
    s = HF(W, H, light=(-0.55, -0.7, 0.55))
    P = lambda pts: [(round(x * f), round(y * f)) for x, y in pts]
    R = lambda x0, y0, x1, y1, col, e=True: s.rect(round(x0 * f), round(y0 * f), max(round(x1 * f), round(x0 * f)), max(round(y1 * f), round(y0 * f)), col, e)
    L = lambda a, b, col=None: s.line((round(a[0] * f), round(a[1] * f)), (round(b[0] * f), round(b[1] * f)), col)
    dark = (44, 46, 60); mid = (66, 70, 90); red = (255, 60, 44)
    # long lower blade-wing + fuel cells between it and the hull
    s.add(P([(0, 24), (60, 28), (100, 33), (96, 38), (44, 35), (0, 25)]), (56, 60, 76), 2.5, 2 * f, 1)
    s.add(P([(6, 25), (60, 29), (92, 34), (88, 36), (44, 34), (6, 26)]), (84, 90, 110), 1.2, 1.2 * f, 1)
    for k in range(3):
        s.add(P([(40 + k * 7, 27), (45 + k * 7, 27), (45 + k * 7, 31), (40 + k * 7, 31)]), (120, 126, 140), 2, 1.5 * f, 1)
    L((30, 27), (74, 29))
    # main hull: needle nose, faceted cockpit wedge
    s.add(P([(0, 22), (34, 15), (48, 8), (76, 6), (76, 30), (44, 28), (12, 24)]), dark, 4, 4 * f, 1)
    s.add(P([(14, 21), (36, 17), (48, 11), (72, 10), (72, 26), (44, 25), (16, 23)]), mid, 1.4, 2 * f, 1)
    s.add(P([(36, 14), (48, 9), (62, 9), (68, 16), (44, 19)]), (88, 94, 118), 2, 2 * f, 2)           # canopy facet
    L((38, 15), (48, 10), (255, 90, 70)); L((48, 10), (62, 10), (255, 90, 70)); L((62, 10), (67, 16), (255, 90, 70))
    R(40, 16, 52, 16, red); R(44, 17, 50, 17, (255, 140, 110))
    L((6, 22), (36, 18)); L((46, 24), (74, 24))
    R(16, 22, 26, 22, red)
    # thruster assembly: block with red vent bands and a ribbed exhaust
    s.add(P([(76, 4), (106, 4), (110, 10), (110, 30), (76, 32)]), (50, 52, 68), 5, 4 * f, 1)
    s.add(P([(80, 8), (104, 8), (106, 12), (106, 26), (80, 28)]), (68, 72, 92), 1.5, 2 * f, 1)
    for k in range(4): L((82 + k * 5, 8), (82 + k * 5, 28))
    R(82, 10, 98, 12, red); R(84, 11, 96, 11, (255, 150, 120)); R(82, 18, 100, 20, red); R(84, 19, 98, 19, (255, 150, 120))
    s.add(P([(104, 10), (112, 10), (112, 26), (104, 26)]), (28, 30, 42), 3, 2 * f, 1)
    s.add(P([(80, 30), (100, 30), (94, 38), (82, 38)]), dark, 2, 2 * f, 1)                              # lower fin
    # exhaust flame (static): one tapering plume, white core -> orange -> red
    Ln = int(26 * f) + 6; x0 = round(112 * f); cyf = round(19 * f)
    for j in range(Ln):
        half = max(1, round((8.0 * f) * (1 - j / Ln)) + 1)
        for dy in range(-half, half + 1):
            t = abs(dy) / max(half, 1) * 0.6 + j / Ln * 0.8
            col = (255, 240, 200) if t < 0.22 else ((255, 170, 90) if t < 0.5 else ((255, 90, 55) if t < 0.8 else (200, 40, 40)))
            s.paint(min(W - 1, x0 + j), cyf + dy, col, emit=True)
    return s.render(spec=0.4, dith=0.35, ao_k=1.3, shadow_k=0.5)

sh = side_shrike(); sh.save(f'{A}/shrike.png'); print('shrike', sh.size)
pv = Image.new('RGBA', (sh.width + 20, sh.height + 20), (60, 50, 80, 255)); pv.alpha_composite(sh, (10, 10))
pv.resize((pv.width * 6, pv.height * 6), 0).save('/tmp/shrike_new.png')
