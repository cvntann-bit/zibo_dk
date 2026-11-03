"""Zibo Dünyası görsellerini işler (docs/zibo_images_needed.md).

Kullanıcının ürettiği beyaz arka planlı JPG'leri alır:
- Zibo pozları (`zibo_*.jpg`) ve binalar (`world_*.jpg`, `world_bg` hariç): kenara bağlı düz
  beyaz arka plan şeffaf yapılır (renkli beyazlar — Zibo'nun tişörtü — korunur), kenar 2 px
  yumuşatılır ve beyaz hale temizlenir, içeriğe göre kırpılır, küçültülür, kayıplı WebP.
- `world_bg.jpg`: yalnızca küçültülür (saydamlık yok).

Kullanım (dijital_kanka/ içinde):  python -I tool/process_world_images.py <girdi_klasörü>
Çıktı: assets/images/home/<poz>.webp ve assets/images/world/<bina>.webp
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

POSE_H = 900          # poz yüksekliği (mevcut pozlar 640; tablet için biraz daha keskin)
BUILDING_MAX = 1024   # bina en uzun kenar
BG_W = 1440           # arka plan genişliği


def cut_white(img: Image.Image) -> Image.Image:
    rgb = np.asarray(img.convert('RGB')).astype(np.int16)
    lo = rgb.min(axis=2)
    hi = rgb.max(axis=2)
    near_white = (lo >= 242) & (hi - lo <= 10)
    labels, _ = ndimage.label(near_white)
    border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    border = border[border != 0]
    bg = np.isin(labels, border)
    alpha = np.where(bg, 0.0, 1.0)
    # Kenar halkası: arka plana 2 px yakın ön plan pikselleri parlaklığa göre yarı saydam.
    ring = ndimage.binary_dilation(bg, iterations=2) & ~bg
    soft = np.clip((252 - lo) / 52.0, 0.15, 1.0)
    alpha = np.where(ring, soft, alpha)
    # Beyaz haleyi temizle: c = (c - 255(1-a)) / a
    a = alpha[..., None]
    clean = np.where(a > 0, (rgb - 255 * (1 - a)) / np.maximum(a, 1e-3), 0)
    out = np.dstack([np.clip(clean, 0, 255), alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def crop(img: Image.Image, pad_frac=0.02) -> Image.Image:
    a = np.asarray(img)[..., 3]
    ys, xs = np.nonzero(a > 8)
    pad = int(max(img.size) * pad_frac)
    box = (max(xs.min() - pad, 0), max(ys.min() - pad, 0), min(xs.max() + pad + 1, img.width), min(ys.max() + pad + 1, img.height))
    return img.crop(box)


def main(src: Path):
    root = Path(__file__).resolve().parent.parent
    home = root / 'assets/images/home'
    world = root / 'assets/images/world'
    world.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.glob('*.jpg')):
        im = Image.open(f)
        name = f.stem
        if name == 'world_bg':
            out = im.convert('RGB').resize((BG_W, round(im.height * BG_W / im.width)), Image.LANCZOS)
            dest = world / 'world_bg.webp'
            out.save(dest, 'WEBP', quality=82, method=6)
        else:
            out = crop(cut_white(im))
            if name.startswith('zibo_'):
                scale = POSE_H / out.height
                dest = home / f'{name}.webp'
            else:
                scale = BUILDING_MAX / max(out.size)
                dest = world / f'{name}.webp'
            out = out.resize((round(out.width * scale), round(out.height * scale)), Image.LANCZOS)
            out.save(dest, 'WEBP', quality=88, method=6)
        check = Image.open(dest)
        corner = check.convert('RGBA').getpixel((0, 0))[3] if check.mode == 'RGBA' else None
        print(f'{name}: {check.size} {check.mode} köşe alfa={corner} {dest.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main(Path(sys.argv[1]))
