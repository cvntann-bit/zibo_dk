import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/push_notification_type.dart';
import '../providers/app_streak_provider.dart';
import '../providers/app_theme_provider.dart';
import '../providers/auth_link_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../providers/dream_journal_provider.dart';
import '../providers/founder_badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/hidden_badge_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
import '../services/badge_coordinator.dart';
import '../services/home_widget_service.dart';
import '../services/home_widget_sync_coordinator.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../utils/founder_badge_reconcile.dart';
import '../utils/info_dialog.dart';
import '../utils/level_up_signal.dart';
import '../utils/tab_navigation.dart';
import '../utils/zibo_event_signal.dart';
import '../utils/widget_module.dart';
import '../widgets/badges_trigger_button.dart';
import '../widgets/coin_balance_widget.dart';
import '../widgets/daily_rewards_trigger_button.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/main_bottom_bar.dart';
import '../widgets/modules_menu_sheet.dart';
import '../widgets/sticker_style.dart';
import '../widgets/streak_freeze_offer_dialog.dart';
import '../widgets/wheel_trigger_button.dart';
import '../widgets/z_floating_button.dart';
import '../widgets/zibo_share_sheet.dart';
import 'completed_goals_screen.dart';
import 'daily_rewards_screen.dart';
import 'goal_tracking_screen.dart';
import 'home_screen.dart';
import 'money_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';
import 'water_tracking_screen.dart';

/// Uygulamanın sabit başlık çubuğunu ve alt gezinme çubuğunu barındıran
/// ana iskelet. Sekmeler arasında geçiş yapıldığında başlık çubuğu sabit
/// kalır, yalnızca gövde (body) değişir. Ayarlar sekmelerden biri değildir;
/// başlık çubuğundaki dişli ikonundan ayrı bir sayfa olarak push edilir.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    this.pushNotificationService,
    this.homeWidgetService,
  });

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `FirebaseMessagingPushNotificationService()` (`AdService`/
  /// `ShareService` ile AYNI desen).
  final PushNotificationService? pushNotificationService;

  /// Ana ekran widget'ları (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü)
  /// için testte sahte bir implementasyon enjekte edebilmek üzere — AYNI
  /// desen, varsayılan `HomeWidgetPluginService()`.
  final HomeWidgetService? homeWidgetService;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  static const _goalTrackingTabIndex = 1;
  static const _profileTabIndex = 2;
  static const _storeTabIndex = 3;

  int _selectedIndex = 0;
  late final PushNotificationService _pushNotificationService =
      widget.pushNotificationService ??
      FirebaseMessagingPushNotificationService();
  late final HomeWidgetService _homeWidgetService =
      widget.homeWidgetService ?? const HomeWidgetPluginService();
  HomeWidgetSyncCoordinator? _homeWidgetSync;
  // 2026 yeni özellik — Rozet Sistemi. `_homeWidgetSync` ile AYNI "nullable
  // field, dispose'ta güvenli temizlik" deseni (bkz. `BadgeCoordinator`
  // dokümantasyonu — `GoalsProvider`/`AppStreakProvider`'a KALICI değil,
  // yalnızca dinleyici olarak bağlı).
  BadgeCoordinator? _badgeCoordinator;
  // **2026 yeni özellik — widget derin bağlantısı.** Uygulama ZATEN
  // AÇIKKEN bir widget'a dokunulduğunda `HomeWidgetService.moduleClicked`
  // akışını dinlemek için — bu sınıfta İLK `StreamSubscription` kullanımı
  // (`_homeWidgetSync` alanıyla AYNI "nullable field, dispose'ta güvenli
  // temizlik" üslubunda).
  StreamSubscription<ZiboWidgetModule?>? _widgetClickSub;
  // `dispose()`'da `context.read(...)` çağırmak GÜVENSİZ (widget o an zaten
  // deactivate ediliyor olabilir, "Looking up a deactivated widget's
  // ancestor is unsafe" hatası fırlatır — gerçekten yakalandı, bkz.
  // CLAUDE.md "Ana Ekran Widget'ları" bölümündeki test gotcha'sı) — bu
  // yüzden referans `initState`'te (güvenli bir zamanda) BİR KEZ okunup
  // burada saklanıyor, `dispose()` yalnızca bu saklanan referansı kullanıyor.
  LocaleProvider? _localeProviderForCleanup;

  /// `main.dart`'ta `Provider<String?>.value(value: uid)` ile sağlanıyor
  /// (bkz. o dosyadaki "neden constructor parametresi DEĞİL" notu —
  /// `RootScreen`'i `const` olmaktan çıkarmak `MaterialApp.home` widget
  /// kimliğinin her rebuild'de değişmesine, dolayısıyla Navigator'ın açık
  /// route yığınının sıfırlanmasına yol açardı).
  String? get _uid => context.read<String?>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Bildirim izni + planlama, uygulama gerçekten başlarken bir kez
    // tetiklenir (bkz. NotificationProvider dokümantasyonu). Bildirime
    // dokununca (uygulama zaten açıkken) Ana Sayfa'ya atlamak için de
    // burada dinleniyor.
    if (notificationsFeatureEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          context.read<NotificationProvider>().initializeAndSchedule();
      });
    }
    // **2026 yeni özellik — FCM push bildirimleri.** Yerel sistemden
    // (yukarıdaki `notificationsFeatureEnabled` bloğu) TAMAMEN BAĞIMSIZ,
    // her zaman etkin (bkz. `PushNotificationService` dokümantasyonu).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pushNotificationService.initialize(
          uid: _uid,
          localNotificationService: LocalNotificationService(),
          onNotificationTap: _handlePushNotificationTap,
        );
      }
    });
    homeTabRequest.addListener(_onHomeTabRequested);
    goalsTabRequest.addListener(_onGoalsTabRequested);
    dailyRewardsPopupRequest.addListener(_onDailyRewardsPopupRequested);
    waterModuleRequest.addListener(_onWaterModuleRequested);
    moneyModuleRequest.addListener(_onMoneyModuleRequested);
    profileTabRequest.addListener(_onProfileTabRequested);
    // 2026 yeni özellik — Level/XP Sistemi. `LevelCelebrationOverlay`'in
    // "Paylaş" butonu Navigator'a erişemediği için (bkz. o dosyanın
    // dokümantasyonu) bu sinyali kullanıp burada, Navigator'ın ALTINDAKİ bu
    // context'le paylaşım sheet'ini açıyoruz.
    pendingLevelShareMessage.addListener(_onLevelShareRequested);
    // **2026 yeni özellik — widget derin bağlantısı.** Uygulama ZATEN
    // açıkken bir widget'a dokunulursa bu akıştan gelir.
    _widgetClickSub = _homeWidgetService.moduleClicked.listen((module) {
      if (module != null) _handleWidgetModuleTap(module);
    });
    // **2026 yeni özellik — ana ekran widget'ları.** Beş modülün widget'ını
    // GÜNCEL tutan koordinatör burada BİR KEZ kuruluyor (bkz. CLAUDE.md "Ana
    // Ekran Widget'ları" bölümü + HomeWidgetSyncCoordinator dokümantasyonu)
    // — `context.read` çağrıları `build()` DIŞINDA olduğu için post-frame
    // callback'e ertelenmesi gerekmiyor (initState'in kendisi zaten güvenli),
    // ama `AppLocalizations.of(context)` ilk frame çizilmeden `null`
    // dönebileceği için `syncAll()` yine de bir sonraki kareye bırakılıyor.
    final sync = HomeWidgetSyncCoordinator(
      context: context,
      service: _homeWidgetService,
      trustedTime: context.read<TrustedTimeProvider>(),
      goals: context.read<GoalsProvider>(),
      water: context.read<WaterProvider>(),
      gratitude: context.read<GratitudeProvider>(),
      manifest: context.read<ManifestProvider>(),
      money: context.read<MoneyProvider>(),
      currency: context.read<CurrencyProvider>(),
      dailyRewards: context.read<DailyRewardsProvider>(),
      profile: context.read<ProfileProvider>(),
    );
    _homeWidgetSync = sync;
    final localeProvider = context.read<LocaleProvider>();
    _localeProviderForCleanup = localeProvider;
    localeProvider.addListener(_onLocaleChangedForWidgetSync);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      sync.syncAll();
      // **2026 yeni özellik — widget derin bağlantısı, SOĞUK başlangıç.**
      // `sync.syncAll()` ile AYNI karede kontrol ediliyor — `Navigator`
      // hazır olduktan (ilk frame çizildikten) SONRA çalışması gerektiği
      // için AYNI erteleme deseni yeterli, ayrı bir postFrameCallback'e
      // gerek yok.
      final initialModule = await _homeWidgetService.initialLaunchModule();
      if (mounted && initialModule != null) _handleWidgetModuleTap(initialModule);
    });
    // **2026 yeni özellik — Rozet Sistemi.** `AppStreakProvider`'ın "bugün
    // açıldı" kaydı + `BadgeCoordinator`'ın kurulumu (constructor'ı zaten
    // EAGER bir ilk `reconcile()` yapıyor, bkz. o sınıfın dokümantasyonu)
    // İKİSİ de `notifyListeners()` tetikleyebiliyor — `initState`'in
    // GÖVDESİNDE senkron çağrılırsa "setState() or markNeedsBuild() called
    // during build" hatasıyla ÇÖKÜYORDU (gerçekten yakalandı, `flutter
    // test`'te). `sync.syncAll()`'un ZATEN kullandığı AYNI postFrameCallback'e
    // taşınarak (ilk frame TAMAMLANDIKTAN sonra) düzeltildi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_recordAppStreakOpen());
      // Gizli/Eğlenceli Rozetler — "Gece Kuşu"/"Erken Kuş" sayaçları,
      // `recordOpenForToday()` ile AYNI tetikleme anı (soğuk başlangıç).
      context.read<HiddenBadgeProvider>().recordOpenForCurrentTime();
      // **2026 bug düzeltmesi — Crashlytics'teki EN BÜYÜK tekrarlayan hata**
      // (bkz. CLAUDE.md "Manifest Günlüğü ↔ Profil fotoğrafı" bölümü) —
      // `recordOpenForToday()` ile AYNI tetikleme anı (soğuk başlangıç).
      // Dosyası artık cihazda OLMAYAN fotoğraf referanslarını temizler.
      context.read<ManifestProvider>().reconcileMissingPhotos();
      context.read<ProfileProvider>().reconcileMissingPhoto();
      _badgeCoordinator = BadgeCoordinator(
        badges: context.read<BadgeProvider>(),
        goals: context.read<GoalsProvider>(),
        appStreak: context.read<AppStreakProvider>(),
        // 2026 güncellemesi — Modül Ustalığı Rozetleri (bkz. CLAUDE.md
        // "Rozet Sistemi" bölümü) için altı provider.
        gratitude: context.read<GratitudeProvider>(),
        water: context.read<WaterProvider>(),
        mood: context.read<MoodProvider>(),
        money: context.read<MoneyProvider>(),
        manifest: context.read<ManifestProvider>(),
        dream: context.read<DreamJournalProvider>(),
        // 2026 güncellemesi — Koleksiyon Rozetleri için iki yeni provider.
        costume: context.read<CostumeProvider>(),
        appTheme: context.read<AppThemeProvider>(),
        // 2026 güncellemesi — Sadakat Rozetleri için (ProfileProvider zaten
        // bu context'te mevcut, bkz. yukarıdaki HomeWidgetSyncCoordinator
        // kurulumu).
        profile: context.read<ProfileProvider>(),
        // 2026 güncellemesi — Sosyal/Paylaşım Rozetleri (Elçi/Topluluk
        // Kurucusu) için ReferralProvider.
        referral: context.read<ReferralProvider>(),
        // 2026 güncellemesi — Gizli/Eğlenceli Rozetler (Gece Kuşu/Erken
        // Kuş) için.
        hiddenBadge: context.read<HiddenBadgeProvider>(),
      );
      // Kurucu Üye rozeti — bkz. `_maybeClaimFounderBadge()` dokümantasyonu.
      unawaited(_maybeClaimFounderBadge());
    });
    // 2026 güncellemesi — Sosyal/Paylaşım Rozetleri: `ReferralProvider.
    // successfulReferralCount` sunucu tarafında (GitHub Actions cron'u)
    // artırılıyor, istemci bunu ancak `refresh()` çağrılınca görüyor —
    // `DailyRewardsProvider.reconcileForToday()` ile AYNI "reconcile-on-
    // resume" felsefesi, bkz. `ReferralProvider.refresh()`'in dokümantasyonu.
    context.read<ReferralProvider>().refresh();
  }

  /// **Faz 4 (B3)** — `AppStreakProvider.recordOpenForToday()`'in HER İKİ
  /// çağrı noktasının (`initState` postFrame + `didChangeAppLifecycleState`
  /// resumed) ORTAK sarmalayıcısı. `isStreakAtRisk` (tam 1 gün kaçırılmış)
  /// ise ÖNCE `StreakFreezeOfferDialog`'u gösterir; kullanıcı ne seçerse
  /// seçsin (kabul/vazgeç) SONRA `recordOpenForToday()` koşulsuz çağrılır —
  /// kabul edilmişse `_lastOpenDate` zaten bugüne eşit olduğu için no-op'a
  /// düşer, vazgeçilmişse normal sıfırlama mantığı çalışır. `BadgeCoordinator`
  /// `AppStreakProvider`'ı DIŞARIDAN dinlediği için (bkz. `initState`) bu
  /// gecikmeli güncellemeyi otomatik yakalar, burada ekstra bir şey
  /// GEREKMEZ.
  ///
  /// **2026-09-26 yeniden yazıldı** — iki kritik düzeltme:
  ///  1. İki provider da kayıtlı veriyi YÜKLEDİKTEN sonra çalışır. Eskiden
  ///     ilk karede, veri gelmeden çalışıyordu: seri her açılışta 1'e
  ///     sıfırlanıyor, "dün kaçırıldı" hiç görülmediği için Streak Freeze
  ///     penceresi HİÇ çıkmıyordu.
  ///  2. Hedefler de artık Streak Freeze ile korunuyor: dünü kaçırılmış
  ///     hedefler aynı pencerede listelenir, TEK bir freeze dünü her yerde
  ///     kurtarır (hedefte o gün mavi ❄️ olur, döngü sıfırlanmaz). Hedef
  ///     sıfırlama/uzlaştırma da artık yalnızca BURADA yapılıyor (eskiden
  ///     `GoalTrackingScreen` kendi başına, karar beklemeden sıfırlıyordu).
  Future<void> _recordAppStreakOpen() async {
    // Soğuk başlangıçta hem ilk kare hem `resumed` tetikleyebiliyor — iki
    // pencere/iki kayıt olmasın.
    if (_dailyStreakCheckRunning) return;
    _dailyStreakCheckRunning = true;
    try {
      final streak = context.read<AppStreakProvider>();
      final goals = context.read<GoalsProvider>();
      await Future.wait([streak.ready, goals.ready]);
      if (!mounted) return;

      final appAtRisk = streak.isStreakAtRisk;
      final atRiskGoals = goals.goalsAtRiskToday;
      var frozen = false;
      if (appAtRisk || atRiskGoals.isNotEmpty) {
        frozen = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => StreakFreezeOfferDialog(
                appStreakAtRisk: appAtRisk,
                atRiskGoals: atRiskGoals,
              ),
            ) ??
            false;
        if (!mounted) return;
      }

      final result = goals.resolveYesterdayFreeze(frozen: frozen);
      streak.recordOpenForToday();

      if (result.completedNames.isNotEmpty) {
        final coins = context.read<CoinProvider>();
        for (var i = 0; i < result.completedNames.length; i++) {
          coins.earnStreak7Bonus();
        }
        pendingZiboEvent.value = ZiboEventType.goalCycleCompleted;
      }
      if (result.resetNames.isNotEmpty) {
        // Olay Tetiklemeli Özel Mesajlar — Ana Sayfa balonu nazik bir
        // "tekrar deneyelim" mesajı gösterir (bkz. `zibo_event_signal.dart`).
        pendingZiboEvent.value = ZiboEventType.streakBroken;
        final l10n = AppLocalizations.of(context)!;
        await showInfoDialog(context, l10n.goalStreakReset(result.resetNames.join(', ')));
      }
    } finally {
      _dailyStreakCheckRunning = false;
    }
  }

  bool _dailyStreakCheckRunning = false;

  /// bkz. `utils/founder_badge_reconcile.dart`'taki `maybeClaimFounderBadge`
  /// dokümantasyonu — gerçek mantık orada, saf/test edilebilir bir üst
  /// düzey fonksiyon olarak; burası yalnızca o anki provider'ları
  /// (`mounted` kontrolüyle) geçiren ince bir sarmalayıcı.
  Future<void> _maybeClaimFounderBadge() {
    if (!mounted) return Future.value();
    return maybeClaimFounderBadge(
      authLink: context.read<AuthLinkProvider>(),
      costume: context.read<CostumeProvider>(),
      founderBadge: context.read<FounderBadgeProvider>(),
    );
  }

  /// **2026 bug düzeltmesi — kullanıcı raporu: "uygulama İspanyolca ama
  /// widget'lar hâlâ Türkçe."** Kök neden bir kare-zamanlama yarışıydı:
  /// `LocaleProvider.notifyListeners()` KAYITLI TÜM listener'ları SENKRON
  /// (aynı çağrı yığınında) tetikliyor — ama `MaterialApp`'in `locale:`
  /// parametresi (dolayısıyla `AppLocalizations.of(context)`'in gördüğü
  /// ambient değer) yalnızca `Consumer3`'ün BİR SONRAKİ FRAME'de yeniden
  /// `build()` çalıştırmasıyla GERÇEKTEN değişiyor (`provider` paketinin
  /// `notifyListeners()` → `setState`-benzeri mekanizması, Flutter'daki HER
  /// `setState` gibi rebuild'i hemen değil bir SONRAKİ çizim karesine
  /// erteliyor). `localeProvider.addListener(sync.syncAll)` DOĞRUDAN
  /// bağlıyken, `sync.syncAll()` bu SENKRON anda (yani `MaterialApp` henüz
  /// YENİ locale'le yeniden inşa EDİLMEDEN) çalışıp `_l10n` üzerinden HÂLÂ
  /// ESKİ (bir adım geride) dili okuyordu — widget'lar dil değiştirildikten
  /// SONRA bile eski dilde KALIYORDU (locale bir daha DEĞİŞMEDİĞİ sürece bu
  /// bir daha tetiklenmediği için asla kendiliğinden düzelmiyordu).
  /// initState'teki İLK `syncAll()` çağrısı ZATEN AYNI gerekçeyle
  /// (`AppLocalizations.of(context)` ilk karede `null` dönebilir)
  /// `addPostFrameCallback`'e erteleniyordu — burada da AYNI erteleme
  /// deseni uygulanıp `MaterialApp` gerçekten yeni locale'le yeniden inşa
  /// OLDUKTAN SONRAKİ karede çalışması sağlandı.
  void _onLocaleChangedForWidgetSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _homeWidgetSync?.syncAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    homeTabRequest.removeListener(_onHomeTabRequested);
    goalsTabRequest.removeListener(_onGoalsTabRequested);
    dailyRewardsPopupRequest.removeListener(_onDailyRewardsPopupRequested);
    waterModuleRequest.removeListener(_onWaterModuleRequested);
    moneyModuleRequest.removeListener(_onMoneyModuleRequested);
    profileTabRequest.removeListener(_onProfileTabRequested);
    pendingLevelShareMessage.removeListener(_onLevelShareRequested);
    _widgetClickSub?.cancel();
    final sync = _homeWidgetSync;
    if (sync != null) {
      _localeProviderForCleanup?.removeListener(_onLocaleChangedForWidgetSync);
      sync.dispose();
    }
    _badgeCoordinator?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bu geri çağrı, state ağaçtan ayrılırken (deactivate → dispose arası)
    // hâlâ tetiklenebiliyor — aşağıdaki `context.read` çağrıları o anda
    // güvenli değil. `mounted` guard'ı en ucuz savunma.
    if (!mounted) return;
    // "Geri Kazanma" push bildiriminin (bkz. functions/src/index.ts)
    // "kaç gündür açılmadı" kontrolü için TEK veri kaynağı — uygulama her
    // öne geldiğinde tazeleniyor.
    if (state == AppLifecycleState.resumed && _uid != null) {
      _pushNotificationService.touchLastActive(_uid!);
    }
    // **2026 bug düzeltmesi — "İstatistiklerim" widget'ı boş/"—" görünüyordu.**
    // Kullanıcı raporu: widget'ı ana ekrana MANUEL olarak (uygulama arka
    // plandayken, `syncAll()`'ın yalnızca `initState`/dil değişiminde
    // tetiklendiği bir andan SONRA) ekleyince carousel hiç veri
    // GÖSTERMİYORDU — `_syncProfileStats()`/`_syncMotivation()` YALNIZCA
    // `syncAll()` içinde çalıştığı için (bkz. `HomeWidgetSyncCoordinator`
    // dokümantasyonu), bir widget'ın "önceki senkronizasyondan SONRA"
    // eklenmesi, kullanıcı uygulamayı BİR SONRAKİ tam soğuk başlangıca
    // kadar (ya da dil değiştirene kadar) hiç taze veri GÖRMEMESİ demekti.
    // Düzeltme: uygulama HER öne gelişte (`resumed` — tam olarak "widget'ı
    // ekleyip uygulamaya geri döndüğün an") `syncAll()` da tetikleniyor —
    // `touchLastActive` ile AYNI tetikleyici, ek bir maliyeti yok (her iki
    // carousel de zaten ucuz, saf hesaplamalar).
    if (state == AppLifecycleState.resumed) {
      _homeWidgetSync?.syncAll();
      // Rozet Sistemi — uygulama her öne geldiğinde (yalnızca soğuk
      // başlangıçta DEĞİL) "bugün açıldı" kaydı tazeleniyor, aynı
      // `touchLastActive`/`syncAll` tetikleyicisiyle.
      unawaited(_recordAppStreakOpen());
      // Gizli/Eğlenceli Rozetler — "Gece Kuşu"/"Erken Kuş" sayaçları,
      // uygulama HER öne geldiğinde (yalnızca soğuk başlangıçta DEĞİL)
      // cihazın O ANKİ saatine göre tazeleniyor — kullanıcı gece yarısı
      // civarında uygulamayı arka planda tutup öne getirse bile sayılıyor.
      context.read<HiddenBadgeProvider>().recordOpenForCurrentTime();
      // Sosyal/Paylaşım Rozetleri — sunucu tarafında (bir SONRAKİ GitHub
      // Actions çalıştırmasında) artırılan `successfulReferralCount`'un
      // istemciye yansıması için AYNI "reconcile-on-resume" tetikleyicisi.
      context.read<ReferralProvider>().refresh();
      // Kırık fotoğraf referansları — bkz. yukarıdaki `initState`'teki AYNI
      // çağrının dokümantasyonu (CLAUDE.md "Manifest Günlüğü ↔ Profil
      // fotoğrafı" bölümü) — uygulama HER öne geldiğinde tazeleniyor,
      // yalnızca soğuk başlangıçta DEĞİL (hesap değiştirip/çıkış yapıp geri
      // dönmek uygulamayı kapatmadan da olabiliyor).
      context.read<ManifestProvider>().reconcileMissingPhotos();
      context.read<ProfileProvider>().reconcileMissingPhoto();
      // Kurucu Üye rozeti — bkz. `_maybeClaimFounderBadge()` dokümantasyonu.
      unawaited(_maybeClaimFounderBadge());
    }
  }

  void _onHomeTabRequested() {
    if (mounted) _setSelectedIndex(0);
  }

  void _onGoalsTabRequested() {
    if (mounted) _setSelectedIndex(_goalTrackingTabIndex);
  }

  void _onDailyRewardsPopupRequested() {
    if (!mounted) return;
    _setSelectedIndex(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => const DailyRewardsScreen(),
        );
      }
    });
  }

  /// **2026 yeni özellik — Level/XP Sistemi.** `LevelCelebrationOverlay`'in
  /// "Paylaş" butonundan gelen istek — bkz. `pendingLevelShareMessage`
  /// dokümantasyonu. `dailyRewardsPopupRequest` ile AYNI "bir sonraki kareye
  /// ertele, sonra bu context'le aç" deseni.
  void _onLevelShareRequested() {
    final message = pendingLevelShareMessage.value;
    if (!mounted || message == null) return;
    pendingLevelShareMessage.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ZiboShareSheet(message: message),
      );
    });
  }

  /// **2026 yeni özellik — widget derin bağlantısı.** `modules_menu_sheet.
  /// dart`'ın Su Takibi'ni açtığı AYNI `MaterialPageRoute` çağrısı — bir
  /// sekme DEĞİL, pushed bir ekran olduğu için `_setSelectedIndex` yerine
  /// doğrudan `Navigator.push` kullanılıyor.
  void _onWaterModuleRequested() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WaterTrackingScreen()),
    );
  }

  /// [_onWaterModuleRequested] ile AYNI desen — Para ve Birikim.
  void _onMoneyModuleRequested() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MoneyScreen()),
    );
  }

  /// [_onGoalsTabRequested] ile AYNI desen — "İstatistiklerim" widget'ı
  /// Profil sekmesine karşılık geliyor.
  void _onProfileTabRequested() {
    if (mounted) _setSelectedIndex(_profileTabIndex);
  }

  /// Bir push bildirimine dokunulduğunda (bkz. `PushNotificationService`)
  /// `PushNotificationType`'a göre doğru sekmeye/popup'a yönlendirir.
  void _handlePushNotificationTap(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.dailyMotivation:
      case PushNotificationType.reEngagement:
      case PushNotificationType.waterReminder:
        // Su Takibi bir alt sekme değil, Z-butonu modül menüsünden push
        // edilen bir ekran (bkz. "Alt Gezinme Çubuğu" bölümü) — global bir
        // "şu ekranı aç" sinyali yok, bu yüzden `dailyMotivation`/
        // `reEngagement` ile AYNI en basit düşüşe (Ana Sayfa'yı öne getir)
        // düşülüyor, kullanıcı oradan iki dokunuşla Su Takibi'ne ulaşabilir.
        homeTabRequest.value++;
      case PushNotificationType.streakReminder:
        goalsTabRequest.value++;
      case PushNotificationType.dailyReward:
        dailyRewardsPopupRequest.value++;
    }
  }

  /// **2026 yeni özellik — widget derin bağlantısı.** Ana ekrandaki BEŞ
  /// widget'ın (bkz. `ZiboWidgetModule`) HERHANGİ birine dokununca (soğuk
  /// başlangıçta [initState]'teki `initialLaunchModule()` kontrolünden VEYA
  /// uygulama zaten açıkken [_widgetClickSub]'tan) hangi modülün açılması
  /// gerektiğini belirler. `_handlePushNotificationTap`'in AYNI switch-
  /// tabanlı deseni — [ZiboWidgetModule.dailyRewards] zaten var olan
  /// [dailyRewardsPopupRequest] sinyalini YENİDEN KULLANIYOR (push
  /// bildirimiyle AYNI hedef), [ZiboWidgetModule.motivation] ("Zibo'nun
  /// Sözü") kendi ayrı bir ekranı olmadığı için (içerik zaten Ana Sayfa'nın
  /// konuşma balonunda yaşıyor) [homeTabRequest]'e düşüyor — kullanıcının
  /// "her widget kendi modülünü DOĞRUDAN açsın" isteğinin bu widget için en
  /// doğru karşılığı Ana Sayfa'nın kendisi.
  void _handleWidgetModuleTap(ZiboWidgetModule module) {
    switch (module) {
      case ZiboWidgetModule.water:
        waterModuleRequest.value++;
      case ZiboWidgetModule.money:
        moneyModuleRequest.value++;
      case ZiboWidgetModule.dailyRewards:
        dailyRewardsPopupRequest.value++;
      case ZiboWidgetModule.motivation:
        homeTabRequest.value++;
      case ZiboWidgetModule.profileStats:
        profileTabRequest.value++;
    }
  }

  // Tüm sekme geçişleri BURADAN geçmeli — `isHomeTabActive` (bkz.
  // tab_navigation.dart), `AnimatedThemeOverlay`'in Premium/Animasyonlu tema
  // parçacık efektini yalnızca Ana Sayfa'da çizebilmesi için bu global
  // sinyale bağımlı; `_selectedIndex`'i doğrudan `setState` ile değiştiren
  // eski çağrı yerlerinin hepsi bu yardımcıya çevrildi.
  void _setSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
    isHomeTabActive.value = index == 0;
  }

  /// **Faz 5** — AppBar'daki Zibo logosu, kullanıcının aboneliğine göre
  /// kendi "Pro"/"Pro+" rozetini taşıyan bir varyanta değişir (Zibo Pro(+)
  /// materyalleri, sabit-genişlik DEĞİL — her logo kendi doğal en/boy
  /// oranıyla `height: 40` sabitine göre ölçekleniyor — Faz 6'da kullanıcı
  /// geri bildirimiyle 28 → 38 → 46 (çok büyük) → 40'a ayarlandı).
  String _ziboLogoAsset(SubscriptionProvider subscription) {
    if (subscription.isProPlus) return 'assets/images/zibo_pro_plus_logo.webp';
    if (subscription.isPro) return 'assets/images/zibo_pro_logo.webp';
    return 'assets/images/zibo_logo_new.webp';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Faz 5 — Zibo Pro/Pro+ kullanıcıya AppBar'da özel logo (bkz.
    // `_ziboLogoAsset`).
    final subscription = context.watch<SubscriptionProvider>();

    // GoalTrackingScreen, yalnızca gerçekten görünen sekme olduğunda
    // otomatik söz döndürme zamanlayıcısını çalıştırabilmek için hangi
    // sekmenin aktif olduğunu bilmek zorunda; bu yüzden _tabs statik değil,
    // her build'de güncel _selectedIndex ile kuruluyor.
    final tabs = [
      const HomeScreen(),
      GoalTrackingScreen(isActive: _selectedIndex == _goalTrackingTabIndex),
      ProfileScreen(isActive: _selectedIndex == _profileTabIndex),
      StoreScreen(isActive: _selectedIndex == _storeTabIndex),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: l10n.homeAppBarTitle,
          child: Image.asset(_ziboLogoAsset(subscription), height: 40),
        ),
        centerTitle: false,
        actions: [
          const CoinBalanceWidget(),
          // Yalnızca Hedefler sekmesindeyken görünür — diğer üç sekmenin
          // AppBar'ı değişmez (bkz. WheelTriggerButton'ın yalnızca Ana
          // Sayfa'da görünmesiyle aynı koşullu-görünürlük deseni).
          if (_selectedIndex == _goalTrackingTabIndex) ...[
            StickerIconButton(
              emoji: '🏆',
              tooltip: l10n.completedGoalsButtonTooltip,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              iconColor: Theme.of(context).colorScheme.onSurface,
              size: 30,
              iconSize: 16,
              borderRadius: 9,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompletedGoalsScreen()),
              ),
            ),
            const SizedBox(width: 8),
          ],
          StickerIconButton(
            emoji: '➕',
            tooltip: l10n.storeButtonTooltip,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            iconColor: Theme.of(context).colorScheme.onSurface,
            size: 30,
            iconSize: 16,
            borderRadius: 9,
            // Mağaza artık bir sekme; "+" bu sekmeye geçiş yapar.
            onPressed: () => _setSelectedIndex(_storeTabIndex),
          ),
          const SizedBox(width: 8),
          StickerIconButton(
            emoji: '⚙️',
            tooltip: l10n.tabSettings,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            iconColor: Theme.of(context).colorScheme.onSurface,
            size: 30,
            iconSize: 16,
            borderRadius: 9,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Mockup'ın `.screen::before` nokta deseni — bkz.
            // `DotGridBackground` dokümantasyonu. Sekmelerin ARKASINDA tek
            // bir yerden ekleniyor, her sekmenin kendi opak yüzeyi
            // (kartlar, alt bar vb.) olduğu yerde zaten görünmez.
            const Positioned.fill(child: DotGridBackground()),
            IndexedStack(index: _selectedIndex, children: tabs),
            // Şans Çarkı tetikleyicisi: yalnızca Ana Sayfa sekmesindeyken
            // görünür (IndexedStack'in dışında olduğu için sekme geçişlerinde
            // kendisi yeniden kurulmuyor, sadece görünürlüğü değişiyor).
            // 2026 güncellemesi — kullanıcı ekran görüntüsüyle Günlük Ödül/
            // Rozetler tetikleyicilerinin "çok iç içe" (üst üste biner gibi)
            // durduğunu bildirdi; Çark/Günlük Ödül biraz daha yukarı
            // (-0.8 → -0.88) taşındı, Rozetler ile Günlük Ödül arasındaki
            // boşluk da büyütüldü (bkz. altta).
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(-1, -0.88),
                child: WheelTriggerButton(),
              ),
            // Günlük Giriş Ödülleri tetikleyicisi: çarkın SİMETRİĞİ, sağ
            // kenarda, aynı koşullu-görünürlük deseniyle.
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(1, -0.88),
                child: DailyRewardsTriggerButton(),
              ),
            // Rozetler tetikleyicisi: Günlük Ödül'ün ALTINDA, aynı sağ
            // kenarda, aynı koşullu-görünürlük deseniyle (bkz. CLAUDE.md
            // "Rozet Sistemi" bölümü). Aradaki boşluk -0.8/-0.55'teki
            // (0.25) eski değerden biraz büyütüldü (0.30) — artık arkasında
            // dairesel bir dekorasyon/gölge OLMADIĞI için (bkz.
            // BadgesTriggerButton dokümantasyonu) daha az gerekli olsa da,
            // fazladan bir nefes payı bırakıldı.
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(1, -0.58),
                child: BadgesTriggerButton(),
              ),
          ],
        ),
      ),
      floatingActionButton: ZFloatingButton(
        label: l10n.modulesMenuZButtonTooltip,
        onTap: () => showModulesMenuSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MainBottomBar(
        selectedIndex: _selectedIndex,
        onHomeTap: () => _setSelectedIndex(0),
        onGoalsTap: () => _setSelectedIndex(_goalTrackingTabIndex),
        onProfileTap: () => _setSelectedIndex(_profileTabIndex),
        onStoreTap: () => _setSelectedIndex(_storeTabIndex),
      ),
    );
  }
}
