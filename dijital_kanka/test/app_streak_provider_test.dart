// AppStreakProvider'ın "uygulamayı her gün açma" serisini (gerçek takvim
// tarihine bağlı, GoalsProvider'ın per-goal döngüsünden BAĞIMSIZ) doğrudan
// (widget pump'lamadan) test eder — DailyRewardsProvider/GoalsProvider'ın
// enjekte edilebilir saat deseniyle aynı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/app_streak_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppStreakProvider', () {
    late DateTime currentDate;
    late AppStreakProvider provider;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      provider = AppStreakProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);
    });

    test('Yeni provider seri 0 ile başlar', () {
      expect(provider.currentStreak, 0);
    });

    test('İlk recordOpenForToday çağrısı seriyi 1 yapar', () {
      provider.recordOpenForToday();

      expect(provider.currentStreak, 1);
    });

    test('Aynı gün içinde tekrar çağrılması seriyi ARTIRMAZ', () {
      provider.recordOpenForToday();
      provider.recordOpenForToday();
      provider.recordOpenForToday();

      expect(provider.currentStreak, 1);
    });

    test('Ertesi gün açılınca seri +1 artar', () {
      provider.recordOpenForToday();
      currentDate = DateTime(2026, 1, 6);

      provider.recordOpenForToday();

      expect(provider.currentStreak, 2);
    });

    test('7 gün art arda açılınca seri 7 olur', () {
      for (var i = 0; i < 7; i++) {
        currentDate = DateTime(2026, 1, 5 + i);
        provider.recordOpenForToday();
      }

      expect(provider.currentStreak, 7);
    });

    test('Bir gün ATLANIRSA seri 1e sıfırlanır', () {
      provider.recordOpenForToday(); // 5 Ocak — seri 1
      currentDate = DateTime(2026, 1, 6);
      provider.recordOpenForToday(); // 6 Ocak — seri 2
      currentDate = DateTime(2026, 1, 8); // 7 Ocak ATLANDI

      provider.recordOpenForToday();

      expect(provider.currentStreak, 1);
    });

    test('notifyListeners yalnızca GERÇEK bir değişiklikte tetiklenir', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.recordOpenForToday();
      expect(notifyCount, 1);

      provider.recordOpenForToday(); // aynı gün — no-op
      expect(notifyCount, 1);
    });

    test('Kalıcılık: seri yeniden başlatmada hatırlanır', () async {
      provider.recordOpenForToday();
      currentDate = DateTime(2026, 1, 6);
      provider.recordOpenForToday();

      final reloaded = AppStreakProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);

      expect(reloaded.currentStreak, 2);
    });

    test('Yeni provider totalDaysOpened 0 ile başlar', () {
      expect(provider.totalDaysOpened, 0);
    });

    test('İlk recordOpenForToday çağrısı totalDaysOpened\'i 1 yapar', () {
      provider.recordOpenForToday();

      expect(provider.totalDaysOpened, 1);
    });

    test('Aynı gün içinde tekrar çağrılması totalDaysOpened\'i ARTIRMAZ', () {
      provider.recordOpenForToday();
      provider.recordOpenForToday();
      provider.recordOpenForToday();

      expect(provider.totalDaysOpened, 1);
    });

    test(
      'Bir gün ATLANIP seri sıfırlansa bile totalDaysOpened SIFIRLANMAZ, '
      'yalnızca artmaya devam eder (Sadakat Rozetleri — CLAUDE.md)',
      () {
        provider.recordOpenForToday(); // 5 Ocak — seri 1, toplam 1
        currentDate = DateTime(2026, 1, 6);
        provider.recordOpenForToday(); // 6 Ocak — seri 2, toplam 2
        currentDate = DateTime(2026, 1, 10); // 7-9 Ocak ATLANDI

        provider.recordOpenForToday(); // seri 1'e sıfırlanır, toplam 3 olur

        expect(provider.currentStreak, 1);
        expect(provider.totalDaysOpened, 3);
      },
    );

    test(
      '7 farklı (ARDIŞIK OLMAYAN) günde açılınca totalDaysOpened 7 olur',
      () {
        final openDays = [5, 6, 9, 10, 15, 20, 25]; // Ocak, boşluklu
        for (final day in openDays) {
          currentDate = DateTime(2026, 1, day);
          provider.recordOpenForToday();
        }

        expect(provider.totalDaysOpened, 7);
        expect(provider.currentStreak, 1); // en son gün tek başına
      },
    );

    test('Kalıcılık: totalDaysOpened yeniden başlatmada hatırlanır', () async {
      provider.recordOpenForToday();
      currentDate = DateTime(2026, 1, 10); // boşluklu — seri sıfırlanır
      provider.recordOpenForToday();

      final reloaded = AppStreakProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);

      expect(reloaded.totalDaysOpened, 2);
      expect(reloaded.currentStreak, 1);
    });

    test(
      'Göç: totalDaysOpened alanı OLMAYAN eski kayıtlı veri currentStreak\'e '
      'düşer (fazla saymaz)',
      () async {
        SharedPreferences.setMockInitialValues({
          'appStreakState': '{"lastOpenDate":"2026-01-06T00:00:00.000","currentStreak":2}',
        });

        final migrated = AppStreakProvider(now: () => DateTime(2026, 1, 6));
        await Future<void>.delayed(Duration.zero);

        expect(migrated.totalDaysOpened, 2);
      },
    );
  });

  group('AppStreakProvider — Faz 4 (B3) Streak Freeze', () {
    late DateTime currentDate;
    late AppStreakProvider provider;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      provider = AppStreakProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);
    });

    test('isStreakAtRisk: seri 0 iken (hiç açılmamış) false', () {
      expect(provider.isStreakAtRisk, isFalse);
    });

    test('isStreakAtRisk: bugün zaten kayıtlıysa false', () {
      provider.recordOpenForToday();
      expect(provider.isStreakAtRisk, isFalse);
    });

    test('isStreakAtRisk: yalnızca dün kayıtlıysa (kaçırılan gün yok) false', () {
      provider.recordOpenForToday();
      currentDate = DateTime(2026, 1, 6);
      expect(provider.isStreakAtRisk, isFalse);
    });

    test('isStreakAtRisk: TAM 1 gün kaçırılmışsa true', () {
      provider.recordOpenForToday(); // 5 Ocak
      currentDate = DateTime(2026, 1, 7); // 6 Ocak kaçırıldı

      expect(provider.isStreakAtRisk, isTrue);
    });

    test(
      'isStreakAtRisk: 2+ gün kaçırılmışsa false (Freeze tek seferde '
      'yalnızca 1 günü tamir eder)',
      () {
        provider.recordOpenForToday(); // 5 Ocak
        currentDate = DateTime(2026, 1, 8); // 6-7 Ocak kaçırıldı

        expect(provider.isStreakAtRisk, isFalse);
      },
    );

    test(
      'repairMissedDayWithFreeze: seri kırılmadan devam eder, '
      'totalDaysOpened yalnızca BUGÜN için artar',
      () {
        provider.recordOpenForToday(); // 5 Ocak — seri 1, toplam 1
        currentDate = DateTime(2026, 1, 7); // 6 Ocak kaçırıldı

        provider.repairMissedDayWithFreeze(usedFreeQuota: false);

        expect(provider.currentStreak, 2);
        expect(provider.totalDaysOpened, 2);
        expect(provider.isStreakAtRisk, isFalse);
      },
    );

    test('freeStreakFreezeQuota: free=0, pro=1, proPlus=3', () {
      final free = AppStreakProvider(now: () => currentDate);
      final pro = AppStreakProvider(now: () => currentDate, isPro: () => true);
      final proPlus = AppStreakProvider(
        now: () => currentDate,
        isPro: () => true,
        isProPlus: () => true,
      );

      expect(free.freeStreakFreezeQuota, 0);
      expect(pro.freeStreakFreezeQuota, 1);
      expect(proPlus.freeStreakFreezeQuota, 3);
    });

    test(
      'repairMissedDayWithFreeze(usedFreeQuota: true) aylık ücretsiz '
      'sayacı artırır',
      () {
        final pro = AppStreakProvider(now: () => currentDate, isPro: () => true);
        pro.recordOpenForToday();
        currentDate = DateTime(2026, 1, 7);

        expect(pro.remainingFreeStreakFreezes, 1);
        pro.repairMissedDayWithFreeze(usedFreeQuota: true);

        expect(pro.remainingFreeStreakFreezes, 0);
      },
    );

    test('Aylık kota: sıfırlama tarihi geçince sayaç sıfırlanır', () {
      final pro = AppStreakProvider(now: () => currentDate, isPro: () => true);
      pro.recordOpenForToday();
      currentDate = DateTime(2026, 1, 7);
      pro.repairMissedDayWithFreeze(usedFreeQuota: true);
      expect(pro.remainingFreeStreakFreezes, 0);

      currentDate = DateTime(2026, 2, 10); // bir ay sonrası
      expect(pro.remainingFreeStreakFreezes, 1);
    });

    test(
      'Aylık kota: kullanıcı AYLARCA açmasa bile sıfırlama doğru zincirlenir '
      '(kota BİRİKMEZ, yalnızca sıfırlanır)',
      () {
        final pro = AppStreakProvider(now: () => currentDate, isPro: () => true);
        pro.recordOpenForToday();
        currentDate = DateTime(2026, 1, 7);
        pro.repairMissedDayWithFreeze(usedFreeQuota: true);
        expect(pro.remainingFreeStreakFreezes, 0);

        currentDate = DateTime(2026, 5, 20); // 4 ay sonrası
        expect(pro.remainingFreeStreakFreezes, 1);
      },
    );

    test(
      'Kalıcılık: aylık ücretsiz sayaç ve sıfırlama tarihi yeniden '
      'başlatmada hatırlanır',
      () async {
        final pro = AppStreakProvider(now: () => currentDate, isPro: () => true);
        pro.recordOpenForToday();
        currentDate = DateTime(2026, 1, 7);
        pro.repairMissedDayWithFreeze(usedFreeQuota: true);
        await Future<void>.delayed(Duration.zero);

        final reloaded = AppStreakProvider(
          now: () => currentDate,
          isPro: () => true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.remainingFreeStreakFreezes, 0);
      },
    );
  });
}
