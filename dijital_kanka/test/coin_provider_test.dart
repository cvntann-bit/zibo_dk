// CoinProvider.purchaseCoinPackage'ı doğrudan (widget pump'lamadan) test
// eder: başarılı satın alma bakiyeyi paket miktarı kadar artırmalı.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/coin_packages.dart';
import 'package:dijital_kanka/models/coin_economy.dart';
import 'package:dijital_kanka/models/coin_package.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/services/ad_service.dart';
import 'package:dijital_kanka/services/purchase_service.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';

/// Hangi ses efektinin kaç kez çağrıldığını sayan sahte servis —
/// `home_screen_sound_test.dart`'taki `_RecordingSoundEffectsService` ile
/// AYNI amaç, burada `_earn`/`purchaseCoinPackage` ayrımını doğrulamak için.
class _RecordingSoundEffectsService extends SoundEffectsService {
  int rewardCallCount = 0;
  int purchaseCallCount = 0;
  int costumeBuyCallCount = 0;
  int themeBuyCallCount = 0;

  @override
  Future<void> playZiboTap() async {}

  @override
  Future<void> playCoinReward() async => rewardCallCount++;

  @override
  Future<void> playCoinPurchase() async => purchaseCallCount++;

  @override
  Future<void> playGoalComplete() async {}

  @override
  Future<void> playCostumeBuy() async => costumeBuyCallCount++;

  @override
  Future<void> playThemeBuy() async => themeBuyCallCount++;

  @override
  Future<void> playWaterDrop() async {}

  @override
  Future<void> playBadgeWin() async {}

  @override
  void dispose() {}
}

class _FailingPurchaseService extends PurchaseService {
  const _FailingPurchaseService();

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async => false;
}

/// Gerçek `InAppPurchasePurchaseService`'in platform-kanalı-bağımlı iki
/// özelliğini (canlı fiyat sorgusu + yetim satın alma teslimi) sahte olarak
/// simüle eder — `orphanedPurchaseProductIds` stream'ine `emitOrphaned(...)`
/// ile elle bir olay ENJEKTE edilebilir.
class _OrphanedPurchaseService extends PurchaseService {
  _OrphanedPurchaseService({this.livePrice});

  final String? livePrice;
  final _controller = StreamController<String>.broadcast();

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async => false;

  @override
  Future<String?> queryLocalizedPrice(CoinPackage package) async => livePrice;

  @override
  Stream<String> get orphanedPurchaseProductIds => _controller.stream;

  void emitOrphaned(String productId) => _controller.add(productId);
}

/// Reklamın hiç tamamlanmadığı/kullanıcının erken kapattığı senaryoyu
/// simüle eder — `MockAdService`'in tersi (her zaman `false`).
class _RejectingAdService extends AdService {
  const _RejectingAdService();

  @override
  Future<bool> showRewardedAd() async => false;

  @override
  Future<bool> showInterstitialAd() async => false;
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

    test('Bonus\'lu bir paket satın alınca bakiyeye miktar + bonus eklenir', () async {
      final provider = CoinProvider();
      final bonusPackage = coinPackages.firstWhere((p) => p.id == 'coins_1000');
      expect(bonusPackage.bonusCoins, greaterThan(0));

      final success = await provider.purchaseCoinPackage(bonusPackage);

      expect(success, isTrue);
      expect(provider.balance, bonusPackage.totalCoins);
      expect(
        provider.balance,
        bonusPackage.coinAmount + bonusPackage.bonusCoins,
      );
    });
  });

  group('CoinProvider - gerçek IAP: canlı fiyat + yetim satın alma teslimi', () {
    test(
      'queryLocalizedPrice, PurchaseService.queryLocalizedPrice sonucuna geçer',
      () async {
        final provider = CoinProvider(
          purchaseService: _OrphanedPurchaseService(livePrice: '₺19,99'),
        );
        const package = CoinPackage(
          id: 'coins_100',
          coinAmount: 100,
          imageAsset: 'assets/images/zibo_coin.png',
        );

        final price = await provider.queryLocalizedPrice(package);

        expect(price, '₺19,99');
      },
    );

    test(
      'Yetim (bir önceki oturumdan kalan) satın alma coin\'i geç de olsa teslim eder',
      () async {
        final service = _OrphanedPurchaseService();
        final provider = CoinProvider(purchaseService: service);
        expect(provider.balance, 0);

        service.emitOrphaned('coins_100'); // gerçek bir coinPackages id'si
        await Future<void>.delayed(Duration.zero);

        // coins_100 = 100 temel + 10 bonus (bkz. CoinPackage.totalCoins).
        expect(provider.balance, 110);
        expect(provider.totalEarned, 110);
      },
    );

    test('Bilinmeyen bir ürün id\'si için yetim olay sessizce yok sayılır', () async {
      final service = _OrphanedPurchaseService();
      final provider = CoinProvider(purchaseService: service);

      service.emitOrphaned('bilinmeyen_urun');
      await Future<void>.delayed(Duration.zero);

      expect(provider.balance, 0);
    });
  });

  group('CoinProvider - kazanma/satın alma sesleri', () {
    const package = CoinPackage(
      id: 'coins_500',
      coinAmount: 500,
      imageAsset: 'assets/images/zibo_coin.png',
    );

    test(
      'Kazanma mekanikleri (check-in, referral, çark) playCoinReward çalar, playCoinPurchase ÇALMAZ',
      () {
        final sound = _RecordingSoundEffectsService();
        final provider = CoinProvider(soundEffectsService: sound);

        provider.earnDailyCheckIn();
        provider.earnReferral();

        expect(sound.rewardCallCount, 2);
        expect(sound.purchaseCallCount, 0);
      },
    );

    test(
      'Satın alma playCoinPurchase çalar, playCoinReward ÇALMAZ',
      () async {
        final sound = _RecordingSoundEffectsService();
        final provider = CoinProvider(soundEffectsService: sound);

        await provider.purchaseCoinPackage(package);

        expect(sound.purchaseCallCount, 1);
        expect(sound.rewardCallCount, 0);
      },
    );

    test('isSoundEnabled false iken hiçbir ses efekti çalınmaz', () async {
      final sound = _RecordingSoundEffectsService();
      final provider = CoinProvider(
        soundEffectsService: sound,
        isSoundEnabled: () => false,
      );

      provider.earnDailyCheckIn();
      await provider.purchaseCoinPackage(package);
      provider.earnReferral();
      provider.spendOnCostume(costumeName: 'Test Kostüm', cost: 50);
      provider.spendOnTheme(themeName: 'Test Tema', cost: 50);

      expect(sound.rewardCallCount, 0);
      expect(sound.purchaseCallCount, 0);
      expect(sound.costumeBuyCallCount, 0);
      expect(sound.themeBuyCallCount, 0);
    });

    test(
      'Kostüm satın alma playCostumeBuy çalar, diğer üç ses ÇALMAZ',
      () {
        final sound = _RecordingSoundEffectsService();
        final provider = CoinProvider(soundEffectsService: sound);
        provider.earnReferral(); // yeterli bakiye (100 ZC)
        sound.rewardCallCount = 0; // yukarıdaki earnReferral'ın kendi sesini sıfırla

        final success = provider.spendOnCostume(
          costumeName: 'Test Kostüm',
          cost: 50,
        );

        expect(success, true);
        expect(sound.costumeBuyCallCount, 1);
        expect(sound.themeBuyCallCount, 0);
        expect(sound.rewardCallCount, 0);
        expect(sound.purchaseCallCount, 0);
      },
    );

    test(
      'Tema satın alma playThemeBuy çalar, diğer üç ses ÇALMAZ',
      () {
        final sound = _RecordingSoundEffectsService();
        final provider = CoinProvider(soundEffectsService: sound);
        provider.earnReferral();
        sound.rewardCallCount = 0;

        final success = provider.spendOnTheme(
          themeName: 'Test Tema',
          cost: 50,
        );

        expect(success, true);
        expect(sound.themeBuyCallCount, 1);
        expect(sound.costumeBuyCallCount, 0);
        expect(sound.rewardCallCount, 0);
        expect(sound.purchaseCallCount, 0);
      },
    );

    test(
      'Bakiye yetersizken kostüm/tema satın alma başarısız olur, HİÇBİR ses çalmaz',
      () {
        final sound = _RecordingSoundEffectsService();
        final provider = CoinProvider(soundEffectsService: sound);

        final costumeSuccess = provider.spendOnCostume(
          costumeName: 'Test Kostüm',
          cost: 50,
        );
        final themeSuccess = provider.spendOnTheme(
          themeName: 'Test Tema',
          cost: 50,
        );

        expect(costumeSuccess, false);
        expect(themeSuccess, false);
        expect(sound.costumeBuyCallCount, 0);
        expect(sound.themeBuyCallCount, 0);
      },
    );
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

  group('CoinProvider - günlük reklam hakları (Şans Çarkı + Ücretsiz coin)', () {
    test(
      'Şans Çarkı günde en fazla maxDailyWheelSpins kez reklamla çevrilebilir',
      () async {
        final provider = CoinProvider(now: () => DateTime(2026, 8, 17));

        for (var i = 0; i < CoinProvider.maxDailyWheelSpins; i++) {
          expect(provider.canSpinWheelToday, isTrue);
          final prize = await provider.watchAdAndSpinWheel();
          expect(prize, isNotNull);
        }

        expect(provider.canSpinWheelToday, isFalse);
        expect(provider.remainingWheelSpinsToday, 0);
        final extraPrize = await provider.watchAdAndSpinWheel();
        expect(extraPrize, isNull);
      },
    );

    test(
      'Reklam karşılığı coin kazanma günde en fazla maxDailyAdWatches kez '
      'mümkün',
      () async {
        final provider = CoinProvider(now: () => DateTime(2026, 8, 17));

        for (var i = 0; i < CoinProvider.maxDailyAdWatches; i++) {
          final rewarded = await provider.earnAdWatch();
          expect(rewarded, isTrue);
        }

        expect(provider.canWatchAdForCoinsToday, isFalse);
        final extraRewarded = await provider.earnAdWatch();
        expect(extraRewarded, isFalse);
        expect(
          provider.balance,
          CoinEconomy.adWatch * CoinProvider.maxDailyAdWatches,
        );
      },
    );

    test(
      'Reklam yüklenemez/erken kapatılırsa (kullanıcı ödülü kazanmazsa) '
      'günlük hak tüketilmez',
      () async {
        final provider = CoinProvider(
          adService: const _RejectingAdService(),
          now: () => DateTime(2026, 8, 17),
        );

        final rewarded = await provider.earnAdWatch();
        expect(rewarded, isFalse);
        expect(
          provider.remainingAdWatchesToday,
          CoinProvider.maxDailyAdWatches,
        );

        final prize = await provider.watchAdAndSpinWheel();
        expect(prize, isNull);
        expect(
          provider.remainingWheelSpinsToday,
          CoinProvider.maxDailyWheelSpins,
        );
      },
    );

    test(
      'Gün değişince Şans Çarkı ve reklam hakları sıfırlanır (cihaz saatine '
      'değil enjekte edilen [now]a bağlı)',
      () async {
        var currentDate = DateTime(2026, 8, 17);
        final provider = CoinProvider(now: () => currentDate);

        for (var i = 0; i < CoinProvider.maxDailyWheelSpins; i++) {
          await provider.watchAdAndSpinWheel();
        }
        for (var i = 0; i < CoinProvider.maxDailyAdWatches; i++) {
          await provider.earnAdWatch();
        }
        expect(provider.canSpinWheelToday, isFalse);
        expect(provider.canWatchAdForCoinsToday, isFalse);

        currentDate = DateTime(2026, 8, 18); // ertesi gün

        expect(provider.canSpinWheelToday, isTrue);
        expect(provider.canWatchAdForCoinsToday, isTrue);
        expect(
          provider.remainingWheelSpinsToday,
          CoinProvider.maxDailyWheelSpins,
        );
        expect(
          provider.remainingAdWatchesToday,
          CoinProvider.maxDailyAdWatches,
        );

        final prize = await provider.watchAdAndSpinWheel();
        expect(prize, isNotNull);
      },
    );

    test(
      'Günlük sayaçlar kalıcı depoya yazılır; uygulama yeniden başlatılsa '
      'bile (AYNI gün) hatırlanır',
      () async {
        final fixedNow = DateTime(2026, 8, 17);
        final firstLaunch = CoinProvider(now: () => fixedNow);
        await firstLaunch.watchAdAndSpinWheel();
        await firstLaunch.earnAdWatch();
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = CoinProvider(now: () => fixedNow);
        await Future<void>.delayed(Duration.zero);

        expect(
          secondLaunch.remainingWheelSpinsToday,
          CoinProvider.maxDailyWheelSpins - 1,
        );
        expect(
          secondLaunch.remainingAdWatchesToday,
          CoinProvider.maxDailyAdWatches - 1,
        );
      },
    );
  });

  group('CoinProvider - earnStreak7Bonus haftalık tavan (coin farming koruması)', () {
    test(
      'İLK çağrı her zaman ödül verir (kullanıcı yeni açtı, henüz hiç '
      'ödül almadı)',
      () {
        final provider = CoinProvider(now: () => DateTime(2026, 8, 17));
        provider.earnStreak7Bonus();
        expect(provider.balance, CoinEconomy.streak7Bonus);
      },
    );

    test(
      'AYNI hafta içinde İKİNCİ (VE ÜÇÜNCÜ) çağrı — ör. 10 hedef açıp '
      'hepsini aynı gün tamamlamayı simüle ediyor — ekstra ödül VERMEZ',
      () {
        final provider = CoinProvider(now: () => DateTime(2026, 8, 17));
        provider.earnStreak7Bonus(); // 1. hedef
        provider.earnStreak7Bonus(); // 2. hedef, AYNI gün
        provider.earnStreak7Bonus(); // 3. hedef, AYNI gün

        expect(provider.balance, CoinEconomy.streak7Bonus);
      },
    );

    test(
      '7 günden AZ bir süre sonra (ör. ertesi gün başka bir hedef '
      'tamamlanınca) HÂLÂ ekstra ödül VERMEZ',
      () {
        var currentDate = DateTime(2026, 8, 17);
        final provider = CoinProvider(now: () => currentDate);
        provider.earnStreak7Bonus();

        currentDate = DateTime(2026, 8, 22); // 5 gün sonra
        provider.earnStreak7Bonus();

        expect(provider.balance, CoinEconomy.streak7Bonus);
      },
    );

    test(
      'TAM 7 gün geçince (rolling pencere) bir SONRAKİ hedef tamamlaması '
      'yeniden ödül verir',
      () {
        var currentDate = DateTime(2026, 8, 17);
        final provider = CoinProvider(now: () => currentDate);
        provider.earnStreak7Bonus();

        currentDate = DateTime(2026, 8, 24); // TAM 7 gün sonra
        provider.earnStreak7Bonus();

        expect(provider.balance, CoinEconomy.streak7Bonus * 2);
      },
    );

    test(
      'Sınır kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(AYNI hafta içinde) hatırlanır',
      () async {
        final fixedNow = DateTime(2026, 8, 17);
        final firstLaunch = CoinProvider(now: () => fixedNow);
        firstLaunch.earnStreak7Bonus();
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = CoinProvider(now: () => fixedNow);
        await Future<void>.delayed(Duration.zero);
        secondLaunch.earnStreak7Bonus();

        expect(secondLaunch.balance, CoinEconomy.streak7Bonus);
      },
    );
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

  group('CoinProvider - Level/XP Sistemi (onXpEarned kancası)', () {
    test('Coin kazanan HER mekanik kazanılan ZC kadar XP kancasını tetikler', () {
      final earnedXp = <int>[];
      final provider = CoinProvider(onXpEarned: earnedXp.add);

      provider.earnDailyCheckIn();
      provider.earnGratitudeJournal();

      expect(earnedXp, [CoinEconomy.dailyCheckIn, CoinEconomy.gratitudeJournal]);
    });

    test('purchaseCoinPackage (gerçek parayla satın alma) XP VERMEZ', () async {
      final earnedXp = <int>[];
      final provider = CoinProvider(
        purchaseService: const MockPurchaseService(),
        onXpEarned: earnedXp.add,
      );
      const package = CoinPackage(
        id: 'coins_100',
        coinAmount: 100,
        imageAsset: 'assets/images/zibo_coin.png',
      );

      await provider.purchaseCoinPackage(package);

      expect(earnedXp, isEmpty);
    });

    test('onXpEarned verilmezse (varsayılan) hiçbir şey çökmez', () {
      final provider = CoinProvider();
      expect(() => provider.earnDailyCheckIn(), returnsNormally);
    });
  });

  group('CoinProvider - Instagram Takip Ödülü', () {
    test('earnInstagramFollowReward sabit 100 ZC kazandırır', () {
      final provider = CoinProvider();
      provider.earnInstagramFollowReward();
      expect(provider.balance, CoinEconomy.instagramFollowReward);
      expect(provider.balance, 100);
    });
  });
}
