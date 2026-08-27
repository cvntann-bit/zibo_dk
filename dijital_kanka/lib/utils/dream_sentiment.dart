import '../models/dream_entry.dart';

/// 2026 yeni özellik — Rüya Günlüğü ↔ Ruh Hali Takibi hafif korelasyonu.
/// Kullanıcı isteği: "AI kullanmadan, sadece tarih karşılaştırmasına dayalı
/// basit bir mantık" — bu yüzden "olumsuz rüya" tespiti bir dil modeli veya
/// dış servis KULLANMIYOR, yalnızca [DreamEntry.title]/[DreamEntry.text]
/// içinde bilinen "kötü rüya" kelimelerini arayan basit bir anahtar kelime
/// taraması. Rüya Günlüğü'nün FORM'una (bkz. `dream_entry_form_screen.dart`)
/// bilerek HİÇ dokunulmadı — kullanıcının "konum/yapı aynen kalsın, sadece
/// hafifçe ilişkilendir" isteğine göre, sentiment yeni bir alan/soru olarak
/// DEĞİL, mevcut serbest metinden ÇIKARSANIYOR.
///
/// Kullanıcının rüyayı HANGİ dilde yazdığını bilemediğimiz için (uygulama
/// arayüz dilinden bağımsız, kullanıcı her zaman kendi rahat olduğu dilde
/// yazabilir) TR+EN+ES anahtar kelimeleri BİRLİKTE taranıyor — `zibo_
/// messages.dart` gibi diğer üç-dilli içerik havuzlarından FARKLI olarak,
/// burada "kullanıcının seçtiği dile göre tek liste" mantığı işlemiyor.
///
/// Bu kesin/mükemmel bir sentiment analizi DEĞİL — bilinçli bir
/// basitleştirme (kullanıcının açık isteği "basit bir mantık"). Yanlış
/// pozitif/negatifler olabilir (ör. "korkuyordum ama sonunda çok mutlu
/// oldum" yine de "olumsuz" işaretlenir) — bu, `dreamMoodCorrelationNote`'un
/// yalnızca hafif bir gözlem sunması, kesin bir teşhis İDDİA ETMEMESİ ile
/// kabul edilebilir bir tradeoff.
const _negativeDreamKeywords = <String>[
  // Türkçe (kısa gövdeler — "kork" gibi kökler "korku"/"korkuyor"/
  // "korkarak" vb. çekimlerin HEPSİNİ substring olarak zaten yakalıyor,
  // ayrıca uzun formları eklemeye gerek yok).
  'kabus', 'kork', 'kaçtım', 'kaçıyor', 'kovalan', 'düştüm', 'düşüyor',
  'öldüm', 'öldür', 'boğul', 'kaybol', 'karanlık', 'canavar', 'saldır',
  'ağla', 'panik', 'tehdit', 'terk',
  // İngilizce
  'nightmare', 'scared', 'fear', 'chased', 'chasing', 'falling', 'died',
  'dying', 'drown', 'lost', 'dark', 'monster', 'attack', 'cry', 'crying',
  'panic', 'threat', 'abandoned',
  // İspanyolca
  'pesadilla', 'miedo', 'perseguido', 'perseguía', 'cayendo', 'caí',
  'morí', 'muerte', 'ahogar', 'perdido', 'perdida', 'oscuro', 'oscuridad',
  'monstruo', 'ataque', 'llorar', 'pánico', 'amenaza', 'abandonado',
];

/// [dream]'in başlığında/metninde bilinen bir "olumsuz rüya" kelimesi
/// geçiyorsa `true` döner (büyük/küçük harf duyarsız).
bool isNegativeDream(DreamEntry dream) {
  final text = '${dream.title} ${dream.text}'.toLowerCase();
  return _negativeDreamKeywords.any(text.contains);
}
