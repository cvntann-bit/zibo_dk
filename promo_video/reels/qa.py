"""Üretilen reels videolarını denetler: süre, video/ses akışı, çözünürlük + her videodan bir kare içeren önizleme tablosu.

Kullanım (repo kökünden):  python promo_video/reels/qa.py
Çıktı: out/qa_sheet_<n>.png (her biri 20 video) ve sorunlu dosyaların listesi.
"""
import re
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
from PIL import Image

HERE = Path(__file__).parent
OUT = HERE / "out"
FF = imageio_ffmpeg.get_ffmpeg_exe()
sys.path.insert(0, str(HERE))
import build  # noqa: E402

bad = []
frames = []
for sp in build.specs():
    f = OUT / build.fname(sp)
    if not f.exists():
        bad.append((f.name, "YOK"))
        continue
    info = subprocess.run([FF, "-hide_banner", "-i", str(f)], capture_output=True, text=True).stderr
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", info)
    secs = int(dur.group(1)) * 3600 + int(dur.group(2)) * 60 + float(dur.group(3))
    if "1080x1920" not in info:
        bad.append((f.name, "çözünürlük"))
    if "Audio:" not in info or "Video: h264" not in info:
        bad.append((f.name, "akış"))
    if not 8 <= secs <= 20:
        bad.append((f.name, f"süre {secs:.1f}"))
    png = OUT / f"_qa_{sp['id']}.png"
    subprocess.run([FF, "-y", "-loglevel", "error", "-ss", f"{secs * 0.55:.2f}", "-i", str(f), "-frames:v", "1",
                    "-vf", "scale=216:384", str(png)], check=True)
    frames.append((sp["id"], png))
print("sorunlu:", bad or "yok")
for g in range(0, len(frames), 20):
    part = frames[g:g + 20]
    sh = Image.new("RGB", (10 * 216, ((len(part) + 9) // 10) * 384))
    for i, (_, p) in enumerate(part):
        sh.paste(Image.open(p).convert("RGB"), ((i % 10) * 216, (i // 10) * 384))
    sh.save(OUT / f"qa_sheet_{g // 20}.png")
    print("sheet", g // 20, [i for i, _ in part][0], "-", [i for i, _ in part][-1])
for _, p in frames:
    p.unlink()
