import 'dart:math';

import 'package:flutter/material.dart';

/// "Gece Gökyüzü" temasının koyu varyantı üzerine bindirilen, SABİT
/// (deterministik) küçük nokta deseni — her `build()`'de aynı yıldızları
/// üretir (tohum sabit), hem çalışma zamanında rastgelelik/performans
/// maliyetinden kaçınmak hem de her yeniden çizimde yıldızların "zıplayıp
/// durmaması" için. Harici bir animasyon/parçacık paketi GEREKMİYOR —
/// `CustomPainter` ile birkaç küçük daire çiziliyor.
class StarryGradientBackground extends StatelessWidget {
  const StarryGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `foregroundPainter` (arka plan gradyanının ÜZERİNE, `child`'dan SONRA
    // çizilir) — sıradan `painter` kullanılsaydı yıldızlar gradyanın
    // ARKASINDA kalıp görünmezdi.
    return CustomPaint(
      foregroundPainter: _StarsPainter(),
      child: child,
    );
  }
}

class _StarsPainter extends CustomPainter {
  // Sabit tohum: aynı yıldız deseni her build'de birebir tekrarlanır.
  static final _random = Random(42);
  static final List<_Star> _stars = List.generate(
    28,
    (_) => _Star(
      dx: _random.nextDouble(),
      dy: _random.nextDouble(),
      radius: 0.6 + _random.nextDouble() * 1.4,
      opacity: 0.25 + _random.nextDouble() * 0.5,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final star in _stars) {
      paint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.opacity,
  });

  final double dx;
  final double dy;
  final double radius;
  final double opacity;
}
