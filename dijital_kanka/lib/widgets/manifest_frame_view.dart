import 'package:flutter/material.dart';

import '../data/manifest_frames.dart';
import 'sticker_style.dart';

const _paper = Color(0xFFFFFDF7);
const _filmBlack = Color(0xFF1B1712);
const _filmHole = Color(0xFFF3E4C0);
const _gold = Color(0xFFF3B23C);
const _cream = Color(0xFFFFF4DE);
const _captionInk = Color(0xFF3A2F22);
const _honey = Color(0xFFF6D488);
const _ziboPeekAsset = 'assets/images/zibo_df_pose3.webp';

/// Manifest süsleme editörünün çerçevesi — [photo]'yu seçilen [frame]'e
/// göre sarar. Tüm ölçüler [width]'e oranlı: 4:5/1:1/9:16 arasında
/// geçişte ve 1080px dışa aktarımda aynı görünür. Kontur/renkler temadan
/// BAĞIMSIZ (çıktı görseli her temada aynı olmalı).
class ManifestFrameView extends StatelessWidget {
  const ManifestFrameView({
    super.key,
    required this.frame,
    required this.width,
    required this.photo,
    this.caption,
  });

  final ManifestFrame frame;
  final double width;
  final Widget photo;

  /// Yalnızca Polaroid ve Defter'in alt boşluğunda gösterilir.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final w = width;
    final border = Border.all(color: kStickerOutline, width: w * 0.009 + 1.5);
    switch (frame) {
      case ManifestFrame.none:
        return _box(
          decoration: BoxDecoration(border: border, borderRadius: BorderRadius.circular(w * 0.04)),
          inset: EdgeInsets.zero,
          photoRadius: w * 0.035,
        );
      case ManifestFrame.polaroid:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _paper, border: border, borderRadius: BorderRadius.circular(w * 0.018)),
              inset: EdgeInsets.fromLTRB(w * 0.045, w * 0.045, w * 0.045, w * 0.17),
              photoBorder: Border.all(color: kStickerOutline.withValues(alpha: 0.25), width: 1.5),
            ),
            if (caption != null)
              Positioned(
                left: w * 0.06,
                right: w * 0.06,
                bottom: w * 0.045,
                child: Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: w * 0.052,
                    color: _captionInk,
                  ),
                ),
              ),
          ],
        );
      case ManifestFrame.film:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _filmBlack, border: border, borderRadius: BorderRadius.circular(w * 0.018)),
              inset: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.08),
            ),
            Positioned.fill(child: CustomPaint(painter: _SprocketPainter(unit: w))),
          ],
        );
      case ManifestFrame.washi:
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            _box(
              decoration: BoxDecoration(color: _paper, border: border, borderRadius: BorderRadius.circular(w * 0.012)),
              inset: EdgeInsets.all(w * 0.035),
            ),
            Positioned(left: -w * 0.05, top: w * 0.03, child: _Tape(width: w * 0.26, angle: -0.66)),
            Positioned(right: -w * 0.05, top: w * 0.03, child: _Tape(width: w * 0.26, angle: 0.66)),
          ],
        );
      case ManifestFrame.gold:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _gold, border: border, borderRadius: BorderRadius.circular(w * 0.025)),
              inset: EdgeInsets.all(w * 0.05),
              photoBorder: border,
            ),
            ..._corners(w, '◆', w * 0.04, inset: w * 0.008, color: kStickerOutline),
          ],
        );
      case ManifestFrame.stars:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _cream, border: border, borderRadius: BorderRadius.circular(w * 0.055)),
              background: CustomPaint(painter: _DotPainter(unit: w)),
              inset: EdgeInsets.all(w * 0.055),
              photoBorder: border,
              photoRadius: w * 0.035,
            ),
            ..._corners(w, '⭐', w * 0.07, inset: w * 0.005),
          ],
        );
      case ManifestFrame.hearts:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _cream, border: border, borderRadius: BorderRadius.circular(w * 0.09)),
              inset: EdgeInsets.all(w * 0.1),
              photoBorder: border,
              photoRadius: w * 0.06,
            ),
            ..._corners(w, '💕', w * 0.1, inset: w * 0.012),
          ],
        );
      case ManifestFrame.notebook:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: _paper, border: border, borderRadius: BorderRadius.circular(w * 0.04)),
              background: CustomPaint(painter: _NotebookPainter(unit: w)),
              inset: EdgeInsets.fromLTRB(w * 0.15, w * 0.16, w * 0.08, w * 0.27),
              photoBorder: Border.all(color: kStickerOutline, width: 2),
            ),
            if (caption != null)
              Positioned(
                left: w * 0.16,
                right: w * 0.06,
                bottom: w * 0.07,
                child: Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: w * 0.06,
                    color: const Color(0xFF2B4C7E),
                  ),
                ),
              ),
          ],
        );
      case ManifestFrame.album:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: const Color(0xFFD9B98C), border: border, borderRadius: BorderRadius.circular(w * 0.04)),
              inset: EdgeInsets.all(w * 0.107),
            ),
            Positioned.fill(child: CustomPaint(painter: _PhotoCornerPainter(unit: w))),
          ],
        );
      case ManifestFrame.pop:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: _honey, border: border, borderRadius: BorderRadius.circular(w * 0.053)),
              child: CustomPaint(painter: _DotPainter(unit: w, color: const Color(0x4714110C), radius: 0.0107, step: 0.053)),
            ),
            Padding(
              padding: EdgeInsets.all(w * 0.093),
              child: Transform.rotate(
                angle: -0.035,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(border: border),
                  child: ClipRect(child: photo),
                ),
              ),
            ),
            Positioned(
              right: w * 0.02,
              top: w * 0.025,
              child: Transform.rotate(
                angle: 0.14,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.012),
                  decoration: BoxDecoration(
                    color: _cream,
                    border: Border.all(color: kStickerOutline, width: w * 0.012 + 1),
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: Text(
                    'WOW!',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 800)],
                      fontSize: w * 0.075,
                      height: 1.1,
                      color: kStickerOutline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case ManifestFrame.stamp:
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _StampPainter(unit: w)),
            Padding(
              padding: EdgeInsets.all(w * 0.093),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: kStickerOutline, width: 2)),
                child: ClipRect(child: photo),
              ),
            ),
            Positioned(
              right: w * 0.12,
              bottom: w * 0.105,
              child: Text('✨', style: TextStyle(fontSize: w * 0.08, height: 1)),
            ),
          ],
        );
      case ManifestFrame.neon:
        return DecoratedBox(
          decoration: BoxDecoration(color: kStickerOutline, borderRadius: BorderRadius.circular(w * 0.067)),
          child: Padding(
            padding: EdgeInsets.all(w * 0.093),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w * 0.04),
                boxShadow: [BoxShadow(color: _gold, blurRadius: w * 0.07, spreadRadius: w * 0.012)],
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: _gold, width: w * 0.018 + 1),
                  borderRadius: BorderRadius.circular(w * 0.04),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(w * 0.04), child: photo),
              ),
            ),
          ),
        );
      case ManifestFrame.floral:
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            _box(
              decoration: BoxDecoration(color: _cream, border: border, borderRadius: BorderRadius.circular(w * 0.08)),
              inset: EdgeInsets.all(w * 0.107),
              photoBorder: border,
              photoRadius: w * 0.053,
            ),
            Positioned(left: -w * 0.013, top: -w * 0.02, child: _emoji('🌸', w * 0.15)),
            Positioned(left: w * 0.107, top: -w * 0.04, child: _emoji('🌼', w * 0.1)),
            Positioned(right: -w * 0.013, bottom: -w * 0.02, child: _emoji('🌷', w * 0.15)),
            Positioned(right: w * 0.12, bottom: -w * 0.033, child: _emoji('🌸', w * 0.1)),
          ],
        );
      case ManifestFrame.night:
        return Stack(
          fit: StackFit.expand,
          children: [
            _box(
              decoration: BoxDecoration(color: const Color(0xFF1D2340), border: border, borderRadius: BorderRadius.circular(w * 0.067)),
              background: CustomPaint(painter: _StarFieldPainter(unit: w)),
              inset: EdgeInsets.all(w * 0.107),
              photoBorder: Border.all(color: _cream, width: w * 0.027),
              photoRadius: w * 0.027,
            ),
            Positioned(right: w * 0.02, top: w * 0.015, child: _emoji('🌙', w * 0.12)),
          ],
        );
      case ManifestFrame.royal:
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF7A1F2B), border: border, borderRadius: BorderRadius.circular(w * 0.053)),
            ),
            Padding(
              padding: EdgeInsets.all(w * 0.085),
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: _gold, width: w * 0.012 + 1)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(w * 0.12),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: _gold, width: w * 0.018 + 1)),
                child: ClipRect(child: photo),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -w * 0.005,
              child: Center(child: _emoji('👑', w * 0.12)),
            ),
          ],
        );
      case ManifestFrame.zibo:
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            _box(
              decoration: BoxDecoration(color: _cream, border: border, borderRadius: BorderRadius.circular(w * 0.08)),
              background: CustomPaint(painter: _DotPainter(unit: w)),
              inset: EdgeInsets.fromLTRB(w * 0.093, w * 0.093, w * 0.093, w * 0.2),
              photoBorder: border,
              photoRadius: w * 0.053,
            ),
            Positioned(
              right: -w * 0.053,
              bottom: -w * 0.04,
              child: Image.asset(_ziboPeekAsset, height: w * 0.52),
            ),
          ],
        );
    }
  }

  Widget _emoji(String glyph, double size) =>
      Text(glyph, style: TextStyle(fontSize: size, height: 1));

  Widget _box({
    required BoxDecoration decoration,
    required EdgeInsets inset,
    Widget? background,
    Border? photoBorder,
    double photoRadius = 0,
  }) {
    return DecoratedBox(
      decoration: decoration,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null) Positioned.fill(child: background),
          Padding(
            padding: inset,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: photoBorder,
                borderRadius: BorderRadius.circular(photoRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(photoRadius),
                child: photo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners(double w, String glyph, double size, {required double inset, Color? color}) {
    final style = TextStyle(fontSize: size, height: 1, color: color);
    Widget g() => Text(glyph, style: style);
    return [
      Positioned(left: inset, top: inset, child: g()),
      Positioned(right: inset, top: inset, child: g()),
      Positioned(left: inset, bottom: inset, child: g()),
      Positioned(right: inset, bottom: inset, child: g()),
    ];
  }
}

class _Tape extends StatelessWidget {
  const _Tape({required this.width, required this.angle});

  final double width;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: width * 0.3,
        decoration: BoxDecoration(
          border: Border.all(color: kStickerOutline.withValues(alpha: 0.35), width: 1.2),
        ),
        child: CustomPaint(painter: _StripePainter()),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xBFF6D488));
    final stripe = Paint()
      ..color = const Color(0xBFF3B23C)
      ..strokeWidth = size.height * 0.28;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width + size.height; x += size.height * 0.75) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

class _SprocketPainter extends CustomPainter {
  const _SprocketPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Paint()..color = _filmHole;
    final holeW = unit * 0.035;
    final holeH = unit * 0.028;
    final gap = unit * 0.07;
    final radius = Radius.circular(unit * 0.006);
    for (final y in [unit * 0.026, size.height - unit * 0.026 - holeH]) {
      for (var x = gap / 2; x + holeW < size.width; x += gap) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, holeW, holeH), radius), hole);
      }
    }
  }

  @override
  bool shouldRepaint(_SprocketPainter oldDelegate) => oldDelegate.unit != unit;
}

class _DotPainter extends CustomPainter {
  const _DotPainter({
    required this.unit,
    this.color = const Color(0x8CF3B23C),
    this.radius = 0.005,
    this.step = 0.037,
  });

  final double unit;
  final Color color;
  final double radius;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    final s = unit * step;
    for (var y = s / 2; y < size.height; y += s) {
      for (var x = s / 2; x < size.width; x += s) {
        canvas.drawCircle(Offset(x, y), unit * radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) =>
      oldDelegate.unit != unit || oldDelegate.color != color;
}

/// Çizgili defter: yatay mavi çizgiler, sol kırmızı kenar çizgisi, üstte
/// spiral delikleri.
class _NotebookPainter extends CustomPainter {
  const _NotebookPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFB9D3EA)
      ..strokeWidth = (unit * 0.006).clamp(0.6, 3.0);
    for (var y = unit * 0.093; y < size.height; y += unit * 0.093) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(
      Offset(unit * 0.093, 0),
      Offset(unit * 0.093, size.height),
      Paint()
        ..color = const Color(0xFFE7998B)
        ..strokeWidth = (unit * 0.012).clamp(1.0, 4.0),
    );
    final hole = Paint()..color = kStickerOutline;
    const count = 5;
    for (var i = 0; i < count; i++) {
      final x = size.width * (i + 1) / (count + 1);
      canvas.drawCircle(Offset(x, unit * 0.07), unit * 0.03, hole);
    }
  }

  @override
  bool shouldRepaint(_NotebookPainter oldDelegate) => oldDelegate.unit != unit;
}

/// Albüm: fotoğrafın dört köşesinde siyah üçgen köşelikler.
class _PhotoCornerPainter extends CustomPainter {
  const _PhotoCornerPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kStickerOutline;
    final o = unit * 0.08;
    final s = unit * 0.147;
    final w = size.width;
    final h = size.height;
    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();
    canvas
      ..drawPath(tri(Offset(o, o), Offset(o + s, o), Offset(o, o + s)), paint)
      ..drawPath(tri(Offset(w - o, o), Offset(w - o - s, o), Offset(w - o, o + s)), paint)
      ..drawPath(tri(Offset(o, h - o), Offset(o + s, h - o), Offset(o, h - o - s)), paint)
      ..drawPath(tri(Offset(w - o, h - o), Offset(w - o - s, h - o), Offset(w - o, h - o - s)), paint);
  }

  @override
  bool shouldRepaint(_PhotoCornerPainter oldDelegate) => oldDelegate.unit != unit;
}

/// Posta pulu: tırtıklı (yarım daire oyuklu) kenarlı beyaz kâğıt + kontur.
class _StampPainter extends CustomPainter {
  const _StampPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final r = unit * 0.03;
    final step = r * 2.6;
    final holes = Path();
    for (var x = step / 2; x < size.width; x += step) {
      holes
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: r))
        ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: r));
    }
    for (var y = step / 2; y < size.height; y += step) {
      holes
        ..addOval(Rect.fromCircle(center: Offset(0, y), radius: r))
        ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: r));
    }
    final paper = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), holes);
    canvas
      ..drawPath(paper, Paint()..color = _paper)
      ..drawPath(
        paper,
        Paint()
          ..color = kStickerOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = (unit * 0.009 + 1).clamp(1.0, 6.0),
      );
  }

  @override
  bool shouldRepaint(_StampPainter oldDelegate) => oldDelegate.unit != unit;
}

/// Gece Gökyüzü: sabit (her çizimde aynı) serpiştirilmiş küçük yıldızlar.
class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final star = Paint()..color = _cream;
    final step = unit * 0.11;
    var i = 0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        i++;
        final jx = ((i * 37) % 11 - 5) / 10 * step * 0.6;
        final jy = ((i * 53) % 13 - 6) / 12 * step * 0.6;
        final r = unit * (i % 3 == 0 ? 0.008 : 0.004);
        canvas.drawCircle(Offset(x + jx, y + jy), r, star);
      }
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) => oldDelegate.unit != unit;
}
