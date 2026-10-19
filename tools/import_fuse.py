"""Fuse sprites: python3 tools/import_fuse.py
Cuts the 4x4 sheets in tools/src/fuse/ into assets/fuse_<anim>_<n>.png, one canvas for all frames, feet on the bottom edge
(like Kesh and Renn). Frames face RIGHT. Edit SPEC to change which sheet frames an animation uses.
idle_fuse_* (Crew screen) is a different import."""
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

# --- second batch: walk, run, jump, gun (shoot), crouch gun (cshoot), bomb special. Each sheet was drawn at its own scale (cell, mul).
# anchor: 'union' = crop to the union of the frames (locomotion); 'fixed' = keep the body at one x in every frame (attacks), cutting
# anything past `xmax` (the sheets draw the flying bullet / bomb trail, the game draws its own).
SPEC2 = {
	'walk':    dict(sheet='Fuse-walk',               cell=128, idx=list(range(0, 16, 2)), k=0.61, anchor='union'),
	'run':     dict(sheet='Fuse-run',                cell=128, idx=list(range(0, 16, 2)), k=0.66, anchor='union'),
	'jump':    dict(sheet='Fuse-jump',               cell=128, idx=[2, 3, 4, 5, 6],       k=0.66, anchor='union'),
	'shoot':   dict(sheet='Fuse-asm_custom_attack',  cell=256, idx=[3, 7, 7, 4, 6],       k=0.71, anchor='fixed', xmax=184, body=0),
	'cshoot':  dict(sheet='Fuse-attack_coruched',    cell=128, idx=[2, 6, 6, 4, 11],      k=0.60, anchor='fixed', xmax=122, body=0),
	'special': dict(sheet='Fuse-special_attack',     cell=128, idx=list(range(0, 14)),    k=0.98, anchor='fixed', xmax=98,  body=0),
}
CW2, H2 = 96, 64
def cells2(path, cs):
	a = np.array(Image.open(path).convert('RGBA')); out = []
	for i in range(16):
		r, c = divmod(i, 4); out.append(a[r*cs:(r+1)*cs, c*cs:(c+1)*cs].copy())
	return out
for anim, sp in SPEC2.items():
	cs = sp['cell']; allc = cells2(SRC % sp['sheet'], cs); k = sp['k']
	if sp['anchor'] == 'fixed':
		allc = [np.where(np.arange(cs)[None, :, None] > sp['xmax'], 0, c) for c in allc]
	imgs = [Image.fromarray(c.astype(np.uint8)) for c in allc]
	boxes = [imgs[i].getbbox() for i in sp['idx']]
	y0 = min(b[1] for b in boxes); y1 = max(b[3] for b in boxes)
	if sp['anchor'] == 'fixed':
		# body anchor = left edge of the figure in the first frame + 18 sheet px of body; same crop for every frame
		x0 = min(b[0] for b in boxes); x1 = max(b[2] for b in boxes)
	else:
		x0 = min(b[0] for b in boxes); x1 = max(b[2] for b in boxes)
	# feet centre of the first frame (bottom 10 rows) in the crop, scaled: that x lands on the canvas centre in every frame
	ref = np.array(imgs[sp['idx'][0]].crop((x0, y0, x1, y1)))[..., 3] > 110; yy, xx = np.nonzero(ref[-10:]); bx = round(float(xx.mean()) * k)
	for n, i in enumerate(sp['idx']):
		f = imgs[i].crop((x0, y0, x1, y1)); f = f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS)
		p = np.array(f); p[..., 3] = np.where(p[..., 3] > 110, 255, 0); f = Image.fromarray(p)
		canvas = Image.new('RGBA', (CW2, H2), (0, 0, 0, 0))
		if sp['anchor'] == 'fixed': canvas.paste(f, (CW2 // 2 - bx, H2 - f.height), f)
		else: canvas.paste(f, ((CW2 - f.width) // 2, H2 - f.height), f)
		canvas.save('assets/fuse_%s_%d.png' % (anim, n))
	print(anim, len(sp['idx']), 'frames, figure', round((x1 - x0) * k), 'x', round((y1 - y0) * k))
