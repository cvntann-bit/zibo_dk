import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/focus_session.dart';
import '../services/cloud_state_store.dart';

/// 2026 yeni özellik — Odak Sayacı (Kronometre/Pomodoro) modülü (bkz.
/// CLAUDE.md). `DreamJournalProvider`/`ManifestProvider` ile AYNI "id ile
/// ayrı ayrı biriken kayıt" `CloudStateStore` (Varyant A) deseni — her
/// tamamlanan/durdurulan oturum kendi kaydı olarak BİRİKİR, üzerine
/// yazılmaz.
class FocusProvider extends ChangeNotifier {
  FocusProvider({
    this.uid,
    DateTime Function() now = DateTime.now,
    FirebaseFirestore? firestore,
  }) : _now = now,
       _store = CloudStateStore(
         prefsKey: _prefsKey,
         uid: uid,
         firestore: firestore,
       ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'focusState';

  /// Yeni oturumun `date`'i için kullanılan saat — `GoalsProvider`/diğer
  /// provider'larla AYNI enjekte edilebilir saat deseni (testte sahte
  /// tarihler vermek için).
  final DateTime Function() _now;

  final String? uid;
  final CloudStateStore _store;

  final List<FocusSession> _sessions = [];
  int _nextId = 1;

  bool _isReady = false;
  bool get isReady => _isReady;

  /// En yeni oturum en başta olacak şekilde salt okunur geçmiş.
  List<FocusSession> get sessions {
    final sorted = List<FocusSession>.from(_sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  /// Şimdiye kadar biriken TOPLAM odak süresi (saniye) — Profil'deki "Odak
  /// Süresi" satırının doğrudan girdisi (bkz. CLAUDE.md).
  int get totalFocusSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      try {
        _nextId = data['nextId'] as int? ?? 1;
        _sessions
          ..clear()
          ..addAll(
            (data['sessions'] as List).map((raw) {
              final map = raw as Map<String, dynamic>;
              return FocusSession(
                id: map['id'] as int,
                date: DateTime.parse(map['date'] as String),
                durationSeconds: map['durationSeconds'] as int,
              );
            }),
          );
      } catch (_) {
        // Bozuk/eski formatlı kayıtlı veri — sessizce boş geçmişle devam
        // et, uygulamanın çökmesindense veri kaybı tercih edilir.
      }
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() => _store.save({
    'nextId': _nextId,
    'sessions': _sessions
        .map(
          (s) => {
            'id': s.id,
            'date': s.date.toIso8601String(),
            'durationSeconds': s.durationSeconds,
          },
        )
        .toList(),
  });

  /// Bir odak seansını kaydeder. [durationSeconds] 60'tan AZ ise (kaza
  /// eseri anlık başlat/durdur, anlamlı bir "odak" sayılmaz) sessizce
  /// reddedilir ve `false` döner — `WaterProvider`/diğer provider'lardaki
  /// "bariz-anlamsız girdiyi reddet" desenidir.
  bool addSession(int durationSeconds) {
    if (durationSeconds < 60) return false;
    _sessions.add(
      FocusSession(id: _nextId, date: _now(), durationSeconds: durationSeconds),
    );
    _nextId++;
    notifyListeners();
    _save();
    return true;
  }
}
