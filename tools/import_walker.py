#!/usr/bin/env python3
"""Slices tools/walker_sheet.jpg (4x4 frames on grey) into assets/walker_00..15.png: grey keyed out, cropped to one shared window,
scaled to SCALE. Prints the anchor (feet, body centre) to use in scripts/walker.gd."""
import os
from PIL import Image
from collections import deque
SRC = os.path.join(os.path.dirname(__file__), 'walker_sheet.jpg')
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')
SCALE = 0.62
im = Image.open(SRC).convert('RGB')
W, H = im.size; cw, ch = W // 4, H // 4
def key(cell):
    w, h = cell.size; px = cell.load()
    border = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)] + [px[0, y] for y in range(h)] + [px[w - 1, y] for y in range(h)]
    bg = tuple(sorted(c[i] for c in border)[len(border) // 2] for i in range(3))
    def near(p, t=26): return all(abs(p[i] - bg[i]) <= t for i in range(3))
    seen = [[False] * h for _ in range(w)]; q = deque()
    for x in range(w):
        for y in (0, h - 1): q.append((x, y))
    for y in range(h):
        for x in (0, w - 1): q.append((x, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[x][y]: continue
        if not near(px[x, y]): continue
        seen[x][y] = True
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    out = Image.new('RGBA', (w, h))
    po = out.load()
    for x in range(w):
        for y in range(h):
            po[x, y] = (0, 0, 0, 0) if seen[x][y] else px[x, y] + (255,)
    return out
frames = []
for i in range(16):
    r, c = divmod(i, 4)
    inset = 9   # skip the black grid lines
    cell = im.crop((c * cw + inset, r * ch + inset, (c + 1) * cw - inset, (r + 1) * ch - inset))
    frames.append(key(cell))
# frame 5 (the stomp) comes from the first sheet: the newer one lost the dust and sparks
old = Image.open(os.path.join(os.path.dirname(__file__), 'walker_sheet_old.jpg')).convert('RGB')
r, c = divmod(5, 4)
frames[5] = key(old.crop((c * cw + 9, r * ch + 9, (c + 1) * cw - 9, (r + 1) * ch - 9)))
# shared crop window = union of every frame's opaque box
box = None
for f in frames:
    b = f.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
    if b: box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
print('window', box)
for i, f in enumerate(frames):
    g = f.crop(box)
    g = g.resize((max(1, int(g.width * SCALE)), max(1, int(g.height * SCALE))), Image.LANCZOS)
    g.save(os.path.join(OUT, 'walker_%02d.png' % i))
print('size', g.size)
# muzzle: right end of the gun in the idle-with-gun frame (6); pods: the two launcher stacks in the vertical frame (11)
def box_of(i): return frames[i].crop(box).getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
a6 = frames[6].crop(box).getchannel('A'); bx6 = box_of(6)
ys = [y for y in range(a6.height) for x in range(bx6[2] - 3, bx6[2]) if a6.getpixel((x, y)) > 40]
print('muzzle art x', round(bx6[2] * SCALE), 'art y', round(sum(ys) / max(len(ys), 1) * SCALE))
a11 = frames[11].crop(box).getchannel('A'); bx11 = box_of(11)
cols = [x for x in range(a11.width) if any(a11.getpixel((x, y)) > 40 for y in range(bx11[1], bx11[1] + 4))]
groups = []
for x in cols:
    if groups and x - groups[-1][-1] <= 3: groups[-1].append(x)
    else: groups.append([x])
print('pod centres art x', [round((g[0] + g[-1]) / 2 * SCALE) for g in groups], 'top art y', round(bx11[1] * SCALE))
# anchor from the idle frame: feet = bottom of its opaque box, centre = middle of its box
b0 = frames[6].crop(box).getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
print('idle box (scaled):', [round(v * SCALE) for v in b0], 'anchor x', round((b0[0] + b0[2]) / 2 * SCALE), 'feet y', round(b0[3] * SCALE))
