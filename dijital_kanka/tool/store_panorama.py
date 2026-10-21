"""Play Store telefon ekran görüntüleri için PANORAMA üretici (kareler birbirini tamamlar).

Tek geniş tuval (N kare x 1080 px, yükseklik 1920) çizilir: kesintisiz gradyan zemin, kareleri aşan
parıltı/Zibo/telefon öğeleri, her karede başlık. Sonra 1080x1920'lik karelere dilimlenir
(Play: kenar 320-3840 px, uzun kenar <= 2x kısa kenar → 9:16 uygun; yüklemeden önce güncel kuralı teyit et).

Renkler (görselden ÖLÇÜLDÜ): app icon mavisi #043A83, Zibo teni ortanca #D18647, açık bal #EFAE70.
Geçiş OKLab'de (doğrudan sRGB karışımı ortada çamurlu gri verir) + gri kuşağı bastıran ara duraklar.

Kullanım (dijital_kanka/ içinden):  python tool/store_panorama.py <kare_sayısı> <çıktı_klasörü> [ekran_klasörü]
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FW, FH = 1080, 1920
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"
FONT_R = "C:/Windows/Fonts/segoeui.ttf"

M1 = np.array([[.4122214708, .5363325363, .0514459929], [.2119034982, .6806995451, .1073969566], [.0883024619, .2817188376, .6299787005]])
M2 = np.array([[.2104542553, .7936177850, -.0040720468], [1.9779984951, -2.4285922050, .4505937099], [.0259040371, .7827717662, -.8086757660]])


def _lin(c):
    c = c / 255
    return np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4)


def _srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= .0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - .055) * 255


def hex2lab(h):
    return M2 @ np.cbrt(M1 @ _lin(np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], float)))


def lab2rgb(lab):
    return _srgb(np.linalg.inv(M1) @ (np.linalg.inv(M2) @ lab) ** 3)


# Soldan sağa: derin lacivert → icon mavisi → parlak mavi → (gri kuşağını atlayan) açık gök/krem → bal ışığı.
STOPS = [(0.00, "#06255A"), (0.28, "#0A4AA3"), (0.52, "#1F6FD0"), (0.66, "#8FB6E3"),
         (0.78, "#F2D9A8"), (0.90, "#EFAE70"), (1.00, "#E8A25E")]


def background(n):
    w = FW * n
    t = np.linspace(0, 1, w)
    labs = np.array([hex2lab(h) for _, h in STOPS])
    pos = [p for p, _ in STOPS]
    ramp = np.stack([np.interp(t, pos, labs[:, i]) for i in range(3)], 1)
    row = np.array([lab2rgb(x) for x in ramp]).clip(0, 255)
    img = np.repeat(row[None], FH, 0)
    # dikey: üst biraz koyu, alt biraz açık (derinlik)
    v = np.linspace(-.10, .06, FH)[:, None, None]
    img = img * (1 + v)
    return Image.fromarray(img.clip(0, 255).astype(np.uint8)).convert("RGBA")


def glow(canvas, cx, cy, r, color, alpha):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (alpha,))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(r * .45)))


def phone(canvas, shot, cx, top, width, tilt=0):
    """Ekran görüntüsünü yuvarlak köşeli telefon çerçevesiyle yerleştirir (cx = yatay merkez, kareleri aşabilir)."""
    sh = shot.convert("RGBA")
    h = round(width * sh.height / sh.width)
    sh = sh.resize((width, h), Image.LANCZOS)
    bez = 22
    frame = Image.new("RGBA", (width + 2 * bez, h + 2 * bez), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle([0, 0, frame.width - 1, frame.height - 1], radius=84, fill=(14, 17, 24, 255))
    mask = Image.new("L", sh.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sh.width - 1, sh.height - 1], radius=64, fill=255)
    frame.paste(sh, (bez, bez), mask)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sx, sy = cx - frame.width // 2, top
    ImageDraw.Draw(shadow).rounded_rectangle([sx + 14, sy + 30, sx + frame.width + 14, sy + frame.height + 30], radius=84, fill=(0, 0, 0, 110))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    if tilt:
        frame = frame.rotate(tilt, expand=True, resample=Image.BICUBIC)
    canvas.alpha_composite(frame, (cx - frame.width // 2, top))


def headline(canvas, frame_idx, lines, sub, dark_text=False):
    d = ImageDraw.Draw(canvas)
    x0 = frame_idx * FW + 72
    col = (16, 24, 44) if dark_text else (255, 255, 255)
    f = ImageFont.truetype(FONT_B, 96)
    y = 120
    for ln in lines:
        d.text((x0, y), ln, font=f, fill=col)
        y += 108
    d.text((x0, y + 14), sub, font=ImageFont.truetype(FONT_R, 46), fill=col)


def slice_frames(canvas, n, out):
    out.mkdir(parents=True, exist_ok=True)
    for i in range(n):
        canvas.crop((i * FW, 0, (i + 1) * FW, FH)).convert("RGB").save(out / f"kare_{i + 1:02d}.png")
    canvas.convert("RGB").resize((canvas.width // 4, canvas.height // 4), Image.LANCZOS).save(out / "panorama_onizleme.png")


def sparkle(canvas, cx, cy, r, color=(255, 244, 214), alpha=235):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = [(cx, cy - r), (cx + r * .18, cy - r * .18), (cx + r, cy), (cx + r * .18, cy + r * .18),
           (cx, cy + r), (cx - r * .18, cy + r * .18), (cx - r, cy), (cx - r * .18, cy - r * .18)]
    d.polygon(pts, fill=color + (alpha,))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(1.2)))
    glow(canvas, cx, cy, r * 1.6, color, 70)


def zibo(canvas, path, cx, bottom, height):
    im = Image.open(path).convert("RGBA")
    w = round(im.width * height / im.height)
    im = im.resize((w, height), Image.LANCZOS)
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - w * .42, bottom - 26, cx + w * .42, bottom + 34], fill=(0, 0, 0, 90))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(20)))
    canvas.alpha_composite(im, (cx - w // 2, bottom - height))


def popup(canvas, shot_path, box, cx, top, width, tilt):
    sh = Image.open(shot_path).convert("RGBA").crop(box)
    h = round(width * sh.height / sh.width)
    sh = sh.resize((width, h), Image.LANCZOS)
    m = Image.new("L", sh.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, sh.width - 1, sh.height - 1], radius=44, fill=255)
    sh.putalpha(m)
    card = Image.new("RGBA", (width + 20, h + 20), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([0, 0, card.width - 1, card.height - 1], radius=54, fill=(255, 255, 255, 255))
    card.alpha_composite(sh, (10, 10))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([cx - card.width // 2 + 12, top + 28, cx + card.width // 2 + 12, top + card.height + 28], radius=54, fill=(0, 0, 0, 120))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(24)))
    card = card.rotate(tilt, expand=True, resample=Image.BICUBIC)
    canvas.alpha_composite(card, (cx - card.width // 2, top))


def draft3(out, ham, assets):
    """3 karelik TASLAK: 1 karşılama · 2 kostüm mağazası · 3 rozetler. Telefon kareler arası dikişi aşar."""
    n = 3
    c = background(n)
    glow(c, 500, 1250, 520, (255, 205, 130), 120)
    for x, y, r in [(150, 520, 34), (930, 380, 26), (1010, 1480, 30), (1180, 1750, 22), (2050, 360, 30), (2380, 1790, 26), (3020, 520, 28), (2920, 1700, 34)]:
        sparkle(c, x, y, r)
    zibo(c, assets / "zibo_galaksi.webp", 540, 1860, 1180)
    # Kare 1 başlık
    headline(c, 0, ["Dijital kankan", "Zibo seninle"], "Günlük hedef, alışkanlık ve eğlence")
    # Kare 2: mağaza telefonu; sağ kenarı dikişi aşan rozet telefonu
    phone(c, Image.open(ham / "magaza_kostumler.jpg"), 1080 + 500, 500, 600)
    headline(c, 1, ["27 kostüm,", "5 nadirlik"], "Topla, giy, çerçeveni parlat")
    phone(c, Image.open(ham / "rozetler.jpg"), 2160 + 10, 560, 600, tilt=0)
    # Kare 3: rozet kutlaması + başlık
    popup(c, ham / "rozet_kutlama.jpg", (40, 180, 475, 668), 2160 + 640, 1130, 470, -6)
    headline(c, 2, ["Rozet topla,", "ödül kazan"], "Her seri yeni bir başarı", dark_text=True)
    slice_frames(c, n, out)


if __name__ == "__main__":
    out = Path(sys.argv[2])
    if sys.argv[1] == "taslak":
        draft3(out, Path(sys.argv[3]), Path(sys.argv[4]))
    else:
        n = int(sys.argv[1])
        slice_frames(background(n), n, out)
    print("hazır:", out)
