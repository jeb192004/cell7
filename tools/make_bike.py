#!/usr/bin/env python3
"""Art for the 1-4 speeder-bike chase: road, rail, Kesh's hover bike, Warden bike, wreck, barrier, the Shrike."""
import sys
from PIL import Image, ImageDraw
import os, random
A = os.path.join(os.path.dirname(__file__), '..', 'assets')
W, H = 480, 270
ROAD = 190
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# road (3 lanes: feet at y=214, 238, 262; dividers between)
g = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(g)
d.rectangle([0, ROAD, W, ROAD + 1], fill=(214, 168, 70, 255))
for y in range(ROAD + 2, H): d.line([(0, y), (W, y)], fill=lerp((98, 94, 112), (56, 52, 68), (y - ROAD) / (H - ROAD)) + (255,))
for y in (226, 250):
    for x in range(0, W, 40): d.rectangle([x + 4, y, x + 22, y + 1], fill=(226, 214, 156, 255))
random.seed(5)
for _ in range(90): d.point((random.randrange(W), random.randrange(ROAD + 3, H)), fill=(44, 40, 58, 255))
g.save(f'{A}/bike_ground.png')
# near rail + poles
n = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(n)
d.rectangle([0, 176, W, 179], fill=(120, 120, 140, 255)); d.rectangle([0, 176, W, 176], fill=(190, 190, 205, 255))
for px in range(0, W, 24): d.rectangle([px + 10, 179, px + 12, ROAD], fill=(74, 70, 92, 255))
for px in range(80, W, 160):
    d.rectangle([px, 96, px + 2, 176], fill=(60, 56, 78, 255)); d.rectangle([px, 96, px + 14, 98], fill=(60, 56, 78, 255))
    d.rectangle([px + 10, 99, px + 15, 102], fill=(255, 214, 130, 255))
n.save(f'{A}/bike_near.png')

def rider(src, box, flip=False):
    im = Image.open(f'{A}/{src}').convert('RGBA').crop(box)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im

LEAN, ARM_X, ARM_Y = 24, 32, 28
def wheel(d, cx, cy, glow):
    d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(26, 22, 36, 255))          # tyre
    d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=glow + (255,))              # glowing rim
    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(40, 36, 54, 255))
    d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=(190, 190, 205, 255))       # hub
    d.line([(cx, cy - 4), (cx, cy + 4)], fill=(70, 66, 90, 255)); d.line([(cx - 4, cy), (cx + 4, cy)], fill=(70, 66, 90, 255))

def bike(body, trim, glow, rider_img, rider_xy, legs, boots, cloak=None, glove=(60, 50, 40, 255)):
    """Side-on hover bike facing right, 64x64 -- shaded parts, glowing hover pods under it."""
    sys.path.insert(0, 'tools')
    from pxshade import Canvas
    c = Canvas(64, 64)
    body, trim = tuple(body[:3]), tuple(trim[:3])
    g = glow
    metal, dark = (96, 92, 118), (44, 40, 60)
    c.part([(6, 44), (26, 44), (26, 52), (6, 50)], metal, bulge=3)                       # exhaust pipe
    c.rect(0, 45, 5, 49, g); c.rect(0, 46, 3, 48, (255, 255, 235))
    c.part([(21, 42), (41, 42), (41, 53), (21, 53)], metal, bulge=4)                      # engine
    c.rect(24, 47, 38, 48, dark); c.rect(24, 50, 31, 51, trim)
    for cx in (16, 50):   # hover pods
        c.part([(cx - 9, 52), (cx + 9, 52), (cx + 7, 57), (cx - 7, 57)], dark, bulge=3)
        c.rect(cx - 6, 57, cx + 6, 58, g); c.rect(cx - 3, 57, cx + 3, 57, (235, 255, 255))
    c.part([(6, 38), (18, 38), (16, 45), (4, 45)], body, bulge=3)                         # tail
    c.part([(14, 38), (29, 38), (29, 41), (14, 41)], dark, bulge=1.5)                     # seat
    c.part([(27, 33), (41, 33), (44, 38), (41, 43), (27, 43)], body, bulge=5)             # tank
    c.rect(28, 34, 40, 35, trim)
    c.part([(44, 29), (47, 29), (55, 50), (49, 52)], metal, bulge=2)                      # fork
    c.part([(42, 40), (57, 40), (63, 47), (44, 51)], body, bulge=4); c.rect(44, 40, 56, 41, trim)   # front fairing
    c.part([(38, 26), (46, 26), (46, 30), (38, 30)], dark, bulge=1.5)                     # bars
    c.part([(49, 33), (54, 33), (54, 38), (49, 38)], (255, 236, 170), bulge=2); c.rect(54, 34, 56, 36, (255, 250, 225))
    if cloak is not None: c.part([(12, 36), (26, 36), (20, 50), (6, 48)], tuple(cloak[:3]), bulge=3)
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0)); gd = ImageDraw.Draw(im)
    for cx in (16, 50):   # soft down-glow under each pod
        gd.ellipse([cx - 10, 57, cx + 10, 64], fill=tuple(g) + (55,)); gd.ellipse([cx - 6, 58, cx + 6, 64], fill=tuple(g) + (110,))
    im.alpha_composite(Image.fromarray(c.img, 'RGBA')); d = ImageDraw.Draw(im)
    big = Image.new('RGBA', (64, 64), (0, 0, 0, 0)); big.alpha_composite(rider_img, rider_xy)
    big = big.rotate(-LEAN, center=(24, 40), resample=Image.NEAREST)
    im.alpha_composite(big)
    d.line([(21, 39), (35, 42)], fill=legs, width=5); d.line([(35, 42), (32, 51)], fill=legs, width=4)
    d.rectangle([28, 50, 37, 53], fill=boots)
    arm = (150, 112, 74, 255) if cloak is None else (70, 66, 90, 255)
    d.line([(ARM_X, ARM_Y), (42, 29)], fill=arm, width=3); d.rectangle([41, 27, 45, 30], fill=glove)
    return im

def np_blend(region, col, a):
    import numpy as np
    out = region.copy()
    m = out[..., 3] == 0
    out[m] = (*col, a)
    return out

k = rider('kesh_idle_0.png', (0, 0, 48, 36))
bike((78, 150, 196, 255), (214, 160, 66, 255), (90, 220, 255), k, (-4, 11), (74, 96, 128, 255), (112, 70, 52, 255)).save(f'{A}/kesh_bike.png')
wd = rider('warden_ready.png', (0, 0, 44, 40))
bike((72, 66, 104, 255), (190, 50, 54, 255), (255, 120, 70), wd, (-2, 8), (40, 38, 56, 255), (24, 22, 34, 255), cloak=(54, 52, 70, 255)).transpose(Image.FLIP_LEFT_RIGHT).save(f'{A}/warden_bike.png')

# wreck (burnt-out hovercar) 48x24
w = Image.new('RGBA', (48, 26), (0, 0, 0, 0)); d = ImageDraw.Draw(w)
d.polygon([(2, 22), (6, 12), (18, 8), (34, 8), (44, 14), (46, 22)], fill=(58, 48, 62, 255))
d.polygon([(8, 12), (18, 8), (24, 8), (22, 14), (8, 14)], fill=(30, 40, 56, 255))
d.rectangle([2, 20, 46, 23], fill=(36, 30, 44, 255)); d.rectangle([30, 10, 40, 13], fill=(110, 60, 48, 255))
for x, y in ((10, 6), (14, 3), (12, 0), (30, 4)): d.rectangle([x, y, x + 2, y + 2], fill=(120, 110, 120, 140))   # smoke
w.save(f'{A}/road_wreck.png')
# barrier 30x22 (concrete w/ hazard stripes)
b = Image.new('RGBA', (30, 22), (0, 0, 0, 0)); d = ImageDraw.Draw(b)
d.polygon([(1, 21), (4, 6), (26, 6), (29, 21)], fill=(150, 146, 160, 255)); d.rectangle([4, 6, 26, 8], fill=(190, 186, 198, 255))
for x in range(4, 26, 8): d.polygon([(x, 12), (x + 4, 12), (x + 8, 18), (x + 4, 18)], fill=(214, 168, 70, 255))
d.rectangle([1, 19, 29, 21], fill=(90, 86, 104, 255))
b.save(f'{A}/road_barrier.png')

# Shrike: talon-winged interceptor (faces left) 72x40 -- angular dark hull, two long forward-raking talons, red visor slit
s = Image.new('RGBA', (72, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
hull, hi, dark, red = (70, 66, 84, 255), (120, 116, 138, 255), (42, 38, 56, 255), (255, 70, 50, 255)
d.polygon([(46, 17), (68, 5), (71, 7), (56, 19)], fill=dark)                      # rear upper fin
d.polygon([(46, 23), (68, 35), (71, 33), (56, 21)], fill=dark)                    # rear lower fin
d.polygon([(52, 14), (30, 10), (6, 2), (1, 3), (22, 16), (40, 19)], fill=dark)    # upper talon sweeping forward
d.polygon([(52, 26), (30, 30), (6, 38), (1, 37), (22, 24), (40, 21)], fill=dark)  # lower talon
d.line([(6, 3), (40, 12)], fill=hi); d.line([(6, 37), (40, 28)], fill=hi)         # talon edges
d.polygon([(10, 20), (22, 14), (46, 13), (60, 17), (60, 23), (46, 27), (22, 26)], fill=hull)   # armoured body
d.polygon([(22, 14), (46, 13), (48, 16), (24, 17)], fill=hi)                     # top plate
d.polygon([(10, 20), (22, 17), (24, 20), (12, 21)], fill=dark)                   # prow
d.rectangle([14, 19, 26, 21], fill=red); d.rectangle([16, 20, 22, 20], fill=(255, 190, 150, 255))   # visor slit
d.rectangle([30, 18, 44, 22], fill=dark); d.rectangle([34, 19, 40, 21], fill=(180, 60, 50, 255))    # canopy / engine band
d.rectangle([2, 19, 10, 21], fill=(90, 90, 100, 255)); d.rectangle([0, 20, 2, 20], fill=(255, 150, 80, 255))   # nose gun
d.rectangle([58, 16, 66, 24], fill=(255, 110, 50, 220)); d.rectangle([62, 18, 71, 22], fill=(255, 220, 140, 255))   # thruster
s.save(f'{A}/shrike.png')
print('ok')
