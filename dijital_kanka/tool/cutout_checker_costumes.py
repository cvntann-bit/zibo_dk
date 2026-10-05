"""Zemini resme PİŞMİŞ damalı "şeffaflık deseni" olan (veya parıltılı siyah zeminli) kostüm görsellerinden
şeffaf PNG kesimi. `cutout_new_costumes.py` bunları reddeder; bu betik onların özel durumudur.

Kullanım (dijital_kanka/ içinden):
    python tool/cutout_checker_costumes.py <girdi.jpg> <çıktı.png> checker <lum_alt> <lum_ust> [chroma_max] [min_parca]
    ... checker ... [min_parca] [halo_chroma halo_mesafe_px]   # damalı desen parıltı haleye pişmişse (galaksi)
    python tool/cutout_checker_costumes.py <girdi.jpg> <çıktı.png> black <eşik> <aşındırma>   # düz siyah zemin (ninja)
    python tool/cutout_checker_costumes.py <girdi.jpg> <çıktı.png> glow [eşik]   # siyah zemin + parıltı (büyücü)
`checker`: iki kare tonu [lum_alt, lum_ust] aralığında ve nötr (düşük doygunluk) pikseller zemin sayılır;
yalnızca KENARA bağlı olanlar silinir (karakterin içindeki nötr bölgeler korunur). `min_parca`: bundan
büyük ayrı parçalar (galaksi gezegenleri) tutulur, daha küçükler (kalıntı kareler) atılır.
`glow`: siyah zemin + yarı saydam parıltı (büyücü şimşeği): alfa = parlaklığa göre, renk
önçarpımdan çıkarılır; böylece parıltı siyaha değil şeffafa karışır.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def checker(rgb, lo, hi, chroma_max, min_piece, min_bg=8000):
    f = rgb.astype(float)
    chroma = f.max(axis=2) - f.min(axis=2)
    lum = f.mean(axis=2)
    bg = (chroma <= chroma_max) & (lum >= lo - 6) & (lum <= hi + 6)
    bg = ndimage.binary_closing(bg, iterations=1, border_value=1)  # kenar pikselleri erozyona girmesin
    lab, nb = ndimage.label(bg)
    sizes_bg = ndimage.sum(bg, lab, range(1, nb + 1))
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])).tolist()) - {0}
    # kenara bağlı zemin HER boyutta silinir; kenara bağlı OLMAYAN (kol-gövde arası damalı boşluk) yalnızca
    # büyükse — küçük nötr bölgeler (göz parlaması, beyaz yaka) korunur
    big = [i + 1 for i, z in enumerate(sizes_bg) if (i + 1) in edge or z >= min_bg]
    fg = ~np.isin(lab, big)
    fg = ndimage.binary_opening(fg, iterations=1)
    lab2, n2 = ndimage.label(fg)
    if n2:
        sizes = ndimage.sum(fg, lab2, range(1, n2 + 1))
        keep = [i + 1 for i, z in enumerate(sizes) if z >= min_piece]
        fg = np.isin(lab2, keep)
    fg = ndimage.binary_erosion(fg, iterations=2)  # damalı kare kenar halkasını yut
    alpha = ndimage.gaussian_filter(fg.astype(float), 1.2)
    return np.clip((alpha - 0.15) / 0.7, 0, 1)


def glow(rgb, t=9):
    """Siyah zemin. Çekirdek (gövde) = zeminden kenar flood-fill ile ayrılan ve ince şimşek
    telleri açılma ile atılmış kısım; dışındaki parlak pikseller parlaklığa göre yarı saydam."""
    f = rgb.astype(float)
    mx = f.max(axis=2)
    bg = mx <= t
    lab, _ = ndimage.label(bg)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    edge = edge[edge != 0]
    solid = ~np.isin(lab, edge)
    # ince parıltı telleri/halo çekirdekten ayrılsın: kalın açılma, sonra aynı yarıçapla geri büyüt
    core = ndimage.binary_opening(solid & (mx > 40), iterations=7)
    core = ndimage.binary_dilation(core, iterations=7) & solid
    core = ndimage.binary_fill_holes(core)
    lab2, n2 = ndimage.label(core)
    if n2 > 1:
        sizes = ndimage.sum(core, lab2, range(1, n2 + 1))
        core = lab2 == (1 + int(np.argmax(sizes)))
    glow_a = np.clip((mx - t) / 90.0, 0, 1)
    alpha = np.where(core, 1.0, glow_a)
    alpha = ndimage.gaussian_filter(alpha, 0.8)
    return alpha, f, core


def black(rgb, t, k):
    """Düz siyah zemin + siyah kıyafet: zemin maskesi `k` kez açılır (kıyafete uzanan ince kanallar kopar)."""
    mx = rgb.astype(float).max(axis=2)
    bg = ndimage.binary_opening(mx <= t, iterations=k, border_value=1)
    lab, _ = ndimage.label(bg)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    edge = edge[edge != 0]
    fg = ~np.isin(lab, edge)
    lab2, n2 = ndimage.label(fg)
    if n2 > 1:
        sizes = ndimage.sum(fg, lab2, range(1, n2 + 1))
        fg = lab2 == (1 + int(np.argmax(sizes)))
    fg = ndimage.binary_erosion(ndimage.binary_fill_holes(fg), iterations=1)
    return np.clip((ndimage.gaussian_filter(fg.astype(float), 1.1) - 0.15) / 0.7, 0, 1)


def main():
    src, dst, mode = sys.argv[1], sys.argv[2], sys.argv[3]
    rgb = np.asarray(Image.open(src).convert("RGB"))
    if mode == "checker":
        lo, hi = float(sys.argv[4]), float(sys.argv[5])
        cm = float(sys.argv[6]) if len(sys.argv) > 6 else 10
        mp = int(sys.argv[7]) if len(sys.argv) > 7 else 5000
        alpha = checker(rgb, lo, hi, cm, mp)
        if len(sys.argv) > 9:  # hale temizliği: <halo_chroma> <halo_mesafe_px> — damalı kareler DÜZ tonludur (kıyafet dokulu)
            f = rgb.astype(float)
            lum = f.mean(axis=2)
            chroma = f.max(axis=2) - f.min(axis=2)
            m1 = ndimage.uniform_filter(lum, 9)
            std = np.sqrt(np.maximum(ndimage.uniform_filter(lum * lum, 9) - m1 * m1, 0))
            flat = (std < 4.0) & (chroma <= float(sys.argv[8])) & (lum >= lo - 8) & (lum <= hi + 8)
            flat = ndimage.binary_opening(flat, iterations=2)
            dist = ndimage.distance_transform_edt(alpha > 0.5)
            cut = ndimage.binary_dilation(flat, iterations=3) & (dist <= float(sys.argv[9]))
            alpha = np.minimum(alpha, ndimage.gaussian_filter((~cut).astype(float), 1.2))
        out_rgb = rgb
    elif mode == "black":
        alpha = black(rgb, float(sys.argv[4]), int(sys.argv[5]))
        out_rgb = rgb
    else:
        alpha, f, body = glow(rgb, float(sys.argv[4]) if len(sys.argv) > 4 else 9)
        a = np.maximum(alpha, 1e-3)[..., None]
        un = np.where(body[..., None], f, np.clip(f / a, 0, 255))
        out_rgb = un.astype(np.uint8)
    out = np.dstack([out_rgb, (alpha * 255).round().astype(np.uint8)])
    Image.fromarray(out, "RGBA").save(dst)
    al = np.asarray(out)[..., 3]
    print(f"{dst}: köşe alfa={[int(al[0,0]),int(al[0,-1]),int(al[-1,0]),int(al[-1,-1])]} opak oran={(al>200).mean():.2f}")


if __name__ == "__main__":
    main()
