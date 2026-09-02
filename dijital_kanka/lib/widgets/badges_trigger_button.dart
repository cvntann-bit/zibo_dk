import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/badges_gallery_screen.dart';

/// Ana Sayfa'da, mevcut Günlük Ödül tetikleyicisinin hemen ALTINDA duran
/// Rozetler tetikleyicisi — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// `DailyRewardsTriggerButton`'ın kod-tabanlı (görsel asset gerektirmeyen)
/// rozet deseninin AKSİNE, kullanıcının verdiği `popup_rozet_icon.png`
/// görselini kullanıyor — kullanıcının açık isteği "hafif, göz yormayan bir
/// animasyon... Şans Çarkı'nın titreşen coin animasyonu gibi dikkat dağıtıcı
/// OLMAYAN, daha sakin ve SÜREKLİ OLMAYAN bir animasyon" idi. Bu yüzden
/// `DailyRewardsTriggerButton`'ın sürekli `repeat(reverse: true)` nabzı
/// yerine, bir döngü İÇİNDE kısa bir nabız + UZUN bir dinlenme dilimi
/// kullanılıyor (`_pulseScaleFor`) — göz sürekli hareket görmüyor, yalnızca
/// arada bir hafifçe "nefes alıyor".
///
/// Tıklanınca ARA bir pop-up/önizleme OLMADAN doğrudan [BadgesGalleryScreen]
/// açılır (kullanıcının açık isteği).
class BadgesTriggerButton extends StatefulWidget {
  const BadgesTriggerButton({super.key});

  @override
  State<BadgesTriggerButton> createState() => _BadgesTriggerButtonState();
}

class _BadgesTriggerButtonState extends State<BadgesTriggerButton>
    with SingleTickerProviderStateMixin {
  static const _size = 64.0;

  late final _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _animationsStarted = false;

  /// Bir döngünün yalnızca ilk %30'unda pürüzsüz bir nabız (1.0 → 1.07 →
  /// 1.0), kalan %70'inde tam dinlenme (1.0, sabit) — "sakin ve sürekli
  /// olmayan" isteğinin karşılığı.
  double _pulseScaleFor(double t) {
    const activeFraction = 0.3;
    if (t >= activeFraction) return 1.0;
    final local = t / activeFraction; // 0..1
    final eased = Curves.easeInOut.transform(local);
    final bump = eased <= 0.5 ? eased * 2 : (1 - eased) * 2;
    return 1.0 + 0.07 * bump;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion && !_animationsStarted) {
      _animationsStarted = true;
      _pulseController.repeat();
    } else if (reduceMotion && _animationsStarted) {
      _animationsStarted = false;
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BadgesGalleryScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Semantics(
            button: true,
            label: l10n.badgesTriggerTooltip,
            child: Tooltip(
              message: l10n.badgesTriggerTooltip,
              child: SizedBox(
                width: _size,
                height: _size,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _pulseScaleFor(_pulseController.value);
                    final glow = (scale - 1.0) / 0.07; // 0..1
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
                              colorScheme.secondaryContainer,
                              colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.25 + 0.25 * glow,
                              ),
                              blurRadius: 6 + 8 * glow,
                              spreadRadius: 1 + 1.5 * glow,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/popup_rozet_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
