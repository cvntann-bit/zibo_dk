// HiddenBadgeProvider'ın "Gece Kuşu"/"Erken Kuş" gün-sayaçlarını doğrudan
// (widget pump'lamadan) test eder — `AppStreakProvider`'ın enjekte edilebilir
// saat deseniyle AYNI ruhta, ama BİLEREK `TrustedTimeProvider` DEĞİL, cihazın
// kendi saatini simüle eden düz bir `DateTime Function()` kullanıyor (bkz.
// provider'ın kendi "BİLEREK cihaz saati" dokümantasyonu).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/hidden_badge_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HiddenBadgeProvider', () {
    late DateTime currentDateTime;
    late HiddenBadgeProvider provider;

    setUp(() async {
      currentDateTime = DateTime(2026, 1, 5, 12); // öğlen — hiçbir pencerede
      provider = HiddenBadgeProvider(now: () => currentDateTime);
      await Future<void>.delayed(Duration.zero);
    });

    test('Yeni provider iki sayaç da 0 ile başlar', () {
      expect(provider.nightOwlDaysCount, 0);
      expect(provider.earlyBirdDaysCount, 0);
    });

    test(
      'Gündüz saatlerinde (pencerelerin DIŞINDA) çağrı hiçbir sayacı '
      'artırmaz',
      () {
        for (final hour in [5, 8, 9, 12, 18, 23]) {
          currentDateTime = DateTime(2026, 1, 5, hour);
          provider.recordOpenForCurrentTime();
        }

        expect(provider.nightOwlDaysCount, 0);
        expect(provider.earlyBirdDaysCount, 0);
      },
    );

    test(
      'Gece yarısı-05:00 arası (00-04) HER saat nightOwlDaysCount\'u '
      'artırır',
      () {
        for (final hour in [0, 1, 2, 3, 4]) {
          currentDateTime = DateTime(2026, 1, 5 + hour, hour);
          provider.recordOpenForCurrentTime();
        }

        expect(provider.nightOwlDaysCount, 5);
        expect(provider.earlyBirdDaysCount, 0);
      },
    );

    test('06:00-08:00 arası (06-07) HER saat earlyBirdDaysCount\'u artırır', () {
      for (final hour in [6, 7]) {
        currentDateTime = DateTime(2026, 1, 5 + hour, hour);
        provider.recordOpenForCurrentTime();
      }

      expect(provider.earlyBirdDaysCount, 2);
      expect(provider.nightOwlDaysCount, 0);
    });

    test('Saat TAM 05:00 VE TAM 08:00 hiçbir sayacı artırmaz (aralık kapalı)', () {
      currentDateTime = DateTime(2026, 1, 5, 5);
      provider.recordOpenForCurrentTime();
      currentDateTime = DateTime(2026, 1, 5, 8);
      provider.recordOpenForCurrentTime();

      expect(provider.nightOwlDaysCount, 0);
      expect(provider.earlyBirdDaysCount, 0);
    });

    test(
      'AYNI GÜN içinde pencerede birden fazla açılış sayacı YALNIZCA BİR '
      'KEZ artırır (gün-bazlı dedup, trivial gaming koruması)',
      () {
        currentDateTime = DateTime(2026, 1, 5, 1);
        provider.recordOpenForCurrentTime();
        currentDateTime = DateTime(2026, 1, 5, 2);
        provider.recordOpenForCurrentTime();
        currentDateTime = DateTime(2026, 1, 5, 4);
        provider.recordOpenForCurrentTime();

        expect(provider.nightOwlDaysCount, 1);
      },
    );

    test('30 FARKLI gecede açılınca nightOwlDaysCount 30 olur', () {
      for (var i = 0; i < 30; i++) {
        currentDateTime = DateTime(2026, 1, 1 + i, 2);
        provider.recordOpenForCurrentTime();
      }

      expect(provider.nightOwlDaysCount, 30);
    });

    test('notifyListeners yalnızca GERÇEK bir değişiklikte tetiklenir', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      currentDateTime = DateTime(2026, 1, 5, 2);
      provider.recordOpenForCurrentTime();
      expect(notifyCount, 1);

      provider.recordOpenForCurrentTime(); // aynı gün — no-op
      expect(notifyCount, 1);

      currentDateTime = DateTime(2026, 1, 5, 14); // pencere dışı — no-op
      provider.recordOpenForCurrentTime();
      expect(notifyCount, 1);
    });

    test(
      'Kalıcılık: her iki sayaç da yeniden başlatmada hatırlanır',
      () async {
        currentDateTime = DateTime(2026, 1, 5, 2);
        provider.recordOpenForCurrentTime();
        currentDateTime = DateTime(2026, 1, 6, 7);
        provider.recordOpenForCurrentTime();

        final reloaded = HiddenBadgeProvider(now: () => currentDateTime);
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.nightOwlDaysCount, 1);
        expect(reloaded.earlyBirdDaysCount, 1);
      },
    );

    test('isReady, yükleme tamamlanınca true olur', () {
      expect(provider.isReady, isTrue);
    });
  });
}
