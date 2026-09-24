import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/currencies.dart';
import '../data/money_quotes.dart';
import '../l10n/app_localizations.dart';
import '../models/money_entry.dart';
import '../providers/costume_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/money_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/locked_feature_overlay.dart';
import '../widgets/money_category_card.dart';
import '../widgets/money_trend_chart.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

const _expenseRed = Color(0xFFE53935);
const _savingGreen = Color(0xFF43A047);
const _incomeBlue = Color(0xFF1E88E5);

/// Para ve Birikim sayfası. Artık bir alt gezinme sekmesi DEĞİL — Z
/// butonunun açtığı modül menüsünden diğer modüller (Rüya/Şükran/Su Takibi
/// vb.) gibi push ediliyor (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümündeki
/// Profil↔Birikim yer değiştirme notu). [isActive] bu yüzden artık
/// varsayılan olarak `true` — pushed bir rota ya tamamen monte ya da hiç
/// monte değildir, eski IndexedStack "hep monte" sorunundan etkilenmez;
/// parametre yalnızca geriye dönük uyumluluk için opsiyonel bırakıldı.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startTimer();
  }

  @override
  void didUpdateWidget(covariant MoneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _showNewQuote());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = moneyQuotesForLocale(Localizations.localeOf(context));
      if (quotes.length <= 1) {
        _quoteIndex = 0;
        return;
      }
      int next;
      do {
        next = _random.nextInt(quotes.length);
      } while (next == _quoteIndex);
      _quoteIndex = next;
    });
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final currencyProvider = context.read<CurrencyProvider>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.moneyCurrencyPickerTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (listContext, index) {
                    final currency = currencies[index];
                    final isSelected = currencyProvider.currencyCode == currency.code;
                    return ListTile(
                      leading: SizedBox(
                        width: 36,
                        child: Text(
                          currency.symbol,
                          textAlign: TextAlign.center,
                          style: Theme.of(listContext).textTheme.titleMedium,
                        ),
                      ),
                      title: Text('${currency.code} — ${currency.name}'),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(listContext).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        currencyProvider.setCurrencyCode(currency.code);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final quotes = moneyQuotesForLocale(locale);
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final quote = applyAddressTerm(
      quotes[_quoteIndex % quotes.length],
      addressTerm,
      locale,
    );

    // Mağaza > Kostümler'den giyilen bir kostüm varsa Zibo'nun görseli onunla
    // değişir; yoksa (veya kostüm listeden kaldırılmışsa) varsayılan görsele
    // düşülür (bkz. HomeScreen'deki aynı desen).
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final equippedImageAsset = equippedId == null
        ? defaultZiboImage
        : (findCostumeById(equippedId)?.imageAsset ?? defaultZiboImage);
    final poseStep = context.watch<ZiboPoseProvider>().poseStep;
    final moneyProvider = context.watch<MoneyProvider>();
    // **2026 güncellemesi — çoklu para birimi.** Artık her kayıt KENDİ para
    // birimini taşıyor (bkz. `MoneyEntry.currencyCode`) — bu, yalnızca YENİ
    // kayıt eklerken varsayılan seçim + trend grafiğinin başlangıç filtresi
    // için kullanılıyor, GÖRÜNTÜLEME artık buna bağımlı değil.
    final defaultCurrencyCode = context.watch<CurrencyProvider>().currencyCode;
    // Faz 5 (D3) — Pro+'a özel gelişmiş analiz bölümü.
    final isProPlus = context.watch<SubscriptionProvider>().isProPlus;

    return Scaffold(
      appBar: plainStickerAppBar(
        context,
        title: l10n.moneyScreenTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StickerIconButton(
              emoji: '💱',
              onPressed: () => _showCurrencyPicker(context),
              tooltip: l10n.moneyCurrencyTooltip,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              size: 34,
              iconSize: 16,
              borderRadius: null,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          SafeArea(
            child: _buildBody(
              context,
              l10n,
              quote,
              equippedId,
              poseStep,
              equippedImageAsset,
              moneyProvider,
              defaultCurrencyCode,
              isProPlus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String quote,
    String? equippedId,
    int poseStep,
    String equippedImageAsset,
    MoneyProvider moneyProvider,
    String defaultCurrencyCode,
    bool isProPlus,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Column(
          children: [
            ZiboAnimatedImage(
              imageKey: const Key('ziboMoneyImage'),
              costumeId: equippedId,
              poseStep: poseStep,
              fallbackImage: equippedImageAsset,
              height: 200,
              semanticLabel: l10n.ziboImagePlaceholder,
            ),
            const SizedBox(height: 14),
            Stack(
              clipBehavior: Clip.none,
              children: [
                SpeechBubble(message: quote),
                Positioned(
                  top: -6,
                  right: -6,
                  child: ShareZiboButton(message: quote),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        MoneyCategoryCard(
          category: MoneyCategory.expense,
          emoji: '💸',
          title: l10n.moneyExpenses,
          accentColor: _expenseRed,
          amountSign: '-',
          defaultCurrencyCode: defaultCurrencyCode,
        ),
        const SizedBox(height: 12),
        MoneyCategoryCard(
          category: MoneyCategory.saving,
          emoji: '📈',
          title: l10n.moneySavings,
          accentColor: _savingGreen,
          amountSign: '+',
          defaultCurrencyCode: defaultCurrencyCode,
        ),
        const SizedBox(height: 12),
        MoneyCategoryCard(
          category: MoneyCategory.income,
          emoji: '💰',
          title: l10n.moneyIncome,
          accentColor: _incomeBlue,
          amountSign: '+',
          defaultCurrencyCode: defaultCurrencyCode,
        ),
        const SizedBox(height: 12),
        // Mockup notu: "Mevcut Durum" başlığı diğer bölümlerin aksine
        // KARTIN DIŞINDA değil, kartın kendi üst araç çubuğunda (Günlük/
        // Haftalık geçişiyle AYNI satırda) — bkz. `MoneyTrendChart`'ın
        // `sectionTitle` parametresi.
        StickerCard(
          child: MoneyTrendChart(
            sectionTitle: l10n.moneyTrendSectionTitle,
            expenses: moneyProvider.entriesFor(MoneyCategory.expense),
            savings: moneyProvider.entriesFor(MoneyCategory.saving),
            incomes: moneyProvider.entriesFor(MoneyCategory.income),
            defaultCurrencyCode: defaultCurrencyCode,
          ),
        ),
        // Faz 5 (D3) — Zibo Pro+'a özel gelişmiş analiz. 2026-09-24
        // güncellemesi — kullanıcı isteğiyle artık HERKESE görünür; Pro+
        // olmayan yalnızca bulanıklaştırılmış + kilit rozetli bir önizleme
        // görür (bkz. `LockedFeatureOverlay`), mevcut kartların (yukarıdaki
        // üçü + trend grafiği) hiçbirine dokunulmuyor.
        const SizedBox(height: 12),
        StickerCard(
          child: _AdvancedAnalysisSection(
            moneyProvider: moneyProvider,
            currencyCode: defaultCurrencyCode,
            locked: !isProPlus,
          ),
        ),
      ],
    );
  }
}

/// **Faz 5 (D3), 2026-09-24 yeniden tasarım.** Zibo Pro+'a özel gelişmiş
/// analiz — kullanıcı isteğiyle önceki basit 3-satırlık metin özetinin
/// YERİNE: (1) her para biriminin KENDİ ayrı kartında üç kategori toplamı
/// (otomatik kur çevirisi YOK, `MoneyProvider.totalsByCurrencyFor` — mevcut
/// çoklu para birimi mimarisiyle AYNI "her birimi kendi başına göster"
/// kuralı), (2) [currencyCode] (Para ve Birikim AppBar'ından seçilen güncel
/// para birimi) için harcama kalemlerinin dağılımını gösteren bir donut
/// grafik (`MoneyProvider.expenseBreakdownByNameFor`).
///
/// **Kilit deseni** — başlık her zaman görünür; [locked] `true` iken (Pro+
/// değil) gövde (para birimi kartları + donut) [LockedFeatureOverlay] ile
/// bulanıklaştırılıp kilit rozeti bindiriliyor. Kullanıcının HİÇ verisi
/// yoksa ve kilitliyse, bulanıklaştıracak bir şey olsun diye sabit bir
/// ÖRNEK veri seti kullanılır (asla gerçek veri gibi sunulmuyor, yalnızca
/// bulanık haliyle görünür) — Pro+ kullanıcı için veri gerçekten yoksa
/// normal boş durum metni gösterilir.
class _AdvancedAnalysisSection extends StatelessWidget {
  const _AdvancedAnalysisSection({
    required this.moneyProvider,
    required this.currencyCode,
    required this.locked,
  });

  final MoneyProvider moneyProvider;
  final String currencyCode;
  final bool locked;

  static const _placeholderCurrency = 'TRY';
  static const _placeholderTotals = (expense: 1250.0, saving: 400.0, income: 3200.0);
  static const _placeholderBreakdown = {'Market': 420.0, 'Kira': 600.0, 'Faturalar': 230.0};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final realCurrencies = moneyProvider.availableCurrencies;
    final realBreakdown = moneyProvider.expenseBreakdownByNameFor(currencyCode);
    final hasRealData = realCurrencies.isNotEmpty;

    final titleText = Text(
      l10n.moneyAdvancedAnalysisTitle,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: [FontVariation('wght', 800)],
        fontSize: 13.5,
      ),
    );

    if (!hasRealData && !locked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleText,
          const SizedBox(height: 10),
          Text(
            l10n.moneyAdvancedAnalysisEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final usePlaceholder = !hasRealData && locked;
    final currencies = usePlaceholder ? const [_placeholderCurrency] : realCurrencies;
    final breakdown = usePlaceholder ? _placeholderBreakdown : realBreakdown;
    final breakdownCurrency = usePlaceholder ? _placeholderCurrency : currencyCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        const SizedBox(height: 12),
        LockedFeatureOverlay(
          locked: locked,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.moneyCurrencyTotalsTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final code in currencies) ...[
                _CurrencyTotalsCard(
                  currencyCode: code,
                  expense: usePlaceholder
                      ? _placeholderTotals.expense
                      : (moneyProvider.totalsByCurrencyFor(MoneyCategory.expense)[code] ?? 0),
                  saving: usePlaceholder
                      ? _placeholderTotals.saving
                      : (moneyProvider.totalsByCurrencyFor(MoneyCategory.saving)[code] ?? 0),
                  income: usePlaceholder
                      ? _placeholderTotals.income
                      : (moneyProvider.totalsByCurrencyFor(MoneyCategory.income)[code] ?? 0),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Text(
                l10n.moneyExpenseBreakdownTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _ExpenseDonutChart(breakdown: breakdown, currencyCode: breakdownCurrency),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tek bir para biriminin üç kategori toplamını gösteren kompakt kart —
/// `MoneyCategoryCard`'ın (ana kartlar) AKSİNE tek bir para birimiyle
/// sınırlı, yan yana/alt alta birden fazlası gösterilebilsin diye küçük.
class _CurrencyTotalsCard extends StatelessWidget {
  const _CurrencyTotalsCard({
    required this.currencyCode,
    required this.expense,
    required this.saving,
    required this.income,
  });

  final String currencyCode;
  final double expense;
  final double saving;
  final double income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final symbol = currencyByCode(currencyCode).symbol;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        borderWidth: 2,
        shadowOffset: const Offset(2, 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$currencyCode ($symbol)',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _MiniStatRow(label: l10n.moneyExpenses, value: expense, symbol: symbol, color: _expenseRed),
          _MiniStatRow(label: l10n.moneySavings, value: saving, symbol: symbol, color: _savingGreen),
          _MiniStatRow(label: l10n.moneyIncome, value: income, symbol: symbol, color: _incomeBlue),
        ],
      ),
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.symbol,
    required this.color,
  });

  final String label;
  final double value;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            '$symbol${value.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Harcama kalemlerinin (`MoneyEntry.name`) dağılımını gösteren donut grafik
/// — en büyük 4 kalem kendi dilimini alır, geri kalanı `moneyExpenseOtherLabel`
/// altında tek bir dilimde toplanır (çok sayıda küçük dilim okunaksız
/// olurdu).
class _ExpenseDonutChart extends StatelessWidget {
  const _ExpenseDonutChart({required this.breakdown, required this.currencyCode});

  final Map<String, double> breakdown;
  final String currencyCode;

  static const _sliceColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (breakdown.isEmpty) {
      return Text(
        l10n.moneyAdvancedAnalysisEmpty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    const maxSlices = 4;
    final top = sorted.take(maxSlices).toList();
    final otherTotal = sorted.skip(maxSlices).fold<double>(0, (sum, e) => sum + e.value);

    final slices = [
      for (var i = 0; i < top.length; i++)
        (name: top[i].key, value: top[i].value, color: _sliceColors[i % _sliceColors.length]),
      if (otherTotal > 0)
        (name: l10n.moneyExpenseOtherLabel, value: otherTotal, color: colorScheme.outlineVariant),
    ];
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.value,
                    color: slice.color,
                    radius: 40,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final slice in slices)
              _LegendChip(
                color: slice.color,
                label: slice.name,
                percent: (slice.value / total * 100).round(),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label, required this.percent});

  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          '$label · $percent%',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
