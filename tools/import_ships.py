"""Bikes + ships from the AI sheet (7ecd75ee). Places each into the old canvas, aligned to the old art's bbox."""
import sys, numpy as np
from PIL import Image
sys.path.insert(0, 'tools'); import import_art as ia
SHEET = '/root/.claude/uploads/4fb42d60-b296-53b8-86b1-508c67e69597/7ecd75ee-image.png'
# name: (crop x0,y0,x1,y1, target width, canvas (w,h), align)
JOBS = {
 'kesh_bike':    ((160, 50, 640, 305), 102, (102, 64), 'bl'),
 'warden_bike':  ((830, 48, 1385, 305), 102, (102, 64), 'bl'),
 'shrike':       ((70, 398, 575, 545), 116, (116, 35), 'lc'),
 'shrike_big':   ((655, 383, 1500, 580), 204, (204, 61), 'lc'),
 'vagabond':     ((360, 623, 1130, 940), 108, None, None),
}
sheet = Image.open(SHEET).convert('RGB')
for name, (box, w, cv, al) in JOBS.items():
    tmp = '/tmp/ai/_%s.png' % name; sheet.crop(box).save(tmp)
    img = ia.shrink(ia.cutout(tmp), w, 80 if 'bike' in name else 56)
    if cv is None: out = img
    else:
        old = Image.open('assets/%s.png' % name) if name != 'shrike_big' else Image.open('assets/shrike_big.png')
        ob = old.getbbox(); out = Image.new('RGBA', cv, (0, 0, 0, 0))
        x = ob[0]; y = (cv[1] - img.height) if al == 'bl' else int((ob[1] + ob[3]) / 2 - img.height / 2)
        if img.width + x > cv[0]: x = cv[0] - img.width
        out.alpha_composite(img, (x, max(0, y)))
    out.save('assets/%s.png' % name); print(name, img.size, '->', out.size, out.getbbox())
