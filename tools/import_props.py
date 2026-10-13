"""Props, drone and shots from the AI sheet (c8a9b34e): fit into each old sprite's tight bbox."""
import sys; sys.path.insert(0, 'tools')
import import_art as ia
from PIL import Image
SHEET = '/root/.claude/uploads/4fb42d60-b296-53b8-86b1-508c67e69597/c8a9b34e-image.png'
JOBS = {'cover_crate': (433, 635, 536, 737), 'cover_cargo': (567, 636, 659, 734), 'cover_wreck': (677, 642, 798, 724),
        'road_wreck': (809, 640, 925, 715), 'road_barrier': (938, 648, 1039, 721), 'drone': (446, 806, 541, 899),
        'bolt': (601, 843, 685, 874), 'shot_high': (759, 839, 847, 875), 'shot_low': (933, 836, 1013, 872)}
sheet = Image.open(SHEET).convert('RGB')
for n, (x0, y0, x1, y1) in JOBS.items():
    old = Image.open('tools/orig/%s_v2.png' % n); ob = old.getbbox(); bw, bh = ob[2] - ob[0], ob[3] - ob[1]
    tmp = '/tmp/ai/_%s.png' % n; sheet.crop((x0 - 3, y0 - 3, x1 + 3, y1 + 3)).save(tmp)
    cut = ia.cutout(tmp); w = min(bw, round(bh * cut.width / cut.height)); img = ia.shrink(cut, max(2, w), 40)
    out = Image.new('RGBA', old.size, (0, 0, 0, 0))
    x = ob[0] + (bw - img.width) // 2; y = ob[3] - img.height if n.startswith(('cover', 'road')) else ob[1] + (bh - img.height) // 2
    out.alpha_composite(img, (max(0, x), max(0, y))); out.save('assets/%s.png' % n); print(n, img.size, old.size)
