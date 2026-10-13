"""Build kesh_*.png (48x48) from the autosprite.io sheets in tools/src/kesh2 (idle, walk, run, shoot, cwalk).
Extracts each frame (grid cells, or components for the walk sheet), scales each sheet so a reference pose is the right height,
shares one palette, adds a 1px outline and puts the feet on the bottom row."""
import numpy as np, os
from PIL import Image
from scipy.ndimage import label, binary_dilation, find_objects
from scipy import ndimage as ndi
SRC = 'tools/src/kesh2/%s.png'
GRID = {'shoot': (4, 4), 'idle': (4, 3), 'run': (4, 4), 'cwalk': (4, 4), 'walk': None}
SHIRT = ((140, 60, 20), (250, 150, 30))   # shadow and highlight of the shirt colour; change these to recolour him
def recolor(a, lo=SHIRT[0], hi=SHIRT[1]):
    h,w=a.shape[:2]; out=a.copy().astype(int)
    r,g,b,al=[out[...,i] for i in range(4)]
    lum=0.3*r+0.59*g+0.11*b
    cy=(al>0)&(b>150)&(g>140)&(r<130); cy[int(h*.3):]=False
    if cy.sum()<2: return a
    gx=np.nonzero(cy)[1].mean()
    cols=np.arange(w)[None,:]*np.ones((h,1)); rows=np.arange(h)[:,None]*np.ones((1,w))
    win=(cols>gx-0.30*h)&(cols<gx+0.07*h)&(rows>h*0.25)&(rows<h*0.60)
    mx=np.maximum(np.maximum(r,g),b); mn=np.minimum(np.minimum(r,g),b)
    m=(al>0)&win&(lum>18)&(lum<88)&(g>=r+2)&(g>=b-4)&((mx-mn)<45)
    m=ndi.binary_closing(m,structure=np.ones((3,3)))&(al>0)&win
    lab,n=ndi.label(m)
    if n:
        sizes=ndi.sum(m,lab,range(1,n+1)); big=1+int(np.argmax(sizes))
        for k in range(1,n+1):
            if k!=big and sizes[k-1]<0.5*sizes[big-1]: m[lab==k]=False
    t=np.clip((lum-20)/60,0,1)
    L=np.array(lo); H=np.array(hi)
    col=L[None,None,:]*(1-t[...,None])+H[None,None,:]*t[...,None]
    out[m,:3]=col[m]
    return out.astype(np.uint8)

def load(n):
    a = np.array(Image.open(SRC % n).convert('RGBA'))
    if a[..., 3].min() == 255:
        bg = a[0, 0, :3].astype(int); a[..., 3] = np.where(np.abs(a[..., :3].astype(int) - bg).sum(2) < 40, 0, 255)
    return a
def frames_of(n):
    a = load(n); H, W = a.shape[:2]; m = a[..., 3] > 20; out = []
    if GRID[n]:
        cols, rows = GRID[n]; cw, ch = W // cols, H // rows
        for r in range(rows):
            for c in range(cols):
                sub = a[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw]; mm = sub[..., 3] > 20
                if mm.sum() < 30: continue
                ys, xs = np.nonzero(mm); out.append(sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    else:
        lab, k = label(binary_dilation(m, iterations=4)); bx = []
        for s in find_objects(lab):
            if s[0].stop - s[0].start > 25: bx.append((s[1].start, s[0].start, s[1].stop, s[0].stop))
        bx.sort(key=lambda b: (round((b[1] + b[3]) / 2 / 110), b[0]))
        for x0, y0, x1, y1 in bx:
            sub = a[y0:y1, x0:x1]; mm = sub[..., 3] > 20; ys, xs = np.nonzero(mm); out.append(sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    return out
SHEET = {n: [recolor(f) for f in frames_of(n)] for n in GRID}
# (sheet, [frame indices], height the reference frames should be, in game pixels)
REF = {'idle': ([0, 2, 4, 6], 41), 'walk': ([0, 1, 2, 3, 4, 5, 6], 41), 'run': ([0, 2, 3, 5, 7, 9, 11], 39), 'shoot': ([0, 1, 2], 41), 'cwalk': ([0, 3, 6, 9], 31)}
SC = {n: REF[n][1] / np.median([SHEET[n][i].shape[0] for i in REF[n][0]]) for n in REF}
MAP = {}
for i, f in enumerate([0, 2, 5, 8]): MAP['idle_%d' % i] = ('idle', f)
for i in range(7): MAP['walk_%d' % i] = ('walk', i)
for i in range(14): MAP['run_%d' % i] = ('run', i)
for k, f in {'jump_0': 9, 'jump_1': 11, 'jump_2': 12, 'slide_0': 8, 'hit_0': 10, 'hit_1': 11}.items(): MAP[k] = ('walk', f)
for k, f in {'shoot_0': 0, 'shoot_1': 3, 'shoot_2': 4, 'shoot_3': 5, 'shoot_4': 9}.items(): MAP[k] = ('shoot', f)
MAP['crouch_0'] = ('cwalk', 0)
for i, f in enumerate([0, 3, 6, 9]): MAP['cwalk_%d' % i] = ('cwalk', f)
for i in range(5): MAP['cshoot_%d' % i] = ('cwalk', 5)
def small(img, sc):
    w, h = max(1, round(img.shape[1] * sc)), max(1, round(img.shape[0] * sc))
    arr = img.astype(np.float32); al = arr[..., 3:4] / 255
    pre = Image.fromarray((arr[..., :3] * al).astype(np.uint8)).resize((w, h), Image.BOX)
    a2 = Image.fromarray(arr[..., 3].astype(np.uint8)).resize((w, h), Image.BOX)
    p = np.array(pre).astype(np.float32); aa = np.array(a2).astype(np.float32) / 255
    rgb = np.where(aa[..., None] > .05, p / np.maximum(aa[..., None], 1e-3), 0).clip(0, 255)
    cy = ((img[..., 2] > 150) & (img[..., 1] > 150) & (img[..., 0] < 130) & (img[..., 3] > 0)).astype(np.uint8) * 255
    cf = np.array(Image.fromarray(cy).resize((w, h), Image.BOX)).astype(float) / 255
    rgb[cf > .22] = (70, 225, 235)
    fl = ((img[..., 0] > 200) & (img[..., 1] > 150) & (img[..., 2] < 170) & (img[..., 3] > 0)).astype(np.uint8) * 255
    ff = np.array(Image.fromarray(fl).resize((w, h), Image.BOX)).astype(float) / 255
    rgb[ff > .5] = (255, 226, 120)
    return np.dstack([rgb, np.where(aa > .5, 255, 0)]).astype(np.uint8)
frames = {}
for name, (sh, i) in MAP.items():
    sc = SC[sh]
    if name.startswith('slide'): sc *= 0.8
    f = SHEET[sh][i]
    if sh in ('walk', 'idle', 'cwalk') and not name.startswith(('jump', 'slide', 'hit')): sc = REF[sh][1] / f.shape[0]   # even out the head height so the walk doesn't bob
    sc = min(sc, 47.4 / f.shape[0], 63.4 / f.shape[1])
    frames[name] = small(f, sc)
allp = np.concatenate([f[f[..., 3] > 0][:, :3] for f in frames.values()])
side = int(np.ceil(np.sqrt(len(allp)))); pad = np.zeros((side * side, 3), np.uint8); pad[:len(allp)] = allp
pal = Image.fromarray(pad.reshape(side, side, 3)).quantize(colors=64, method=Image.MEDIANCUT, dither=Image.NONE)
os.makedirs('assets', exist_ok=True)
for name, f in frames.items():
    q = np.array(Image.fromarray(f[..., :3]).quantize(palette=pal, dither=Image.NONE).convert('RGB'))
    q[(f[..., 0] == 255) & (f[..., 1] == 226) & (f[..., 2] == 120)] = (255, 226, 120)
    m = f[..., 3] > 0; h, w = m.shape
    gog = (f[..., 0] == 70) & (f[..., 1] == 225) & (f[..., 2] == 235) & m   # goggles: a steady anchor so the head doesn't slide
    gog[int(h * .3):] = False   # (the slingshot tip is cyan too; only look at the head)
    if gog.sum() >= 2: hcx = np.nonzero(gog)[1].mean() - 1.5
    else:
        top = max(1, int(h * .22)); hcx = np.nonzero(m[:top])[1].mean()
    dx = int(round(29 - hcx)); dy = 47 - (h - 1)
    if name.startswith('run') and gog.sum() >= 2:   # run: half-way between feet-on-the-ground and a steady head, so the bob stays small
        dy = int(round((dy + (16.5 - np.nonzero(gog)[0].mean())) / 2))
    dx = max(1, min(dx, 63 - w)); dy = max(1, min(dy, 47 - h))
    out = np.zeros((48, 64, 4), np.uint8)
    out[dy:dy + h, dx:dx + w][m] = np.dstack([q, np.full((h, w), 255, np.uint8)])[m]
    lab, n = label(out[..., 3] > 0, structure=np.ones((3, 3)))
    for kk in range(1, n + 1):
        if (lab == kk).sum() < 12: out[lab == kk] = 0
    al = out[..., 3] > 0; ring = np.zeros_like(al)
    ring[1:] |= al[:-1]; ring[:-1] |= al[1:]; ring[:, 1:] |= al[:, :-1]; ring[:, :-1] |= al[:, 1:]
    ring &= ~al
    out[ring] = (22, 16, 30, 255)
    Image.fromarray(out, 'RGBA').save('assets/kesh_%s.png' % name)
print(len(frames), 'frames', {k: round(v, 3) for k, v in SC.items()})
