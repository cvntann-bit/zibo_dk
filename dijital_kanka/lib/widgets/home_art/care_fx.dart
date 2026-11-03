import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bakım oyunlarının parçacık efektleri — taslaktaki efekt tuvalinin
/// (`docs/home_studio/index.html` `tick`, `kitchenFrame`, `bedFrame`,
/// `salonFrame`) Dart karşılığı (docs/zibo_world_roadmap.md Faz 4).
///
/// Koordinatlar 900×1200 birimlik oda sahnesinde. Değerler taslaktaki gibi
/// kare başına ilerler; [step] her karede bir kez çağrılır.
class CareFx {
  final _rnd = math.Random();

  final List<_Spot> spots = [];
  final List<_Foam> foams = [];
  final List<_Bubble> bubbles = [];
  final List<_Drop> drops = [];
  final List<_Star> sparks = [];
  final List<_Crumb> crumbs = [];
  final List<_Float> hearts = [];
  final List<_Float> zs = [];
  final List<_Float> pops = [];
  final List<_Dust> dusts = [];

  /// Kalan duş karesi; bitince [onShowerDone] çağrılır.
  int shower = 0;
  VoidCallback? onShowerDone;

  /// Uyurken Z üretimi.
  bool sleeping = false;
  int _t = 0;

  /// Sürüklenen sabun (bar rengi, kontur) ve konumu.
  Offset? soapAt;
  Color soapBar = const Color(0xFFFF9FBF);
  Color soapStroke = const Color(0xFFE2668F);

  bool get busy =>
      foams.isNotEmpty ||
      bubbles.isNotEmpty ||
      drops.isNotEmpty ||
      sparks.isNotEmpty ||
      crumbs.isNotEmpty ||
      hearts.isNotEmpty ||
      zs.isNotEmpty ||
      pops.isNotEmpty ||
      dusts.isNotEmpty ||
      shower > 0 ||
      sleeping;

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  // --- Banyo ---------------------------------------------------------------

  /// [count] kir lekesi (Zibo'nun gövdesi üstünde rastgele).
  void dirty(int count) {
    clearBath();
    for (var i = 0; i < count; i++) {
      spots.add(_Spot(_r(170, 400), _r(400, 600), _r(16, 32)));
    }
  }

  void clearBath() {
    spots.clear();
    foams.clear();
    bubbles.clear();
    drops.clear();
    sparks.clear();
    shower = 0;
  }

  /// Lekelerin ortalama koyuluğu (0 temiz, 1 kirli).
  double get dirt => spots.isEmpty ? 0 : spots.fold<double>(0, (n, s) => n + s.a) / spots.length;

  /// Sabunla ovma: köpük + baloncuk, yakındaki lekeler silinir.
  void scrub(Offset p, Color fill, Color stroke) {
    if (foams.length < 260) foams.add(_Foam(p.dx + _r(-20, 20), p.dy + _r(-20, 20), _r(12, 30), fill, stroke));
    if (_rnd.nextBool()) bubbles.add(_Bubble(p.dx, p.dy, _r(6, 22), _r(1.2, 3), _r(0, 6)));
    for (final s in spots) {
      if ((Offset(s.x, s.y) - p).distance < 75) s.a = math.max(0, s.a - .07);
    }
  }

  void startShower() => shower = 110;

  void towel() {
    drops.clear();
    for (var i = 0; i < 14; i++) {
      sparks.add(_Star(_r(150, 430), _r(360, 600), _r(10, 22), 1 + _rnd.nextDouble() * .5));
    }
  }

  // --- Mutfak --------------------------------------------------------------

  void eat(Offset mouth) {
    for (var i = 0; i < 14; i++) {
      crumbs.add(_Crumb(mouth.dx + _r(-30, 30), mouth.dy + 10, _r(-1.5, 1.5), -_rnd.nextDouble() * 3));
    }
    for (var i = 0; i < 3; i++) {
      hearts.add(_Float(mouth.dx - 60 + i * 60, mouth.dy - 60, 1.2, 44, '♥'));
    }
  }

  // --- Salon ---------------------------------------------------------------

  void pop(String text) => pops.add(_Float(560, 420, 1.6, 46, text));

  /// Zıplayan Zibo'nun ayak altından kalkan toz (odalar arası geçiş).
  void dust(Offset feet) {
    for (var i = 0; i < 7; i++) {
      final dir = i.isEven ? 1 : -1;
      dusts.add(_Dust(feet.dx + _r(-20, 20), feet.dy - _r(0, 10), dir * _r(1.2, 3.6), -_r(.2, 1.4), _r(10, 20)));
    }
  }

  /// Bir kare ilerletir.
  void step() {
    // Duş: damlalar, köpük erir, lekeler silinir.
    if (shower > 0) {
      shower--;
      for (var i = 0; i < 6; i++) {
        drops.add(_Drop(120 + _r(0, 80) + _r(-60, 60), 296, _r(9, 15)));
      }
      for (final f in foams) {
        f.a -= .018;
      }
      for (final s in spots) {
        s.a = math.max(0, s.a - .03);
      }
      if (shower == 0) onShowerDone?.call();
    }
    foams.removeWhere((f) => f.a <= 0);
    for (final b in bubbles) {
      b.y -= b.vy;
      b.x += math.sin(b.y / 20 + b.w) * .8;
      b.a -= .006;
    }
    bubbles.removeWhere((b) => b.a <= 0 || b.y < -40);
    for (final d in drops) {
      d.y += d.v;
    }
    drops.removeWhere((d) => d.y >= 760);
    for (final s in sparks) {
      s.a -= .015;
      s.y -= .6;
    }
    sparks.removeWhere((s) => s.a <= 0);
    for (final c in crumbs) {
      c.x += c.vx;
      c.y += c.vy;
      c.vy += .25;
      c.a -= .02;
    }
    crumbs.removeWhere((c) => c.a <= 0);
    for (final h in hearts) {
      h.y -= 1.2;
      h.a -= .014;
    }
    hearts.removeWhere((h) => h.a <= 0);
    if (sleeping && ++_t % 34 == 0) zs.add(_Float(330, 440, 1, _r(26, 40), 'Z'));
    for (final z in zs) {
      z.y -= .8;
      z.x += .5;
      z.a -= .007;
    }
    zs.removeWhere((z) => z.a <= 0);
    for (final p in pops) {
      p.y -= .9;
      p.a -= .012;
    }
    pops.removeWhere((p) => p.a <= 0);
    for (final d in dusts) {
      d.x += d.vx;
      d.y += d.vy;
      d.vx *= .94;
      d.r += .9;
      d.a -= .03;
    }
    dusts.removeWhere((d) => d.a <= 0);
  }
}

class _Dust {
  _Dust(this.x, this.y, this.vx, this.vy, this.r);
  double x, y, vx, vy, r;
  double a = .85;
}

class _Spot {
  _Spot(this.x, this.y, this.r);
  final double x, y, r;
  double a = 1;
}

class _Foam {
  _Foam(this.x, this.y, this.r, this.fill, this.stroke);
  final double x, y, r;
  final Color fill, stroke;
  double a = 1;
}

class _Bubble {
  _Bubble(this.x, this.y, this.r, this.vy, this.w);
  double x, y;
  final double r, vy, w;
  double a = 1;
}

class _Drop {
  _Drop(this.x, this.y, this.v);
  final double x, v;
  double y;
}

class _Star {
  _Star(this.x, this.y, this.r, this.a);
  final double x, r;
  double y, a;
}

class _Crumb {
  _Crumb(this.x, this.y, this.vx, this.vy);
  double x, y, vx, vy;
  double a = 1;
}

class _Float {
  _Float(this.x, this.y, this.a, this.size, this.text);
  double x, y, a;
  final double size;
  final String text;
}

/// [CareFx]'i sahne ölçeğinde çizer.
class CareFxPainter extends CustomPainter {
  CareFxPainter(this.fx, {required Listenable repaint, this.offsetY = 0}) : super(repaint: repaint);

  final CareFx fx;

  /// Uzatılmış tuvalde sahnenin üst boşluğu ([RoomScene.extraTop]).
  final double offsetY;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 900;
    canvas.save();
    canvas.scale(k);
    canvas.translate(0, offsetY);
    final paint = Paint();
    double op(double a) => a.clamp(0.0, 1.0);

    for (final s in fx.spots) {
      if (s.a <= 0) continue;
      paint
        ..style = PaintingStyle.fill
        ..color = Color.fromRGBO(110, 72, 40, .62 * s.a);
      canvas
        ..drawCircle(Offset(s.x, s.y), s.r, paint)
        ..drawCircle(Offset(s.x + s.r * .6, s.y + s.r * .3), s.r * .6, paint)
        ..drawCircle(Offset(s.x - s.r * .5, s.y + s.r * .4), s.r * .5, paint);
    }
    for (final f in fx.foams) {
      final o = op(f.a);
      canvas.drawCircle(Offset(f.x, f.y), f.r, Paint()..color = f.fill.withValues(alpha: o));
      canvas.drawCircle(
        Offset(f.x, f.y),
        f.r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = f.stroke.withValues(alpha: o),
      );
    }
    for (final b in fx.bubbles) {
      final o = op(b.a);
      canvas.drawCircle(Offset(b.x, b.y), b.r, Paint()..color = Colors.white.withValues(alpha: .35 * o));
      canvas.drawCircle(
        Offset(b.x, b.y),
        b.r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFF7CC8F0).withValues(alpha: o),
      );
      canvas.drawCircle(Offset(b.x - b.r * .35, b.y - b.r * .35), b.r * .25, Paint()..color = Colors.white.withValues(alpha: o));
    }
    final dropPaint = Paint()
      ..color = const Color(0xFF5BB8E8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final d in fx.drops) {
      canvas.drawLine(Offset(d.x, d.y), Offset(d.x, d.y + 16), dropPaint);
    }
    for (final s in fx.sparks) {
      canvas.drawPath(_star(s.x, s.y, s.r, 8, .4), Paint()..color = const Color(0xFFFFD64A).withValues(alpha: op(s.a)));
    }
    for (final c in fx.crumbs) {
      canvas.drawCircle(Offset(c.x, c.y), 5, Paint()..color = const Color(0xFFC9772E).withValues(alpha: op(c.a)));
    }
    for (final h in fx.hearts) {
      _text(canvas, h, const Color(0xFFF2564B), null);
    }
    for (final z in fx.zs) {
      _text(canvas, z, Colors.white, const Color(0xFF1B2A5C));
    }
    for (final p in fx.pops) {
      _text(canvas, p, const Color(0xFFFFD64A), const Color(0xFF14110C));
    }
    for (final d in fx.dusts) {
      canvas.drawCircle(Offset(d.x, d.y), d.r, Paint()..color = const Color(0xFFE9DCC6).withValues(alpha: op(d.a)));
    }
    final soap = fx.soapAt;
    if (soap != null) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: soap, width: 76, height: 48), const Radius.circular(18));
      canvas.drawRRect(r, Paint()..color = fx.soapBar);
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = fx.soapStroke,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(soap.dx - 26, soap.dy - 16, 34, 9), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: .6),
      );
    }
    canvas.restore();
  }

  Path _star(double x, double y, double r, int points, double inner) {
    final path = Path();
    for (var i = 0; i < points; i++) {
      final rr = i.isOdd ? r * inner : r;
      final t = i * math.pi / (points / 2);
      final p = Offset(x + math.cos(t) * rr, y + math.sin(t) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _text(Canvas canvas, _Float f, Color fill, Color? stroke) {
    final o = f.a.clamp(0.0, 1.0);
    TextStyle style(Paint? fg) => TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: const [FontVariation('wght', 800)],
      fontSize: f.size,
      foreground: fg,
      color: fg == null ? fill.withValues(alpha: o) : null,
    );
    if (stroke != null) {
      final outline = TextPainter(
        text: TextSpan(
          text: f.text,
          style: style(
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = f.size / 7
              ..strokeJoin = StrokeJoin.round
              ..color = stroke.withValues(alpha: o),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      outline.paint(canvas, Offset(f.x, f.y - f.size));
    }
    final tp = TextPainter(text: TextSpan(text: f.text, style: style(null)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(f.x, f.y - f.size));
  }

  @override
  bool shouldRepaint(CareFxPainter oldDelegate) => true;
}
