"""Ursk sprites: python3 tools/import_ursk.py
Cuts tools/src/ursk/idle.png and walk.png (4x4 grids, 128px cells) into assets/ursk_idle_0..15.png and ursk_walk_0..15.png.
Adult height is H px; the young Ursk is the same frames drawn smaller in code (scale 0.7). Frames face RIGHT."""
import numpy as np
from PIL import Image
H = 60
def cut(path, flip):
    a = np.array(Image.open(path).convert('RGBA')); cw = 128
    cells = [a[r*cw:(r+1)*cw, c*cw:(c+1)*cw] for r in range(4) for c in range(4)]
    return [Image.fromarray(c) for c in cells], flip
out = {}
for name, flip in (('idle', False), ('walk', False)):
    cells, _ = cut('tools/src/ursk/%s.png' % name, flip)
    ys, xs = [], []
    for c in cells:
        yy, xx = np.nonzero(np.array(c)[..., 3] > 20); ys += [yy.min(), yy.max()]; xs += [xx.min(), xx.max()]
    out[name] = (cells, (min(xs), min(ys), max(xs) + 1, max(ys) + 1))
# one scale for both sheets (from the idle height) so he doesn't change size between animations
ih = out['idle'][1][3] - out['idle'][1][1]; s = H / ih
wh = out['walk'][1][3] - out['walk'][1][1]; sw = H * 0.95 / wh   # the walk sheet is drawn smaller; match it to idle
for name, (cells, box) in out.items():
    for i, c in enumerate(cells):
        k = s if name == 'idle' else sw
        o = c.crop(box); o = o.resize((max(1, round(o.width * k)), max(1, round(o.height * k))), Image.LANCZOS)
        p = np.array(o); p[..., 3] = np.where(p[..., 3] > 110, 255, 0)
        Image.fromarray(p).save('assets/ursk_%s_%d.png' % (name, i))
print('scale', s, 'idle', out['idle'][1], 'walk', out['walk'][1])
