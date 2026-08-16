import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/favorite_quotes_provider.dart';

/// "Favori Sözler" satırının açtığı sayfa — kullanıcının Ana Sayfa'daki
/// konuşma balonundan kalp ikonuyla (bkz. `FavoriteQuoteButton`)
/// favorilediği sözlerin listesi. Her satırdaki kalp ikonuna tekrar
/// dokununca favoriden çıkarılır.
class FavoriteQuotesScreen extends StatelessWidget {
  const FavoriteQuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = context.watch<FavoriteQuotesProvider>();
    final quotes = favorites.quotes;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoriteQuotesScreenTitle)),
      body: SafeArea(
        child: quotes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.favoriteQuotesEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return Card(
                    child: ListTile(
                      title: Text(quote),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite),
                        color: colorScheme.primary,
                        tooltip: l10n.favoriteQuoteRemoveTooltip,
                        onPressed: () => favorites.toggleFavorite(quote),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
