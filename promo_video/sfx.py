"""Kodla üretilen (sentezlenen) çizgi film ses efektleri — telif/lisans sorunu YOK.

Her fonksiyon mono float dizisi döndürür. `Track` bunları saniye cinsinden zamanlara
yerleştirip WAV yazar. Video sahnelerindeki olay zamanları `seek(t)` ile birebir aynı
olduğu için ses kareyle tam eşleşir (bkz. v01/sound.py).
"""
import wave

import numpy as np

SR = 44100


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _sweep(f0, f1, dur, curve=1.0):
    """f0→f1 frekans kaymalı sinüs (faz birikimli, tıkırtısız)."""
    t = _t(dur)
    f = f0 + (f1 - f0) * (t / dur) ** curve
    return np.sin(2 * np.pi * np.cumsum(f) / SR), t


def _fade(x, a=0.004, r=0.01):
    n_a, n_r = int(SR * a), int(SR * r)
    x = x.copy()
    x[:n_a] *= np.linspace(0, 1, n_a)
    x[-n_r:] *= np.linspace(1, 0, n_r)
    return x


def blop(pitch=420, dur=0.13):
    """Baloncuk 'blop' — perde hızla yükselir."""
    s, t = _sweep(pitch, pitch * 2.6, dur, 0.6)
    return _fade(s * np.exp(-t * 16))


def pop(pitch=900, dur=0.07):
    """Kısa 'pop' — perde hızla düşer."""
    s, t = _sweep(pitch, pitch * 0.25, dur, 0.5)
    return _fade(s * np.exp(-t * 30), 0.001)


def tick(pitch=1500, dur=0.03):
    s, t = _sweep(pitch, pitch * 0.8, dur)
    return _fade(s * np.exp(-t * 90), 0.001, 0.004) * 0.6


def thud(dur=0.22, pitch=130):
    """Yere iniş — pes ve yumuşak."""
    s, t = _sweep(pitch, pitch * 0.4, dur, 0.5)
    return _fade(s * np.exp(-t * 14))


def boing(dur=0.45, pitch=260):
    """Yay 'boing' — titreşimli, düşen perde."""
    t = _t(dur)
    f = pitch * (1 - 0.35 * t / dur) * (1 + 0.22 * np.sin(2 * np.pi * 17 * t) * np.exp(-t * 5))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR)
    return _fade(s * np.exp(-t * 6.5))


def whoosh(dur=0.6, lo=300, hi=3800, seed=1):
    """Sahne geçişi — süpürülen filtreli gürültü."""
    n = int(SR * dur)
    noise = np.random.default_rng(seed).standard_normal(n)
    t = np.arange(n) / n
    cutoff = lo + (hi - lo) * np.sin(np.pi * t) ** 1.5
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    low = np.empty(n)
    band = np.empty(n)
    y1 = y2 = 0.0
    for i in range(n):  # iki kutuplu basit bant geçiren
        y1 += a[i] * (noise[i] - y1)
        y2 += a[i] * 0.5 * (y1 - y2)
        low[i] = y2
        band[i] = y1 - y2
    env = np.sin(np.pi * t) ** 2
    return _fade((band * 1.6 + low * 0.5) * env, 0.02, 0.05) * 0.9


def coin(dur=0.5):
    """Klasik iki notalı coin sesi (Si5 → Mi6)."""
    t = _t(dur)
    n1 = int(SR * 0.07)
    f = np.where(np.arange(len(t)) < n1, 987.8, 1318.5)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR)
    s += 0.3 * np.sin(2 * np.pi * np.cumsum(f * 2) / SR)
    return _fade(s * np.exp(-np.maximum(0, t - 0.07) * 9), 0.002, 0.03) * 0.7


def bell(pitch=880, dur=0.6):
    t = _t(dur)
    s = np.sin(2 * np.pi * pitch * t) + 0.4 * np.sin(2 * np.pi * pitch * 2.01 * t) * np.exp(-t * 9) \
        + 0.2 * np.sin(2 * np.pi * pitch * 3.0 * t) * np.exp(-t * 14)
    return _fade(s * np.exp(-t * 6), 0.002, 0.04) * 0.6


def sparkle(dur=0.5, seed=3):
    """Pırıltı — tiz, rastgele minik çanlar."""
    rng = np.random.default_rng(seed)
    out = np.zeros(int(SR * dur))
    for i in range(7):
        b = bell(rng.choice([2093, 2349, 2637, 3136, 3520, 4186]), 0.22) * 0.5
        at = int(SR * (i * dur / 9 + rng.random() * 0.02))
        out[at:at + len(b)] += b[:len(out) - at]
    return out


def chime(notes=(523.3, 659.3, 784.0, 1046.5), step=0.09, dur=1.4):
    """Kapanış — yukarı çıkan majör arpej."""
    out = np.zeros(int(SR * (dur + step * len(notes))))
    for i, f in enumerate(notes):
        b = bell(f, dur)
        at = int(SR * step * i)
        out[at:at + len(b)] += b
    return out


def party(seed=5):
    """Konfeti patlaması — kısa gürültü patlaması + pırıltı."""
    n = int(SR * 0.25)
    t = np.arange(n) / SR
    burst = np.random.default_rng(seed).standard_normal(n) * np.exp(-t * 22) * 0.5
    out = np.zeros(int(SR * 0.9))
    out[:n] += _fade(burst, 0.001)
    sp = sparkle(0.7, seed)
    out[int(SR * 0.05):int(SR * 0.05) + len(sp)] += sp[:len(out) - int(SR * 0.05)]
    return out


class Track:
    def __init__(self, duration):
        self.buf = np.zeros(int(SR * (duration + 0.5)))

    def add(self, at, sound, gain=1.0):
        i = int(SR * at)
        if i >= len(self.buf):
            return
        seg = sound[:len(self.buf) - i] * gain
        self.buf[i:i + len(seg)] += seg

    def write(self, path, peak=0.85):
        x = np.tanh(self.buf * 0.9)  # yumuşak sınırlayıcı
        x = x / np.max(np.abs(x)) * peak
        with wave.open(str(path), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((x * 32767).astype("<i2").tobytes())
        return float(np.sqrt(np.mean(x ** 2)))
