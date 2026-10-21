"""Flutter web (flutter run -d web-server --web-port 8790 -t lib/web_capture_main.dart) uygulamasından YÜKSEK ÇÖZÜNÜRLÜKLÜ ekran görüntüleri alır
(Playwright + yüklü Chrome, 412x915 görünüm, deviceScaleFactor=3 → 1236x2745 PNG). Telefon gerekmez.

Test durumu localStorage'a yazılır (Flutter web shared_preferences = `flutter.<anahtar>` → JSON-string):
onboarding bitti, ad "Zibo", 1450 ZC, tüm kostümler sahipli, "reklamsız" (Appodeal banner web'de çalışmıyor → Ana Sayfa'yı bozuyor).
Bu veri yalnızca bu tarayıcı oturumunda yaşar; gerçek hesaba dokunmaz.

Kullanım (dijital_kanka/ içinden):  python tool/store_capture_web.py <çıktı_klasörü> [liste|<senaryo>...]
"""
import json
import os
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

URL = "http://localhost:8790"
ALL = ["zibo_" + x for x in "hippi sporcu chef ogrenci asker hoca artist kovboy punk rapci gentleman samurai gladyator korsan cyborg astronot buyucu ninja king zombi firavun viking altin anime ejder_ruhu galaksi elmas".split()]


# 9 sahipli kostüm: 10 ve üzeri "Moda İkonu/Tam Gardırop" rozet pencerelerini tetikler (her açılışta çıkar).
OWNED = ["zibo_" + x for x in "hippi sporcu chef ogrenci artist kovboy buyucu king firavun viking anime ejder_ruhu galaksi altin".split()]
LANG = os.environ.get("LANG_CODE", "tr")
BADGES = {b: {"earnedAt": "2026-10-01T10:00:00.000", "claimed": True} for b in ("collector", "fashion_icon")}


def init_script(equipped=None, keys=None):
    state = {
        "onboardingState": {"completed": True},
        "profileState": {"name": "Zibo"},
        "adFreeState": {"isAdFree": True},
        "languageCode": {"value": LANG},
        "badgeState": {"earned": BADGES},
                "coinState": {"balance": 1450, "totalEarned": 1450, "totalSpent": 0, "transactions": []},
        "costumeState": {"ownedIds": OWNED, "equippedId": equipped},
    }
    if keys: state = {k: v for k, v in state.items() if k in keys}
    js = "".join(f"localStorage.setItem('flutter.{k}', {json.dumps(json.dumps(json.dumps(v)))});" for k, v in state.items())
    return js


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    mode = sys.argv[2] if len(sys.argv) > 2 else "liste"
    with sync_playwright() as p:
        b = p.chromium.launch(channel="chrome", headless=False, args=["--window-position=0,0"])
        ctx = b.new_context(viewport={"width": 412, "height": 915}, device_scale_factor=int(os.environ.get("DSF","3")), locale=LANG)
        ctx.add_init_script(init_script(keys=os.environ.get('KEYS','').split(',') if os.environ.get('KEYS') else None))
        page = ctx.new_page()
        page.on('console', lambda m: print('[console]', m.type, m.text[:1500]) if m.type in ('error','warning','log') else None)
        page.on('framenavigated', lambda f: print('[NAV]', f.url))
        page.on('crash', lambda: print('[CRASH]'))
        page.on('pageerror', lambda e: print('[pageerror]', str(e)[:300]))
        page.goto(URL)
        page.wait_for_timeout(int(os.environ.get("WAIT_MS", "25000")))
        page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        page.wait_for_timeout(1500)
        def labels():
            return page.evaluate("""() => [...document.querySelectorAll('flt-semantics')].map(e => (e.getAttribute('aria-label') || e.innerText || '').trim().split(String.fromCharCode(10)).join(' / ').slice(0, 50)).filter(Boolean)""")

        def tap(text, nth=0):
            loc = page.locator('flt-semantics[role="button"]', has_text=text)
            if loc.count() == 0:
                loc = page.locator("flt-semantics", has_text=text)
            box = loc.nth(nth).bounding_box()
            page.mouse.click(box["x"] + box["width"] / 2, box["y"] + box["height"] / 2)
            page.wait_for_timeout(1600)

        def tap_xy(x, y):
            page.mouse.click(x, y)
            page.wait_for_timeout(1600)

        def shot(name):
            page.wait_for_timeout(700)
            page.screenshot(path=str(out / f"{name}.png"))
            print("shot", name)

        def dismiss():
            page.wait_for_timeout(2500)   # kutlama pencereleri yüklemeden kısa süre sonra çıkar
            for _ in range(6):
                ls = labels()
                if any("Ödülü Al" in t for t in ls):
                    tap("Ödülü Al")
                else:
                    break

        if mode == "liste":
            dismiss()
            for t in labels():
                print(" -", t)
            shot("_ilk")
        else:
            # Alt bar / Z / Rozetler kutusu konumları dil bağımsız (etiketler dile göre değişir → koordinat).
            NAV = {"ana": (44, 888), "oyun": (130, 888), "profil": (281, 888), "magaza": (368, 888), "z": (206, 836)}
            page.wait_for_timeout(2500)
            shot("ana_sayfa")
            tap_xy(366, 242); shot("rozetler")       # Rozetler kutusu
            tap_xy(26, 29)                           # Geri
            tap_xy(*NAV["oyun"]); shot("oyun_salonu")
            tap_xy(*NAV["profil"]); shot("profil")
            tap_xy(*NAV["magaza"]); shot("magaza_coin")
            tap_xy(160, 138)                         # Kostümler (alt sekmeler tek a11y düğümü)
            names = {"tr": ("Yaygın", "Nadir", "Epik"), "en": ("Common", "Rare", "Epic"), "es": ("Común", "Raro", "Épico")}[LANG]
            for g in names:
                tap(g + " ·")
            page.mouse.move(206, 500)
            page.mouse.wheel(0, 300)
            page.wait_for_timeout(800)
            shot("magaza_kostumler")
            page.mouse.wheel(0, -1500)
            page.wait_for_timeout(700)
            tap_xy(253, 138); shot("magaza_temalar")
            tap_xy(347, 138); shot("magaza_pro")
            tap_xy(*NAV["ana"])
            tap_xy(*NAV["z"]); shot("modul_menusu")
        b.close()


if __name__ == "__main__":
    main()
