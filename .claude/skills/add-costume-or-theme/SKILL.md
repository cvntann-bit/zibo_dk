---
name: add-costume-or-theme
description: Zibo Mağaza'sına yeni bir kostüm veya tema ekler (görsel işleme + poz seti + ARB + fiyat + Firestore rules kontrolü dahil). Kullanıcı "yeni kostüm ekle", "yeni tema ekle", "şu kostümü mağazaya koy" dediğinde kullan.
---

# Yeni kostüm / tema ekleme prosedürü

Tam bağlam: `dijital_kanka/docs/history/costumes-poses-themes.md`. ID contract → `docs/decisions/009`.

## Kostüm

1. **ID** — kalıcı, `zibo_<isim>` deseni. `costumes.dart`'taki liste FİYATA GÖRE SIRALI (ucuzdan pahalıya) — yeni kostümü doğru yere ekle (Mağaza ızgarası listeyi olduğu gibi dolaşır).
2. **`lib/data/costumes.dart`** — `Costume(id, imageAsset, name, price)`. `name` yalnızca dahili referans — EKRANDA `localizedName(l10n)` kullanılır.
3. **Vitrin görseli** — `assets/images/zibo_<isim>.png`. Kullanıcının 1024×1024 kaynağını `tool/crop_new_costume_covers.dart` (~%96 doluluk) ile kırp. Piksel-alfa ile şeffaflık doğrula.
4. **Poz seti (opsiyonel)** — `zibo_<isim>_pose1..N.png` → `tool/process_all_poses.dart` (`_poseSets` listesine ekle → GLOBAL 763px hedefe kırpıp ölçekler). `lib/data/costume_poses.dart`'taki `costumePoses` Map'ine girdi. Map'te girdisi yoksa `ZiboAnimatedImage` otomatik tek statik `imageAsset`'e düşer.
5. **ARB** — `costumeName<Id>` (TR/EN/ES) → `flutter gen-l10n`. `Costume.localizedName` switch'ine `case`.
6. **Alt bar Z Coin teması (opsiyonel)** — özel tema (Altın/Elmas gibi) ise `z_floating_button.dart` `_coinAssetFor` switch'i.
7. **Firestore rules** — kostüm eski `33000` üst sınırından PAHALIYSA `firestore.rules`'taki harcama üst sınırını yükselt (`docs/decisions/005`).
8. **Test** — `widget_test.dart`'a satın al + giy + Ana Sayfa'da poz/görsel değişimi senaryosu.

## Tema

1. **ID + `lib/data/app_themes.dart`** — `AppThemeOption(id, lightColors, darkColors, lightPrimary, ...)`. Kod-tabanlı (görsel asset YOK). `animationType` verilmezse `none` → `isPremiumAnimated == false` → "Standart" grubunda. Fiyat 250-500 ZC (standart) aralığında.
2. **Premium/animasyonlu** ise: `ThemeAnimationType` enum'a değer + `ThemeParticleEffect`'e `CustomPainter` + fiyat 650-900 ZC.
3. **ARB** — `themeName<Id>` (TR/EN/ES) → `flutter gen-l10n`. `AppThemeOption.localizedName` switch'ine `case`.
4. **`isStarryInDark`** yalnızca "Gece Gökyüzü" temasına özel — yeni temada KULLANMA.
5. **Test** — `test/app_themes_data_test.dart`'taki `appThemes.length` + fiyat aralığı + `animationType` assertion'larını güncelle.

## Ortak gotcha'lar

- `GridView.count` `childAspectRatio` — yeni kart içeriği eklerken (ör. hediye önizleme satırı) TAŞMA riski. Değeri TAHMİN ETME, gerçekçi dar viewport'ta (`412×915`) `tester.takeException()` ile doğrula.
- `const` veri listesindeki SABİT bir alan (isim, renk) kullanıcıya GÖRÜNÜYORSA ARB'ye taşınamaz (`BuildContext`'siz oluşturulur) → modele `localizedX(AppLocalizations l10n)` metodu ekle, ham alanı asla `Text()`/`SnackBar()`'da kullanma.
- Rozet hediye sistemi bu kostüm/temayı hediye edecekse → `lib/data/badge_gift_rewards.dart` (`docs/decisions/009`).
