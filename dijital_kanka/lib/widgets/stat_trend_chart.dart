import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bir istatistik kategorisinin son birkaç haftalık değişimini gösteren
/// KÜÇÜK, sade bir çizgi grafik — `MoneyTrendChart`'ın aksine eksen
/// etiketleri/dokunma tooltip'i YOK (kullanıcı isteği: "basit bir çizgi/bar
/// grafik"), yalnızca genel eğilimi göstermesi yeterli. [color] kategoriye
/// özel sabit bir renk (bkz. `ProfileStatCard`) — puan rengiyle (bkz.
/// `CircularScoreGauge`) BİLEREK bağımsız, iki renk sistemi birbirine
/// karışmasın diye.
class StatTrendChart extends StatelessWidget {
  const StatTrendChart({super.key, required this.values, required this.color});

  /// En eskiden en yeniye sıralı haftalık değerler (bkz. `ProfileStats`).
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    // Tüm değerler eşitse (ör. hepsi 0) fl_chart minY==maxY durumunda
    // çizgiyi düz bir çizgi olarak bile göstermeyebiliyor — yapay bir pay
    // ekleniyor.
    final span = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY) * 0.2;

    return LineChart(
      LineChartData(
        minY: minY - span,
        maxY: maxY + span,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }
}
