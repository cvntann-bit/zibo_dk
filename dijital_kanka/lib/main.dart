import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

import 'config/appodeal_config.dart';
import 'data/app_themes.dart';
import 'l10n/app_localizations.dart';
import 'providers/ad_free_provider.dart';
import 'providers/app_streak_provider.dart';
import 'providers/app_theme_provider.dart';
import 'providers/auth_link_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/coin_provider.dart';
import 'providers/costume_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/custom_messages_provider.dart';
import 'providers/daily_rewards_provider.dart';
import 'providers/dream_journal_provider.dart';
import 'providers/favorite_quotes_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/founder_badge_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/gratitude_provider.dart';
import 'providers/hidden_badge_provider.dart';
import 'providers/home_quick_widgets_provider.dart';
import 'providers/instagram_follow_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/manifest_provider.dart';
import 'providers/money_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/push_notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/profile_stats_archive_provider.dart';
import 'providers/referral_provider.dart';
import 'providers/sound_effects_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trusted_time_provider.dart';
import 'providers/water_provider.dart';
import 'providers/xp_provider.dart';
import 'providers/zibo_pose_provider.dart';
import 'utils/ad_free_promo_trigger.dart';
import 'utils/rate_prompt_trigger.dart';
import 'utils/banner_ad_reload_signal.dart';
import 'utils/auth_switch.dart';
import 'utils/root_navigator_key.dart';
import 'models/app_theme_option.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'services/ad_service.dart';
import 'services/appodeal_ad_service.dart';
import 'services/google_auth_service.dart';
import 'services/home_widget_service.dart';
import 'services/iap_purchase_service.dart';
import 'services/purchase_service.dart';
import 'services/push_notification_service.dart';
import 'services/sound_effects_service.dart';
import 'widgets/ad_blur_overlay.dart';
import 'widgets/animated_theme_overlay.dart';
import 'widgets/app_loading_screen.dart';
import 'widgets/badge_celebration_overlay.dart';
import 'widgets/level_celebration_overlay.dart';
import 'widgets/sticker_style.dart' show kStickerOutline;
import 'widgets/theme_fade_overlay.dart';

// Zibo'nun tombul, sıcak, samimi karakterine uygun bal/hardal/krem paleti
// (açık tema) ve aynı ruhu koyu zeminde taşıyan bir koyu tema karşılığı.
// Anahtar tonlar elle sabitleniyor ki ColorScheme.fromSeed'in otomatik
// türetmesi soluk/pembemsi ya da tam parlak sarıya kaymasın.
const _mustard = Color(0xFFA9711F); // koyu hardal/kahverengi — auto-türetilen tonlar için seed
// "Çizgi Roman Çıkartması" mockup'ının `--gold` değişkeniyle BİREBİR aynı,
// canlı/karikatürsü altın-sarı — kullanıcı "html'deki sarı daha canlı ve
// cartoon, onu kullan" dedi. `_mustard` (koyu, donuk kahverengi-sarı) SADECE
// `ColorScheme.fromSeed`'in otomatik türettiği (elle override edilmeyen)
// tonlar için seed olarak kalıyor — asıl görünür `primary` artık bu.
const _vividGold = Color(0xFFF3B23C);
const _honey = Color(0xFFEFCB7A); // açık bal tonu — ikincil/tonal vurgu
const _cream = Color(0xFFFFF8E8); // sıcak krem — açık tema arka planı
const _honeyCream = Color(0xFFF7EAC9); // açık tema kart/yüzey rengi
const _honeyCreamHigh = Color(0xFFF4E1B4); // açık temada biraz daha koyu yüzey
const _espresso = Color(0xFF4A3620); // sıcak koyu kahve — açık temada metin
const _espressoSoft = Color(0xFF7A5C34); // açık temada ikincil metin
const _sandOutline = Color(0xFFDCC28A); // açık temada kenarlık/ayraç rengi
const _terracotta = Color(0xFFB5502A); // açık temada "kaçırıldı" uyarı rengi
const _terracottaContainer = Color(0xFFF6D9BE);

// Koyu tema: çok koyu (neredeyse siyah) antrasit zemin + göz yormayan
// sarımtrak/krem metin. Zibo görseli, coin ikonu gibi görseller değişmez —
// yalnızca renkler (ColorScheme üzerinden) etkilenir.
const _darkBackground = Color(0xFF17140F); // çok koyu, hafif sıcak antrasit
const _darkSurfaceContainer = Color(0xFF231F19); // koyu temada kart yüzeyi
const _darkSurfaceContainerHigh = Color(0xFF2B261F); // biraz daha açık yüzey
const _darkCream = Color(0xFFE3C179); // koyu temada metin: göz yormayan sarımtrak
const _darkCreamSoft = Color(0xFFB89A5E); // koyu temada ikincil metin
const _darkGold = Color(0xFFD9A94A); // koyu temada buton/vurgu rengi
const _darkOnGold = Color(0xFF2A1E0A); // altın rengi buton üzerindeki koyu metin
const _darkGoldContainer = Color(0xFF3A2F1C); // koyu temada tonal buton zemini
const _darkOutline = Color(0xFF4A4033);
const _darkTerracotta = Color(0xFFCC7A4A);
const _darkTerracottaContainer = Color(0xFF3D2A1C);

final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: _mustard,
  brightness: Brightness.light,
).copyWith(
  primary: _vividGold,
  // Canlı altın-sarı üzerinde beyaz metin/ikonun kontrastı ZAYIF (bkz.
  // yukarıdaki `_vividGold` notu) — mockup da AYNI sebeple altın dolgular
  // üzerinde hep sabit koyu `--outline` kullanıyor, beyaz DEĞİL.
  onPrimary: kStickerOutline,
  primaryContainer: _honey,
  onPrimaryContainer: _espresso,
  secondaryContainer: _honey,
  onSecondaryContainer: _espresso,
  surface: _cream,
  onSurface: _espresso,
  onSurfaceVariant: _espressoSoft,
  surfaceContainer: _honeyCream,
  surfaceContainerHigh: _honeyCreamHigh,
  surfaceContainerHighest: _honeyCreamHigh,
  outlineVariant: _sandOutline,
  error: _terracotta,
  errorContainer: _terracottaContainer,
  onErrorContainer: _terracotta,
);

final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: _mustard,
  brightness: Brightness.dark,
).copyWith(
  primary: _darkGold,
  onPrimary: _darkOnGold,
  primaryContainer: _darkGoldContainer,
  onPrimaryContainer: _darkCream,
  secondaryContainer: _darkGoldContainer,
  onSecondaryContainer: _darkCream,
  surface: _darkBackground,
  onSurface: _darkCream,
  onSurfaceVariant: _darkCreamSoft,
  surfaceContainer: _darkSurfaceContainer,
  surfaceContainerHigh: _darkSurfaceContainerHigh,
  surfaceContainerHighest: _darkSurfaceContainerHigh,
  outlineVariant: _darkOutline,
  error: _darkTerracotta,
  errorContainer: _darkTerracottaContainer,
  onErrorContainer: _darkCream,
);

final _buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
);

/// "Çizgi Roman Çıkartması" görsel kimliğinin tipografi çifti (bkz.
/// `docs/theme_new.md` "Tipografi" bölümü): başlıklarda SEYREK kullanılan
/// yuvarlak/oyuncu **Baloo 2**, gövde/UI metninde **Nunito**.
///
/// İkisi de `assets/fonts/`'a gömülü DEĞİŞKEN (variable) font dosyaları —
/// `google_fonts` paketinin yaptığı gibi çalışma zamanında internetten
/// İNDİRİLMİYOR. Bu bilinçli bir tercih: ilk denemede `google_fonts`
/// kullanıldığında ağı olmayan bir cihazda/emülatörde font sessizce
/// sistem varsayılanına düşüyordu (indirme başarısız oluyor ama hata
/// göstermiyordu) — bu hem güvenilmez hem de gerçek kullanıcının ilk
/// açılışta ağı yoksa aynı soruna düşebileceği anlamına geliyordu. Ağırlık
/// `FontVariation` ile açıkça seçiliyor (tek bir değişken dosya TÜM
/// ağırlıkları taşıyor, `FontWeight`'in otomatik eşleşmesine güvenmek
/// yerine).
TextStyle _withFont(TextStyle? style, String family, double weight) {
  return (style ?? const TextStyle()).copyWith(
    fontFamily: family,
    fontVariations: [FontVariation('wght', weight)],
  );
}

TextTheme _buildTextTheme(ColorScheme colorScheme) {
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
  ).textTheme;
  return base.copyWith(
    displayLarge: _withFont(base.displayLarge, 'Baloo2', 700),
    displayMedium: _withFont(base.displayMedium, 'Baloo2', 700),
    displaySmall: _withFont(base.displaySmall, 'Baloo2', 700),
    headlineLarge: _withFont(base.headlineLarge, 'Baloo2', 700),
    headlineMedium: _withFont(base.headlineMedium, 'Baloo2', 700),
    headlineSmall: _withFont(base.headlineSmall, 'Baloo2', 700),
    titleLarge: _withFont(base.titleLarge, 'Baloo2', 700),
    titleMedium: _withFont(base.titleMedium, 'Nunito', 700),
    titleSmall: _withFont(base.titleSmall, 'Nunito', 700),
    bodyLarge: _withFont(base.bodyLarge, 'Nunito', 400),
    bodyMedium: _withFont(base.bodyMedium, 'Nunito', 400),
    bodySmall: _withFont(base.bodySmall, 'Nunito', 400),
    labelLarge: _withFont(base.labelLarge, 'Nunito', 700),
    labelMedium: _withFont(base.labelMedium, 'Nunito', 600),
    labelSmall: _withFont(base.labelSmall, 'Nunito', 600),
  );
}

/// Açık ve koyu temanın ikisi de aynı yapı taşlarını (kart, buton, giriş
/// alanı stilleri) paylaşır; yalnızca renkleri farklıdır. Bu ortak fonksiyon
/// sayesinde iki tema birbirinden kopyala-yapıştır olmuyor.
ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    useMaterial3: true,
    textTheme: _buildTextTheme(colorScheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: colorScheme.primary.withValues(alpha: 0.18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: _buttonShape,
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _buttonShape,
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: _buttonShape,
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
  );
}

final _lightTheme = _buildTheme(_lightColorScheme);
final _darkTheme = _buildTheme(_darkColorScheme);

/// Bir Firestore transaction'ı bittikten sonra `cloud_firestore` plugin'inin,
/// o transaction'a özel platform akışını kapatırken (engine detach anında)
/// fırlattığı `MissingPluginException`'ı tanır — bkz.
/// `PlatformDispatcher.instance.onError` içindeki uzun not. Kanal adı
/// `plugins.flutter.io/firebase_firestore/transaction/<uuid>` desenini taşır.
bool _isBenignFirestoreStreamTeardownError(Object error) {
  if (error is! MissingPluginException) return false;
  final message = error.message ?? '';
  return message.contains('firebase_firestore/transaction');
}

/// `MainActivity.kt`'deki `TikTokBusinessSdk.initializeSdk(...)` çağrısının
/// sonucunu (başarı/hata/istisna) taşıyan tek yönlü kanal — bkz.
/// `android/CLAUDE.md` "TikTok Business SDK" bölümü. SDK native tarafta
/// tamamen kendi kendine çalıştığı için Dart'a normalde HİÇ köprü yok; bu
/// TEK istisna, Events Manager'da event hiç görünmeyince (2026-09-12) cihaza
/// fiziksel erişim/adb GEREKMEDEN init sonucunu uzaktan (Firebase Console)
/// görebilmek için eklendi.
const _tikTokDiagnosticChannel = MethodChannel(
  'dijital_kanka/tiktok_sdk_diagnostic',
);

/// `main()`'in `WidgetsFlutterBinding.ensureInitialized()`'tan SONRAKİ ilk
/// satırında kaydediliyor — bir önceki sürümde `Firebase.initializeApp()` +
/// `signInAnonymously()` + `logAppOpen()` `await`'lerinden SONRA
/// kaydediliyordu, ve `MainActivity.kt`'deki native çağrı bu `await` zincirini
/// bitirmeden dönebiliyordu: `MethodChannel.invokeMethod`, Dart tarafında
/// HENÜZ hiçbir handler kayıtlı değilken gelirse mesaj sessizce KAYBOLUYOR
/// (ne native tarafta ne Dart tarafta hiçbir hata/istisna görünmüyor) — bu
/// yüzden Firebase Crashlytics'te "tiktok-sdk-diagnostic" hiç görünmedi.
/// Mesaj bu değişkende, Crashlytics güvenle çağrılabilir hale gelene (bkz.
/// `main()`'deki `_firebaseReady = true` satırı) kadar bekletiliyor.
String? _pendingTikTokDiagnostic;
bool _firebaseReadyForTikTokDiagnostic = false;

void _listenForTikTokDiagnostics() {
  _tikTokDiagnosticChannel.setMethodCallHandler((call) async {
    if (call.method != 'log') return;
    final message = call.arguments as String? ?? 'bilinmeyen mesaj';
    debugPrint('TikTok SDK diagnostic: $message');
    _pendingTikTokDiagnostic = message;
    await _flushTikTokDiagnosticIfReady();
  });
}

Future<void> _flushTikTokDiagnosticIfReady() async {
  if (!_firebaseReadyForTikTokDiagnostic) return;
  final message = _pendingTikTokDiagnostic;
  if (message == null) return;
  _pendingTikTokDiagnostic = null;
  await FirebaseCrashlytics.instance.recordError(
    'TikTok SDK diagnostic: $message',
    null,
    reason: 'tiktok-sdk-diagnostic',
    fatal: false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `Firebase.initializeApp()`'tan ÖNCE, herhangi bir `await`'in native
  // taraftaki hızlı callback'i geride bırakmasına fırsat kalmadan — bkz.
  // yukarıdaki `_pendingTikTokDiagnostic` dokümantasyonu.
  _listenForTikTokDiagnostics();
  // "Zibo ADS" tanıtım sıklığının en son gösterim zamanını (kalıcı, oturumlar
  // arası) belleğe yükler — bkz. ad_free_promo_trigger.dart. `runApp`'tan
  // ÖNCE tamamlanması gerekiyor, aksi halde ilk Mağaza ziyaretinde henüz
  // yüklenmemiş sayılıp tetikleyici hiç göstermez (bkz. o dosyadaki güvenli
  // varsayılan).
  await AdFreePromoTrigger.initialize();
  await RatePromptTrigger.initialize();
  // `android/app/google-services.json`'daki proje bilgilerini okuyup
  // Firebase'i başlatır — Android tarafında `google-services` Gradle
  // plugin'i (bkz. android/app/build.gradle.kts) bu dosyadan gerekli
  // yapılandırmayı derleme zamanında üretir, burada ayrıca elle bir
  // `FirebaseOptions` vermeye gerek yok. Yalnızca Android hedeflendiği için
  // (bkz. CLAUDE.md — web önizlemesi yalnızca dev/görsel doğrulama amaçlı,
  // ayrı bir `FirebaseOptions` yapılandırması YOK) try/catch ile sarılı:
  // web'de veya ilk kurulum sırasında bir sorun olursa uygulama Firebase'siz
  // de açılmaya devam etsin.
  //
  // `uid`, kullanıcının anonim (isim/şifre GEREKTİRMEYEN) Firebase kimliği —
  // TÜM "güne bağlı"/kullanıcı verisi provider'larına (bkz. CLAUDE.md
  // "Firestore Veri Kalıcılığı" bölümü) buradan aktarılır. `null` kalırsa
  // (Firebase kullanılamıyor) her provider otomatik olarak saf-yerel
  // (`SharedPreferences`) moda düşer — hiçbir yerde Firebase'e SERT bir
  // bağımlılık yok.
  String? uid;
  try {
    await Firebase.initializeApp();
    // FCM push bildirimleri: uygulama TAMAMEN KAPALIYKEN gelen mesajları
    // işleyecek üst düzey handler'ı kaydeder — `runApp`'tan ÖNCE
    // yapılmalı (bkz. `firebaseMessagingBackgroundHandler` dokümantasyonu).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    var user = FirebaseAuth.instance.currentUser;
    // Cihazda daha önce oturum açılmışsa (Firebase Auth SDK'sı bunu kendi
    // yerel deposunda kalıcı tutar) AYNI anonim kimlik korunur — her açılışta
    // YENİ bir kullanıcı/uid oluşmaz.
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    uid = user?.uid;
    // Analytics SDK'sının gerçekten çalıştığını doğrulamak (ve Firebase
    // Console'un "kurulum doğrulandı" adımını hemen geçmesini sağlamak)
    // için standart `app_open` olayını logluyoruz — özel bir olay şeması
    // YOK, yalnızca bağlantıyı kanıtlayan minimum çağrı.
    await FirebaseAnalytics.instance.logAppOpen();
    // Çökme/hata izleme (Crashlytics) — bkz. CLAUDE.md "Crashlytics"
    // bölümü. Firebase kullanılamıyorsa (web önizlemesi, test ortamı) bu
    // blok hiç ÇALIŞMIYOR (aynı try/catch'in İÇİNDE) — Crashlytics'i
    // GEREKTİREN bir global hata yakalayıcı asla Firebase'siz bir ortamda
    // KURULMUYOR.
    //
    // (1) Flutter FRAMEWORK'ünün kendi hata mekanizması (widget build/
    // layout/paint hataları) — varsayılan davranış (konsola yazdırıp devam
    // etmek) yerine ARTIK Crashlytics'e de FATAL olarak bildiriliyor.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // (2) Flutter'ın KENDİ hata bölgesinin (error zone) DIŞINDA kalan
    // hatalar — ör. bir `Future` içinde yakalanmamış (unhandled) asenkron
    // bir hata, veya bir platform kanalı callback'inde fırlatılan bir
    // istisna. `true` dönmek "bu hatayı BEN halloştim, platformun kendi
    // varsayılan davranışını (uygulamayı sonlandırma) TETİKLEME" demek —
    // Crashlytics'e KAYDETTİKTEN sonra uygulamanın MÜMKÜNSE çalışmaya
    // devam etmesi tercih edildi.
    PlatformDispatcher.instance.onError = (error, stack) {
      // Bilinen, ZARARSIZ `cloud_firestore` yarışı — bir Firestore
      // transaction'ı (bkz. `FounderBadgeProvider.claimIfEligible`) bittikten
      // SONRA plugin, o transaction'a özel `EventChannel` akışını KAPATMAYA
      // çalışıyor; uygulama tam o anda arka plana atılıp Flutter engine
      // detach olursa native handler zaten kaldırılmış oluyor →
      // `MissingPluginException(... firebase_firestore/transaction/<uuid> ...)`.
      // Transaction'ın KENDİSİ çoktan tamamlanmış, veri ETKİLENMİYOR. FATAL
      // olarak raporlamak crash-free oranını yanıltıyor ve gereksiz
      // "regressed issue" uyarısı üretiyor — yine de non-fatal olarak
      // kaydediyoruz ki büsbütün kör kalmayalım.
      if (_isBenignFirestoreStreamTeardownError(error)) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
        return true;
      }
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // (3) TikTok SDK teşhis köprüsü — dinleyici `main()`'in EN başında
    // kaydedildi (bkz. yukarıdaki dokümantasyon); burada yalnızca
    // `FirebaseCrashlytics.instance` artık güvenle çağrılabilir olduğunu
    // işaretleyip native taraftan bu ana kadar gelmiş olabilecek mesajı
    // (varsa) hemen gönderiyoruz.
    _firebaseReadyForTikTokDiagnostic = true;
    await _flushTikTokDiagnosticIfReady();
  } catch (_) {
    // Firebase/Auth başlatılamadı (ör. web önizlemesi, ağ yok, yapılandırma
    // eksik) — `uid` `null` kalır, uygulama Firebase'e bağımlı olmadan
    // (tamamen yerel depoyla) sorunsuz çalışmaya devam eder.
  }
  // Appodeal SDK'sı — Firebase'den TAMAMEN BAĞIMSIZ bir try/catch (biri
  // başarısız olursa diğerini etkilemesin diye). `Appodeal.initialize(...)`
  // AdMob'un `MobileAds.instance.initialize()`'ının AKSİNE `await`
  // EDİLMİYOR — paketin kendi API'si `initialize()`'dan hiçbir şey
  // DÖNDÜRMÜYOR (fire-and-forget, bkz. CLAUDE.md "AdMob Entegrasyonu"
  // bölümündeki Appodeal notu), yalnızca `runApp`'tan ÖNCE ÇAĞRILMASI
  // yeterli — SDK arka planda kendi kendine başlatılıp reklam yüklemeye
  // başlıyor, `AppodealAdService.showX()` zaten `isLoaded()`'i polling ile
  // bekliyor. `setTesting(kDebugMode)` DEBUG build'lerde HER ZAMAN test
  // reklamı gösterilmesini garanti ediyor — kullanıcının önceki AdMob
  // hesabının banlanmasına katkıda bulunan hatayı (gerçek reklam
  // birimleriyle kendi cihazından test etmek) bir daha TEKRARLAMAMAK için.
  // Web önizlemesinde veya platform desteklenmiyorsa (`flutter_test` dahil)
  // hatayı yutup uygulamanın reklamsız çalışmaya devam etmesine izin verir.
  try {
    Appodeal.setTesting(kDebugMode);
    // **2026 — CMP (Consent Management Platform).** Reklam SDK'sı, ilk reklam
    // isteğinden ÖNCE kullanıcının rıza durumunu bilmeli — bu yüzden
    // `initialize` DOĞRUDAN değil, consent formu tamamlandıktan SONRA
    // çağrılıyor. `loadAndShowIfRequired` yalnızca GEREKLİ olduğunda (AB/EEA
    // kullanıcısı, düzenlemeye tabi ABD eyaletleri) form gösteriyor; Türkiye
    // gibi yerlerde form HİÇ çıkmadan callback anında dönüyor.
    var appodealStarted = false;
    void startAppodealOnce() {
      if (appodealStarted) return;
      appodealStarted = true;
      _initializeAppodeal();
    }

    Appodeal.ConsentForm.loadAndShowIfRequired(
      appKey: AppodealConfig.appKey,
      onConsentFormDismissed: (error) {
        if (error != null) {
          debugPrint('Appodeal consent error: ${error.description}');
          try {
            FirebaseCrashlytics.instance.recordError(
              'Appodeal consent form error: ${error.description}',
              null,
              reason: 'appodeal-consent',
              fatal: false,
            );
          } catch (_) {}
        }
        startAppodealOnce();
      },
    );
    // Savunma katmanı: consent callback'i herhangi bir sebeple (plugin/native
    // takılması) HİÇ gelmezse reklamlar o oturum boyunca sonsuza dek
    // yüklenmez — 10 sn sonra yine de başlat.
    Future<void>.delayed(const Duration(seconds: 10), startAppodealOnce);
  } catch (_) {
    _initializeAppodeal();
  }
  runApp(_AppRoot(initialUid: uid));
}

/// `Appodeal.initialize` çağrısı — consent formu tamamlandıktan sonra
/// (`main()`'de) çağrılır. Ayrı bir fonksiyon çünkü İKİ yerden tetikleniyor:
/// consent callback'i VE 10 sn'lik savunma zamanlayıcısı (bkz. `main()`).
void _initializeAppodeal() {
  try {
    Appodeal.initialize(
      appKey: AppodealConfig.appKey,
      adTypes: const [
        AppodealAdType.RewardedVideo,
        AppodealAdType.Interstitial,
        // 2026 yeni özellik — kalıcı banner reklamlar (Ana Sayfa ve diğer
        // modül ekranlarına tek tek yerleştiriliyor, bkz. `HomeBannerAd`).
        AppodealAdType.Banner,
      ],
      // Init hataları eskiden tamamen yutuluyordu — "reklam gelmiyor"
      // tanısını imkânsız kılıyordu. Artık Crashlytics'e non-fatal olarak
      // loglanıyor (bir ağ adaptörü eksik/uyumsuzsa veya App Key yanlışsa
      // burada görünür).
      onInitializationFinished: (errors) {
        if (errors == null || errors.isEmpty) return;
        // **Bug düzeltmesi — Crashlytics'te 1.9.2'den beri her sürümde
        // tekrar eden bu non-fatal, TEŞHİS EDİLEMEZ haldeydi:** `errors`
        // elemanları `ApdInitializationError` — Dart'ın varsayılan
        // `toString()`'i override edilmeyen bir sınıf için yalnızca
        // "Instance of 'ApdInitializationError'" basıyor, gerçek nedeni
        // (hangi ağ adaptörü/App Key/config sorunu) HİÇ göstermiyordu.
        // Asıl bilgi `.description` alanında — artık ONU logluyoruz.
        final descriptions = errors.map((e) => e.description).join('; ');
        debugPrint('Appodeal init errors: $descriptions');
        // Firebase başlatılamadıysa (web önizleme / test) Crashlytics
        // çağrısı fırlatabilir — bu geç/asenkron callback ana try/catch'in
        // DIŞINDA çalıştığı için kendi guard'ı gerekiyor.
        try {
          FirebaseCrashlytics.instance.recordError(
            'Appodeal initialization finished with errors: $descriptions',
            null,
            reason: 'appodeal-init',
            fatal: false,
          );
        } catch (_) {}
      },
    );
    // **2026-09-22 düzeltmesi — kullanıcı raporu: "anasayfadaki banner alt
    // bar'ı kapatıyor, olması gereken yerde değil".** Buradaki ÖNCEKİ kod
    // `Appodeal.show(AppodealAdType.Banner)` çağırıyordu — bu, `BannerAdSlot`
    // içindeki gömülü `AppodealBanner` widget'ının kullandığı
    // `Appodeal.BANNER_VIEW` tipinden TAMAMEN FARKLI bir reklam yuvası
    // (`Appodeal.BANNER`, klasik/konteynersiz tip — paket kaynağı
    // `AppodealAdView.kt`'de doğrulandı). Appodeal'ın native SDK'sı bu
    // klasik tipi HERHANGİ bir widget'a gömmeden, ekranın ALT kenarına sabit
    // bir kaplama (overlay) olarak gösteriyor — bu yüzden doğru
    // konumlandırılmış (konuşma balonu/widget'lar arası) banner'ın YANINDA,
    // ekranın en altında alt navigasyon çubuğunu kapatan İKİNCİ, istenmeyen
    // bir reklam beliriyordu. Daha önce fark edilmemişti çünkü prod'da bu
    // klasik yuva genelde fill ALMIYORDU (bkz. daha önceki "no fill" teşhisi)
    // — debug build'de test reklamları HER ZAMAN fill aldığı için ortaya
    // çıktı. Artık `bannerAdReloadSignal`'ı artırıyoruz — `BannerAdSlot` bunu
    // dinleyip `AppodealBanner`'ı YENİDEN oluşturarak (native `init{}`'in
    // KENDİ, doğru `BANNER_VIEW` çağrısını tekrar tetikleyerek) reklamı
    // gömülü kabına yerleştiriyor. `onBannerFailedToLoad`/`onBannerShowFailed`
    // hâlâ AYNI gerekçeyle Crashlytics'e loglanıyor.
    Appodeal.setBannerCallbacks(
      onBannerLoaded: (isPrecache) {
        bannerAdReloadSignal.value++;
      },
      onBannerFailedToLoad: () {
        try {
          FirebaseCrashlytics.instance.recordError(
            'Appodeal banner failed to load',
            null,
            reason: 'appodeal-banner',
            fatal: false,
          );
        } catch (_) {}
      },
      onBannerShowFailed: () {
        try {
          FirebaseCrashlytics.instance.recordError(
            'Appodeal banner show failed',
            null,
            reason: 'appodeal-banner',
            fatal: false,
          );
        } catch (_) {}
      },
    );
  } catch (_) {}
}

/// `DijitalKankaApp`'i (dolayısıyla TÜM `MultiProvider` ağacını) hangi
/// `uid`'in yönettiğini tutan, uygulamanın GERÇEK kök widget'ı.
///
/// **2026 yeni özellik — Google ile hesap bağlama/kurtarma.** Bir hesap
/// BAĞLANDIĞINDA (`AuthLinkProvider.linkWithGoogle`) Firebase uid'i
/// DEĞİŞMEZ (anonim hesap Google'a "yükseltiliyor", aynı kimlik kalıyor) —
/// bu yüzden o akış için `_AppRoot`'un hiçbir şey yapmasına gerek YOK.
/// Ama bir kullanıcı YENİ bir cihazda "Google ile Giriş Yap" ile ESKİ bir
/// hesabı KURTARDIĞINDA (`AuthLinkProvider.signInWithGoogle`), dönen uid bu
/// cihazın o ana kadar kullandığı (taze/boş) anonim uid'den FARKLI olur —
/// TÜM `MultiProvider` ağacının (coin/hedefler/kostümler/her şey) o YENİ
/// uid ile SIFIRDAN kurulması gerekir. `switchToUid` (bkz. `utils/
/// auth_switch.dart`) sinyali geldiğinde `_uid`'i güncelleyip
/// `KeyedSubtree(key: ValueKey(_uid))` ile `DijitalKankaApp`'i SIFIRDAN
/// yeniden kurduruyoruz — `ProfileScreen`'in istatistik kartı animasyonunu
/// her girişte yeniden oynatmak için kullandığı AYNI "değişen Key ile
/// zorla yeniden kurdurma" tekniği (bkz. CLAUDE.md).
class _AppRoot extends StatefulWidget {
  const _AppRoot({required this.initialUid});

  final String? initialUid;

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late String? _uid = widget.initialUid;

  @override
  void initState() {
    super.initState();
    switchToUid.addListener(_onSwitchRequested);
  }

  void _onSwitchRequested() {
    final newUid = switchToUid.value;
    if (newUid != null && newUid != _uid && mounted) {
      setState(() => _uid = newUid);
    }
  }

  @override
  void dispose() {
    switchToUid.removeListener(_onSwitchRequested);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_uid),
      child: DijitalKankaApp(uid: _uid),
    );
  }
}

/// "Güne bağlı" bir provider'ın `now:` parametresi için, `create` context'ini
/// KAPATMAYAN (capture etmeyen) bir saat closure'ı üretir.
///
/// **Crashlytics — `_InheritedProviderScopeElement.widget` / "Null check
/// operator used on a null value" (Xiaomi + Android 14 activity restoration).**
/// Eski desen `now: () => context.read<TrustedTimeProvider>().now()` idi:
/// closure `create` context'ini SAKLIYORDU ve sonradan (uygulama arka plandan
/// öne gelince `RootScreen.didChangeAppLifecycleState` → `HomeWidgetSync
/// Coordinator` → `DailyRewardsProvider.todayIndex` → `_now()` zinciriyle)
/// çağrıldığında, o context'in elementi geçici olarak "deactivated" olabildiği
/// için `context.read`'in `visitAncestorElements` gezintisi unmount edilmiş bir
/// elemente çarpıp çöküyordu. Burada `TrustedTimeProvider` BİR KEZ, `create`
/// anında (ağaç kararlıyken) çözülüp elde edilen ÖRNEĞE bağlanıyor —
/// döndürülen closure artık hiçbir `BuildContext`'e dokunmuyor. `Trusted
/// TimeProvider` listede EN BAŞTA (bkz. altta) olduğu için onu kullanan her
/// provider'dan daha uzun yaşıyor, dangling referans riski yok.
DateTime Function() _trustedNow(BuildContext context) {
  final trustedTime = context.read<TrustedTimeProvider>();
  return trustedTime.now;
}

class DijitalKankaApp extends StatelessWidget {
  const DijitalKankaApp({
    super.key,
    this.uid,
    this.adService,
    this.purchaseService,
    this.homeWidgetService,
  });

  /// Kullanıcının anonim Firebase kimliği (bkz. `main()`) — `null` ise
  /// (Firebase kullanılamıyor VEYA test ortamı) TÜM aşağıdaki provider'lar
  /// otomatik olarak saf-yerel (`SharedPreferences`) moda düşer; hiçbir
  /// provider testi bu alanı VERMEZ, bu yüzden mevcut tüm testler
  /// değişmeden çalışmaya devam eder (bkz. `CloudStateStore` dokümantasyonu).
  final String? uid;

  /// Test enjeksiyonu için — `RootScreen.pushNotificationService`/
  /// `HomeScreen.soundEffectsService` ile AYNI desen. `null` ise (üretimde
  /// HER ZAMAN) gerçek [AppodealAdService] kullanılır; `flutter_test`'te
  /// gerçek Appodeal SDK'sı platform kanalına dokunamadığı için ("Reklam
  /// İzle" bastığında reklam hiç "yüklenmez", `showRewardedAd()` sessizce
  /// `false` döner) bunu doğrudan test eden senaryolar `const
  /// MockAdService()` enjekte eder (bkz. widget_test.dart).
  final AdService? adService;

  /// Test enjeksiyonu için — [adService] ile AYNI desen. `null` ise
  /// (üretimde HER ZAMAN) gerçek [InAppPurchasePurchaseService] kullanılır;
  /// `flutter_test`'te gerçek Play Billing platform kanalına dokunamadığı
  /// için bunu doğrudan test eden senaryolar `const MockPurchaseService()`
  /// enjekte eder.
  final PurchaseService? purchaseService;

  /// Test enjeksiyonu için — `RootScreen.homeWidgetService` ile AYNI desen,
  /// `_AppStartupGate` üzerinden oraya iletiliyor (bkz. "Ana Ekran
  /// Widget'ları" bölümündeki dil-değişimi regresyon testi). `null` ise
  /// (üretimde HER ZAMAN) `RootScreen`'in KENDİ varsayılanı
  /// (`HomeWidgetPluginService()`) kullanılır.
  final HomeWidgetService? homeWidgetService;

  @override
  Widget build(BuildContext context) {
    // `CoinProvider` VE `AdFreeProvider` AYNI `PurchaseService` örneğini
    // paylaşmalı — ikisi de `orphanedPurchaseProductIds`'i dinliyor (bkz. o
    // dosyadaki dokümantasyon); iki AYRI `InAppPurchasePurchaseService`
    // örneği aynı satın almayı iki kez `completePurchase` etmeye çalışabilir.
    final resolvedPurchaseService =
        purchaseService ?? InAppPurchasePurchaseService();
    return MultiProvider(
      providers: [
        // TrustedTimeProvider EN BAŞTA olmalı — aşağıdaki "güne bağlı"
        // provider'ların `create` callback'leri `context.read<
        // TrustedTimeProvider>()` ile buna erişiyor (MultiProvider listede
        // ÖNCEKİ provider'ları SONRAKİlerin context'inden görünür kılar).
        ChangeNotifierProvider(create: (_) => TrustedTimeProvider(uid: uid)),
        // 2026 yeni özellik — Google hesap bağlama (bkz. AuthLinkProvider
        // dokümantasyonu). Diğer provider'lardan BAĞIMSIZ, kendi `uid`'ini
        // doğrudan `main()`'den alıyor. `googleAuthService` BURADA AÇIKÇA
        // gerçek `FirebaseGoogleAuthService()` ile veriliyor —
        // `AuthLinkProvider`'ın KENDİ varsayılanı bilerek `FakeGoogleAuthService`
        // (bkz. o dosyadaki "Kritik" notu — `CoinProvider`/`adService` ile
        // AYNI "sağlam varsayılan, üretimde açıkça override" deseni).
        ChangeNotifierProvider(
          create: (_) => AuthLinkProvider(
            uid: uid,
            googleAuthService: FirebaseGoogleAuthService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AppThemeProvider(uid: uid)),
        // 2026 yeni özellik — Rozet Sistemi (bkz. CLAUDE.md "Rozet Sistemi"
        // bölümü). `BadgeProvider` kazanılan rozetleri tutuyor —
        // `BadgeCoordinator` tarafından (bkz. `RootScreen`) DIŞARIDAN
        // dinleniyor. `AppStreakProvider`'ın kendisi ("uygulamayı her gün
        // açma" serisi) artık AŞAĞIDA, `SubscriptionProvider`'dan SONRA
        // kuruluyor (Faz 4 / B3 — `isPro`/`isProPlus` closure'larına ihtiyacı
        // var, `CoinProvider` ile AYNI gerekçe).
        ChangeNotifierProvider(create: (_) => BadgeProvider(uid: uid)),
        // Gizli/Eğlenceli Rozetler ("Gece Kuşu"/"Erken Kuş") — BİLEREK
        // `AppStreakProvider`'ın AKSİNE `TrustedTimeProvider` VERİLMİYOR,
        // varsayılan (cihazın kendi `DateTime.now()`) kullanılıyor — bkz.
        // `HiddenBadgeProvider`'ın "BİLEREK cihaz saati" dokümantasyonu.
        ChangeNotifierProvider(create: (_) => HiddenBadgeProvider(uid: uid)),
        // SoundEffectsProvider de CoinProvider'dan ÖNCE olmalı — AYNI
        // gerekçe: CoinProvider'ın `create` callback'i coin kazanma/satın
        // alma seslerini açık/kapalı tercihine bağlamak için `context.read<
        // SoundEffectsProvider>()` kullanıyor (bkz. altta).
        ChangeNotifierProvider(create: (_) => SoundEffectsProvider(uid: uid)),
        // 2026 yeni özellik — Level/XP Sistemi (bkz. CLAUDE.md "Level/XP
        // Sistemi" bölümü). `SoundEffectsProvider` ile AYNI gerekçeyle
        // `CoinProvider`'dan ÖNCE olmalı — `CoinProvider`'ın `create`
        // callback'i kazanılan HER ZC için otomatik XP vermek üzere
        // `context.read<XpProvider>()` kullanıyor (bkz. altta).
        ChangeNotifierProvider(create: (_) => XpProvider(uid: uid)),
        // "Zibo ADS" (reklamsız deneyim) — bkz. AdFreeProvider dokümantasyonu.
        // `CoinProvider`'dan ÖNCE olmalı: AYNI `resolvedPurchaseService`
        // örneğini paylaşır VE `CoinProvider`'ın `create` callback'i
        // interstitial reklamları kapatmak için `context.read<
        // AdFreeProvider>()` kullanıyor (bkz. altta).
        ChangeNotifierProvider(
          create: (_) => AdFreeProvider(
            uid: uid,
            purchaseService: resolvedPurchaseService,
          ),
        ),
        // Zibo Pro / Zibo Pro+ abonelik durumu (bkz. SubscriptionProvider
        // dokümantasyonu). `AdFreeProvider` ile AYNI `resolvedPurchaseService`
        // örneğini paylaşır. `now` diğer "güne bağlı" provider'larla AYNI
        // gerekçeyle `TrustedTimeProvider`'a bağlı (süre kontrolü cihaz
        // saatine değil buna dayanıyor).
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            uid: uid,
            purchaseService: resolvedPurchaseService,
            now: _trustedNow(context),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            // `isSoundEnabled`/`isAdFree`/`onXpEarned`/`now` closure'ları da
            // `create` context'ini KAPATMAMALI (bkz. `_trustedNow`
            // dokümantasyonu — aynı "deactivated element" çökme sınıfı).
            // İlgili provider'lar BİR KEZ, burada çözülüp örneklerine
            // bağlanıyor.
            final soundEffects = context.read<SoundEffectsProvider>();
            final xp = context.read<XpProvider>();
            final adFree = context.read<AdFreeProvider>();
            final subscription = context.read<SubscriptionProvider>();
            return CoinProvider(
              uid: uid,
              adService: adService ?? AppodealAdService(),
              purchaseService: resolvedPurchaseService,
              soundEffectsService: AudioPlayersSoundEffectsService(),
              isSoundEnabled: () => soundEffects.enabled,
              isAdFree: () => adFree.isAdFree,
              isPro: () => subscription.isPro,
              isProPlus: () => subscription.isProPlus,
              now: _trustedNow(context),
              onXpEarned: (amount) => xp.addXp(amount),
            );
          },
        ),
        // Faz 4 (B3) — aylık ücretsiz Streak Freeze hakkı `isPro`/`isProPlus`
        // gerektirdiği için `SubscriptionProvider`'dan SONRA, `CoinProvider`
        // ile AYNI closure-çözme desenle kuruluyor.
        ChangeNotifierProvider(
          create: (context) {
            final subscription = context.read<SubscriptionProvider>();
            return AppStreakProvider(
              now: _trustedNow(context),
              uid: uid,
              isPro: () => subscription.isPro,
              isProPlus: () => subscription.isProPlus,
            );
          },
        ),
        ChangeNotifierProvider(create: (_) => CostumeProvider(uid: uid)),
        // 2026 yeni özellik — Kurucu Üye rozeti artık Google hesabına
        // bağlanan İLK 500 kullanıcıya, canlı bir Firestore sayacıyla
        // veriliyor (bkz. FounderBadgeProvider dokümantasyonu). Diğer
        // provider'lardan bağımsız, yalnızca kendi `uid`'ini alıyor.
        ChangeNotifierProvider(create: (_) => FounderBadgeProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (_) => CustomMessagesProvider(uid: uid),
        ),
        ChangeNotifierProvider(create: (_) => CurrencyProvider(uid: uid)),
        // Aşağıdaki altı provider "güne bağlı" mekanizmalar (günlük ödül/
        // streak/sıfırlanma) taşıyor — hepsi cihazın DOĞRUDAN `DateTime.
        // now()`'u yerine `TrustedTimeProvider.now()`'u kullanıyor (bkz. o
        // dosyadaki "Güvenilir Zaman" dokümantasyonu — kullanıcı telefonun
        // tarihini elle ileri alarak bu ödülleri tekrar tekrar
        // tetikleyemesin diye).
        ChangeNotifierProvider(
          create: (context) => DailyRewardsProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DreamJournalProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (_) => FavoriteQuotesProvider(uid: uid),
        ),
        // 2026 yeni özellik — Odak Sayacı modülü (bkz. CLAUDE.md).
        ChangeNotifierProvider(
          create: (context) => FocusProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        // 2026 yeni özellik — Instagram Takip Kartı ve Ödülü (bkz. CLAUDE.md).
        ChangeNotifierProvider(
          create: (_) => InstagramFollowProvider(uid: uid),
        ),
        ChangeNotifierProvider(
          create: (context) => GoalsProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GratitudeProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => HomeQuickWidgetsProvider(uid: uid)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => ManifestProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MoneyProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => MoodProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (_) => PushNotificationProvider(uid: uid),
        ),
        // Düz (ChangeNotifier OLMAYAN) bir değer — `RootScreen`'in push
        // bildirimlerini başlatabilmesi için `uid`'e ihtiyacı var, ama
        // bunu bir constructor parametresi olarak geçirmek `_AppStartupGate`/
        // `RootScreen`'i `const` OLMAKTAN çıkarırdı; bu da `MaterialApp.home`
        // widget KİMLİĞİNİN her rebuild'de (ör. koyu tema değişince)
        // değişmesine, dolayısıyla `Navigator`'ın İÇİNDEKİ TÜM route
        // yığınının (ör. o an açık olan Ayarlar sayfası) sıfırlanmasına yol
        // AÇARDI — gerçekten yaşandı, `flutter test`'te "Koyu Tema anahtarı
        // açılınca uygulama koyu temaya geçer" testi RootScreen'in tema
        // değişimi SONRASI ağaçtan tamamen kaybolduğunu ortaya çıkardı. Bunun
        // yerine `uid` bir `Provider<String?>.value` olarak sağlanıp
        // `RootScreen` bunu `context.read<String?>()` ile okuyor —
        // `_AppStartupGate`/`RootScreen` `const` kalmaya devam ediyor.
        Provider<String?>.value(value: uid),
        ChangeNotifierProvider(create: (_) => OnboardingProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileStatsArchiveProvider(uid: uid),
        ),
        ChangeNotifierProvider(create: (_) => ReferralProvider(uid: uid)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => WaterProvider(
            now: _trustedNow(context),
            uid: uid,
          ),
        ),
        // Kalıcı DEĞİL, `uid` almıyor — saf görsel/UI durumu (bkz.
        // ZiboPoseProvider dokümantasyonu).
        ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, AppThemeProvider>(
        builder: (context, themeProvider, localeProvider, appThemeProvider, _) {
          // Mağaza > Temalar'dan satın alınıp uygulanan kod-tabanlı bir tema
          // varsa (bkz. AppThemeOption.colorScheme), TÜM uygulamanın açık/
          // koyu ColorScheme'i onunla değiştiriliyor — yalnızca Ana Sayfa'nın
          // arka planı değil, butonlar/alt gezinme çubuğu/konuşma balonları/
          // kartlar/her sayfanın `scaffoldBackgroundColor`'ı da bu üzerinden
          // otomatik tutarlı hale geliyor (hepsi zaten `Theme.of(context).
          // colorScheme` kullanıyor). Tema yoksa varsayılan sabit temalara
          // düşülür.
          final equippedId = appThemeProvider.equippedId;
          final equippedTheme = equippedId == null
              ? null
              : findAppThemeById(equippedId);
          final lightTheme = equippedTheme == null
              ? _lightTheme
              : _buildTheme(equippedTheme.colorScheme(false));
          final darkTheme = equippedTheme == null
              ? _darkTheme
              : _buildTheme(equippedTheme.colorScheme(true));

          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            // Tema aniden değil, kısa bir "perde" efektiyle değişsin (bkz.
            // ThemeFadeOverlay içindeki not — AnimatedTheme burada takılmaya
            // yol açtığı için bilerek kullanılmıyor). AnimatedThemeOverlay
            // İÇERİDE (fade perdesinin ALTINDA) sarılıyor ki tema değişince
            // parçacık katmanı da aynı yumuşak geçişe dahil olsun, aniden
            // belirip kaybolmasın. AdBlurOverlay reklam katmanı — reklam
            // gösterilirken (bkz. `AppodealAdService`) uygulamanın TAMAMININ
            // (AppBar dahil) üzerine bir yedek bulanıklaştırma katmanı
            // bindirebilsin diye (bkz. o dosyadaki dokümantasyon).
            // BadgeCelebrationOverlay EN DIŞTA — bir rozet HANGİ EKRANDA
            // olursa olsun (bkz. `home:` içindeki içeriğin başka bir rota
            // push edilince boyanmaması gotcha'sı, `BadgeCelebrationOverlay`
            // dokümantasyonu) konfeti/kutlama popup'ı görünsün diye.
            builder: (context, child) => BadgeCelebrationOverlay(
              child: LevelCelebrationOverlay(
                child: AdBlurOverlay(
                  child: ThemeFadeOverlay(
                    themeMode: themeProvider.themeMode,
                    equippedThemeId: equippedId,
                    child: AnimatedThemeOverlay(
                      animationType:
                          equippedTheme?.animationType ??
                          ThemeAnimationType.none,
                      isDark: themeProvider.isDarkMode,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
            // Kullanıcının Ayarlar'dan seçtiği dil (bkz. LocaleProvider) —
            // varsayılan Türkçe, kalıcı olarak saklanır.
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: _AppStartupGate(homeWidgetService: homeWidgetService),
          );
        },
      ),
    );
  }
}

/// `RootScreen`'i, açılışta kritik provider'ların (bkz. `AppLoadingScreen`
/// dokümantasyonu) ilk yüklemesi bitene kadar `AppLoadingScreen` arkasında
/// gizler — kullanıcı varsayılan/boş durumdan gerçek veriye "zıplayan" bir
/// geçiş görmez, yumuşak bir çapraz-solma (`AnimatedSwitcher`) ile geçilir.
class _AppStartupGate extends StatelessWidget {
  const _AppStartupGate({this.homeWidgetService});

  /// `DijitalKankaApp.homeWidgetService`'ten (test enjeksiyonu için) geçiyor
  /// — yalnızca `RootScreen` dalına iletiliyor, `AppLoadingScreen`/
  /// `OnboardingScreen`'in ona ihtiyacı yok.
  final HomeWidgetService? homeWidgetService;

  @override
  Widget build(BuildContext context) {
    // `provider` paketinin `ConsumerN` yardımcıları en fazla 6 tipe kadar
    // destekliyor (Consumer7 YOK) — 7. provider (ProfileProvider)
    // eklenince doğrudan `context.watch<X>()` çağrılarına geçildi (zaten bu
    // widget'ın kendi `build()`'i içinde olduğumuz için `ConsumerN`
    // sarmalayıcısına hiç gerek yok, aynı yeniden-build davranışını verir).
    final theme = context.watch<ThemeProvider>();
    final appTheme = context.watch<AppThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final coin = context.watch<CoinProvider>();
    final costume = context.watch<CostumeProvider>();
    final onboarding = context.watch<OnboardingProvider>();
    // ProfileProvider'ın burada da hazır olması ZORUNLU — bkz.
    // ProfileProvider.isReady dokümantasyonu: Onboarding'in isim adımı bu
    // provider'a YAZIYOR, geç tamamlanan bir ilk yükleme bu yazıyı sessizce
    // silebilirdi.
    final profile = context.watch<ProfileProvider>();
    // Zibo Pro/Pro+ abonelik durumu — CoinProvider/CostumeProvider ile AYNI
    // gerekçe: Pro'ya özel içerik ileride eklenince "önce free göster, sonra
    // Pro'ya zıpla" titremesi olmasın diye startup kapısına dahil edildi.
    final subscription = context.watch<SubscriptionProvider>();

    final ready =
        theme.isReady &&
        appTheme.isReady &&
        locale.isReady &&
        coin.isReady &&
        costume.isReady &&
        onboarding.isReady &&
        profile.isReady &&
        subscription.isReady;
    // Uygulama İLK açılışta (bkz. OnboardingProvider.isCompleted == false)
    // RootScreen yerine tanıtım akışını gösterir — akış bittiğinde
    // (completeOnboarding çağrılınca) bu widget yeniden build olup doğrudan
    // RootScreen'e geçer, ayrı bir navigasyon adımı gerekmez.
    final Widget child;
    if (!ready) {
      child = const AppLoadingScreen(key: ValueKey('loading'));
    } else if (!onboarding.isCompleted) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else {
      child = RootScreen(
        key: const ValueKey('root'),
        homeWidgetService: homeWidgetService,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: child,
    );
  }
}
