# Zibo (dijital_kanka) — Proje Haritası

Flutter mobil uygulaması: "Zibo" adlı maskot karakterin eşlik ettiği bir kişisel gelişim / "dijital kanka" uygulaması. Günlük hedefler, alışkanlık modülleri (su/şükran/ruh hali/rüya/manifest günlükleri, para takibi, odak sayacı), sanal para ekonomisi (Zibo Coin), kostüm/tema mağazası, rozet sistemi, XP/seviye, Ana Ekran widget'ları. Yalnızca **Android**, üç dil (TR/EN/ES).

> **Bu dosya kasıtlı olarak KÜÇÜKTÜR.** Uzun mimari açıklamalar, geçmiş bug düzeltmeleri ve
> feature implementasyon detayları `docs/` altındadır ve YALNIZCA gerektiğinde okunur.
> **Görevin özellikle geçmiş bağlam gerektirmiyorsa proje geçmişinin tamamını okuma.**

## Teknoloji stack'i

- **Flutter** + `provider` (state management, ~40 `ChangeNotifier`)
- **Firebase**: Analytics, Anonymous Auth (+ opsiyonel Google Sign-In linking), Firestore, Crashlytics, Cloud Messaging (FCM)
- **Reklam**: Appodeal mediation (`stack_appodeal_flutter`) — yalnızca rewarded + interstitial
- **IAP**: `in_app_purchase` (Google Play Billing) — 5 tüketilebilir coin paketi
- **Sunucu tarafı**: Cloud Functions/Blaze YOK. Zamanlanmış işler = `notification-scripts/` (Node + `firebase-admin`) + `.github/workflows/` cron'ları (repo kökünde)
- Yerel bildirim zamanlayıcı: `flutter_local_notifications` (şu an RAFTA — `notificationsFeatureEnabled = false`)

## Temel mimari yaklaşımı

- **Katman bazlı klasörler** (`lib/data|models|providers|screens|services|utils|widgets`) — feature klasörü YOK.
- Her kullanıcı-verisi provider'ı `CloudStateStore` üzerinden hem `SharedPreferences` hem Firestore'a senkron. Firestore yolu: `users/{uid}/state/{prefsKey}`.
- Servisler soyut arayüz + gerçek implementasyon (üretim varsayılanı) + fake/mock (yalnızca testte enjekte edilir): `AdService`, `PurchaseService`, `NotificationService`, `ShareService`, `GoogleAuthService`, `SoundEffectsService`, `PhotoPickerService`, `HomeWidgetService`.
- `RootScreen` = sabit AppBar + kod-tabanlı alt bar + `IndexedStack` (4 sekme: Ana Sayfa / Hedefler / Profil / Mağaza). **`IndexedStack` TÜM sekmeleri hemen kurar** — her sekmenin provider'ı uygulama genelinde mevcut olmalı, `Timer`'lı ekranlar `isActive` koruması taşımalı.
- Diğer modüller (Rüya/Şükran/Ruh Hali/Su/Manifest/Para/Odak) alt bardaki Z butonunun açtığı modül menüsünden `Navigator.push` ile açılır.
- Detaylar → **`docs/ARCHITECTURE.md`**

## Değiştirilmemesi gereken kritik contract'lar

| Ne | Değer / kural |
|---|---|
| Dart paket adı | `dijital_kanka` — BİLEREK değiştirilmedi (kullanıcı-görünür ad ARB `appTitle` = "Zibo") |
| Android `applicationId` | `com.dijitalkanka.dijital_kanka` |
| Firestore kullanıcı verisi | `users/{uid}/state/{prefsKey}` — her provider'ın kendi doc'u |
| `coinState` doc | `firestore.rules` şekil/monotonluk/delta doğrulaması uygular — bu kuralları gevşetmek coin senkronunu SESSİZCE bozar |
| İçerik havuzları | `lib/data/*_quotes.dart`, `zibo_messages.dart`, `motivation_pools.dart` vb. — ARB'ye TAŞINMAZ, `xTr/xEn/xEs` + `xForLocale(Locale)` deseni, üç dil BİREBİR aynı uzunlukta |
| Kostüm / tema / rozet ID'leri | Kalıcı. `badge_gift_rewards.dart` map'i + Firestore + `localizedName` switch'leri bunlara bağlı. `founder_badge` = satılamayan pseudo-kostüm ID |
| `CoinPackage.id` | Play Console tüketilebilir ürün ID'leriyle BİREBİR eşleşmeli (`coins_100` … `coins_10000`) |
| `res/raw/keep.xml` | Yalnızca çalışma-zamanında STRING adıyla okunan Android kaynaklarını listeler (`zibo_notification`, `default_web_client_id`). Buraya eklenmezse R8 release build'de kaynağı SESSİZCE siler |
| `TrustedTimeProvider` | Güvenlik-kritik. Cihaz saati manipülasyonuna karşı; `_verifiedThisSession` guard'ı. Detaylar → `docs/decisions/003-*` |
| Play App Signing SHA-1 | Firebase'e kayıtlı olmalı (Google ile giriş için). Cihazdan `apksigner verify --print-certs` ile ÖLÇ, Play Console ekran görüntüsünden kopyalama |
| Sürüm bump | `pubspec.yaml` `+N` her Play yüklemesinde bir öncekinden KESİN büyük olmalı (tüm track'ler genelinde) |

## Global kurallar (her görevde geçerli)

- **`flutter analyze` bu makinede ÇÖKÜYOR** (yoldaki boşluk/Türkçe karakter). Kullanma — `flutter test`'e güven.
- Flutter SDK `C:\flutter\bin` — PATH'te değil, her komuttan önce `export PATH="$PATH:/c/flutter/bin"`.
- Test komutu: `flutter test` (`dijital_kanka/` içinde). Önceden belgelenmiş `audioplayers`/`home_widget` platform-kanalı flake'i tek testi etkiler, gerçek regresyon değil.
- Windows'ta native plugin derlemesi symlink ister → görsel doğrulama `flutter run -d web-server` + Browser araçlarıyla; gerçek cihaz testi `adb` ile ayrı.
- **Yeni asset dosyası** eklendikten sonra hot reload/restart YETMEZ — `flutter run` oturumunu tamamen kapatıp aç.
- ARB anahtarı ekledikten sonra kod derlemeden önce `flutter gen-l10n` çalıştır.
- Kullanılmayan ARB anahtarını SİLME (proje konvansiyonu) — kod-seviyesi ölü fonksiyonlar silinebilir.
- `feedback_auto_commit_push` memory: tamamlanan her düzenlemeyi sorMADAN commit + push et.
- **Gerçek cihaz kullanıcının canlı/kişisel telefonu olabilir** (`adb shell dumpsys package` ile `installerPackageName=com.android.vending` kontrol et) — release sürümün üzerine debug build kurmak (imza uyuşmazlığı → `uninstall` gerektirir) kullanıcı verisini SİLER, yapma.

## Dokümantasyon haritası — hangi durumda nereye bak

| İhtiyaç | Dosya |
|---|---|
| **Şu anda proje nerede?** (aktif sistemler, release durumu, bilinen sorunlar, açık işler) | `docs/CURRENT_STATE.md` |
| Sistem NASIL çalışıyor (bileşenler, veri akışı, servis sınırları, auth akışı) | `docs/ARCHITECTURE.md` |
| Bir mimari kararın NEDENİ / kısıtları (yanlış karar vermeyi önler) | `docs/decisions/` |
| Bir feature'ın implementasyon geçmişi, eski bug'ların kökü, "bu neden böyle" | `docs/history/` — `docs/history/README.md` indeksinden ilgili dosyayı seç |
| Bir alt-dizinde çalışırken o alana özgü kurallar/tuzaklar | O dizindeki nested `CLAUDE.md` (`lib/providers/`, `lib/l10n/`, `lib/services/`, `test/`, `android/`, `tool/`, `notification-scripts/`) — Claude Code bunları o dosyalara dokununca otomatik yükler |
| Tekrarlanan prosedür (release AAB, yeni rozet, yeni dil, görsel işleme) | `.claude/skills/` |

**`docs/history/` dosyalarını görevin AÇIKÇA geçmiş bağlam gerektirmediği sürece OKUMA** —
regression araştırması, "bu neden değişti", "eski implementasyon neydi", ya da kullanıcı doğrudan
geçmişi sorduğunda ilgili TEK dosyayı aç. Tümünü asla varsayılan olarak context'e yükleme.

## Klasör haritası (repo kökü = `C:\dev\Zibo DK`)

```
dijital_kanka/            # Flutter projesi (asıl çalışma dizini)
  lib/
    config/               # Sabit config (appodeal_config, notification_config)
    data/                 # Sabit veri listeleri (söz havuzları, coin paketleri, rozet tanımları, kostümler)
    l10n/                 # ARB kaynakları + üretilen AppLocalizations  → lib/l10n/CLAUDE.md
    models/               # Saf veri sınıfları
    providers/            # ChangeNotifier state  → lib/providers/CLAUDE.md
    screens/              # Sayfa seviyesi widget'lar (onboarding/ alt-dizini dahil)
    services/             # Soyut servis arayüzleri + gerçek/fake impl  → lib/services/CLAUDE.md
    utils/                # Küçük paylaşılan yardımcılar + saf fonksiyonlar
    widgets/              # Yeniden kullanılabilir UI parçaları
    main.dart, *_generator_main.dart  # Giriş noktaları (ana + önizleme/screenshot üreticileri)
  android/                # → android/CLAUDE.md (release imzalama, R8/keep.xml, RemoteViews, manifest)
  test/                   # → test/CLAUDE.md (flutter_test tuzakları)
  tool/                   # Elle çalıştırılan tek-seferlik görsel/veri betikleri  → tool/CLAUDE.md
  firestore.rules         # Firestore güvenlik kuralları (elle Console'a yapıştırılır)
  docs/                   # Bu dokümantasyon mimarisi
notification-scripts/     # Node + firebase-admin zamanlanmış işler  → notification-scripts/CLAUDE.md
.github/workflows/        # Zamanlanmış iş cron'ları (saatlik)
```
