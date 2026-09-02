import 'package:flutter/foundation.dart';

import '../models/dream_entry.dart';
import '../services/cloud_state_store.dart';

/// Rüya Günlüğü'ndeki kayıtları tutan tek kaynak. `CloudStateStore` ile
/// kalıcı — `GoalsProvider`/`MoneyProvider` ile aynı desen.
class DreamJournalProvider extends ChangeNotifier {
  DreamJournalProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'dreamEntries';

  final CloudStateStore _store;
  final List<DreamEntry> _entries = [];
  int _nextId = 0;

  /// En yeni kayıt en üstte olacak şekilde salt okunur liste. İki kayıt aynı
  /// milisaniyede eklenmişse (art arda hızlı `addDream` çağrıları, ör.
  /// testlerde) `date` tek başına belirleyici olmayabilir — bu yüzden id
  /// (artan sırada atanır) ikincil, kesin sonuç veren bir sıralama anahtarı
  /// olarak kullanılıyor.
  List<DreamEntry> get dreams {
    final sorted = List<DreamEntry>.of(_entries)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return int.parse(b.id).compareTo(int.parse(a.id));
      });
    return List.unmodifiable(sorted);
  }

  DreamEntry? findById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Bugün en az bir rüya kaydedilmiş mi — "Denge Ustası" (Gizli/Eğlenceli
  /// Rozetler, bkz. `hidden_badges.dart`) rozetinin YEDİ modül kontrolünden
  /// biri. Bu provider'ın enjekte edilebilir bir saati OLMADIĞI için
  /// (bkz. sınıf dokümantasyonu — `addDream` de doğrudan `DateTime.now()`
  /// kullanıyor) burada da AYNI şekilde ham `DateTime.now()` kullanılıyor.
  bool get hasEntryToday {
    final now = DateTime.now();
    return _entries.any(
      (e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day,
    );
  }

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded == null) return;
    try {
      _nextId = decoded['nextId'] as int;
      final rawList = decoded['entries'] as List;
      _entries
        ..clear()
        ..addAll(
          rawList.map(
            (raw) => DreamEntry(
              id: (raw as Map<String, dynamic>)['id'] as String,
              title: raw['title'] as String,
              text: raw['text'] as String,
              date: DateTime.parse(raw['date'] as String),
            ),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  Future<void> _save() async {
    await _store.save({
      'nextId': _nextId,
      'entries': _entries
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'text': e.text,
              'date': e.date.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  /// Yeni bir rüya kaydeder; tarih otomatik olarak şu an (bugün) atanır.
  void addDream({required String title, required String text}) {
    final trimmedTitle = title.trim();
    final trimmedText = text.trim();
    if (trimmedTitle.isEmpty || trimmedText.isEmpty) return;
    _entries.add(
      DreamEntry(
        id: '${_nextId++}',
        title: trimmedTitle,
        text: trimmedText,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
    _save();
  }

  /// Var olan bir kaydın başlığını/metnini günceller; tarihi DEĞİŞMEZ.
  void updateDream(String id, {required String title, required String text}) {
    final trimmedTitle = title.trim();
    final trimmedText = text.trim();
    if (trimmedTitle.isEmpty || trimmedText.isEmpty) return;
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _entries[index] = DreamEntry(
      id: id,
      title: trimmedTitle,
      text: trimmedText,
      date: _entries[index].date,
    );
    notifyListeners();
    _save();
  }

  void removeDream(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    _save();
  }
}
