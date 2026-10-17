"""Fuse sprites: python3 tools/import_fuse.py
Cuts the 4x4 sheets in tools/src/fuse/ into assets/fuse_<anim>_<n>.png, one canvas for all frames, feet on the bottom edge
(like Kesh and Renn). Frames face RIGHT. Edit SPEC to change which sheet frames an animation uses.
Still missing from Fuse: walk, run, jump (she can't be a playable until those exist). idle_fuse_* (Crew screen) is a different import."""
import numpy as np
from PIL import Image
SRC = 'tools/src/fuse/%s.png'
CW, H, S = 80, 64, 0.44      # canvas size (px) and scale from sheet pixels to game pixels (a standing Fuse is ~50px tall)
# the sheets were drawn a little differently: the multipliers make her the same size in every animation (measured on the standing poses)
SPEC = {
	'idle':         ('idle',                [0, 4, 8, 12],               1.0),
	'crouch':       ('Fuse-crouch',         [12],                        1.036),
	'cwalk':        ('Fuse-walking_crouch', list(range(0, 16, 2)),       1.036),
	'hit':          ('Fuse-hit_react',      [4, 5, 6, 7],                1.086),
	'plant_ground': ('Fuse-plant_device',   list(range(0, 10)),          1.027),   # stand, bend down, set the charge, rise
	'plant_wall':   ('Fuse-plant_device',   list(range(10, 16)),         1.027),   # raise arm, reach, stick the charge to the wall
}
def cells(path):
	a = np.array(Image.open(path).convert('RGBA'))
	out = []
	for i in range(16):
		r, c = divmod(i, 4)
		out.append(a[r*128:(r+1)*128, c*128:(c+1)*128].copy())
	return out
def strip_device(cell):
	"""Frames 14-15 of the plant sheet have the charge drawn on the wall, apart from her. Remove it: the game draws the charge itself."""
	cell = cell.copy(); cell[:, 108:, 3] = 0
	return cell
device_at = None
for anim, (sheet, idx, mul) in SPEC.items():
	allc = cells(SRC % sheet)
	if sheet == 'Fuse-plant_device':
		a = allc[15][:, 108:, 3]; ys, xs = np.nonzero(a)
		if len(xs): device_at = (108 + xs.min(), ys.min(), 108 + xs.max(), ys.max())
		allc = [strip_device(c) if i >= 12 else c for i, c in enumerate(allc)]
	imgs = [Image.fromarray(c) for c in allc]
	boxes = [imgs[i].getbbox() for i in idx]
	x0 = min(b[0] for b in boxes); x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes); y0 = min(b[1] for b in boxes)
	k = S * mul
	for n, i in enumerate(idx):
		f = imgs[i].crop((x0, y0, x1, y1)); f = f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS)
		p = np.array(f); p[..., 3] = np.where(p[..., 3] > 110, 255, 0); f = Image.fromarray(p)
		canvas = Image.new('RGBA', (CW, H), (0, 0, 0, 0))
		canvas.paste(f, ((CW - f.width) // 2, H - f.height), f)
		canvas.save('assets/fuse_%s_%d.png' % (anim, n))
	print(anim, len(idx), 'frames, figure', round((x1 - x0) * k), 'x', round((y1 - y0) * k))
print('charge sprite on the wall (sheet px in the 128 cell):', device_at)
