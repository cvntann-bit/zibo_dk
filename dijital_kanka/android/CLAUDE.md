# `android/` — Android / release / native kuralları

## Release imzalama

- `android/upload-keystore.jks` + `android/key.properties` (ikisi de `.gitignore`'da — YEDEĞİ şifre yöneticisinde olmalı). `build.gradle.kts` `key.properties`'i `rootProject.file(...)` ile okur; dosya YOKSA build kırılmaz, sessizce debug imzasına düşer → `flutter build appbundle --release`'den ÖNCE `key.properties`'in var olduğunu kontrol et.
- **Play App Signing aktif** — Google APK'yı KENDİ App Signing Key'iyle YENİDEN imzalar. Dağıtılan APK'nın imzasını Play Console ekran görüntüsünden kopyalama; `adb shell pm path` + `adb pull` + `apksigner verify --print-certs` ile ÖLÇ.
- **Firebase'e İKİ SHA sertifikası kayıtlı olmalı**: upload/imzalama sertifikası (yerel `adb install` testleri) + Play App Signing Key (Play Store'dan indiren gerçek kullanıcılar). Şu an `google-services.json`'da 4 hash var.
- `pubspec.yaml` `+N` her Play yüklemesinde bir öncekinden KESİN büyük (tüm track'ler genelinde, sonsuza dek).
- AAB: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`. Prosedür → `.claude/skills/release-aab/`.

## R8 / kaynak küçültme (`isMinifyEnabled = true`, `isShrinkResources = true`)

- R8 yalnızca native/Kotlin/Java katmanını işler — tüm Dart kodu AOT ile ayrı `libapp.so`'ya derlenir, R8 görmez. Risk yalnızca native plugin köprüsünde.
- **`res/raw/keep.xml`** — yalnızca çalışma-zamanında STRING adıyla okunan kaynakları listeler (`@raw/zibo_notification`, `@string/default_web_client_id`). Eklenmezse R8 SESSİZCE siler → çökme (ses yok / Google Sign-In "hiçbir şey olmuyor"). Detay → `docs/decisions/010`.
- **`proguard-rules.pro`** minimal — Flutter embedding, Play Core `-dontwarn`, Credential Manager `-keep`, **`androidx.work.**`/`androidx.room.**` `-keep`** (WorkManager'ın generated `_Impl` sınıfları — transitif plugin bağımlılığı, silinince açılışta `WorkDatabase` çökmesi).
- **GERÇEK doğrulama = derleme BAŞARISI DEĞİL** — `flutter build apk --release` + gerçek cihaza kur + AÇ. WorkManager çökmesi ilk derlemede değil yalnızca cihazda uygulamayı açınca ortaya çıktı.

## `AndroidManifest.xml`

- `<queries>` bloğu: `mailto:`/`https:`/`market:` intent'leri + agresif OEM (Xiaomi/Huawei/Oppo/Vivo/OnePlus) autostart paket adları — Android 11+ paket görünürlüğü için açıkça listelenmeli, yoksa `canLaunchUrl`/`canResolveActivity` hep `false`.
- 5 widget `<receiver>` (`.widgets.ZiboXWidgetProvider`, `APPWIDGET_UPDATE`) + `MainActivity`'de `es.antonborri.home_widget.action.LAUNCH` intent-filter.
- Appodeal `com.google.android.gms.ads.APPLICATION_ID` meta-data'sı GEREKTİRMEZ (AdMob'un aksine — o kaldırıldı). Appodeal App Key doğrudan Dart'tan (`AppodealConfig.appKey`).
- `MainActivity.kt` `onCreate()`'te `WindowCompat.setDecorFitsSystemWindows(window, true)` — Android 15 edge-to-edge zorlamasına karşı savunmacı. (`AdActivity` tema override'ı AdMob kaldırılınca gitti.)

## TikTok Business SDK (kurulum/olay takibi — UA kampanyaları)

- 2026 — TikTok Ads Manager'da "App promotion" kampanyası için gerekli. Resmi Flutter paketi
  (`tiktok_business_sdk`, pub.dev) 1 yıldır güncellenmemiş/deneysel (v0.0.1) — kullanılmadı. SDK
  tamamen **native** tarafta: `TikTokConfig.kt` (App ID/TT App ID/Access Token — TikTok'un "App
  Secret" dediği, ama Appodeal App Key'le AYNI sınıf: gerçek sunucu sırrı değil, APK'ya gömülen
  istemci kimliği) + `MainActivity.onCreate()`'te `TikTokBusinessSdk.initializeSdk(...)`. Dart'a
  HİÇ köprü YOK — SDK kurulum/açılış olaylarını `ProcessLifecycleOwner` ile kendisi otomatik izliyor.
- Bağımlılık JitPack'ten (`com.github.tiktok:tiktok-business-android-sdk`) geliyor — Maven
  Central/Google deposunda YOK, bu yüzden `android/build.gradle.kts`'e `maven { url =
  uri("https://jitpack.io") }` eklendi. Sürüm yükseltirken resmi `tiktok/tiktok-business-android-sdk`
  GitHub reposunun (ByteDance'in ARŞİVLENMİŞ `bytedance/...` fork'u DEĞİL) en güncel etiketini kullan.
- TikTok Ads Manager'daki "Verify setup" adımı ancak SDK'lı bir build **gerçek cihazda açılınca**
  olayları görür — bu yüzden kampanya kurulumu, yeni AAB Play'e yüklenip bir cihazda çalıştırılana
  kadar tamamlanamaz.
- **2026-09-12 — "No event data yet" teşhisi**: doğru build (1.10.0+29) cihazda kurulu/açık olsa ve
  Events Manager'ın QR-kod "Test event" eşleşmesi ("Connected devices: 1") başarılı olsa bile hiç
  event görünmedi. `initializeSdk(config)`'in callback'siz overload'u başarı/hatayı TAMAMEN sessiz
  bırakıyor — teşhis için `TTInitCallback` + `setLogLevel(DEBUG)` eklendi, sonuç `MainActivity.kt` →
  `MethodChannel("dijital_kanka/tiktok_sdk_diagnostic")` → `main.dart`'taki mevcut
  `FirebaseCrashlytics.instance.recordError(..., fatal: false)` deseniyle (Appodeal init hatalarıyla
  AYNI yol) Firebase Console'a taşınıyor — cihaza fiziksel erişim/adb GEREKMEDEN uzaktan okunabilir.
- **1.10.1+30'da bu teşhis mesajının KENDİSİ de hiç gelmedi** (Crashlytics'te "tiktok-sdk-diagnostic"
  diye bir kayıt hiç oluşmadı, ama AYNI sürümden diğer non-fatal'lar — Appodeal — normal şekilde
  geliyordu, yani Crashlytics bağlantısının kendisi ÇALIŞIYORDU). Kök neden bir YARIŞ DURUMU: Dart
  tarafındaki `_listenForTikTokDiagnostics()` çağrısı `main()`'de `Firebase.initializeApp()` +
  `signInAnonymously()` + `logAppOpen()` `await`'lerinden SONRAYDI; native taraftaki
  `TikTokBusinessSdk.initializeSdk(config, callback)` çağrısının callback'i bu zincir bitmeden
  dönebiliyor — `MethodChannel.invokeMethod` Dart'ta HENÜZ hiçbir handler kayıtlı değilken gelirse
  mesaj HİÇBİR YERDE hata vermeden kaybolur. 1.10.2+31'de dinleyici `main()`'in `Widgets
  FlutterBinding.ensureInitialized()`'tan HEMEN sonraki ilk satırına taşındı; mesaj bir değişkende
  bekletilip Firebase hazır olunca (`_firebaseReadyForTikTokDiagnostic = true`) gönderiliyor. Bu
  desen (erken kayıt + "hazır olunca flush et") — native→Dart köprüsü kurarken bir daha akla gelsin.

## RemoteViews (Ana Ekran Widget'ları — `.../kotlin/.../widgets/`)

- **YALNIZCA beyaz-listedeki view sınıfları inflate edilir**: `FrameLayout`/`LinearLayout`/`RelativeLayout`/`TextView`/`ImageView`/`ProgressBar`/`ViewFlipper`/`Button`/`Chronometer`. Ham `<View>` / `<Space>` DEĞİL → `InflateException: Class not allowed`. Boşluk için komşu elemanın `layout_margin*`'ini kullan.
- **YALNIZCA beyaz-listedeki `setX` action'ları**: `setImageViewResource`, `setTextViewText`, `setInt(id, "setBackgroundColor"/"setColorFilter", ...)`, `setProgressBar` vb. `setProgressTintList` gibi reflection çağrıları DEĞİL. `android:rotation` gibi statik XML öznitelikleri güvenli (inflate-zamanı, action değil).
- **Bu hata GÖNDEREN uygulamada değil ALICI süreçte (launcher / SystemUI) oluşur** → kendi paketinizin logcat'inde HİÇ iz bırakmaz. `adb logcat`'i `AppWidgetHostView` / `Launcher` / `NotificationManagerService` etiketleriyle de ara.
- Widget güncelleme: `HomeWidgetSyncCoordinator` → `HomeWidget.saveWidgetData` + `updateWidget`. Carousel'ler (`ZiboMotivationWidgetProvider`/`ZiboProfileStatsWidgetProvider`) `RemoteViews.addView(...)` ile `ViewFlipper`'a sayfa ekler (native `flipInterval` — Dart açık olmasa bile döner).
- `android:previewLayout` (API 31+) bazı launcher'larda (MIUI) render EDİLMİYOR → `android:previewImage` PNG fallback'i de gerekli (`lib/widget_preview_generator_main.dart` gerçek cihazda üretir + `tool/compose_widget_previews.dart` logo bindirir).
- MIUI `requestPinAppWidget()` `isRequestPinAppWidgetSupported()` `true` dese bile SESSİZCE no-op → `WidgetsScreen` artık "Ekle iddiası" yerine 3 adımlı manuel talimat sheet'i gösterir.

## Bildirimler / kanallar

- Bir Android bildirim kanalı BİR KEZ oluşturulduktan sonra kod'daki ses/ayar değişikliği kanalı GÜNCELLEMEZ. "Kod doğru ama cihazda çalışmıyor" raporunda İLK adım: kullanıcıdan Ayarlar > Uygulamalar > Zibo > Bildirimler'de kanalın GERÇEKTE ne gösterdiğini sor. Çözüm: uygulamayı TAMAMEN kaldır + yeniden kur (yalnızca `adb install -r` YETMEZ).
- `notificationsFeatureEnabled` (`lib/config/notification_config.dart`) `false` iken `daily_reminders` kanalı HİÇ oluşturulmaz (her alt kurulum adımı kendi flag'ine göre AYRI gate'lenmeli).

## `adb` / gerçek cihaz

- **Cihazdaki sürüm kullanıcının canlı Play Store kurulumu olabilir** (`adb shell dumpsys package | grep installerPackageName` → `com.android.vending`). Bunun üzerine debug build kurmak imza uyuşmazlığı → `uninstall` → kullanıcı verisi SİLİNİR. YAPMA.
- `INSTALL_FAILED_USER_RESTRICTED` (MIUI): Geliştirici Seçenekleri'nde "USB üzerinden yükleme" ayrı bir anahtar.
- Git Bash yol dönüştürmesi `/sdcard/...` yollarını bozar → `MSYS_NO_PATHCONV=1 adb shell ...`.
- `gh` CLI bu makinede YOK — GitHub API için `git credential fill` ile token al.
