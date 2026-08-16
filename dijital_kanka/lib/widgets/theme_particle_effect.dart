import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/app_theme_option.dart';

/// [type]'a göre hafif, düşük parçacık sayılı bir dekoratif animasyon çizer
/// (kar/galaksi yıldızları/konfeti/kalp/nota/yaprak/çiçek yaprağı). Hem tam
/// ekran "canlı" kaplamada (bkz.
/// `AnimatedThemeOverlay`, [progress] gerçek bir sürekli-dönen
/// `AnimationController`) HEM DE Mağaza kartındaki küçük, HAREKETSİZ
/// önizlemede (bkz. `ThemeOptionCard`, [progress] sabit bir
/// `AlwaysStoppedAnimation`) AYNI çizim kodu kullanılıyor — `Animation`
/// arayüzünü ikisi de karşıladığı için `CustomPainter(repaint:
/// progress)` otomatik olarak doğru davranıyor: canlı kullanımda her
/// tık'ta yeniden çiziyor, statik önizlemede HİÇ (çünkü `AlwaysStoppedAnimation`
/// asla `notifyListeners` tetiklemiyor) — önizleme kartları için sıfır
/// ekstra animasyon maliyeti.
///
/// Parçacık pozisyonları/hızları SABİT bir tohumla (`Random(seed)`)
/// üretiliyor (bkz. `StarryGradientBackground`'daki aynı gerekçe) — her
/// `build()`'de birebir aynı dizilim, ayrı bir state/cache katmanı
/// gerekmiyor, "zıplama" riski yok.
class ThemeParticleEffect extends StatelessWidget {
  const ThemeParticleEffect({
    super.key,
    required this.type,
    required this.progress,
    required this.isDark,
    this.particleCount,
  });

  final ThemeAnimationType type;

  /// Canlı kaplamada bir `AnimationController` (sürekli `repeat()`), Mağaza
  /// kartı önizlemesinde `const AlwaysStoppedAnimation(0.35)` gibi SABİT bir
  /// değer.
  final Animation<double> progress;
  final bool isDark;

  /// `null` ise türe göre makul bir varsayılan kullanılır (bkz. altta) —
  /// tam ekran kaplamada telefon donanımını zorlamayacak kadar düşük,
  /// küçük kart önizlemesinde daha da az.
  final int? particleCount;

  @override
  Widget build(BuildContext context) {
    if (type == ThemeAnimationType.none) return const SizedBox.shrink();
    final CustomPainter painter = switch (type) {
      ThemeAnimationType.snow => _SnowPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 45,
      ),
      ThemeAnimationType.galaxy => _GalaxyPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 40,
      ),
      ThemeAnimationType.confetti => _ConfettiPainter(
        progress: progress,
        count: particleCount ?? 35,
      ),
      ThemeAnimationType.hearts => _HeartsPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 28,
      ),
      ThemeAnimationType.notes => _NotesPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 26,
      ),
      ThemeAnimationType.tropical => _LeavesPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 22,
      ),
      ThemeAnimationType.petals => _PetalsPainter(
        progress: progress,
        isDark: isDark,
        count: particleCount ?? 32,
      ),
      ThemeAnimationType.none => throw StateError('unreachable'),
    };
    return CustomPaint(painter: painter, size: Size.infinite);
  }
}

// ---- Kar (Kış Teması) ----

class _Snowflake {
  const _Snowflake(
    this.x,
    this.startY,
    this.speed,
    this.radius,
    this.swayAmplitude,
    this.swayPhase,
    this.opacity,
  );

  final double x;
  final double startY;
  final double speed;
  final double radius;
  final double swayAmplitude;
  final double swayPhase;
  final double opacity;
}

List<_Snowflake> _generateSnowflakes(int count) {
  final random = Random(7);
  return List.generate(
    count,
    (_) => _Snowflake(
      random.nextDouble(),
      random.nextDouble(),
      0.5 + random.nextDouble() * 0.8,
      1.2 + random.nextDouble() * 2.2,
      0.015 + random.nextDouble() * 0.025,
      random.nextDouble() * 2 * pi,
      0.35 + random.nextDouble() * 0.5,
    ),
  );
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({required this.progress, required this.isDark, required this.count})
    : flakes = _generateSnowflakes(count),
      super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_Snowflake> flakes;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    // Koyu modda saf beyaz; açık modun soluk buz-mavisi gradyanında beyaz
    // düşük kontrastlı kalacağı için (bkz. StarryGradientBackground'ın AYNI
    // gerekçeyle yalnızca koyu modda gösterilmesi), açık modda daha koyu,
    // mat bir denim mavisi kullanılıyor.
    final color = isDark ? Colors.white : const Color(0xFF6D93B8);
    final paint = Paint()..color = color;
    for (final flake in flakes) {
      final y = (flake.startY + t * flake.speed) % 1.0;
      final sway =
          sin(t * 2 * pi * flake.speed + flake.swayPhase) * flake.swayAmplitude;
      final x = (flake.x + sway) % 1.0;
      paint.color = color.withValues(alpha: flake.opacity);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        flake.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

// ---- Galaksi (twinkle eden yıldızlar) ----

class _GalaxyStar {
  const _GalaxyStar(
    this.x,
    this.y,
    this.radius,
    this.baseOpacity,
    this.twinkleSpeed,
    this.twinklePhase,
  );

  final double x;
  final double y;
  final double radius;
  final double baseOpacity;
  final double twinkleSpeed;
  final double twinklePhase;
}

List<_GalaxyStar> _generateGalaxyStars(int count) {
  final random = Random(13);
  return List.generate(
    count,
    (_) => _GalaxyStar(
      random.nextDouble(),
      random.nextDouble(),
      0.8 + random.nextDouble() * 1.6,
      0.35 + random.nextDouble() * 0.45,
      0.6 + random.nextDouble() * 1.4,
      random.nextDouble() * 2 * pi,
    ),
  );
}

/// Kayan yıldız — sabit bir başlangıç noktasından çapraz bir yönde kısa bir
/// süreliğine "kayıyor" (bkz. altta `_GalaxyPainter.paint`'teki periyot/aktif
/// pencere mantığı), sonra tekrar görünmez oluyor ve döngü boyunca kendi
/// periyoduyla tekrarlanıyor — sürekli görünen twinkle yıldızlarından FARKLI
/// olarak yalnızca ARA SIRA (döngünün küçük bir diliminde) beliriyor, gerçek
/// bir kayan yıldız gözlemi gibi.
class _ShootingStar {
  const _ShootingStar(
    this.startX,
    this.startY,
    this.angle,
    this.length,
    this.period,
    this.phase,
    this.activeFraction,
  );

  final double startX;
  final double startY;

  /// Kayma yönü (radyan) — aşağı-sağa doğru çapraz bir aralıkta.
  final double angle;

  /// Toplam kayma mesafesi, ekran köşegeninin bir kesri olarak.
  final double length;

  /// Bu yıldızın kendi döngü uzunluğu (0-1, tam animasyon döngüsünün
  /// kesri) — periyot bitince baştan başlar.
  final double period;

  /// Döngü içindeki başlangıç kayması (yıldızlar arası eş zamanlı
  /// belirmeyi önlemek için, her biri farklı bir anda "kayıyor").
  final double phase;

  /// `period`'un ne kadarlık bir kısmında yıldız GERÇEKTEN hareket
  /// halinde/görünür olduğu — geri kalanında tamamen görünmez.
  final double activeFraction;
}

List<_ShootingStar> _generateShootingStars(int count) {
  final random = Random(77);
  return List.generate(
    count,
    (_) => _ShootingStar(
      random.nextDouble(),
      random.nextDouble() * 0.5,
      // Aşağı-sağa doğru çapraz bir yön (yaklaşık 20°-55°) — kayan
      // yıldızların tipik, tanıdık gökyüzü görünümü.
      (20 + random.nextDouble() * 35) * pi / 180,
      0.28 + random.nextDouble() * 0.18,
      0.22 + random.nextDouble() * 0.2,
      random.nextDouble(),
      0.06 + random.nextDouble() * 0.04,
    ),
  );
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({
    required this.progress,
    required this.isDark,
    required this.count,
  }) : stars = _generateGalaxyStars(count),
       // Kayan yıldız sayısı bilerek `count`'tan (twinkle yıldız sayısı)
       // BAĞIMSIZ, sabit ve küçük tutuldu (3) — bu bir "ana efekt" değil,
       // ara sıra beliren bir tamamlayıcı detay; Mağaza kartı önizlemesinde
       // de (daha az twinkle yıldızıyla) aynı sayıda kayan yıldız kullanılır.
       shootingStars = _generateShootingStars(3),
       super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_GalaxyStar> stars;
  final List<_ShootingStar> shootingStars;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    // Koyu modda saf beyaz; açık modun pembe/mor gökada gradyanı üzerinde
    // hafif altımsı-krem bir ton daha iyi ayırt ediliyor.
    final color = isDark ? Colors.white : const Color(0xFFFFF3C4);
    final paint = Paint()..color = color;
    for (final star in stars) {
      final twinkle =
          0.5 + 0.5 * sin(t * 2 * pi * star.twinkleSpeed + star.twinklePhase);
      final opacity = (star.baseOpacity * (0.4 + 0.6 * twinkle)).clamp(
        0.0,
        1.0,
      );
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }

    for (final star in shootingStars) {
      final cyclePosition = (t + star.phase) % star.period;
      final activeWindow = star.period * star.activeFraction;
      if (cyclePosition > activeWindow) continue; // bu döngüde henüz sırası gelmedi
      final travel = cyclePosition / activeWindow; // 0..1, kayma ilerlemesi
      final diagonal = sqrt(
        size.width * size.width + size.height * size.height,
      );
      final dx = cos(star.angle);
      final dy = sin(star.angle);
      final headX = star.startX * size.width + dx * star.length * diagonal * travel;
      final headY = star.startY * size.height + dy * star.length * diagonal * travel;
      final tailX = headX - dx * star.length * diagonal * 0.35;
      final tailY = headY - dy * star.length * diagonal * 0.35;
      // Kısa bir belirip-kaybolma (fade in/out) — hem başlangıçta hem
      // bitişte ani bir "flaş" olmasın diye.
      final fade = sin(travel * pi).clamp(0.0, 1.0);
      final headOffset = Offset(headX, headY);
      final tailOffset = Offset(tailX, tailY);
      final trailPaint = Paint()
        ..shader = ui.Gradient.linear(tailOffset, headOffset, [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.85 * fade),
        ])
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tailOffset, headOffset, trailPaint);
      canvas.drawCircle(
        headOffset,
        1.7,
        Paint()..color = color.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

// ---- Parti konfetisi ----

const _confettiColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF6FB5),
  Color(0xFFB388FF),
];

class _ConfettiPiece {
  const _ConfettiPiece(
    this.x,
    this.startY,
    this.speed,
    this.size,
    this.rotationSpeed,
    this.rotationPhase,
    this.colorIndex,
  );

  final double x;
  final double startY;
  final double speed;
  final double size;
  final double rotationSpeed;
  final double rotationPhase;
  final int colorIndex;
}

List<_ConfettiPiece> _generateConfetti(int count) {
  final random = Random(21);
  return List.generate(
    count,
    (i) => _ConfettiPiece(
      random.nextDouble(),
      random.nextDouble(),
      0.4 + random.nextDouble() * 0.6,
      3.5 + random.nextDouble() * 3,
      0.3 + random.nextDouble() * 0.9,
      random.nextDouble() * 2 * pi,
      i % _confettiColors.length,
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.count})
    : pieces = _generateConfetti(count),
      super(repaint: progress);

  final Animation<double> progress;
  final int count;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    for (final piece in pieces) {
      final y = (piece.startY + t * piece.speed) % 1.0;
      paint.color = _confettiColors[piece.colorIndex].withValues(alpha: 0.85);
      final center = Offset(piece.x * size.width, y * size.height);
      final rotation = t * 2 * pi * piece.rotationSpeed + piece.rotationPhase;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.count != count;
}

// ---- Kalpler (Kalpli Tema) — snow ile AYNI dalgalı hareket, TERS yönde
// (yukarı süzülüyor) ----

class _FloatingShape {
  const _FloatingShape(
    this.x,
    this.startY,
    this.speed,
    this.size,
    this.swayAmplitude,
    this.swayPhase,
    this.opacity,
    this.rotationSpeed,
    this.rotationPhase,
  );

  final double x;
  final double startY;
  final double speed;
  final double size;
  final double swayAmplitude;
  final double swayPhase;
  final double opacity;
  final double rotationSpeed;
  final double rotationPhase;
}

List<_FloatingShape> _generateFloatingShapes(int count, int seed) {
  final random = Random(seed);
  return List.generate(
    count,
    (_) => _FloatingShape(
      random.nextDouble(),
      random.nextDouble(),
      0.4 + random.nextDouble() * 0.7,
      8 + random.nextDouble() * 10,
      0.02 + random.nextDouble() * 0.03,
      random.nextDouble() * 2 * pi,
      0.35 + random.nextDouble() * 0.5,
      0.2 + random.nextDouble() * 0.5,
      random.nextDouble() * 2 * pi,
    ),
  );
}

/// Gerçek, tanınabilir bir kalp silueti (♥) — iki YUVARLAK üst lob + alt
/// SİVRİ uç, "iki daire + üçgen" görsel etkisini veren klasik parametrik
/// kalp eğrisiyle (`x = 16·sin³t`, `y = 13·cos t − 5·cos 2t − 2·cos 3t −
/// cos 4t`, `t ∈ [0, 2π]`) üretiliyor. **2026 güncellemesi — eski elle
/// ayarlanmış 4 kübik Bezier'lik yaklaşım gerçek bir kalbe benzemiyordu**
/// (kullanıcı bildirdi: "düzgün görünmüyor") — yerine, hiç elle
/// koordinat tahmin etmeden HER ZAMAN doğru orantılı bir kalp üreten bu
/// matematiksel formüle geçildi. Eğri 48 noktayla örneklenip kendi sınırlayıcı
/// kutusuna göre [-1, 1] aralığına normalize ediliyor (modül yüklenirken BİR
/// KEZ, `_buildUnitHeartPath()` ile) — `_HeartsPainter` her parçacık için bu
/// SABİT birim path'i `canvas.scale(size/2)` ile ölçekleyip çiziyor, 28
/// parçacık × her karede yeniden path inşa etmek yerine (performans).
final Path _unitHeartPath = _buildUnitHeartPath();

Path _buildUnitHeartPath() {
  const steps = 48;
  final points = <Offset>[];
  var minX = double.infinity, maxX = -double.infinity;
  var minY = double.infinity, maxY = -double.infinity;
  for (var i = 0; i <= steps; i++) {
    final t = (i / steps) * 2 * pi;
    final x = 16 * pow(sin(t), 3).toDouble();
    // Negatif işaret: matematiksel eğrinin y-yukarı düzlemindeki sivri ucu
    // (en negatif y) Flutter'ın y-aşağı tuvalinde ALTA (pozitif y) düşsün
    // diye — aksi halde kalp baş aşağı görünürdü.
    final y =
        -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t));
    points.add(Offset(x, y));
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
  final width = maxX - minX;
  final height = maxY - minY;
  final scale = 2.0 / (width > height ? width : height);
  final cx = (minX + maxX) / 2;
  final cy = (minY + maxY) / 2;
  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    final nx = (p.dx - cx) * scale;
    final ny = (p.dy - cy) * scale;
    if (i == 0) {
      path.moveTo(nx, ny);
    } else {
      path.lineTo(nx, ny);
    }
  }
  path.close();
  return path;
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter({required this.progress, required this.isDark, required this.count})
    : hearts = _generateFloatingShapes(count, 31),
      super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_FloatingShape> hearts;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final color = isDark ? const Color(0xFFFF9EC4) : const Color(0xFFE0447D);
    final paint = Paint()..color = color;
    for (final heart in hearts) {
      // Kar tanelerinin AKSİNE yukarı süzülüyor: `startY - t*speed`,
      // negatif değerleri 0..1 aralığına saracak şekilde `% 1.0` uygulanıyor.
      final y = (heart.startY - t * heart.speed) % 1.0;
      final wrappedY = y < 0 ? y + 1.0 : y;
      final sway =
          sin(t * 2 * pi * heart.speed + heart.swayPhase) * heart.swayAmplitude;
      final x = (heart.x + sway) % 1.0;
      paint.color = color.withValues(alpha: heart.opacity);
      canvas.save();
      canvas.translate(x * size.width, wrappedY * size.height);
      canvas.rotate(
        sin(t * 2 * pi * heart.rotationSpeed + heart.rotationPhase) * 0.3,
      );
      // Birim kalp path'i [-1, 1] aralığında — `size/2` ile ölçeklemek
      // nihai genişliği/yüksekliği `heart.size`'a eşitliyor.
      canvas.scale(heart.size / 2);
      canvas.drawPath(_unitHeartPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

// ---- Müzik notaları (Nota Teması) — yukarı süzülen kafa+sap+bayrak ----

class _NotesPainter extends CustomPainter {
  _NotesPainter({required this.progress, required this.isDark, required this.count})
    : notes = _generateFloatingShapes(count, 44),
      super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_FloatingShape> notes;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final color = isDark ? Colors.white : const Color(0xFF6B4FB5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final note in notes) {
      final y = (note.startY - t * note.speed) % 1.0;
      final wrappedY = y < 0 ? y + 1.0 : y;
      final sway =
          sin(t * 2 * pi * note.speed + note.swayPhase) * note.swayAmplitude;
      final x = (note.x + sway) % 1.0;
      final alpha = note.opacity;
      paint.color = color.withValues(alpha: alpha);
      strokePaint.color = color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x * size.width, wrappedY * size.height);
      canvas.rotate(-0.35); // notaların tipik hafif eğik duruşu
      final headRadius = note.size * 0.32;
      final stemHeight = note.size * 1.6;
      // Nota kafası (hafif oval).
      canvas.save();
      canvas.scale(1.15, 0.85);
      canvas.drawCircle(Offset.zero, headRadius, paint);
      canvas.restore();
      // Sap.
      final stemX = headRadius * 0.9;
      canvas.drawLine(
        Offset(stemX, 0),
        Offset(stemX, -stemHeight),
        strokePaint,
      );
      // Bayrak (küçük eğri).
      final flag = Path()
        ..moveTo(stemX, -stemHeight)
        ..quadraticBezierTo(
          stemX + note.size * 0.6,
          -stemHeight + note.size * 0.2,
          stemX + note.size * 0.4,
          -stemHeight + note.size * 0.7,
        );
      canvas.drawPath(flag, strokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NotesPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

// ---- Yapraklar (Tropikal Tema) — konfetiyle AYNI düşme+dönme, yaprak
// formunda ----

class _LeavesPainter extends CustomPainter {
  _LeavesPainter({required this.progress, required this.isDark, required this.count})
    : leaves = _generateFloatingShapes(count, 58),
      super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_FloatingShape> leaves;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final color = isDark ? const Color(0xFF8FE0B0) : const Color(0xFF2E7D4F);
    final veinColor = isDark
        ? const Color(0xFF071A0F)
        : const Color(0xFFFFF5E0);
    final paint = Paint();
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final leaf in leaves) {
      final y = (leaf.startY + t * leaf.speed) % 1.0;
      final sway =
          sin(t * 2 * pi * leaf.speed + leaf.swayPhase) * leaf.swayAmplitude;
      final x = (leaf.x + sway) % 1.0;
      final rotation = t * 2 * pi * leaf.rotationSpeed + leaf.rotationPhase;
      paint.color = color.withValues(alpha: leaf.opacity);
      veinPaint.color = veinColor.withValues(alpha: leaf.opacity * 0.6);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: leaf.size * 1.8,
        height: leaf.size * 0.75,
      );
      canvas.drawOval(rect, paint);
      canvas.drawLine(
        Offset(-leaf.size * 0.85, 0),
        Offset(leaf.size * 0.85, 0),
        veinPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

// ---- Çiçek yaprakları/petaller (Çiçekli Tema) — konfetiyle AYNI düşme+
// dönme, oval petal formunda ----

class _PetalsPainter extends CustomPainter {
  _PetalsPainter({required this.progress, required this.isDark, required this.count})
    : petals = _generateFloatingShapes(count, 67),
      super(repaint: progress);

  final Animation<double> progress;
  final bool isDark;
  final int count;
  final List<_FloatingShape> petals;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final petalColor = isDark
        ? const Color(0xFFFF9EC4)
        : const Color(0xFFD1477A);
    // Merkez, gerçek çiçeklerin polen/çekirdek kısmı gibi sarımsı-altın —
    // beş yapraktan görsel olarak ayrılıp şeklin "çiçek" olarak okunmasını
    // güçlendiriyor (bkz. altta `_drawFlower`).
    final centerColor = isDark
        ? const Color(0xFFFFE29A)
        : const Color(0xFFF2A93B);
    final petalPaint = Paint();
    final centerPaint = Paint();
    for (final petal in petals) {
      final y = (petal.startY + t * petal.speed) % 1.0;
      final sway =
          sin(t * 2 * pi * petal.speed + petal.swayPhase) * petal.swayAmplitude;
      final x = (petal.x + sway) % 1.0;
      final rotation = t * 2 * pi * petal.rotationSpeed + petal.rotationPhase;
      petalPaint.color = petalColor.withValues(alpha: petal.opacity);
      centerPaint.color = centerColor.withValues(alpha: petal.opacity);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rotation);
      _drawFlower(canvas, petal.size, petalPaint, centerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalsPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.count != count;
}

/// Düzgün, simetrik BEŞ yapraklı bir çiçek — kullanıcının "birkaç yapraklı,
/// simetrik bir çiçek/petal formu" isteği doğrultusunda TEK bir oval/dikdörtgen
/// (eski tasarım) yerine gerçekten "çiçek" olarak okunan bir siluet. Her
/// yaprak, merkezden dışa doğru uzanan bir oval; beşi eşit açıyla (360°/5)
/// döndürülerek yerleştiriliyor, ortaya küçük bir "polen" dairesi ekleniyor.
void _drawFlower(
  Canvas canvas,
  double size,
  Paint petalPaint,
  Paint centerPaint,
) {
  const petalCount = 5;
  final petalLength = size * 0.55;
  final petalWidth = size * 0.34;
  for (var i = 0; i < petalCount; i++) {
    canvas.save();
    canvas.rotate((2 * pi / petalCount) * i);
    // Yaprağı merkezden DIŞA doğru kaydır — döndürüldükten sonra her biri
    // kendi açısında dışarı bakan bir oval oluşturur.
    canvas.translate(0, -petalLength * 0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: petalWidth,
        height: petalLength,
      ),
      petalPaint,
    );
    canvas.restore();
  }
  canvas.drawCircle(Offset.zero, size * 0.16, centerPaint);
}
