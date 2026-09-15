import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/currencies.dart';
import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/money_entry.dart';
import 'sticker_style.dart';

const _expenseRed = Color(0xFFE53935);
const _savingGreen = Color(0xFF43A047);
const _incomeBlue = Color(0xFF1E88E5);

enum _Granularity { daily, weekly }

/// [expenses]/[savings]/[incomes], seçili [_Granularity]'ye göre (gün ya da
/// hafta) GRUPLANIP kümülatif (biriken) toplam olarak çizilir — "Mevcut
/// Durum" bölümünün amacı zaman içinde hangisinin daha baskın olduğunu
/// göstermek, o yüzden her periyodun kendi tutarı değil, o periyoda KADAR
/// birikmiş toplam çizgi üzerinde gösteriliyor. Üç kategori de AYNI zaman
/// eksenini (üç listenin birleşimi) paylaşır, böylece çizgiler
/// karşılaştırılabilir kalır. Sağ üstteki Günlük/Haftalık seçici periyodu
/// değiştirir — haftalık görünüm aynı veriyi daha az (ama her biri daha
/// geniş bir zaman aralığını temsil eden) noktaya sıkıştırır.
///
/// **2026 güncellemesi — çoklu para birimi ("basit çözüm": otomatik kur
/// çevirisi YOK, tek seferde TEK para birimi çiziliyor).** Kayıtlar artık
/// farklı para birimlerinde olabildiği için (bkz. `MoneyEntry.currencyCode`)
/// bir kümülatif toplamda FARKLI birimleri ham sayı olarak toplamak anlamsız
/// olurdu — bunun yerine widget kendi `_selectedCurrency` state'ini taşıyor
/// (granularity'yi zaten kendi yönettiği gibi), grafiği yalnızca O para
/// birimindeki kayıtlarla çiziyor. [expenses]/[savings]/[incomes] HÂLÂ TAM
/// (filtrelenmemiş) listeler olarak geçiriliyor — filtreleme `build()`
/// içinde yapılıyor, bu sayede widget kayıtlardaki BENZERSİZ para birimi
/// kümesini kendi hesaplayıp seçiciyi doldurabiliyor.
class MoneyTrendChart extends StatefulWidget {
  const MoneyTrendChart({
    super.key,
    required this.sectionTitle,
    required this.expenses,
    required this.savings,
    required this.incomes,
    required this.defaultCurrencyCode,
  });

  /// Mockup notu: "Mevcut Durum" başlığı diğer bölümlerin aksine kartın
  /// DIŞINA değil, kartın kendi üst araç çubuğuna (Günlük/Haftalık
  /// geçişiyle AYNI satıra) yerleştiriliyor — bkz. `docs/theme_new.md`.
  final String sectionTitle;
  final List<MoneyEntry> expenses;
  final List<MoneyEntry> savings;
  final List<MoneyEntry> incomes;

  /// Grafiğin BAŞLANGIÇ para birimi — kullanıcının Para ve Birikim
  /// AppBar'ından seçtiği güncel global para birimi (`CurrencyProvider.
  /// currencyCode`). Kayıtlarda bu para birimi hiç YOKSA (kullanıcı yalnızca
  /// başka bir para biriminde kayıt girmişse) grafik boş bir "veri yok"
  /// durumuna düşer — kullanıcı seçiciden mevcut bir para birimine geçebilir.
  final String defaultCurrencyCode;

  @override
  State<MoneyTrendChart> createState() => _MoneyTrendChartState();
}

class _MoneyTrendChartState extends State<MoneyTrendChart> {
  _Granularity _granularity = _Granularity.daily;
  late String _selectedCurrency = widget.defaultCurrencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    // Kayıtlardaki BENZERSİZ para birimi kodları, alfabetik — seçici bu
    // listeyi dolduruyor, birden fazla varsa gösteriliyor.
    final availableCurrencies =
        {
          for (final entry in [...widget.expenses, ...widget.savings, ...widget.incomes])
            entry.currencyCode,
        }.toList()
          ..sort();
    // Gotcha (gerçek testte yakalandı) — `_selectedCurrency` (widget'ın
    // İLK build'inde ayarlanan BAŞLANGIÇ değeri) kayıtlar EKLENMEDEN ÖNCE
    // seçilmiş olabilir ve `availableCurrencies`'te HİÇ BULUNMAYABİLİR —
    // bu durumda `DropdownButton`'a DOĞRUDAN `_selectedCurrency` vermek
    // "there should be exactly one item with [DropdownButton]'s value"
    // assertion'ını tetikliyordu (seçili değerle EŞLEŞEN hiçbir `item` yok).
    // `effectiveCurrency`, `_selectedCurrency` hâlâ GEÇERLİYSE onu korur,
    // değilse mevcut ilk para birimine düşer — kalıcı state (`_selectedCurrency`)
    // yalnızca kullanıcı GERÇEKTEN seçim yapınca değişir.
    final effectiveCurrency = availableCurrencies.contains(_selectedCurrency)
        ? _selectedCurrency
        : (availableCurrencies.isEmpty ? _selectedCurrency : availableCurrencies.first);
    final currencySymbol = currencyByCode(effectiveCurrency).symbol;

    final expenses = widget.expenses.where((e) => e.currencyCode == effectiveCurrency).toList();
    final savings = widget.savings.where((e) => e.currencyCode == effectiveCurrency).toList();
    final incomes = widget.incomes.where((e) => e.currencyCode == effectiveCurrency).toList();

    final titleText = Text(
      widget.sectionTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: [FontVariation('wght', 800)],
        fontSize: 13.5,
      ),
    );

    if (expenses.isEmpty && savings.isEmpty && incomes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText,
          const SizedBox(height: 10),
          if (availableCurrencies.length > 1) ...[
            _CurrencySelector(
              availableCurrencies: availableCurrencies,
              selected: effectiveCurrency,
              onChanged: (code) => setState(() => _selectedCurrency = code),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            l10n.moneyTrendEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final series = _buildSeries(expenses, savings, incomes, _granularity);
    final maxY = [
      ...series.expenseCumulative,
      ...series.savingCumulative,
      ...series.incomeCumulative,
    ].reduce((a, b) => a > b ? a : b);
    // Tek bir tepe noktası tam kenara yapışmasın diye küçük bir üst pay.
    final chartMaxY = maxY <= 0 ? 100.0 : maxY * 1.2;
    final yInterval = chartMaxY / 4;
    // +1: seri sıfır taban noktasıyla başlıyor (bkz. _buildSeries), o yüzden
    // nokta sayısı periyot sayısından bir fazla.
    final lastIndex = series.buckets.length.toDouble();
    final xInterval = lastIndex <= 4 ? 1.0 : (lastIndex / 4).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: titleText),
            const SizedBox(width: 8),
            SegmentedButton<_Granularity>(
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
              ],
              selected: {_granularity},
              onSelectionChanged: (selection) =>
                  setState(() => _granularity = selection.first),
            ),
          ],
        ),
        if (availableCurrencies.length > 1) ...[
          const SizedBox(height: 6),
          _CurrencySelector(
            availableCurrencies: availableCurrencies,
            selected: effectiveCurrency,
            onChanged: (code) => setState(() => _selectedCurrency = code),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: lastIndex,
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
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _formatAxisAmount(value, currencySymbol),
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
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
                      if (index <= 0 || index > series.buckets.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          formatShortAxisDate(series.buckets[index - 1], locale),
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
                          '$currencySymbol${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: spot.bar.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                _line(series.expenseCumulative, _expenseRed),
                _line(series.savingCumulative, _savingGreen),
                _line(series.incomeCumulative, _incomeBlue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(color: _expenseRed, label: l10n.moneyTrendExpenseLegend),
              _LegendDot(color: _savingGreen, label: l10n.moneyTrendSavingLegend),
              _LegendDot(color: _incomeBlue, label: l10n.moneyIncome),
            ],
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(List<double> cumulative, Color color) => LineChartBarData(
    spots: [for (var i = 0; i < cumulative.length; i++) FlSpot(i.toDouble(), cumulative[i])],
    isCurved: true,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
  );
}

String _formatAxisAmount(double value, String currencySymbol) {
  if (value >= 1000) {
    final thousands = value / 1000;
    final rounded = thousands.roundToDouble();
    final text = (thousands - rounded).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : thousands.toStringAsFixed(1);
    return '$currencySymbol${text}k';
  }
  return '$currencySymbol${value.round()}';
}

class _MoneyTrendSeries {
  const _MoneyTrendSeries({
    required this.buckets,
    required this.expenseCumulative,
    required this.savingCumulative,
    required this.incomeCumulative,
  });

  final List<DateTime> buckets;
  final List<double> expenseCumulative;
  final List<double> savingCumulative;
  final List<double> incomeCumulative;
}

/// Bir tarihi seçili periyoda göre bir "kova" başlangıcına indirger — günlük
/// modda günün kendisi, haftalık modda o haftanın Pazartesi'si (ISO haftası,
/// istikrarlı bir gruplama anahtarı için).
DateTime _bucketStart(DateTime date, _Granularity granularity) {
  final day = DateTime(date.year, date.month, date.day);
  if (granularity == _Granularity.daily) return day;
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

Map<DateTime, double> _sumByBucket(List<MoneyEntry> entries, _Granularity granularity) {
  final map = <DateTime, double>{};
  for (final entry in entries) {
    final bucket = _bucketStart(entry.date, granularity);
    map[bucket] = (map[bucket] ?? 0) + entry.amount;
  }
  return map;
}

_MoneyTrendSeries _buildSeries(
  List<MoneyEntry> expenses,
  List<MoneyEntry> savings,
  List<MoneyEntry> incomes,
  _Granularity granularity,
) {
  final expenseByBucket = _sumByBucket(expenses, granularity);
  final savingByBucket = _sumByBucket(savings, granularity);
  final incomeByBucket = _sumByBucket(incomes, granularity);
  final allBuckets = {
    ...expenseByBucket.keys,
    ...savingByBucket.keys,
    ...incomeByBucket.keys,
  }.toList()..sort();

  var runningExpense = 0.0;
  var runningSaving = 0.0;
  var runningIncome = 0.0;
  // Sıfırdan başlayan bir taban nokta ile başlar — aksi halde tek bir
  // periyot varken (ör. kullanıcı bugün ilk kaydını girdiğinde) çizgi
  // çizecek İKİNCİ bir nokta olmadığı için grafik tamamen BOŞ görünüyordu.
  final expenseCumulative = <double>[0];
  final savingCumulative = <double>[0];
  final incomeCumulative = <double>[0];
  for (final bucket in allBuckets) {
    runningExpense += expenseByBucket[bucket] ?? 0;
    runningSaving += savingByBucket[bucket] ?? 0;
    runningIncome += incomeByBucket[bucket] ?? 0;
    expenseCumulative.add(runningExpense);
    savingCumulative.add(runningSaving);
    incomeCumulative.add(runningIncome);
  }
  return _MoneyTrendSeries(
    buckets: allBuckets,
    expenseCumulative: expenseCumulative,
    savingCumulative: savingCumulative,
    incomeCumulative: incomeCumulative,
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// **2026 yeni özellik** — grafiğin hangi para biriminde çizildiğini
/// seçmek için kompakt bir açılır liste; yalnızca `[availableCurrencies]`
/// BİRDEN FAZLA öğe taşıdığında (bkz. `_MoneyTrendChartState.build`)
/// gösteriliyor — tek para birimli (yaygın) durumda hiçbir ekstra UI
/// eklenmiyor.
class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.availableCurrencies,
    required this.selected,
    required this.onChanged,
  });

  final List<String> availableCurrencies;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: Theme.of(context).textTheme.labelMedium,
      items: [
        for (final code in availableCurrencies)
          DropdownMenuItem(value: code, child: Text('${currencyByCode(code).symbol} $code')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
