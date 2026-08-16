// AppThemeProvider'ın sahiplik/aktif tema mantığını ve SharedPreferences
// üzerinden kalıcılığını doğrudan (widget pump'lamadan) test eder —
// CostumeProvider'daki aynı desenin bire bir aynısı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/app_theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider hiçbir temaya sahip değildir, hiçbiri aktif değildir', () async {
    final provider = AppThemeProvider();
    await Future<void>.delayed(Duration.zero); // _loadFromPrefs tamamlansın

    expect(provider.ownedIds, isEmpty);
    expect(provider.equippedId, isNull);
    expect(provider.isOwned('sunset'), isFalse);
    expect(provider.isEquipped('sunset'), isFalse);
  });

  test('markOwned bir temayı sahiplenilmiş yapar', () async {
    final provider = AppThemeProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.markOwned('sunset');

    expect(provider.isOwned('sunset'), isTrue);
    expect(provider.isOwned('ocean'), isFalse);
  });

  test('Sahip olunmayan bir tema uygulanamaz', () async {
    final provider = AppThemeProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.toggleEquipped('sunset');

    expect(provider.equippedId, isNull);
    expect(provider.isEquipped('sunset'), isFalse);
  });

  test(
    'toggleEquipped sahip olunan bir temayı uygular, tekrar çağrılınca kaldırır',
    () async {
      final provider = AppThemeProvider();
      await Future<void>.delayed(Duration.zero);
      await provider.markOwned('sunset');

      await provider.toggleEquipped('sunset');
      expect(provider.equippedId, 'sunset');
      expect(provider.isEquipped('sunset'), isTrue);

      await provider.toggleEquipped('sunset');
      expect(provider.equippedId, isNull);
      expect(provider.isEquipped('sunset'), isFalse);
    },
  );

  test('Farklı bir tema uygulanınca öncekinin yerini alır', () async {
    final provider = AppThemeProvider();
    await Future<void>.delayed(Duration.zero);
    await provider.markOwned('sunset');
    await provider.markOwned('ocean');

    await provider.toggleEquipped('sunset');
    await provider.toggleEquipped('ocean');

    expect(provider.equippedId, 'ocean');
    expect(provider.isEquipped('sunset'), isFalse);
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni AppThemeProvider) sahiplik ve aktif tema hatırlanır',
    () async {
      final provider = AppThemeProvider();
      await Future<void>.delayed(Duration.zero);
      await provider.markOwned('sunset');
      await provider.toggleEquipped('sunset');

      final restarted = AppThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(restarted.isOwned('sunset'), isTrue);
      expect(restarted.equippedId, 'sunset');
    },
  );
}
