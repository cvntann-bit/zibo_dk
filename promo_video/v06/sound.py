"""v06 "Yalnız değilsin" (zengin sürüm) için ses kurgusu.

Çalıştır (repo kökünden):  python promo_video/v06/sound.py [en|es]   (dil eki yoksa TR)
Önce `python promo_video/render.py v06 [--lang ..]` ile sessiz MP4'ler üretilmiş olmalı.

Müzik: promo_video/From Sad to Bright.mp3 — 109,98 bpm, ilk ölçü başı 0,44 sn. Sahne sınırları
ölçülere hizalı (S = [0, D0 + 2k·BAR]); sad→bright geçişi (şarkının 9,17. sn'si) = S[2] = daire açılışı.
Efekt zamanları index.html'deki olaylarla birebir aynı. Sesler kodla sentezlenir (telif yok).
"""
import math
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

BAR = 240 / 109.98
D0 = 0.44
S = [0.0] + [D0 + k * BAR for k in range(2, 15, 2)]
END = S[7]
PENT = [587.3, 659.3, 784.0, 880.0, 987.8, 1174.7, 1318.5]  # Sol majör pentatonik
BRIGHT = (523.3, 659.3, 784.0, 1046.5)

song = sfx.load_music(ROOT.parent / "From Sad to Bright.mp3", FF)
music = song[:int(sfx.SR * END)].copy()
fade = np.linspace(1, 0, int(sfx.SR * 0.9))
music[-len(fade):] *= fade[:, None]
music *= 0.78

T = sfx.Track(END)


def words(t0, count, step):
    for i in range(count):
        T.add(t0 + i * step, sfx.pop(640 + (i % 4) * 110), 0.5)


def landings(t0, t1, w, phase):
    """|sin(w·lt + phase)| zıplamasının yere değdiği anlar (sin = 0)."""
    k = math.ceil((w * 0 + phase) / math.pi)
    while True:
        lt = (k * math.pi - phase) / w
        if lt > t1 - t0:
            break
        if lt > 0.05:
            T.add(t0 + lt, sfx.thud(0.09, 120), 0.3)
        k += 1


# sahne geçişleri
for s in S[1:-1]:
    T.add(s - 0.05, sfx.whoosh(0.6, seed=int(s * 10)), 0.7)

# ── 0: KANCA
words(0.15, 5, 0.18)
T.add(0.5, sfx.womp(0.7, 200, 110), 0.5)                 # bulut belirir (gök gürültüsü gibi)
T.add(0.6, sfx.womp(0.5, 260, 150), 0.4)                 # başlık sarsıntısı
T.add(1.2, sfx.boing(0.35, 280), 0.55)                   # "GÜN 3" takvimi
T.add(1.25, sfx.thud(0.14, 170), 0.5)
for i in range(3):
    T.add(0.9 + i * 0.3, sfx.blop(380 + i * 40, 0.14), 0.7)
    T.add(1.9 + i * 0.35, sfx.thud(0.12, 150), 0.55)     # × damgası
    T.add(1.9 + i * 0.35, sfx.tick(900, 0.05), 0.4)
for i in range(11):
    T.add(0.2 + i * 0.42, sfx.tick(2200 + (i % 3) * 300, 0.02), 0.12)   # yağmur

# ── 1: SORUN
t = S[1]
words(t + 0.1, 5, 0.2)
T.add(t + 0.6, sfx.womp(0.6, 300, 180), 0.4)
T.add(t + 1.4, sfx.blop(430, 0.15), 0.6)                 # yazıyor balonu
for i in range(9):
    T.add(t + 1.6 + i * 0.3, sfx.tick(1500 - (i % 3) * 120, 0.025), 0.18)  # yazıyor noktaları
for i in range(7):
    T.add(t + 0.3 + i * 0.55, sfx.tick(2000 + (i % 2) * 300, 0.02), 0.1)   # yağmur

# ── 2: SELAM + SU (daire açılışı = şarkının parlak bölümü)
t = S[2]
T.add(t, sfx.whoosh(0.8, 200, 4200, seed=77), 0.6)
T.add(t + 0.05, sfx.chime(BRIGHT, 0.07, 1.2), 0.45)
T.add(t + 0.25, sfx.blop(520, 0.16), 0.8)                # balon 1
T.add(t + 1.7, sfx.blop(470, 0.16), 0.8)                 # balon 2
landings(t, S[3], 3.6, 0.4)                              # Zibo zıplıyor
for i in range(10):                                      # yükselen kalpler
    T.add(t + 0.8 + i * 0.42, sfx.bell(PENT[i % 7] * 2, 0.2), 0.16)
T.add(t + 2.9, sfx.boing(0.35, 330), 0.6)                # bardak
for i in range(14):
    T.add(t + 3.2 + i * 0.08, sfx.tick(900 + i * 60, 0.03), 0.35)
T.add(t + 3.3, sfx.party(seed=9), 0.35)
T.add(t + 4.2, sfx.sparkle(0.5, 9), 0.45)

# ── 3: KÜÇÜK ADIMLAR (canlı telefon)
t = S[3]
words(t + 0.1, 6, 0.16)
T.add(t + 0.3, sfx.boing(0.4, 260), 0.55)                # telefon belirir
T.add(t + 0.35, sfx.blop(340, 0.18), 0.6)
for k in range(1, 7):                                    # su sayacı 0→6 (eOut ile)
    p = k / 6.0
    lt = 0.9 + 1.1 * (1 - (1 - p) ** (1 / 3))
    T.add(t + lt, sfx.tick(1100 + k * 90, 0.035), 0.5)
for k in range(1, 4):                                    # seri 0→3
    T.add(t + 1.3 + 0.5 * k / 3, sfx.bell(PENT[k + 1] * 2, 0.25), 0.4)
T.add(t + 1.9, sfx.pop(820), 0.6)                        # yüz gülümser
T.add(t + 1.9, sfx.chime((659.3, 784.0, 987.8), 0.06, 0.7), 0.3)
for i in range(3):                                       # şükran satırları yazılır
    for j in range(5):
        T.add(t + 2.1 + i * 0.3 + j * 0.09, sfx.tick(1700 + j * 40, 0.02), 0.18)
T.add(t + 2.6, sfx.blop(560, 0.12), 0.5)                 # kalp
T.add(t + 3.2, sfx.bell(1046.5, 0.5), 0.45)              # "Harika!"
T.add(t + 3.3, sfx.party(seed=33), 0.7)

# ── 4: BÜYÜR (kostümler)
t = S[4]
words(t + 0.1, 3, 0.2)
for k in range(4):
    tk = t + k * 0.95
    if k:
        T.add(tk - 0.04, sfx.whoosh(0.3, 500, 2600, seed=k), 0.45)
    T.add(tk + 0.02, sfx.pop(620 + (k % 3) * 120), 0.7)
    T.add(tk + 0.02, sfx.bell(PENT[k + 2] * 2, 0.22), 0.3)
    T.add(tk + 0.12, sfx.blop(420 + k * 40, 0.1), 0.4)   # isim çıkartması
landings(t, S[5], 3.2, 0.0)
T.add(t + 3.8, sfx.sparkle(0.5, 4), 0.4)

# ── 5: YARIN YİNE (akşam)
t = S[5]
words(t + 0.1, 3, 0.2)
T.add(t + 0.3, sfx.bell(392.0, 1.2), 0.35)               # ay
for i in range(7):
    T.add(t + 0.5 + i * 0.12, sfx.bell(PENT[(i + 2) % 7] * 2, 0.3), 0.18)   # yıldızlar
for i in range(6):
    T.add(t + 1.2 + i * 0.42, sfx.bell(PENT[i % 7] * 2, 0.2), 0.13)        # kalpler

# ── 6: SON
t = S[6]
T.add(t + 0.05, sfx.blop(360, 0.2), 0.9)
T.add(t + 0.1, sfx.bell(PENT[0] * 2, 0.9), 0.4)
T.add(t + 0.25, sfx.party(seed=44), 0.9)
T.add(t + 0.8, sfx.boing(0.35, 340), 0.5)                # Zibo belirir
T.add(t + 1.4, sfx.coin(), 0.85)                         # "Ücretsiz indir"
T.add(t + 1.5, sfx.party(seed=45), 0.6)
T.add(t + 2.6, sfx.chime(BRIGHT, 0.09, 1.4), 0.45)

wav = OUT / "v06_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 and sys.argv[1] != "tr" else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v06_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v06_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", f"{END:.3f}",
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
