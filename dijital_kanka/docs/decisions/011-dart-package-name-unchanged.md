# 011 — Dart paket adı `dijital_kanka` bilerek değiştirilmedi

## Context
Kullanıcı-görünür uygulama adı 2026'da "Zibo" oldu. Dahili Dart paket/dizin adı hâlâ
`dijital_kanka`.

## Decision
`pubspec.yaml` `name: dijital_kanka` ve TÜM `package:dijital_kanka/...` import'ları AYNEN KALIYOR.
Yalnızca kullanıcı-görünür ad değişti:
- `android/app/src/main/AndroidManifest.xml` `android:label`
- ARB `appTitle` anahtarı (üç dilde de "Zibo" — recents/görev değiştirici başlığı)
- Uygulama ikonu `assets/images/zibo_app_icon.png`

## Neden
Dahili paket adını değiştirmek proje genelinde onlarca dosyada import yeniden yazımı gerektirir ve
HİÇBİR kullanıcı-görünür faydası yoktur. `applicationId` (`com.dijitalkanka.dijital_kanka`) da AYNI
sebeple değişmez — Play Console'daki uygulama kimliği buna bağlı.

## Kısıt
- Bu projede "package name" / "app name" ayrımına dikkat: `dijital_kanka` (Dart), `Zibo` (görünür), `com.dijitalkanka.dijital_kanka` (Android/Play). Dokümantasyonda/kodda hiçbirini diğeriyle karıştırma.
