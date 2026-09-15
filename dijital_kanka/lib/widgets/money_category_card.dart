import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/currencies.dart';
import '../l10n/app_localizations.dart';
import '../models/money_entry.dart';
import '../providers/money_provider.dart';
import 'sticker_style.dart';

/// Para ve Birikim sayfasındaki tek bir kategoriyi (ör. Harcamalar); adını,
/// kayıt listesini, toplamını ve yeni kayıt ekleme butonunu gösteren kart.
/// [accentColor] + [amountSign] kategoriye göre değişir — kullanıcı isteği:
/// Harcamalar kırmızı/"-", Birikimler yeşil/"+" (Gelen Para nötr/"+").
class MoneyCategoryCard extends StatelessWidget {
  const MoneyCategoryCard({
    super.key,
    required this.category,
    required this.emoji,
    required this.title,
    required this.accentColor,
    required this.amountSign,
    required this.defaultCurrencyCode,
  });

  final MoneyCategory category;
  final String emoji;
  final String title;
  final Color accentColor;
  final String amountSign;

  /// **2026 güncellemesi — eskiden `currencySymbol` idi, artık GÖRÜNTÜLEME
  /// için kullanılmıyor (her kayıt artık KENDİ para birimini taşıyor, bkz.
  /// `MoneyEntry.currencyCode`).** Yalnızca YENİ kayıt ekleme diyalogunda
  /// para birimi seçicisinin başlangıç değeri için — kullanıcının Para ve
  /// Birikim AppBar'ından seçtiği GÜNCEL global para birimi
  /// (`CurrencyProvider.currencyCode`).
  final String defaultCurrencyCode;

  Future<void> _showEntryDialog(BuildContext context, {MoneyEntry? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name);
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : null,
    );
    // Diyalog kendi para birimi seçimini tutuyor — `StatefulBuilder` ile
    // (Şükran Günlüğü düzenleme diyalogundaki gibi AYRI bir StatefulWidget'a
    // GEREK YOK, burada yalnızca TEK bir dropdown state'i var, `Gratitude
    // EditDialogContent`'in "3 controller'lı, editable" karmaşıklığı yok).
    var selectedCurrencyCode = existing?.currencyCode ?? defaultCurrencyCode;

    final result = await showDialog<(String, double, String)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submit() {
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              if (nameController.text.trim().isEmpty ||
                  amount == null ||
                  amount <= 0) {
                return;
              }
              Navigator.of(dialogContext).pop((
                nameController.text.trim(),
                amount,
                selectedCurrencyCode,
              ));
            }

            return AlertDialog(
              title: Text(existing == null ? l10n.moneyAddEntryTitle : l10n.moneyEditEntryTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.moneyEntryNameHint),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.moneyEntryAmountHint,
                            prefixText: currencyByCode(selectedCurrencyCode).symbol,
                          ),
                          onSubmitted: (_) => submit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        child: DropdownButtonFormField<String>(
                          value: selectedCurrencyCode,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l10n.moneyEntryCurrencyLabel),
                          items: [
                            for (final currency in currencies)
                              DropdownMenuItem(
                                value: currency.code,
                                child: Text(
                                  '${currency.code} ${currency.symbol}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedCurrencyCode = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: submit,
                  child: Text(
                    MaterialLocalizations.of(dialogContext).okButtonLabel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;
    if (existing == null) {
      context.read<MoneyProvider>().addEntry(
        category,
        name: result.$1,
        amount: result.$2,
        currencyCode: result.$3,
      );
    } else {
      context.read<MoneyProvider>().updateEntry(
        category,
        id: existing.id,
        name: result.$1,
        amount: result.$2,
        currencyCode: result.$3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final moneyProvider = context.watch<MoneyProvider>();
    final entries = moneyProvider.entriesFor(category);
    // **2026 güncellemesi — çoklu para birimi.** Tek bir `total` DEĞİL,
    // para birimine göre gruplanmış toplamlar (bkz. `totalsByCurrencyFor`
    // dokümantasyonu) — otomatik kur çevirisi YAPILMADAN, her para birimi
    // ALFABETİK sırayla kendi toplamıyla `' + '` ile birleştiriliyor (ör.
    // "₺500.00 + $50.00"), kullanıcının açık isteği.
    final totalsByCurrency = moneyProvider.totalsByCurrencyFor(category);
    final sortedCurrencyCodes = totalsByCurrency.keys.toList()..sort();
    final totalText = entries.isEmpty
        ? '${currencyByCode(defaultCurrencyCode).symbol}0.00'
        : sortedCurrencyCodes
              .map(
                (code) =>
                    '${currencyByCode(code).symbol}${totalsByCurrency[code]!.toStringAsFixed(2)}',
              )
              .join(' + ');

    // Dıştaki `Card` GÖRSEL OLARAK şeffaf — SADECE `widget_test.dart`'ın
    // `find.ancestor(of: find.text('💸 Harcamalar'), matching:
    // find.byType(Card))` deseni bozulmasın diye korunuyor, gerçek dolgu/
    // kontur/gölge içteki `Container`'dan geliyor (bkz. `CostumeCard`'daki
    // AYNI desen).
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: stickerDecoration(
          fill: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$emoji $title',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: [FontVariation('wght', 800)],
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Text(
                  l10n.moneyCategoryTotal(totalText),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.moneyEmptyCategory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) Container(height: 1, color: colorScheme.outlineVariant),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEntryDialog(context, existing: entries[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entries[i].name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$amountSign${currencyByCode(entries[i].currencyCode).symbol}'
                            '${entries[i].amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DeleteDot(
                            tooltip: l10n.moneyDeleteEntryTooltip,
                            onTap: () => context
                                .read<MoneyProvider>()
                                .removeEntry(category, entries[i].id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            const SizedBox(height: 6),
            DashedStickerButton(
              label: l10n.moneyAddEntryButton,
              onPressed: () => _showEntryDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir kaydı ANINDA silen küçük "✕" düğmesi — mockup'ın `.del` (bkz.
/// `docs/theme_new.md`): soluk konturlu, küçük, dikkat çekmeyen bir daire —
/// silme onay penceresi YOK (Rüya/Şükran'ın aksine, gerçek koddaki davranış
/// bu).
class _DeleteDot extends StatelessWidget {
  const _DeleteDot({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
            ),
            child: Text(
              '✕',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurfaceVariant,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
