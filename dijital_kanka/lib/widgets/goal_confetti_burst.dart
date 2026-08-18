import 'dart:math';

import 'package:flutter/material.dart';

/// Hedef Takibi'nde bir hedef tamamlanınca oynatılan TEK SEFERLİK bir
/// konfeti PATLAMASI. Mağaza > Temalar'daki ambians `ThemeParticleEffect
/// (type: confetti)`'nin AKSİNE (o sürekli tekrarlanan, yukarıdan aşağı
/// SARILAN bir "yağmur" efekti — bkz. `theme_particle_effect.dart`), bu
/// widget kendi ayrı, tek seferlik bir fizik modeli kullanıyor: parçacıklar
/// ekranın ÜST kenarına yakın birkaç noktadan RASTGELE yönlere doğru
/// "patlayıp" (gerçek bir konfeti topu/patlayıcısı gibi), sonra yerçekimiyle
/// aşağı düşerek ekrana "yağıyor".
///
/// **Fizik modeli kasıtlı olarak basit tutuldu** (gerçekçi bir parçacık
/// simülasyonu değil, görsel bir efekt): her parçacığın bir başlangıç
/// konumu (`originX`/`originY`, ekranın üst kenarına yakın) + bir patlama
/// hız vektörü (`vx`/`vy` — `vy` çoğunlukla negatif/yukarı, gerçek bir
/// patlama gibi) var. `progress` (0..1, bkz. [progress]) ile orantılı bir
/// "zaman" değişkeni üzerinden `y(t) = originY + vy·t + 0.5·g·t²` (sabit
/// yerçekimi ivmesi `g`) ile parçacık zamanla aşağı düşmeye başlıyor,
/// `x(t) = originX + vx·t` ile yatay hareket sabit hızda devam ediyor (hava
/// sürtünmesi modellenmiyor — bu ölçekte fark edilmeyecek kadar küçük bir
/// detay). Parçacıklar TAM AYNI ANDA değil, çok kısa bir "dalga" halinde
/// (bkz. `_BurstPiece.delay`) art arda ateşleniyor — gerçek bir patlamanın
/// anlık ama yine de biraz dağınık başlangıcını taklit ediyor.
class GoalConfettiBurst extends StatelessWidget {
  const GoalConfettiBurst({
    super.key,
    required this.progress,
    this.particleCount = 150,
  });

  /// Genelde tek seferlik `forward(from: 0)` ile oynatılan bir
  /// `AnimationController` (0..1) — Mağaza kartlarındaki gibi sabit bir
  /// `AlwaysStoppedAnimation` da teknik olarak çalışır (statik bir kare
  /// gösterir) ama bu widget'ın asıl kullanım amacı canlı patlama.
  final Animation<double> progress;

  /// Kullanıcı isteği: mevcut ambians konfetiden (35-60 parçacık) "belirgin
  /// şekilde" daha yoğun/kalabalık — varsayılan 150.
  final int particleCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoalConfettiPainter(progress: progress, count: particleCount),
      size: Size.infinite,
    );
  }
}

const _confettiColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF6FB5),
  Color(0xFFB388FF),
  Color(0xFFFFA94D),
];

class _BurstPiece {
  const _BurstPiece(
    this.originX,
    this.originY,
    this.vx,
    this.vy,
    this.size,
    this.rotationSpeed,
    this.rotationPhase,
    this.colorIndex,
    this.delay,
  );

  /// 0..1, ekran genişliğinin kesri.
  final double originX;

  /// Ekran yüksekliğinin kesri — hafif NEGATİF (ekranın az üstünden,
  /// "üstten geliyormuş" hissi için).
  final double originY;

  /// `progress` birimi başına yatay hareket (ekran genişliğinin kesri).
  final double vx;

  /// `progress` birimi başına dikey hareket — NEGATİF değerler yukarı
  /// doğru ilk "fırlama"yı temsil ediyor, yerçekimi zamanla bunu tersine
  /// çeviriyor.
  final double vy;

  final double size;
  final double rotationSpeed;
  final double rotationPhase;
  final int colorIndex;

  /// 0..1 — bu parçacığın patlamaya BAŞLADIĞI an (`progress`'in bir
  /// kesri). Hepsi TAM aynı anda ateşlenmiyor, ilk %15'lik dilimde art
  /// arda "dalgalanıyor" — gerçek bir patlamanın çok kısa ama fark edilir
  /// yayılma süresini taklit ediyor.
  final double delay;
}

List<_BurstPiece> _generateBurst(int count) {
  final random = Random(2026);
  // Patlama, ekranın üst kenarı boyunca birkaç ayrı noktadan (TEK bir
  // merkez yerine) "ateşleniyor" — gerçek konfeti patlayıcılarının/
  // toplarının birden fazla noktadan fışkırması gibi, daha organik/dolu
  // bir görünüm için.
  const sourceCount = 4;
  return List.generate(count, (i) {
    final sourceX = (i % sourceCount + 0.5) / sourceCount;
    final originX = (sourceX + (random.nextDouble() - 0.5) * 0.4).clamp(
      0.0,
      1.0,
    );
    final originY = -0.05 - random.nextDouble() * 0.08;
    // Yalnızca ÜST yarım daire (0..π) — patlama yukarı/yanlara doğru
    // fışkırıyor, gerçek yerçekimi zaten aşağı çekecek; bu, "rastgele
    // yönlere infilak" hissini "üstten aşağı yağma" hissiyle dengeliyor.
    final angle = random.nextDouble() * pi;
    final speed = 0.5 + random.nextDouble() * 0.6;
    final vx = cos(angle) * speed;
    final vy = -sin(angle) * speed * 0.9;
    return _BurstPiece(
      originX,
      originY,
      vx,
      vy,
      3.5 + random.nextDouble() * 3.5,
      0.4 + random.nextDouble() * 1.2,
      random.nextDouble() * 2 * pi,
      i % _confettiColors.length,
      random.nextDouble() * 0.15,
    );
  });
}

class _GoalConfettiPainter extends CustomPainter {
  _GoalConfettiPainter({required this.progress, required this.count})
    : pieces = _generateBurst(count),
      super(repaint: progress);

  final Animation<double> progress;
  final int count;
  final List<_BurstPiece> pieces;

  // Yerçekimi ivmesi — `progress` birimi² başına ekran-yüksekliği kesri.
  static const _gravity = 2.4;

  // Ekranın alt kısmında yumuşak bir solma başlangıcı/bitişi — sert bir
  // "kesilme" yerine parçacıklar ekranın dışına akıcı şekilde kayboluyor.
  static const _fadeStart = 0.85;
  static const _fadeEnd = 1.15;

  @override
  void paint(Canvas canvas, Size size) {
    final totalT = progress.value;
    final paint = Paint();
    for (final piece in pieces) {
      if (totalT < piece.delay) continue; // henüz "ateşlenmedi"
      final t = totalT - piece.delay;
      final x = piece.originX + piece.vx * t;
      if (x < -0.1 || x > 1.1) continue;
      final y = piece.originY + piece.vy * t + 0.5 * _gravity * t * t;
      if (y > _fadeEnd) continue; // ekranın altına düşüp kaybolmuş
      final alpha = y > _fadeStart
          ? (1 - (y - _fadeStart) / (_fadeEnd - _fadeStart)).clamp(0.0, 1.0)
          : 1.0;
      paint.color = _confettiColors[piece.colorIndex].withValues(
        alpha: 0.9 * alpha,
      );
      final rotation = t * 2 * pi * piece.rotationSpeed + piece.rotationPhase;
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
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
  bool shouldRepaint(covariant _GoalConfettiPainter oldDelegate) =>
      oldDelegate.count != count;
}
