import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/custom_messages_screen.dart';

/// Ana Sayfa'daki konuşma balonunun köşesinde duran, [ShareZiboButton]/
/// [FavoriteQuoteButton] ile AYNI görsel dilde (`IconButton.filled`, 36x36)
/// küçük bir ikon — basılınca kullanıcının kendi özel mesajlarını
/// yönettiği [CustomMessagesScreen]'i açar.
class CustomMessagesButton extends StatelessWidget {
  const CustomMessagesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filled(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CustomMessagesScreen()),
      ),
      tooltip: l10n.customMessagesButtonTooltip,
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
