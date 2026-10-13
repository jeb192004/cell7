"""Build warden_*.png / warden_s_*.png (44x56) from the AI sheet figures in /tmp/ai/ward."""
import numpy as np
from PIL import Image
from scipy.ndimage import label, binary_dilation, binary_fill_holes
SRC = '/tmp/ai/ward/f%02d.png'; SC = 0.165; W, H = 44, 56
MAP = {'ready': 0, 'aim': 1, 'fire': 3, 's_ready': 5, 's_aim': 6, 's_fire': 8}
def figure(i):
    a = np.array(Image.open(SRC % i).convert('RGB')).astype(int)
    bg = np.array([10, 15, 33]); m = np.abs(a - bg).sum(2) > 34
    m = binary_fill_holes(binary_dilation(m, iterations=2))
    lab, n = label(m)
    if n > 1: m = lab == 1 + int(np.argmax([(lab == k).sum() for k in range(1, n + 1)]))
    ys, xs = np.nonzero(m); y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return np.dstack([a.astype(np.uint8), (m * 255).astype(np.uint8)])[y0:y1, x0:x1]
def small(arr, sc):
    h, w = round(arr.shape[0] * sc), round(arr.shape[1] * sc)
    f = arr.astype(np.float32); al = f[..., 3:4] / 255
    pre = np.array(Image.fromarray((f[..., :3] * al).astype(np.uint8)).resize((w, h), Image.BOX)).astype(np.float32)
    aa = np.array(Image.fromarray(arr[..., 3]).resize((w, h), Image.BOX)).astype(np.float32) / 255
    rgb = np.where(aa[..., None] > .05, pre / np.maximum(aa[..., None], 1e-3), 0).clip(0, 255)
    # keep the orange eye glow in the head region
    r, g, b = [arr[..., k].astype(int) for k in range(3)]
    org = ((r > 200) & (g > 110) & (b < 90)).astype(np.uint8) * 255; org[int(arr.shape[0] * .3):] = 0
    cf = np.array(Image.fromarray(org).resize((w, h), Image.BOX)).astype(float) / 255
    rgb[cf > .2] = (255, 150, 40)
    return np.dstack([rgb, np.where(aa > .5, 255, 0)]).astype(np.uint8)
fr = {}
for k, i in MAP.items():
    f = figure(i); sc = min(SC, (H - .6) / f.shape[0], (W - .6) / f.shape[1]); fr[k] = small(f, sc)
allp = np.concatenate([f[f[..., 3] > 0][:, :3] for f in fr.values()])
side = int(np.ceil(np.sqrt(len(allp)))); pad = np.zeros((side * side, 3), np.uint8); pad[:len(allp)] = allp
pal = Image.fromarray(pad.reshape(side, side, 3)).quantize(colors=56, method=Image.MEDIANCUT, dither=Image.NONE)
def outline(out):
    al = out[..., 3] > 0; ring = np.zeros_like(al)
    ring[1:] |= al[:-1]; ring[:-1] |= al[1:]; ring[:, 1:] |= al[:, :-1]; ring[:, :-1] |= al[:, 1:]
    out[ring & ~al] = (12, 10, 20, 255); return out
final = {}
for k, f in fr.items():
    q = np.array(Image.fromarray(f[..., :3]).quantize(palette=pal, dither=Image.NONE).convert('RGB'))
    m = f[..., 3] > 0; h, w = m.shape
    ref = {'fire': 'fire', 's_fire': 's_fire'}.get(k, k)
    o = np.array(Image.open('tools/orig/warden_%s.png' % ref).convert('RGBA')) if False else None
    top = max(1, int(h * .25)); hcx = np.nonzero(m[:top])[1].mean()
    dx = int(round(21 - hcx)); dx = max(1, min(dx, W - 1 - w)); dy = H - 1 - (h - 1) - 1
    out = np.zeros((H, W, 4), np.uint8)
    out[dy:dy + h, dx:dx + w][m, :3] = q[m]; out[dy:dy + h, dx:dx + w][m, 3] = 255
    final[k] = outline(out)
def crouch(a):   # drop 14 rows out of the legs/coat to make the crouch
    return np.concatenate([np.zeros((14, W, 4), np.uint8), a[:36], a[50:]], axis=0)
for k in list(final):
    Image.fromarray(final[k], 'RGBA').save('assets/warden_%s.png' % k)
    if not k.endswith('ready'):
        pre = 's_' if k.startswith('s_') else ''; base = k[len(pre):]
        Image.fromarray(crouch(final[k]), 'RGBA').save('assets/warden_%sc%s.png' % (pre, base))
# the aim/caim names the game wants: aim, fire, caim, cfire
print('done')
