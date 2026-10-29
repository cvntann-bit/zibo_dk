import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Tek yönetici hesabı. `dijital_kanka/firestore.rules` içindeki `isAdmin()` ile
/// AYNI olmalı — asıl koruma oradadır; buradaki kontrol yalnızca arayüz kapısı.
const kAdminEmail = 'cvntann@gmail.com';

bool isAdminUser(User? user) =>
    user != null && user.emailVerified && user.email?.toLowerCase() == kAdminEmail;

class AdminAuth {
  AdminAuth._();

  static bool _initialized = false;

  /// Google hesap seçiciyi açıp Firebase'e giriş yapar. Kullanıcı vazgeçerse `null`.
  static Future<User?> signInWithGoogle() async {
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize();
      _initialized = true;
    }
    try {
      // Önbellekteki hesabı sessizce yeniden kullanmasın — her seferinde seçici açılsın.
      await signIn.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google idToken boş geldi');
      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return result.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled &&
          !(e.description ?? '').toLowerCase().contains('reauth')) {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
