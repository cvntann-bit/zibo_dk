import 'package:flutter/material.dart';

/// Günlük Ruh Hali Takibi'ndeki 5 sabit seçenek — en kötüden en iyiye sıralı.
/// Her değer kendi emoji'sini ve rengini taşır (bkz. CLAUDE.md "Günlük Ruh
/// Hali Takibi" bölümü — bu renkler bilerek uygulamanın hardal/altın
/// temasından bağımsız, evrensel kırmızı→yeşil "trafik ışığı" skalası).
enum Mood {
  veryUnhappy(emoji: '😢', color: Color(0xFFE53935)),
  unhappy(emoji: '🙁', color: Color(0xFFFB8C00)),
  neutral(emoji: '😐', color: Color(0xFFFDD835)),
  happy(emoji: '🙂', color: Color(0xFF9CCC65)),
  veryHappy(emoji: '😄', color: Color(0xFF43A047));

  const Mood({required this.emoji, required this.color});

  final String emoji;
  final Color color;
}

/// 2026 yeni özellik — Rüya Günlüğü ↔ Ruh Hali Takibi korelasyonu (bkz.
/// `lib/utils/dream_sentiment.dart`) için: enum'un en kötü İKİ değeri
/// (kötüden iyiye sıralı olduğu için `index <= 1`) "düşük ruh hali" sayılır.
extension MoodLowness on Mood {
  bool get isLow => index <= 1;
}

/// 2026 yeni özellik — Motivasyon Sözü Sistemi (bkz. `lib/utils/
/// motivation_quote_selector.dart`) için: [MoodLowness.isLow]'un simetriği —
/// enum'un en iyi İKİ değeri "yüksek enerjili" sayılır. `neutral` (index 2)
/// ne düşük ne yüksek — üçüncü, ayrı bir kategori (bkz. `MoodPoolTag`).
extension MoodEnergy on Mood {
  bool get isHighEnergy => index >= 3;
}

/// **Faz 5 (D2)** — Zibo Pro+'ın detaylı trend grafiği için sayısal skor
/// (1-5, `veryUnhappy`=1 … `veryHappy`=5). [MoodLowness]/[MoodEnergy]'nin
/// zaten `index`'i örtük bir skor gibi kullanmasıyla AYNI ruhta, yalnızca
/// adı konmuş/genel amaçlı bir versiyonu.
extension MoodScore on Mood {
  int get score => index + 1;
}

/// Günlük Ruh Hali Takibi'nde tek bir güne ait kayıt.
class MoodEntry {
  const MoodEntry({required this.date, required this.mood, this.note});

  /// Saat bileşeni olmadan (gece yarısı) — bir güne yalnızca bir kayıt
  /// düşer, bkz. `MoodProvider.setTodayMood` (üzerine yazar).
  final DateTime date;

  final Mood mood;

  /// 2026 yeni özellik — kullanıcının o gün nasıl hissettiğine dair
  /// serbestçe yazdığı kısa not/günlük (opsiyonel, `null` veya boşsa hiç
  /// yazılmamış demektir). Eski (bu alan eklenmeden ÖNCE) kayıtlı veride bu
  /// alan hiç yok — `MoodProvider._loadFromPrefs` bunu `null`'a düşürüyor,
  /// zaten nullable olduğu için ayrı bir göç adımı GEREKMİYOR.
  final String? note;
}
