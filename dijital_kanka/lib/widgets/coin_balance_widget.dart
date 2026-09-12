import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_provider.dart';

/// Başlık çubuğunda her zaman görünen coin bakiyesi rozeti: ikon + sayı.
/// Bakiye değiştiğinde sayı eski değerden yeni değere doğru kısa bir
/// animasyonla sayar, üstünde de "+N" / "-N" şeklinde yükselip kaybolan
/// bir metin belirir.
class CoinBalanceWidget extends StatefulWidget {
  const CoinBalanceWidget({super.key});

  @override
  State<CoinBalanceWidget> createState() => _CoinBalanceWidgetState();
}

class _CoinBalanceWidgetState extends State<CoinBalanceWidget>
    with SingleTickerProviderStateMixin {
  // initState içinde kuruluyor (late final + ilk erişimde kurulum değil):
  // aksi halde bu widget hiç coin olayı yaşamadan dispose edilirse
  // (ör. testte), controller ilk kez dispose() içinde oluşturulmaya
  // çalışılır ve artık deaktif olan context üzerinden vsync araması
  // güvensiz hale gelir.
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;
  late final Animation<double> _floatOpacity;

  CoinProvider? _provider;
  int? _floatingDelta;
  int _displayedBalance = 0;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatOffset = Tween(
      begin: 0.0,
      end: -18.0,
    ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeOut));
    _floatOpacity = TweenSequence<double>([
      TweenSequenceItem(weight: 15, tween: Tween(begin: 0.0, end: 1.0)),
      TweenSequenceItem(weight: 55, tween: ConstantTween(1.0)),
      TweenSequenceItem(weight: 30, tween: Tween(begin: 1.0, end: 0.0)),
    ]).animate(_floatController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<CoinProvider>();
    if (_provider != provider) {
      _provider?.removeListener(_onCoinsChanged);
      _provider = provider..addListener(_onCoinsChanged);
      _displayedBalance = provider.balance;
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onCoinsChanged);
    _floatController.dispose();
    super.dispose();
  }

  void _onCoinsChanged() {
    final delta = _provider!.lastDelta;
    if (delta == null || !mounted) return;
    setState(() => _floatingDelta = delta);
    _floatController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final balance = context.watch<CoinProvider>().balance;

    final tween = IntTween(begin: _displayedBalance, end: balance);
    if (_displayedBalance != balance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _displayedBalance = balance;
      });
    }

    return Semantics(
      label: l10n.coinBalanceLabel(balance),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/zibo_coin.webp', width: 20),
                const SizedBox(width: 6),
                TweenAnimationBuilder<int>(
                  tween: tween,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => Text(
                    '$value',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_floatingDelta != null)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => Opacity(
                  opacity: _floatOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _floatOffset.value),
                    child: child,
                  ),
                ),
                child: Text(
                  _floatingDelta! >= 0
                      ? '+${_floatingDelta!}'
                      : '${_floatingDelta!}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _floatingDelta! >= 0
                        ? Colors.green.shade700
                        : colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
