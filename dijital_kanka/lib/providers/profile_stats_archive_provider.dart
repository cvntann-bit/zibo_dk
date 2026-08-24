import 'package:flutter/foundation.dart';

import '../models/monthly_stats_snapshot.dart';
import '../services/cloud_state_store.dart';
import '../utils/profile_stats.dart';

/// Profil'deki "İstatistiklerim" bölümünün ay sonu arşivini tutar.
/// `ProfileStats.compute()`'un KENDİSİ (rolling-window formülleri, geniş
/// test kapsamı olan mevcut mantık) hiçbir şekilde değiştirilmedi/kalıcı
/// bir state'e çevrilmedi — bu provider yalnızca, takvim ayı değiştiğinde o
/// ANDA hesaplanan canlı sonucun donmuş bir kopyasını (bkz.
/// `MonthlyStatsSnapshot`) saklıyor. `CloudStateStore` ile kalıcı,
/// `MoneyProvider`/`DreamJournalProvider` gibi diğer TÜM provider'larla AYNI
/// desen (Varyant A, tek anahtarlı JSON).
///
/// **Bilinçli basitleştirme:** rolling-window hesaplama geçmişi kalıcı
/// tutmadığı için, "geçen ayın TAM son günündeki" değer değil, "kullanıcının
/// yeni ayda uygulamayı İLK açtığı anda" görülen canlı değer arşivleniyor —
/// pratikte neredeyse her zaman aynı gün/çok yakın bir yaklaşıklık (kullanıcı
/// genelde uygulamayı düzenli açıyor). Kullanıcı bir veya daha fazla ayı
/// hiç açmadan atlarsa, yalnızca EN SON görülen ay arşivlenir — atlanan ara
/// ayların verisi rolling-window'dan zaten geri getirilemez.
class ProfileStatsArchiveProvider extends ChangeNotifier {
  ProfileStatsArchiveProvider({String? uid})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'profileStatsArchive';

  final CloudStateStore _store;

  final List<MonthlyStatsSnapshot> _snapshots = [];
  String? _lastSeenMonthKey;

  /// En yeni ay en üstte.
  List<MonthlyStatsSnapshot> get snapshots => List.unmodifiable(_snapshots.reversed);

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data == null) return;
    try {
      _lastSeenMonthKey = data['lastSeenMonthKey'] as String?;
      final rawList = data['snapshots'] as List? ?? const [];
      _snapshots
        ..clear()
        ..addAll(rawList.map(_snapshotFromJson));
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  MonthlyStatsSnapshot _snapshotFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final rawScores = map['scores'] as Map<String, dynamic>;
    return MonthlyStatsSnapshot(
      year: map['year'] as int,
      month: map['month'] as int,
      scores: rawScores.map((key, value) => MapEntry(key, (value as num).toDouble())),
    );
  }

  Future<void> _save() async {
    await _store.save({
      'lastSeenMonthKey': _lastSeenMonthKey,
      'snapshots': _snapshots
          .map((s) => {'year': s.year, 'month': s.month, 'scores': s.scores})
          .toList(),
    });
  }

  /// `ProfileScreen` her aktif olduğunda çağrılır (bkz. o ekranın
  /// `isActive`/`didUpdateWidget` deseni). Takvim ayı SON kontrolden beri
  /// değiştiyse, ÖNCEKİ ay [liveStats]'ın o anki değerleriyle arşivlenir.
  /// Aynı ay içindeki tekrar çağrılar (ör. her `build()`'de) ucuz bir no-op.
  void archiveIfMonthChanged(List<CategoryStat> liveStats, DateTime now) {
    final nowKey = _monthKey(now.year, now.month);
    if (_lastSeenMonthKey == null) {
      // İlk çalıştırma — henüz karşılaştırılacak bir temel yok.
      _lastSeenMonthKey = nowKey;
      _save();
      return;
    }
    if (_lastSeenMonthKey == nowKey) return;

    final previous = _parseMonthKey(_lastSeenMonthKey!);
    final scores = <String, double>{
      for (final stat in liveStats)
        if (stat.hasData) stat.category.name: stat.score,
    };
    if (scores.isNotEmpty) {
      _snapshots.add(
        MonthlyStatsSnapshot(year: previous.$1, month: previous.$2, scores: scores),
      );
    }
    _lastSeenMonthKey = nowKey;
    notifyListeners();
    _save();
  }

  static String _monthKey(int year, int month) => '$year-$month';

  static (int, int) _parseMonthKey(String key) {
    final parts = key.split('-');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
