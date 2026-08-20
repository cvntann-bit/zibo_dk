import 'package:flutter/material.dart';

/// "Gizlilik Politikası"/"Kullanım Koşulları" için paylaşılan, minimal bir
/// ekran — Ayarlar > Hakkında bölümündeki ilgili satırdan push edilir,
/// gerçek metin `lib/data/legal_texts.dart`'tan geliyor (bkz. CLAUDE.md
/// "Ayarlar" bölümü — eskiden ikisi de aynı kısa yer tutucu metni
/// gösteriyordu, artık her biri kendi gerçek içeriğini alıyor).
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
      // Gerçek hukuki metinler (bkz. legal_texts.dart) yer tutucudan ÇOK
      // daha uzun — SingleChildScrollView OLMADAN taşardı (bir önceki
      // sürümde yalnızca tek satırlık bir yer tutucu metin olduğu için bu
      // hiç sorun değildi).
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
