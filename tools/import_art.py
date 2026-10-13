"""Bring AI-generated pixel art into the game: remove the flat background, trim, shrink to game size, clean up the palette.
usage: python3 tools/import_art.py SRC OUT WIDTH [colors] [--flip]"""
import sys
import numpy as np
from PIL import Image
from scipy.ndimage import label, binary_dilation

def cutout(src, tol=26):
    im = Image.open(src).convert('RGB'); a = np.array(im).astype(int)
    bg = np.median(np.concatenate([a[0, :], a[-1, :], a[:, 0], a[:, -1]]), axis=0)
    diff = np.abs(a - bg).sum(axis=2)
    cand = diff < tol
    lab, n = label(cand)
    edge_labels = set(np.unique(np.concatenate([lab[0, :], lab[-1, :], lab[:, 0], lab[:, -1]]))) - {0}
    bgmask = np.isin(lab, list(edge_labels))
    alpha = (~bgmask).astype(np.uint8) * 255
    rgba = np.dstack([a.astype(np.uint8), alpha])
    ys, xs = np.nonzero(alpha)
    return Image.fromarray(rgba, 'RGBA').crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

def shrink(img, width, colors=48):
    h = round(img.height * width / img.width)
    arr = np.array(img).astype(np.float32); al = arr[..., 3:4] / 255.0
    pre = Image.fromarray((arr[..., :3] * al).astype(np.uint8)).resize((width, h), Image.BOX)
    a2 = Image.fromarray(arr[..., 3].astype(np.uint8)).resize((width, h), Image.BOX)
    p = np.array(pre).astype(np.float32); aa = np.array(a2).astype(np.float32) / 255.0
    rgb = np.where(aa[..., None] > 0.05, p / np.maximum(aa[..., None], 1e-3), 0).clip(0, 255).astype(np.uint8)
    q = Image.fromarray(rgb).quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGB')
    out = np.dstack([np.array(q), np.where(aa > 0.5, 255, 0).astype(np.uint8)])
    return Image.fromarray(out, 'RGBA')

if __name__ == '__main__':
    src, out, width = sys.argv[1], sys.argv[2], int(sys.argv[3])
    colors = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4].isdigit() else 48
    img = shrink(cutout(src), width, colors)
    if '--flip' in sys.argv: img = img.transpose(Image.FLIP_LEFT_RIGHT)
    img.save(out); print(out, img.size)
