#!/usr/bin/env python3
"""Highway art for level 1-2: dusk sky, Sovereignty skyline, overpass, light poles, asphalt, cargo containers."""
from PIL import Image, ImageDraw
import os, random
A = os.path.join(os.path.dirname(__file__), '..', 'assets')
W, H, GY = 480, 270, 222
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# sky: banded dusk gradient + dim low sun
sky = Image.new('RGBA', (W, H)); d = ImageDraw.Draw(sky)
stops = [(0, (34, 30, 66)), (110, (96, 54, 110)), (180, (206, 108, 98)), (230, (244, 170, 110)), (270, (244, 170, 110))]
for y in range(H):
    for (y0, c0), (y1, c1) in zip(stops, stops[1:]):
        if y0 <= y < y1:
            t = (y - y0) / (y1 - y0); t = round(t * 12) / 12   # banding
            d.line([(0, y), (W, y)], fill=lerp(c0, c1, t) + (255,))
for r, c in ((40, (240, 150, 110)), (30, (250, 190, 130)), (22, (255, 226, 170))):
    d.ellipse([340 - r, 168 - r, 340 + r, 168 + r], fill=c + (255,))
sky.save(f'{A}/bg_hw_sky.png')

# far: skyline of tall spires (tileable: nothing crosses the edges)
random.seed(7)
far = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(far)
col = (92, 66, 112, 255); lit = (255, 190, 100, 255)
x = 6
while x < W - 40:
    w = random.choice([18, 24, 30, 16]); h = random.choice([60, 90, 120, 74, 100])
    top = 214 - h
    d.rectangle([x, top, x + w, H], fill=col)
    if random.random() < 0.5: d.rectangle([x + w // 2 - 1, top - 14, x + w // 2, top], fill=col)   # antenna
    for wy in range(top + 6, 210, 9):
        for wx in range(x + 3, x + w - 3, 6):
            if random.random() < 0.18: d.rectangle([wx, wy, wx + 1, wy + 2], fill=lit)
    x += w + random.choice([2, 6, 10])
d.rectangle([0, 214, W, H], fill=col)
far.save(f'{A}/bg_hw_far.png')

# mid: elevated deck with pillars (tileable: pillars every 120px, deck full width)
mid = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(mid)
deck = (70, 52, 90, 255); dk = (50, 36, 68, 255); hi = (150, 110, 120, 255)
d.rectangle([0, 150, W, 164], fill=deck); d.rectangle([0, 150, W, 151], fill=hi); d.rectangle([0, 163, W, 164], fill=dk)
for px in range(30, W, 120):
    d.rectangle([px, 164, px + 14, GY], fill=deck); d.rectangle([px + 12, 164, px + 14, GY], fill=dk)
    d.rectangle([px - 4, 164, px + 18, 170], fill=dk)
for gx in range(0, W, 8): d.rectangle([gx, 144, gx, 150], fill=dk)       # railing on the deck
d.rectangle([0, 144, W, 145], fill=dk)
mid.save(f'{A}/bg_hw_mid.png')

# near: guard rail + light poles (poles every 160px)
near = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(near)
rail = (120, 120, 140, 255); post = (74, 70, 92, 255)
d.rectangle([0, 206, W, 209], fill=rail); d.rectangle([0, 206, W, 206], fill=(190, 190, 205, 255))
for px in range(0, W, 24): d.rectangle([px + 10, 206, px + 12, 222], fill=post)
for px in range(80, W, 160):
    d.rectangle([px, 120, px + 2, 222], fill=(60, 56, 78, 255))
    d.rectangle([px, 120, px + 14, 122], fill=(60, 56, 78, 255))
    d.rectangle([px + 10, 123, px + 15, 126], fill=(255, 214, 130, 255))
    d.polygon([(px + 8, 127), (px + 18, 127), (px + 26, 150), (px, 150)], fill=(255, 214, 130, 40))
near.save(f'{A}/bg_hw_dunes.png')

# ground: asphalt
g = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(g)
d.rectangle([0, GY, W, GY], fill=(214, 168, 70, 255))      # kerb stripe
for y in range(GY + 1, H):
    d.line([(0, y), (W, y)], fill=lerp((92, 88, 104), (58, 54, 70), (y - GY) / (H - GY)) + (255,))
for x in range(0, W, 48): d.rectangle([x + 6, 246, x + 30, 247], fill=(222, 210, 150, 255))   # lane dashes
random.seed(3)
for _ in range(70): d.point((random.randrange(W), random.randrange(GY + 2, H)), fill=(46, 42, 58, 255))
for _ in range(5):
    x = random.randrange(10, W - 30); y = random.randrange(GY + 6, H - 6)
    d.line([(x, y), (x + 9, y + 2), (x + 15, y + 1)], fill=(40, 36, 52, 255))
g.save(f'{A}/hw_ground.png')

# cargo container 34x34
c = Image.new('RGBA', (34, 34), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
d.rectangle([0, 0, 33, 33], fill=(70, 84, 106, 255)); d.rectangle([0, 0, 33, 1], fill=(120, 138, 164, 255)); d.rectangle([0, 32, 33, 33], fill=(36, 44, 62, 255))
for x in range(3, 31, 5): d.line([(x, 4), (x, 29)], fill=(52, 64, 86, 255))                   # corrugation
d.rectangle([0, 0, 1, 33], fill=(40, 48, 68, 255)); d.rectangle([32, 0, 33, 33], fill=(40, 48, 68, 255))
d.rectangle([10, 13, 23, 17], fill=(206, 150, 54, 255)); d.rectangle([10, 13, 23, 13], fill=(246, 196, 96, 255))   # amber stripe
c.save(f'{A}/cover_cargo.png')
print('ok')
