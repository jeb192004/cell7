"""Vagabond-9, side view (nose right). python3 tools/make_vagabond_side.py  -> assets/vagabond.png"""
import sys, random; sys.path.insert(0, 'tools')
from hf import *

def vagabond(seed=21):
    rng = random.Random(seed)
    W, H = 128, 76
    s = HF(W, H, light=(-0.55, -0.7, 0.55), ss=4)
    grey = [(124, 120, 116), (100, 98, 102), (114, 112, 114)]
    tan = [(150, 118, 86), (116, 88, 64), (136, 106, 78)]
    brown = [(122, 88, 62), (104, 76, 56)]
    # ---- twin engine nacelles (stacked), ribbed, dark nozzles with blue glow
    for y0 in (9, 27):
        s.add([(2, y0), (36, y0 - 1), (36, y0 + 14), (2, y0 + 15)], (74, 76, 92), 5, 6, 1)
        for k in range(5): s.line((9 + k * 5, y0 + 1), (9 + k * 5, y0 + 14))
        s.add([(0, y0 + 1), (6, y0), (6, y0 + 14), (0, y0 + 15)], (34, 36, 50), 3, 2, 1)
        s.rect(1, y0 + 4, 2, y0 + 10, (90, 150, 255), emit=True)
        s.add([(26, y0 + 2), (38, y0 + 2), (38, y0 + 13), (26, y0 + 13)], (110, 82, 60), 2, 2, 1)        # brown collar
    # ---- big swept wing under the belly (root along the hull, tip sweeping back and down)
    s.add([(82, 42), (88, 46), (74, 66), (50, 73), (20, 72), (32, 58), (40, 44)], (116, 86, 62), 3, 3, 1)
    s.add([(78, 46), (82, 48), (70, 62), (50, 68), (30, 67), (40, 57), (46, 47)], (146, 110, 78), 1.5, 2, 1)
    s.line((46, 47), (30, 67), (70, 52, 40)); s.line((64, 47), (56, 66), (70, 52, 40))
    for p in ((44, 52), (62, 52), (58, 62), (38, 64)): s.paint(p[0], p[1], (210, 180, 140))
    s.rect(22, 70, 26, 71, (255, 120, 70), emit=True)           # wingtip light
    # ---- hull
    hull = s._mask([(26, 12), (56, 8), (84, 8), (102, 10), (114, 16), (120, 26), (120, 36), (114, 43), (104, 48), (84, 50), (28, 48), (24, 36)])
    s.add(hull, (112, 108, 104), 4, 6, 1)
    plates(s, hull, 22, 6, 122, 52, grey * 3 + tan * 2 + brown, rng, 8, 17, 7, 13)
    # nose: warmer tan plating, rounded
    nose = hull.copy(); nose[:, :92] = False
    plates(s, nose, 92, 6, 122, 52, tan * 2 + grey, rng, 7, 13, 6, 11, height=2.0)
    # ---- cockpit: angled windshield with mullions
    s.add([(98, 11), (112, 13), (119, 24), (102, 23)], (26, 34, 44), 2, 2, 1)
    s.add([(100, 12), (111, 14), (117, 22), (103, 22)], (100, 214, 226), 2, 2, 2)
    s.line((105, 12), (108, 22), (40, 74, 94)); s.line((110, 14), (112, 22), (40, 74, 94)); s.line((101, 17), (116, 18), (40, 74, 94))
    s.rect(101, 13, 103, 13, (235, 255, 255), emit=True)
    # ---- dorsal turret + barrel
    s.ellipse(58, 8, 12, 6, (62, 64, 78), 2, 3, 1); s.ellipse(58, 6, 9, 5, (142, 146, 158), 4, 5, 1)
    s.add([(64, 3), (84, 3), (84, 7), (64, 7)], (76, 78, 92), 3, 1.5, 1)
    s.rect(85, 4, 86, 6, (255, 200, 110), emit=True)
    # ---- radar dish on an arm, orange cable
    s.add([(54, 30), (58, 30), (58, 38), (54, 38)], (86, 88, 102), 2, 1, 1)
    s.ellipse(52, 33, 8, 10, (60, 62, 76), 2, 3, 1); s.ellipse(52, 33, 6, 8, (176, 180, 190), 3, 5, 1)
    s.rect(51, 32, 53, 34, (120, 232, 255), emit=True)
    for k in range(10): s.paint(60 + k, 24 + (k // 3), (214, 120, 60))
    # ---- vent / service panel (lower right)
    s.add([(78, 30), (100, 30), (100, 44), (78, 44)], (50, 52, 64), 1.5, 1.5, 1)
    for k in range(4): s.line((80, 32 + k * 3), (98, 32 + k * 3), (24, 26, 34))
    for k in range(3): s.line((82 + k * 6, 31), (82 + k * 6, 43), (24, 26, 34))
    s.rect(96, 41, 98, 42, (120, 230, 255), emit=True)
    # ---- panel lines, scratch, lights, grime
    for p0, p1 in (((40, 12), (40, 46)), ((70, 10), (70, 28)), ((90, 14), (92, 46))): s.line(p0, p1)
    s.line((68, 14), (78, 20), (96, 130, 170))
    s.rect(30, 14, 31, 15, (255, 80, 60), emit=True); s.rect(30, 44, 31, 45, (90, 255, 140), emit=True)
    for x in range(104, 118, 4): s.rect(x, 33, x + 1, 34, (120, 230, 255), emit=True)
    for _ in range(60):
        x, y = rng.randint(26, 118), rng.randint(10, 48)
        if s.inmask(hull, x, y): s.paint(x, y, (70, 58, 52))
    return s.render(spec=0.35, ao_k=1.5, shadow_k=0.55)

if __name__ == '__main__':
    v = vagabond(); v.save('assets/vagabond.png'); print(v.size)
    pv = Image.new('RGBA', (v.width + 20, v.height + 20), (14, 12, 36, 255)); pv.alpha_composite(v, (10, 10))
    pv.resize((pv.width * 6, pv.height * 6), 0).save('/tmp/vag_side.png')
