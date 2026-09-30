"""Zibo tanıtım videolarını kare kare MP4'e çevirir.

Kullanım (repo kökünden):
    python promo_video/render.py v01              # 9:16 + 16:9 MP4 -> promo_video/v01/out/
    python promo_video/render.py v01 --stills 1,4,10   # yalnızca o saniyelerin PNG kareleri

Gereksinim: `pip install playwright imageio-ffmpeg` + kurulu Google Chrome.
Video sayfası `window.seek(t)`, `window.DURATION` ve `window.READY` sağlamalı
(bkz. v01/index.html) — animasyon gerçek zamana DEĞİL yalnızca `t`'ye bağlı olduğu
için çıktı takılmasız ve her çalıştırmada birebir aynı.
"""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
from playwright.sync_api import sync_playwright

FPS = 30
FORMATS = {"v": (1080, 1920, "9x16"), "h": (1920, 1080, "16x9")}


def main():
    name = sys.argv[1]
    stills = None
    if "--stills" in sys.argv:
        stills = [float(x) for x in sys.argv[sys.argv.index("--stills") + 1].split(",")]
    root = Path(__file__).parent / name
    out = root / "out"
    out.mkdir(exist_ok=True)
    url = (root / "index.html").resolve().as_uri()
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        for fmt, (w, h, label) in FORMATS.items():
            page = browser.new_page(viewport={"width": w, "height": h})
            page.goto(f"{url}?f={fmt}&cap=1")
            page.wait_for_function("window.READY === true")
            duration = page.evaluate("window.DURATION")
            if stills is not None:
                for t in stills:
                    page.evaluate(f"seek({t})")
                    page.screenshot(path=str(out / f"still_{label}_{t:05.2f}.png"))
                page.close()
                continue
            target = out / f"zibo_{name}_{label}.mp4"
            ff = subprocess.Popen(
                [imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error",
                 "-f", "image2pipe", "-framerate", str(FPS), "-c:v", "png", "-i", "-",
                 "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p",
                 "-movflags", "+faststart", str(target)],
                stdin=subprocess.PIPE)
            frames = int(duration * FPS)
            for i in range(frames):
                page.evaluate(f"seek({i / FPS})")
                ff.stdin.write(page.screenshot(type="png"))
                if i % 90 == 0:
                    print(f"{label}: {i}/{frames}", flush=True)
            ff.stdin.close()
            ff.wait()
            page.close()
            print(f"OK {target} ({target.stat().st_size / 1e6:.1f} MB)", flush=True)
        browser.close()


if __name__ == "__main__":
    main()
