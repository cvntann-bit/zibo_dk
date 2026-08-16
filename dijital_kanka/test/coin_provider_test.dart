// CoinProvider.purchaseCoinPackage'ı doğrudan (widget pump'lamadan) test
// eder: başarılı satın alma bakiyeyi paket miktarı kadar artırmalı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/coin_package.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/services/purchase_service.dart';

class _FailingPurchaseService extends PurchaseService {
  const _FailingPurchaseService();

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async => false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CoinProvider - satın alma', () {
    const package = CoinPackage(
      id: 'coins_500',
      coinAmount: 500,
      imageAsset: 'assets/images/zibo_coin.png',
    );

    test('Başarılı satın alma paket miktarı kadar coin ekler', () async {
      final provider = CoinProvider();
      expect(provider.balance, 0);

      final success = await provider.purchaseCoinPackage(package);

      expect(success, isTrue);
      expect(provider.balance, 500);
    });

    test('Başarısız satın alma bakiyeyi değiştirmez', () async {
      final provider = CoinProvider(
        purchaseService: const _FailingPurchaseService(),
      );

      final success = await provider.purchaseCoinPackage(package);

      expect(success, isFalse);
      expect(provider.balance, 0);
    });
  });

  group('CoinProvider - ömür boyu toplamlar', () {
    test('totalEarned/totalSpent kazanma ve harcamalarla birlikte artar', () {
      final provider = CoinProvider();

      provider.earnDailyCheckIn();
      provider.earnReferral();
      expect(provider.totalEarned, 5 + 100);
      expect(provider.totalSpent, 0);

      final spent = provider.spendStreakFreeze();
      expect(spent, isTrue);
      expect(provider.totalSpent, 80);
      expect(provider.totalEarned, 5 + 100); // kazanılan toplam değişmez
    });

    test('totalEarned/totalSpent kalıcı depoya yazılır; uygulama yeniden '
        'başlatılsa bile (yeni CoinProvider) hatırlanır', () async {
      final provider = CoinProvider();
      provider.earnDailyCheckIn();
      provider.spendStreakFreeze(); // bakiye yetersiz, hiçbir şey değişmez
      provider.earnReferral();
      await Future<void>.delayed(Duration.zero);

      final secondLaunch = CoinProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.totalEarned, 5 + 100);
      expect(secondLaunch.totalSpent, 0);
    });
  });

  group('CoinProvider - kalıcılık', () {
    const package = CoinPackage(
      id: 'coins_500',
      coinAmount: 500,
      imageAsset: 'assets/images/zibo_coin.png',
    );

    test(
      'Bakiye ve işlem geçmişi kalıcı depoya yazılır; uygulama yeniden '
      'başlatılsa bile (yeni CoinProvider) hatırlanır',
      () async {
        final firstLaunch = CoinProvider();
        firstLaunch.earnDailyCheckIn();
        await firstLaunch.purchaseCoinPackage(package);
        // _record'un kalıcı depoya yazması asenkron (bkz. _save) — yeni
        // provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = CoinProvider();
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.balance, 505); // 5 (check-in) + 500 (paket)
        expect(secondLaunch.transactions, hasLength(2));
      },
    );
  });
}
