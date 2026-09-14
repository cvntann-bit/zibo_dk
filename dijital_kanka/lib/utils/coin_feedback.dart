import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'info_dialog.dart';

/// Bir harcama denemesi bakiye yetersizliğinden başarısız olduğunda ortak
/// uyarıyı gösterir. Coin harcayan her ekran/widget bunu kullanabilir.
void showInsufficientCoinsWarning(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showInfoDialog(context, l10n.insufficientCoins);
}
