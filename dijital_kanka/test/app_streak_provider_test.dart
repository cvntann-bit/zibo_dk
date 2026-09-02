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
  });
}
