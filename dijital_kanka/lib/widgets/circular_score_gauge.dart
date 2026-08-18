import 'package:flutter/material.dart';

/// 0-10 arası bir ortalama puanı dairesel bir ilerleme halkası olarak
/// gösterir — halkanın rengi puana göre kırmızıdan (düşük) yeşile (yüksek)
/// sürekli bir skalada değişir (0-3 kırmızı tonları, 4-6 sarı/turuncu
/// tonları, 7-10 yeşil tonları civarı — kesin sınırlar değil, sürekli bir
/// geçiş). Bu renk skalası, kategori grafiğinin kendi (bkz. `StatTrendChart`)
/// sabit rengiyle BİLEREK bağımsız — biri "ne kadar iyi", diğeri "hangi
/// kategori" bilgisini taşıyor, ikisi birbirine karışmasın diye.
///
/// **2026 güncellemesi — dolma + sayaç animasyonu.** Kullanıcı isteği: halka
/// sıfırdan gerçek puana doğru dolsun, içindeki sayı da AYNI ANDA 0'dan
/// gerçek değere sayarak artsın, Profil sayfasına HER girişte tekrar
/// oynasın. Animasyonun kendisi burada (`initState`'te başlayan tek bir
/// `AnimationController`), "her girişte tekrar oynama" ise ÇAĞIRANIN
/// (`ProfileScreen`) sorumluluğunda — sekme her aktif olduğunda bu widget'ı
/// (ve tüm İstatistiklerim alt ağacını) değişen bir `Key` ile yeniden
/// kurdurup `initState`'in baştan çalışmasını sağlıyor (bkz.
/// `ProfileScreen`'deki `_statsReplayKey` notu).
class CircularScoreGauge extends StatefulWidget {
  const CircularScoreGauge({super.key, required this.score, this.size = 64});

  /// 0.0-10.0 arası ortalama puan.
  final double score;
  final double size;

  @override
  State<CircularScoreGauge> createState() => _CircularScoreGaugeState();
}

class _CircularScoreGaugeState extends State<CircularScoreGauge>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE53935);
  static const _amber = Color(0xFFFFA726);
  static const _green = Color(0xFF43A047);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final _animation = Tween<double>(
    begin: 0,
    end: widget.score.clamp(0.0, 10.0),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Color _ringColorFor(double score) {
    if (score <= 5) {
      return Color.lerp(_red, _amber, score / 5)!;
    }
    return Color.lerp(_amber, _green, (score - 5) / 5)!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = widget.size;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = _animation.value;
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
                  value: value / 10,
                  strokeWidth: size * 0.11,
                  backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  valueColor: AlwaysStoppedAnimation<Color>(_ringColorFor(value)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
