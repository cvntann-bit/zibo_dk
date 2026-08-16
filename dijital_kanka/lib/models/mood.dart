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

/// Günlük Ruh Hali Takibi'nde tek bir güne ait kayıt.
class MoodEntry {
  const MoodEntry({required this.date, required this.mood});

  /// Saat bileşeni olmadan (gece yarısı) — bir güne yalnızca bir kayıt
  /// düşer, bkz. `MoodProvider.setTodayMood` (üzerine yazar).
  final DateTime date;

  final Mood mood;
}
