"""Build the unshielded Warden art from the autosprite.io sheets in tools/src/warden2 (walk.png 4x4 @128, shoot.png 4x4 @256).
Writes assets/warden_{ready,aim,fire,caim,cfire}.png and warden_walk_0..7.png, all W x H with the hood centred on column HX.
The shoot sheet is drawn ~25% smaller than the walk sheet, so it gets a bigger scale to keep the head the same size.
The muzzle flash is cut out of shoot frame 10 and pasted onto the other frames (the sheet's own smoke puffs and tracers are dropped)."""
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
W, H, HX = 68, 56, 21
SC_W = 0.52; SC_S = 0.65
def load(n):
    a = np.array(Image.open('tools/src/warden2/%s.png' % n).convert('RGBA'))
    if a[..., 3].min() == 255:
        bg = a[0, 0, :3].astype(int); a[..., 3] = np.where(np.abs(a[..., :3].astype(int) - bg).sum(2) < 40, 0, 255)
    return a
WALK, SHOOT = load('walk'), load('shoot')
def cell(a, cw, i):
    r, c = divmod(i, 4); return a[r*cw:(r+1)*cw, c*cw:(c+1)*cw].copy()
# --- muzzle flash from shoot frame 10
f10 = cell(SHOOT, 256, 10)
R, G, B, A = [f10[..., k].astype(int) for k in range(4)]
X = np.arange(256)[None, :]*np.ones((256, 1))
flash = (A > 0) & (R > 200) & (G > 90) & (B < 200) & (X >= 160)
flash = ndi.binary_dilation(flash, iterations=1) & (A > 0) & (X >= 160)
tip10 = 160; row10 = int(np.nonzero(flash)[0].mean())   # the flash starts at the rifle tip
def rifle_tip(s):
    al = s[..., 3] > 20; xs = np.nonzero(al)[1]; tip = xs.max()
    rows = np.nonzero(al[:, tip-3:tip+1].any(1))[0]; return tip, int(rows.mean())
def with_flash(s):
    s = s.copy(); tip, row = rifle_tip(s)
    dx, dy = tip - tip10, row - row10
    ys, xs = np.nonzero(flash)
    for y, x in zip(ys, xs):
        yy, xx = y+dy, x+dx
        if 0 <= yy < 256 and 0 <= xx < 256: s[yy, xx] = f10[y, x]
    return s
def clean_shoot(s):
    """drop the smoke puff / tracer: keep the biggest blob plus anything touching it"""
    al = s[..., 3] > 20; lab, n = ndi.label(ndi.binary_dilation(al, iterations=2))
    if n > 1:
        big = 1 + int(np.argmax(ndi.sum(al, lab, range(1, n+1)))); s[(lab != big)] = 0
    return s
def crop(s):
    ys, xs = np.nonzero(s[..., 3] > 20); return s[ys.min():ys.max()+1, xs.min():xs.max()+1]
def head_cx(s):
    m = s[..., 3] > 20; h = m.shape[0]; top = max(1, int(h*.25)); return np.nonzero(m[:top])[1].mean()
def small(arr, sc):
    h, w = max(1, round(arr.shape[0]*sc)), max(1, round(arr.shape[1]*sc))
    f = arr.astype(np.float32); al = f[..., 3:4]/255
    pre = np.array(Image.fromarray((f[..., :3]*al).astype(np.uint8)).resize((w, h), Image.BOX)).astype(np.float32)
    aa = np.array(Image.fromarray(arr[..., 3]).resize((w, h), Image.BOX)).astype(np.float32)/255
    rgb = np.where(aa[..., None] > .05, pre/np.maximum(aa[..., None], 1e-3), 0).clip(0, 255)
    r, g, b = [arr[..., k].astype(int) for k in range(3)]
    org = ((r > 200) & (g > 110) & (b < 90) & (arr[..., 3] > 0)).astype(np.uint8)*255; org[int(arr.shape[0]*.3):] = 0   # eye glow
    cf = np.array(Image.fromarray(org).resize((w, h), Image.BOX)).astype(float)/255
    rgb[cf > .2] = (255, 150, 40)
    fl = ((r > 235) & (g > 170) & (b < 200) & (arr[..., 3] > 0)).astype(np.uint8)*255; fl[:int(arr.shape[0]*.3)] = 0   # muzzle flash core
    ff = np.array(Image.fromarray(fl).resize((w, h), Image.BOX)).astype(float)/255
    rgb[ff > .5] = (255, 226, 120)
    return np.dstack([rgb, np.where(aa > .5, 255, 0)]).astype(np.uint8)
SRC = {}
for k, i in {'ready': 2, 'walk_0': 0, 'walk_1': 2, 'walk_2': 4, 'walk_3': 6, 'walk_4': 8, 'walk_5': 10, 'walk_6': 12, 'walk_7': 14}.items():
    SRC[k] = (crop(cell(WALK, 128, i)), SC_W)
for k, i, fl in [('aim', 4, False), ('fire', 6, True), ('caim', 9, False), ('cfire', 9, True)]:
    s = clean_shoot(cell(SHOOT, 256, i))
    if fl: s = with_flash(s)
    SRC[k] = (crop(s), SC_S)
fr = {k: small(a, sc) for k, (a, sc) in SRC.items()}
allp = np.concatenate([f[f[..., 3] > 0][:, :3] for f in fr.values()])
side = int(np.ceil(np.sqrt(len(allp)))); pad = np.zeros((side*side, 3), np.uint8); pad[:len(allp)] = allp
pal = Image.fromarray(pad.reshape(side, side, 3)).quantize(colors=56, method=Image.MEDIANCUT, dither=Image.NONE)
def outline(out):
    al = out[..., 3] > 0; ring = np.zeros_like(al)
    ring[1:] |= al[:-1]; ring[:-1] |= al[1:]; ring[:, 1:] |= al[:, :-1]; ring[:, :-1] |= al[:, 1:]
    out[ring & ~al] = (12, 10, 20, 255); return out
for k, f in fr.items():
    q = np.array(Image.fromarray(f[..., :3]).quantize(palette=pal, dither=Image.NONE).convert('RGB'))
    m = f[..., 3] > 0; h, w = m.shape
    q[(f[..., 0] == 255) & (f[..., 1] == 226) & (f[..., 2] == 120)] = (255, 226, 120)
    hcx = head_cx(np.dstack([f[..., :3], f[..., 3]]))
    dx = int(round(HX - hcx)); dx = max(1, dx); dy = H-2-(h-1)
    assert dx + w <= W-1, (k, dx, w)
    out = np.zeros((H, W, 4), np.uint8)
    out[dy:dy+h, dx:dx+w][m, :3] = q[m]; out[dy:dy+h, dx:dx+w][m, 3] = 255
    lab, n = ndi.label(out[..., 3] > 0, structure=np.ones((3, 3)))
    for kk in range(1, n+1):
        if (lab == kk).sum() < 6: out[lab == kk] = 0
    Image.fromarray(outline(out), 'RGBA').save('assets/warden_%s.png' % k)
print({k: v.shape[:2] for k, v in fr.items()})
