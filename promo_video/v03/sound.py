"""v03 "Oyun Salonu fragmanı" için ses kurgusu: Pixel Dash müziği + kodla üretilen efektler.

Çalıştır (repo kökünden):  python promo_video/v03/sound.py [es|en]
(dil eki verilirse aynı ses o dilin MP4'lerine eklenir)
Önce `python promo_video/render.py v03 [--lang ..]` ile sessiz MP4'ler üretilmiş olmalı.

Müzik: promo_video/Pixel Dash.mp3 (Suno) — beatgrid.py ile ölçüldü: ilk 30 sn'de 144,46 bpm,
ilk vuruş 0,176 sn (ölçü başı), ton Do majör. Video 12 ölçü = 19,94 sn, şarkının BAŞINDAN
kesintisiz çalar; son saniyede sönümlenir. Efekt zamanları index.html'deki olaylarla birebir aynı.
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent))
import sfx  # noqa: E402

ROOT = Path(__file__).parent
OUT = ROOT / "out"
FF = imageio_ffmpeg.get_ffmpeg_exe()
BAR = 240 / 144.46
DURATION = 12 * BAR
S = [i * BAR for i in range(13)]
BEAT0 = 0.176
PENT = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5, 1174.7]  # Do majör pentatonik (müzikle aynı ton)

song = sfx.load_music(ROOT.parent / "Pixel Dash.mp3", FF)
music = sfx.splice(song, [(0, BEAT0)]) * 0.9
_end, _fade = int(sfx.SR * DURATION), int(sfx.SR * 1.0)
music[_end - _fade:_end] *= np.linspace(1, 0, _fade)[:, None]
music[_end:] = 0

T = sfx.Track(DURATION)


def words(at, n, step=0.14):
    for i in range(n):
        T.add(at + i * step, sfx.pop(700 + i * 90), 0.4)


# Her ölçü başında sahne geçişi
for i in range(1, 12):
    T.add(S[i] - 0.08, sfx.whoosh(0.5, 300, 3200, seed=i), 0.7)

# 0) Giriş: Zibo düşer-zıplar, başlık, YENİ rozeti, vitrinler
T.add(0.37, sfx.thud(), 0.9)
T.add(0.37, sfx.boing(), 0.5)
T.add(0.66, sfx.thud(0.15, 160), 0.45)
words(0.3, 2, 0.15)
T.add(0.55, sfx.blop(360, 0.16), 0.8)
T.add(0.6, sfx.sparkle(0.5, 3), 0.35)
for i in range(4):
    T.add(0.6 + i * 0.1, sfx.blop(PENT[i] * 0.75, 0.11), 0.6)
T.add(0.75, sfx.blop(520), 0.7)

# 1–7) Oyunlar: kart iner (pop), isim etiketi (blop), yükselen gam, oynanış tıkırtıları
for k in range(7):
    s = S[k + 1]
    T.add(s + 0.3, sfx.pop(650), 0.6)
    T.add(s + 0.2, sfx.thud(0.12, 150), 0.4)
    words(s + 0.2, 2, 0.12)
    T.add(s + 0.45, sfx.blop(PENT[k] * 0.7, 0.14), 0.75)
    T.add(s + 0.55, sfx.bell(PENT[k] * 2, 0.3), 0.3)
    for j in range(4):  # oyun içi tıkırtı (bot oynuyor)
        T.add(s + 0.75 + j * 0.2, sfx.tick(1200 + 250 * ((j + k) % 3), 0.03), 0.25)

# 8) Takas: altı ★ jetonu coin'e akar (her varışta yükselen nota), son coin
s = S[8]
words(s + 0.2, 5, 0.14)
for i in range(6):
    a = s + 0.45 + i * 0.15
    T.add(a, sfx.blop(320 + i * 55, 0.1), 0.6)
    T.add(a, sfx.bell(PENT[i] * 2, 0.25), 0.3)
T.add(s + 1.25, sfx.coin(), 1.0)
T.add(s + 1.25, sfx.sparkle(0.4, 8), 0.35)
T.add(s + 0.6 + 0.05, sfx.blop(480), 0.0)

# 9) Hangisi senin oyunun? — 7 vitrin sırayla
s = S[9]
words(s + 0.15, 4, 0.14)
for k in range(7):
    T.add(s + 0.12 + k * 0.1, sfx.blop(PENT[k] * 0.75, 0.11), 0.65)
T.add(s + 0.85, sfx.pop(800), 0.55)

# 10–11) Kapanış: Zibo, ikon, konfeti, logo, buton, zil
s = S[10]
T.add(s + 0.1, sfx.blop(340, 0.18), 0.9)
T.add(s + 0.15, sfx.party(), 0.8)
T.add(s + 0.35, sfx.blop(460), 0.7)
T.add(s + 0.6, sfx.pop(760), 0.5)
T.add(s + 0.83, sfx.blop(560), 0.8)
T.add(s + 0.9, sfx.chime((523.3, 659.3, 784.0, 1046.5)), 0.35)

wav = OUT / "v03_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v03_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v03_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", f"{DURATION:.3f}",
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
