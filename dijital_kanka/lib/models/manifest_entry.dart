/// Manifest Günlüğü'ne kaydedilmiş tek bir giriş: bir fotoğraf + niyet
/// metni. `DreamEntry` ile aynı desen — bir güne BİRDEN FAZLA giriş
/// düşebilir (bkz. `ManifestProvider.addEntry`), bu yüzden her girişin
/// kendi [id]'si var; coin ödülünün gün başına yalnızca bir kez verilmesi
/// artık entry düzeyinde değil, `ManifestProvider`'da GÜN düzeyinde
/// (`isTodayRewardClaimed`) takip ediliyor.
class ManifestEntry {
  const ManifestEntry({
    required this.id,
    required this.date,
    required this.photoPath,
    required this.intentionText,
  });

  final String id;

  /// Saat bileşeni olmadan (gece yarısı) — yalnızca hangi GÜNE ait olduğunu
  /// belirtir, aynı tarihte birden fazla kayıt olabilir.
  final DateTime date;

  /// Fotoğrafın cihazdaki KALICI yerel dosya yolu (uygulamanın belge
  /// dizini altında — bkz. `PhotoPickerService.saveToPermanentStorage`).
  /// Sunucuya yüklenmez, yalnızca bu cihazda saklanır.
  final String photoPath;

  final String intentionText;
}
