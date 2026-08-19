import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_link_provider.dart';
import '../services/google_auth_service.dart';
import 'auth_switch.dart';

/// Profil/Ayarlar'daki Google hesap bağlama satırının `onTap`'i — TEK
/// yerde tutulup her iki ekrandan da çağrılıyor (kod tekrarını önlemek
/// için).
///
/// **Zaten bağlıysa:** yalnızca bağlı email'i bir SnackBar'la hatırlatır,
/// başka bir şey yapmaz (unlink akışı kullanıcı isteğinde YOK).
///
/// **Bağlı değilse:** [AuthLinkProvider.linkWithGoogle] çağrılır. Bu Google
/// hesabı BAŞKA bir cihazda zaten bağlıysa (bkz.
/// [GoogleAccountAlreadyLinkedElsewhereException]), kullanıcıya "o hesaba
/// GEÇMEK ister misin?" diye soran bir onay diyaloğu açılır — "Evet"
/// derse [AuthLinkProvider.signInWithGoogle] çağrılıp dönen uid
/// `switchToUid` sinyaline verilir, bu da `main.dart`'ın `_AppRoot`'unun
/// TÜM uygulamayı o (kurtarılan) hesabın uid'iyle YENİDEN kurmasını
/// tetikler.
Future<void> handleGoogleLinkTap(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final authLink = context.read<AuthLinkProvider>();

  if (authLink.isLinked) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(authLink.linkedEmail ?? '')));
    return;
  }

  try {
    final linked = await authLink.linkWithGoogle();
    if (!context.mounted || !linked) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.googleLinkSuccessMessage)));
  } on GoogleAccountAlreadyLinkedElsewhereException {
    if (!context.mounted) return;
    await _offerSignInInstead(context, l10n, authLink);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.googleLinkFailedMessage)));
  }
}

Future<void> _offerSignInInstead(
  BuildContext context,
  AppLocalizations l10n,
  AuthLinkProvider authLink,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.googleAlreadyLinkedDialogTitle),
      content: Text(l10n.googleAlreadyLinkedDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.googleSignInInsteadButton),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final outcome = await authLink.signInWithGoogle();
    if (!context.mounted) return;
    if (outcome != null) {
      // TÜM uygulamayı (main.dart'taki _AppRoot) kurtarılan hesabın uid'i
      // ile yeniden kurdurur — bkz. utils/auth_switch.dart.
      switchToUid.value = outcome.uid;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.googleSignInSuccessMessage)));
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.googleSignInFailedMessage)));
  }
}
