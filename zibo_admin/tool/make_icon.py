import sys, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops
src, res, preview = sys.argv[1], sys.argv[2], sys.argv[3]
king = Image.open(src).convert('RGBA')
king = king.crop((0, 0, king.width, 520))  # baş + kaftan (küçük ikonda okunur)
a = king.getchannel('A')
king = king.crop(a.getbbox())

def outlined(img, w):
    pad = w * 2
    base = Image.new('RGBA', (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    base.paste(img, (pad, pad), img)
    alpha = base.getchannel('A').point(lambda v: 255 if v > 40 else 0)
    ring = alpha.filter(ImageFilter.MaxFilter(w * 2 + 1)).filter(ImageFilter.GaussianBlur(1.2))
    white = Image.new('RGBA', base.size, (255, 253, 247, 255)); white.putalpha(ring)
    ink = alpha.filter(ImageFilter.MaxFilter(w * 2 + 7)).filter(ImageFilter.GaussianBlur(1.2))
    dark = Image.new('RGBA', base.size, (20, 17, 12, 255)); dark.putalpha(ink)
    out = Image.alpha_composite(dark, white)
    return Image.alpha_composite(out, base)

S = 432  # 108dp @ xxxhdpi
def background(size):
    bg = Image.new('RGBA', (size, size))
    d = ImageDraw.Draw(bg)
    c1, c2 = (255, 158, 48), (232, 96, 12)  # açık turuncu merkez → koyu turuncu kenar
    for r in range(size, 0, -2):
        t = r / size
        col = tuple(int(c1[i] * (1 - t) + c2[i] * t) for i in range(3))
        d.ellipse((size/2 - r*0.75, size*0.42 - r*0.75, size/2 + r*0.75, size*0.42 + r*0.75), fill=col + (255,))
    return bg

def foreground(size, box):
    fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    k = outlined(king, 9)
    scale = min(box / k.width, box / k.height)
    k = k.resize((int(k.width * scale), int(k.height * scale)), Image.LANCZOS)
    fg.paste(k, ((size - k.width) // 2, (size - k.height) // 2 + int(size * 0.02)), k)
    return fg

# Adaptive: güvenli bölge çapı 66dp/108dp → içerik ~ 0.64*S
fg = foreground(S, int(S * 0.64)); bg = background(S)
dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, m in dens.items():
    d = os.path.join(res, f'mipmap-{name}'); os.makedirs(d, exist_ok=True)
    s = int(108 * m)
    fg.resize((s, s), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))
    bg.resize((s, s), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_background.png'))
    # Eski (API<26) ikon: 48dp yuvarlatılmış kare, içerik daha büyük
    L = int(48 * m) * 4
    leg = Image.alpha_composite(background(L), foreground(L, int(L * 0.86)))
    mask = Image.new('L', (L, L), 0); ImageDraw.Draw(mask).rounded_rectangle((0, 0, L - 1, L - 1), radius=L // 5, fill=255)
    leg.putalpha(mask)
    leg.resize((int(48 * m), int(48 * m)), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))

# Önizleme: daire maskeli adaptive + eski
pv = Image.alpha_composite(bg, fg)
cm = Image.new('L', (S, S), 0); ImageDraw.Draw(cm).ellipse((0, 0, S - 1, S - 1), fill=255)
pv.putalpha(cm)
sheet = Image.new('RGBA', (S * 2 + 60, S + 40), (40, 40, 40, 255))
sheet.paste(pv, (20, 20), pv)
legacy = Image.open(os.path.join(res, 'mipmap-xxxhdpi', 'ic_launcher.png')).resize((S, S), Image.LANCZOS)
sheet.paste(legacy, (S + 40, 20), legacy)
sheet.save(preview)
