import 'package:flutter/material.dart';

import 'sticker_style.dart';

/// 0-10 arası bir ortalama puanı dairesel bir ilerleme halkası olarak
/// gösterir. **2026-09-15 tek-vurgu güncellemesi** (bkz. `docs/theme_new.md`
/// "Onaylanan: Profil sekmesi") — halka eskiden puana göre kırmızıdan
/// yeşile değişen bir skalaydı, artık HER puanda aynı altın
/// (`colorScheme.primary`); "ne kadar iyi" bilgisi artık dolgu YÜZDESİYLE
/// taşınıyor, renkle değil.
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final strokeWidth = size * 0.11;
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
                  strokeWidth: strokeWidth,
                  backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Mockup'ın `.gauge::after` katmanı — halkanın deliğine, gerisi
              // gibi 2px sabit kontur çizen küçük bir "sticker rozet" hissi.
              Container(
                width: size - strokeWidth * 2,
                height: size - strokeWidth * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerLowest,
                  border: Border.all(color: kStickerOutline, width: 2),
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
