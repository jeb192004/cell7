import sys; sys.path.insert(0, 'tools')
from hf import *
# ---- Vagabond-9, straight down, nose right. ~96x58
def vagabond():
    W, H = 118, 72; cy = 36; dx = 14
    s = HF(W, H, light=(-0.5, -0.7, 0.55))
    T = lambda pts: [(x + dx, y) for x, y in pts]
    Mi = lambda pts: [(x + dx, 2 * cy - y) for x, y in pts]
    both = lambda pts, col, hgt, bev, mat=0: (s.add(T(pts), col, hgt, bev, mat), s.add(Mi(pts), col, hgt, bev, mat))
    steel = (128, 128, 136); dsteel = (88, 88, 100); rust = (150, 104, 70); rust2 = (120, 84, 62); teal = (96, 214, 226)
    # engines
    for sgn in (-1, 1):
        y0 = cy + sgn * 15
        s.add(T([(0, y0 - 6), (24, y0 - 6), (24, y0 + 6), (0, y0 + 6)]), (70, 72, 88), 4, 5, 1)
        s.add(T([(-3, y0 - 5), (2, y0 - 5), (2, y0 + 5), (-3, y0 + 5)]), (40, 40, 56), 3, 2, 1)
        for i, (x1, col) in enumerate(((2, (90, 150, 255)), (8, (140, 200, 255)), (13, (200, 235, 255)))):    # flame core
            s.rect(dx - 3 - x1, y0 - 3 + i, dx - 3, y0 + 3 - i, col, emit=True)
        s.rect(dx - 5, y0 - 1, dx - 3, y0 + 1, (255, 255, 255), emit=True)
    # cargo pods
    both([(26, cy - 9), (34, cy - 26), (58, cy - 26), (62, cy - 9)], rust, 4, 4, 0)
    both([(30, cy - 14), (36, cy - 23), (54, cy - 23), (56, cy - 14)], rust2, 1.5, 2, 0)
    # fuselage
    s.add(T([(8, cy - 11), (60, cy - 12), (74, cy - 7), (74, cy + 7), (60, cy + 12), (8, cy + 11)]), steel, 6, 7, 1)
    s.add(T([(12, cy - 8), (56, cy - 9), (64, cy - 5), (64, cy + 5), (56, cy + 9), (12, cy + 8)]), (104, 108, 122), 1.5, 3, 1)
    # hammerhead crossbar
    both([(64, cy - 14), (74, cy - 30), (88, cy - 28), (90, cy - 14)], dsteel, 5, 4, 1)
    s.add(T([(64, cy - 14), (90, cy - 14), (90, cy + 14), (64, cy + 14)]), dsteel, 5, 5, 1)
    s.add(T([(70, cy - 12), (86, cy - 12), (86, cy + 12), (70, cy + 12)]), (100, 100, 114), 1.5, 3, 1)
    # cockpit glass: two canopies
    s.add(T([(76, cy - 10), (91, cy - 7), (91, cy - 1), (76, cy - 2)]), teal, 4, 3, 2)
    s.add(T([(76, cy + 2), (91, cy + 1), (91, cy + 7), (76, cy + 10)]), (80, 190, 205), 4, 3, 2)
    s.line((83 + dx, cy - 9), (84 + dx, cy - 2), (40, 70, 90)); s.line((83 + dx, cy + 3), (84 + dx, cy + 9), (40, 70, 90))
    # offset turret
    s.ellipse(dx + 40, cy - 5, 10, 10, (70, 72, 86), 2, 3, 1); s.ellipse(dx + 40, cy - 5, 7, 7, (150, 154, 164), 4, 7, 1)
    s.add(T([(46, cy - 7), (62, cy - 7), (62, cy - 4), (46, cy - 4)]), (80, 82, 96), 3, 1.4, 1)
    s.rect(dx + 63, cy - 7, dx + 64, cy - 5, (255, 200, 110), emit=True)
    # radar dish
    s.ellipse(dx + 24, cy + 6, 8, 8, (70, 72, 86), 2, 3, 1); s.ellipse(dx + 24, cy + 6, 6, 6, (176, 180, 190), 3, 5, 1); s.rect(dx + 23, cy + 5, dx + 25, cy + 7, (120, 230, 255), emit=True)
    # wingtip guns
    s.rect(dx + 86, cy - 29, dx + 93, cy - 27, (96, 96, 108)); s.rect(dx + 86, cy + 27, dx + 93, cy + 29, (96, 96, 108))
    s.rect(dx + 94, cy - 28, dx + 94, cy - 28, (255, 200, 110), emit=True); s.rect(dx + 94, cy + 28, dx + 94, cy + 28, (255, 200, 110), emit=True)
    # panel lines, rivets, vents, lights
    for p0, p1 in (((12, cy), (66, cy)), ((36, cy - 11), (36, cy + 11)), ((58, cy - 25), (58, cy - 9)), ((58, cy + 25), (58, cy + 9)), ((70, cy - 13), (70, cy + 13))):
        s.line((p0[0] + dx, p0[1]), (p1[0] + dx, p1[1]))
    for x in range(30, 56, 5): s.paint(dx + x, cy - 24, (200, 170, 140)); s.paint(dx + x, cy + 24, (200, 170, 140))
    for x in range(14, 30, 3): s.rect(dx + x, cy + 9, dx + x, cy + 10, (30, 30, 40))      # vents
    s.rect(dx + 8, cy - 10, dx + 9, cy - 9, (255, 80, 60), emit=True); s.rect(dx + 8, cy + 9, dx + 9, cy + 10, (90, 255, 140), emit=True)
    s.rect(dx + 66, cy - 13, dx + 67, cy - 12, (120, 230, 255), emit=True); s.rect(dx + 66, cy + 12, dx + 67, cy + 13, (120, 230, 255), emit=True)
    for x in range(44, 56, 4): s.rect(dx + x, cy + 4, dx + x + 1, cy + 5, (230, 170, 60))   # hazard marks
    return s.render(spec=0.3, dith=0.4)

im = vagabond(); im.save('/tmp/vag_snes.png')
sheet = Image.new('RGBA', (140, 86), (14, 12, 36, 255)); sheet.alpha_composite(im, (6, 6))
sheet.resize((sheet.width * 6, sheet.height * 6), 0).save('/tmp/vag_prev.png')
print(im.size)

def aegis():
    W, H = 92, 86; cy = 43
    s = HF(W, H, light=(0.5, -0.7, 0.55))
    metal = (100, 106, 126); dark = (60, 64, 84); pod = (78, 84, 108); red = (205, 44, 40)
    # swept rear wings (top shorter, bottom longer) with a raised spine
    s.add([(54, cy - 12), (72, cy - 36), (82, cy - 36), (68, cy - 7)], dark, 3, 3, 1)
    s.add([(58, cy - 12), (72, cy - 32), (78, cy - 32), (66, cy - 9)], metal, 1.5, 1.5, 1)
    s.add([(54, cy + 12), (74, cy + 40), (86, cy + 40), (70, cy + 7)], metal, 3, 3, 1)
    s.add([(58, cy + 12), (74, cy + 36), (82, cy + 36), (68, cy + 9)], (130, 136, 156), 1.5, 1.5, 1)
    # forward pincer arms (curve forward, tips glow)
    s.add([(36, cy - 11), (22, cy - 26), (6, cy - 36), (4, cy - 31), (18, cy - 21), (32, cy - 6)], metal, 3, 3, 1)
    s.add([(30, cy - 12), (18, cy - 24), (8, cy - 32), (8, cy - 29), (20, cy - 20), (32, cy - 9)], (126, 132, 152), 1.2, 1.4, 1)
    s.add([(36, cy + 11), (20, cy + 30), (4, cy + 40), (2, cy + 35), (16, cy + 24), (32, cy + 6)], dark, 3, 3, 1)
    s.add([(30, cy + 12), (18, cy + 28), (8, cy + 36), (8, cy + 33), (20, cy + 24), (32, cy + 9)], (88, 94, 116), 1.2, 1.4, 1)
    s.rect(3, cy - 36, 8, cy - 34, (255, 150, 100), emit=True); s.rect(1, cy + 38, 6, cy + 40, (255, 150, 100), emit=True)
    s.rect(2, cy - 35, 3, cy - 35, (255, 240, 220), emit=True); s.rect(0, cy + 39, 1, cy + 39, (255, 240, 220), emit=True)
    # faceted mask-pod
    s.add([(26, cy), (38, cy - 17), (60, cy - 17), (72, cy), (60, cy + 17), (38, cy + 17)], pod, 6, 8, 1)
    s.add([(34, cy), (42, cy - 12), (58, cy - 12), (66, cy), (58, cy + 12), (42, cy + 12)], (92, 98, 124), 2, 4, 1)
    s.add([(38, cy - 17), (60, cy - 17), (54, cy - 9), (42, cy - 9)], (126, 134, 160), 1.5, 2, 1)
    # red visor
    s.add([(26, cy - 1), (38, cy - 8), (42, cy - 8), (42, cy + 8), (38, cy + 8), (26, cy + 1)], (120, 20, 24), 1.5, 2, 2)
    s.add([(28, cy - 1), (38, cy - 6), (40, cy - 5), (40, cy + 5), (38, cy + 6), (28, cy + 1)], red, 0.5, 1, 2)
    s.rect(30, cy - 1, 39, cy + 1, (255, 120, 90), emit=True); s.rect(32, cy, 37, cy, (255, 235, 210), emit=True)
    # panel lines & lights
    for p0, p1 in (((40, cy), (66, cy)), ((50, cy - 17), (50, cy + 17)), ((60, cy - 17), (66, cy - 8)), ((60, cy + 17), (66, cy + 8))):
        s.line(p0, p1)
    s.rect(46, cy - 14, 47, cy - 13, (255, 80, 60), emit=True); s.rect(46, cy + 13, 47, cy + 14, (255, 80, 60), emit=True)
    # thruster + flame
    s.add([(70, cy - 6), (78, cy - 6), (78, cy + 6), (70, cy + 6)], (56, 56, 72), 3, 2, 1)
    for i, (L, col) in enumerate(((16, (255, 110, 50)), (12, (255, 170, 80)), (7, (255, 230, 160)))):
        s.rect(78, cy - 4 + i, 78 + L, cy + 4 - i, col, emit=True)
    return s.render(spec=0.3, dith=0.4)

a = aegis(); a.save('/tmp/aeg_snes.png')
sheet = Image.new('RGBA', (240, 96), (14, 12, 36, 255))
sheet.alpha_composite(im, (4, 10)); sheet.alpha_composite(a, (136, 5))
sheet.resize((sheet.width * 5, sheet.height * 5), 0).save('/tmp/snes_prev.png'); print(a.size)
