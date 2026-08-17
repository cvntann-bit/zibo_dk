/// Basit, para birimine göre dallanan bir fiyat biçimlendirici — "19,99 ₺"
/// gibi. Şu an yalnızca `'TRY'` destekleniyor (kullanıcının açık isteği:
/// "şimdilik sadece TL göster") ama [PackagePrice.currencyCode] alanı
/// sayesinde ileride ülkeye göre farklı bir para birimi eklenmek istenirse
/// yalnızca burada yeni bir `case` eklemek yeterli olacak — çağıran taraflar
/// (ör. `_PackageCardState`) hiç değişmeyecek.
///
/// [languageCode] YALNIZCA sayının biçimini (ondalık/binlik ayracı) seçer,
/// para birimini DEĞİL — kullanıcının "gerçek çoklu para birimine kolayca
/// genişletilebilecek şekilde kur, ama şimdilik yalnızca FORMAT olarak
/// uyarla" isteği doğrultusunda: İngilizce arayüzde "159.90 ₺" (nokta
/// ondalık), Türkçe/İspanyolca arayüzde "159,90 ₺" (virgül ondalık,
/// ikisinde de yaygın kullanım). Fiyatın kendisi (ve `₺` sembolü) HENÜZ
/// gerçek bir bölgeye/para birimine göre DEĞİŞMİYOR — bu yalnızca
/// [PackagePrice.currencyCode]'un zaten desteklediği bir sonraki adım.
String formatCurrencyAmount(
  double amount,
  String currencyCode, {
  String languageCode = 'tr',
}) {
  final formattedNumber = languageCode == 'en'
      ? _formatEnglishStyleNumber(amount)
      : _formatTurkishStyleNumber(amount);
  switch (currencyCode) {
    case 'TRY':
      return '$formattedNumber ₺';
    default:
      return '$formattedNumber $currencyCode';
  }
}

/// Türkçe/İspanyolca sayı biçimi: ondalık ayracı virgül, binlik ayracı nokta
/// (ör. 1499.99 → "1.499,99"). `intl` paketine bilerek gerek duyulmadı —
/// yalnızca iki ondalık basamaklı, pozitif fiyatlar için gereken bu kadar
/// basit bir biçimlendirme.
String _formatTurkishStyleNumber(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final wholePart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < wholePart.length; i++) {
    if (i > 0 && (wholePart.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(wholePart[i]);
  }
  return '$buffer,$decimalPart';
}

/// İngilizce sayı biçimi: ondalık ayracı nokta, binlik ayracı virgül
/// (ör. 1499.90 → "1,499.90") — yukarıdakinin ayraçları ters çevrilmiş hali.
String _formatEnglishStyleNumber(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final wholePart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < wholePart.length; i++) {
    if (i > 0 && (wholePart.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(wholePart[i]);
  }
  return '$buffer.$decimalPart';
}
