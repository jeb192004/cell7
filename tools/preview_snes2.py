import sys; sys.path.insert(0, 'tools')
from hf import *
import random

def plates(s, mask, x0, y0, x1, y1, palette, rng, minw=9, maxw=20, minh=7, maxh=15, height=1.8, bevel=1.1, mat=1):
    """cover a region with riveted hull plates: irregular grid, each plate its own tint and slight height."""
    y = y0
    while y < y1:
        hh = rng.randint(minh, maxh); x = x0 + rng.randint(-6, 0)
        while x < x1:
            ww = rng.randint(minw, maxw)
            m = np.zeros_like(mask); m[max(y, 0):y + hh, max(x, 0):x + ww] = True; m &= mask
            if m.sum() > 6:
                col = rng.choice(palette)
                s.add(m, col, height + rng.uniform(-0.4, 0.5), bevel, mat)
                if m.sum() > 40 and rng.random() < 0.7:        # rivets
                    ys, xs = np.nonzero(m); cx0, cy0 = xs.min() + 1, ys.min() + 1
                    for (px, py) in ((cx0, cy0), (xs.max() - 1, cy0)):
                        if m[py, px]: s.paint(px, py, tuple(min(255, c + 45) for c in col))
            x += ww
        y += hh

def vagabond(seed=4):
    rng = random.Random(seed)
    W, H = 132, 76; cy = 38; dx = 10
    s = HF(W, H, light=(-0.5, -0.7, 0.55))
    grey = [(128, 124, 120), (98, 96, 100), (112, 110, 112)]
    tan = [(150, 118, 86), (112, 84, 62), (134, 104, 76)]
    slate = [(96, 100, 110), (86, 90, 102)]
    # --- engines: two nacelles, staggered
    for (y0, back) in ((cy - 22, 0), (cy + 14, 5)):
        x_back = dx + back
        s.add([(x_back, y0), (x_back + 34, y0 - 1), (x_back + 34, y0 + 15), (x_back, y0 + 16)], (74, 76, 92), 6, 7, 1)
        for k in range(4): s.line((x_back + 8 + k * 6, y0 + 1), (x_back + 8 + k * 6, y0 + 15))
        s.add([(x_back - 5, y0 + 2), (x_back + 2, y0 + 1), (x_back + 2, y0 + 15), (x_back - 5, y0 + 14)], (36, 38, 52), 3, 2, 1)
        s.rect(x_back - 4, y0 + 5, x_back, y0 + 10, (90, 150, 255), emit=True); s.rect(x_back - 3, y0 + 7, x_back, y0 + 8, (230, 250, 255), emit=True)
        for i, (L, col) in enumerate(((10, (80, 140, 250)), (7, (140, 200, 255)), (4, (220, 245, 255)))):
            s.rect(x_back - 5 - L, y0 + 6 + i, x_back - 5, y0 + 9 - i, col, emit=True)
    # --- landing flap + ramp
    s.add([(dx + 30, cy + 26), (dx + 56, cy + 26), (dx + 52, cy + 36), (dx + 28, cy + 35)], (130, 98, 70), 3, 3, 1)
    s.add([(dx + 70, cy + 22), (dx + 98, cy + 22), (dx + 96, cy + 30), (dx + 72, cy + 30)], (118, 88, 64), 2.5, 2, 1)
    # --- hull
    hull = s._mask([(dx + 14, cy - 17), (dx + 70, cy - 22), (dx + 98, cy - 20), (dx + 112, cy - 10), (dx + 116, cy), (dx + 112, cy + 12), (dx + 98, cy + 22), (dx + 70, cy + 25), (dx + 14, cy + 20), (dx + 6, cy + 10), (dx + 6, cy - 8)])
    s.add(hull, (110, 106, 104), 4, 6, 1)
    plates(s, hull, dx, cy - 24, dx + 118, cy + 28, grey * 3 + tan + slate, rng)
    # darker belly band + nose plating tint
    nose = hull.copy(); nose[:, :dx + 84] = False
    plates(s, nose, dx + 84, cy - 24, dx + 118, cy + 28, tan + grey, rng, 8, 14, 7, 12)
    # --- cockpit glass (offset to the top) + small side window
    s.add([(dx + 88, cy - 16), (dx + 108, cy - 11), (dx + 110, cy - 3), (dx + 90, cy - 5)], (100, 214, 226), 3, 3, 2)
    s.line((dx + 96, cy - 15), (dx + 98, cy - 5), (40, 72, 92)); s.line((dx + 103, cy - 13), (dx + 104, cy - 4), (40, 72, 92))
    s.add([(dx + 90, cy + 3), (dx + 104, cy + 5), (dx + 104, cy + 10), (dx + 90, cy + 9)], (70, 160, 180), 2, 2, 2)
    s.rect(dx + 91, cy - 15, dx + 93, cy - 14, (235, 255, 255), emit=True)
    # --- turret (offset, top-left) + barrel
    s.ellipse(dx + 34, cy - 17, 11, 9, (62, 64, 78), 2, 3, 1); s.ellipse(dx + 34, cy - 17, 8, 7, (140, 144, 156), 4, 7, 1)
    s.add([(dx + 40, cy - 19), (dx + 62, cy - 19), (dx + 62, cy - 15), (dx + 40, cy - 15)], (74, 76, 90), 3, 1.5, 1)
    s.rect(dx + 63, cy - 18, dx + 64, cy - 16, (255, 200, 110), emit=True)
    # --- radar dish on the lower side, on an arm
    s.add([(dx + 44, cy + 12), (dx + 56, cy + 12), (dx + 56, cy + 24), (dx + 44, cy + 24)], (90, 90, 104), 2, 1.5, 1)
    s.ellipse(dx + 52, cy + 26, 11, 8, (60, 62, 76), 2, 3, 1); s.ellipse(dx + 52, cy + 26, 9, 6, (170, 174, 184), 3, 5, 1)
    s.rect(dx + 51, cy + 25, dx + 53, cy + 27, (120, 232, 255), emit=True)
    # --- vents, lights, grime
    for k in range(5): s.rect(dx + 20 + k * 3, cy + 8, dx + 20 + k * 3, cy + 15, (26, 26, 36))
    s.rect(dx + 8, cy - 12, dx + 9, cy - 11, (255, 80, 60), emit=True); s.rect(dx + 8, cy + 11, dx + 9, cy + 12, (90, 255, 140), emit=True)
    for x in range(dx + 76, dx + 112, 7): s.rect(x, cy + 17, x + 1, cy + 18, (120, 230, 255), emit=True)
    for _ in range(40):
        x, y = rng.randint(dx + 8, dx + 112), rng.randint(cy - 20, cy + 22)
        if hull[y, x]: s.paint(x, y, (70, 58, 52))
    return s.render(spec=0.3, dith=0.35, ao_k=1.5, shadow_k=0.55)

def aegis():
    W, H = 112, 60; cy = 30
    s = HF(W, H, light=(-0.4, -0.75, 0.55))
    metal = (60, 62, 80); dark = (40, 42, 56); red = (255, 60, 44)
    # delta wings: long blades converging to one tip on the right
    top = [(34, cy - 8), (52, cy - 26), (62, cy - 28), (108, cy - 2), (66, cy - 9)]
    bot = [(34, cy + 8), (52, cy + 26), (62, cy + 28), (108, cy + 2), (66, cy + 9)]
    for blade, sgn in ((top, -1), (bot, 1)):
        s.add(blade, metal, 3, 4, 1)
        inner = [(x if i != 3 else x - 4, cy + (y - cy) * 0.55) for i, (x, y) in enumerate(blade)]
        s.add(inner, (84, 88, 108), 1.5, 2, 1)
        s.line((58, cy + sgn * 24), (100, cy + sgn * 2), None)
        for k in range(5):       # glowing red slits along the blades
            t = 0.2 + k * 0.14
            x = int(60 + t * 36); y = int(cy + sgn * (22 - t * 20))
            s.rect(x, y, x + 3, y, red, emit=True)
    # central spike
    s.add([(56, cy - 3), (104, cy), (56, cy + 3)], (50, 52, 70), 2, 1.5, 1)
    # armoured pod
    pod = [(14, cy - 14), (46, cy - 17), (66, cy - 11), (72, cy), (66, cy + 11), (46, cy + 17), (14, cy + 14), (6, cy + 7), (6, cy - 7)]
    s.add(pod, (54, 58, 76), 5, 6, 1)
    s.add([(18, cy - 10), (46, cy - 12), (62, cy - 7), (66, cy), (62, cy + 7), (46, cy + 12), (18, cy + 10), (12, cy + 5), (12, cy - 5)], (72, 76, 98), 1.5, 3, 1)
    s.add([(26, cy - 6), (52, cy - 6), (58, cy - 2), (58, cy + 2), (52, cy + 6), (26, cy + 6)], (150, 44, 44), 1.2, 2, 2)    # red canopy
    s.add([(30, cy - 3), (50, cy - 3), (54, cy - 1), (54, cy + 1), (50, cy + 3), (30, cy + 3)], (210, 60, 54), 0.6, 1, 2)
    s.rect(34, cy - 1, 48, cy + 1, (255, 150, 120), emit=True)
    # glowing rim vents on the pod
    s.rect(8, cy - 8, 9, cy + 8, red, emit=True); s.rect(10, cy - 6, 10, cy + 6, (255, 140, 110), emit=True)
    for x0, y0, x1, y1 in ((20, cy - 14, 44, cy - 16), (20, cy + 14, 44, cy + 16)): s.line((x0, y0), (x1, y1), None)
    s.line((36, cy - 12), (36, cy + 12), None); s.line((60, cy - 9), (60, cy + 9), None)
    # thruster glow at the rear (left)
    for i, (L, col) in enumerate(((10, (255, 80, 50)), (7, (255, 150, 80)), (4, (255, 225, 160)))):
        s.rect(5 - L, cy - 4 + i, 5, cy + 4 - i, col, emit=True)
    img = s.render(spec=0.4, dith=0.35, ao_k=1.3, shadow_k=0.5)
    return img.transpose(Image.FLIP_LEFT_RIGHT)    # in game he flies right -> left

v = vagabond(); a = aegis()
v.save('/tmp/vag2.png'); a.save('/tmp/aeg2.png'); print(v.size, a.size)
sheet = Image.new('RGBA', (270, 90), (14, 12, 36, 255)); sheet.alpha_composite(v, (4, 6)); sheet.alpha_composite(a, (150, 14))
sheet.resize((sheet.width * 4, sheet.height * 4), 0).save('/tmp/snes_prev2.png')
