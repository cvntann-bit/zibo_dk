"""v01 için ses kurgusu: müzik yatağı + kodla üretilen efektler.

Çalıştır (repo kökünden):  python promo_video/v01/sound.py [es]
(dil eki verilirse aynı ses o dilin MP4'lerine eklenir)
Önce `python promo_video/render.py v01` ile sessiz MP4'ler üretilmiş olmalı.
Çıktı: out/v01_mix.wav + out/zibo_v01_{9x16,16x9}_sesli.mp4

Müzik: promo_video/Bouncy Finale.mp3 (Suno) — 100 bpm, ilk vuruş 0,29. sn, ton Sol majör
(ölçülerek bulundu). Vuruş 0,6 sn / ölçü 2,4 sn; index.html'deki sahne süreleri buna göre
2,4 ve 4,8 sn — her sahne geçişi bir ölçü başına denk gelir. Efekt zamanları index.html'deki
olaylarla birebir aynı; biri değişirse diğeri de değişmeli.
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

sys.path.insert(0, str(Path(__file__).parent.parent))
import sfx  # noqa: E402

ROOT = Path(__file__).parent
OUT = ROOT / "out"
FF = imageio_ffmpeg.get_ffmpeg_exe()
DURATION = 26.4
S = [0, 2.4, 7.2, 12.0, 16.8, 21.6]  # sahne başlangıçları (index.html SCENES dur toplamları)
PENT = [587.3, 659.3, 784.0, 880.0, 987.8, 1174.7, 1318.5]  # Sol majör pentatonik (müzikle aynı ton)
BEAT0 = 0.29   # şarkıdaki ilk ölçü başı
BAR = 2.4

# Müzik: videonun ilk 8 ölçüsü şarkının başından, son 3 ölçüsü şarkının GERÇEK bitişinden
# (27. ölçü = 65,09. sn) — böylece video şarkının kendi final vuruşlarıyla kapanır.
song = sfx.load_music(ROOT.parent / "Bouncy Finale.mp3", FF)
music = sfx.splice(song, [(0, BEAT0), (8 * BAR, BEAT0 + 27 * BAR)]) * 0.8

T = sfx.Track(DURATION)

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
    T.add(1.05 + i * 0.14, sfx.bell(PENT[i] * 2, 0.18), 0.2)

# 2) Özellikler: başlık kelimeleri, 6 kart (yükselen gam), vurgu zilleri
for i in range(4):
    T.add(S[1] + 0.37 + i * 0.15, sfx.pop(700 + i * 90), 0.5)
T.add(S[1] + 0.6, sfx.boing(0.35, 300), 0.4)   # Zibo alttan çıkar
for i in range(6):
    T.add(S[1] + 1.05 + i * 0.15, sfx.blop(PENT[i] * 0.7), 0.75)
    T.add(S[1] + 2.47 + i * 0.3, sfx.bell(PENT[i] * 2, 0.22), 0.28)

# 3) Zibo Coin: coin belirir, sayaç tıkır tıkır sayar, bitişte "coin"
for i in range(4):
    T.add(S[2] + 0.37 + i * 0.13, sfx.pop(700 + i * 90), 0.5)
T.add(S[2] + 0.55, sfx.coin(), 0.8)
for i in range(30):  # 1,05–3,3 sn: giderek yavaşlayan sayaç
    p = i / 29
    T.add(S[2] + 1.05 + 2.25 * (1 - (1 - p) ** 2), sfx.tick(1300 + 700 * p), 0.55)
T.add(S[2] + 3.35, sfx.coin(), 1.0)
T.add(S[2] + 3.35, sfx.sparkle(0.45, 8), 0.35)

# 4) Kostümler: her vuruşta bir geçiş — "svuş" ile kayar, vuruşta "pop" ile oturur
T.add(S[3] + 0.45, sfx.blop(300, 0.18), 0.8)
for k in range(6):
    T.add(S[3] + 0.9 + k * 0.6, sfx.whoosh(0.3, 500, 2600, seed=k), 0.4)
    T.add(S[3] + 1.17 + k * 0.6, sfx.pop(620 + (k % 3) * 120), 0.7)
T.add(S[3] + 1.2 + 5 * 0.6, sfx.sparkle(0.5, 4), 0.4)  # son kostüm: Elmas

# 5) Oyun Salonu: başlık, YENİ etiketi, 7 vitrin (yükselen gam)
T.add(S[4] + 0.45, sfx.blop(360, 0.16), 0.8)
T.add(S[4] + 0.9, sfx.boing(0.3, 420), 0.45)
for i in range(7):
    T.add(S[4] + 0.75 + i * 0.15, sfx.blop(PENT[i] * 0.75, 0.11), 0.7)
T.add(S[4] + 1.9, sfx.pop(800), 0.6)

# 6) Kapanış: ikon, konfeti, logo, buton, zil
T.add(S[5] + 0.45, sfx.blop(340, 0.18), 0.9)
T.add(S[5] + 0.55, sfx.party(), 0.8)
T.add(S[5] + 0.78, sfx.blop(460), 0.7)
T.add(S[5] + 1.05, sfx.pop(760), 0.5)
T.add(S[5] + 1.68, sfx.blop(560), 0.8)
T.add(S[5] + 1.78, sfx.chime(), 0.35)

wav = OUT / "v01_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v01_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v01_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", str(DURATION),
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
