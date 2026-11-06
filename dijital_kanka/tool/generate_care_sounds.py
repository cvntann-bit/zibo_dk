"""Zibo'nun Evi bakım ses efektlerini sentezler (lisans gerektirmez).

Çıktı: assets/sounds/care_*.wav (44.1 kHz, 16-bit, mono, tepe ~0.35 —
mevcut UI sesleriyle aynı yükseklikte). Kullanıcı 2026-11-06'da "kodla üret"
dedi; telefonda dinlenip beğenilmeyen ses buradan yeniden ayarlanır.

Çalıştır (dijital_kanka/ içinde):  python tool/generate_care_sounds.py
"""

import os

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
rng = np.random.default_rng(7)


def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=.004, release=None, decay=None):
    """Kısa atak + üstel sönüm (decay sn) ya da doğrusal bırakma."""
    e = np.ones(n)
    a = max(1, int(SR * attack))
    e[:a] = np.linspace(0, 1, a)
    if decay is not None:
        e[a:] *= np.exp(-np.arange(n - a) / (SR * decay))
    if release is not None:
        r = max(1, int(SR * release))
        e[-r:] *= np.linspace(1, 0, r)
    return e


def band(x, lo, hi, order=4):
    sos = butter(order, [lo, hi], btype='band', fs=SR, output='sos')
    return sosfilt(sos, x)


def sweep(f0, f1, sec, curve=1.0):
    t = t_axis(sec)
    f = f0 + (f1 - f0) * (t / sec) ** curve
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def bell(freq, sec, decay):
    t = t_axis(sec)
    tone = np.sin(2 * np.pi * freq * t) + .35 * np.sin(2 * np.pi * freq * 2.01 * t) + .12 * np.sin(2 * np.pi * freq * 3.98 * t)
    return tone * env(len(t), attack=.003, decay=decay)


def place(buf, clip, at):
    i = int(SR * at)
    buf[i:i + len(clip)] += clip[:max(0, len(buf) - i)]


def save(name, x, peak=.35):
    x = x - np.mean(x)
    fade = int(SR * .006)
    x[-fade:] *= np.linspace(1, 0, fade)
    x = x / (np.abs(x).max() + 1e-9) * peak
    wavfile.write(os.path.join(OUT, f'care_{name}.wav'), SR, (x * 32767).astype(np.int16))
    print(f'care_{name}.wav  {len(x) / SR:.2f}s')


# Odalar arası zıplama: yumuşak "boing" (yükselen perde + titreşim).
def hop():
    sec = .2
    t = t_axis(sec)
    f = 240 + 380 * (1 - np.exp(-t / .03)) + 18 * np.sin(2 * np.pi * 28 * t) * np.exp(-t / .08)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), attack=.002, decay=.07)
    x += .25 * np.sin(2 * np.pi * 2 * np.cumsum(f) / SR) * env(len(t), attack=.002, decay=.04)
    return x


# Yemek tabağa gelir: seramik "tın".
def plate():
    x = bell(2093, .45, .09) + .6 * bell(3136, .45, .06) + .3 * bell(5274, .45, .03)
    click = band(rng.standard_normal(int(SR * .01)), 2000, 9000) * env(int(SR * .01), attack=.0005, decay=.002)
    place(x, click * .8, 0)
    return x


# Çiğneme: iki "hırş" (bant geçiren gürültü) + tok vuruş.
def chomp():
    sec = .5
    x = np.zeros(int(SR * sec))
    for at, gain in ((0, 1), (.2, .8)):
        n = int(SR * .11)
        crunch = band(rng.standard_normal(n), 900, 4200) * env(n, attack=.003, decay=.03)
        # Çıtırtı: rastgele kısa tıklar.
        for _ in range(6):
            k = rng.integers(0, n - 200)
            crunch[k:k + 120] += band(rng.standard_normal(120), 2500, 8000) * .7
        thump = np.sin(2 * np.pi * 130 * t_axis(.09)) * env(int(SR * .09), attack=.002, decay=.025)
        place(x, crunch * gain, at)
        place(x, thump * .6 * gain, at)
    return x


# Köpük: kısa yükselen "blup" (3 çeşit, rastgele çalınır).
def bubble(f0, f1, sec):
    x = sweep(f0, f1, sec, curve=2.2) * env(int(SR * sec), attack=.002, decay=sec / 2.5)
    pad = np.zeros(int(SR * .03))
    return np.concatenate([x, pad])


# Duş: yumuşak su sesi (yüksek bantlı gürültü, hafif dalgalanma) + damlacıklar.
def shower():
    sec = 1.7
    n = int(SR * sec)
    t = t_axis(sec)
    hiss = band(rng.standard_normal(n), 1800, 9000, order=2)
    hiss *= .8 + .2 * np.sin(2 * np.pi * 5.5 * t + rng.random() * 6)
    e = np.ones(n)
    a, r = int(SR * .12), int(SR * .45)
    e[:a] = np.linspace(0, 1, a)
    e[-r:] = np.linspace(1, 0, r) ** 2
    x = hiss * e * .5
    for _ in range(14):
        at = rng.uniform(.05, sec - .3)
        place(x, .25 * bubble(rng.uniform(900, 1300), rng.uniform(1800, 2600), .03)[:int(SR * .04)], at)
    return x


# Tertemiz: parlak çan arpeji (Do-Mi-Sol-Do).
def sparkle():
    sec = 1.0
    x = np.zeros(int(SR * sec))
    for i, f in enumerate((1047, 1319, 1568, 2093)):
        place(x, bell(f, .6, .16) * (.8 + i * .07), i * .07)
    shimmer = band(rng.standard_normal(int(SR * .5)), 6000, 12000) * env(int(SR * .5), attack=.05, decay=.12)
    place(x, shimmer * .15, .2)
    return x


def switch_click():
    n = int(SR * .012)
    return band(rng.standard_normal(n), 1500, 7000) * env(n, attack=.0005, decay=.0025)


# Işığı kapat: şalter tıkı + yumuşak inen ninni notaları (Sol → Mi → Do).
def lights_off():
    x = np.zeros(int(SR * 1.1))
    place(x, switch_click(), 0)
    for i, f in enumerate((784, 659, 523)):
        place(x, bell(f, .6, .22) * .55, .08 + i * .17)
    return x


# Işığı aç: şalter tıkı + yükselen notalar (Do → Mi → Sol).
def lights_on():
    x = np.zeros(int(SR * .9))
    place(x, switch_click(), 0)
    for i, f in enumerate((523, 659, 784)):
        place(x, bell(f, .5, .14) * .55, .06 + i * .1)
    return x


if __name__ == '__main__':
    save('hop', hop(), peak=.28)
    save('plate', plate(), peak=.25)
    save('chomp', chomp(), peak=.35)
    save('bubble1', bubble(380, 1150, .045), peak=.22)
    save('bubble2', bubble(460, 1400, .04), peak=.22)
    save('bubble3', bubble(320, 980, .05), peak=.22)
    save('shower', shower(), peak=.3)
    save('sparkle', sparkle(), peak=.32)
    save('lights_off', lights_off(), peak=.3)
    save('lights_on', lights_on(), peak=.3)
