import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gratitude_entry.dart';
import '../services/cloud_state_store.dart';

/// Şükran Günlüğü'ndeki günlük kayıtları tutan tek kaynak.
/// `SharedPreferences` ile kalıcı — `GoalsProvider`/`DreamJournalProvider`
/// ile aynı JSON-encode deseni. Bir güne yalnızca BİR kayıt düşebilir
/// (bkz. [isTodayComplete]); [Goal.dateOnly] ile aynı gerekçeyle tarihler
/// saat bileşeni atılmış olarak karşılaştırılır.
class GratitudeProvider extends ChangeNotifier {
  /// [now], `GoalsProvider`'la aynı gerekçeyle enjekte edilebilir: testte
  /// "gün değişince yeni bir giriş açılır" davranışını gerçek saatin
  /// geçmesini beklemeden doğrulayabilmek için.
  GratitudeProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'gratitudeEntries';

  final DateTime Function() _now;
  final CloudStateStore _store;
  final List<GratitudeEntry> _entries = [];

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  /// En yeni kayıt en üstte olacak şekilde salt okunur liste. Bir güne
  /// yalnızca bir kayıt düşebildiği için (bkz. [saveToday]) tarihe göre
  /// sıralamak tek başına yeterli — `DreamJournalProvider`'daki id
  /// tiebreaker'ına burada gerek yok.
  List<GratitudeEntry> get entries {
    final sorted = List<GratitudeEntry>.of(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  /// Bugüne ait kayıt (varsa) — form yerine "tamamlandı" durumunu göstermek
  /// için kullanılır.
  GratitudeEntry? get todayEntry {
    for (final entry in _entries) {
      if (entry.date == _today) return entry;
    }
    return null;
  }

  bool get isTodayComplete => todayEntry != null;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Firestore migrasyonundan ÖNCE bu anahtar altında düz bir JSON
      // listesi (map değil) saklanıyordu — `CloudStateStore` yalnızca
      // Map<String, dynamic> okuyabildiği için bu ÇOK ESKİ biçimi burada
      // ayrıca tanıyıp yeni sarmalanmış biçime göç ettiriyoruz (bkz.
      // `CostumeProvider`'daki aynı gerekçeli göç deseni).
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
          decoded.map(
            (raw) => GratitudeEntry(
              date: DateTime.parse((raw as Map<String, dynamic>)['date'] as String),
              text1: raw['text1'] as String,
              text2: raw['text2'] as String,
              text3: raw['text3'] as String,
              isComplete: raw['isComplete'] as bool,
            ),
          ),
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
              'text1': e.text1,
              'text2': e.text2,
              'text3': e.text3,
              'isComplete': e.isComplete,
            },
          )
          .toList(),
    });
  }

  /// Bugünün üç şükran cümlesini kaydeder. Bugün için zaten bir kayıt VARSA
  /// (kilitli) veya üç metinden biri boşsa hiçbir şey yapmadan `false`
  /// döner; başarıyla kaydedilirse `true` döner — çağıran taraf (bkz.
  /// `GratitudeJournalScreen`) bunu `GoalCard`'ın `cycleCompleted` dönüşünü
  /// kullanma şekliyle AYNI biçimde kullanıp yalnızca `true` döndüğünde
  /// `CoinProvider.earnGratitudeJournal()`'ı çağırır.
  bool saveToday({
    required String text1,
    required String text2,
    required String text3,
  }) {
    if (isTodayComplete) return false;
    final t1 = text1.trim();
    final t2 = text2.trim();
    final t3 = text3.trim();
    if (t1.isEmpty || t2.isEmpty || t3.isEmpty) return false;

    _entries.add(
      GratitudeEntry(
        date: _today,
        text1: t1,
        text2: t2,
        text3: t3,
        isComplete: true,
      ),
    );
    notifyListeners();
    _save();
    return true;
  }

  /// Var olan bir kaydı (bugünün ya da geçmişten bir günün) DÜZENLER —
  /// [saveToday]'in aksine kilit KONTROLÜ yapmaz, çünkü bu zaten var olan bir
  /// kaydın İÇERİĞİNİ değiştiriyor, yeni bir gün "tamamlıyor" değil.
  /// [date]'e ait kayıt yoksa ya da üç metinden biri (trim sonrası) boşsa
  /// hiçbir şey yapmadan `false` döner.
  bool updateEntry(
    DateTime date, {
    required String text1,
    required String text2,
    required String text3,
  }) {
    final t1 = text1.trim();
    final t2 = text2.trim();
    final t3 = text3.trim();
    if (t1.isEmpty || t2.isEmpty || t3.isEmpty) return false;

    final index = _entries.indexWhere((e) => e.date == date);
    if (index == -1) return false;

    _entries[index] = GratitudeEntry(
      date: date,
      text1: t1,
      text2: t2,
      text3: t3,
      isComplete: true,
    );
    notifyListeners();
    _save();
    return true;
  }
}
