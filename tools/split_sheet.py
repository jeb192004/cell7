"""Split an AI sprite sheet into individual figures. usage: split_sheet.py SRC OUTDIR [minh]"""
import sys, os, numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import label, binary_dilation, find_objects
src, outd = sys.argv[1], sys.argv[2]; minh = int(sys.argv[3]) if len(sys.argv) > 3 else 100; NOSPLIT = len(sys.argv) > 4
os.makedirs(outd, exist_ok=True)
im = Image.open(src).convert('RGB'); a = np.array(im).astype(int)
bg = np.median(a[:6, :].reshape(-1, 3), axis=0)
m = np.abs(a - bg).sum(2) > 40
lab, n = label(binary_dilation(m, iterations=2)); sl = find_objects(lab)
boxes = []
for s in sl:
    y0, y1, x0, x1 = s[0].start, s[0].stop, s[1].start, s[1].stop
    if y1 - y0 >= minh: boxes.append([x0, y0, x1, y1])
boxes.sort(key=lambda b: (b[1] // 220, b[0]))
res = []
for b in boxes:
    x0, y0, x1, y1 = b; w = x1 - x0
    parts = max(1, round(w / 90)) if (w > 130 and y0 < 150 and not NOSPLIT) else 1
    cuts = [x0]
    for k in range(1, parts):
        t = x0 + w * k // parts; r = range(t - 22, t + 22)
        dens = [m[y0:y1, x].sum() for x in r]; cuts.append(list(r)[int(np.argmin(dens))])
    cuts.append(x1)
    for i in range(parts): res.append((cuts[i], y0, cuts[i + 1], y1))
sheet = Image.new('RGB', (1600, 900), (13, 18, 39)); d = ImageDraw.Draw(sheet)
for i, (x0, y0, x1, y1) in enumerate(res):
    c = im.crop((x0, y0, x1, y1)); c.save(f'{outd}/f{i:02d}.png')
    px = (i % 12) * 130 + 5; py = (i // 12) * 220 + 5
    c2 = c.copy(); c2.thumbnail((125, 190)); sheet.paste(c2, (px, py)); d.text((px, py + 195), str(i), fill=(255, 255, 0))
sheet.save(f'{outd}/_index.png'); print(len(res))
