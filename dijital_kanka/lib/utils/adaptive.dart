import 'package:flutter/widgets.dart';

/// Tablet / geniş ekran düzen kuralları (2026-10-29, Google Play "tablet için
/// tasarlandı" rozeti hedefi — bkz. `docs/tablet_optimization.md`).
///
/// Telefonda (genişlik < 700) hiçbir şey değişmez; kurallar yalnızca geniş
/// ekranda devreye girer. Eşikler `MediaQuery.sizeOf` genişliğine göre — test
/// ortamının varsayılan 800×600 yüzeyi "dar tablet" sayılır ama yan menü
/// (≥ 1000) devreye girmez.
class Adaptive {
  Adaptive._();

  /// Yan gezinme menüsü + iki bölmeli Ana Sayfa: yatay tablet / geniş pencere.
  static const double sideNavMinWidth = 1000;

  /// Liste/form ağırlıklı ekranlarda içeriğin en fazla genişliği.
  static const double contentMaxWidth = 760;

  /// Ana Sayfa'nın tek bölmeli (dikey) hâlinde balon + kart sütununun genişliği.
  static const double homeColumnMaxWidth = 680;

  static bool useSideNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= sideNavMinWidth;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

  /// Sekme gövdesinin genişliği (yan menü açıksa onun 96 dp'si düşülür).
  static double bodyWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return useSideNav(context) ? w - 96 : w;
  }

  /// Kaydırılan bir gövdeyi [maxWidth] içinde ortalamak için yatay dolgu —
  /// telefonda [minPadding], geniş ekranda iki yandaki boşluğun yarısı.
  static double horizontalPadding(BuildContext context, {double maxWidth = contentMaxWidth, double minPadding = 20}) {
    final extra = (bodyWidth(context) - maxWidth) / 2;
    return extra > minPadding ? extra : minPadding;
  }

  /// Kullanılabilir [width] içinde en az [minTileWidth] genişlikte kaç sütun
  /// sığar — telefonda [min] altına düşmez, çok geniş ekranda [max]'ı aşmaz.
  static int columnsFor(double width, {required double minTileWidth, int min = 2, int max = 6}) =>
      (width / minTileWidth).floor().clamp(min, max);
}

/// Çocuğunu ekranın ortasında en fazla [maxWidth] genişlikte tutar; telefonda
/// (genişlik ≤ [maxWidth]) etkisizdir. Kaydırılabilir gövdeleri sarmak için:
/// yükseklik kısıtını olduğu gibi geçirir.
class AdaptiveCenter extends StatelessWidget {
  const AdaptiveCenter({super.key, this.maxWidth = Adaptive.contentMaxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dar ekranda (telefon) çocuğa HİÇ dokunma — kısıtlar aynen geçer,
        // düzen eskisiyle birebir aynı kalır.
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) return child;
        // Geniş ekranda yalnızca genişlik daralır; yükseklik kısıtı olduğu
        // gibi (sıkıysa sıkı) kalır → Expanded/Positioned.fill düzenleri bozulmaz.
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
