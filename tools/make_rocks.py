"""Pre-rendered asteroid spin sheets (lighting stays fixed while the rock turns). python3 tools/make_rocks.py"""
import sys, math, random; sys.path.insert(0, 'tools')
from hf import *
A = 'assets'
FRAMES = 16
def rock(r, seed, theta):
    rng = random.Random(seed)
    S = int(r * 2 + 8); c = S / 2.0
    s = HF(S, S, light=(-0.6, -0.6, 0.55))
    n = 13
    radii = [r * rng.uniform(0.78, 1.0) for _ in range(n)]
    pts = [(c + math.cos(2 * math.pi * i / n + theta) * radii[i], c + math.sin(2 * math.pi * i / n + theta) * radii[i]) for i in range(n)]
    base = (126, 110, 102)
    s.add(pts, base, 3 + r / 5, r * 0.7, 0)
    # craters and ridges, rotating with the rock
    for k in range(3 + int(r // 8)):
        a = rng.uniform(0, 2 * math.pi) + theta; d = rng.uniform(0.1, 0.6) * r; cr = rng.uniform(0.14, 0.26) * r + 1
        m = s.ellipse(c + math.cos(a) * d, c + math.sin(a) * d, cr, cr * 0.85, (96, 82, 78), -1.8, cr * 0.8, 0)
    for k in range(2 + int(r // 6)):    # mineral flecks
        a = rng.uniform(0, 2 * math.pi) + theta; d = rng.uniform(0.1, 0.8) * r
        x, y = int(c + math.cos(a) * d), int(c + math.sin(a) * d)
        if s.alpha[y, x]: s.paint(x, y, (150, 190, 210))
    return s.render(spec=0.1, dith=0.45, ao_k=1.0, shadow_k=0.2)
for name, r in (('rock_s', 8), ('rock_m', 14), ('rock_l', 22)):
    frames = [rock(r, 100 + r, 2 * math.pi * k / FRAMES) for k in range(FRAMES)]
    w, h = frames[0].size
    sheet = Image.new('RGBA', (w * FRAMES, h), (0, 0, 0, 0))
    for k, f in enumerate(frames): sheet.alpha_composite(f, (k * w, 0))
    sheet.save(f'{A}/{name}.png'); print(name, w, h)
prev = Image.new('RGBA', (240, 60), (14, 12, 36, 255)); x = 4
for name in ('rock_s', 'rock_m', 'rock_l'):
    im = Image.open(f'{A}/{name}.png'); w = im.width // FRAMES
    for k in (0, 5, 10): prev.alpha_composite(im.crop((k * w, 0, k * w + w, im.height)), (x, 4)); x += w + 4
prev.resize((prev.width * 4, prev.height * 4), 0).save('/tmp/rocks.png')
