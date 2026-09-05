// Şükran Günlüğü'ndeki üç metin kutusuna, kullanıcı yazmaya başlamadan önce
// gösterilen ilham verici placeholder önerileri — kullanıcı isteği: "her gün
// değişen ilham verici öneriler". `zibo_event_messages.dart`'taki "TR only
// for now" kararıyla AYNI gerekçeyle (kullanıcı yalnızca Türkçe örnek verdi,
// çeviri istenmedi) BİLEREK yalnızca Türkçe — `motivation_pools.dart`'ın
// TR/EN/ES tam çevirisinden FARKLI, daha dar bir kapsam kararı.
//
// Rotasyon deterministik gün-bazlı (bkz. [gratitudePromptForField]) — gerçek
// rastgelelik DEĞİL, `zibo_messages.dart`'taki söz havuzlarının index-tabanlı
// deseninden FARKLI olarak burada tekrar-önleme/dokunuşa tepki GEREKMİYOR
// (placeholder yalnızca kullanıcı yazmaya başlamadan önce görünüyor, normal
// TextField placeholder davranışıyla kayboluyor) — bu yüzden basit bir
// "günün sırasına göre havuzdan seç" yeterli. Üç alan AYNI ANDA farklı
// önerilerle dolsun diye her alan kendi sabit ofsetiyle (9 — 27 sözlük
// havuzun üçte biri) havuzda ilerliyor, üçü de HER GÜN birlikte değişiyor.
const List<String> gratitudePromptsTr = [
  'Sahip olduğun ama unuttuğun bir imkan...',
  'Doğada fark ettiğin güzel bir şey...',
  'Geçmişten bugüne şükrettiğin bir şey...',
  'Bugün seni gülümseten küçük bir an...',
  'Yanında olduğu için minnettar olduğun bir kişi...',
  'Bedeninin bugün senin için yaptığı bir şey...',
  'Bugün kolayca hallettiğin bir iş...',
  'Çocukluğundan şükrettiğin bir anı...',
  'Evinde/odanda sevdiğin küçük bir detay...',
  'Bugün tattığın güzel bir yemek/içecek...',
  'Sana destek olan bir dostluk...',
  'Öğrenmiş olduğun ve seni geliştiren bir ders...',
  'Bugün duyduğun güzel bir söz/müzik...',
  'Kolayca ulaşabildiğin, değerini bilmediğin bir kaynak (su, elektrik vb.)...',
  'Geçen hafta seni mutlu eden bir gelişme...',
  'Şu an sahip olduğun bir yetenek/beceri...',
  'Bugün birine yardım etme fırsatın oldu mu?...',
  'Sağlığınla ilgili şükrettiğin bir şey...',
  'Bir hayvanın/evcil dostunun sana verdiği mutluluk...',
  'Bugün gördüğün güzel bir manzara/gökyüzü...',
  'Ailenden şükrettiğin bir şey...',
  'Bugün kendine ayırdığın küçük bir an...',
  'Geçmişte zor gelip şimdi seni güçlendiren bir deneyim...',
  'Şu anki işinde/okulunda sevdiğin bir şey...',
  'Bugün seni güldüren bir şaka/olay...',
  'Kendinle ilgili gurur duyduğun bir özellik...',
  'Yarına dair umut verici bir beklenti...',
];

/// [date] ve [fieldIndex]'e (0, 1 veya 2) göre havuzdan deterministik bir
/// öneri döner — aynı gün içinde üç alan da AYNI çağrıda tutarlı, farklı
/// önerilerle dolar; gün değişince (bir sonraki takvim günü) üçü de birlikte
/// döner. Saf/test edilebilir bir fonksiyon.
String gratitudePromptForField(DateTime date, int fieldIndex) {
  // Yıl+ay+gün'den basit, monoton artan bir "gün sırası" — takvim ayının
  // gerçek gün sayısına duyarlı olmasına gerek yok, yalnızca HER takvim
  // gününde FARKLI (ve ertesi gün yine farklı) bir değer üretmesi yeterli.
  final dayOrdinal = date.year * 372 + date.month * 31 + date.day;
  final index = (dayOrdinal + fieldIndex * 9) % gratitudePromptsTr.length;
  return gratitudePromptsTr[index];
}
