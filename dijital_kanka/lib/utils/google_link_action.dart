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

/// Ayarlar'daki "Hesap Değiştir" butonunun `onPressed`'i — mevcut oturumu
/// (Google'a bağlı olsun ya da olmasın) doğrudan
/// [AuthLinkProvider.signInWithGoogle]'a devrederek Google'ın hesap
/// seçicisini AÇAR (bkz. `GoogleAuthService._authenticate`'in artık
/// `authenticate()`'ten ÖNCE eklentinin kendi önbelleğini temizlemesi —
/// bu yüzden seçici HER ZAMAN taze görünür, önceki hesabı sessizce
/// yeniden KULLANMAZ). Seçilen hesap DAHA ÖNCE hiç kullanılmadıysa
/// `signInWithCredential` otomatik olarak yeni/boş bir Firebase kullanıcısı
/// oluşturur; DAHA ÖNCE kullanılmışsa o hesabın kayıtlı verilerine döner —
/// [GoogleAuthService.signIn]'in KENDİ davranışı, burada AYRICA bir dallanma
/// GEREKMEDİ.
Future<void> handleSwitchAccountTap(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final authLink = context.read<AuthLinkProvider>();

  try {
    final outcome = await authLink.signInWithGoogle();
    if (!context.mounted) return;
    if (outcome != null) {
      // TÜM uygulamayı (main.dart'taki _AppRoot) seçilen hesabın uid'i ile
      // yeniden kurdurur — bkz. utils/auth_switch.dart.
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

/// Ayarlar'daki "Çıkış Yap" butonunun `onPressed`'i — onay diyaloğu
/// (kullanıcı isteği: zorunlu bir onay adımı) sonrası
/// [AuthLinkProvider.signOut]'u çağırıp dönen TAZE anonim uid'i
/// `switchToUid`'e verir. Bu, TÜM uygulamanın (main.dart'taki `_AppRoot`)
/// taze/boş bir başlangıç durumuyla yeniden kurulmasını tetikler —
/// başarı SnackBar'ı BİLEREK YOK, çünkü bu yeniden kurulum eski widget
/// ağacını (dolayısıyla her SnackBar'ı) anında söküyor; kullanıcı zaten
/// Onboarding'in yeniden görünmesiyle "çıkış yapıldığını" net şekilde
/// anlıyor.
Future<void> handleSignOutTap(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final authLink = context.read<AuthLinkProvider>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.googleSignOutConfirmTitle),
      content: Text(l10n.googleSignOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.googleSignOutButton),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final newUid = await authLink.signOut();
    if (!context.mounted) return;
    if (newUid != null) {
      switchToUid.value = newUid;
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.googleSignOutFailedMessage)));
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.googleSignOutFailedMessage)));
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
