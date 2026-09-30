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


def womp(dur=0.55, f0=330, f1=170):
    """Hüzünlü 'womp' — alçalan, hafif titreyen tını (sorun anları için)."""
    t = _t(dur)
    f = (f0 + (f1 - f0) * (t / dur) ** 0.8) * (1 + 0.03 * np.sin(2 * np.pi * 6 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return _fade((np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.25 * np.sin(3 * ph)) * np.exp(-t * 3.2) * 0.6, 0.01, 0.05)


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
        b = bell(rng.choice([1975.5, 2349.3, 2637, 3136, 3520, 3951]), 0.22) * 0.5
        at = int(SR * (i * dur / 9 + rng.random() * 0.02))
        out[at:at + len(b)] += b[:len(out) - at]
    return out


def chime(notes=(392.0, 493.9, 587.3, 784.0), step=0.09, dur=1.4):
    """Kapanış — yukarı çıkan majör arpej (varsayılan: Sol majör)."""
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

    def write(self, path, music=None, sfx_gain=1.0, peak=0.89):
        """WAV yazar. `music` verilirse (N,2) stereo yatak olarak efektlerin altına karıştırılır."""
        n = len(self.buf)
        mix = np.zeros((n, 2))
        if music is not None:
            m = music[:n]
            mix[:len(m)] += m
        mix += (self.buf * sfx_gain)[:, None]
        mix = np.tanh(mix * 0.95)  # yumuşak sınırlayıcı
        mix = mix / np.max(np.abs(mix)) * peak
        with wave.open(str(path), "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((mix * 32767).astype("<i2").tobytes())
        return float(np.sqrt(np.mean(mix ** 2)))


def load_music(path, ffmpeg):
    """Herhangi bir ses dosyasını (mp3/wav) 44,1 kHz stereo float dizisine çevirir."""
    import subprocess
    raw = subprocess.run([ffmpeg, "-loglevel", "error", "-i", str(path), "-f", "s16le",
                          "-ac", "2", "-ar", str(SR), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype="<i2").astype(float).reshape(-1, 2) / 32768


def splice(song, parts, xfade=0.04):
    """Şarkıdan [(video_başlangıcı, şarkı_başlangıcı), ...] parçalarını uç uca ekler.

    Parçalar arası kısa çapraz geçiş yapılır; kesim noktaları ölçü başına denk getirilirse
    ek yeri duyulmaz. Son parça şarkının sonuna kadar sürer.
    """
    total = int(SR * (parts[-1][0])) + max(0, len(song) - int(SR * parts[-1][1]))
    out = np.zeros((total, 2))
    nx = int(SR * xfade)
    for j, (v0, s0) in enumerate(parts):
        a = int(SR * v0)
        b = int(SR * parts[j + 1][0]) if j + 1 < len(parts) else total
        seg = song[int(SR * s0) - (nx if j else 0):int(SR * s0) + (b - a) + (nx if j + 1 < len(parts) else 0)].copy()
        if j:
            seg[:2 * nx] *= np.linspace(0, 1, 2 * nx)[:, None]
        else:
            seg[:int(SR * 0.01)] *= np.linspace(0, 1, int(SR * 0.01))[:, None]
        if j + 1 < len(parts):
            seg[-2 * nx:] *= np.linspace(1, 0, 2 * nx)[:, None]
        at = a - (nx if j else 0)
        out[at:at + len(seg)] += seg[:total - at]
    return out
