// Oyun Salonu Faz 2 (docs/game_zibo.md): kalıcı ★ cüzdanı + uzaktan ayar.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/games_config.dart';
import 'package:dijital_kanka/providers/game_points_provider.dart';

void main() {
  const config = GamesConfig.defaults;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GamePointsProvider> make(DateTime Function() now) async {
    final p = GamePointsProvider(now: now);
    await p.ready;
    return p;
  }

  test('ücretsizde oyun başına günde 3 hak; Pro 5, Pro+ 8', () async {
    final p = await make(() => DateTime(2026, 9, 29, 10));
    expect(p.playsLeft('kule', 'free', config), 3);
    expect(p.playsLeft('kule', 'pro', config), 5);
    expect(p.playsLeft('kule', 'plus', config), 8);
    for (var i = 0; i < 3; i++) {
      expect(p.consumePlay('kule', 'free', config), isTrue);
    }
    expect(p.consumePlay('kule', 'free', config), isFalse);
    // Haklar oyun başına ayrı.
    expect(p.playsLeft('tren', 'free', config), 3);
  });

  test('sahibin verdiği "sınırsız hak" hediyesi: hak tükenmez, reklam teklif edilmez, kayıtta korunur', () async {
    SharedPreferences.setMockInitialValues({
      'gamePointsState': '{"points":0,"unlimitedPlays":true}',
    });
    final p = await make(() => DateTime(2026, 9, 29, 10));
    expect(p.unlimitedPlays, isTrue);
    for (var i = 0; i < 20; i++) {
      expect(p.consumePlay('kule', 'free', config), isTrue);
    }
    expect(p.playsLeft('kule', 'free', config), GamePointsProvider.unlimitedPlaysDisplay);
    expect(p.canAdForPlay('kule', 'free', config), isFalse);
    // Bir sonraki kayıt hediyeyi SİLMEMELİ (`set` belgeyi bütünüyle yazar).
    p.recordFinish('kule', claimedPoints: 10, config: config);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gamePointsState'), contains('"unlimitedPlays":true'));
    // Hediyesi olmayan kullanıcıda alan hiç yazılmaz.
    SharedPreferences.setMockInitialValues({});
    final q = await make(() => DateTime(2026, 9, 29, 10));
    q.recordFinish('kule', claimedPoints: 10, config: config);
    await Future<void>.delayed(Duration.zero);
    expect((await SharedPreferences.getInstance()).getString('gamePointsState'), isNot(contains('unlimitedPlays')));
  });

  test('reklamla ek hak yalnızca ücretsizde ve oyun başına günde en fazla 2', () async {
    final p = await make(() => DateTime(2026, 9, 29, 10));
    expect(p.canAdForPlay('kule', 'pro', config), isFalse);
    expect(p.grantAdPlay('kule', 'free', config), isTrue);
    expect(p.grantAdPlay('kule', 'free', config), isTrue);
    expect(p.grantAdPlay('kule', 'free', config), isFalse);
    expect(p.playsLeft('kule', 'free', config), 5);
  });

  test('gün değişince haklar yenilenir', () async {
    var now = DateTime(2026, 9, 29, 23, 50);
    final p = await make(() => now);
    for (var i = 0; i < 3; i++) {
      p.consumePlay('kule', 'free', config);
    }
    expect(p.playsLeft('kule', 'free', config), 0);
    now = DateTime(2026, 9, 30, 0, 5);
    expect(p.playsLeft('kule', 'free', config), 3);
  });

  test('puan tur tavanını aşamaz, negatif olamaz; bakiye ve haftalık puan artar', () async {
    final p = await make(() => DateTime(2026, 9, 29, 10));
    expect(p.recordFinish('kule', claimedPoints: 9999, config: config), 250);
    expect(p.recordFinish('tren', claimedPoints: -5, config: config), 0);
    expect(p.recordFinish('tren', claimedPoints: 40, config: config), 40);
    expect(p.points, 290);
    expect(p.weekPoints, 290);
  });

  test('rekor yalnızca daha yüksek skorla güncellenir', () async {
    final p = await make(() => DateTime(2026, 9, 29, 10));
    p.recordFinish('kule', claimedPoints: 10, score: 12, config: config);
    p.recordFinish('kule', claimedPoints: 10, score: 8, config: config);
    expect(p.best('kule'), 12);
  });

  test('pazartesi haftalık puan sıfırlanır, bakiye kalır', () async {
    var now = DateTime(2026, 10, 4, 22); // Pazar
    final p = await make(() => now);
    p.recordFinish('tren', claimedPoints: 100, config: config);
    expect(p.weekPoints, 100);
    now = DateTime(2026, 10, 5, 9); // Pazartesi
    expect(p.weekPoints, 0);
    expect(p.points, 100);
  });

  test('durum kalıcıdır (yeniden açılınca yüklenir)', () async {
    final now = DateTime(2026, 9, 29, 10);
    final first = await make(() => now);
    first.recordFinish('2048', claimedPoints: 120, score: 3400, config: config);
    first.consumePlay('2048', 'free', config);
    await Future<void>.delayed(Duration.zero);

    final second = await make(() => now);
    expect(second.points, 120);
    expect(second.best('2048'), 3400);
    expect(second.playsLeft('2048', 'free', config), 2);
  });

  group('Takas Gişesi', () {
    test('kademeli kur: ilk 20 ZC 50★, sonraki 20 ZC 100★', () async {
      final p = await make(() => DateTime(2026, 9, 29, 10));
      expect(p.costFor(20, 'free', config), 1000);
      expect(p.costFor(25, 'free', config), 1500);
      expect(p.weeklyCap('free', config), 60);
      expect(p.weeklyCap('pro', config), 80);
      expect(p.weeklyCap('plus', config), 100);
      expect(p.costFor(61, 'free', config), isNull);
    });

    test('takas ★ düşer, haftalık sayaç artar, kur ilerler; puan yetmezse olmaz', () async {
      final p = await make(() => DateTime(2026, 9, 29, 10));
      p.recordFinish('2048', claimedPoints: 600, config: config);
      p.recordFinish('tren', claimedPoints: 600, config: config); // 1200 ★
      expect(p.maxAffordable('free', config), 22); // 20×50 + 2×100
      expect(p.exchange(22, 'free', config), 1200);
      expect(p.points, 0);
      expect(p.weekExchanged, 22);
      expect(p.currentRate('free', config), 100);
      expect(p.exchange(1, 'free', config), isNull);
    });

    test('haftalık tavan dolunca daha fazla takas yok; pazartesi sıfırlanır', () async {
      var now = DateTime(2026, 10, 4, 10); // Pazar
      final p = await make(() => now);
      for (var i = 0; i < 20; i++) {
        p.recordFinish('2048', claimedPoints: 600, config: config); // 12.000 ★
      }
      expect(p.exchange(60, 'free', config), 7000);
      expect(p.weeklyRoom('free', config), 0);
      expect(p.maxAffordable('free', config), 0);
      expect(p.exchange(1, 'free', config), isNull);
      // Pro basamakları hâlâ açık.
      expect(p.weeklyRoom('pro', config), 20);
      now = DateTime(2026, 10, 5, 9); // Pazartesi
      expect(p.weekExchanged, 0);
      expect(p.maxAffordable('free', config), 50); // kalan 5.000 ★ = 20×50 + 20×100 + 10×200
    });

    test('bozuk exchangeLadder yok sayılır, geçerlisi uygulanır', () {
      expect(GamesConfig.fromJson({'exchangeLadder': [{'zc': 'x'}]}).exchangeLadder.length, 5);
      final c = GamesConfig.fromJson({
        'exchangeLadder': [
          {'zc': 10, 'rate': 80},
          {'zc': 10, 'rate': 150, 'minTier': 'pro'},
        ],
      });
      expect(c.exchangeLadder.length, 2);
      expect(c.exchangeLadder[1].openFor('free'), isFalse);
      expect(c.exchangeLadder[1].openFor('plus'), isTrue);
    });
  });

  group('GamesConfig.fromJson', () {
    test('Firestore alanları varsayılanların üstüne yazılır, bozuklar yok sayılır', () {
      final c = GamesConfig.fromJson({
        'dailyPlays': {'free': 2, 'pro': 'çok'},
        'maxAdPlaysPerGame': 1,
        'games': {
          'tren': {'perCoin': 3, 'cap': 300, 'label': 'yok say'},
          'kule': {'enabled': false},
        },
      });
      expect(c.playsFor('free'), 2);
      expect(c.playsFor('pro'), 5);
      expect(c.maxAdPlaysPerGame, 1);
      expect(c.gameConfig('tren'), {'perCoin': 3, 'cap': 300});
      expect(c.capOf('tren'), 300);
      expect(c.isEnabled('kule'), isFalse);
      expect(c.gameConfig('kule'), {'perFloor': 2, 'perfectBonus': 1, 'cap': 250});
      expect(c.isEnabled('hafiza'), isTrue);
    });

    test('doküman yoksa varsayılanlar', () {
      final c = GamesConfig.fromJson(null);
      expect(c.capOf('yakala'), 400);
      expect(c.playsFor('plus'), 8);
    });
  });
}
