/// Basit, para birimine göre dallanan bir fiyat biçimlendirici — "19,99 ₺"
/// gibi. Şu an yalnızca `'TRY'` destekleniyor (kullanıcının açık isteği:
/// "şimdilik sadece TL göster") ama [PackagePrice.currencyCode] alanı
/// sayesinde ileride ülkeye göre farklı bir para birimi eklenmek istenirse
/// yalnızca burada yeni bir `case` eklemek yeterli olacak — çağıran taraflar
/// (ör. `_PackageCardState`) hiç değişmeyecek.
String formatCurrencyAmount(double amount, String currencyCode) {
  final formattedNumber = _formatTurkishStyleNumber(amount);
  switch (currencyCode) {
    case 'TRY':
      return '$formattedNumber ₺';
    default:
      return '$formattedNumber $currencyCode';
  }
}

/// Türkçe sayı biçimi: ondalık ayracı virgül, binlik ayracı nokta
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
