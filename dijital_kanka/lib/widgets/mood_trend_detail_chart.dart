import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/mood.dart';
import 'locked_feature_overlay.dart';
import 'sticker_style.dart';

enum _Granularity { week, month }

/// **Faz 5 (D2), 2026-09-24 yeniden tasarım** — Zibo Pro+'a özel, Ruh Hali
/// Takibi'nin haftalık/aylık trend grafiği. Artık GÜNLÜK ham skorları değil,
/// seçilen granülariteye göre KOVALANMIŞ (haftalık: ISO hafta başlangıcı,
/// aylık: takvim ayı) ORTALAMA ruh hali skorunu çiziyor — `MoneyTrendChart`'ın
/// kova/bucket deseniyle AYNI ruhta (yalnızca kümülatif toplam yerine
/// ortalama). Veri OLMAYAN kovalar atlanıyor (boş bir haftayı/ayı sıfır
/// gibi göstermek yanıltıcı olurdu). Son 8 haftalık/6 aylık DOLU kova
/// gösteriliyor.
///
/// **Artık Profil'de DEĞİL** — kullanıcı isteğiyle Ruh Hali Takibi'nin
/// kendi ekranına (bkz. `mood_tracking_screen.dart`, "Son 7 Gün" şeridinin
/// hemen altı) taşındı; `ProfileScreen`'in "İstatistiklerim" bölümüne hiç
/// referans vermiyor.
///
/// **Giriş animasyonu** — ilk mount'ta çizgi düz bir taban çizgisinden
/// (`minY`) gerçek değerlere doğru `LineChart`'ın kendi implicit animasyonu
/// (`duration`/`curve`) ile "dolarak" beliriyor; granülarite değiştirmek bu
/// sıfırlamayı TEKRAR TETİKLEMİYOR (iki gerçek veri seti arasında doğrudan
/// geçiş yapıyor). Bu, projedeki İLK grafik giriş animasyonu — gelecekteki
/// diğer trend grafikleri (Para, Su, Hedef, Şükran) için şablon.
///
/// **2026-09-24 — kilit deseni değişti.** Artık Pro+ olmayan kullanıcıdan
/// TAMAMEN gizlenmiyor (eski `if (isProPlus)` sarmalayıcısı KALDIRILDI, bkz.
/// `mood_tracking_screen.dart`) — bunun yerine [locked] `true` iken başlık/
/// granülarite toggle'ı NORMAL görünür kalıp yalnızca çizim alanı
/// [LockedFeatureOverlay] ile bulanıklaştırılıyor + kilit rozeti/paywall
/// yönlendirmesi bindiriliyor (kullanıcı isteği: "tüm grafikler gözüksün
/// blurlu olsun"). [locked] iken veri YOKSA (yeni kullanıcı) gerçek boş
/// durum yerine sabit bir ÖRNEK dalga bulanıklaştırılıyor — aksi halde
/// bulanıklaştıracak hiçbir şey olmazdı.
class MoodTrendDetailChart extends StatefulWidget {
  const MoodTrendDetailChart({super.key, required this.entries, required this.locked});

  final List<MoodEntry> entries;

  /// `true` → grafik bulanıklaştırılıp kilit rozeti gösterilir (Pro+ değil).
  final bool locked;

  @override
  State<MoodTrendDetailChart> createState() => _MoodTrendDetailChartState();
}

class _Bucket {
  const _Bucket({required this.periodStart, required this.average});

  final DateTime periodStart;
  final double average;
}

DateTime _isoWeekStart(DateTime date) {
  final dayOnly = DateTime(date.year, date.month, date.day);
  return dayOnly.subtract(Duration(days: dayOnly.weekday - 1));
}

class _MoodTrendDetailChartState extends State<MoodTrendDetailChart> {
  _Granularity _granularity = _Granularity.week;

  /// İlk build'den SONRA `true` olur — yalnızca İLK görünüşte düz taban
  /// çizgisinden gerçek değerlere "dolma" animasyonu tetiklensin diye
  /// (granülarite değişiminde TEKRAR sıfırlanmaz).
  bool _hasAppeared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hasAppeared = true);
    });
  }

  List<_Bucket> _buckets() {
    final grouped = <DateTime, List<MoodEntry>>{};
    for (final entry in widget.entries) {
      final key = _granularity == _Granularity.week
          ? _isoWeekStart(entry.date)
          : DateTime(entry.date.year, entry.date.month);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    final windowSize = _granularity == _Granularity.week ? 8 : 6;
    final recentKeys = sortedKeys.length > windowSize
        ? sortedKeys.sublist(sortedKeys.length - windowSize)
        : sortedKeys;
    return [
      for (final key in recentKeys)
        _Bucket(
          periodStart: key,
          average:
              grouped[key]!.map((e) => e.mood.score).reduce((a, b) => a + b) /
              grouped[key]!.length,
        ),
    ];
  }

  String _bucketLabel(_Bucket bucket, Locale locale) => _granularity == _Granularity.week
      ? formatShortAxisDate(bucket.periodStart, locale)
      : monthNamesShortForLocale(locale)[bucket.periodStart.month - 1];

  /// [widget.locked] iken ve kullanıcının GERÇEK verisi henüz yoksa (yeni
  /// kullanıcı) bulanıklaştıracak hiçbir şey olmaz — bunun yerine sabit,
  /// hoş bir örnek dalga üretilir. ASLA gerçek veri olarak sunulmuyor
  /// (yalnızca bulanık haliyle görünür).
  List<_Bucket> _placeholderBuckets() {
    final today = DateTime.now();
    const sample = [3, 4, 3, 5, 4, 4, 5, 4];
    return [
      for (var i = 0; i < sample.length; i++)
        _Bucket(
          periodStart: today.subtract(Duration(days: (sample.length - i) * 7)),
          average: sample[i].toDouble(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    final realBuckets = _buckets();
    final buckets = realBuckets.isEmpty && widget.locked
        ? _placeholderBuckets()
        : realBuckets;

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

    if (buckets.isEmpty) {
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

    final lastIndex = (buckets.length - 1).toDouble();
    final xInterval = lastIndex <= 4 ? 1.0 : (lastIndex / 4).ceilToDouble();
    const baselineY = 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Flexible(child: titleText), const SizedBox(width: 8), granularityToggle],
        ),
        const SizedBox(height: 12),
        LockedFeatureOverlay(
          locked: widget.locked,
          child: SizedBox(
            height: 180,
            child: LineChart(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              LineChartData(
                minX: 0,
                maxX: lastIndex <= 0 ? 1 : lastIndex,
                minY: baselineY,
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
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _bucketLabel(buckets[index], locale),
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
                        (m) => m.score == spot.y.round().clamp(1, 5),
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
                      for (var i = 0; i < buckets.length; i++)
                        FlSpot(i.toDouble(), _hasAppeared ? buckets[i].average : baselineY),
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
        ),
      ],
    );
  }
}
