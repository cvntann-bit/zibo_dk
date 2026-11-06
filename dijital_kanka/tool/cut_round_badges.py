"""Beyaz zeminli yuvarlak rozet görsellerinden yalnız madalyonu keser.

Görsel üreticisi madalyonun çevresine küçük parçacıklar/parıltılar serpiştirebiliyor
(2026-11-06, Zibo'nun Evi rozetleri). Bu betik: beyaz olmayan pikseller → delikleri
doldur → açma ile parçacıkları kopar → en büyük bileşen = madalyon → alanından
eşdeğer daire (merkez = ağırlık merkezi) → dairenin dışını kenarı yumuşatarak saydam
yap → kare kırp → 512 px WebP (kayıplı q85, alfa kayıpsız).

Kullanım: python tool/cut_round_badges.py <girdi_klasörü> <çıktı_klasörü> [kenar_payı_px]
"""

import glob
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SIZE = 512


def cut(path, out_dir, inset):
    im = Image.open(path).convert('RGB')
    a = np.asarray(im).astype(np.float32)
    # Beyaz zeminden ayrılan her şey (açık pastel kenarlar dahil).
    ink = (a.min(axis=2) < 232) | ((a.max(axis=2) - a.min(axis=2)) > 18)
    ink = ndimage.binary_fill_holes(ink)
    yy, xx = np.ogrid[-6:7, -6:7]
    ink = ndimage.binary_opening(ink, structure=(xx * xx + yy * yy) <= 36)
    labels, n = ndimage.label(ink)
    sizes = ndimage.sum(ink, labels, range(1, n + 1))
    disc = labels == (int(np.argmax(sizes)) + 1)
    cy, cx = ndimage.center_of_mass(disc)
    r = np.sqrt(disc.sum() / np.pi) - inset
    h, w = disc.shape
    Y, X = np.mgrid[0:h, 0:w]
    dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    alpha = np.clip(r - dist + .5, 0, 1)
    rgba = np.dstack([a, alpha * 255]).astype(np.uint8)
    box = (int(cx - r - 2), int(cy - r - 2), int(cx + r + 3), int(cy + r + 3))
    out = Image.fromarray(rgba, 'RGBA').crop(box).resize((SIZE, SIZE), Image.LANCZOS)
    name = os.path.splitext(os.path.basename(path))[0] + '.webp'
    out.save(os.path.join(out_dir, name), 'WEBP', quality=85, method=6, exact=False)
    o = np.asarray(out)
    print(f'{name}: r={r:.1f}px merkez=({cx:.0f},{cy:.0f}) köşe alfa={o[0, 0, 3]},{o[-1, -1, 3]} orta alfa={o[SIZE // 2, SIZE // 2, 3]}')


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    inset = float(sys.argv[3]) if len(sys.argv) > 3 else 2.0
    os.makedirs(dst, exist_ok=True)
    for f in sorted(glob.glob(os.path.join(src, '*.jpg')) + glob.glob(os.path.join(src, '*.png'))):
        cut(f, dst, inset)
