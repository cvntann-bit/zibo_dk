---
name: release-aab
description: Zibo (dijital_kanka) için Play Store'a yüklenecek release AAB üretir. Sürüm numarasını bump eder, imzalı bundle derler, commit + push eder. Kullanıcı "AAB oluştur", "yeni sürüm yayınlayayım", "release build al" dediğinde kullan.
---

# Release AAB üretme prosedürü

Bağlam: proje `dijital_kanka/` alt dizininde. Flutter SDK `C:\flutter\bin` (PATH'te değil).

## 1. Sürüm numarasını bump et

`dijital_kanka/pubspec.yaml` → `version: X.Y.Z+N`:
- `+N` (versionCode) HER Play yüklemesinde bir öncekinden KESİN büyük olmalı (tüm track'ler genelinde, kalıcı) → `+N`'i **her zaman +1** artır.
- `X.Y.Z` (versionName): yalnızca bug fix → `Z`++; yeni feature → `Y`++, `Z`=0; büyük değişiklik → `X`++.
- Değişikliğin niteliğini kullanıcıya sor/çıkarım yap, ona göre karar ver.

## 2. Ön koşulları doğrula

```bash
cd "C:/dev/Zibo DK/dijital_kanka" && ls android/key.properties android/upload-keystore.jks
```
İkisi de VAR olmalı (`.gitignore`'da — repo'da yok, yerel makinede olmalı). Yoksa DURDUR, kullanıcıya söyle (imzalama yapılamaz, build sessizce debug imzasına düşer).

## 3. Derle

```bash
cd "C:/dev/Zibo DK/dijital_kanka" && export PATH="$PATH:/c/flutter/bin" && flutter build appbundle --release
```
- Gradle ~8-10 dk. `run_in_background: true` ile başlat, tamamlanma bildirimini bekle.
- Zararsız uyarılar: KGP (Kotlin Gradle Plugin) plugin uyarısı, SDK XML version, MaterialIcons tree-shaking. Bunlar HATA DEĞİL.
- Başarı: `√ Built build\app\outputs\bundle\release\app-release.aab`

## 4. Testleri çalıştır (paralel/önceden de olabilir)

```bash
cd "C:/dev/Zibo DK/dijital_kanka" && export PATH="$PATH:/c/flutter/bin" && flutter test
```
Belgelenmiş `audioplayers`/`home_widget` flake'i (1 test) hariç yeşil olmalı.

## 5. Commit + push

```bash
cd "C:/dev/Zibo DK" && git add -A && git commit -m "Bump version to X.Y.Z+N for release AAB
<değişiklik özeti>

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>" && git push
```

## 6. Kullanıcıya teslim et

`SendUserFile` ile `build/app/outputs/bundle/release/app-release.aab` yolunu ver + sürüm no + kısa içerik.
Kullanıcı Play Console'a KENDİSİ yükler (Kapalı/Üretim testine).

## Notlar
- APK gerekiyorsa (yerel `adb install` testi): `flutter build apk --release` (veya `--debug`).
- **Cihazdaki kurulum kullanıcının canlı Play sürümü olabilir** — üzerine debug build kurma (imza uyuşmazlığı → uninstall → veri kaybı). `adb shell dumpsys package <pkg> | grep installerPackageName` kontrol et.
