import 'package:flutter/material.dart';

/// "Çizgi Roman Çıkartması" mockup'ının `.screen::before` katmanıyla AYNI
/// ince nokta deseni — mockup'ta `radial-gradient(#00000010 1.5px,
/// transparent 1.8px)` / `background-size:14px 14px` olarak tanımlı. CSS'in
/// tekrarlayan radial-gradient'i Flutter'da doğrudan bir `BoxDecoration`
/// ile ifade edilemediği için tek seferlik bir `CustomPainter` ızgarası
/// kullanılıyor (statik, animasyonsuz — [shouldRepaint] yalnızca renk
/// değişince true döner).
///
/// [RootScreen]'in gövde `Stack`'inde, sekmelerin ARKASINDA (`IndexedStack`
/// öncesinde) tek bir yerden ekleniyor — böylece her sekme kendi arka
/// planını OPAK bir renkle KAPLAMADIĞI sürece (mockup'taki `.navbar`'ın
/// beyaz dolgusu gibi) desen otomatik olarak görünür, ekran başına ayrı
/// ayrı eklenmesi gerekmez.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key});

  static const _spacing = 14.0;
  static const _radius = 1.5;

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);
    return IgnorePointer(
      child: CustomPaint(painter: _DotGridPainter(dotColor: dotColor)),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (var y = DotGridBackground._spacing / 2; y < size.height; y += DotGridBackground._spacing) {
      for (var x = DotGridBackground._spacing / 2; x < size.width; x += DotGridBackground._spacing) {
        canvas.drawCircle(Offset(x, y), DotGridBackground._radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => oldDelegate.dotColor != dotColor;
}
