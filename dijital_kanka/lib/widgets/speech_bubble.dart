import 'package:flutter/material.dart';

/// Üstte küçük bir kuyruğu (ok ucu) olan klasik konuşma balonu şekli.
/// Zibo'nun günün mesajını göstermek için kullanılır.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _SpeechBubblePainter(color: colorScheme.surfaceContainerHigh),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({required this.color});

  final Color color;
  static const double _radius = 20;
  static const double _tailHeight = 14;
  static const double _tailWidth = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final bubbleRect = Rect.fromLTWH(
      0,
      _tailHeight,
      size.width,
      size.height - _tailHeight,
    );
    final rrect = RRect.fromRectAndRadius(
      bubbleRect,
      const Radius.circular(_radius),
    );

    final path = Path()..addRRect(rrect);

    final tailCenterX = size.width / 2;
    final tailPath = Path()
      ..moveTo(tailCenterX - _tailWidth / 2, _tailHeight + 1)
      ..lineTo(tailCenterX, 0)
      ..lineTo(tailCenterX + _tailWidth / 2, _tailHeight + 1)
      ..close();

    path.addPath(tailPath, Offset.zero);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.15), 6, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color;
}
