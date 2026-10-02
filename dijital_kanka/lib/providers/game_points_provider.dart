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

  /// Sahibin elle verdiği "sınırsız oyun hakkı" hediyesi — yalnızca sunucu
  /// tarafı yönetim betiği (`notification-scripts/src/grantGift.js`) bu alanı
  /// `gamePointsState.unlimitedPlays = true` olarak yazar; uygulama içinden
  /// hiçbir yol bunu AÇMAZ. Açıkken günlük hak sayacı tüketilmez, reklamla ek
  /// hak teklif edilmez.
  bool _unlimitedPlays = false;
  bool get unlimitedPlays => _unlimitedPlays;

  /// Sınırsız modda oyunun arayüzüne bildirilen sabit hak sayısı (HTML
  /// oyunlar "N hak kaldı" yazıyor — ∞ yerine büyük, sabit bir sayı).
  static const unlimitedPlaysDisplay = 99;

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
    if (_unlimitedPlays) return unlimitedPlaysDisplay;
    return config.playsFor(tier) + _playsOf(gameId).bonus;
  }

  int playsLeft(String gameId, String tier, GamesConfig config) {
    if (_unlimitedPlays) return unlimitedPlaysDisplay;
    final left = maxPlays(gameId, tier, config) - _playsOf(gameId).used;
    return left < 0 ? 0 : left;
  }

  /// Reklamla +1 hak alınabilir mi? Yalnızca ücretsiz üyelikte (Pro/Pro+
  /// zaten daha çok hak alıyor, reklam görmüyor) ve günlük sınır dolmadıysa.
  bool canAdForPlay(String gameId, String tier, GamesConfig config) {
    _roll();
    if (_unlimitedPlays) return false;
    return tier == 'free' && _playsOf(gameId).ads < config.maxAdPlaysPerGame;
  }

  /// Bir tur başlatır; hak yoksa `false`.
  bool consumePlay(String gameId, String tier, GamesConfig config) {
    if (_unlimitedPlays) return true;
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

  // --- Takas Gişesi (Faz 3) -------------------------------------------

  /// [tier] üyeliğine açık basamaklar (sırayla).
  List<ExchangeStep> ladderFor(String tier, GamesConfig config) =>
      config.exchangeLadder.where((s) => s.openFor(tier)).toList();

  /// Bu üyelikle haftada alınabilecek en fazla ZC.
  int weeklyCap(String tier, GamesConfig config) =>
      ladderFor(tier, config).fold(0, (sum, s) => sum + s.zc);

  /// Bu hafta daha kaç ZC alınabilir (puandan bağımsız).
  int weeklyRoom(String tier, GamesConfig config) {
    final room = weeklyCap(tier, config) - weekExchanged;
    return room < 0 ? 0 : room;
  }

  /// [zc] kadar ZC almanın ★ bedeli (bu haftanın basamaklarından devam
  /// ederek). Haftalık tavanı aşıyorsa `null`.
  int? costFor(int zc, String tier, GamesConfig config) {
    if (zc <= 0) return 0;
    var cost = 0, pos = weekExchanged, left = zc, base = 0;
    for (final step in ladderFor(tier, config)) {
      final end = base + step.zc;
      if (left > 0 && pos < end) {
        final take = (end - pos) < left ? end - pos : left;
        cost += take * step.rate;
        pos += take;
        left -= take;
      }
      base = end;
    }
    return left > 0 ? null : cost;
  }

  /// Mevcut ★ ile bu hafta alınabilecek en fazla ZC.
  int maxAffordable(String tier, GamesConfig config) {
    var n = 0;
    final room = weeklyRoom(tier, config);
    while (n < room) {
      final c = costFor(n + 1, tier, config);
      if (c == null || c > _points) break;
      n++;
    }
    return n;
  }

  /// Şu anki basamağın kuru (1 ZC kaç ★). Tavan dolduysa `null`.
  int? currentRate(String tier, GamesConfig config) {
    var base = 0;
    for (final step in ladderFor(tier, config)) {
      if (weekExchanged < base + step.zc) return step.rate;
      base += step.zc;
    }
    return null;
  }

  /// Takası uygular: bedel ★'dan düşülür, haftalık sayaç artar. Başarılıysa
  /// ödenen ★ bedelini, değilse `null` döner. ZC'yi çağıran taraf
  /// (`CoinProvider.earnGameExchange`) ekler.
  int? exchange(int zc, String tier, GamesConfig config) {
    _roll();
    final cost = costFor(zc, tier, config);
    if (zc <= 0 || cost == null || cost > _points) return null;
    _points -= cost;
    _weekExchanged += zc;
    _changed();
    return cost;
  }

  /// Takas kurunun sıfırlanmasına kalan gün (pazartesi 00:00'a; 1-7).
  int get daysUntilWeekReset => 8 - _today.weekday;

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
        _unlimitedPlays = data['unlimitedPlays'] == true;
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
      // Yalnızca açıkken yazılır — `set` belgeyi bütünüyle değiştirdiği için
      // yazılmazsa sunucudan verilen hediye bir sonraki kayıtta SİLİNİRDİ.
      if (_unlimitedPlays) 'unlimitedPlays': true,
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
