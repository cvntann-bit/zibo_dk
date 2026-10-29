# Tablet optimizasyonu — "Tabletler için tasarlandı" rozeti (2026-10-29)

Tetikleyici: kullanıcı — Zibo tablette Yaşam Tarzı'nda ilk 11'de, çocuklar çok seviyor; Pinterest'teki Google Play
"tablet için optimize edildi" ibaresini istiyor. Test cihazı: **Galaxy Tab A11+ (SM-X230), Android 16, 800×1280 dp**.

## Google'ın kuralları (araştırma, developer.android.com "Adaptive app quality guidelines", 2026-10-21)
- Rozet **otomatik değil**: Tier 2'yi (Kademe 2) karşılayıp Google'ın **başvuru formuyla** istenir
  (sayfadaki "Get your badge" → Google Form).
- **Tier 3 (hazır):** dikey+yatay, çoklu pencere, ekranı doldurma (letterbox/uyumluluk modu yok), temel klavye/fare.
- **Tier 2 (optimize — rozet için asgari):** tüm düzenler duyarlı; butonlar/alt paneller/metin alanları geniş ekranda
  tam genişlikte uzamaz; dokunma alanı ≥ 48dp; klavye gezinmesi (Tab/oklar, Esc/Enter), fare hover.
- **Tier 1:** tablete özel farklılaşma (sürükle-bırak, kalem vb.) — isteğe bağlı.
- Play Console mağaza kaydı: tablet ekran görüntüleri (7" ve 10", en az 4, 1080–7680 px, 16:9 / 9:16) — rozet şartı
  olarak yazılmamış ama vitrin için gerekli.
- Android 16 (targetSdk 36): sw ≥ 600dp ekranlarda yön/yeniden boyutlandırma kısıtları yok sayılır.

## Ölçülen başlangıç durumu (2026-10-29)
- İyi: manifest'te yön kilidi yok, tam ekran, dönüş çalışıyor (Tier 3 temeli).
- Kötü: her şey tam genişlikte uzuyordu; Mağaza coin paketleri ~900 px yükseklikte dev kartlar; yatay Ana Sayfa'nın
  yarısı boş; alt menü yatayda tüm genişliğe yayılıyordu; **oyunlar 360×640 telefon tuvali — yatayda ortada dar şerit**.

## Yapılanlar (commit 48c4382 + sonrası)
- `lib/utils/adaptive.dart`: `Adaptive` (eşikler: yan menü ≥ 1000 dp genişlik; içerik 760 dp; Ana Sayfa sütunu
  680 dp), `AdaptiveCenter`, `horizontalPadding`, `columnsFor`. Telefonda (< 700 dp) hiçbir şey değişmez.
- RootScreen: genişlik ≥ 1000 → alt bar + Z FAB yerine `MainSideRail` (Z en üstte + 4 sekme, aynı semantik etiketler).
- Ana Sayfa: yatay geniş ekranda iki bölme (solda büyük Zibo, sağda balon + banner + kartlar); dikey tablette sütun
  680 dp ortalı, Zibo üst sınırı 400 → 500.
- Mağaza: gövde 900 dp ortalı; coin paketi / kostüm / tema ızgaraları 2–5 sütun (`_storeGridColumns`).
- Oyun Salonu: 960 dp ortalı, geniş ekranda iki sütun. Profil: 760 dp ortalı.
- 25 modül/alt ekranın `Scaffold.body`'si `AdaptiveCenter` ile sarıldı (oyun WebView'ı, kök ekran ve
  açılış/tanıtım ekranları HARİÇ).
- Oyunlar (`assets/games/*`): Kule, Coin Yakala, Zıpla, Tren, Tuğla tuvali yükseklik 640 sabit, genişlik ekran
  oranına göre 360–1200 (ekranı doldurur). Coin Yakala geniş alanda doğma sıklığı genişlikle orantılı. Tren yatayda
  24×15 ızgara (tur başında seçilir), ızgara ölçeklenip ortalanır. Tuğla yatayda 7→13 sütun (tur başında), arka plan
  tüm tuvale yayılır. 2048 tahta sınırı 440 → 760 px. Hafıza kart sütunu kartları en büyük gösterecek şekilde seçilir.
- Testler 751/751 yeşil. Tablette yatay+dikey tüm sekmeler ve 7 oyun gözle doğrulandı (release APK).

## Kalanlar
- [ ] Klavye/fare kontrol listesi (Tier 2): Tab sırası, Esc ile kapanma, hover — Flutter Material varsayılanları büyük
      ölçüde karşılıyor, tablette fiziksel klavyeyle doğrulanmalı.
- [x] 48dp dokunma alanı (2026-10-29): `StickerIconButton` görseli aynı, dokunma alanı ≥ 48dp (`kStickerMinTapTarget`,
      `stickerTapPadding`); köşe `Positioned` ofsetleri dolgu kadar düzeltildi (Ana Sayfa balonu, Hedefler, Para,
      Paywall kapat, Ana Sayfa kart kalemi). Yatay iki bölmede sağ dolgu 120 → rozet/hediye düğmeleri balona binmiyor.
- [x] Tablet ekran görüntüleri (2026-10-29): `tool/store_capture_web.py ... tablet` (release web build `build/web`
      + `zibo_web_release` launch config, VIEWPORT=1280x720/720x1280, DSF=1.5 → 1920x1080 / 1080x1920; Mağaza alt
      sekmeleri SEG koordinatı). Çıktı `store_assets/tablet/Zibo_Tablet_Ekran_Goruntuleri.zip` (TR/EN/ES × yatay/dikey ×
      7). Oyun içi görüntü yok (WebView web'de çalışmıyor) — gerekirse tabletten adb ile.
- [ ] Ekran görüntülerini Play Console'a yükleme (kullanıcı).
- [ ] Rozet başvuru formu (kullanıcıyla).
- [ ] Sürüm (AAB) — kullanıcı isteyince.
