import '../data/address_terms.dart';

/// Söz havuzlarındaki sabit "kanka" kelimesini kullanıcının Profil'den
/// seçtiği hitap tercihiyle (bkz. `ProfileProvider.addressTerm`) değiştirir.
///
/// Yalnızca Türkçe metinlerde anlamlı (bkz. `address_terms.dart`'taki kapsam
/// notu) — İngilizce/İspanyolca söz havuzları zaten "buddy"/"amigo" gibi
/// farklı sabit kelimeler kullanıyor, bu fonksiyon onlara hiç uygulanmıyor.
/// Cümle başında büyük harfli "Kanka", cümle içinde küçük harfli "kanka"
/// olarak geçtiği için (bkz. veri dosyalarındaki tutarlı kullanım) her iki
/// biçim de seçilen terimin aynı büyük/küçük harf varyantıyla değiştiriliyor.
String applyAddressTerm(String text, String term) {
  if (term == defaultAddressTerm) return text;
  final capitalized = term[0].toUpperCase() + term.substring(1);
  final lower = term.toLowerCase();
  return text.replaceAll('Kanka', capitalized).replaceAll('kanka', lower);
}
