// DailyRewardsProvider'ın 7 günlük döngü mantığını (gerçek takvim
// tarihine bağlı) doğrudan (widget pump'lamadan) test eder — GoalsProvider'ın
// tek-hedef döngü testleriyle aynı desen (enjekte edilebilir saat).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/coin_economy.dart';
import 'package:dijital_kanka/providers/daily_rewards_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyRewardsProvider', () {
    late DateTime currentDate;
    late DailyRewardsProvider provider;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      provider = DailyRewardsProvider(now: () => currentDate);
      // Constructor'daki `_cycleStartDate` alan başlatıcısı gerçek
      // `DateTime.now()`'u kullanıyor (enjekte edilen saat DEĞİL) — doğru
      // değer yalnızca asenkron `_loadFromPrefs` tamamlanınca (enjekte
      // edilen saate göre) atanıyor. `GoalsProvider`/`WaterProvider`
      // testlerindeki aynı gotcha.
      await Future<void>.delayed(Duration.zero);
    });

    test('Yeni provider Gün 1 ile başlar, bugün henüz alınmamıştır', () {
      expect(provider.isTodayClaimed, isFalse);
      expect(provider.todayIndex, 0);
      expect(provider.todayAmount, CoinEconomy.dailyLoginRewards[0]);
      expect(provider.statusForIndex(0), DailyRewardDayStatus.today);
      for (var i = 1; i < 7; i++) {
        expect(provider.statusForIndex(i), DailyRewardDayStatus.upcoming);
      }
    });

    test('claimToday Gün 1 ödülünü verir ve bugünü kilitler', () {
      final amount = provider.claimToday();

      expect(amount, CoinEconomy.dailyLoginRewards[0]);
      expect(provider.isTodayClaimed, isTrue);
      expect(provider.statusForIndex(0), DailyRewardDayStatus.claimed);
    });

    test('Aynı gün ikinci claimToday çağrısı null döner, tekrar ödül vermez', () {
      provider.claimToday();

      final secondAttempt = provider.claimToday();

      expect(secondAttempt, isNull);
    });

    test('Ertesi gün Gün 2 açılır, önceki gün claimed kalır', () {
      provider.claimToday(); // Gün 1
      currentDate = DateTime(2026, 1, 6);
      provider.reconcileForToday();

      expect(provider.todayIndex, 1);
      expect(provider.statusForIndex(0), DailyRewardDayStatus.claimed);
      expect(provider.statusForIndex(1), DailyRewardDayStatus.today);
      expect(provider.todayAmount, CoinEconomy.dailyLoginRewards[1]);

      final amount = provider.claimToday();
      expect(amount, CoinEconomy.dailyLoginRewards[1]);
    });

    test('Bir gün kaçırılırsa (24 saat içinde alınmazsa) döngü Gün 1\'den yeniden başlar', () {
      provider.claimToday(); // Gün 1 (5 Ocak) alındı
      currentDate = DateTime(2026, 1, 7); // 6 Ocak (Gün 2) atlandı

      final reset = provider.reconcileForToday();

      expect(reset, isTrue);
      expect(provider.todayIndex, 0);
      expect(provider.isTodayClaimed, isFalse);
      expect(provider.statusForIndex(0), DailyRewardDayStatus.today);
      expect(provider.todayAmount, CoinEconomy.dailyLoginRewards[0]);
    });

    test('7 gün art arda alınıp döngü tamamlanınca ertesi gün otomatik olarak Gün 1\'den yeniden başlar', () {
      for (var day = 0; day < 7; day++) {
        final amount = provider.claimToday();
        expect(amount, CoinEconomy.dailyLoginRewards[day]);
        currentDate = currentDate.add(const Duration(days: 1));
        provider.reconcileForToday();
      }

      // 7 gün art arda alındı (5-11 Ocak), currentDate şimdi 12 Ocak —
      // yeni bir Gün 1 olmalı.
      expect(provider.todayIndex, 0);
      expect(provider.isTodayClaimed, isFalse);
      expect(provider.todayAmount, CoinEconomy.dailyLoginRewards[0]);

      final amount = provider.claimToday();
      expect(amount, CoinEconomy.dailyLoginRewards[0]);
    });

    test('Gün 7 alındıktan sonra AYNI gün içinde tüm kutucuklar claimed görünür', () {
      for (var day = 0; day < 7; day++) {
        provider.claimToday();
        if (day < 6) {
          currentDate = currentDate.add(const Duration(days: 1));
          provider.reconcileForToday();
        }
      }

      // Hâlâ 7. günün tarihindeyiz (currentDate hiç ilerletilmedi son
      // döngüde) — reconcile çağrılsa bile sıfırlanmamalı.
      final resetSameDay = provider.reconcileForToday();
      expect(resetSameDay, isFalse);
      for (var i = 0; i < 7; i++) {
        expect(provider.statusForIndex(i), DailyRewardDayStatus.claimed);
      }
      expect(provider.isTodayClaimed, isTrue);
    });

    test(
      'Durum kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni DailyRewardsProvider) hatırlanır',
      () async {
        provider.claimToday();
        currentDate = DateTime(2026, 1, 6);
        provider.reconcileForToday();
        provider.claimToday();
        await Future<void>.delayed(Duration.zero);

        final restarted = DailyRewardsProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(restarted.todayIndex, 1);
        expect(restarted.isTodayClaimed, isTrue);
        expect(restarted.statusForIndex(0), DailyRewardDayStatus.claimed);
        expect(restarted.statusForIndex(1), DailyRewardDayStatus.claimed);
      },
    );
  });
}
