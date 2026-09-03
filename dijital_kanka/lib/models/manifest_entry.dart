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
  ///
  /// **2026 güncellemesi — nullable'a çevrildi (`ManifestProvider.
  /// addEntry()`'de kayıt OLUŞTURULURKEN hâlâ ZORUNLU/dolu).** "Cihazlar
  /// arası fotoğraf taşınmaz" sınırlaması yüzünden (bkz. sınıfın kendi
  /// dokümantasyonu) bir hesap değişiminden gelen kayıt BU cihazda hiç var
  /// olmamış bir path taşıyabiliyordu — Crashlytics'teki en büyük
  /// tekrarlayan crash buradan geliyordu (bkz. CLAUDE.md "Manifest Günlüğü
  /// ↔ Profil fotoğrafı" bölümü). `ManifestProvider.reconcileMissingPhotos()`
  /// artık dosya diskte YOKSA bu alanı kalıcı olarak `null`'a çeviriyor —
  /// `null`, "bu kaydın fotoğrafı SONRADAN kayboldu" anlamına geliyor.
  final String? photoPath;

  final String intentionText;
}
