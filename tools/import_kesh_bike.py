"""Build assets/kesh_bike_00..24.png from the autosprite.io 5x5 bike sheet (tools/src/kesh_bike/sheet.png).
Frames are lined up on the hover pads (the sheet drifts down the cell), the jacket is recoloured to the shirt orange,
and the flame's tail is faded (the sheet clips it at the cell edge). SHIRT matches tools/import_kesh2.py."""
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
SHIRT = ((140, 60, 20), (250, 150, 30))
SC = 0.625
a = np.array(Image.open('tools/src/kesh_bike/sheet.png').convert('RGBA'))
def cell(i):
    r, c = divmod(i, 5); return a[r*256:(r+1)*256, c*256:(c+1)*256].copy()
def recolor(s):
    r, g, b, al = [s[..., k].astype(int) for k in range(4)]
    lum = .3*r + .59*g + .11*b
    H, W = al.shape; X = np.arange(W)[None, :]*np.ones((H, 1)); Y = np.arange(H)[:, None]*np.ones((1, W))
    bodyal = al.copy(); bodyal[:, :100] = False
    top = np.nonzero(bodyal.any(1))[0].min()   # top of the rider's head
    win = (X >= 113) & (X <= 184) & (Y > top+22) & (Y < top+52)
    brown = (al > 0) & (r > g+6) & (g >= b) & (r-b > 24) & (lum > 55) & (lum < 135)
    m = brown & win
    m = ndi.binary_opening(m, structure=np.ones((2, 2)))
    lab, n = ndi.label(m)
    if n:
        sz = ndi.sum(m, lab, range(1, n+1)); big = 1+int(np.argmax(sz))
        for k in range(1, n+1):
            if sz[k-1] < .25*sz[big-1]: m[lab == k] = False
    t = np.clip((lum-60)/110, 0, 1)
    col = np.array(SHIRT[0])[None, None, :]*(1-t[..., None]) + np.array(SHIRT[1])[None, None, :]*t[..., None]
    o = s.copy(); o[m, :3] = col[m].astype(np.uint8)
    return o, m
if __name__ == '__main__':
    import sys
    dbg = len(sys.argv) > 1
    outs = []
    for i in range(25):
        s = cell(i)
        s[:, 238:, 3] = 0   # stray pixels at the right edge
        s2, m = recolor(s)
        al = s2[..., 3] > 20
        R, G, B = [s2[..., k].astype(int) for k in range(3)]
        X = np.arange(256)[None, :]*np.ones((256, 1))
        body = al.copy(); body[:, :100] = False
        ys, xs = np.nonzero(body)
        bot = ys.max()
        # crop: x 0..239, rows bot-108 .. bot+4
        y0 = bot-108
        crop = np.zeros((112, 240, 4), np.uint8)
        src = s2[max(y0, 0):bot+4, :240]
        crop[112-src.shape[0]:, :] = src
        # fade the flame tail (clipped at the cell edge)
        fade = np.clip(np.arange(240)/34.0, 0, 1)[None, :]
        crop[..., 3] = (crop[..., 3]*np.where(np.arange(240)[None, :] < 34, fade, 1)).astype(np.uint8)
        arr = crop.astype(np.float32); alf = arr[..., 3:4]/255
        pre = Image.fromarray((arr[..., :3]*alf).astype(np.uint8)).resize((120, 56), Image.BOX)
        a2 = np.array(Image.fromarray(arr[..., 3].astype(np.uint8)).resize((120, 56), Image.BOX)).astype(float)/255
        p = np.array(pre).astype(float)
        rgb = np.where(a2[..., None] > .05, p/np.maximum(a2[..., None], 1e-3), 0).clip(0, 255)
        out = np.dstack([rgb, np.where(a2 > .45, 255, 0)]).astype(np.uint8)
        # soft flame tail keeps partial alpha
        tail = (np.arange(120)[None, :] < 12)&(a2 > .08)
        out[..., 3] = np.where(tail, (a2*255).astype(np.uint8), out[..., 3])
        outs.append(out)
        Image.fromarray(out, 'RGBA').save('assets/kesh_bike_%02d.png' % i)
    if dbg:
        sheet = Image.new('RGBA', (150*5*2, 70*5*2), (60, 60, 70, 255))
        for i, o in enumerate(outs):
            r, c = divmod(i, 5)
            sheet.alpha_composite(Image.fromarray(o).resize((300, 140), Image.NEAREST), (c*300, r*140))
        sheet.save(sys.argv[1])
    print('ok')
