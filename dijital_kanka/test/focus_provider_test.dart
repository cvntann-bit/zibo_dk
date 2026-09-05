// FocusProvider'ın oturum kaydetme/toplam süre hesaplama mantığını doğrudan
// (widget pump'lamadan) test eder — `DreamJournalProvider`/`GoalsProvider`
// testleriyle AYNI enjekte edilebilir saat deseni.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/focus_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FocusProvider', () {
    late DateTime currentDate;
    late FocusProvider provider;

    setUp(() {
      currentDate = DateTime(2026, 4, 1, 10);
      provider = FocusProvider(now: () => currentDate);
    });

    test('Yeni provider hiç oturum olmadan, sıfır toplam süreyle başlar', () {
      expect(provider.sessions, isEmpty);
      expect(provider.totalFocusSeconds, 0);
    });

    test('60 saniyeden kısa bir oturum reddedilir', () {
      final saved = provider.addSession(30);
      expect(saved, isFalse);
      expect(provider.sessions, isEmpty);
    });

    test('60 saniye veya daha uzun bir oturum kaydedilir', () {
      final saved = provider.addSession(90);
      expect(saved, isTrue);
      expect(provider.sessions, hasLength(1));
      expect(provider.sessions.first.durationSeconds, 90);
      expect(provider.sessions.first.date, currentDate);
    });

    test('Birden fazla oturum BİRİKİR (üzerine yazılmaz), en yeni en üstte', () {
      provider.addSession(120);
      currentDate = DateTime(2026, 4, 2, 9);
      provider.addSession(300);

      expect(provider.sessions, hasLength(2));
      expect(provider.sessions.first.durationSeconds, 300); // en yeni önce
      expect(provider.sessions.last.durationSeconds, 120);
    });

    test('totalFocusSeconds tüm oturumların toplamı', () {
      provider.addSession(60);
      provider.addSession(180);
      expect(provider.totalFocusSeconds, 240);
    });

    test(
      'Oturumlar kalıcı depoya yazılır; uygulama yeniden başlatılsa bile hatırlanır',
      () async {
        final firstLaunch = FocusProvider(now: () => currentDate);
        firstLaunch.addSession(600);
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = FocusProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.sessions, hasLength(1));
        expect(secondLaunch.totalFocusSeconds, 600);
      },
    );
  });
}
