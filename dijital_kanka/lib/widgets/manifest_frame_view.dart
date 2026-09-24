import 'package:flutter/material.dart';

import '../data/manifest_frames.dart';
import 'sticker_style.dart';

const _paper = Color(0xFFFFFDF7);
const _filmBlack = Color(0xFF1B1712);
const _filmHole = Color(0xFFF3E4C0);
const _gold = Color(0xFFF3B23C);
const _cream = Color(0xFFFFF4DE);
const _captionInk = Color(0xFF3A2F22);

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

  /// Yalnızca Polaroid'in alt boşluğunda gösterilir.
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
    }
  }

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
  const _DotPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = const Color(0x8CF3B23C);
    final step = unit * 0.037;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), unit * 0.005, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.unit != unit;
}
