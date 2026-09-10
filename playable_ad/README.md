# Zibo — Playable Ad

`zibo_playable.html` — tek dosya, self-contained (~570 KB), sıfır dış kaynak.
Kullanıcı 3 hızlı mini-görevle ("su ver • şükret • hedefi işaretle") yorgun
Zibo'yu neşelendirir; sahneye renk/güneş gelir, coinler uçar, halka dolar →
"Seviye 2" + konfeti + **ÜCRETSİZ İNDİR** end-card'ı. Dokunulmasa bile
otomatik ilerleyip end-card'a ulaşır (ağ zorunluluğu).

## Yeniden üretme

```
cd dijital_kanka
dart run tool/prep_playable_assets.dart   # Zibo görsellerini küçültür -> tool/playable_assets.txt
dart run tool/build_playable.dart          # tool/playable_template.html + assets -> playable_ad/zibo_playable.html
```

Metin / görsel / akış değişikliği → `tool/playable_template.html`'i düzenle, `build_playable.dart`'ı tekrar çalıştır.

## Ağlara yükleme

| Ağ | Nereye | Boyut sınırı | Not |
|---|---|---|---|
| **AppLovin** (Discovery/AXON) | Creative Sets → Add Creative → Playable → HTML upload | 5 MB | `mraid.open` destekli. |
| **Unity Ads** | Campaigns → Creative Pack → Playable → upload `.html` | 5 MB | `ExitApi.exit()` fallback var. |
| **ironSource / LevelPlay** | Assets → Playables → upload | 5 MB | `dapi.openStoreUrl()` fallback var. |
| **Meta** | Ads Manager → Playable Source → upload | 2 MB | `FbPlayableAd.onCTAClick()` fallback var. `<570 KB` sığar. |
| **Moloco / TikTok** | Playable/interactive asset upload | 2–5 MB | Genel `mraid.open` + `window.open` fallback. |

CTA / mağaza linki: `https://play.google.com/store/apps/details?id=com.dijitalkanka.dijital_kanka`
(değişirse `tool/playable_template.html` içindeki `STORE` sabiti + `build` tekrar).

## Yerelde test

```
cd playable_ad
python3 -m http.server 8000   # veya herhangi bir statik sunucu
# tarayıcıda http://localhost:8000/zibo_playable.html  (mobil viewport ile bak)
```
`file://` ile açma — bazı tarayıcılar data-URI görsellerini/JS'i kısıtlar.

## Bilinen sınırlar

- Zibo görselleri 3D render, PNG'de iyi sıkışmıyor (~95 KB/adet). `img.quantize`
  ALFA'yı bozuyor (siyah kutu) — bu yüzden sadece resize + max-level PNG.
  Daha küçük istenirse harici bir araçla (pngquant/cwebp) alfa-korumalı sıkıştır.
- Tek dil (TR). EN/ES varyantı için `playable_template.html`'i kopyalayıp
  metinleri çevir, ayrı `zibo_playable_en.html` üret.
