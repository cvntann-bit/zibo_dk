// CostumeProvider'ın sahiplik/giyme mantığını, SharedPreferences üzerinden
// kalıcılığını ve ÇOK ESKİ iki-anahtarlı yerel formattan yeni birleşik
// biçime göçünü doğrudan (widget pump'lamadan) test eder. Firestore'a göç
// mantığının kendisi `cloud_state_store_test.dart`'ta ayrıca ve kapsamlı
// şekilde test ediliyor — burada tekrarlanmıyor.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/costume_provider.dart';

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

}
