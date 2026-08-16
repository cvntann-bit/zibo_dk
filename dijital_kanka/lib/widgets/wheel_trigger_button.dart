import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/wheel_screen.dart';

/// Ekranın sol kenarında, yalnızca Ana Sayfa'dayken görünen, dikkat çekici
/// Şans Çarkı tetikleyicisi. İki katman üst üste durur:
/// - Arka plan (`zibo_cark_katman1.png`): sürekli ve hızlı döner.
/// - Ön plan (`zibo_cark_katman2.png` yerine — bkz. CLAUDE.md "Şans Çarkı"
///   bölümündeki not — birkaç küçük `zibo_coin.png` kopyası): dönmez, ama
///   üzerindeki coin'ler dikkat çeksin diye sürekli hafifçe titrer/büyür.
///
/// Basılınca tam ekran çark popup'ını ([WheelScreen]) açar. [RootScreen]
/// tarafından yalnızca Ana Sayfa sekmesindeyken sabit bir overlay olarak
/// konumlandırılır (bkz. root_screen.dart).
class WheelTriggerButton extends StatefulWidget {
  const WheelTriggerButton({super.key});

  @override
  State<WheelTriggerButton> createState() => _WheelTriggerButtonState();
}

class _WheelTriggerButtonState extends State<WheelTriggerButton>
    with TickerProviderStateMixin {
  static const _size = 72.0;

  // Arka plan katmanı hızlıca döner (kullanıcının isteği: "sürekli ve hızlı
  // şekilde dönsün").
  late final _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  // Ön plandaki coin'lerin hafif "nabız" animasyonu için ortak saat; her
  // coin kendi fazını (bkz. _PulsingCoin.phase) bu tek saatten türetiyor,
  // böylece hepsi tam senkron zıplamıyor.
  late final _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _animationsStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sürekli tekrar eden animasyonlar widget mount olduğu sürece asla
    // "settle" olmaz — kullanıcının OS düzeyindeki "hareketi azalt"
    // erişilebilirlik tercihine (ve flutter_test'in bunu true'ya
    // sabitleyebilmesine, bkz. widget_test.dart) saygı duyuyoruz.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _animationsStarted) {
      _animationsStarted = false;
      _spinController.stop();
      _pulseController.stop();
    } else if (!reduceMotion && !_animationsStarted) {
      _animationsStarted = true;
      _spinController.repeat();
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const WheelScreen(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Semantics(
            button: true,
            label: l10n.wheelTriggerTooltip,
            child: Tooltip(
              message: l10n.wheelTriggerTooltip,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) => Transform.rotate(
                        angle: _spinController.value * 2 * pi,
                        child: child,
                      ),
                      child: Image.asset(
                        'assets/images/zibo_cark_katman1.png',
                        width: _size,
                        height: _size,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 2,
                      child: _PulsingCoin(
                        controller: _pulseController,
                        size: 22,
                        phase: 0,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      left: 0,
                      child: _PulsingCoin(
                        controller: _pulseController,
                        size: 18,
                        phase: 0.45,
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

class _PulsingCoin extends StatelessWidget {
  const _PulsingCoin({
    required this.controller,
    required this.size,
    required this.phase,
  });

  final Animation<double> controller;
  final double size;

  /// 0-1 arası faz kayması — coin'lerin hepsi tam senkron zıplamasın diye.
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + phase) % 1.0;
        final scale = 1.0 + 0.2 * sin(t * 2 * pi).abs();
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.asset('assets/images/zibo_coin.png', width: size, height: size),
    );
  }
}
