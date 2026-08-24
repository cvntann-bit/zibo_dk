import 'package:flutter/material.dart';

/// Dil kodunun görünen adı (autonym) — bir dilin kendi adı ne UI dilinden
/// bağımsızdır, bu yüzden ARB'ye taşınmadı (İngilizce arayüzde bile
/// "Türkçe" hep "Türkçe" görünmeli, "Turkish" değil).
String languageAutonym(String code) => switch (code) {
  'en' => 'English',
  'es' => 'Español',
  _ => 'Türkçe',
};

String languageFlagEmoji(String code) => switch (code) {
  'en' => '🇬🇧',
  'es' => '🇪🇸',
  _ => '🇹🇷',
};

/// Bir dil koduna karşılık gelen küçük, YUVARLAK bayrak rozeti — bayrak
/// emoji glifleri doğası gereği dikdörtgen olduğu için `ClipOval` ile
/// yuvarlatılıyor. Hem Ayarlar'daki dil seçici hem Onboarding'in ilk açılış
/// dil seçim ekranı tarafından paylaşılıyor.
class LanguageFlagCircle extends StatelessWidget {
  const LanguageFlagCircle({super.key, required this.languageCode, this.size = 22});

  final String languageCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      // ClipOval kırpar, ama bayrak emoji glifi kutudan KÜÇÜK kalırsa
      // kırpma hiçbir şeye dokunmaz ve rozet yuvarlak değil, düz bir bayrak
      // gibi görünür. Bu yüzden glif bilerek kutudan biraz BÜYÜK çiziliyor
      // (fontSize > size) ki köşeleri gerçekten yuvarlanıp kırpılsın.
      child: ClipOval(
        child: OverflowBox(
          maxWidth: size * 1.3,
          maxHeight: size * 1.3,
          child: Center(
            child: Text(
              languageFlagEmoji(languageCode),
              style: TextStyle(fontSize: size * 1.05),
            ),
          ),
        ),
      ),
    );
  }
}
