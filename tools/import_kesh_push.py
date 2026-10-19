"""Kesh's Current push: python3 tools/import_kesh_push.py
Cuts tools/src/kesh/Kesh-force_push.png (4x4, 128 px cells) into assets/kesh_push_<n>.png on Kesh's 64x48 canvas (feet on the bottom edge,
body centred) and recolours the sage-green shirt to Kesh's orange so he matches the rest of his sheets. PushCutscene picks the frames up by name.
Frames used: stand, ready, arm out, full push, hold. Stray specks over his head (frames 10-11) are removed."""
import colorsys
import numpy as np
from PIL import Image
from scipy import ndimage
SRC = 'tools/src/kesh/Kesh-force_push.png'
FRAMES = [3, 6, 7, 8, 10, 11]
K = 0.56                  # sheet px -> game px (his walk frames are 43 px tall, the sheet's standing figure ~77)
CW, CH = 64, 48
TARGET_HUE = 26 / 360.0
SHIRT_Y = (51, 78)        # the shirt is the dark tee under the brown vest, between chin and belt (sheet px)
SHIRT_X = (50, 76)        # stops before the fist so the glove stays dark
def recolour(a):
	rgb = a[..., :3].astype(float) / 255.0
	out = a.copy()
	for y in range(SHIRT_Y[0], SHIRT_Y[1]):
		for x in range(SHIRT_X[0], SHIRT_X[1]):
			if a[y, x, 3] < 110: continue
			h, s, v = colorsys.rgb_to_hsv(*rgb[y, x])
			if v < 0.30 and s < 0.45 and not (150 / 360 < h < 215 / 360 and s > 0.3 and v > 0.22):
				r, g, b = colorsys.hsv_to_rgb(TARGET_HUE, 0.85 - v * 0.8, 0.40 + v * 1.5)
				out[y, x, :3] = (int(r * 255), int(g * 255), int(b * 255))
	return out
sheet = np.array(Image.open(SRC).convert('RGBA'))
def cell(i):
	r, c = divmod(i, 4); return sheet[r*128:(r+1)*128, c*128:(c+1)*128].copy()
ref = cell(FRAMES[0])[..., 3] > 110
yy, xx = np.nonzero(ref); fy = yy.max(); m = yy > fy - 8; bx = float(xx[m].mean())          # feet centre of the standing frame: lands on the canvas centre in every frame
for n, i in enumerate(FRAMES):
	a = cell(i); alpha = a[..., 3] > 110
	lab, cnt = ndimage.label(ndimage.binary_dilation(alpha, iterations=2))
	if cnt > 1:
		sizes = ndimage.sum(alpha, lab, range(1, cnt + 1)); keep = 1 + int(np.argmax(sizes))
		a[..., 3] = np.where(lab == keep, a[..., 3], 0)       # drop specks
	a = recolour(a)
	im = Image.fromarray(a); box = im.getbbox()
	im = im.resize((round(128 * K), round(128 * K)), Image.LANCZOS)
	p = np.array(im); p[..., 3] = np.where(p[..., 3] > 110, 255, 0); im = Image.fromarray(p)
	b = im.getbbox(); feet_y = b[3]
	canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
	canvas.paste(im, (int(CW / 2 - bx * K), CH - feet_y), im)
	canvas.save('assets/kesh_push_%d.png' % n)
	print('kesh_push_%d.png' % n, 'from frame', i, 'bbox', canvas.getbbox())
