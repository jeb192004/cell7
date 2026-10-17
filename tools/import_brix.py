"""Brix sprites: python3 tools/import_brix.py
Cuts the 4x4 sheets in tools/src/brix/ into assets/brix_<anim>_<n>.png, all on one canvas with the feet on the bottom edge
(like Kesh's frames), so Player can swap animations without the feet jumping. Frames face RIGHT.
Edit SPEC to change which sheet frames an animation uses."""
import numpy as np
from PIL import Image
SRC = 'tools/src/brix/Brix-%s.png'
CW, H, S = 96, 74, 0.66              # canvas width/height (px) and the scale from sheet pixels to game pixels
# anim -> (sheet, frames, cell size, scale multiplier, crop the right edge at x)
SPEC = {
	'idle':   ('idle',            [0, 4, 8, 12],             128, 1.0, None),
	'walk':   ('walk',            [0, 2, 4, 6, 8, 10, 12, 14], 128, 1.0, None),
	'run':    ('run',             [0, 2, 4, 6, 8, 10, 12, 14], 128, 1.0, None),
	'jump':   ('jump',            [5, 6, 7],                 128, 1.0, None),
	'crouch': ('crouch',          [0],                       128, 1.0, None),
	'cwalk':  ('walking_crouch',  [0, 2, 4, 6, 8, 10, 12, 14], 128, 1.0, None),
	'hit':    ('hit_react',       [1, 2, 3],                 128, 1.0, None),
	'shoot':  ('asm_custom_attack', [3, 4, 5, 6, 7],         256, 1.3, 215),
}
def cells(path, cw, cut):
	a = np.array(Image.open(path).convert('RGBA'))
	out = []
	for i in range(16):
		r, c = divmod(i, 4)
		cell = a[r*cw:(r+1)*cw, c*cw:(c+1)*cw].copy()
		if cut: cell[:, cut:, 3] = 0
		out.append(Image.fromarray(cell))
	return out
for anim, (sheet, idx, cw, mul, cut) in SPEC.items():
	allc = cells(SRC % sheet, cw, cut)
	boxes = [allc[i].getbbox() for i in range(16)]
	x0 = min(b[0] for b in boxes); x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes); y0 = min(b[1] for b in boxes)
	k = S * mul
	for n, i in enumerate(idx):
		f = allc[i].crop((x0, y0, x1, y1)); f = f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.LANCZOS)
		p = np.array(f); p[..., 3] = np.where(p[..., 3] > 110, 255, 0); f = Image.fromarray(p)
		canvas = Image.new('RGBA', (CW, H), (0, 0, 0, 0))
		canvas.paste(f, ((CW - f.width) // 2, H - f.height), f)
		canvas.save('assets/brix_%s_%d.png' % (anim, n))
	print(anim, len(idx), 'frames, figure', round((x1 - x0) * k), 'x', round((y1 - y0) * k))
# NOTE: assets/brix_idle_* were then moved down 19px onto a 96x92 canvas by hand: in the idle pose the gun hangs below the boots, so
# the boots (not the gun) have to sit on the player's feet line. Re-running this script puts the idle frames back on the 96x74 canvas.
