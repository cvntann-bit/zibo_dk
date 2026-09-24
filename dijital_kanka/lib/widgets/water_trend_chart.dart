import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/water_entry.dart';
import 'locked_feature_overlay.dart';
import 'sticker_style.dart';

enum _Granularity { daily, weekly, monthly }

class _Point {
  const _Point({required this.periodStart, required this.ml});

  final DateTime periodStart;
  final double ml;
}

DateTime _isoWeekStart(DateTime date) {
  final dayOnly = DateTime(date.year, date.month, date.day);
  return dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
}

/// **Faz 5 (D2) Pro+ Analitik Genişletmesi (2026-09-25)** — Su Takibi'nin
/// trend grafiği. `MoodTrendDetailChart`/`MoneyTrendChart` ile AYNI ortak
/// desenler: `LockedFeatureOverlay` ile bulanıklaştırma (madde 6, ortak
/// tasarım standardı), ilk mount'ta taban çizgisinden "dolma" animasyonu.
/// Granülarite `MoneyTrendChart`'ın 3'lü seçeneğiyle AYNI (Günlük/Haftalık/
/// Aylık, kullanıcı isteği: "günlük haftalık aylık gibi") — ARB etiketleri
/// (`moneyTrendGranularityDaily/Weekly/Monthly`) metin BİREBİR aynı olduğu
/// için Money ile PAYLAŞILIYOR, yeni bir kopya eklenmedi.
///
/// **Günlük mod**: son 14 günün HAM (kovalanmamış) tüketimi, gün başına bir
/// nokta. **Haftalık/Aylık mod**: `MoodTrendDetailChart`'ın kova/ortalama
/// deseniyle AYNI — ISO hafta/takvim ayına göre kovalanıp o dönemin
/// ORTALAMA günlük tüketimi çiziliyor (veri olmayan kovalar atlanıyor).
/// Grafiğin üstüne kullanıcının GÜNCEL hedefi kesikli bir referans çizgisi
/// olarak bindiriliyor.
///
/// Grafiğin altında, [entries]'in TÜMÜ üzerinden hesaplanan ortalama hedef
/// tutturma oranını gösteren küçük bir özet satırı var — kullanıcı isteği
/// "hedefe ulaşma oranını gösteren bir özet".
class WaterTrendChart extends StatefulWidget {
  const WaterTrendChart({
    super.key,
    required this.entries,
    required this.goalMl,
    required this.locked,
  });

  /// Bugün dahil TÜM geçmiş kayıtlar (tarih sırası önemsiz).
  final List<WaterEntry> entries;

  /// Kullanıcının GÜNCEL hedefi — grafikteki referans çizgisi için.
  final int goalMl;

  /// `true` → grafik ve özet bulanıklaştırılıp kilit rozeti gösterilir.
  final bool locked;

  @override
  State<WaterTrendChart> createState() => _WaterTrendChartState();
}

class _WaterTrendChartState extends State<WaterTrendChart> {
  _Granularity _granularity = _Granularity.daily;
  bool _hasAppeared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasAppeared = true);
    });
  }

  List<_Point> _placeholderPoints() {
    final today = DateTime.now();
    const sample = [1200, 1800, 1000, 2000, 1500, 1750, 2200];
    return [
      for (var i = 0; i < sample.length; i++)
        _Point(
          periodStart: today.subtract(Duration(days: sample.length - i)),
          ml: sample[i].toDouble(),
        ),
    ];
  }

  List<_Point> _points() {
    if (widget.entries.isEmpty) return [];
    final sorted = [...widget.entries]..sort((a, b) => a.date.compareTo(b.date));

    if (_granularity == _Granularity.daily) {
      const window = 14;
      final recent = sorted.length > window ? sorted.sublist(sorted.length - window) : sorted;
      return [
        for (final entry in recent)
          _Point(periodStart: entry.date, ml: entry.consumedMl.toDouble()),
      ];
    }

    final grouped = <DateTime, List<WaterEntry>>{};
    for (final entry in sorted) {
      final key = _granularity == _Granularity.weekly
          ? _isoWeekStart(entry.date)
          : DateTime(entry.date.year, entry.date.month);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    final windowSize = _granularity == _Granularity.weekly ? 8 : 6;
    final recentKeys = sortedKeys.length > windowSize
        ? sortedKeys.sublist(sortedKeys.length - windowSize)
        : sortedKeys;
    return [
      for (final key in recentKeys)
        _Point(
          periodStart: key,
          ml: grouped[key]!.map((e) => e.consumedMl).reduce((a, b) => a + b) / grouped[key]!.length,
        ),
    ];
  }

  String _pointLabel(_Point point, Locale locale) => _granularity == _Granularity.monthly
      ? monthNamesShortForLocale(locale)[point.periodStart.month - 1]
      : formatShortAxisDate(point.periodStart, locale);

  double get _averageGoalRate {
    if (widget.entries.isEmpty) return 0;
    final ratios = widget.entries.map(
      (e) => e.goalUnitCount == 0 ? 0.0 : e.unitCount / e.goalUnitCount,
    );
    return ratios.reduce((a, b) => a + b) / widget.entries.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    final realPoints = _points();
    final usePlaceholder = realPoints.isEmpty && widget.locked;
    final points = usePlaceholder ? _placeholderPoints() : realPoints;
    final goalMl = usePlaceholder ? 2000 : widget.goalMl;
    final goalRate = usePlaceholder ? 0.68 : _averageGoalRate;

    final titleText = Text(
      l10n.waterTrendTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: [FontVariation('wght', 800)],
        fontSize: 13.5,
      ),
    );

    final granularityToggle = SegmentedButton<_Granularity>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
        side: const BorderSide(color: kStickerOutline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      ),
      segments: [
        ButtonSegment(
          value: _Granularity.daily,
          label: Text(l10n.moneyTrendGranularityDaily),
        ),
        ButtonSegment(
          value: _Granularity.weekly,
          label: Text(l10n.moneyTrendGranularityWeekly),
        ),
        ButtonSegment(
          value: _Granularity.monthly,
          label: Text(l10n.moneyTrendGranularityMonthly),
        ),
      ],
      selected: {_granularity},
      onSelectionChanged: (selection) =>
          setState(() => _granularity = selection.first),
    );

    if (points.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText,
          const SizedBox(height: 8),
          granularityToggle,
          const SizedBox(height: 10),
          Text(
            l10n.waterTrendEmptyState,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final lastIndex = (points.length - 1).toDouble();
    final xInterval = lastIndex <= 4 ? 1.0 : (lastIndex / 4).ceilToDouble();
    final maxValue = [
      ...points.map((p) => p.ml),
      goalMl.toDouble(),
    ].reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxValue * 1.2;
    final yInterval = chartMaxY / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        const SizedBox(height: 8),
        granularityToggle,
        const SizedBox(height: 12),
        LockedFeatureOverlay(
          locked: widget.locked,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                child: LineChart(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  LineChartData(
                    minX: 0,
                    maxX: lastIndex <= 0 ? 1 : lastIndex,
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: goalMl.toDouble(),
                          color: colorScheme.tertiary,
                          strokeWidth: 1.5,
                          dashArray: const [6, 4],
                        ),
                      ],
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '${value.round()}',
                              style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: xInterval,
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _pointLabel(points[index], locale),
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) => touchedSpots
                            .map(
                              (spot) => LineTooltipItem(
                                l10n.waterProgressMlShort(spot.y.round()),
                                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), _hasAppeared ? points[i].ml : 0),
                        ],
                        isCurved: true,
                        color: colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _GoalRateSummary(rate: goalRate),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Ortalama hedef tutturma" özet satırı — ikon + etiket + yüzde. Ayrı bir
/// grafik DEĞİL, `MiniStatRow`/`_AnalysisStatRow` ailesindeki basit bir
/// istatistik satırı.
class _GoalRateSummary extends StatelessWidget {
  const _GoalRateSummary({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        borderWidth: 2,
        shadowOffset: const Offset(2, 2),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.waterGoalRateTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '%$percent',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 15,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
