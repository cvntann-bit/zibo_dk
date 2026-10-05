"""cutout_new_costumes.py'nin ürettiği şeffaf PNG'leri uygulama varlığına (WebP) çevirir.

Kullanım (dijital_kanka/ içinden):
    python tool/finalize_new_costumes.py <cutout klasörü>
Çıktı: assets/images/zibo_<id>.webp (kapak) [+ zibo_<id>_pose1.webp, _pose2.webp].

Kurallar (mevcut kostümlerle AYNI düzen — bkz. lib/data/costume_poses.dart, tool/CLAUDE.md):
  * Her görsel şeffaf içeriğin sınır kutusuna KIRPILIR.
  * Kapak: yükseklik COVER_H (1024 px). Pozlar: yükseklik 763 px (TÜM kostümler için TEK global hedef —
    farklı kostümler arasında geçişte Zibo'nun görünen boyutu sabit kalır).
  * Çift görselli kostümde: kapak = ana görsel; pose1 = ana görsel, pose2 = "1" görseli.
    Tek görselli kostümde yalnızca kapak yazılır (poz seti yok → ZiboAnimatedImage statik kapağa düşer).
  * Kayıplı WebP (cwebp -q 85, alfa kalitesi 100). Son adımda ham alfa sayısal doğrulanır.
Hangi kaynağın hangi kostüm/pozlara gittiği ASSETS tablosunda — bilerek elle seçildi (kaynak kalitesi:
kusurlu/damalı zeminli görseller `cutout_checker_costumes.py` ile ayrıca kesilip aynı klasöre konur).
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

CWEBP = os.environ.get(
    "CWEBP_PATH",
    r"C:\Users\MONSTER\AppData\Local\Microsoft\WinGet\Packages\Google.Libwebp_Microsoft.Winget.Source_8wekyb3d8bbwe\libwebp-1.6.0-windows-x64\bin\cwebp.exe",
)
OUT = Path(__file__).resolve().parents[1] / "assets" / "images"
COVER_H, POSE_H = 1024, 763

# kostüm id → [ana kaynak, (isteğe bağlı) ikinci poz kaynağı]
ASSETS = {
    "zibo_chef": ["chef_zibo", "chef_zibo1"],
    "zibo_ogrenci": ["ogrenci_zibo", "ogrenci_zibo1"],
    "zibo_artist": ["artist_zibo"],
    "zibo_kovboy": ["kovboy_zibo", "kovboy_zibo1"],
    "zibo_buyucu": ["buyucu_zibo", "buyucu_zibo1"],
    "zibo_ninja": ["ninja_zibo", "ninja_zibo1"],
    "zibo_firavun": ["firavun_zibo", "firavun_zibo1"],
    "zibo_viking": ["viking_zibo"],
    "zibo_anime": ["anime_zibo"],
    "zibo_ejder_ruhu": ["ejder_ruhu_zibo", "ejder_ruhu_zibo1"],
    "zibo_galaksi": ["galaxy_zibo", "galaxy_zibo1"],
}


def cropped(path):
    im = Image.open(path).convert("RGBA")
    box = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    return im.crop(box)


def resized(im, height):
    w = round(im.width * height / im.height)
    return im.resize((w, height), Image.LANCZOS)


def write_webp(im, dest):
    with tempfile.TemporaryDirectory() as td:
        png = Path(td) / "x.png"
        im.save(png)
        subprocess.run([CWEBP, "-quiet", "-q", "85", "-alpha_q", "100", "-m", "6", str(png), "-o", str(dest)], check=True)


def main():
    cut = Path(sys.argv[1])
    total = 0
    for cid, srcs in ASSETS.items():
        base = cropped(cut / f"{srcs[0]}.png")
        write_webp(resized(base, COVER_H), OUT / f"{cid}.webp")
        written = [f"{cid}.webp"]
        if len(srcs) == 2:
            write_webp(resized(base, POSE_H), OUT / f"{cid}_pose1.webp")
            write_webp(resized(cropped(cut / f"{srcs[1]}.png"), POSE_H), OUT / f"{cid}_pose2.webp")
            written += [f"{cid}_pose1.webp", f"{cid}_pose2.webp"]
        for name in written:
            p = OUT / name
            im = Image.open(p)
            a = np.asarray(im.convert("RGBA"))[..., 3]
            corners = [int(a[0, 0]), int(a[0, -1]), int(a[-1, 0]), int(a[-1, -1])]
            total += p.stat().st_size
            print(f"{name:34s} {im.size} {p.stat().st_size / 1024:6.0f} KB  köşe alfa={corners} opak oran={(a > 200).mean():.2f}")
    print(f"toplam: {total / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
