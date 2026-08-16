import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/push_notification_type.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../utils/tab_navigation.dart';
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
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';

/// Uygulamanın sabit başlık çubuğunu ve alt gezinme çubuğunu barındıran
/// ana iskelet. Sekmeler arasında geçiş yapıldığında başlık çubuğu sabit
/// kalır, yalnızca gövde (body) değişir. Ayarlar sekmelerden biri değildir;
/// başlık çubuğundaki dişli ikonundan ayrı bir sayfa olarak push edilir.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key, this.pushNotificationService});

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `FirebaseMessagingPushNotificationService()` (`AdService`/
  /// `ShareService` ile AYNI desen).
  final PushNotificationService? pushNotificationService;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  static const _goalTrackingTabIndex = 1;
  static const _profileTabIndex = 2;
  static const _storeTabIndex = 3;

  int _selectedIndex = 0;
  late final PushNotificationService _pushNotificationService =
      widget.pushNotificationService ?? FirebaseMessagingPushNotificationService();

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
        if (mounted) context.read<NotificationProvider>().initializeAndSchedule();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    homeTabRequest.removeListener(_onHomeTabRequested);
    goalsTabRequest.removeListener(_onGoalsTabRequested);
    dailyRewardsPopupRequest.removeListener(_onDailyRewardsPopupRequested);
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

  /// Bir push bildirimine dokunulduğunda (bkz. `PushNotificationService`)
  /// `PushNotificationType`'a göre doğru sekmeye/popup'a yönlendirir.
  void _handlePushNotificationTap(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.dailyMotivation:
      case PushNotificationType.reEngagement:
        homeTabRequest.value++;
      case PushNotificationType.streakReminder:
        goalsTabRequest.value++;
      case PushNotificationType.dailyReward:
        dailyRewardsPopupRequest.value++;
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
      const ProfileScreen(),
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
