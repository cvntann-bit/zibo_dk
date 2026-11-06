// Zibo Dünyası Faz 1 (docs/zibo_world_roadmap.md): ev ayarları, ihtiyaçlar
// (tembel düşüş, taban, gerçek zamanlı uyku, günlük ücretsiz yemek) ve dekor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/home_catalog.dart';
import 'package:dijital_kanka/data/home_config.dart';
import 'package:dijital_kanka/data/zibo_world_lines.dart';
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

    test('Pro\'ya özel ve sezonluk eşyalar uzaktan tanımlanır', () {
      final c = HomeConfig.fromJson({
        'proOnly': ['salon:kanepe:altin'],
        'limited': {
          'salon:duvar:cam': {'from': '2026-12-01', 'to': '2026-12-31'},
          'bozuk': {'from': 'x'},
        },
      });
      expect(c.isProOnly('salon:kanepe:altin'), isTrue);
      expect(c.isProOnly('salon:kanepe:mavi'), isFalse);
      expect(c.isLimited('salon:duvar:cam'), isTrue);
      expect(c.isLimited('bozuk'), isFalse);
      expect(c.isOnSale('salon:duvar:cam', DateTime(2026, 11, 30, 23)), isFalse);
      expect(c.isOnSale('salon:duvar:cam', DateTime(2026, 12, 1, 0, 1)), isTrue);
      expect(c.isOnSale('salon:duvar:cam', DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(c.isOnSale('salon:duvar:cam', DateTime(2027, 1, 1)), isFalse);
      expect(c.isOnSale('salon:kanepe:mavi', DateTime(2027, 1, 1)), isTrue);
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

    test('rozet sayaçları: besleme/yıkama, bakım günü günde 1, uyku yalnız %30+ enerjiyle', () async {
      final p = await make();
      p.recordFeed();
      p.recordFeed();
      p.recordBath();
      expect(p.feedCount, 2);
      expect(p.bathCount, 1);
      expect(p.careDays, 1); // aynı gün tek sayılır
      clock = clock.add(const Duration(hours: 10)); // enerji düşsün
      // Kısa uyku (ışığı aç/kapa) sayılmaz.
      p.startSleep();
      clock = clock.add(const Duration(minutes: 5));
      p.wake();
      expect(p.sleepCount, 0);
      // Uzun uyku sayılır (60 dk = %100 hız).
      p.startSleep();
      clock = clock.add(const Duration(minutes: 40));
      p.refresh();
      p.wake();
      expect(p.sleepCount, 1);
      // Ertesi gün bakım yeni gün sayılır.
      clock = clock.add(const Duration(days: 1));
      p.recordFeed();
      expect(p.careDays, 2);
    });

    test('reklamla +1 yemek: yalnız ücretsiz kullanıcı, hak bitince, günde 2', () async {
      final p = await make();
      expect(p.adFoodsLeft, 0); // ücretsiz hak varken teklif yok
      for (var i = 0; i < 3; i++) {
        p.useFreeFood();
      }
      expect(p.adFoodsLeft, 2);
      tier = SubscriptionTier.pro;
      expect(p.adFoodsLeft, 0); // Pro'ya gösterilmez
      tier = SubscriptionTier.free;
      expect(p.grantAdFood(), isTrue);
      expect(p.freeFoodsLeft, 1);
      expect(p.adFoodsLeft, 0); // önce açılan hak kullanılır
      expect(p.useFreeFood(), isTrue);
      expect(p.adFoodsLeft, 1);
      expect(p.grantAdFood(), isTrue);
      expect(p.useFreeFood(), isTrue);
      expect(p.adFoodsLeft, 0);
      expect(p.grantAdFood(), isFalse);
      clock = DateTime(2026, 11, 3, 0, 1);
      expect(p.freeFoodsLeft, 3);
      for (var i = 0; i < 3; i++) {
        p.useFreeFood();
      }
      expect(p.adFoodsLeft, 2); // yeni gün, yeni hak
    });
  });

  test('katalog çevirisi: her eşya, kategori, yemek ve sabunun EN/ES adı var', () {
    for (final def in homeRooms) {
      for (final c in def.categories) {
        expect(c.nameEn, isNotEmpty, reason: c.nameTr);
        expect(c.nameEs, isNotEmpty, reason: c.nameTr);
        for (final it in c.items) {
          expect(it.nameEn, isNotEmpty, reason: it.nameTr);
          expect(it.nameEs, isNotEmpty, reason: it.nameTr);
        }
      }
    }
    for (final f in homeFoods) {
      expect(f.nameEn, isNotEmpty, reason: f.nameTr);
      expect(f.nameEs, isNotEmpty, reason: f.nameTr);
    }
    for (final sp in homeSoaps) {
      expect(sp.nameEn, isNotEmpty, reason: sp.nameTr);
      expect(sp.nameEs, isNotEmpty, reason: sp.nameTr);
    }
    final apple = homeFoods.firstWhere((f) => f.id == 'red_apple');
    expect(apple.nameFor('tr'), 'Elma');
    expect(apple.nameFor('en'), 'Apple');
    expect(apple.nameFor('es'), 'Manzana');
    expect(apple.nameFor('de'), 'Elma');
  });

  group('HomeDecorProvider', () {
    test('Ev Dekoratörü sayacı: yalnız satın alınanlar, etkinlik ödülü sayılmaz', () async {
      final p = HomeDecorProvider();
      await p.ready;
      p.markOwned(HomeRoom.kitchen, 'boya', 'gok');
      p.markOwned(HomeRoom.living, 'boya', 'gok', bought: false);
      expect(p.purchasedDecorCount, 1);
      expect(p.isOwned(HomeRoom.living, 'boya', 'gok'), isTrue);
    });

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

  group('Konuşma balonu cümleleri', () {
    test('üç dilde her ihtiyaç için aynı sayıda cümle', () {
      for (final need in HomeNeed.values) {
        final n = ziboWorldNeedLinesTr[need]!.length;
        expect(ziboWorldNeedLinesEn[need]!.length, n);
        expect(ziboWorldNeedLinesEs[need]!.length, n);
      }
      expect(ziboWorldHappyLinesEn.length, ziboWorldHappyLinesTr.length);
      expect(ziboWorldHappyLinesEs.length, ziboWorldHappyLinesTr.length);
    });

    test('dile göre seçilir, bilinmeyen dil Türkçe', () {
      expect(ziboWorldLineForLocale(const Locale('en'), HomeNeed.hunger, 0), ziboWorldNeedLinesEn[HomeNeed.hunger]![0]);
      expect(ziboWorldLineForLocale(const Locale('de'), null, 4), ziboWorldHappyLinesTr[4 % ziboWorldHappyLinesTr.length]);
    });
  });
}
