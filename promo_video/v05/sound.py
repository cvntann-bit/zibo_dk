"""v05 "Yalnız değilsin" animasyon reklamı için ses kurgusu.

Çalıştır (repo kökünden):  python promo_video/v05/sound.py [en|es]
Önce `python promo_video/render.py v05 [--lang ..]` ile sessiz MP4'ler üretilmiş olmalı.

Müzik: promo_video/From Sad to Bright.mp3 (Suno) — 109,98 bpm, ilk ölçü başı 0,44 sn. Sahne
sınırları ölçülere hizalı (S = [0, D0 + 2k·BAR]); sad→bright geçişi 9,17. sn'de (S[2]).
Efekt zamanları index.html'deki olaylarla birebir aynı. Sesler kodla sentezlenir (telif yok).
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
D0 = 0.44
S = [0.0] + [D0 + k * BAR for k in range(2, 15, 2)]
END = S[7]
DURATION = END
PENT = [587.3, 659.3, 784.0, 880.0, 987.8, 1174.7, 1318.5]  # Sol majör pentatonik (müzikle aynı ton)

# Müzik: ilk END saniye, sonda 0,9 sn fade-out
song = sfx.load_music(ROOT.parent / "From Sad to Bright.mp3", FF)
n = int(sfx.SR * END)
music = song[:n].copy()
fade = np.linspace(1, 0, int(sfx.SR * 0.9))
music[-len(fade):] *= fade[:, None]
music *= 0.8

T = sfx.Track(DURATION)


def words(t0, count, step):
    """Başlık kelimelerinin tek tek 'pop' etmesi."""
    for i in range(count):
        T.add(t0 + i * step, sfx.pop(640 + (i % 4) * 110), 0.5)


# Sahne geçişleri: kısa "svuş" + beyaz flaş anı
for s in S[1:-1]:
    T.add(s - 0.05, sfx.whoosh(0.6, seed=int(s * 10)), 0.75)

# ── 0: KANCA — "Kaç alışkanlığı 3. günde bıraktın?" + sorun listesi, damlalar
words(0.15, 5, 0.18)
T.add(0.6, sfx.womp(0.5, 260, 150), 0.45)  # sarsıntı (üzgün)
for i in range(3):
    T.add(0.9 + i * 0.3, sfx.blop(380 + i * 40, 0.14), 0.7)   # satır belirir
    T.add(1.9 + i * 0.35, sfx.thud(0.12, 150), 0.55)           # × damgası
    T.add(1.9 + i * 0.35, sfx.tick(900, 0.05), 0.4)
for i in range(10):                                            # yağmur damlası
    T.add(0.2 + i * 0.45, sfx.tick(2200 + (i % 3) * 300, 0.02), 0.12)

# ── 1: SORUN — "Sorun sen değilsin. Yalnız olman."
t1 = S[1]
words(t1 + 0.1, 4, 0.2)
T.add(t1 + 0.6, sfx.womp(0.6, 300, 180), 0.4)
for i in range(6):
    T.add(t1 + 0.5 + i * 0.4, sfx.tick(1800 - i * 60, 0.03), 0.15)  # yağmur devam

# ── 2: SELAM + SU — balonlar, bardak dolar, sıçrama
t2 = S[2]
T.add(t2 + 0.25, sfx.blop(520, 0.16), 0.8)     # balon 1
T.add(t2 + 1.7, sfx.blop(470, 0.16), 0.8)      # balon 2
T.add(t2 + 2.9, sfx.boing(0.35, 330), 0.6)     # bardak belirir
for i in range(14):                            # su dolarken tıkırtı yükselir
    T.add(t2 + 3.2 + i * 0.08, sfx.tick(900 + i * 60, 0.03), 0.35)
T.add(t2 + 4.3, sfx.sparkle(0.5, 9), 0.5)      # sıçrama
T.add(t2 + 3.3, sfx.party(seed=9), 0.35)

# ── 3: KÜÇÜK ADIMLAR — 4 kart, konfeti
t3 = S[3]
words(t3 + 0.1, 4, 0.18)
for i in range(4):
    T.add(t3 + 0.4 + i * 0.25, sfx.pop(700 + i * 90), 0.7)     # kart belirir
    T.add(t3 + 0.4 + i * 0.25, sfx.blop(PENT[i] * 0.8, 0.1), 0.35)
T.add(t3 + 1.3, sfx.party(seed=33), 0.7)                        # konfeti
T.add(t3 + 1.3, sfx.chime((523.3, 659.3, 784.0, 1046.5), 0.08, 0.9), 0.35)

# ── 4: BÜYÜR — kostüm değişimleri (her 0,95 sn), halka vurguları
t4 = S[4]
words(t4 + 0.1, 3, 0.18)
for k in range(4):
    tk = t4 + k * 0.95
    if k:
        T.add(tk - 0.04, sfx.whoosh(0.3, 500, 2600, seed=k), 0.45)
    T.add(tk + 0.02, sfx.pop(620 + (k % 3) * 120), 0.7)
    T.add(tk + 0.02, sfx.bell(PENT[k + 2] * 2, 0.22), 0.3)
T.add(t4 + 3.8, sfx.sparkle(0.5, 4), 0.4)

# ── 5: YARIN YİNE — el sallama, son vurgu
t5 = S[5]
words(t5 + 0.1, 3, 0.2)
T.add(t5 + 0.7, sfx.boing(0.4, 300), 0.5)
for i in range(4):
    T.add(t5 + 1.2 + i * 0.22, sfx.blop(PENT[i + 1] * 0.8, 0.1), 0.45)  # üç el sallama tıkı

# ── 6: SON — logo (zil), konfeti, buton ("Ücretsiz indir")
t6 = S[6]
T.add(t6 + 0.05, sfx.blop(360, 0.2), 0.9)
T.add(t6 + 0.1, sfx.bell(PENT[0] * 2, 0.9), 0.4)
T.add(t6 + 0.25, sfx.party(seed=44), 0.9)
T.add(t6 + 1.4, sfx.coin(), 0.9)
T.add(t6 + 1.4, sfx.sparkle(0.45, 8), 0.35)
T.add(t6 + 2.6, sfx.chime((523.3, 659.3, 784.0, 1046.5), 0.09, 1.4), 0.45)

wav = OUT / "v05_mix.wav"
print("RMS", round(T.write(wav, music=music, sfx_gain=1.0), 3))
SUFFIX = f"_{sys.argv[1]}" if len(sys.argv) > 1 else ""
for label in ("9x16", "16x9"):
    src = OUT / f"zibo_v05_{label}{SUFFIX}.mp4"
    dst = OUT / f"zibo_v05_{label}{SUFFIX}_sesli.mp4"
    subprocess.run([FF, "-y", "-loglevel", "error", "-i", str(src), "-i", str(wav),
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", f"{DURATION:.3f}",
                    "-movflags", "+faststart", str(dst)], check=True)
    print("OK", dst.name)
