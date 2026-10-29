import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/in_app_message.dart';
import 'sticker_style.dart';

/// Yönetici panelinden gelen mesaj kartını sticker dilinde bir pencere olarak gösterir
/// (bkz. `InAppMessageProvider`). Metin panelden gelir — ARB'de yalnızca "Tamam" var.
Future<void> showInAppMessageCard(
  BuildContext context, {
  required InAppMessage message,
  required String languageCode,
}) {
  final text = message.texts[languageCode]!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      final l10n = AppLocalizations.of(dialogContext)!;
      return Dialog(
        key: const Key('inAppMessageCard'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            decoration: stickerDecoration(
              fill: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: stickerCircleDecoration(fill: colorScheme.primaryContainer),
                    child: Text(message.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    text.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.35, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('inAppMessageOkButton'),
                      style: stickerFilledButtonStyle(dialogContext, radius: 14, fontSize: 16),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.commonOkButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
