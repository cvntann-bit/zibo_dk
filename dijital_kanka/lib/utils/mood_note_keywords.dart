import '../data/motivation_pools.dart' show MoodPoolTag;

/// 2026 yeni özellik — Ruh Hali Notundan Anahtar Kelime Çıkarımı. Kullanıcı
/// isteği: "gerçek AI/NLP kullanma, basit string/kelime eşleştirmesi
/// yeterli" — `dream_sentiment.dart`'taki (Rüya Günlüğü ↔ Ruh Hali Takibi
/// korelasyonu) BİREBİR AYNI desen: kısa gövdeler (kökler), TR+EN+ES
/// BİRLİKTE taranıyor (kullanıcı notu HANGİ dilde yazdığını bilemeyiz —
/// arayüz dilinden bağımsız), büyük/küçük harf duyarsız `contains` taraması.
///
/// **İki kategori — "düşük" (teselli/rahatlatma temalı sözlerin çıkma
/// ihtimalini artırmak için) ve "yüksek" (pekiştirici/coşkulu sözler
/// için).** `motivation_quote_selector.dart`'taki [MoodPoolTag] ile AYNI
/// iki uç — `neutral` için bir kelime listesi YOK, çünkü "nötr" zaten
/// hiçbir özel sinyal bulunamadığında dönülen VARSAYILAN durum.
const _lowMoodKeywords = <String>[
  // Türkçe
  'yorgun', 'yoruld', 'stres', 'kayg', 'endişe', 'üzgün', 'üzül', 'zor',
  'sınav', 'baskı', 'bunal', 'tüken', 'korku', 'ağla', 'yalnız', 'başarısız',
  'moralim', 'bezgin', 'sıkıl',
  // İngilizce
  'tired', 'exhaust', 'stress', 'anxious', 'anxiety', 'sad', 'upset',
  'hard', 'exam', 'pressure', 'overwhelm', 'burn', 'fear', 'cry', 'lonely',
  'fail', 'worried', 'down',
  // İspanyolca
  'cansad', 'estrés', 'estres', 'ansi', 'triste', 'difícil', 'dificil',
  'examen', 'presión', 'presion', 'agotad', 'miedo', 'llorar', 'solo',
  'sola', 'fracas', 'preocup',
];

const _highMoodKeywords = <String>[
  // Türkçe
  'mutlu', 'mutluluk', 'başarı', 'başardım', 'harika', 'gurur', 'sevin',
  'heyecan', 'güzel', 'keyif', 'enerjik', 'huzur', 'kazandım',
  // İngilizce
  'happy', 'success', 'succeed', 'great', 'proud', 'joy', 'excite',
  'wonderful', 'energetic', 'peace', 'good', 'won',
  // İspanyolca
  'feliz', 'éxito', 'exito', 'logr', 'genial', 'orgull', 'alegr',
  'emocion', 'maravill', 'enérgic', 'energic', 'paz', 'gané',
];

/// [note]'un içinde bilinen "düşük" veya "yüksek" ruh hali kelimelerinden
/// biri geçiyorsa ilgili [MoodPoolTag]'i döner — [note] `null`/boş ise VEYA
/// hem düşük hem yüksek kelimeler AYNI ANDA eşleşiyorsa (çelişkili sinyal,
/// hangisine güvenileceği belirsiz) `null` döner, `motivation_quote_
/// selector.dart`'taki [pickMotivationQuote] bu durumda kullanıcının
/// SEÇTİĞİ emoji'ye (`Mood`) göre hesaplanan etikete sessizce geri döner.
///
/// Bu KESİN bir duygu analizi DEĞİL (bilinçli basitleştirme, kullanıcının
/// açık "AI/NLP değil, basit eşleştirme yeterli" isteğiyle tutarlı) —
/// yalnızca notun KENDİ kaydettiği emoji'yle ÇELİŞEN/onu TAMAMLAYAN bir
/// ipucu bulunduğunda söz seçimine "hafif" bir nüans katmak için kullanılır.
MoodPoolTag? moodNoteKeywordBias(String? note) {
  if (note == null) return null;
  final trimmed = note.trim();
  if (trimmed.isEmpty) return null;

  final text = trimmed.toLowerCase();
  final matchesLow = _lowMoodKeywords.any(text.contains);
  final matchesHigh = _highMoodKeywords.any(text.contains);

  if (matchesLow && matchesHigh) return null;
  if (matchesLow) return MoodPoolTag.low;
  if (matchesHigh) return MoodPoolTag.high;
  return null;
}
