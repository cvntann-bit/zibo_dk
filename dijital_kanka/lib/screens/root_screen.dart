import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/push_notification_type.dart';
import '../providers/app_streak_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
import '../services/badge_coordinator.dart';
import '../services/home_widget_service.dart';
import '../services/home_widget_sync_coordinator.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../utils/tab_navigation.dart';
import '../utils/widget_module.dart';
import '../widgets/badges_trigger_button.dart';
import '../widgets/coin_balance_widget.dart';
import '../widgets/daily_rewards_trigger_button.dart';
import '../widgets/main_bottom_bar.dart';
import '../widgets/modules_menu_sheet.dart';
import '../widgets/wheel_trigger_button.dart';
import '../widgets/z_floating_button.dart';
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
      context.read<AppStreakProvider>().recordOpenForToday();
      _badgeCoordinator = BadgeCoordinator(
        badges: context.read<BadgeProvider>(),
        goals: context.read<GoalsProvider>(),
        appStreak: context.read<AppStreakProvider>(),
      );
    });
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
      context.read<AppStreakProvider>().recordOpenForToday();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          child: Image.asset('assets/images/zibo_logo_new.png', height: 28),
        ),
        centerTitle: false,
        actions: [
          const CoinBalanceWidget(),
          // Yalnızca Hedefler sekmesindeyken görünür — diğer üç sekmenin
          // AppBar'ı değişmez (bkz. WheelTriggerButton'ın yalnızca Ana
          // Sayfa'da görünmesiyle aynı koşullu-görünürlük deseni).
          if (_selectedIndex == _goalTrackingTabIndex)
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: l10n.completedGoalsButtonTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompletedGoalsScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.storeButtonTooltip,
            // Mağaza artık bir sekme; "+" bu sekmeye geçiş yapar.
            onPressed: () => _setSelectedIndex(_storeTabIndex),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.tabSettings,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: tabs),
            // Şans Çarkı tetikleyicisi: yalnızca Ana Sayfa sekmesindeyken
            // görünür (IndexedStack'in dışında olduğu için sekme geçişlerinde
            // kendisi yeniden kurulmuyor, sadece görünürlüğü değişiyor).
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(-1, -0.8),
                child: WheelTriggerButton(),
              ),
            // Günlük Giriş Ödülleri tetikleyicisi: çarkın SİMETRİĞİ, sağ
            // kenarda, aynı koşullu-görünürlük deseniyle.
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(1, -0.8),
                child: DailyRewardsTriggerButton(),
              ),
            // Rozetler tetikleyicisi: Günlük Ödül'ün HEMEN ALTINDA, aynı
            // sağ kenarda, aynı koşullu-görünürlük deseniyle (bkz. CLAUDE.md
            // "Rozet Sistemi" bölümü).
            if (_selectedIndex == 0)
              const Align(
                alignment: Alignment(1, -0.55),
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
