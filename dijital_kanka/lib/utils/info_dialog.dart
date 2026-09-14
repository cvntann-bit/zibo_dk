import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Kısa bilgi/uyarı mesajlarını (satın alma sonucu, ödül bildirimi, hata vb.)
/// göstermek için ortak dialog. `SnackBar`'ın aksine Scaffold'un alt bar/FAB
/// alanını itmez — Ana Sayfa'daki Z butonunun geçici olarak yukarı kayıp
/// geri inmesine sebep olan davranış budur.
Future<void> showInfoDialog(BuildContext context, String message) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          key: const Key('infoDialogOkButton'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.commonOkButton),
        ),
      ],
    ),
  );
}
