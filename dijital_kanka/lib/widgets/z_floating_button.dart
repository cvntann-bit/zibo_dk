import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/costume_provider.dart';
import 'sticker_style.dart';

const _coinSize = 64.0;
const _framePadding = 6.0;

/// Giyili kostüme göre gösterilecek Z Coin buton görseli. Yalnızca Altın ve
/// Elmas Kaplama Zibo kostümlerinin kendi teması var — diğer TÜM kostümlerde
/// (veya kostümsüzken) standart görsele düşülür. Üç dosya da
/// `tool/process_coin_theme.dart`/`measure_coin_bounds.dart` ile AYNI
/// 374x374 kare tuvale kırpılıp ölçeklendi (bkz. CLAUDE.md "Alt Gezinme
/// Çubuğu") — bu yüzden hangisi gösterilirse gösterilsin buton boyutu SABİT
/// kalır, yalnızca görsel/tema değişir.
String _coinAssetFor(String? equippedCostumeId) {
  switch (equippedCostumeId) {
    case 'zibo_altin':
      return 'assets/images/bottom_bar_z_coin_altintema.webp';
    case 'zibo_elmas':
      return 'assets/images/bottom_bar_z_coin_elmastema.webp';
    default:
      return 'assets/images/bottom_bar_z_coin.webp';
  }
}

/// Z butonu — kostüme göre değişen Z Coin görselini kendi ekseni etrafında
/// hafifçe "sallayan", RootScreen'in `Scaffold.floatingActionButton`
/// alanına `FloatingActionButtonLocation.centerDocked` ile bağlanan bir
/// widget. `MainBottomBar`'daki `BottomAppBar`'ın `CircularNotchedRectangle`
/// şekliyle birlikte Flutter'ın standart "ortada yüzen buton + çentikli bar"
/// deseni oluşuyor — pozisyon/çentik hizalaması tamamen Flutter'ın kendi
/// Scaffold geometrisi tarafından hesaplanıyor, elle piksel/oran hesabı YOK
/// (bkz. CLAUDE.md "Alt Gezinme Çubuğu" — önceki, tamamen özel PNG'lere
/// dayanan sürümün yerini bu aldı).
class ZFloatingButton extends StatefulWidget {
  const ZFloatingButton({super.key, required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  State<ZFloatingButton> createState() => _ZFloatingButtonState();
}

class _ZFloatingButtonState extends State<ZFloatingButton>
    with SingleTickerProviderStateMixin {
  // Sürekli, yavaş bir "sallanma" — bir tam tur 2.4 saniye sürüyor, genlik
  // küçük (bkz. build()'teki sin() kullanımı) ki dikkat çeksin ama rahatsız
  // etmesin.
  late final _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool _animationsStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // WheelTriggerButton'daki aynı desen: OS düzeyindeki "hareketi azalt"
    // erişilebilirlik tercihine (ve flutter_test'in bunu sabitleyebilmesine)
    // saygı duy.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _animationsStarted) {
      _animationsStarted = false;
      _shakeController.stop();
    } else if (!reduceMotion && !_animationsStarted) {
      _animationsStarted = true;
      _shakeController.repeat();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // "Çizgi Roman Çıkartması" çerçevesi — YALNIZCA kontur/gölge/dolgu
        // ekliyor, kostüm görselinin kendisine (aşağıdaki tek `Image`)
        // DOKUNMUYOR (bkz. `z_floating_button_test.dart`'ın `find.byType(
        // Image)` varsayımı, `theme_new.md` "Z butonu" notu).
        child: DecoratedBox(
          decoration: stickerCircleDecoration(
            fill: colorScheme.primary,
            borderWidth: 3,
            shadowOffset: const Offset(3, 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_framePadding),
            child: SizedBox(
              width: _coinSize,
              height: _coinSize,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  // Tam bir sinüs turu (0 -> 2π) sorunsuz döngü sağlıyor
                  // (başı ve sonu aynı açıda, sıçrama yok). Genlik ~3.4
                  // derece — "hafif".
                  final angle = sin(_shakeController.value * 2 * pi) * 0.06;
                  return Transform.rotate(angle: angle, child: child);
                },
                child: Image.asset(_coinAssetFor(equippedId)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
