"""v02 "Zibo ile bir gün" için ses kurgusu: müzik yatağı + kodla üretilen efektler.

Çalıştır (repo kökünden):  python promo_video/v02/sound.py [es|en]
(dil eki verilirse aynı ses o dilin MP4'lerine eklenir)
Önce `python promo_video/render.py v02 [--lang ..]` ile sessiz MP4'ler üretilmiş olmalı.

Müzik: promo_video/Cozy Morning Routine.mp3 (Suno) — analyze.py ile ölçüldü: 100 bpm,
ilk ölçü başı 0,66. sn (öncesi bir vuruşluk giriş), ton Do majör, 96,66–106,26 arası 4 ölçülük
SAKİN bölüm, son akor 151,86'daki ölçüde çalıp sönüyor. Video 13 ölçü (31,2 sn):
  gündüz (9 ölçü)  ← şarkının başı
  gece (2 ölçü)    ← sakin bölümün son 2 ölçüsü
  yeni gün (1 ölçü)← sakin bölümden sonraki dolu dönüş (geceyle kesintisiz)
  son ölçü         ← şarkının gerçek bitişi (son akor + sönüm)
Efekt zamanları index.html'deki olaylarla birebir aynı.
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
DURATION = 31.2
S = [0, 2.4, 7.2, 12.0, 16.8, 21.6, 26.4]  # giriş, sabah, öğle, ikindi, akşam, gece, kapanış
PENT = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5, 1174.7]  # Do majör pentatonik (müzikle aynı ton)
BEAT0, BAR = 0.66, 2.4

song = sfx.load_music(ROOT.parent / "Cozy Morning Routine.mp3", FF)
music = sfx.splice(song, [(0, BEAT0), (9 * BAR, BEAT0 + 42 * BAR), (12 * BAR, BEAT0 + 63 * BAR)]) * 0.95
_fade = int(sfx.SR * 0.8)  # son akorun sönümünü videonun sonuna yumuşakça bağla
_end = int(sfx.SR * DURATION)
music[_end - _fade:_end] *= __import__("numpy").linspace(1, 0, _fade)[:, None]
music[_end:] = 0

T = sfx.Track(DURATION)

# Vakit geçişleri: yumuşak "vuş" + saat etiketinin "tik-tak"ı
for s in S[1:]:
    T.add(s - 0.1, sfx.whoosh(0.7, 250, 2600, seed=int(s * 10)), 0.6)
    T.add(s + 0.05, sfx.tick(1100, 0.04), 0.7)
    T.add(s + 0.2, sfx.tick(800, 0.04), 0.7)

# 0) Giriş: Zibo düşer-zıplar, başlık kelimeleri
T.add(0.44, sfx.thud(), 0.9)
T.add(0.44, sfx.boing(), 0.55)
T.add(0.73, sfx.thud(0.15, 160), 0.5)
T.add(0.88, sfx.thud(0.1, 190), 0.3)
for i in range(4):
    T.add(0.55 + i * 0.18, sfx.pop(700 + i * 90), 0.55)


def words(seg, n):
    for i in range(n):
        T.add(S[seg] + 0.37 + i * 0.15, sfx.pop(700 + i * 90), 0.45)


# 1) Sabah: bardak dolar (yükselen baloncuklar), hedef rozeti
words(1, 3)
T.add(S[1] + 0.5, sfx.blop(340, 0.16), 0.8)
for i in range(12):
    T.add(S[1] + 0.95 + i * 0.17, sfx.blop(300 + i * 45, 0.1), 0.5)
T.add(S[1] + 3.1, sfx.bell(PENT[4], 0.5), 0.6)
T.add(S[1] + 3.1, sfx.sparkle(0.4, 2), 0.3)
T.add(S[1] + 3.3, sfx.blop(520), 0.7)

# 2) Öğle: üç hedef vuruşlarda işaretlenir, ödül coin'i
words(2, 4)
T.add(S[2] + 0.5, sfx.blop(320, 0.18), 0.8)
for i in range(3):
    T.add(S[2] + 1.2 + i * 0.6, sfx.pop(800), 0.8)
    T.add(S[2] + 1.22 + i * 0.6, sfx.bell(PENT[i * 2], 0.3), 0.4)
T.add(S[2] + 3.05, sfx.coin(), 1.0)
T.add(S[2] + 3.25, sfx.blop(560), 0.6)

# 3) İkindi: oyun vitrinleri, yıldız sayacı
words(3, 4)
for i in range(3):
    T.add(S[3] + 0.75 + i * 0.15, sfx.blop(PENT[i * 2] * 0.75, 0.12), 0.75)
T.add(S[3] + 0.9, sfx.boing(0.3, 420), 0.4)
for i in range(18):
    p = i / 17
    T.add(S[3] + 1.5 + 1.5 * (1 - (1 - p) ** 2), sfx.tick(1300 + 700 * p), 0.5)
T.add(S[3] + 3.05, sfx.sparkle(0.5, 6), 0.45)


def typing(seg, chars, seed):
    import numpy as np
    rng = np.random.default_rng(seed)
    for i in range(chars):
        T.add(S[seg] + 1.0 + 2.0 * i / chars, sfx.tick(1700 + rng.integers(0, 500), 0.025), 0.32)


# 4) Akşam: şükran notu yazılır, ruh hali rozeti
words(4, 3)
T.add(S[4] + 0.5, sfx.blop(300, 0.18), 0.8)
T.add(S[4] + 0.7, sfx.blop(480), 0.6)
typing(4, 29, 1)
T.add(S[4] + 3.1, sfx.bell(PENT[3], 0.5), 0.55)
T.add(S[4] + 3.3, sfx.blop(540), 0.6)

# 5) Gece: rüya yazılır, seri rozeti
words(5, 4)
T.add(S[5] + 0.3, sfx.sparkle(0.6, 9), 0.35)  # astronot Zibo süzülür
T.add(S[5] + 0.5, sfx.blop(280, 0.18), 0.7)
typing(5, 20, 2)
T.add(S[5] + 3.1, sfx.bell(PENT[2], 0.6), 0.5)
T.add(S[5] + 3.1, sfx.bell(PENT[4], 0.6), 0.4)
T.add(S[5] + 3.3, sfx.blop(520), 0.6)

# 6) Kapanış: yeni gün doğar — logo, buton (müziğin final vuruşunda), zil
words(6, 4)
T.add(S[6] + 0.75, sfx.blop(380, 0.18), 0.9)
T.add(S[6] + 1.68, sfx.blop(560), 0.8)
T.add(S[6] + 1.78, sfx.chime((523.3, 659.3, 784.0, 1046.5)), 0.35)

wav = OUT / "v02_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v02_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v02_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", str(DURATION),
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
