import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'config/admob_config.dart';
import 'data/app_themes.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_theme_provider.dart';
import 'providers/auth_link_provider.dart';
import 'providers/coin_provider.dart';
import 'providers/costume_provider.dart';
import 'providers/daily_rewards_provider.dart';
import 'providers/dream_journal_provider.dart';
import 'providers/favorite_quotes_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/gratitude_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/manifest_provider.dart';
import 'providers/money_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/push_notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/sound_effects_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trusted_time_provider.dart';
import 'providers/water_provider.dart';
import 'providers/zibo_pose_provider.dart';
import 'utils/ad_free_promo_trigger.dart';
import 'utils/auth_switch.dart';
import 'models/app_theme_option.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'services/ad_service.dart';
import 'services/admob_ad_service.dart';
import 'services/google_auth_service.dart';
import 'services/push_notification_service.dart';
import 'services/sound_effects_service.dart';
import 'widgets/ad_blur_overlay.dart';
import 'widgets/animated_theme_overlay.dart';
import 'widgets/app_loading_screen.dart';
import 'widgets/theme_fade_overlay.dart';

// Zibo'nun tombul, sıcak, samimi karakterine uygun bal/hardal/krem paleti
// (açık tema) ve aynı ruhu koyu zeminde taşıyan bir koyu tema karşılığı.
// Anahtar tonlar elle sabitleniyor ki ColorScheme.fromSeed'in otomatik
// türetmesi soluk/pembemsi ya da tam parlak sarıya kaymasın.
const _mustard = Color(0xFFA9711F); // koyu hardal/kahverengi — ana vurgu
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
  primary: _mustard,
  onPrimary: Colors.white,
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

/// Açık ve koyu temanın ikisi de aynı yapı taşlarını (kart, buton, giriş
/// alanı stilleri) paylaşır; yalnızca renkleri farklıdır. Bu ortak fonksiyon
/// sayesinde iki tema birbirinden kopyala-yapıştır olmuyor.
ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    useMaterial3: true,
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // "Zibo ADS" tanıtım sıklığının en son gösterim zamanını (kalıcı, oturumlar
  // arası) belleğe yükler — bkz. ad_free_promo_trigger.dart. `runApp`'tan
  // ÖNCE tamamlanması gerekiyor, aksi halde ilk Mağaza ziyaretinde henüz
  // yüklenmemiş sayılıp tetikleyici hiç göstermez (bkz. o dosyadaki güvenli
  // varsayılan).
  await AdFreePromoTrigger.initialize();
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
  } catch (_) {
    // Firebase/Auth başlatılamadı (ör. web önizlemesi, ağ yok, yapılandırma
    // eksik) — `uid` `null` kalır, uygulama Firebase'e bağımlı olmadan
    // (tamamen yerel depoyla) sorunsuz çalışmaya devam eder.
  }
  // AdMob SDK'sı — Firebase'den TAMAMEN BAĞIMSIZ bir try/catch (biri
  // başarısız olursa diğerini etkilemesin diye). `MobileAds.instance.
  // initialize()` çağrılmadan `RewardedAd.load(...)` (bkz.
  // AdMobAdService) sessizce başarısız olur — bu yüzden `runApp`'tan ÖNCE
  // tamamlanmalı. Web önizlemesinde veya platform desteklenmiyorsa
  // (`flutter_test` dahil) hatayı yutup uygulamanın reklamsız (her
  // `showRewardedAd()` çağrısı `false` dönerek) çalışmaya devam etmesine
  // izin verir.
  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
  runApp(_AppRoot(initialUid: uid));
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

class DijitalKankaApp extends StatelessWidget {
  const DijitalKankaApp({super.key, this.uid, this.adService});

  /// Kullanıcının anonim Firebase kimliği (bkz. `main()`) — `null` ise
  /// (Firebase kullanılamıyor VEYA test ortamı) TÜM aşağıdaki provider'lar
  /// otomatik olarak saf-yerel (`SharedPreferences`) moda düşer; hiçbir
  /// provider testi bu alanı VERMEZ, bu yüzden mevcut tüm testler
  /// değişmeden çalışmaya devam eder (bkz. `CloudStateStore` dokümantasyonu).
  final String? uid;

  /// Test enjeksiyonu için — `RootScreen.pushNotificationService`/
  /// `HomeScreen.soundEffectsService` ile AYNI desen. `null` ise (üretimde
  /// HER ZAMAN) gerçek [AdMobAdService] kullanılır; `flutter_test`'te gerçek
  /// AdMob SDK'sı platform kanalına dokunamadığı için ("Reklam İzle"
  /// bastığında reklam hiç "yüklenmez", `showRewardedAd()` sessizce `false`
  /// döner) bunu doğrudan test eden senaryolar `const MockAdService()`
  /// enjekte eder (bkz. widget_test.dart).
  final AdService? adService;

  @override
  Widget build(BuildContext context) {
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
        // SoundEffectsProvider de CoinProvider'dan ÖNCE olmalı — AYNI
        // gerekçe: CoinProvider'ın `create` callback'i coin kazanma/satın
        // alma seslerini açık/kapalı tercihine bağlamak için `context.read<
        // SoundEffectsProvider>()` kullanıyor (bkz. altta).
        ChangeNotifierProvider(create: (_) => SoundEffectsProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => CoinProvider(
            uid: uid,
            adService:
                adService ??
                AdMobAdService(
                  rewardedAdUnitId: AdMobConfig.rewardedAdUnitId,
                  interstitialAdUnitId: AdMobConfig.interstitialAdUnitId,
                ),
            soundEffectsService: AudioPlayersSoundEffectsService(),
            isSoundEnabled: () =>
                context.read<SoundEffectsProvider>().enabled,
            now: () => context.read<TrustedTimeProvider>().now(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CostumeProvider(uid: uid)),
        // Aşağıdaki altı provider "güne bağlı" mekanizmalar (günlük ödül/
        // streak/sıfırlanma) taşıyor — hepsi cihazın DOĞRUDAN `DateTime.
        // now()`'u yerine `TrustedTimeProvider.now()`'u kullanıyor (bkz. o
        // dosyadaki "Güvenilir Zaman" dokümantasyonu — kullanıcı telefonun
        // tarihini elle ileri alarak bu ödülleri tekrar tekrar
        // tetikleyemesin diye).
        ChangeNotifierProvider(
          create: (context) => DailyRewardsProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DreamJournalProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (_) => FavoriteQuotesProvider(uid: uid),
        ),
        ChangeNotifierProvider(
          create: (context) => GoalsProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GratitudeProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => ManifestProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MoneyProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => MoodProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
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
            now: () => context.read<TrustedTimeProvider>().now(),
            uid: uid,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(uid: uid)),
        ChangeNotifierProvider(
          create: (context) => WaterProvider(
            now: () => context.read<TrustedTimeProvider>().now(),
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
            // belirip kaybolmasın. AdBlurOverlay EN DIŞTA — AdMob reklamı
            // gösterilirken (bkz. `AdMobAdService`) uygulamanın TAMAMININ
            // (AppBar dahil) üzerine bir yedek bulanıklaştırma katmanı
            // bindirebilsin diye (bkz. o dosyadaki dokümantasyon).
            builder: (context, child) => AdBlurOverlay(
              child: ThemeFadeOverlay(
                themeMode: themeProvider.themeMode,
                equippedThemeId: equippedId,
                child: AnimatedThemeOverlay(
                  animationType:
                      equippedTheme?.animationType ?? ThemeAnimationType.none,
                  isDark: themeProvider.isDarkMode,
                  child: child!,
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
            home: const _AppStartupGate(),
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
  const _AppStartupGate();

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

    final ready =
        theme.isReady &&
        appTheme.isReady &&
        locale.isReady &&
        coin.isReady &&
        costume.isReady &&
        onboarding.isReady &&
        profile.isReady;
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
      child = const RootScreen(key: ValueKey('root'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: child,
    );
  }
}
