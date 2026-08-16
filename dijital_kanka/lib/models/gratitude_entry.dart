/// Şükran Günlüğü'nde tek bir güne ait kayıt. Bir kayıt yalnızca üç şükran
/// cümlesi de doldurulup kaydedildiğinde oluşturulur — bu yüzden şu an
/// [isComplete] pratikte hep `true`, ama veri modelinde ayrı bir alan olarak
/// tutuluyor (bkz. `GratitudeProvider.saveToday` dokümantasyonu: ileride
/// taslak/kısmi kaydetme eklenirse bu alan zaten hazır olur).
class GratitudeEntry {
  const GratitudeEntry({
    required this.date,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.isComplete,
  });

  /// Saat bileşeni olmadan (gece yarısı) — bir güne yalnızca bir kayıt
  /// düşer, bkz. `GratitudeProvider.isTodayComplete`.
  final DateTime date;

  final String text1;
  final String text2;
  final String text3;

  final bool isComplete;
}
