import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/daily_rewards_provider.dart';
import '../screens/daily_rewards_screen.dart';

/// Ekranın sağ kenarında, yalnızca Ana Sayfa'dayken görünen, dikkat çekici
/// Günlük Giriş Ödülleri tetikleyicisi — `WheelTriggerButton`'ın (sol
/// kenarda) SİMETRİĞİ olacak şekilde konumlandırılıyor (bkz.
/// root_screen.dart). Kod-tabanlı bir hediye kutusu rozeti (görsel asset
/// gerektirmez, `Temalar`'dan seçilen aktif temanın `colorScheme.primary`
/// rengini otomatik yansıtır) — bugünün ödülü henüz alınmadıysa hafif bir
/// "nabız" (ölçek + parlama) animasyonuyla dikkat çeker; alınmışsa animasyon
/// durur ve köşede küçük bir tik rozeti belirir.
class DailyRewardsTriggerButton extends StatefulWidget {
  const DailyRewardsTriggerButton({super.key});

  @override
  State<DailyRewardsTriggerButton> createState() =>
      _DailyRewardsTriggerButtonState();
}

class _DailyRewardsTriggerButtonState extends State<DailyRewardsTriggerButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _size = 72.0;

  late final _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _animationsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Uygulama uzun süre arka planda kalıp gün değiştiyse, bu sekmeye
    // dönüldüğünde (bu widget yeniden mount olduğunda) rozetin doğru
    // durumu (bugünün ödülü hazır mı/alınmış mı) hemen yansıtması için —
    // `GoalTrackingScreen._reconcileForToday` ile AYNI desen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcile());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reconcile();
  }

  void _reconcile() {
    if (!mounted) return;
    context.read<DailyRewardsProvider>().reconcileForToday();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final claimed = context.watch<DailyRewardsProvider>().isTodayClaimed;
    // Sürekli tekrar eden animasyon widget mount olduğu sürece asla
    // "settle" olmaz — kullanıcının OS düzeyindeki "hareketi azalt"
    // tercihine (ve flutter_test'in bunu sabitleyebilmesine, bkz.
    // widget_test.dart) saygı duyuyoruz; ayrıca bugünün ödülü zaten
    // alınmışsa animasyon dikkat çekmemeli, dursun.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final shouldAnimate = !reduceMotion && !claimed;
    if (shouldAnimate && !_animationsStarted) {
      _animationsStarted = true;
      _pulseController.repeat(reverse: true);
    } else if (!shouldAnimate && _animationsStarted) {
      _animationsStarted = false;
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final claimed = context.watch<DailyRewardsProvider>().isTodayClaimed;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const DailyRewardsScreen(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Semantics(
            button: true,
            label: l10n.dailyRewardsTriggerTooltip,
            child: Tooltip(
              message: l10n.dailyRewardsTriggerTooltip,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final t = _pulseController.value;
                        final scale = 1.0 + 0.1 * t;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: _size,
                            height: _size,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.primary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.35 + 0.35 * t,
                                  ),
                                  blurRadius: 8 + 10 * t,
                                  spreadRadius: 1 + 2 * t,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: _size * 0.5,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    if (claimed)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.secondaryContainer,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
