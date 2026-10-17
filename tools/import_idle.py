"""Crew-screen idle animations: python3 tools/import_idle.py <key> <sheet.png> [cell=128]
Cuts a 4x4 autosprite.io idle sheet into assets/idle_<key>_0..15.png (one shared crop so the frames don't jitter).
title.gd shows idle_<key>_N on the Crew screen when they exist, else the crew_<key>.png card."""
import sys, numpy as np
from PIL import Image
key, sheet = sys.argv[1], sys.argv[2]; cw = int(sys.argv[3]) if len(sys.argv) > 3 else 128
a = np.array(Image.open(sheet).convert('RGBA'))
if a[..., 3].min() == 255:
    bg = a[0, 0, :3].astype(int); a[..., 3] = np.where(np.abs(a[..., :3].astype(int) - bg).sum(2) < 30, 0, 255)
cells = [a[r*cw:(r+1)*cw, c*cw:(c+1)*cw] for r in range(4) for c in range(4)]
ys, xs = [], []
for c in cells:
    yy, xx = np.nonzero(c[..., 3] > 20); ys += [yy.min(), yy.max()]; xs += [xx.min(), xx.max()]
y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
for i, c in enumerate(cells):
    o = c[y0:y1+1, x0:x1+1].copy(); o[..., 3] = np.where(o[..., 3] > 20, 255, 0)
    Image.fromarray(o).save('assets/idle_%s_%d.png' % (key, i))
