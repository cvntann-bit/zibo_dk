// CostumeProvider'ın sahiplik/giyme mantığını, SharedPreferences üzerinden
// kalıcılığını ve ÇOK ESKİ iki-anahtarlı yerel formattan yeni birleşik
// biçime göçünü doğrudan (widget pump'lamadan) test eder. Firestore'a göç
// mantığının kendisi `cloud_state_store_test.dart`'ta ayrıca ve kapsamlı
// şekilde test ediliyor — burada tekrarlanmıyor.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/goal.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider hiçbir kostüme sahip değildir, hiçbiri giyili değildir', () async {
    final provider = CostumeProvider();
    await Future<void>.delayed(Duration.zero); // _loadFromPrefs tamamlansın

    expect(provider.ownedIds, isEmpty);
    expect(provider.equippedId, isNull);
    expect(provider.isOwned('zibo_hippi'), isFalse);
    expect(provider.isEquipped('zibo_hippi'), isFalse);
  });

  test('markOwned bir kostümü sahiplenilmiş yapar', () async {
    final provider = CostumeProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.markOwned('zibo_hippi');

    expect(provider.isOwned('zibo_hippi'), isTrue);
    expect(provider.isOwned('zibo_sporcu'), isFalse);
  });

  test('Sahip olunmayan bir kostüm giyilemez', () async {
    final provider = CostumeProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.toggleEquipped('zibo_hippi');

    expect(provider.equippedId, isNull);
    expect(provider.isEquipped('zibo_hippi'), isFalse);
  });

  test(
    'toggleEquipped sahip olunan bir kostümü giydirir, tekrar çağrılınca çıkarır',
    () async {
      final provider = CostumeProvider();
      await Future<void>.delayed(Duration.zero);
      await provider.markOwned('zibo_hippi');

      await provider.toggleEquipped('zibo_hippi');
      expect(provider.equippedId, 'zibo_hippi');
      expect(provider.isEquipped('zibo_hippi'), isTrue);

      await provider.toggleEquipped('zibo_hippi');
      expect(provider.equippedId, isNull);
      expect(provider.isEquipped('zibo_hippi'), isFalse);
    },
  );

  test('Farklı bir kostüm giyilince öncekinin yerini alır', () async {
    final provider = CostumeProvider();
    await Future<void>.delayed(Duration.zero);
    await provider.markOwned('zibo_hippi');
    await provider.markOwned('zibo_sporcu');

    await provider.toggleEquipped('zibo_hippi');
    await provider.toggleEquipped('zibo_sporcu');

    expect(provider.equippedId, 'zibo_sporcu');
    expect(provider.isEquipped('zibo_hippi'), isFalse);
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni CostumeProvider) sahiplik ve giyili kostüm hatırlanır',
    () async {
      final provider = CostumeProvider();
      await Future<void>.delayed(Duration.zero);
      await provider.markOwned('zibo_hippi');
      await provider.toggleEquipped('zibo_hippi');

      final restarted = CostumeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(restarted.isOwned('zibo_hippi'), isTrue);
      expect(restarted.equippedId, 'zibo_hippi');
    },
  );

  test(
    'ÇOK ESKİ iki-anahtarlı yerel format (ownedCostumeIds/equippedCostumeId) '
    'tanınıp yeni birleşik biçime göç ettirilir',
    () async {
      SharedPreferences.setMockInitialValues({
        'ownedCostumeIds': ['zibo_hippi', 'zibo_sporcu'],
        'equippedCostumeId': 'zibo_hippi',
      });

      final provider = CostumeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isOwned('zibo_hippi'), isTrue);
      expect(provider.isOwned('zibo_sporcu'), isTrue);
      expect(provider.equippedId, 'zibo_hippi');
    },
  );

  group('reconcileGoalUnlocks (2026 — kostümler hedefle de ücretsiz açılır)', () {
    late DateTime currentDate;
    late CostumeProvider costumeProvider;
    late GoalsProvider goalsProvider;
    late WaterProvider waterProvider;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      costumeProvider = CostumeProvider();
      await Future<void>.delayed(Duration.zero);
      goalsProvider = GoalsProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);
      goalsProvider.addGoal('Test hedefi');
      waterProvider = WaterProvider(now: () => currentDate);
    });

    test('Hiçbir eşiğe ulaşılmamışsa hiçbir kostüm açılmaz', () {
      final unlocked = costumeProvider.reconcileGoalUnlocks(
        goalsProvider,
        waterProvider,
      );

      expect(unlocked, isEmpty);
      expect(costumeProvider.isOwned('zibo_hippi'), isFalse);
    });

    test(
      'goalStreak eşiğine (zibo_hippi, 3 gün) ulaşılınca kostüm otomatik açılır',
      () {
        final goal = goalsProvider.goals.first;
        for (var day = 0; day < 3; day++) {
          goalsProvider.toggleToday(goal.id);
          if (day < 2) {
            currentDate = currentDate.add(const Duration(days: 1));
            goalsProvider.reconcileForToday();
          }
        }
        expect(goalsProvider.longestStreak, 3);

        final unlocked = costumeProvider.reconcileGoalUnlocks(
          goalsProvider,
          waterProvider,
        );

        expect(unlocked, ['zibo_hippi']);
        expect(costumeProvider.isOwned('zibo_hippi'), isTrue);
      },
    );

    test(
      'goalCompletions eşiğine (zibo_asker, 1 tamamlanan döngü) ulaşılınca '
      'kostüm otomatik açılır',
      () {
        final goal = goalsProvider.goals.first;
        for (var day = 0; day < Goal.daysPerCycle; day++) {
          goalsProvider.toggleToday(goal.id);
          if (day < Goal.daysPerCycle - 1) {
            currentDate = currentDate.add(const Duration(days: 1));
            goalsProvider.reconcileForToday();
          }
        }
        expect(goalsProvider.completions, hasLength(1));

        final unlocked = costumeProvider.reconcileGoalUnlocks(
          goalsProvider,
          waterProvider,
        );

        expect(unlocked, contains('zibo_asker'));
        expect(costumeProvider.isOwned('zibo_asker'), isTrue);
      },
    );

    test(
      'waterDaysCompleted eşiğine (zibo_sporcu, 5 gün) ulaşılınca kostüm '
      'otomatik açılır',
      () {
        for (var day = 0; day < 5; day++) {
          for (var i = 0; i < waterProvider.goalUnitCount; i++) {
            waterProvider.incrementUnit();
          }
          if (day < 4) currentDate = currentDate.add(const Duration(days: 1));
        }
        expect(waterProvider.completedDaysCount, 5);

        final unlocked = costumeProvider.reconcileGoalUnlocks(
          goalsProvider,
          waterProvider,
        );

        expect(unlocked, contains('zibo_sporcu'));
        expect(costumeProvider.isOwned('zibo_sporcu'), isTrue);
      },
    );

    test('Zaten sahip olunan bir kostüm tekrar "yeni açıldı" olarak dönmez', () async {
      await costumeProvider.markOwned('zibo_hippi');

      final goal = goalsProvider.goals.first;
      for (var day = 0; day < 3; day++) {
        goalsProvider.toggleToday(goal.id);
        if (day < 2) {
          currentDate = currentDate.add(const Duration(days: 1));
          goalsProvider.reconcileForToday();
        }
      }

      final unlocked = costumeProvider.reconcileGoalUnlocks(
        goalsProvider,
        waterProvider,
      );

      expect(unlocked, isEmpty); // zaten sahipti, tekrar "açıldı" sayılmadı
    });
  });
}
