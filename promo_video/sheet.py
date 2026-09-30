"""`render.py --stills` ile üretilen kareleri tek bir önizleme tablosunda toplar.

Kullanım (repo kökünden):  python promo_video/sheet.py v02 [dil]
Çıktı: <video>/out/sheet_9x16.png ve sheet_16x9.png
"""
import glob
import sys
from pathlib import Path

from PIL import Image

out = Path(__file__).parent / sys.argv[1] / "out"
prefix = "still" + (f"_{sys.argv[2]}" if len(sys.argv) > 2 else "")
for lab, (tw, th, cols) in {"9x16": (300, 533, 7), "16x9": (640, 360, 3)}.items():
    fs = sorted(glob.glob(str(out / f"{prefix}_{lab}_*.png")))
    if not fs:
        continue
    rows = -(-len(fs) // cols)
    sh = Image.new("RGB", (cols * tw, rows * th))
    for i, f in enumerate(fs):
        sh.paste(Image.open(f).convert("RGB").resize((tw, th)), ((i % cols) * tw, (i // cols) * th))
    sh.save(out / f"sheet_{lab}.png")
