/// Odak Sayacı'nda tamamlanmış (veya durdurulmuş) tek bir odaklanma
/// oturumu — `DreamEntry`/`GoalCompletion` gibi saf/değişmez bir veri
/// sınıfı (`ChangeNotifier` DEĞİL).
class FocusSession {
  const FocusSession({
    required this.id,
    required this.date,
    required this.durationSeconds,
  });

  /// `FocusProvider._nextId`'den atanan, çakışmasız bir kimlik —
  /// `DreamJournalProvider`'daki AYNI desen.
  final int id;

  /// Oturumun TAMAMLANDIĞI (kaydedildiği) an — `DreamEntry.date` gibi
  /// otomatik atanır, sonradan değişmez.
  final DateTime date;

  /// Oturumun süresi, saniye cinsinden.
  final int durationSeconds;
}
