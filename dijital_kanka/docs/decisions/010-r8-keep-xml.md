# 010 — Çalışma-zamanında string ile okunan Android kaynakları `res/raw/keep.xml`'de korunmalı

## Context
Release build'de `isMinifyEnabled = true` + `isShrinkResources = true` (R8 kaynak küçültme).
R8'in statik kullanım analizi, bir kaynağa yalnızca ÇALIŞMA ZAMANINDA bir STRING/İSİM üzerinden
referans verilen durumları GÖREMEZ → kaynağı "kullanılmıyor" sanıp APK'dan SESSİZCE siler
(derleme hatası/uyarısı YOK, yalnızca çalışma zamanında sessiz eksiklik).

## Bu proje bu bug'ı İKİ KEZ yaşadı
1. **`res/raw/zibo_notification.wav`** — `flutter_local_notifications`'ın `RawResourceAndroidNotificationSound('zibo_notification')`'ı bu kaynağa yalnızca metin ismiyle referans veriyor. Silinince: bildirim kanalı hatasız oluşuyor ama gerçek çalma anında sessizce ses yok. Teşhis SAATLER aldı.
2. **`@string/default_web_client_id`** — `google_sign_in_android`'in native tarafı `context.getResources().getIdentifier("default_web_client_id", "string", ...)` ile reflection'la okuyor (`google-services` plugin'inin `google-services.json`'dan ürettiği string). Silinince: `serverClientId` boş → Android `CredentialManager` isteği Google'a HİÇ göndermeden reddediyor → "Google ile Bağla çalışmıyor" (Cloud Console'da hiç istek görünmüyor çünkü sunucuya ulaşmıyor). Yalnızca DEBUG build'ler (küçültme kapalı) çalışıyordu.

## Decision
`android/app/src/main/res/raw/keep.xml`:
```xml
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@raw/zibo_notification,@string/default_web_client_id" />
```
(dosya `raw/` klasöründe olsa da `tools:keep` içeriğine `@string/`/`@drawable/` gibi başka tür
kaynaklar da eklenebilir.)

## Kalıcı kural
Herhangi bir native platform eklentisi (herhangi bir Flutter plugin) bir Android kaynağına yalnızca
STRING/İSİM üzerinden çalışma zamanında referans verdiğinde (raw ses/video, generated string,
drawable — statik `R.xxx.yyy` yerine), release build'de küçültme AÇIKKEN o kaynağı PROAKTİF olarak
`keep.xml`'e ekle. Doğrulama: `aapt2 dump resources <apk>` ile kaynağın gerçekten APK'da olduğunu
teyit et.

## İlgili
`android/CLAUDE.md` · `docs/history/founder-badge-iap-release-crashlytics.md` · `docs/history/push-notifications-sounds.md`
