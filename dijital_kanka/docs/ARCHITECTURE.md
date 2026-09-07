# Zibo — Mimari

Bu dosya sistemin **NASIL ÇALIŞTIĞINI** anlatır (uzun süre geçerli teknik bilgi). Geliştirme
geçmişi / bug hikayeleri için `docs/history/`, karar gerekçeleri için `docs/decisions/`.

---

## 1. Genel yapı

- **Flutter**, tek modül, katman bazlı klasörler (`lib/data|models|providers|screens|services|utils|widgets`). Feature klasörü yok — bir feature'ın parçaları bu katmanlara dağılır.
- **State management: `provider`.** ~40 `ChangeNotifier` `main.dart`'ta `MultiProvider` ile uygulama köküne bağlanır.
- Giriş noktaları: `main.dart` (uygulama), `lib/widget_preview_generator_main.dart` + `lib/store_screenshot_generator_main.dart` (elle çalıştırılan, gerçek cihazda PNG üreten alternatif entry point'ler — normal `main.dart`'ı etkilemez).

## 2. Uygulama başlangıç akışı (`main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()` → `AdFreePromoTrigger.initialize()`
2. `Firebase.initializeApp()` + Anonymous Auth (`currentUser` yoksa `signInAnonymously()`) + `FirebaseAnalytics.logAppOpen()` + Crashlytics global hata yakalayıcıları — **HEPSİ tek bir try/catch içinde**. Firebase kullanılamıyorsa (web önizleme, `flutter_test`, config eksik) uygulama Firebase'siz / tam yerel modda açılmaya devam eder.
3. `firebaseMessagingBackgroundHandler` kaydı (top-level, `@pragma('vm:entry-point')`)
4. `MobileAds`/Appodeal init (Firebase'den bağımsız ayrı try/catch)
5. `runApp(_AppRoot(initialUid: uid))`

### `_AppRoot` → `KeyedSubtree(key: ValueKey(uid))` → `DijitalKankaApp`

`switchToUid` global `ValueNotifier<String?>` değişince `_AppRoot` `setState` ile `_uid`'i değiştirir; `KeyedSubtree`'nin key'i değiştiği için Flutter TÜM provider ağacını söküp yeni uid ile SIFIRDAN kurar. Bu, "Google ile giriş yap / hesap değiştir / çıkış yap" sonrası tüm kullanıcı verisinin yeni uid'e geçmesini TEK mekanizmayla sağlar — 40 provider'a elle "uid değişti, yeniden yükle" eklemeye gerek yok.

### `_AppStartupGate` (3 yönlü)

`DijitalKankaApp.home`, doğrudan `RootScreen` değil `_AppStartupGate`'tir. YEDİ provider (`ThemeProvider`, `AppThemeProvider`, `LocaleProvider`, `CoinProvider`, `CostumeProvider`, `OnboardingProvider`, `ProfileProvider`) `isReady == true` olana kadar `AppLoadingScreen` (markalı splash) gösterilir. Sonra:
- `!onboarding.isCompleted` → `OnboardingScreen`
- aksi halde → `RootScreen`

`isReady`, her provider'ın `_loadFromPrefs()`'inin HER çıkış yolunda koşulsuz `true` yapılır. `ProfileProvider` bu kapıya SONRADAN eklendi (bir yarış koşulu düzeltmesi — bkz. `docs/history/adfree-theme-splash-onboarding.md`). Diğer ~30 provider bu kapıda DEĞİL — ilk karede görünmezler, arka planda yüklenmeye devam eder.

## 3. Navigasyon

- **`RootScreen`**: sabit `AppBar` (coin bakiyesi + sekmeye-özel koşullu ikonlar) + `IndexedStack` (4 sabit sekme) + kod-tabanlı alt bar (`MainBottomBar` — `BottomAppBar` + ortada dock'lu `ZFloatingButton`, `NavigationBar` DEĞİL).
- **4 sekme:** Ana Sayfa / Hedefler / **Profil** / Mağaza. (Para ve Birikim eskiden sekmeydi, Profil'le yer değiştirdi.)
- **Ayarlar** sekme DEĞİL — AppBar dişli ikonundan `Navigator.push`.
- **Modül ekranları** (Rüya/Şükran/Ruh Hali/Su/Manifest Günlükleri + Para ve Birikim + Odak Sayacı): alt bardaki Z butonunun `showModulesMenuSheet`'inden `Navigator.push`. Her biri kendi `Scaffold`/`AppBar`/geri butonu taşır.
- **Ana Sayfa'ya özel overlay'ler** (sadece `_selectedIndex == 0` iken): sol kenarda `WheelTriggerButton` (Şans Çarkı), sağ kenarda `DailyRewardsTriggerButton` + `BadgesTriggerButton`.
- **`IndexedStack` KRİTİK gotcha:** dört sekme widget'ı her `build()`'de kurulur (yalnızca görünürlük gizlenir). Sonuç: (a) her sekmenin ihtiyaç duyduğu provider uygulama genelinde mevcut olmalı; (b) `Timer.periodic`'li bir sekme (`MoneyScreen` eskiden, `GoalTrackingScreen`, `StoreScreen`, `ProfileScreen`) `isActive` parametresi + `didUpdateWidget` start/stop taşımalı — yoksa görünmezken de çalışır ve testte "pending timer" hatası verir.
- **Sekmeler-arası / bildirim / widget yönlendirme sinyalleri** (`lib/utils/tab_navigation.dart` + benzerleri): `homeTabRequest` / `goalsTabRequest` / `profileTabRequest` / `waterModuleRequest` / `moneyModuleRequest` / `dailyRewardsPopupRequest` — global `ValueNotifier<int>` (widget ağacı dışından yazılabilsin diye). `RootScreen` bunları dinleyip sekme değiştirir / modül push eder / popup açar. Ayrıca `isHomeTabActive` (bool `ValueNotifier`) — animasyonlu tema parçacık katmanı yalnızca Ana Sayfa'da çizilsin diye.

## 4. Kalıcılık: `CloudStateStore`

`lib/services/cloud_state_store.dart` — her kullanıcı-verisi provider'ının `_loadFromPrefs`/`_save`'inin YERİNE geçen paylaşılan yardımcı.

- `load()`: önce Firestore (`users/{uid}/state/{prefsKey}`), orada veri yoksa yerel `SharedPreferences`'taki eski veriyi okuyup Firestore'a **göç ettirir**.
- `save()`: HER ZAMAN önce yerele (eski JSON biçimi/anahtar korunur), sonra (varsa) Firestore'a.
- **`uid == null`** (Firebase yok / test): tamamen eski davranış — saf `SharedPreferences`, Firestore'a hiç dokunulmaz. Her provider constructor'ı `uid`'i OPSİYONEL alır; hiçbir provider testi vermez → ~150 mevcut test değişmeden saf-yerel modda çalışır.
- Provider constructor'ları enjekte edilebilir `firestore` de alabilir (test için `fake_cloud_firestore`).

**Migrasyon varyantları:** (A) tek anahtarlı JSON map — mekanik swap; (A-türevi) düz JSON liste (`GratitudeProvider`/`MoodProvider`/`ManifestProvider`) — `_loadLegacyRawList()` sarar; (B) iki-anahtarlı eski format → tek doc (`CostumeProvider`/`AppThemeProvider`/`NotificationProvider`); (C) tek skaler değer (`ThemeProvider` bool, `LocaleProvider` string) — `{'value': ...}` sarmalı + `_loadLegacyBool/String`.
**Alan-seviyesi göç deseni** ("oku-zamanı-göç-et"): yeni bir `required` alan (`MoneyEntry.date`, `MoneyEntry.currencyCode`) eklendiğinde `_entryFromJson` eski kayıtlara varsayılan atar, bir SONRAKİ `_save()`'de kalıcı olur — ayrı migrasyon betiği gerekmez.

### `notifyListeners()` disiplini
Bir `ChangeNotifier`'ın dışarıdan çağrılan bir "reconcile/senkronize et" metodu, SONUCU DEĞİŞTİRMESE BİLE `notifyListeners()` çağırmalıdır — `IndexedStack`'te sürekli monte kalan widget'lar (örn. `DailyRewardsTriggerButton`) aksi halde SESSİZCE eski durumu göstermeye devam eder (özellikle "durum" zaman geçtikçe kendiliğinden değişebiliyorsa — "hangi gün bugün" gibi).

## 5. Servis soyutlamaları

Her biri: soyut arayüz + gerçek implementasyon (üretim VARSAYILANI) + fake/mock (yalnızca testte enjekte).

| Servis | Gerçek impl | Notlar |
|---|---|---|
| `AdService` | `AppodealAdService` | `showRewardedAd()` / `showInterstitialAd()` → `Future<bool>`. Appodeal callback'leri SDK-seviyesinde GLOBAL, `Completer` köprüsü kullanılır. Ön-yükleme YOK (SDK sürekli arka planda yükler). `CoinProvider`'ın KENDİ varsayılanı hâlâ `MockAdService` — yalnızca `main.dart` gerçek servisi override eder. |
| `PurchaseService` | `InAppPurchasePurchaseService` | `buyConsumable(autoConsume: true)` + `purchaseStream`. `orphanedPurchaseProductIds` stream'i — çökme sonrası teslim edilmemiş satın almaları yakalar, `CoinProvider` dinler. `queryLocalizedPrice()` — Play Store'un gerçek fiyat metni (yoksa `CoinPackage.price` sabitine düşer). |
| `NotificationService` | `LocalNotificationService` | `flutter_local_notifications`. İKİ kanal: `daily_reminders` (rafta — `notificationsFeatureEnabled` false ise HİÇ oluşturulmaz) + `push_notifications` (FCM ön plan bildirimleri için, `zibo_notification` özel sesli). HER platform-kanalı metodu try/catch'li — test/desteklenmeyen platformda sessizce no-op. |
| `ShareService` | `SharePlusService` | `shareImageBytes()` (path'li `XFile` verir — path'siz fallback bir yarış koşuluna yol açıyordu) + `shareText()`. |
| `GoogleAuthService` | `FirebaseGoogleAuthService` | `linkCurrentUser()` (uid KORUNUR — `linkWithCredential`), `signIn()`/`signInWithGoogle()` (uid DEĞİŞİR — `signInWithCredential`), `signOut()` (→ `signInAnonymously()` + `clearLocalAccountData()`). `AuthLinkProvider`'ın KENDİ varsayılanı `FakeGoogleAuthService` (test güvenliği — gerçek servis `flutter_test`'te `[core/no-app]` fırlatır). `_authenticate()` her çağrıda önce `_signIn.signOut()` + timeout'lu. `idToken == null` → `GoogleSignInMissingIdTokenException` (sessizce yutmaz). |
| `SoundEffectsService` | `AudioPlayersSoundEffectsService` | Tek `AudioPlayer`, ortak `_play(assetPath)` (stop+play, üst üste binme yok). Metotlar: `playZiboTap`/`playCoinReward`/`playCoinPurchase`/`playGoalComplete`/`playCostumeBuy`/`playThemeBuy`/`playWaterDrop`/`playBadgeWin`. `SoundEffectsProvider.enabled` (Ayarlar). Her tüketici KENDİ örneğini oluşturur. |
| `PhotoPickerService` | `ImagePickerPhotoService` | Galeri seçimi + `app_photos/` altına kalıcı kopya. Fotoğraflar SUNUCUYA yüklenmez — Firestore'a yalnızca YOL (string) senkronize edilir, baytlar DEĞİL → cihazlar arası taşınmaz (bkz. `docs/decisions/`). Android 13+ Photo Picker izinsiz çalışır; `<=32` için `READ_EXTERNAL_STORAGE maxSdkVersion=32` fallback. |
| `HomeWidgetService` | `HomeWidgetPluginService` | `home_widget` paketi, KLASİK RemoteViews API (Glance DEĞİL). `pushStatus`/`pushCarousel`/`requestPin`. Deep-link: `zibowidget://open/<prefix>` → `initialLaunchModule()` / `moduleClicked` stream. |

## 6. Zaman: `TrustedTimeProvider`

Güvenlik-kritik (günlük ödül / streak / rozet zaman pencereleri). `now()`:
- Bir ağ doğrulaması BU OTURUMDA tamamlandıysa (`_verifiedThisSession`) → `verified + _stopwatch.elapsed` (donanım saati, cihaz TARİH ayarından bağımsız — ileri/geri alınsa fark etmez).
- Aksi halde (kalıcı depodan yüklenmiş ama bu oturumda tazelenmemiş değer dahil) → cihaz saatine güvenle düşer (bootstrap penceresi).

Kaynak: `uid != null` iken `CompositeTrustedTimeService([FirestoreTrustedTimeService, HttpDateTrustedTimeService])`; `uid == null` iken yalnızca HTTP `Date`.

**İstisna — kozmetik/eğlence özellikler cihaz saatini KULLANIR** (bilinçli): `motivation_quote_selector.dart`'ın `timeBucketFor` (sabah/öğle/akşam/gece sözü), `HiddenBadgeProvider` (Gece Kuşu / Erken Kuş rozetleri) — kullanıcının O ANKİ gerçek yerel saatini yansıtmalı.

## 7. Firebase / backend

- **Firestore** (Spark/ücretsiz plan — Blaze YOK): `users/{uid}/state/*` (per-provider), `users/{uid}` kök doc (`fcmToken`/`lastActiveAt`/`timeZone`), `_serverTime/ping`, `referralRedemptions/*` (create-only), `founderBadgeStatus/status` (paylaşılan sayaç). Kurallar → `firestore.rules` (elle Console'a yapıştırılır, otomatik deploy YOK).
- **Auth**: Anonymous (varsayılan) + opsiyonel Google linking (`linkWithCredential` uid'i korur).
- **FCM push** (bkz. `notification-scripts/CLAUDE.md`): 4 tür (daily motivation / streak / daily reward / re-engagement) + water reminder. Cron mantığı: `.github/workflows/*.yml` SAATLİK çalışır, her betik `pendingNotifyHours`/`markNotifyHoursSent` catch-up penceresiyle kullanıcının KENDİ saat dilimindeki hedef saate denk gelenlere gönderir. Dil: `content.js` (TR/EN/ES). Dedup: `messageId` + `dedupeByFcmToken`.
- **Crashlytics**: `FlutterError.onError` + `PlatformDispatcher.instance.onError` (return true → uygulama çökmez, fatal olarak raporlanır). Mapping dosyası `isMinifyEnabled` sayesinde otomatik yüklenir.

## 8. Yerelleştirme

Resmi Flutter `gen-l10n`. 3 ARB (`app_tr.arb` template, `app_en.arb`, `app_es.arb`). `LocaleProvider` (`SharedPreferences`). Detaylı kurallar → `lib/l10n/CLAUDE.md`.

**Kritik ayrım:** UI "chrome" metinleri (buton/başlık/tooltip) → ARB. Büyük "içerik havuzları" (söz listeleri) → `lib/data/*.dart` sabit `xTr/xEn/xEs` listeleri + `xForLocale(Locale)`. Söz seçimi STRING değil INDEX tabanlı (`_quoteIndex`) — dil değişince ekrandaki söz anında doğru dile geçer. Üç dil BİREBİR aynı uzunlukta olmalı (index güvenliği; `pool.toSet().length` testleriyle kapsanır). Hitap kelimesi: TR "Kanka" (kullanıcının Profil'den seçtiği terimle `applyAddressTerm` ile değiştirilir), EN "buddy", ES "amigo".

## 9. Reklam & para kazanma

- **Appodeal mediation** — tek ağa bağımlılık riski (AdMob hesabı banlanmıştı) için seçildi. Şu an Appodeal'in kendi (IAB/Bidon) + AppLovin/BidMachine (Appodeal varsayılan hesabı) dolgusu. Unity Ads adaptörü kodda hazır ama Appodeal Console'da "Store link required" bekliyor.
- **IAP**: 5 tüketilebilir coin paketi. **Açık güvenlik boşluğu:** makbuz sunucu tarafında doğrulanmıyor (Blaze/Cloud Functions kararı bekliyor).
- **Zibo ADS** = reklamsız deneyim MOCKUP'ı — gerçek satın alma YOK, "Yakında" mesajı. Üç tetikleme yolu: periyodik Mağaza promosyonu, Mağaza'daki kalıcı kart, Ana Sayfa'da art arda hızlı Zibo dokunması.
- Interstitial tetikleme noktaları: art arda dokunma (%75 reklam / %25 Zibo ADS teklifi), Günlük Giriş Ödülü alımı, 7 günlük hedef döngüsü tamamlama (konfeti kutlaması BİTİNCE).

## 10. Ana Ekran Widget'ları

`home_widget` KLASİK RemoteViews API. **5 widget** (Su Takibi, Para ve Birikim, Günlük Giriş Ödülleri, Zibo'nun Sözü, İstatistiklerim) — diğer 5'i (Hedef/Rüya/Şükran/Ruh Hali/Manifest) kullanıcı isteğiyle KALDIRILDI. Üçü `ZiboBaseWidgetProvider.kt` paylaşır, ikisi (carousel'ler) `ViewFlipper` + `pushCarousel`. Veri akışı: `HomeWidgetSyncCoordinator` (`RootScreen.initState` + her `resumed`'da `syncAll()`) → `HomeWidget.saveWidgetData` + `updateWidget`.

**RemoteViews KRİTİK kural:** yalnızca beyaz-listedeki view sınıfları inflate edilir (`FrameLayout`/`LinearLayout`/`TextView`/`ImageView`/`ProgressBar`/`ViewFlipper` — ham `<View>`/`<Space>` DEĞİL) ve yalnızca beyaz-listedeki `setX` action'ları. Bu hata GÖNDEREN uygulamada değil ALICI süreçte (launcher) oluşur → kendi logcat'inizde iz bırakmaz. Bkz. `android/CLAUDE.md`.

## 11. Görsel işleme

`tool/` altında elle çalıştırılan tek-seferlik betikler (`image` paketi = `dev_dependency`). Arka plan temizleme (`remove_bg.dart` beyaz, `remove_black_bg.dart` siyah), kırpma, poz normalizasyonu, widget/önizleme asset üretimi. Bkz. `tool/CLAUDE.md`. PNG şeffaflık doğrulaması: önizleme aracına GÜVENME — pikselin HAM alfa değerini ölç.
