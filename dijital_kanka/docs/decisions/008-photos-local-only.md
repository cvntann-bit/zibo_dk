# 008 — Fotoğraflar yalnızca cihazda yerel

## Context
Profil fotoğrafı + Manifest Günlüğü fotoğrafları galeriden seçiliyor. Kullanıcı bunların cihaz
değişince taşınmasını beklerdi.

## Decision
`PhotoPickerService.saveToPermanentStorage()` seçilen dosyayı `getApplicationDocumentsDirectory()/
app_photos/` altına kopyalar. Firestore'a yalnızca **dosya YOLU (string)** senkronize edilir —
gerçek dosya BAYTLARI HİÇBİR ZAMAN senkronize edilmez.

## Neden
- Gerçek fotoğraf kalıcılığı = Firebase Storage. **Şubat 2026'dan beri Cloud Storage for Firebase Spark planda hiç kullanılamıyor** — bucket oluşturmak bile Blaze gerektiriyor. Kullanıcı Blaze'e geçmiyor ([002](002-no-cloud-functions.md)).
- `AskUserQuestion` ile netleştirildi: kullanıcı Blaze'e GEÇMEMEYİ, yalnızca "kırık kaydı temizle" yaklaşımını seçti.

## Sonuçlar / Kısıtlar
- Kullanıcı hesap değiştirir / uygulamayı silip yeniden kurarsa, Firestore'dan geri gelen `photoPath` BU cihazda hiç var olmamış olabilir → `_File.length` → `PathNotFoundException: ... app_photos/*.jpg` (Crashlytics'teki en büyük tekrarlayan hata, `errorBuilder` bunu yakalamaz — hata widget ağacına ulaşmadan global `onError`'a sızar).
- **İki katmanlı savunma**:
  1. `_SafeFileImage` (manifest) / `_hasReadablePhoto` (profil) — `File(path).existsSync()` ile SENKRON varlık kontrolü, dosya yoksa `Image.file`'ı HİÇ İNŞA ETMEDEN kırık-resim placeholder'ına düşer.
  2. `ManifestProvider.reconcileMissingPhotos()` / `ProfileProvider.reconcileMissingPhoto()` — `RootScreen.initState` + her `resumed`'da; diskte olmayan `photoPath`'i kalıcı olarak `null`'a çevirir (niyet metni silinmez).
- `_SafeFileImage`/`_hasReadablePhoto` "anlık senkron güvenlik ağı", reconcile "kalıcı temizlik" — İKİSİ BİRLİKTE tutulur (reconcile bir frame sonra çalışır, ilk karede placeholder gerekir).
- Fotoğraf GERİ GELMEZ (mimari olarak imkansız) — yalnızca arayüz artık çökmez / tutarsız görünmez.
- `image_picker.pickImage(source: gallery)` Android 13+ (API 33+) sistem Photo Picker'ını kullanır → çalışma-zamanı izni GEREKMEZ. `<=32` için `AndroidManifest.xml`'de `READ_EXTERNAL_STORAGE maxSdkVersion=32` fallback.

## İlgili
`docs/history/journal-modules-profile.md` (Crashlytics kök nedeni bölümü)
