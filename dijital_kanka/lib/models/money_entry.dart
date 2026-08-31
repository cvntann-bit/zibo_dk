/// Harcamalar ve Birikimler sayfasındaki üç bölüm. Eskiden ayrı bir
/// `payment` (Ödemeler) kategorisi de vardı — "Harcamalar" ile aynı şeyi
/// ifade ettiği için kullanıcı isteğiyle birleştirildi (bkz.
/// `MoneyProvider._loadFromPrefs`'teki geri uyumluluk göçü).
enum MoneyCategory { expense, saving, income }

/// Bir kategoriye eklenmiş tek bir kayıt (ör. "Kira" - 5000 TL).
class MoneyEntry {
  const MoneyEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.currencyCode,
  });

  final String id;
  final String name;
  final double amount;

  /// Kaydın eklendiği an — "Mevcut Durum" trend grafiğinin zaman eksenini
  /// oluşturmak için kullanılır (bkz. `MoneyScreen`/`MoneyTrendChart`).
  final DateTime date;

  /// **2026 güncellemesi — kullanıcı isteği: her kayıt KENDİ para birimini
  /// taşıyabilsin (tek bir global ayara bağımlı kalmadan).** ISO 4217 kodu
  /// (`CurrencyOption.code`, bkz. `data/currencies.dart`) — kaydın
  /// eklendiği ANDAKİ para birimi, sonradan global ayar değişse bile
  /// GERİYE DÖNÜK değişmez (bkz. `GoalCompletion`/favori sözlerdeki AYNI
  /// "anlık görüntü" felsefesi). Otomatik kur çevirisi YOK — kullanıcının
  /// açık isteği, bkz. `MoneyProvider.totalsByCurrencyFor`.
  final String currencyCode;
}
