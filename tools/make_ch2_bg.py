"""PLACEHOLDER chapter 2 backgrounds (480x270 seamless layers) until the real art arrives.
ship (2-1), vent (2-2 first half), bay (2-2 second half), mines (2-3), catwalk (2-4). Layers: sky, far, mid, ground."""
import numpy as np, sys
from PIL import Image, ImageDraw
W, H = 480, 270
rs = np.random.RandomState(5)
def grad(top, bot):
    a = np.zeros((H, W, 4), np.uint8); t = np.linspace(0, 1, H)[:, None]
    for c in range(3): a[..., c] = (top[c] + (bot[c] - top[c]) * t).astype(np.uint8)[:, :, None].repeat(W, 1)[..., 0] if False else (top[c] + (bot[c] - top[c]) * t).repeat(W, 1).astype(np.uint8)
    a[..., 3] = 255; return Image.fromarray(a, 'RGBA')
def new(): return Image.new('RGBA', (W, H), (0, 0, 0, 0))
def panels(im, base, line, step=48, rivet=None):
    d = ImageDraw.Draw(im)
    for x in range(0, W, step): d.line([(x, 0), (x, H)], fill=line)
    for y in range(0, H, 32): d.line([(0, y), (W, y)], fill=line)
    if rivet:
        for x in range(0, W, step):
            for y in range(0, H, 32): d.point((x + 3, y + 3), rivet); d.point((x + step - 4, y + 3), rivet)
def shade_noise(im, amt=6):
    a = np.array(im).astype(int); n = rs.randint(-amt, amt + 1, (H, W, 1)); a[..., :3] = np.clip(a[..., :3] + n * (a[..., 3:4] > 0), 0, 255)
    return Image.fromarray(a.astype(np.uint8), 'RGBA')
def deck(top, base, dark, y0=222, grate=False, gaps=False):
    im = new(); d = ImageDraw.Draw(im)
    d.rectangle([0, y0, W, H], fill=base); d.rectangle([0, y0, W, y0 + 2], fill=top); d.rectangle([0, y0 + 3, W, y0 + 4], fill=dark)
    for x in range(0, W, 24): d.line([(x, y0 + 5), (x, H)], fill=dark)
    for y in range(y0 + 14, H, 14): d.line([(0, y), (W, y)], fill=dark)
    if grate:
        for x in range(0, W, 8): d.line([(x, y0 + 2), (x, y0 + 12)], fill=dark)
    return shade_noise(im, 4)
def save(name, im): im.save('assets/%s.png' % name); print(name)

# ---------- ship ----------
im = grad((18, 22, 34), (30, 36, 52)); panels(im, None, (12, 15, 24, 255), 48, (60, 68, 88, 255)); save('bg_ship_sky', shade_noise(im, 3))
far = new(); d = ImageDraw.Draw(far)
for x in range(30, W, 80):
    d.rectangle([x - 4, 30, x + 4, 222], fill=(24, 28, 40)); d.rectangle([x - 4, 30, x - 3, 222], fill=(40, 46, 62))
for x in range(70, W, 160):
    d.ellipse([x - 14, 70, x + 14, 98], fill=(10, 12, 20), outline=(60, 70, 92)); d.ellipse([x - 10, 74, x + 10, 94], fill=(18, 40, 70))
    d.point((x - 4, 80), (160, 200, 255))
save('bg_ship_far', far)
mid = new(); d = ImageDraw.Draw(mid)
for x in range(0, W, 120):
    d.rectangle([x + 20, 0, x + 34, 222], fill=(34, 40, 56)); d.rectangle([x + 20, 0, x + 22, 222], fill=(58, 66, 88)); d.rectangle([x + 32, 0, x + 34, 222], fill=(20, 24, 34))
d.rectangle([0, 52, W, 62], fill=(38, 44, 60)); d.rectangle([0, 52, W, 53], fill=(66, 74, 98)); d.rectangle([0, 60, W, 62], fill=(22, 26, 36))
d.rectangle([0, 150, W, 156], fill=(30, 35, 48))
for x in range(10, W, 120): d.rectangle([x + 60, 160, x + 90, 222], fill=(28, 32, 44)); d.rectangle([x + 66, 168, x + 84, 176], fill=(180, 60, 50))
save('bg_ship_mid', shade_noise(mid, 3))
save('ship_ground', deck((96, 106, 128), (46, 52, 70), (28, 32, 44), grate=True))

# ---------- vent ----------
im = grad((8, 9, 13), (18, 20, 28)); panels(im, None, (4, 5, 8, 255), 24)
d = ImageDraw.Draw(im)
for x in range(0, W, 24): d.rectangle([x + 8, 0, x + 12, H], fill=(14, 15, 20))
save('bg_vent_sky', shade_noise(im, 2))
far = new(); d = ImageDraw.Draw(far)
for x in range(40, W, 120): d.rectangle([x, 96, x + 22, 150], fill=(18, 20, 26)); [d.line([(x + 2, y), (x + 20, y)], fill=(4, 5, 8)) for y in range(100, 148, 5)]; d.rectangle([x + 4, 100, x + 18, 146], outline=(60, 90, 140))
save('bg_vent_far', far)
mid = new(); d = ImageDraw.Draw(mid)
for x in range(0, W, 60): d.rectangle([x, 0, x + 6, 222], fill=(24, 26, 34))
save('bg_vent_mid', mid)
save('vent_ground', deck((60, 66, 80), (28, 30, 40), (16, 17, 24), grate=True))

# ---------- docking bay ----------
im = grad((6, 8, 20), (22, 28, 52)); d = ImageDraw.Draw(im)
for _ in range(60): d.point((rs.randint(0, W), rs.randint(0, 120)), (200, 215, 255, 255))
save('bg_bay_sky', im)
far = new(); d = ImageDraw.Draw(far)
d.rectangle([0, 150, W, 222], fill=(20, 24, 36)); d.rectangle([0, 150, W, 152], fill=(70, 80, 104))
for x in range(0, W, 96): d.rectangle([x + 40, 30, x + 52, 150], fill=(28, 32, 46)); d.rectangle([x + 40, 30, x + 42, 150], fill=(52, 60, 80))
d.rectangle([0, 20, W, 30], fill=(30, 35, 50)); [d.rectangle([x, 22, x + 20, 28], fill=(255, 235, 170)) for x in range(10, W, 96)]
save('bg_bay_far', far)
mid = new(); d = ImageDraw.Draw(mid)
for x in range(30, W, 160): d.rectangle([x, 170, x + 70, 222], fill=(40, 46, 62), outline=(70, 80, 104)); d.rectangle([x + 4, 176, x + 66, 182], fill=(180, 120, 40))
save('bg_bay_mid', mid)
save('bay_ground', deck((130, 140, 160), (52, 58, 78), (30, 34, 48)))

# ---------- mines ----------
im = grad((40, 10, 14), (120, 38, 22)); d = ImageDraw.Draw(im)
for _ in range(70): x, y = rs.randint(0, W), rs.randint(0, H); d.point((x, y), (255, 180, 80, 255))
save('bg_mines_sky', im)
far = new(); d = ImageDraw.Draw(far); pts = [(0, 222)]
for x in range(0, W + 1, 20): pts.append((x, 120 + int(40 * np.sin(x * 2 * np.pi / 240) + 20 * np.sin(x * 2 * np.pi / 96))))
pts.append((W, 222)); d.polygon(pts, fill=(58, 20, 22)); save('bg_mines_far', far)
mid = new(); d = ImageDraw.Draw(mid); pts = [(0, 222)]
for x in range(0, W + 1, 12): pts.append((x, 150 + int(26 * np.sin(x * 2 * np.pi / 160) + 12 * np.sin(x * 2 * np.pi / 60))))
pts.append((W, 222)); d.polygon(pts, fill=(38, 16, 18))
for x in range(20, W, 120): d.rectangle([x, 90, x + 5, 222], fill=(64, 44, 30)); d.rectangle([x - 30, 130, x + 35, 134], fill=(64, 44, 30)); d.rectangle([x - 24, 100, x - 22, 134], fill=(52, 36, 26))
save('bg_mines_mid', shade_noise(mid, 3))
g = deck((130, 60, 36), (60, 30, 24), (36, 18, 16)); d = ImageDraw.Draw(g)
for x in range(0, W, 40): d.rectangle([x, 223, x + 30, 225], fill=(140, 130, 120))
save('mines_ground', g)

# ---------- catwalk ----------
im = grad((24, 8, 12), (170, 70, 20)); d = ImageDraw.Draw(im)
d.ellipse([140, 200, 340, 330], fill=(255, 150, 40, 255)); d.ellipse([190, 230, 290, 330], fill=(255, 220, 120, 255))
save('bg_cat_sky', im)
far = new(); d = ImageDraw.Draw(far)
for x in range(0, W, 160):
    d.rectangle([x + 20, 40, x + 30, 222], fill=(30, 14, 16)); d.line([(x + 25, 60), (x + 105, 222)], fill=(30, 14, 16), width=3); d.line([(x + 105, 60), (x + 25, 222)], fill=(30, 14, 16), width=3)
save('bg_cat_far', far)
mid = new(); d = ImageDraw.Draw(mid)
for x in range(0, W, 96): d.rectangle([x + 40, 0, x + 48, 222], fill=(20, 10, 12)); d.rectangle([x, 70, x + 96, 76], fill=(26, 12, 14))
save('bg_cat_mid', mid)
g = new(); d = ImageDraw.Draw(g); d.rectangle([0, 222, W, 232], fill=(70, 62, 66)); d.rectangle([0, 222, W, 223], fill=(150, 140, 150))
for x in range(0, W, 6): d.line([(x, 224), (x, 231)], fill=(30, 26, 30))
for x in range(0, W, 48): d.rectangle([x, 232, x + 3, H], fill=(40, 32, 36))
save('cat_ground', g)
