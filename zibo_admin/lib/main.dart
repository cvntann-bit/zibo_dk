import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_auth.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yapılandırma `android/app/google-services.json`'dan (Zibo ile aynı Firebase projesi).
  await Firebase.initializeApp();
  runApp(const ZiboAdminApp());
}

class ZiboAdminApp extends StatelessWidget {
  const ZiboAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zibo Yönetici',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      home: const AuthGate(),
    );
  }
}

/// Giriş yoksa → giriş ekranı; yönetici olmayan hesap → reddedilir; yönetici → sekmeler.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const SignInScreen();
        if (!isAdminUser(user)) return SignInScreen(rejectedEmail: user.email ?? user.uid);
        return const HomeShell();
      },
    );
  }
}
