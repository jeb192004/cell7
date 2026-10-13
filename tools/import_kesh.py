"""Build kesh_*.png (48x48) from the AI sheet figures in /tmp/ai/kesh (see split_sheet.py)."""
import numpy as np, sys
from PIL import Image
from scipy.ndimage import label, binary_dilation
SRC = '/tmp/ai/kesh/f%02d.png'; SC = 0.30
MAP = {'idle_0': 0, 'run_0': 5, 'run_1': 8, 'run_2': 10, 'run_3': 11, 'run_4': 13, 'run_5': 12,
       'jump_0': 18, 'jump_1': 20, 'jump_2': 17,
       'shoot_0': 24, 'shoot_1': 25, 'shoot_2': 26, 'shoot_3': 27, 'shoot_4': 29,
       'crouch_0': 32, 'cshoot_0': 33, 'cshoot_1': 34, 'cshoot_2': 34, 'cshoot_3': 33, 'cshoot_4': 32,
       'slide_0': 35, 'hit_0': 36, 'hit_1': 37}
def orig(n):
    return Image.open('tools/orig/kesh_%s.png' % n).convert('RGBA') if __import__('os').path.exists('tools/orig/kesh_%s.png' % n) else Image.open('assets/kesh_%s.png' % n).convert('RGBA')
def figure(i, dil=10):
    a = np.array(Image.open(SRC % i).convert('RGB')).astype(int)
    bg = np.array([13, 18, 39]); m = np.abs(a - bg).sum(2) > 40
    lab, n = label(binary_dilation(m, iterations=dil))
    if n > 1:
        sizes = [(lab[m] == k).sum() for k in range(1, n + 1)]; keep = 1 + int(np.argmax(sizes)); m = m & (lab == keep)
    ys, xs = np.nonzero(m); y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgba = np.dstack([a.astype(np.uint8), (m * 255).astype(np.uint8)])[y0:y1, x0:x1]
    return Image.fromarray(rgba, 'RGBA')
def small(img, sc):
    w, h = max(1, round(img.width * sc)), max(1, round(img.height * sc))
    arr = np.array(img).astype(np.float32); al = arr[..., 3:4] / 255
    pre = Image.fromarray((arr[..., :3] * al).astype(np.uint8)).resize((w, h), Image.BOX)
    a2 = Image.fromarray(arr[..., 3].astype(np.uint8)).resize((w, h), Image.BOX)
    p = np.array(pre).astype(np.float32); aa = np.array(a2).astype(np.float32) / 255
    rgb = np.where(aa[..., None] > .05, p / np.maximum(aa[..., None], 1e-3), 0).clip(0, 255)
    src = np.array(img).astype(int); cy = ((src[..., 2] > 150) & (src[..., 1] > 150) & (src[..., 0] < 130) & (src[..., 3] > 0)).astype(np.uint8) * 255
    cf = np.array(Image.fromarray(cy).resize((w, h), Image.BOX)).astype(float) / 255
    rgb[cf > .22] = (70, 225, 235)
    return np.dstack([rgb, np.where(aa > .5, 255, 0)]).astype(np.uint8)
frames = {}
for name, i in MAP.items():
    f = figure(i, 4 if name.startswith(('run', 'idle', 'jump', 'hit', 'crouch')) else 10); sc = SC
    if name == 'slide_0': sc = 46 / f.width
    sc = min(sc, 47.4 / f.height, 47.4 / f.width)
    frames[name] = small(f, sc)
# shared palette
allp = np.concatenate([f[f[..., 3] > 0][:, :3] for f in frames.values()])
side = int(np.ceil(np.sqrt(len(allp)))); pad = np.zeros((side * side, 3), np.uint8); pad[:len(allp)] = allp
pal = Image.fromarray(pad.reshape(side, side, 3)).quantize(colors=60, method=Image.MEDIANCUT, dither=Image.NONE)
for name, f in frames.items():
    q = np.array(Image.fromarray(f[..., :3]).quantize(palette=pal, dither=Image.NONE).convert('RGB'))
    m = f[..., 3] > 0; h, w = m.shape
    o = np.array(orig(name)); om = o[..., 3] > 0; oy, ox = np.nonzero(om)
    by = oy.max()
    top = max(1, int(h * .25)); hy, hx = np.nonzero(m[:top]); hcx = hx.mean()
    otop = oy.min() + max(1, int((oy.max() - oy.min()) * .25)); sel = om[oy.min():otop]; ohx = np.nonzero(sel)[1].mean()
    if name == 'slide_0': dx = int(ox.min()); dy = by - (h - 1)
    else: dx = int(round(ohx - hcx)); dy = by - (h - 1)
    dx = max(0, min(dx, 48 - w)); dy = max(0, min(dy, 48 - h))
    out = np.zeros((48, 48, 4), np.uint8)
    for yy in range(h):
        for xx in range(w):
            X, Y = xx + dx, yy + dy
            if m[yy, xx] and 0 <= X < 48 and 0 <= Y < 48: out[Y, X, :3] = q[yy, xx]; out[Y, X, 3] = 255
    if name.startswith(('run', 'idle', 'jump', 'hit', 'crouch')):
        lab, n = label(out[..., 3] > 0, structure=np.ones((3, 3)))
        for kk in range(1, n + 1):
            if (lab == kk).sum() < 14: out[lab == kk] = 0
    al = out[..., 3] > 0; ring = np.zeros_like(al)
    ring[1:] |= al[:-1]; ring[:-1] |= al[1:]; ring[:, 1:] |= al[:, :-1]; ring[:, :-1] |= al[:, 1:]
    ring &= ~al
    if name not in ('hit_1',): out[ring] = (22, 16, 30, 255)
    Image.fromarray(out, 'RGBA').save('assets/kesh_%s.png' % name)
    print(name, (w, h), (dx, dy), 'clipped' if (dx < 0 or dx + w > 48 or dy < 0) else '')
