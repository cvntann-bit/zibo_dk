// Zibo Dünyası Faz 1 (docs/zibo_world_roadmap.md): ev ayarları, ihtiyaçlar
// (tembel düşüş, taban, gerçek zamanlı uyku, günlük ücretsiz yemek) ve dekor.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/home_catalog.dart';
import 'package:dijital_kanka/data/home_config.dart';
import 'package:dijital_kanka/models/home_item.dart';
import 'package:dijital_kanka/models/home_need.dart';
import 'package:dijital_kanka/models/subscription_tier.dart';
import 'package:dijital_kanka/providers/home_decor_provider.dart';
import 'package:dijital_kanka/providers/home_needs_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HomeConfig', () {
    test('uzak doküman yalnızca verdiği alanları ezer', () {
      final c = HomeConfig.fromJson({
        'minLevel': 5,
        'decayPerHour': {'hunger': 10, 'bilinmeyen': 3},
        'priceOverrides': {'mutfak:boya:gok': 25},
      });
      expect(c.minLevel, 5);
      expect(c.decayPerHour[HomeNeed.hunger], 10);
      expect(c.decayPerHour[HomeNeed.fun], HomeConfig.defaults.decayPerHour[HomeNeed.fun]);
      expect(c.freeFoodsPerDay, HomeConfig.defaults.freeFoodsPerDay);
      expect(c.priceFor('mutfak:boya:gok', 40, SubscriptionTier.free), 25);
      expect(HomeConfig.fromJson(null).minLevel, HomeConfig.defaults.minLevel);
    });

    test('abonelik indirimi; bedava ürün bedava kalır', () {
      const c = HomeConfig.defaults;
      expect(c.priceFor('x', 100, SubscriptionTier.free), 100);
      expect(c.priceFor('x', 100, SubscriptionTier.pro), 90);
      expect(c.priceFor('x', 100, SubscriptionTier.proPlus), 80);
      expect(c.priceFor('x', 0, SubscriptionTier.proPlus), 0);
      expect(c.priceFor('x', 1, SubscriptionTier.proPlus), 1);
    });
  });

  group('Katalog', () {
    test('her odanın başlangıç eşyası katalogda var', () {
      expect(homeRooms.map((r) => r.room).toSet(), HomeRoom.values.toSet());
      for (final room in homeRooms) {
        for (final entry in room.defaults.entries) {
          expect(room.category(entry.key)?.item(entry.value), isNotNull, reason: '${room.room.id}:${entry.key}');
        }
      }
      expect(homeSoaps.where((s) => s.price == 0).map((s) => s.id), contains(HomeDecorProvider.defaultSoap));
    });
  });

  group('HomeNeedsProvider', () {
    late DateTime clock;
    var tier = SubscriptionTier.free;

    Future<HomeNeedsProvider> make() async {
      final p = HomeNeedsProvider(now: () => clock, tier: () => tier);
      await p.ready;
      return p;
    }

    setUp(() {
      clock = DateTime(2026, 11, 2, 9);
      tier = SubscriptionTier.free;
    });

    test('zamanla düşer, tabanın altına inmez', () async {
      final p = await make();
      expect(p.level(HomeNeed.hunger), 80);
      clock = clock.add(const Duration(hours: 5));
      expect(p.level(HomeNeed.hunger), 60); // 4/saat
      expect(p.level(HomeNeed.hygiene), 65); // 3/saat
      clock = clock.add(const Duration(days: 3));
      expect(p.level(HomeNeed.hunger), HomeConfig.defaults.minLevel);
      expect(p.lowest, HomeNeed.hunger);
    });

    test('Pro+ ihtiyaçları daha yavaş düşer', () async {
      tier = SubscriptionTier.proPlus;
      final p = await make();
      clock = clock.add(const Duration(hours: 10));
      expect(p.level(HomeNeed.hunger), 50); // 4 × 0.75 × 10
    });

    test('add düşüşü kalıcı hale getirir ve 100 ile sınırlar', () async {
      final p = await make();
      clock = clock.add(const Duration(hours: 5));
      p.add(HomeNeed.hunger, 25);
      expect(p.level(HomeNeed.hunger), 85);
      p.add(HomeNeed.hunger, 50);
      expect(p.level(HomeNeed.hunger), 100);
      clock = clock.add(const Duration(hours: 1));
      expect(p.level(HomeNeed.hunger), 96);
    });

    test('uyku gerçek zamanlı: enerji uyurken dolar, düşmez', () async {
      final p = await make();
      p.startSleep();
      expect(p.isAsleep, isTrue);
      clock = clock.add(const Duration(minutes: 6)); // 60 dk'da 0→100
      expect(p.level(HomeNeed.energy), closeTo(90, 0.001));
      clock = clock.add(const Duration(hours: 2));
      expect(p.level(HomeNeed.energy), 100);
      p.wake();
      expect(p.isAsleep, isFalse);
      expect(p.level(HomeNeed.energy), 100);
      clock = clock.add(const Duration(hours: 2));
      expect(p.level(HomeNeed.energy), 94);
    });

    test('uyku kayıttan devam eder (uygulama kapalıyken de dolar)', () async {
      final p = await make();
      p.add(HomeNeed.energy, -60); // 20
      p.startSleep();
      await Future<void>.delayed(Duration.zero);
      clock = clock.add(const Duration(minutes: 30));
      final q = await make();
      expect(q.isAsleep, isTrue);
      expect(q.level(HomeNeed.energy), closeTo(70, 0.001));
    });

    test('Pro uyku hızı', () async {
      tier = SubscriptionTier.pro;
      final p = await make();
      p.add(HomeNeed.energy, -80); // 0
      p.startSleep();
      clock = clock.add(const Duration(minutes: 20));
      expect(p.level(HomeNeed.energy), closeTo(50, 0.001)); // 1.5×
    });

    test('saat geri alınırsa değer artmaz', () async {
      final p = await make();
      clock = clock.subtract(const Duration(hours: 10));
      expect(p.level(HomeNeed.hunger), 80);
    });

    test('günlük ücretsiz yemek hakkı her gün sıfırlanır', () async {
      final p = await make();
      for (var i = 0; i < 3; i++) {
        expect(p.useFreeFood(), isTrue);
      }
      expect(p.freeFoodsLeft, 0);
      expect(p.useFreeFood(), isFalse);
      tier = SubscriptionTier.pro;
      expect(p.freeFoodsLeft, 2);
      tier = SubscriptionTier.free;
      clock = DateTime(2026, 11, 3, 0, 1);
      expect(p.freeFoodsLeft, 3);
    });
  });

  group('HomeDecorProvider', () {
    test('başlangıç eşyası takılı ve sahipli; satın alınmayan takılamaz', () async {
      final p = HomeDecorProvider();
      await p.ready;
      expect(p.equipped(HomeRoom.bath, 'boya'), 'gok');
      expect(p.isOwned(HomeRoom.bath, 'boya', 'gok'), isTrue);
      expect(p.equip(HomeRoom.kitchen, 'boya', 'gok'), isFalse);
      p.markOwned(HomeRoom.kitchen, 'boya', 'gok');
      expect(p.equip(HomeRoom.kitchen, 'boya', 'gok'), isTrue);
      expect(p.equippedItem(HomeRoom.kitchen, 'boya').id, 'gok');
      // Katalogda olmayan eşya sahiplenilmez.
      p.markOwned(HomeRoom.kitchen, 'boya', 'yok-boyle-bir-sey');
      expect(p.isOwned(HomeRoom.kitchen, 'boya', 'yok-boyle-bir-sey'), isFalse);
    });

    test('sabun bir kez alınır, seçim kayıtta kalır', () async {
      final p = HomeDecorProvider();
      await p.ready;
      expect(p.selectedSoap, HomeDecorProvider.defaultSoap);
      expect(p.selectSoap('nane'), isFalse);
      p.markSoapOwned('nane');
      expect(p.selectSoap('nane'), isTrue);
      p.markOwned(HomeRoom.living, 'boya', 'gok');
      p.equip(HomeRoom.living, 'boya', 'gok');
      await Future<void>.delayed(Duration.zero);
      final q = HomeDecorProvider();
      await q.ready;
      expect(q.selectedSoap, 'nane');
      expect(q.equipped(HomeRoom.living, 'boya'), 'gok');
    });
  });
}
