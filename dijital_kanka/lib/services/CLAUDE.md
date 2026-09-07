# `lib/services/` — Servis soyutlama kuralları

## Desen

Her servis: **soyut arayüz + gerçek implementasyon (üretim VARSAYILANI) + fake/mock (yalnızca testte
enjekte)**. Servisin gerçek implementasyonu bir platform kanalına dokunur → `flutter_test`'te
kullanılamaz.

- Gerçek implementasyonun platform-kanalına dokunan HER metodu **try/catch'li** olmalı — eklenti kullanılamıyorsa (test, desteklenmeyen platform) özellik sessizce devre dışı kalır, `RootScreen`'i pump'layan HER test çökmeden çalışır.
- Bir servisin `main.dart`'taki varsayılanı Mock'tan gerçek platform-kanalı implementasyonuna geçirildiğinde, o servisi DOĞRUDAN egzersiz eden HER mevcut widget testini gözden geçir ve gerekiyorsa `MockX` enjekte etmeye çevir (`AdMobAdService`, `InAppPurchasePurchaseService`, `HomeWidgetService` geçişlerinde bu oldu).

## Servisler ve gotcha'ları

| Servis | Not |
|---|---|
| `AdService` → `AppodealAdService` | Appodeal callback'leri GLOBAL → `Completer<bool>` köprüsü. `Appodeal.initialize()` `void` döner (fire-and-forget). Bir platform-kanalı `Future`'ını `await`lemeden ateşlerken hatasını `.catchError()` ile yakala (senkron `try/catch` YETMEZ). `CoinProvider`'ın KENDİ varsayılanı hâlâ `MockAdService` — yalnızca `main.dart` gerçek servisi verir. |
| `PurchaseService` → `InAppPurchasePurchaseService` | `buyConsumable(autoConsume: true)` + `purchaseStream` → `_pending` Map<productId, Completer>. `orphanedPurchaseProductIds` stream — çökme sonrası teslim edilmemiş satın alma; `CoinProvider` dinler, `awardXp: false` ile teslim eder. TÜM gövde tek try/catch. **Makbuz sunucu tarafında doğrulanmıyor** (bkz. `docs/decisions/005`). |
| `NotificationService` → `LocalNotificationService` | İKİ kanal: `daily_reminders` (`notificationsFeatureEnabled` false ise HİÇ oluşturulmaz — `lib/config/notification_config.dart`) + `push_notifications` (`zibo_notification` sesli). `showNow()` idempotent `initialize()` çağırır (FCM ön plan mesajları için). `res/raw/zibo_notification.wav` `keep.xml`'de korunmalı (bkz. `docs/decisions/010`). |
| `GoogleAuthService` → `FirebaseGoogleAuthService` | `AuthLinkProvider`'ın KENDİ varsayılanı `FakeGoogleAuthService` (gerçek servis testte `[core/no-app]`). `linkCurrentUser` uid KORUR, `signIn`/`signOut` uid DEĞİŞTİRİR (→ `switchToUid` → `KeyedSubtree` remount). `_authenticate()` her çağrıda önce `_signIn.signOut()` + timeout. `idToken == null` → `GoogleSignInMissingIdTokenException` (sessizce `null` dönme). Detay → `docs/decisions/004`. |
| `ShareService` → `SharePlusService` | `shareImageBytes()` — path'li `XFile` verir (path'siz fallback bir Android cache-eviction yarış koşuluna yol açıyordu, Crashlytics'te `PathNotFoundException`). `shareText()` (referral daveti). |
| `SoundEffectsService` → `AudioPlayersSoundEffectsService` | Tek `AudioPlayer`, ortak `_play(assetPath)` (stop+play). 8 metot. `SoundEffectsProvider.enabled` kontrolü ÇAĞIRAN tarafta. Her tüketici KENDİ örneğini oluşturur. `assets/sounds/` `pubspec.yaml`'da. `CoinProvider._earn()` merkezi kancasından `playCoinReward` otomatik. |
| `PhotoPickerService` → `ImagePickerPhotoService` | `app_photos/` altına kalıcı kopya. Yalnızca YOL Firestore'a senkron, baytlar DEĞİL → `docs/decisions/008`. `_SafeFileImage`/`_hasReadablePhoto` senkron `existsSync()` guard'ı + `reconcileMissingPhotos` kalıcı temizlik. |
| `HomeWidgetService` → `HomeWidgetPluginService` | `home_widget` KLASİK RemoteViews. `pushStatus`/`pushCarousel(module, {items})` — `CarouselItem{value, label?, progress?, hasData}` ortak şekli. `requestPinWidget(qualifiedAndroidName:)` — provider `.widgets.` alt paketinde olduğu için TAM NİTELİKLİ isim şart. Deep-link: `zibowidget://open/<prefix>`. |
| `CloudStateStore` | Servis değil, kalıcılık sarmalayıcısı — `lib/providers/CLAUDE.md` + `docs/decisions/001`. |
| `TrustedTimeService` (`Firestore`/`HttpDate`/`Composite`) | `docs/decisions/003`. |
| `BadgeCoordinator` / `HomeWidgetSyncCoordinator` | Provider'ları parametre alır, `addListener` ekler. `lib/providers/CLAUDE.md`. |
