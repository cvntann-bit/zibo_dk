import 'package:flutter/material.dart';

/// "Gizlilik Politikası"/"Kullanım Koşulları" gibi henüz gerçek içeriği
/// olmayan hukuki sayfalar için paylaşılan, minimal bir yer tutucu ekran —
/// Ayarlar > Hakkında bölümündeki ilgili satırdan push edilir. Gerçek metin
/// hazır olduğunda [body] burada güncellenecek (bkz. CLAUDE.md "Ayarlar"
/// bölümü) — ayrı bir ekrana ihtiyaç yok, tek widget'ın parametreleri
/// değişecek.
class LegalPlaceholderScreen extends StatelessWidget {
  const LegalPlaceholderScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
