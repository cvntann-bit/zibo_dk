"""v01 için ses efekti kurgusu — zamanlar index.html'deki sahne olaylarıyla birebir aynı.

Çalıştır (repo kökünden):  python promo_video/v01/sound.py
Önce `python promo_video/render.py v01` ile sessiz MP4'ler üretilmiş olmalı.
Çıktı: out/v01_sfx.wav + out/zibo_v01_{9x16,16x9}_sesli.mp4
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

sys.path.insert(0, str(Path(__file__).parent.parent))
import sfx  # noqa: E402

OUT = Path(__file__).parent / "out"
S = [0, 3.2, 8.2, 12.0, 17.2, 21.2]  # sahne başlangıçları (index.html SCENES dur toplamları)
T = sfx.Track(25.5)
SCALE = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5, 1174.7]  # Do majör pentatonik — sıralı "pop"lar için

# Sahne geçişleri
for s in S[1:]:
    T.add(s - 0.05, sfx.whoosh(0.65, seed=int(s * 10)), 0.8)

# 1) Giriş: Zibo düşer-zıplar, logo ve etiket belirir, yıldızlar
T.add(0.44, sfx.thud(), 0.9)
T.add(0.44, sfx.boing(), 0.55)
T.add(0.73, sfx.thud(0.15, 160), 0.5)
T.add(0.88, sfx.thud(0.1, 190), 0.3)
T.add(0.95, sfx.blop(380, 0.16), 0.9)          # logo
T.add(1.5, sfx.blop(520), 0.8)                 # etiket
for i in range(6):
    T.add(1.05 + i * 0.14, sfx.bell(2093 + i * 260, 0.18), 0.22)

# 2) Özellikler: başlık kelimeleri, 6 kart (yükselen gam), vurgu tıkları
for i in range(4):
    T.add(S[1] + 0.32 + i * 0.13, sfx.pop(700 + i * 90), 0.5)
for i in range(6):
    T.add(S[1] + 1.12 + i * 0.13, sfx.blop(SCALE[i] * 0.7), 0.75)
    T.add(S[1] + 2.62 + i * 0.32, sfx.bell(SCALE[i] * 2, 0.22), 0.3)
T.add(S[1] + 0.6, sfx.boing(0.35, 300), 0.4)   # Zibo alttan çıkar

# 3) Zibo Coin: coin belirir, sayaç tıkır tıkır sayar, bitişte "coin"
for i in range(4):
    T.add(S[2] + 0.37 + i * 0.13, sfx.pop(700 + i * 90), 0.5)
T.add(S[2] + 0.55, sfx.coin(), 0.8)
for i in range(22):  # 1.05–2.55 sn: hızlanıp yavaşlayan sayaç
    p = i / 21
    T.add(S[2] + 1.05 + 1.5 * (1 - (1 - p) ** 2), sfx.tick(1300 + 700 * p), 0.55)
T.add(S[2] + 2.6, sfx.coin(), 1.0)
T.add(S[2] + 2.6, sfx.sparkle(0.45, 8), 0.35)

# 4) Kostümler: her geçişte kısa "svuş" + pop
T.add(S[3] + 0.45, sfx.blop(300, 0.18), 0.8)
for k in range(9):
    at = S[3] + 0.75 + k * 0.45
    T.add(at, sfx.whoosh(0.24, 500, 2600, seed=k), 0.4)
    T.add(at + 0.2, sfx.pop(620 + (k % 3) * 120), 0.7)
T.add(S[3] + 0.75 + 8 * 0.45 + 0.25, sfx.sparkle(0.5, 4), 0.4)  # son kostüm: Elmas

# 5) Oyun Salonu: başlık, YENİ etiketi, 7 vitrin (yükselen gam)
T.add(S[4] + 0.45, sfx.blop(360, 0.16), 0.8)
T.add(S[4] + 0.9, sfx.boing(0.3, 420), 0.45)
for i in range(7):
    T.add(S[4] + 0.85 + i * 0.11, sfx.blop(SCALE[i] * 0.75, 0.11), 0.7)
T.add(S[4] + 1.9, sfx.pop(800), 0.6)

# 6) Kapanış: ikon, konfeti, logo, buton, zil
T.add(S[5] + 0.45, sfx.blop(340, 0.18), 0.9)
T.add(S[5] + 0.55, sfx.party(), 0.8)
T.add(S[5] + 0.78, sfx.blop(460), 0.7)
T.add(S[5] + 1.05, sfx.pop(760), 0.5)
T.add(S[5] + 1.42, sfx.blop(560), 0.8)
T.add(S[5] + 1.45, sfx.chime(), 0.75)

wav = OUT / "v01_sfx.wav"
print("RMS", round(T.write(wav), 3))
ff = imageio_ffmpeg.get_ffmpeg_exe()
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v01_{label}.mp4"
    dst = OUT / f"zibo_v01_{label}_sesli.mp4"
    subprocess.run([ff, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest",
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
