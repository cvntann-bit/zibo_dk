/// Rüya Günlüğü'ne kaydedilmiş tek bir rüya kaydı.
class DreamEntry {
  const DreamEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
  });

  final String id;
  final String title;
  final String text;

  /// Kayıt oluşturulduğu an otomatik olarak atanır (bkz.
  /// `DreamJournalProvider.addDream`); düzenlemede değişmez.
  final DateTime date;
}
