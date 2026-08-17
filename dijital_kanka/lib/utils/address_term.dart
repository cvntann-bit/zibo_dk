import 'package:flutter/material.dart' show Locale;

import '../data/address_terms.dart';

/// Söz havuzlarındaki sabit hitap kelimesini kullanıcının Profil'den seçtiği
/// hitap tercihiyle (bkz. `ProfileProvider.addressTerm`) değiştirir.
///
/// **2026 güncellemesi — artık üç dilde de çalışıyor.** Önceki sürüm yalnızca
/// Türkçe metinlerdeki "Kanka"yı değiştiriyordu; İngilizce/İspanyolca söz
/// havuzları "Buddy"/"Amigo" kullandığı için bu fonksiyon onlarda TAMAMEN
/// ETKİSİZDİ (kullanıcı hangi dili seçerse seçsin, İngilizce/İspanyolca
/// sözlerdeki hitap HİÇBİR ZAMAN kişiselleşmiyordu — kullanıcı isteğiyle bu
/// kapsam genişletildi). [locale] verilen dile göre değiştirilecek
/// yer tutucu kelimeyi seçer (`_placeholderFor`) — TR: "Kanka", EN: "Buddy",
/// ES: "Amigo". Cümle başında büyük harfli, cümle içinde küçük harfli
/// geçtiği için (bkz. veri dosyalarındaki tutarlı kullanım, üç dilde de
/// AYNI desen) her iki biçim de seçilen terimin aynı büyük/küçük harf
/// varyantıyla değiştiriliyor. [locale] verilmezse Türkçe varsayılan
/// davranışa düşer (geriye dönük uyumluluk — mevcut testler/çağrı yerleri).
String applyAddressTerm(
  String text,
  String term, [
  Locale locale = const Locale('tr'),
]) {
  if (term == defaultAddressTerm) return text;
  final placeholder = _placeholderFor(locale);
  final capitalized = term[0].toUpperCase() + term.substring(1);
  final lower = term.toLowerCase();
  return text
      .replaceAll(placeholder, capitalized)
      .replaceAll(placeholder.toLowerCase(), lower);
}

String _placeholderFor(Locale locale) => switch (locale.languageCode) {
  'en' => 'Buddy',
  'es' => 'Amigo',
  _ => 'Kanka',
};
