import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/zibo_event.dart';
import '../services/cloud_state_store.dart';

/// Zibo Dünyası etkinlikleri (docs/zibo_world_roadmap.md Faz 6).
///
/// Firebase varsa açılışta `events` koleksiyonundan `enabled == true`
/// dokümanlar bir kez okunur (okuma hatası sessizce yutulur, etkinlik
/// görünmez). Açılan günler `users/{uid}/state/eventsState`'te saklanır —
/// aynı kutu iki kez açılamaz.
///
/// Gün hesabı `now` ile yapılır; `main.dart`'ta `TrustedTimeProvider`'a
/// bağlanır (telefonun tarihini ileri alarak gelecek kutular açılamasın).
///
/// Ödülü bu sınıf VERMEZ: [open] kutuyu açık işaretler ve ödülü döndürür,
/// çağıran taraf ZC'yi (`CoinProvider.earnEventReward`) ya da eşyayı
/// (`HomeDecorProvider.markOwned`) uygular. Önce işaretlenir ki ödül iki kez
/// alınamasın.
class EventsProvider extends ChangeNotifier {
  EventsProvider({String? uid, FirebaseFirestore? firestore, DateTime Function()? now})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance),
      _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid, firestore: firestore) {
    _ready = _load();
  }

  static const _prefsKey = 'eventsState';

  final FirebaseFirestore? _firestore;
  final DateTime Function() _now;
  final CloudStateStore _store;
  late final Future<void> _ready;

  List<ZiboEvent> _events = const [];
  final Map<String, Set<int>> _opened = {};
  bool _isReady = false;

  bool get isReady => _isReady;
  Future<void> get ready => _ready;

  /// Testler ve önizleme için: koleksiyon okunmadan etkinlik listesi.
  @visibleForTesting
  void setEvents(List<ZiboEvent> events) {
    _events = events;
    notifyListeners();
  }

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  Iterable<ZiboEvent> get _usable => _events.where((e) => e.enabled && e.isSupported);

  /// Bugün süren etkinlikler (başlangıca göre sıralı).
  List<ZiboEvent> get active =>
      _usable.where((e) => !_today.isBefore(e.start) && !_today.isAfter(e.end)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// 30 gün içinde başlayacaklar.
  List<ZiboEvent> get upcoming =>
      _usable.where((e) => _today.isBefore(e.start) && _daysBetween(_today, e.start) <= 30).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// Bugünün gün sırası (0 = ilk gün); başlamadıysa -1.
  int todayIndex(ZiboEvent e) => _today.isBefore(e.start) ? -1 : _daysBetween(e.start, _today);

  bool isOpened(ZiboEvent e, int day) => _opened[e.id]?.contains(day) ?? false;

  bool canOpen(ZiboEvent e, int day) {
    if (day < 0 || day >= e.days.length || isOpened(e, day)) return false;
    if (_today.isAfter(e.end)) return false;
    final today = todayIndex(e);
    return e.catchUp ? day <= today : day == today;
  }

  /// Giriş ekranındaki kapı rozeti: açılmayı bekleyen kutu sayısı.
  int get openableCount {
    var n = 0;
    for (final e in active) {
      for (var d = 0; d < e.days.length; d++) {
        if (canOpen(e, d)) n++;
      }
    }
    return n;
  }

  /// Kutuyu açar; açılamıyorsa null. Ödülü çağıran uygular.
  EventReward? open(ZiboEvent e, int day) {
    if (!canOpen(e, day)) return null;
    (_opened[e.id] ??= {}).add(day);
    notifyListeners();
    _save();
    return e.days[day];
  }

  Future<void> _load() async {
    final data = await _store.load();
    if (data != null) {
      try {
        final opened = data['opened'];
        if (opened is Map) {
          for (final entry in opened.entries) {
            if (entry.value is List) {
              _opened['${entry.key}'] = {for (final d in entry.value as List) if (d is num) d.toInt()};
            }
          }
        }
      } catch (_) {
        // Bozuk kayıt: hiç açılmamış say.
      }
    }
    _isReady = true;
    notifyListeners();
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final snap = await firestore.collection('events').where('enabled', isEqualTo: true).get();
      _events = [
        for (final doc in snap.docs)
          if (ZiboEvent.fromJson(doc.id, doc.data()) case final event?) event,
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('EventsProvider: events okunamadı ($e)');
    }
  }

  Future<void> _save() => _store.save({
    'opened': {for (final e in _opened.entries) e.key: (e.value.toList()..sort())},
  });
}
