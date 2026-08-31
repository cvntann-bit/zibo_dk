import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/currencies.dart';
import '../l10n/app_localizations.dart';
import '../models/money_entry.dart';
import '../providers/money_provider.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$emoji $title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  l10n.moneyCategoryTotal(totalText),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
              for (final entry in entries)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showEntryDialog(context, existing: entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$amountSign${currencyByCode(entry.currencyCode).symbol}'
                            '${entry.amount.toStringAsFixed(2)}',
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: l10n.moneyDeleteEntryTooltip,
                            onPressed: () => context
                                .read<MoneyProvider>()
                                .removeEntry(category, entry.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _showEntryDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.moneyAddEntryButton),
            ),
          ],
        ),
      ),
    );
  }
}
