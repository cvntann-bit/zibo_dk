import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/favorite_quotes_provider.dart';
import 'sticker_style.dart';

/// Bir Zibo sözünün yanına konan küçük kalp ikonu; [ShareZiboButton] ile
/// aynı görsel dilde ([IconButton.filled], 36x36) ama zıt köşede duruyor.
/// Basılınca sözü [FavoriteQuotesProvider]'a ekler/çıkarır — favorilenen
/// sözler Profil sayfasında listelenir (bkz. CLAUDE.md "Profil" bölümü).
class FavoriteQuoteButton extends StatelessWidget {
  const FavoriteQuoteButton({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = context.watch<FavoriteQuotesProvider>();
    final isFavorite = favorites.isFavorite(message);

    return StickerIconButton(
      onPressed: () => favorites.toggleFavorite(message),
      tooltip: isFavorite
          ? l10n.favoriteQuoteRemoveTooltip
          : l10n.favoriteQuoteAddTooltip,
      emoji: isFavorite ? '⭐' : '☆',
      size: 26,
      iconSize: 13,
      borderRadius: 8,
    );
  }
}
