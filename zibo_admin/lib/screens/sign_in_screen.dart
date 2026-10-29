import 'package:flutter/material.dart';

import '../admin_auth.dart';
import '../theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.rejectedEmail});

  /// Yönetici olmayan bir hesapla giriş yapıldıysa o hesap — ekranda uyarı gösterilir.
  final String? rejectedEmail;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AdminAuth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = widget.rejectedEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Zibo Yönetici')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: stickerDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔐', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                const Text(
                  'Yalnızca yönetici hesabı girebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (rejected != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$rejected yönetici değil.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kBad, fontWeight: FontWeight.w700),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kBad)),
                ],
                const SizedBox(height: 20),
                if (rejected != null)
                  OutlinedButton(onPressed: AdminAuth.signOut, child: const Text('Çıkış yap'))
                else
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: Text(_busy ? 'Bekle…' : 'Google ile giriş'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
