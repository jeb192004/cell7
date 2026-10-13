#!/usr/bin/env python3
"""Builds warden_s_*.png: the Warden frames (ready, aim, fire, caim, cfire, walk_0..7) with a riot shield held out front.
Run tools/import_warden2.py first. The rifle barrel is pasted back over the shield so it pokes through."""
from PIL import Image, ImageDraw
import numpy as np, os
A = os.path.join(os.path.dirname(__file__), '..', 'assets')
SX = 33   # left edge of the shield slab (the Warden's hood is centred on column 21)
for n in ['ready', 'aim', 'fire', 'caim', 'cfire'] + ['walk_%d' % i for i in range(8)]:
    im = Image.open(f'{A}/warden_{n}.png').convert('RGBA')
    if n.startswith('walk') or n == 'ready':   # a swinging hand never pokes out in front of the shield
        arr = np.array(im); arr[:, SX + 6:] = 0; im = Image.fromarray(arr, 'RGBA')
    al = np.array(im)[..., 3] > 0
    ys = np.nonzero(al.any(1))[0]
    top = int(ys.min()) + 6
    if n.startswith('walk') or n == 'ready': top = int(ys.min()) + 7
    bot = 52
    x0 = SX
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0)); d = ImageDraw.Draw(sh)
    d.rectangle([x0, top, x0 + 5, bot], fill=(58, 62, 84, 255))           # slab
    d.rectangle([x0, top, x0, bot], fill=(104, 110, 138, 255))             # lit edge
    d.rectangle([x0 + 5, top, x0 + 5, bot], fill=(30, 32, 48, 255))        # shadow edge
    d.rectangle([x0 - 1, top - 1, x0 + 6, top], fill=(190, 140, 50, 255))  # amber rim top
    d.rectangle([x0 - 1, bot, x0 + 6, bot + 1], fill=(190, 140, 50, 255)) # amber rim bottom
    ty = top + 6
    d.rectangle([x0 + 2, ty, x0 + 3, ty + 3], fill=(255, 170, 60, 255))    # visor slit glow
    for y in range(top + 12, bot - 3, 6):
        d.rectangle([x0 + 1, y, x0 + 4, y], fill=(40, 44, 64, 255))        # ribs
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.alpha_composite(im)
    out.alpha_composite(sh)
    if n in ('aim', 'fire', 'caim', 'cfire'):   # the barrel (everything past the shield) pokes through, plus the rows it runs along
        a = np.array(im)
        rows = np.nonzero(al[:, x0 + 8:].any(1))[0]
        r0, r1 = int(rows.min()), int(rows.max())
        gun = im.crop((x0 - 1, r0, im.size[0], r1 + 1)); out.alpha_composite(gun, (x0 - 1, r0))
    out.save(f'{A}/warden_s_{n}.png')
print('ok')
