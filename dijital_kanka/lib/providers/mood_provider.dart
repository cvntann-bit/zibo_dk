import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood.dart';
import '../services/cloud_state_store.dart';

/// Günlük Ruh Hali Takibi'ndeki günlük kayıtları tutan tek kaynak.
/// `SharedPreferences` ile kalıcı — `GratitudeProvider` ile aynı JSON-encode
/// deseni, tek farkla: burada kilitleme YOK, bugünün seçimi gün bitene kadar
/// istendiği kadar ÜZERİNE YAZILABİLİR (bkz. [setTodayMood]).
class MoodProvider extends ChangeNotifier {
  /// [now], `GoalsProvider`/`GratitudeProvider`'la aynı gerekçeyle enjekte
  /// edilebilir: testte "gün değişince yeni bir seçim açılır" davranışını
  /// gerçek saatin geçmesini beklemeden doğrulayabilmek için.
  MoodProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'moodEntries';

  final DateTime Function() _now;
  final CloudStateStore _store;
  final List<MoodEntry> _entries = [];

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  /// En yeni kayıt en üstte olacak şekilde salt okunur liste.
  List<MoodEntry> get entries {
    final sorted = List<MoodEntry>.of(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  /// Bugün için seçilen ruh hali (henüz seçilmediyse `null`).
  Mood? get todayMood {
    for (final entry in _entries) {
      if (entry.date == _today) return entry.mood;
    }
    return null;
  }

  /// Belirtilen tarihe ait kayıt (varsa) — "Son 7 Gün" şeridi için.
  MoodEntry? entryForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final entry in _entries) {
      if (entry.date == target) return entry;
    }
    return null;
  }

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Firestore migrasyonundan ÖNCE bu anahtar altında düz bir JSON
      // listesi (map değil) saklanıyordu — bkz. `GratitudeProvider`'daki
      // aynı gerekçeli göç deseni.
      final legacyList = await _loadLegacyRawList();
      if (legacyList != null) {
        data = {'entries': legacyList};
        await _store.save(data);
      }
    }
    if (data == null) return;
    try {
      final decoded = data['entries'] as List;
      _entries
        ..clear()
        ..addAll(
          decoded.map((raw) {
            final map = raw as Map<String, dynamic>;
            return MoodEntry(
              date: DateTime.parse(map['date'] as String),
              mood: Mood.values.byName(map['mood'] as String),
              // Eski (bu alan eklenmeden ÖNCE) kayıtlarda `note` hiç yok —
              // `as String?` bunu sessizce `null`'a düşürür.
              note: map['note'] as String?,
            );
          }),
        );
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  Future<List<dynamic>?> _loadLegacyRawList() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return null;
    try {
      final decoded = jsonDecode(saved);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    await _store.save({
      'entries': _entries
          .map(
            (e) => {
              'date': e.date.toIso8601String(),
              'mood': e.mood.name,
              'note': e.note,
            },
          )
          .toList(),
    });
  }

  /// Bugünün ruh halini kaydeder — bugün için zaten bir kayıt VARSA onun
  /// yerine geçer (üzerine yazar), yoksa yeni bir kayıt oluşturur. Şükran
  /// Günlüğü'ndeki `saveToday`'in aksine kilitleme yok, bu yüzden bir
  /// başarı/başarısızlık dönmesine gerek yok — her çağrı başarılı olur.
  ///
  /// [note] — 2026 yeni özellik, opsiyonel serbest metin (bkz. `MoodEntry.
  /// note` dokümantasyonu). **`note` HİÇ VERİLMEZSE** (parametre atlanırsa,
  /// örn. yalnızca bir emoji'ye dokunulduğunda) bugünün MEVCUT notu
  /// KORUNUR — yalnızca ruh hali değişir. **`note` AÇIKÇA verilirse**
  /// (boş string DAHİL — `mood_tracking_screen.dart`'ın not alanı temizlenip
  /// kaydedildiğinde) trim'lenip boşsa `null`'a (notu SİLER), doluysa yeni
  /// metne güncellenir. Bu tek parametreyle hem "yalnızca emoji'ye dokun"
  /// hem "notu güncelle/temizle" akışlarının İKİSİ de karşılanıyor.
  void setTodayMood(Mood mood, {String? note}) {
    String? resolvedNote;
    if (note == null) {
      final existingToday = _entries.where((e) => e.date == _today);
      resolvedNote = existingToday.isEmpty ? null : existingToday.first.note;
    } else {
      final trimmed = note.trim();
      resolvedNote = trimmed.isEmpty ? null : trimmed;
    }
    _entries.removeWhere((e) => e.date == _today);
    _entries.add(MoodEntry(date: _today, mood: mood, note: resolvedNote));
    notifyListeners();
    _save();
  }
}
