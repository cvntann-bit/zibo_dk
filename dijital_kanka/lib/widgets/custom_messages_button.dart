import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/custom_messages_screen.dart';
import 'sticker_style.dart';

/// Ana Sayfa'daki konuşma balonunun köşesinde duran, [ShareZiboButton]/
/// [FavoriteQuoteButton] ile AYNI görsel dilde (`IconButton.filled`, 36x36)
/// küçük bir ikon — basılınca kullanıcının kendi özel mesajlarını
/// yönettiği [CustomMessagesScreen]'i açar.
class CustomMessagesButton extends StatelessWidget {
  const CustomMessagesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StickerIconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CustomMessagesScreen()),
      ),
      tooltip: l10n.customMessagesButtonTooltip,
      emoji: '✏️',
      size: 26,
      iconSize: 14,
      borderRadius: 8,
    );
  }
}
