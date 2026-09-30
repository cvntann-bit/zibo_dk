"""Şarkının bir bölümünde vuruş ızgarasını ince ayarla (analyze.py'nin kaba temposundan sonra).

Kullanım:  python promo_video/beatgrid.py "promo_video/Şarkı.mp3" <başlangıç_sn> <bitiş_sn> <bpm_alt> <bpm_üst>
Çıktı: o bölümde en iyi oturan bpm + ilk vuruş zamanı, ve vuruş başına kick (pes) gücü —
ölçü başını (her 4 vuruşta bir en güçlü) görmek için.
"""
import sys

import imageio_ffmpeg
import numpy as np

sys.path.insert(0, __file__.rsplit("beatgrid.py", 1)[0])
import sfx  # noqa: E402

path, a, b, lo, hi = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5])
x = sfx.load_music(path, imageio_ffmpeg.get_ffmpeg_exe()).mean(axis=1)
sr = sfx.SR
x = x[int(a * sr):int(b * sr)]
hop, win = 256, 1024
fr = np.lib.stride_tricks.sliding_window_view(x, win)[::hop]
S = np.abs(np.fft.rfft(fr * np.hanning(win), axis=1))
flux = np.maximum(0, np.diff(np.log1p(S * 50), axis=0)).sum(1)
flux = (flux - flux.mean()) / flux.std()
low = np.maximum(0, np.diff(S[:, :5].sum(1)))
fps = sr / hop
dur = len(flux) / fps


def score(env, per, ph):
    idx = np.round(np.arange(ph, dur, per) * fps).astype(int)
    idx = idx[idx < len(env)]
    return env[idx].mean(), idx


best = max(((score(flux, 60 / bpm, ph)[0], bpm, ph) for bpm in np.arange(lo, hi + 1e-9, 0.02)
            for ph in np.arange(0, 60 / bpm, 0.004)), key=lambda r: r[0])
_, bpm, ph = best
per = 60 / bpm
print(f"bölüm {a}-{b} sn: bpm {bpm:.2f}  vuruş {per:.4f} sn  ilk vuruş {a + ph:.3f} sn (puan {best[0]:.2f})")
_, idx = score(low, per, ph)
k = low[idx]
print("vuruş başına pes güç (4'lü gruplar):")
for i in range(0, min(len(k), 48), 4):
    print(f"  {a + ph + i * per:7.3f} sn:", [int(v) for v in k[i:i + 4]])
for off in range(4):
    print(f"  ölçü fazı +{off} vuruş ({a + ph + off * per:.3f} sn): toplam {int(k[off::4].sum())}")
