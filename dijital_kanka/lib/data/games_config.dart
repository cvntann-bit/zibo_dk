/// Oyun Salonu'nun TÜM rakamları tek yerde (bkz. `docs/game_zibo.md`).
///
/// Buradaki değerler VARSAYILAN'dır. Firestore'daki `config/games`
/// dokümanı (Firebase konsolundan elle düzenlenir) varsa onun alanları bu
/// varsayılanların ÜSTÜNE yazılır — böylece puan oranı, tur tavanı, günlük
/// hak gibi rakamlar uygulama güncellemesi OLMADAN değişir. Doküman yoksa,
/// okunamazsa ya da bir alan eksik/bozuksa varsayılana düşülür.
///
/// `config/games` doküman şekli (hepsi isteğe bağlı):
/// ```json
/// {
///   "dailyPlays": {"free": 3, "pro": 5, "plus": 8},
///   "maxAdPlaysPerGame": 2,
///   "games": {
///     "tren": {"perCoin": 5, "cap": 600, "enabled": true},
///     ...
///   }
/// }
/// ```
/// Bir oyunun `"enabled": false` olması onu Oyun Salonu'nda "Yakında"ya
/// çevirir (acil kapatma anahtarı).
class GamesConfig {
  const GamesConfig({
    required this.dailyPlays,
    required this.maxAdPlaysPerGame,
    required this.games,
  });

  /// Üyelik seviyesine göre oyun BAŞINA günlük hak ('free' / 'pro' / 'plus').
  final Map<String, int> dailyPlays;

  /// Ücretsiz kullanıcının oyun başına günde reklamla alabileceği ek hak.
  final int maxAdPlaysPerGame;

  /// Oyun kimliği → oyuna `ziboInit` ile giden rakamlar (her birinde `cap`).
  final Map<String, Map<String, Object>> games;

  /// Oyun Salonu'ndaki sıra da budur.
  static const gameIds = ['kule', 'hafiza', '2048', 'yakala', 'tren', 'tugla', 'zipla'];

  static const defaults = GamesConfig(
    dailyPlays: {'free': 3, 'pro': 5, 'plus': 8},
    maxAdPlaysPerGame: 2,
    games: {
      // Kat × 2 + mükemmel × 1 (kullanıcı kararı 2026-09-27).
      'kule': {'perFloor': 2, 'perfectBonus': 1, 'cap': 250},
      // Seviye tabanı × yıldız çarpanı; hamle limiti dolarsa 0.
      'hafiza': {'ptsEasy': 100, 'ptsMid': 180, 'ptsHard': 300, 'mult2': 0.6, 'mult1': 0.3, 'cap': 300},
      // Skor ÷ 20 + en yüksek kostüm bonusu; geri alma sınırı.
      '2048': {'scoreDiv': 20, 'bonus256': 50, 'bonus1024': 100, 'bonus2048': 200, 'cap': 600, 'maxUndo': 3},
      // 1 skor = 1 ★ (kullanıcı kararı 2026-09-27); can biterse 0.
      'yakala': {'perScore': 1, 'cap': 400},
      // Coin × 5 (kullanıcı kararı 2026-09-27).
      'tren': {'perCoin': 5, 'cap': 600},
      // Kırılan tuğla × 1 (kullanıcı kararı 2026-09-27).
      'tugla': {'perBrick': 1, 'cap': 400},
      // Yalnızca coin × 5; sütunlar rekor için (kullanıcı kararı 2026-09-27).
      'zipla': {'perCoin': 5, 'cap': 600},
    },
  );

  /// Oyuna giden rakamlar ('enabled' anahtarı çıkarılmış).
  Map<String, Object> gameConfig(String gameId) {
    final raw = games[gameId] ?? const <String, Object>{};
    return {
      for (final e in raw.entries)
        if (e.key != 'enabled') e.key: e.value,
    };
  }

  bool isEnabled(String gameId) => games.containsKey(gameId) && games[gameId]!['enabled'] != false;

  /// Tur tavanı — oyundan gelen puan bunu ASLA aşamaz.
  int capOf(String gameId) => (games[gameId]?['cap'] as num?)?.toInt() ?? 0;

  int playsFor(String tier) => dailyPlays[tier] ?? dailyPlays['free'] ?? 3;

  /// Firestore dokümanını varsayılanların üstüne uygular. Yalnızca sayı ve
  /// bool değerler kabul edilir; tanınmayan/bozuk alanlar yok sayılır.
  factory GamesConfig.fromJson(Map<String, dynamic>? json, {GamesConfig base = defaults}) {
    if (json == null) return base;
    final plays = Map<String, int>.of(base.dailyPlays);
    final rawPlays = json['dailyPlays'];
    if (rawPlays is Map) {
      rawPlays.forEach((k, v) {
        if (k is String && v is num && v >= 0) plays[k] = v.toInt();
      });
    }
    final maxAd = json['maxAdPlaysPerGame'];
    final games = {
      for (final e in base.games.entries) e.key: Map<String, Object>.of(e.value),
    };
    final rawGames = json['games'];
    if (rawGames is Map) {
      rawGames.forEach((id, fields) {
        if (id is! String || fields is! Map) return;
        final target = games.putIfAbsent(id, () => <String, Object>{});
        fields.forEach((k, v) {
          if (k is String && (v is num || v is bool)) target[k] = v as Object;
        });
      });
    }
    return GamesConfig(
      dailyPlays: plays,
      maxAdPlaysPerGame: maxAd is num && maxAd >= 0 ? maxAd.toInt() : base.maxAdPlaysPerGame,
      games: games,
    );
  }
}
