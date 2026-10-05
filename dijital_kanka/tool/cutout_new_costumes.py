"""Düz renkli arka planlı kostüm görsellerinden (JPG) şeffaf PNG kesimi üretir.

Kullanım (dijital_kanka/ içinden):
    python tool/cutout_new_costumes.py "<kaynak klasör>" <çıktı klasörü>
Kaynak düzeni: <nadirlik>/<kostüm>/<kostüm>.jpg [+ <kostüm>1.jpg]. Çıktı: <çıktı>/<dosya>.png (RGBA, TAM boyut).

Yöntem (kenardan flood-fill): arka plan rengine yakın piksellerden YALNIZCA görselin kenarına bağlı
olanlar silinir — karakterin İÇİNDEKİ koyu/açık bölgeler (siyah kıyafet, beyaz gömlek) kenara
bağlı değilse korunur. Sonra maske 1 px aşındırılıp (JPEG kenar halkası gider) hafifçe yumuşatılır.
Her görselin arka plan türü köşe piksellerinden OTOMATİK seçilir (siyah / beyaz-gri stüdyo).

GÜVENİLMEZ sınıf: arka planı resmin İÇİNE pişmiş "damalı şeffaflık deseni" olan görseller
(köşelerde iki tonlu kareler) — bu betik onları REDDEDER (`--` ile raporlar), çünkü kenardan
flood-fill desenli zeminde ya sızar ya da karakteri yer. Onlar kaynakta gerçek şeffaf PNG olarak
yeniden dışa aktarılmalı.

KRİTİK (bkz. tool/CLAUDE.md): şeffaflık önizleme ile DEĞİL ham alfa ile doğrulanır — bu betik
bitişte köşe alfa değerlerini ve opak piksel oranını sayısal olarak basar.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def classify(rgb):
    """Köşe örneklerinden arka plan türü: 'black' | 'light' | 'checker' (desenli → reddedilir)."""
    h, w, _ = rgb.shape
    s = 24
    corners = [rgb[:s, :s], rgb[:s, -s:], rgb[-s:, :s], rgb[-s:, -s:]]
    means = [c.reshape(-1, 3).mean(axis=0) for c in corners]
    stds = [c.reshape(-1, 3).mean(axis=1).std() for c in corners]
    if max(stds) > 14:  # iki tonlu kare deseni → köşe içi varyans yüksek
        return "checker"
    lum = [m.mean() for m in means]
    if max(lum) < 30:
        return "black"
    if min(lum) > 200:
        return "light"
    return "checker"


def cutout(path):
    rgb = np.asarray(Image.open(path).convert("RGB"))
    kind = classify(rgb.astype(float))
    if kind == "checker":
        return None, kind
    f = rgb.astype(float)
    if kind == "black":
        bg = f.max(axis=2) <= 9      # arka plan ölçülen ~0-4; koyu kıyafetler (ninja, cüppe) >= 10 -> korunur
    else:  # light: köşelerin medyan rengine yakın + açık
        # Acik studyo zemini + zemin GOLGESI: dusuk renk doygunlugu (gri/beyaz) ve acik. Kostumun kendi
        # renkli pikselleri (turuncu ten, kahverengi onluk) doygunluk esigini asar, korunur.
        chroma = f.max(axis=2) - f.min(axis=2)
        bg = (chroma <= 13) & (f.min(axis=2) >= 170)
    lab, _ = ndimage.label(bg)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    edge = edge[edge != 0]
    outside = np.isin(lab, edge)
    fg = ~outside
    fg = ndimage.binary_opening(fg, iterations=1)                    # kenara yapışan tek piksel gürültüsü
    lab2, n2 = ndimage.label(fg)                                       # yalnızca EN BÜYÜK parça = karakter
    if n2 > 1:
        sizes = ndimage.sum(fg, lab2, range(1, n2 + 1))
        fg = lab2 == (1 + int(np.argmax(sizes)))
    fg = ndimage.binary_fill_holes(fg)
    fg = ndimage.binary_erosion(fg, iterations=1)                      # JPEG halkasını yut
    alpha = ndimage.gaussian_filter(fg.astype(float), 1.1)
    alpha = np.clip((alpha - 0.15) / 0.7, 0, 1)
    out = np.dstack([rgb, (alpha * 255).round().astype(np.uint8)])
    return Image.fromarray(out, "RGBA"), kind


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.mkdir(parents=True, exist_ok=True)
    ok, rejected = [], []
    for p in sorted(src.glob("*/*/*.jpg")):
        im, kind = cutout(p)
        if im is None:
            rejected.append(p.name)
            print(f"-- REDDEDİLDİ (damalı/desenli zemin): {p.name}")
            continue
        im.save(dst / (p.stem + ".png"))
        a = np.asarray(im)[..., 3]
        print(f"OK {p.name:28s} zemin={kind:6s} köşe alfa={[int(a[0,0]),int(a[0,-1]),int(a[-1,0]),int(a[-1,-1])]} opak oran={(a>200).mean():.2f}")
        ok.append(p.name)
    print(f"{len(ok)} kesildi, {len(rejected)} reddedildi: {rejected}")


if __name__ == "__main__":
    main()
