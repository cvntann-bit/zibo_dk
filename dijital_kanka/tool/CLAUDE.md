# `tool/` — Elle çalıştırılan görsel/veri betikleri

Bunlar uygulamanın çalışma zamanına dahil DEĞİL. `image` paketi yalnızca bunlar için
`dev_dependency`. Çalıştırma: `dart run tool/<betik>.dart <argüman>`.

## Kategoriler

- **Arka plan temizleme**: `remove_bg.dart` (BEYAZ stüdyo arka planı — kenardan flood-fill + feather), `remove_black_bg.dart` (SİYAH arka plan — bazı üretici araçları "transparent" yerine "black" export eder), `clean_app_icon.dart` (köşe-bağlantılı beyaz kare tuval, ikonun içindeki beyaza dokunmaz).
- **Kırpma**: `crop_transparent.dart` (içeriğin gerçek sınır kutusuna), `crop_pose_content.dart`, `crop_new_costume_covers.dart`.
- **Poz normalizasyonu**: `process_all_poses.dart` (TÜM kostüm poz setlerini TEK global hedef yüksekliğe — 763px — kırpıp ölçekler; `measure_pose_bounds.dart` ile ölç). `tool/pose_originals_backup/` altında işlenmemiş yedekler.
- **Rozet görselleri**: `process_badge_images.dart` + kategori-özel varyantları (`process_module_mastery_badge_images.dart` vb.) — dosya adlarını korur, 512px'e küçültür.
- **Widget asset'leri**: `prepare_widget_assets.dart` (logo + karakter görseli), `compose_widget_previews.dart` (gerçek cihazda üretilen temel PNG'lere logo bindirir).
- **Coin/tema görselleri**: `process_coin_theme.dart`, `split_wheel_layers.dart` (çark → disk + frame katmanı).
- **Diğer**: `flutter_launcher_icons` (dev_dependency) — `dart run flutter_launcher_icons` tüm mipmap boyutlarını tek kaynaktan üretir.
- **İçerik üretimi**: `generate_content_js_daily_motivation.dart` — `lib/data/zibo_messages.dart`'ı düz metin okuyup `notification-scripts/src/content.js`'in `daily_motivation` bloğunu üretir (837 satırı elle kopyalamak yerine).

## KRİTİK: PNG şeffaflık doğrulaması

Önizleme aracına (`Read`, görsel önizleyici) GÜVENME — şeffaf pikselleri farklı renklerde
(bazen SİYAH) kompozit edebilir, bu bir görüntüleyici tuhaflığı, gerçek veri değil.
**Nihai kanıt: pikselin HAM alfa değerini ölç** (geçici bir `dart run` betiğiyle `img.getPixel(x,y).a`,
sonra sil). `yilmaz_efsanevi_rozet.png` bug'ı (baked-in siyah kare) tam bu yüzden gözden kaçtı.
Yeni bir rozet/kostüm görseli eklemeden ÖNCE piksel-alfa ile şeffaflık doğrula.

## Radyal maskeleme / feather birim hataları

`split_wheel_layers.dart`'ın `_featherFrac`'i ilk yazımda piksel biriminde tanımlanıp 0-1
yarıçap-kesriyle karşılaştırıldı → tüm aralığı yuttu. Bu tür radyal işlerde her zaman köşe/orta
noktalarda alfa değerini SAYISAL ölç, yalnızca görsel önizlemeye güvenme.

## Görsel varlıklar artık WebP (2026-09-12)

`assets/images/`'daki üretim PNG'lerinin çoğu (`zibo_app_icon.png` HARİÇ — bkz. altta)
`convert_images_to_webp.dart` ile KAYIPSIZ (VP8L) WebP'ye çevrildi (Play Console "Bit eşlem
resim optimizasyonu" önerisi, bkz. `android/CLAUDE.md`) — ~%25 boyut kazancı, piksel-piksel
doğrulanmış. **Bu dosyadaki DİĞER betikler (`crop_pose_content.dart`, `normalize_pose_sizes.dart`,
`process_coin_theme.dart`, `crop_new_costume_covers.dart` vb.) HÂLÂ PNG okuyup/yazıyor,
KASITLI olarak güncellenmedi** — her birini ayrı ayrı WebP'ye taşımak yerine, YENİ bir
kostüm/rozet eklerken akış şöyle: (1) ham görseli her zamanki gibi PNG olarak bu betiklerden
geçir, (2) TÜM işleme bittikten (kırpma/ölçekleme/pozisyonlama) SONRA, son adım olarak
`dart run tool/convert_images_to_webp.dart` çalıştır — yeni dosya da otomatik WebP'ye döner.
Mevcut bir kostüm/rozet görselini bu eski betiklerden biriyle YENİDEN işlemeye çalışırsan
(artık `.webp` olduğu için) "dosya bulunamadı" hatası alırsın — bu BEKLENEN, sessiz bozulma
DEĞİL. `zibo_app_icon.png` PNG olarak KALDI çünkü `flutter_launcher_icons`'ın (pubspec.yaml
`image_path`) WebP kaynak desteği doğrulanmadı.

## Fake-async betikleri gerçek cihazda çalıştırma

`flutter_test` + `RenderRepaintBoundary.toImage()` gerçek font/emoji yüklemez (tofu). Önizleme PNG'si
üretmek için `lib/*_generator_main.dart` alternatif entry point'lerini `flutter build apk --debug -t
lib/widget_preview_generator_main.dart` ile derle, cihazda aç, `adb exec-out run-as <pkg> cat <yol>`
ile çek.
