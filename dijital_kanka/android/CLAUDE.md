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
- **Play Console "Uygulama optimizasyonu eşiğin altında" uyarısı (2026-09-12)**: App bundle explorer > Ayrıntılar, R8 yapılandırması Tam Mod/Kaynak Küçültme/Kullanılmayan Kaynak Kaldırma'nın üçü de AÇIKKEN tek eksik "Sınıfları Yeniden Paketleme" idi — düşük Optimizasyon/Kod karartma/Küçültme yüzdelerinin sebebi. Çözüm `-repackageclasses ''` — mevcut `-keep` kurallarına DOKUNMUYOR (yalnızca zaten obfuscate edilmeye izinli sınıfların paket yapısını düzleştiriyor), bu yüzden geçmişteki `res/raw/keep.xml` sınıfı riskte DEĞİL. Skor Play Console'da hemen değil, yeni sürüm birkaç gün Production'da kaldıktan sonra güncelleniyor.
- **Aynı uyarının "Bit eşlem resim optimizasyonu" kalemi**: `assets/images/`'daki büyük PNG'ler (kostüm/rozet/coin görselleri, toplam ~73MB) `tool/convert_images_to_webp.dart` ile kayıpsız WebP'ye çevrildi (~%25 küçülme, piksel-piksel doğrulandı) — bkz. `tool/CLAUDE.md` "Görsel varlıklar artık WebP" bölümü.
- **2026-09-16 — asıl boyut kazancı görsellerden çıktı, DEX'ten değil**: `--analyze-size` ile ölçülünce DEX yalnızca 9MB'ken `assets/` 58MB'dı (101MB toplam AAB'nin baskın kısmı) — Play Console'un DEX yüzdesi zaten çözülmüş küçük bir yan konu. `image` pub paketinin `encodeWebP`'si YALNIZCA VP8L (lossless) yazabiliyor (kaynağı okunarak doğrulandı, lossy VP8 encoder YOK), bu yüzden gerçek kayıplı sıkıştırma için Google'ın `cwebp`'i (libwebp, `winget install Google.Libwebp`) kullanıldı — `tool/convert_images_to_webp_lossy.dart`, kalite 85. `assets/images` 56MB → 11MB, toplam AAB (tek-ABI arm64 `--analyze-size`) 101MB → 56MB. Piksel-piksel eşitlik artık mümkün değil (lossy) — doğrulama: saydam pikseller saydam kalmalı + ortalama RGB farkı eşik altında + elle görsel spot-check.

## Eklenti/SDK sürümü değişince

- `stack_appodeal_flutter` 4.2.0 → 4.3.1 sonrası ilk release derlemesi eklentinin KENDİ sınıflarını "Unresolved reference" diye
  bulamadı (eski Kotlin önbelleği) — `flutter clean` + `flutter pub get` ile geçti. Eklenti sürümü değişince önce `flutter clean`.
- Appodeal adaptör sürümleri eklentinin `example/android/app/build.gradle` setinden alınır. AppLovin 13.6.x ile R8 `com.amazon.privacypass`
  "Missing class" der → `proguard-rules.pro`'daki `-dontwarn com.amazon.privacypass.**` bunun için (Vungle 7.7.x bunu kendi kuralıyla
  örtüyordu AMA kilitli sınıfı 22 → 670 artırıyor; bu yüzden Vungle 7.6.1.0'da bırakıldı).

## Yeni reklam ağı (Appodeal adaptörü) eklemeden ÖNCE — DEX kontrol listesi (2026-10-24, ölçülmüş)

Bir ağın DEX maliyeti kendi kod boyutu değil, **kural dosyasının (consumer `proguard.txt`) neyi kilitlediği**dir. Vungle 7.6.1: kendi kodu 594 sınıf
ama `-keep class com.google.android.gms.** {*;}` + protobuf keep'leri yüzünden Play Services/Firebase/Firestore kodunun ~3.600 sınıfı kilitleniyordu;
çıkarınca Play optimizasyon %28 → %36. Eklemeden önce: (1) adaptör AAR'ı (`artifactory.appodeal.com/.../adapters/<ağ>/<sürüm>`) + ağın KENDİ SDK AAR'ının
`proguard.txt`'ini oku (`unzip -p x.aar proguard.txt`); (2) `com.google.**`, `androidx.**`, `com.google.protobuf.**` için geniş `-keep` ara — varsa pahalıdır;
(3) release APK derle, `build/app/outputs/mapping/release/{mapping,seeds,configuration}.txt` ile kilitli sınıf oranını ve `seeds.txt` kayıt sayısını önceki derlemeyle kıyasla;
(4) Play skoru yalnızca yeni bundle yüklenince görünür. Ölçülenler: Yandex yığını ~35K kilitli kayıt, AppLovin ~19K, Mintegral ~+3,5K sınıf (oran %53→%59,5), Meta adaptörü ~+180 sınıf (ucuz) AMA Appodeal rehberi BidMachine'i şart koşuyor (+~65K kayıt, pahalı).
Aday ağ kuralları: unity_ads SDK `-keep class com.unity3d.** {}` + `-keep public class com.google.protobuf.** {}` (pahalı, 2026-09'da zaten çıkarılmıştı); inmobi/ironsource/my_target adaptörleri geniş keep taşıyor; dt_exchange/bigo/moloco/pubmatic adaptör kuralları temiz (SDK kuralları doğrulanmadı).

## `AndroidManifest.xml`

- `<queries>` bloğu: `mailto:`/`https:`/`market:` intent'leri + agresif OEM (Xiaomi/Huawei/Oppo/Vivo/OnePlus) autostart paket adları — Android 11+ paket görünürlüğü için açıkça listelenmeli, yoksa `canLaunchUrl`/`canResolveActivity` hep `false`.
- 5 widget `<receiver>` (`.widgets.ZiboXWidgetProvider`, `APPWIDGET_UPDATE`) + `MainActivity`'de `es.antonborri.home_widget.action.LAUNCH` intent-filter.
- Appodeal `com.google.android.gms.ads.APPLICATION_ID` meta-data'sı GEREKTİRMEZ (AdMob'un aksine — o kaldırıldı). Appodeal App Key doğrudan Dart'tan (`AppodealConfig.appKey`).
- `MainActivity.kt` `onCreate()`'te `WindowCompat.setDecorFitsSystemWindows(window, true)` — Android 15 edge-to-edge zorlamasına karşı savunmacı. (`AdActivity` tema override'ı AdMob kaldırılınca gitti.)

## TikTok Business SDK — KALDIRILDI (2026-10-22)

- Kullanıcı TikTok'ta artık reklam vermiyor → SDK, JitPack deposu, `TikTokConfig.kt`, `MainActivity` init/teşhis kodu,
  `main.dart` teşhis köprüsü ve proguard `com.tiktok` kuralı silindi (DEX'te ~159 sınıf, hepsi karartılmamış).
  Gerekirse eski hali git geçmişinde (ör. `git log -S TikTokBusinessSdk`).

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
