import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/share_service.dart';
import 'sticker_style.dart';
import 'zibo_share_sheet.dart';

/// Bir Zibo sözünün yanına konan küçük paylaş ikonu; basılınca sözü kişisel-
/// leştirilebilir bir kart önizlemesiyle açan [ZiboShareSheet]'i bottom sheet
/// olarak gösterir.
class ShareZiboButton extends StatelessWidget {
  const ShareZiboButton({
    super.key,
    required this.message,
    this.shareService = const SharePlusService(),
  });

  final String message;

  /// Testte gerçek `share_plus` platform channel'ına dokunmadan sahte bir
  /// implementasyon enjekte edebilmek için var (bkz. [ShareService]).
  final ShareService shareService;

  void _openShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          ZiboShareSheet(message: message, shareService: shareService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StickerIconButton(
      onPressed: () => _openShareSheet(context),
      tooltip: l10n.shareButtonTooltip,
      emoji: '📤',
      size: 26,
      iconSize: 13,
      borderRadius: 8,
    );
  }
}
