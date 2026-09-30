"""Bir müzik dosyasının temposunu, vuruş/ölçü fazını, tonunu ve ses zarfını ölçer.

Kullanım (repo kökünden):  python promo_video/analyze.py "promo_video/Şarkı.mp3"
Çıkan değerler videonun sahne sürelerini ve sound.py'deki BEAT0/BAR/splice noktalarını
belirlemek için kullanılır (kulakla değil ölçümle — bkz. v01/sound.py).
"""
import sys

import imageio_ffmpeg
import numpy as np

sys.path.insert(0, __file__.rsplit("analyze.py", 1)[0])
import sfx  # noqa: E402

x = sfx.load_music(sys.argv[1], imageio_ffmpeg.get_ffmpeg_exe()).mean(axis=1)
sr = sfx.SR
print(f"süre {len(x) / sr:.2f} sn")

hop, win = 512, 2048
fr = np.lib.stride_tricks.sliding_window_view(x, win)[::hop]
S = np.abs(np.fft.rfft(fr * np.hanning(win), axis=1))
flux = np.maximum(0, np.diff(np.log1p(S * 50), axis=0)).sum(1)
flux = (flux - flux.mean()) / flux.std()
fps = sr / hop
t = np.arange(len(flux)) / fps

# tempo: onset zarfının otokorelasyonu (70–180 bpm)
n = min(len(flux), int(60 * fps))
ac = np.correlate(flux[:n], flux[:n], "full")[n - 1:]
cands = []
for bpm in np.arange(70, 180.01, 0.25):
    lag = 60 / bpm * fps
    cands.append((sum(ac[int(round(k * lag))] for k in (1, 2, 4)), bpm))
cands.sort(reverse=True)
print("tempo adayları:", [(float(b), int(v)) for v, b in cands[:5]])
bpm = cands[0][1]
per = 60 / bpm


def phase(seg, period, steps):
    return max(steps, key=lambda p: seg[np.clip(np.round(np.arange(p, len(seg) / fps, period) * fps).astype(int), 0, len(seg) - 1)].sum())


for a in range(0, int(len(x) / sr) - 9, 10):
    seg = flux[int(a * fps):int((a + 10) * fps)]
    ph = phase(seg, per, np.arange(0, per, 0.005))
    print(f"  {a:3d}-{a + 10} sn vuruş fazı (mod {per:.3f}): {(a + ph) % per:.3f}")
ph = phase(flux, per, np.arange(0, per, 0.005))
low = np.maximum(0, np.diff(S[:, :8].sum(1)))
bars = sorted(((low[np.clip(np.round(np.arange(p, len(low) / fps, per * 4) * fps).astype(int), 0, len(low) - 1)].sum(), round(float(p), 3))
               for p in ph + per * np.arange(4)), reverse=True)
print(f"bpm {bpm}  vuruş {per:.3f} sn  ölçü {per * 4:.3f} sn  ilk vuruş {ph:.3f}")
print("ölçü başı adayları (güç, faz):", [(int(v), p) for v, p in bars])

# ton (Krumhansl profilleri)
big = np.lib.stride_tricks.sliding_window_view(x, 8192)[::4096]
P = (np.abs(np.fft.rfft(big * np.hanning(8192), axis=1)) ** 2).sum(0)
f = np.fft.rfftfreq(8192, 1 / sr)
ch = np.zeros(12)
for i in range(1, len(f)):
    if 60 < f[i] < 2000:
        ch[int(round(12 * np.log2(f[i] / 261.63))) % 12] += P[i]
N = "C C# D D# E F F# G G# A A# B".split()
maj = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
mnr = np.array([6.33, 2.68, 3.52, 5.38, 2.6, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
keys = sorted([(np.corrcoef(np.roll(maj, k), ch)[0, 1], N[k] + " majör") for k in range(12)]
              + [(np.corrcoef(np.roll(mnr, k), ch)[0, 1], N[k] + " minör") for k in range(12)], reverse=True)
print("ton adayları:", [(k, round(float(v), 2)) for v, k in keys[:3]])

# ses zarfı (0,5 sn'lik RMS) — sessizlik/bitiş/geçiş yerlerini görmek için
h = sr // 2
rms = [round(float(np.sqrt(np.mean(x[i * h:(i + 1) * h] ** 2))), 2) for i in range(len(x) // h)]
for i in range(0, len(rms), 20):
    print(f"  rms {i / 2:5.1f} sn:", rms[i:i + 20])
