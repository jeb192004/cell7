#!/usr/bin/env python3
"""Night-town art for level 1-3: sky + moon, hazy skyline, building silhouettes, street lamps/banners, pavement."""
from PIL import Image, ImageDraw
import os, random
A = os.path.join(os.path.dirname(__file__), '..', 'assets')
W, H, GY = 480, 270, 222
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

sky = Image.new('RGBA', (W, H)); d = ImageDraw.Draw(sky)
stops = [(0, (12, 10, 34)), (110, (44, 28, 78)), (190, (120, 56, 108)), (230, (196, 100, 112)), (270, (196, 100, 112))]
for y in range(H):
    for (y0, c0), (y1, c1) in zip(stops, stops[1:]):
        if y0 <= y < y1:
            t = round((y - y0) / (y1 - y0) * 12) / 12
            d.line([(0, y), (W, y)], fill=lerp(c0, c1, t) + (255,))
random.seed(11)
for _ in range(70):
    x, y = random.randrange(W), random.randrange(0, 130)
    d.point((x, y), fill=(230, 220, 255, 255) if random.random() < 0.3 else (150, 140, 190, 255))
d.ellipse([352, 40, 380, 68], fill=(226, 220, 240, 255)); d.ellipse([360, 44, 380, 68], fill=(196, 188, 214, 255))
for cx, cy, r in ((362, 52, 3), (372, 60, 2), (358, 62, 2)): d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(176, 168, 198, 255))
sky.save(f'{A}/bg_town_sky.png')

def skyline(seed, col, lit, base, hs, ws, density, beacon=False):
    random.seed(seed)
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    x = 4
    while x < W - 44:
        w = random.choice(ws); h = random.choice(hs); top = base - h
        d.rectangle([x, top, x + w, H], fill=col)
        if random.random() < 0.4: d.rectangle([x + w // 2, top - 12, x + w // 2 + 1, top], fill=col)
        for wy in range(top + 6, base - 4, 9):
            for wx in range(x + 3, x + w - 3, 6):
                if random.random() < density: d.rectangle([wx, wy, wx + 1, wy + 2], fill=lit)
        x += w + random.choice([2, 5, 9])
    d.rectangle([0, base, W, H], fill=col)
    if beacon:
        d.rectangle([236, base - 150, 239, base], fill=col); d.rectangle([234, base - 154, 241, base - 150], fill=col)
        d.rectangle([237, base - 160, 238, base - 154], fill=(255, 70, 60, 255))
    return im
skyline(5, (70, 46, 96, 255), (255, 176, 96, 255), 210, [70, 100, 130, 90], [18, 26, 32], 0.12, True).save(f'{A}/bg_town_far.png')
skyline(9, (34, 26, 58, 255), (255, 200, 120, 255), 222, [80, 110, 140, 96, 124], [40, 56, 48], 0.07).save(f'{A}/bg_town_mid.png')

# near: lamps + Sovereignty banners (every 160 / 240 px, tileable)
n = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(n)
for px in range(40, W, 160):
    d.rectangle([px, 150, px + 2, GY], fill=(24, 20, 40, 255)); d.rectangle([px, 150, px + 12, 152], fill=(24, 20, 40, 255))
    d.rectangle([px + 8, 153, px + 13, 157], fill=(255, 214, 130, 255))
    d.polygon([(px + 6, 158), (px + 15, 158), (px + 24, 190), (px - 3, 190)], fill=(255, 214, 130, 38))
for px in range(120, W, 240):
    d.rectangle([px, 110, px + 12, 112], fill=(24, 20, 40, 255))
    d.rectangle([px + 1, 112, px + 11, 148], fill=(120, 28, 36, 255)); d.rectangle([px + 1, 148, px + 11, 148], fill=(80, 16, 24, 255))
    d.ellipse([px + 3, 122, px + 9, 128], fill=(222, 170, 70, 255)); d.rectangle([px + 5, 129, px + 7, 140], fill=(222, 170, 70, 255))
n.save(f'{A}/bg_town_dunes.png')

# street
g = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(g)
d.rectangle([0, GY, W, GY], fill=(170, 150, 190, 255))
for y in range(GY + 1, H): d.line([(0, y), (W, y)], fill=lerp((86, 74, 110), (50, 42, 70), (y - GY) / (H - GY)) + (255,))
for row, y in enumerate(range(GY + 6, H, 9)):
    off = 12 if row % 2 else 0
    d.line([(0, y), (W, y)], fill=(60, 50, 82, 255))
    for x in range(off, W, 24): d.line([(x, y), (x, y + 8)], fill=(60, 50, 82, 255))
random.seed(2)
for _ in range(50): d.point((random.randrange(W), random.randrange(GY + 2, H)), fill=(40, 32, 58, 255))
g.save(f'{A}/town_ground.png')
print('ok')
