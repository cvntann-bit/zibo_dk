import 'package:flutter/material.dart';

/// 0-10 arası bir ortalama puanı dairesel bir ilerleme halkası olarak
/// gösterir — halkanın rengi puana göre kırmızıdan (düşük) yeşile (yüksek)
/// sürekli bir skalada değişir (0-3 kırmızı tonları, 4-6 sarı/turuncu
/// tonları, 7-10 yeşil tonları civarı — kesin sınırlar değil, sürekli bir
/// geçiş). Bu renk skalası, kategori grafiğinin kendi (bkz. `StatTrendChart`)
/// sabit rengiyle BİLEREK bağımsız — biri "ne kadar iyi", diğeri "hangi
/// kategori" bilgisini taşıyor, ikisi birbirine karışmasın diye.
class CircularScoreGauge extends StatelessWidget {
  const CircularScoreGauge({super.key, required this.score, this.size = 64});

  /// 0.0-10.0 arası ortalama puan.
  final double score;
  final double size;

  static const _red = Color(0xFFE53935);
  static const _amber = Color(0xFFFFA726);
  static const _green = Color(0xFF43A047);

  Color get _ringColor {
    final clamped = score.clamp(0.0, 10.0);
    if (clamped <= 5) {
      return Color.lerp(_red, _amber, clamped / 5)!;
    }
    return Color.lerp(_amber, _green, (clamped - 5) / 5)!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score.clamp(0.0, 10.0) / 10,
              strokeWidth: size * 0.11,
              backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
