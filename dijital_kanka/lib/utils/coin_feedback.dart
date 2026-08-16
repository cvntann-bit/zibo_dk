import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Bir harcama denemesi bakiye yetersizliğinden başarısız olduğunda ortak
/// uyarıyı gösterir. Coin harcayan her ekran/widget bunu kullanabilir.
void showInsufficientCoinsWarning(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.insufficientCoins)));
}
