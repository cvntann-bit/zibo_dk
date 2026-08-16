import 'package:dijital_kanka/utils/ad_free_promo_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdFreePromoTrigger', () {
    test('yüklenmeden önce (initialize çağrılmadan) hiçbir zaman true dönmez', () {
      AdFreePromoTrigger.resetForTest(loaded: false);
      for (var i = 0; i < 10; i++) {
        expect(AdFreePromoTrigger.shouldShowOnStoreVisit(), isFalse);
      }
    });

    test('cooldown yokken (hiç gösterilmemiş) tam 5. ziyarette true döner', () {
      AdFreePromoTrigger.resetForTest();
      final results = List.generate(
        5,
        (_) => AdFreePromoTrigger.shouldShowOnStoreVisit(),
      );
      expect(results, [false, false, false, false, true]);
    });

    test(
      '5. ziyarette gösterildikten SONRA, aynı oturumda 10. ziyarette '
      'cooldown dolmadığı için TEKRAR true DÖNMEZ',
      () {
        AdFreePromoTrigger.resetForTest();
        for (var i = 0; i < 5; i++) {
          AdFreePromoTrigger.shouldShowOnStoreVisit();
        }
        for (var i = 0; i < 5; i++) {
          expect(AdFreePromoTrigger.shouldShowOnStoreVisit(), isFalse);
        }
      },
    );

    test('son gösterimden 3 günden az geçtiyse eşik dolsa bile false döner', () {
      AdFreePromoTrigger.resetForTest(
        lastShownAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      for (var i = 0; i < 5; i++) {
        expect(AdFreePromoTrigger.shouldShowOnStoreVisit(), isFalse);
      }
    });

    test('son gösterimden 3 günden fazla geçtiyse eşik dolunca true döner', () {
      AdFreePromoTrigger.resetForTest(
        lastShownAt: DateTime.now().subtract(const Duration(days: 4)),
      );
      for (var i = 0; i < 4; i++) {
        expect(AdFreePromoTrigger.shouldShowOnStoreVisit(), isFalse);
      }
      expect(AdFreePromoTrigger.shouldShowOnStoreVisit(), isTrue);
    });
  });
}
