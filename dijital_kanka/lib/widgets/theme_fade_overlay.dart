import 'package:flutter/material.dart';

/// [themeMode] her değiştiğinde, altındaki [child]'ın üstüne kısa süreliğine
/// (yeni arka plan renginde) bir "perde" koyup hemen açarak yumuşak bir
/// geçiş hissi verir.
///
/// Bilerek `AnimatedTheme` KULLANMIYOR: tüm [ThemeData] ağacını (kart/buton
/// gibi karmaşık Material 3 alt temaları dahil) her karede yeniden inşa edip
/// interpolasyon yapmaya çalışmak hem pahalıydı (tüm ekran, hatta
/// IndexedStack'teki görünmeyen sekmeler bile saniyede ~60 kez yeniden
/// çiziliyordu) hem de buton/kart gibi renk dışı alt temalar düzgün
/// interpolasyon desteklemediği için görsel takılmaya/kesintiye yol
/// açıyordu. Burada tema anında değişir; yalnızca tek bir opaklık
/// animasyonu (bu perde) çalışır — ucuz ve pürüzsüzdür.
class ThemeFadeOverlay extends StatefulWidget {
  const ThemeFadeOverlay({
    super.key,
    required this.themeMode,
    this.equippedThemeId,
    required this.child,
  });

  final ThemeMode themeMode;

  /// Mağaza > Temalar'dan aktif edilen kod-tabanlı temanın id'si (bkz.
  /// `AppThemeProvider.equippedId`) — açık/koyu mod değişiminin yanı sıra
  /// kullanıcı bir temayı satın alıp uyguladığında/kaldırdığında da aynı
  /// "perde" geçişi tetiklensin diye izleniyor, aksi halde renkler ANİDEN
  /// değişip göze çarpan bir "flaş" hissi verirdi.
  final String? equippedThemeId;

  final Widget child;

  @override
  State<ThemeFadeOverlay> createState() => _ThemeFadeOverlayState();
}

class _ThemeFadeOverlayState extends State<ThemeFadeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1, // Başlangıçta perde tamamen açık (görünmez).
  );

  @override
  void didUpdateWidget(covariant ThemeFadeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode ||
        oldWidget.equippedThemeId != widget.equippedThemeId) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veilColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Opacity(
              opacity: 1 - _controller.value,
              child: ColoredBox(color: veilColor),
            ),
          ),
        ),
      ],
    );
  }
}
