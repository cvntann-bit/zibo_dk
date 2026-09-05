// InstagramFollowProvider'ın tek seferlik "ödül alındı" bayrağını doğrudan
// (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/instagram_follow_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider ödül alınmamış olarak başlar', () async {
    final provider = InstagramFollowProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.claimed, isFalse);
  });

  test('markClaimed İLK çağrıda true döner ve durumu kalıcı olarak günceller', () async {
    final provider = InstagramFollowProvider();
    await Future<void>.delayed(Duration.zero);

    final result = await provider.markClaimed();

    expect(result, isTrue);
    expect(provider.claimed, isTrue);
  });

  test('markClaimed İKİNCİ çağrıda false döner (tekrar ödül verilmez)', () async {
    final provider = InstagramFollowProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.markClaimed();
    final secondAttempt = await provider.markClaimed();

    expect(secondAttempt, isFalse);
  });

  test(
    'claimed durumu kalıcı depoya yazılır; yeniden başlatmada hatırlanır',
    () async {
      final firstLaunch = InstagramFollowProvider();
      await Future<void>.delayed(Duration.zero);
      await firstLaunch.markClaimed();

      final secondLaunch = InstagramFollowProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.claimed, isTrue);
      // Yeniden başlatma sonrası ikinci bir talep de reddedilmeli.
      expect(await secondLaunch.markClaimed(), isFalse);
    },
  );
}
