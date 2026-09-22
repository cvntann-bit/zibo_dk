import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/mood.dart';
import 'sticker_style.dart';

enum _Granularity { week, month }

/// **Faz 5 (D2)** — Zibo Pro+'a özel, Ruh Hali Takibi'nin haftalık/aylık
/// detaylı trend grafiği. `MoneyTrendChart`'ın (bkz. o dosya) `fl_chart`
/// `LineChart` deseniyle AYNI iskelet (granularite `SegmentedButton`'ı,
/// `FlGridData`/`FlTitlesData`/`LineTouchData`) ama TEK çizgi (para
/// birimi seçici/kümülatif toplam YOK — ruh hali kümülatif bir miktar
/// değil, GÜNLÜK bir skor). Yalnızca `mood_tracking_screen.dart`'ın
/// mevcut "Son 7 Gün" noktalı şeridinden FARKLI, EK bir görünüm —
/// `ProfileScreen`'in "İstatistiklerim" bölümüne ekleniyor, o şeride
/// dokunulmuyor.
class MoodTrendDetailChart extends StatefulWidget {
  const MoodTrendDetailChart({super.key, required this.entries});

  final List<MoodEntry> entries;

  @override
  State<MoodTrendDetailChart> createState() => _MoodTrendDetailChartState();
}

class _MoodTrendDetailChartState extends State<MoodTrendDetailChart> {
  _Granularity _granularity = _Granularity.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    final days = _granularity == _Granularity.week ? 7 : 30;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final cutoff = todayDateOnly.subtract(Duration(days: days - 1));
    final relevant = widget.entries.where((e) => !e.date.isBefore(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final titleText = Text(
      l10n.moodTrendTitle,
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
          value: _Granularity.week,
          label: Text(l10n.moodTrendGranularityWeek),
        ),
        ButtonSegment(
          value: _Granularity.month,
          label: Text(l10n.moodTrendGranularityMonth),
        ),
      ],
      selected: {_granularity},
      onSelectionChanged: (selection) =>
          setState(() => _granularity = selection.first),
    );

    if (relevant.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Flexible(child: titleText), const SizedBox(width: 8), granularityToggle],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.moodTrendEmptyState,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final lastIndex = (relevant.length - 1).toDouble();
    final xInterval = lastIndex <= 4 ? 1.0 : (lastIndex / 4).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Flexible(child: titleText), const SizedBox(width: 8), granularityToggle],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: lastIndex <= 0 ? 1 : lastIndex,
              minY: 0.5,
              maxY: 5.5,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 1 || index > Mood.values.length) {
                        return const SizedBox.shrink();
                      }
                      final mood = Mood.values.firstWhere((m) => m.score == index);
                      return Text(mood.emoji, style: const TextStyle(fontSize: 13));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= relevant.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          formatShortAxisDate(relevant[index].date, locale),
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    final mood = Mood.values.firstWhere(
                      (m) => m.score == spot.y.round(),
                    );
                    return LineTooltipItem(
                      mood.emoji,
                      const TextStyle(fontSize: 16),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < relevant.length; i++)
                      FlSpot(i.toDouble(), relevant[i].mood.score.toDouble()),
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
      ],
    );
  }
}
