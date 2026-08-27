// WaterProvider'ın günlük ilerleme/hedef mantığını doğrudan (widget
// pump'lamadan) test eder: birim işaretleme hedefte durmalı, geri alma
// çalışmalı, gün değişince sayaç sıfırlanmalı (ama dünkü kayıt kaybolmamalı),
// birim (bardak/şişe) + ml ayarı + litre hedefi doğru çalışmalı ve kayıtlar
// kalıcı olmalı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/water_entry.dart';
import 'package:dijital_kanka/providers/water_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WaterProvider', () {
    late DateTime currentDate;
    late WaterProvider provider;

    setUp(() {
      currentDate = DateTime(2026, 1, 5);
      provider = WaterProvider(now: () => currentDate);
    });

    test(
      'Yeni provider bugün 0/8 bardak (varsayılan hedef, 250ml) ile başlar',
      () {
        expect(provider.unit, WaterUnit.glass);
        expect(provider.glassMl, 250);
        expect(provider.bottleMl, 500);
        expect(provider.goalMl, 2000);
        expect(provider.goalUnitCount, 8);
        expect(provider.todayCount, 0);
        expect(provider.isTodayComplete, isFalse);
        expect(provider.todayEntry, isNull);
        expect(provider.history, isEmpty);
      },
    );

    test('incrementUnit sayaç arttırır, hedefe ulaşana kadar false döner', () {
      for (var i = 0; i < 7; i++) {
        final justCompleted = provider.incrementUnit();
        expect(justCompleted, isFalse);
      }
      expect(provider.todayCount, 7);
      expect(provider.isTodayComplete, isFalse);
    });

    test('Tam hedefe ulaşan dokunuş true döner, sonrasında sayaç artmaz', () {
      for (var i = 0; i < 7; i++) {
        provider.incrementUnit();
      }
      final completingTap = provider.incrementUnit();
      expect(completingTap, isTrue);
      expect(provider.todayCount, 8);
      expect(provider.isTodayComplete, isTrue);

      // Hedef tamamlandıktan sonraki dokunuş bir şey yapmaz.
      final extraTap = provider.incrementUnit();
      expect(extraTap, isFalse);
      expect(provider.todayCount, 8);
    });

    test(
      'Hedefi doldurup boşaltıp tekrar doldurmak coin ödülünü İKİNCİ KEZ '
      'vermez (coin farming koruması)',
      () {
        for (var i = 0; i < 7; i++) {
          provider.incrementUnit();
        }
        expect(provider.incrementUnit(), isTrue); // 8. birim: ilk ödül
        expect(provider.isTodayRewardClaimed, isTrue);

        provider.decrementUnit(); // 7'ye düş
        expect(provider.isTodayRewardClaimed, isTrue); // ödül durumu KORUNUR

        final secondCompletion = provider.incrementUnit(); // tekrar 8'e çık
        expect(secondCompletion, isFalse);
        expect(provider.isTodayRewardClaimed, isTrue);
      },
    );

    test(
      'Ödül alındıktan sonra hedef yükseltilip yeniden tamamlansa bile '
      'aynı gün tekrar ödül verilmez',
      () async {
        for (var i = 0; i < 8; i++) {
          provider.incrementUnit();
        }
        expect(provider.isTodayRewardClaimed, isTrue);

        await provider.setGoalUnitCount(10); // 8/10 artık tamamlanmamış
        expect(provider.isTodayComplete, isFalse);
        expect(provider.isTodayRewardClaimed, isTrue); // hâlâ korunuyor

        provider.incrementUnit(); // 9
        final reCompletion = provider.incrementUnit(); // 10 — yeni hedef
        expect(reCompletion, isFalse);
      },
    );

    test('Gün değişince ödül durumu da sıfırlanır, yeni gün yeniden kazanabilir', () {
      for (var i = 0; i < 8; i++) {
        provider.incrementUnit();
      }
      expect(provider.isTodayRewardClaimed, isTrue);

      currentDate = DateTime(2026, 1, 6);
      expect(provider.isTodayRewardClaimed, isFalse);

      for (var i = 0; i < 7; i++) {
        provider.incrementUnit();
      }
      expect(provider.incrementUnit(), isTrue); // yeni günde tekrar kazanılabilir
    });

    test('decrementUnit sayaç azaltır, 0 altına inmez', () {
      provider.incrementUnit();
      provider.incrementUnit();
      provider.decrementUnit();
      expect(provider.todayCount, 1);

      provider.decrementUnit();
      provider.decrementUnit(); // zaten 0, etkisi olmamalı
      expect(provider.todayCount, 0);
    });

    test('setGoalUnitCount hedefi güncel birimin ml değeriyle çarpıp ml cinsinden saklar', () async {
      await provider.setGoalUnitCount(10);
      expect(provider.goalUnitCount, 10);
      expect(provider.goalMl, 2500);
    });

    test('setUnit birimi değiştirir, hedef ml cinsinden sabit kalır', () async {
      await provider.setGoalUnitCount(8); // 8 bardak = 2000ml
      expect(provider.goalMl, 2000);

      await provider.setUnit(WaterUnit.bottle); // şişe varsayılan 500ml
      expect(provider.unit, WaterUnit.bottle);
      expect(provider.goalMl, 2000); // ml sabit kaldı
      expect(provider.goalUnitCount, 4); // 2000 / 500
    });

    test('setGlassMl/setBottleMl birim başına ml değerini 50-2000 aralığına sabitler', () async {
      await provider.setGlassMl(300);
      expect(provider.glassMl, 300);

      await provider.setGlassMl(10); // alt sınırın altında
      expect(provider.glassMl, 50);

      await provider.setBottleMl(5000); // üst sınırın üstünde
      expect(provider.bottleMl, 2000);
    });

    test('Gün değişince sayaç sıfırlanır, dünkü kayıt geçmişte kalır', () {
      provider.incrementUnit();
      provider.incrementUnit();
      provider.incrementUnit();
      expect(provider.todayCount, 3);

      currentDate = DateTime(2026, 1, 6); // ertesi gün

      expect(provider.todayCount, 0);
      expect(provider.isTodayComplete, isFalse);
      // Ama dünkü kayıt geçmiş listesinde hâlâ duruyor.
      expect(provider.history, hasLength(1));
      expect(provider.history.first.unitCount, 3);
      expect(provider.history.first.date, DateTime(2026, 1, 5));
      expect(provider.history.first.isCompleted, isFalse);

      provider.incrementUnit();
      expect(provider.todayCount, 1);
      expect(provider.history, hasLength(1)); // bugünün kaydı history'de DEĞİL
    });

    test('Hedefi tamamlayan bir gün geçmişte isCompleted=true olarak görünür', () {
      for (var i = 0; i < 8; i++) {
        provider.incrementUnit();
      }
      currentDate = DateTime(2026, 1, 6);

      expect(provider.history, hasLength(1));
      expect(provider.history.first.isCompleted, isTrue);
    });

    test(
      'Kayıt kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni WaterProvider) hatırlanır',
      () async {
        final firstLaunch = WaterProvider(now: () => currentDate);
        firstLaunch.incrementUnit();
        firstLaunch.incrementUnit();
        await firstLaunch.setUnit(WaterUnit.bottle);
        await firstLaunch.setGoalUnitCount(6);
        // Kalıcı depoya yazma asenkron (bkz. _save) — yeni provider'ı
        // oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = WaterProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.todayCount, 2);
        expect(secondLaunch.unit, WaterUnit.bottle);
        expect(secondLaunch.goalUnitCount, 6);
      },
    );

    test(
      'Eski (birim/ml kavramından önceki) kayıtlı veri doğru okunur',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'waterState',
          '{"goalGlasses": 10, "entries": ['
          '{"date": "2026-01-04T00:00:00.000", "glassCount": 5, "goalGlasses": 10, "rewardClaimed": false}'
          ']}',
        );

        final migrated = WaterProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(migrated.unit, WaterUnit.glass);
        expect(migrated.goalMl, 2500); // 10 * 250
        expect(migrated.goalUnitCount, 10);
        expect(migrated.history, hasLength(1));
        expect(migrated.history.first.unitCount, 5);
      },
    );

    test(
      'completedDaysCount — 2026 güncellemesi (kostüm mağazasının "hedefle '
      'ücretsiz aç" özelliği için): yalnızca hedefe ULAŞILAN günleri sayar, '
      'yarım kalan günler hariç',
      () {
        expect(provider.completedDaysCount, 0);

        // Gün 1 (2026-01-05): tam hedef (8/8) — sayılır.
        for (var i = 0; i < 8; i++) {
          provider.incrementUnit();
        }
        // Gün 2 (2026-01-06): tam hedef — sayılır.
        currentDate = currentDate.add(const Duration(days: 1));
        for (var i = 0; i < 8; i++) {
          provider.incrementUnit();
        }
        // Gün 3 (2026-01-07): yarım kalmış — SAYILMAZ.
        currentDate = currentDate.add(const Duration(days: 1));
        for (var i = 0; i < 4; i++) {
          provider.incrementUnit();
        }

        expect(provider.completedDaysCount, 2);
      },
    );
  });
}
