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
  });

  final String id;
  final String name;
  final double amount;

  /// Kaydın eklendiği an — "Mevcut Durum" trend grafiğinin zaman eksenini
  /// oluşturmak için kullanılır (bkz. `MoneyScreen`/`MoneyTrendChart`).
  final DateTime date;
}
