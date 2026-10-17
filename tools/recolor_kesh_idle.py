"""Kesh's hi-res idle sheet: python3 tools/recolor_kesh_idle.py [sheet.png]
Recolors the vest/shirt from olive-brown to the orange jacket he wears in-game, then cuts the 4x4 sheet with import_idle.py
(assets/idle_kesh_0..15.png). Torso rows are Y0..Y1 inside each 128px cell (skin, hair, goggles, tool, gloves and pants are left alone)."""
import sys, colorsys, subprocess, numpy as np
from PIL import Image
src = sys.argv[1] if len(sys.argv) > 1 else 'tools/src/kesh/idle_hires.png'
Y0, Y1, X1 = 45, 66, 67          # vest and shirt only: not the sling arm, belt or pants
GLOVE = (57, 59, 68, 67)         # x0, y0, x1, y1 of the gray-teal bracer
ORANGE = (0.075, 0.82)            # hue (0..1), saturation of the jacket
a = np.array(Image.open(src).convert('RGBA'))
for r in range(4):
	for c in range(4):
		cell = a[r*128:(r+1)*128, c*128:(c+1)*128]
		for y in range(Y0, Y1):
			for x in range(X1):
				R, G, B, A = cell[y, x]
				if A < 40: continue
				if GLOVE[0] <= x <= GLOVE[2] and GLOVE[1] <= y <= GLOVE[3]: continue
				h, s, v = colorsys.rgb_to_hsv(R/255, G/255, B/255); hd = h * 360
				if 150 <= hd <= 260 and s > 0.2: continue                     # cyan goggles/tool, teal gloves
				if 8 <= hd <= 40 and s > 0.2 and v > 0.42: continue           # skin
				nv = min(1.0, 0.18 + v * 1.45)
				ns = ORANGE[1] * (0.65 + 0.35 * min(1.0, v * 2.2))
				nr, ng, nb = colorsys.hsv_to_rgb(ORANGE[0], ns, nv)
				cell[y, x, :3] = (int(nr*255), int(ng*255), int(nb*255))
out = 'tools/src/kesh/idle_hires_orange.png'
Image.fromarray(a).save(out)
subprocess.run(['python3', 'tools/import_idle.py', 'kesh', out], check=True)
