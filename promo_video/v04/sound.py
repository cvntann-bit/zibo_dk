"""v04 "sorun → çözüm" reklamı için ses kurgusu: From Sad to Bright müziği + kodla üretilen efektler.

Çalıştır (repo kökünden):  python promo_video/v04/sound.py [es|en]
(dil eki verilirse aynı ses o dilin MP4'lerine eklenir)
Önce `python promo_video/render.py v04 [--lang ..]` ile sessiz MP4'ler üretilmiş olmalı.

Müzik: promo_video/From Sad to Bright.mp3 (Suno) — analyze.py/beatgrid.py ile ölçüldü: 109,98 bpm,
ilk ölçü başı 0,44 sn, ton Sol majör, sakin→neşeli geçiş 9,17. sn'de (4. ölçü başı = ölçü 4).
Video şarkının 2. ölçüsünden başlar (2 ölçü sakin → ölçü 4'teki "düşüş" videonun 2. ölçüsü),
ölçü 0–5 kesintisiz akar, son ölçü şarkının GERÇEK bitişinden (27. ölçü, 59,36 sn) gelir.
Efekt zamanları index.html'deki olaylarla birebir aynı.
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
BAR = 240 / 109.98
DURATION = 7 * BAR
S = [i * BAR for i in range(8)]
D0 = 0.44
BEAT = BAR / 4
PENT = [392.0, 440.0, 493.9, 587.3, 659.3, 784.0, 880.0]  # Sol majör pentatonik (müzikle aynı ton)

song = sfx.load_music(ROOT.parent / "From Sad to Bright.mp3", FF)
music = sfx.splice(song, [(0, D0 + 2 * BAR), (6 * BAR, D0 + 27 * BAR)]) * 0.9
_end, _fade = int(sfx.SR * DURATION), int(sfx.SR * 0.3)
music[_end - _fade:_end] *= np.linspace(1, 0, _fade)[:, None]
music[_end:] = 0

T = sfx.Track(DURATION)
rng = np.random.default_rng(4)


def words(at, n, step=0.15, pitch=700, gain=0.45):
    for i in range(n):
        T.add(at + i * step, sfx.pop(pitch + i * 90), gain)


# ---- SORUN (ölçü 0–1): yağmur, yumuşak pop'lar, üç ✗, hüzünlü womp ----
for k in range(int(S[2] / 0.13)):
    T.add(0.05 + k * 0.13 + rng.random() * 0.05, sfx.tick(2400 + rng.integers(0, 900), 0.015), 0.1)
words(0.3, 5, 0.16, 480, 0.3)
T.add(0.8, sfx.blop(250, 0.16), 0.4)
words(S[1] + 0.2, 5, 0.16, 480, 0.3)
for i in range(3):
    T.add(S[1] + BEAT * (i + 1) + 0.05, sfx.thud(0.14, 110), 0.7)
    T.add(S[1] + BEAT * (i + 1) + 0.05, sfx.tick(900, 0.04), 0.5)
T.add(S[1] + 1.15, sfx.womp(), 0.6)

# ---- DÜŞÜŞ (ölçü 2 başı): yükselen geçiş, patlama ----
T.add(S[2] - 0.78, sfx.whoosh(0.85, 200, 5500, seed=2), 1.0)
T.add(S[2], sfx.thud(0.3, 90), 1.0)
T.add(S[2], sfx.boing(0.4, 300), 0.6)
T.add(S[2] + 0.02, sfx.sparkle(0.6, 11), 0.5)
T.add(S[2] + 0.02, sfx.chime((392.0, 493.9, 587.3, 784.0)), 0.3)

# ---- ÇÖZÜM ----
for i in range(3, 7):
    T.add(S[i] - 0.08, sfx.whoosh(0.5, 300, 3200, seed=i), 0.6)
# ölçü 2: "Çözüm: Zibo!", yıldızlar, etiket
words(S[2] + 0.25, 2, 0.2, 760, 0.55)
for k in range(6):
    T.add(S[2] + 0.3 + k * 0.08, sfx.bell(PENT[k % 7] * 2, 0.2), 0.2)
T.add(S[2] + 0.75, sfx.blop(480), 0.7)
# ölçü 3: hedefler tek tek işaretlenir, coin
words(S[3] + 0.2, 4, 0.15)
T.add(S[3] + 0.35, sfx.blop(420, 0.14), 0.6)
for k in range(3):
    T.add(S[3] + BEAT * (k + 1), sfx.pop(800), 0.7)
    T.add(S[3] + BEAT * (k + 1) + 0.02, sfx.bell(PENT[k * 2] * 2, 0.3), 0.4)
T.add(S[3] + 1.75, sfx.coin(), 1.0)
T.add(S[3] + 1.9, sfx.blop(540), 0.6)
# ölçü 4: seri sayacı + rozetler
words(S[4] + 0.2, 4, 0.15)
for k in range(3):
    T.add(S[4] + 0.3 + k * 0.17, sfx.blop(PENT[k] * 0.8, 0.12), 0.7)
T.add(S[4] + 0.75, sfx.blop(500), 0.6)
for n in range(2, 8):  # sayaç 1→7: eOut eğrisinin her basamak geçişinde tık
    p = 1 - (1 - (n - 1.5) / 6) ** (1 / 3)
    T.add(S[4] + 0.5 + 1.5 * p, sfx.tick(1200 + n * 130, 0.03), 0.5)
T.add(S[4] + 1.95, sfx.bell(PENT[4], 0.5), 0.5)
# ölçü 5: oyunlar, coin, takas
words(S[5] + 0.2, 6, 0.15)
for k in range(3):
    T.add(S[5] + 0.35 + k * 0.13, sfx.blop(PENT[k * 2] * 0.75, 0.12), 0.7)
T.add(S[5] + 0.7, sfx.coin(), 0.9)
T.add(S[5] + 1.1, sfx.blop(520), 0.7)
T.add(S[5] + 1.3, sfx.sparkle(0.5, 6), 0.4)
# ölçü 6: ikon, konfeti, logo, buton, SON VURUŞ (şarkının son akoru ≈ ölçü 6 + 1,63)
T.add(S[6] + 0.1, sfx.blop(340, 0.18), 0.9)
T.add(S[6] + 0.15, sfx.party(), 0.8)
T.add(S[6] + 0.35, sfx.blop(460), 0.7)
T.add(S[6] + 0.7, sfx.pop(760), 0.5)
T.add(S[6] + 1.09, sfx.blop(560), 0.8)
T.add(S[6] + 1.4, sfx.pop(900), 0.4)
T.add(S[6] + 1.63, sfx.chime((392.0, 493.9, 587.3, 784.0)), 0.5)
T.add(S[6] + 1.63, sfx.sparkle(0.5, 12), 0.4)

wav = OUT / "v04_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v04_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v04_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", f"{DURATION:.3f}",
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
