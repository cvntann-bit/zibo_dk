import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/games_config.dart';
import '../services/cloud_state_store.dart';

/// Oyun Salonu'nun kalıcı durumu (bkz. `docs/game_zibo.md` Faz 2):
/// Oyun Puanı ★ bakiyesi, oyun başına günlük hak / reklamla ek hak,
/// rekorlar ve haftalık puan. `CloudStateStore` → `gamePointsState`.
///
/// Gün ve hafta sınırları enjekte edilen [now]'dan türetilir (uygulamada
/// `TrustedTimeProvider` — cihaz saatini ileri almak hak/hafta sıfırlatmaz).
/// Hafta pazartesi başlar. Oyunlar coin VERMEZ; ★ → ZC takası Faz 3'te
/// (Takas Gişesi) bu sağlayıcı üzerinden yapılacak.
class GamePointsProvider extends ChangeNotifier {
  GamePointsProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _load();
  }

  static const _prefsKey = 'gamePointsState';

  final DateTime Function() _now;
  final CloudStateStore _store;
  final Completer<void> _readyCompleter = Completer<void>();

  int _points = 0;
  int _totalEarned = 0;
  int _weekPoints = 0;
  int _weekExchanged = 0;
  String _dayKey = '';
  String _weekKey = '';
  final Map<String, _DailyPlays> _plays = {};
  final Map<String, int> _best = {};

  /// Kayıtlı veri yüklenince tamamlanır (AppStreakProvider ile aynı desen).
  Future<void> get ready => _readyCompleter.future;

  int get points => _points;
  int get totalEarned => _totalEarned;

  /// Bu hafta oyunlardan kazanılan ★ (sıralama için).
  int get weekPoints {
    _roll();
    return _weekPoints;
  }

  /// Bu hafta Takas Gişesi'nde alınan ZC (Faz 3).
  int get weekExchanged {
    _roll();
    return _weekExchanged;
  }

  int best(String gameId) => _best[gameId] ?? 0;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _currentDayKey => _key(_today);
  String get _currentWeekKey => _key(_today.subtract(Duration(days: _today.weekday - 1)));

  /// Gün değiştiyse haklar, hafta değiştiyse haftalık sayaçlar sıfırlanır.
  /// Değişiklik olursa `true` döner (çağıran kaydeder).
  bool _roll() {
    var changed = false;
    final day = _currentDayKey;
    if (_dayKey != day) {
      _dayKey = day;
      _plays.clear();
      changed = true;
    }
    final week = _currentWeekKey;
    if (_weekKey != week) {
      _weekKey = week;
      _weekPoints = 0;
      _weekExchanged = 0;
      changed = true;
    }
    return changed;
  }

  _DailyPlays _playsOf(String gameId) => _plays.putIfAbsent(gameId, _DailyPlays.new);

  /// Bugün bu oyun için toplam hak (üyelik + reklamla alınanlar).
  int maxPlays(String gameId, String tier, GamesConfig config) {
    _roll();
    return config.playsFor(tier) + _playsOf(gameId).bonus;
  }

  int playsLeft(String gameId, String tier, GamesConfig config) {
    final left = maxPlays(gameId, tier, config) - _playsOf(gameId).used;
    return left < 0 ? 0 : left;
  }

  /// Reklamla +1 hak alınabilir mi? Yalnızca ücretsiz üyelikte (Pro/Pro+
  /// zaten daha çok hak alıyor, reklam görmüyor) ve günlük sınır dolmadıysa.
  bool canAdForPlay(String gameId, String tier, GamesConfig config) {
    _roll();
    return tier == 'free' && _playsOf(gameId).ads < config.maxAdPlaysPerGame;
  }

  /// Bir tur başlatır; hak yoksa `false`.
  bool consumePlay(String gameId, String tier, GamesConfig config) {
    if (playsLeft(gameId, tier, config) <= 0) return false;
    _playsOf(gameId).used++;
    _changed();
    return true;
  }

  /// İzlenen ödüllü reklam karşılığı +1 hak. Sınır dolmuşsa `false`.
  bool grantAdPlay(String gameId, String tier, GamesConfig config) {
    if (!canAdForPlay(gameId, tier, config)) return false;
    final p = _playsOf(gameId);
    p.ads++;
    p.bonus++;
    _changed();
    return true;
  }

  /// Biten bir turun puanını işler: puan [0, tur tavanı] aralığına
  /// kısılır, bakiyeye ve haftalık puana eklenir; [score] rekoru geçerse
  /// rekor güncellenir. Kabul edilen puanı döner.
  int recordFinish(String gameId, {required int claimedPoints, int? score, required GamesConfig config}) {
    _roll();
    final accepted = claimedPoints.clamp(0, config.capOf(gameId));
    _points += accepted;
    _totalEarned += accepted;
    _weekPoints += accepted;
    if (score != null && score > best(gameId)) _best[gameId] = score;
    _changed();
    return accepted;
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final data = await _store.load();
      if (data != null) {
        _points = (data['points'] as num?)?.toInt() ?? 0;
        _totalEarned = (data['totalEarned'] as num?)?.toInt() ?? _points;
        _weekPoints = (data['weekPoints'] as num?)?.toInt() ?? 0;
        _weekExchanged = (data['weekExchanged'] as num?)?.toInt() ?? 0;
        _dayKey = data['dayKey'] as String? ?? '';
        _weekKey = data['weekKey'] as String? ?? '';
        final plays = data['plays'];
        if (plays is Map) {
          plays.forEach((k, v) {
            if (k is String && v is Map) _plays[k] = _DailyPlays.fromJson(v);
          });
        }
        final best = data['best'];
        if (best is Map) {
          best.forEach((k, v) {
            if (k is String && v is num) _best[k] = v.toInt();
          });
        }
      }
    } catch (_) {
      // Bozuk kayıt — sıfırdan devam.
    }
    if (_roll()) unawaited(_save());
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    notifyListeners();
  }

  Future<void> _save() {
    return _store.save({
      'points': _points,
      'totalEarned': _totalEarned,
      'weekPoints': _weekPoints,
      'weekExchanged': _weekExchanged,
      'dayKey': _dayKey,
      'weekKey': _weekKey,
      'plays': {for (final e in _plays.entries) e.key: e.value.toJson()},
      'best': _best,
    });
  }
}

class _DailyPlays {
  _DailyPlays();

  factory _DailyPlays.fromJson(Map<dynamic, dynamic> json) => _DailyPlays()
    ..used = (json['used'] as num?)?.toInt() ?? 0
    ..bonus = (json['bonus'] as num?)?.toInt() ?? 0
    ..ads = (json['ads'] as num?)?.toInt() ?? 0;

  int used = 0;
  int bonus = 0;
  int ads = 0;

  Map<String, int> toJson() => {'used': used, 'bonus': bonus, 'ads': ads};
}
