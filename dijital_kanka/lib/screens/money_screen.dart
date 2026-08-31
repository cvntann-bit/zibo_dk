import 'dart:async';
import 'dart:math';

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
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/money_category_card.dart';
import '../widgets/money_trend_chart.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moneyScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_exchange),
            tooltip: l10n.moneyCurrencyTooltip,
            onPressed: () => _showCurrencyPicker(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(
          context,
          l10n,
          quote,
          equippedId,
          poseStep,
          equippedImageAsset,
          moneyProvider,
          defaultCurrencyCode,
        ),
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
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
            const SizedBox(height: 8),
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
        const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        Text(l10n.moneyTrendSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MoneyTrendChart(
              expenses: moneyProvider.entriesFor(MoneyCategory.expense),
              savings: moneyProvider.entriesFor(MoneyCategory.saving),
              incomes: moneyProvider.entriesFor(MoneyCategory.income),
              defaultCurrencyCode: defaultCurrencyCode,
            ),
          ),
        ),
      ],
    );
  }
}
