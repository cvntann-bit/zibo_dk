import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/wheel_prizes.dart';
import '../l10n/app_localizations.dart';
import '../models/wheel_prize.dart';
import '../providers/coin_provider.dart';
import '../widgets/prize_wheel.dart';

/// Şans Çarkı popup'ı: büyük döndürülebilir çark (bkz. [PrizeWheel]) — "ok
/// işaretçisi" ve ortadaki "Reklam İzle ve Çevir" hub'ı zaten
/// `zibo_cark_frame.png`'nin içinde hazır geldiği için burada ayrıca
/// çizilmiyor, yalnızca hub'ın üzerine görünmez, dokunulabilir bir alan
/// yerleştiriliyor. Tam ekran bir Dialog olarak açılır (bkz.
/// [WheelTriggerButton]).
class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  static const _wheelSize = 300.0;
  // zibo_cark_frame.png'deki hub, çarkın çapının ~%74'ünü kaplıyor (bkz.
  // tool/split_wheel_layers.dart'taki _frameHubFraction*2) — dokunulabilir
  // alan hub'ın görsel sınırlarıyla eşleşsin diye aynı oran kullanılıyor.
  static const _hubSizeFraction = 0.74;
  // Her çevirmede en az bu kadar tam tur atılır — kısa/ani bir sıçrama
  // yerine gerçek bir "dönüyor" hissi versin diye.
  static const _fullTurnsPerSpin = 5;

  // initState()'te (late final yerine) ATANIYOR: build()/dispose() dışında
  // hiçbir yerde erişilmediği bir senaryoda (ör. kullanıcı çarkı hiç
  // çevirmeden kapatırsa) late final'in TEMBEL başlatılması ilk kez
  // dispose() içinde tetiklenirdi — o noktada widget artık deactivate
  // edilmiş olduğundan vsync:this ancestor look-up'ı "Looking up a
  // deactivated widget's ancestor is unsafe" hatasıyla çöker. Mount
  // olurken (initState) erken atayarak bunu önlüyoruz.
  late final AnimationController _controller;
  late Animation<double> _rotationAnimation = const AlwaysStoppedAnimation(
    0,
  );

  double _rotation = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final coins = context.read<CoinProvider>();
    setState(() => _spinning = true);

    final prize = await coins.watchAdAndSpinWheel();
    if (!mounted) return;

    if (prize == null) {
      setState(() => _spinning = false);
      return;
    }

    final targetIndex = wheelPrizes.indexOf(prize);
    final sliceAngle = 2 * pi / wheelPrizes.length;
    // Hedef dilimin ortasını göstergenin (saat 12 yönü) altına getirecek
    // açı; ardından en az _fullTurnsPerSpin tam tur ekleniyor ki çark hep
    // ileri doğru (asla geri) ve doyurucu uzunlukta dönsün.
    final targetWithinTurn = -(sliceAngle * (targetIndex + 0.5));
    var target = targetWithinTurn;
    while (target < _rotation + _fullTurnsPerSpin * 2 * pi) {
      target += 2 * pi;
    }

    setState(() {
      _rotationAnimation = Tween<double>(begin: _rotation, end: target)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
    });
    await _controller.forward(from: 0);
    _rotation = target;
    if (!mounted) return;
    setState(() => _spinning = false);

    await _showResultDialog(prize);
  }

  Future<void> _showResultDialog(WheelPrize prize) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.wheelResultTitle),
        content: Text(l10n.wheelResultMessage(prize.amount)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.wheelResultButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hubSize = _wheelSize * _hubSizeFraction;
    // Günlük hak tükendiyse (bkz. CoinProvider.maxDailyWheelSpins) hub'ın
    // dokunma alanı devre dışı kalır + başlığın altında uyarı mesajı
    // belirir — `_WatchAdCard`'daki AYNI "pasif görünüm" deseni.
    final canSpin = context.watch<CoinProvider>().canSpinWheelToday;

    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.wheelCloseTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              l10n.wheelTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!canSpin) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.dailyAdLimitReachedMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            Expanded(
              // Kullanıcı isteği: çark popup'ı biraz yukarıya kaydırılsın —
              // `Center` yerine hafifçe yukarı kaymış bir `Align` kullanmak,
              // çarkın kendisine/animasyonuna hiç dokunmadan yalnızca
              // görsel konumunu değiştiriyor.
              child: Align(
                alignment: const Alignment(0, -0.25),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, _) => PrizeWheel(
                        size: _wheelSize,
                        rotation: _rotationAnimation.value,
                      ),
                    ),
                    // zibo_cark_frame.png zaten "Reklam İzle ve Çevir"
                    // metnini/ikonunu içeriyor — burada yalnızca dokunma
                    // alanı ve (çevirme sırasında) bir yükleniyor göstergesi
                    // ekleniyor, ayrıca bir buton çizilmiyor.
                    SizedBox(
                      width: hubSize,
                      height: hubSize,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: const Key('wheelSpinButton'),
                          customBorder: const CircleBorder(),
                          onTap: (_spinning || !canSpin) ? null : _spin,
                          child: Semantics(
                            button: true,
                            label: l10n.wheelSpinButton,
                            child: Center(
                              child: _spinning
                                  ? SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.primary,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
