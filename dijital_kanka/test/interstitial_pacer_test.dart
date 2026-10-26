// Geçiş reklamı sıklık kuralları (2026-10-26): ilk 3 saat koruma, günde en
// fazla 2, iki gösterim arası 4 dk — ve CoinProvider'ın bu kurallara uyması.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/services/ad_service.dart';
import 'package:dijital_kanka/services/interstitial_pacer.dart';

class _CountingAdService extends AdService {
  int interstitials = 0;

  @override
  Future<bool> showRewardedAd() async => true;

  @override
  Future<bool> showInterstitialAd() async {
    interstitials++;
    return true;
  }
}

void main() {
  late DateTime clock;
  DateTime now() => clock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 10, 26, 9);
  });

  Future<InterstitialPacer> loadedPacer() async {
    final pacer = InterstitialPacer(now: now);
    await pacer.load();
    return pacer;
  }

  test('yüklenmeden önce gösterim yok', () {
    expect(InterstitialPacer(now: now).check(), InterstitialSkipReason.notReady);
  });

  test('ilk açılıştan sonraki 3 saat koruma, sonra serbest', () async {
    final pacer = await loadedPacer();
    expect(pacer.check(), InterstitialSkipReason.newUserShield);
    clock = clock.add(const Duration(hours: 2, minutes: 59));
    expect(pacer.check(), InterstitialSkipReason.newUserShield);
    clock = clock.add(const Duration(minutes: 1));
    expect(pacer.check(), isNull);
  });

  test('ilk açılış anı kalıcı — yeniden yüklemede koruma tekrar başlamaz', () async {
    await loadedPacer();
    clock = clock.add(const Duration(hours: 4));
    final reloaded = await loadedPacer();
    expect(reloaded.check(), isNull);
  });

  test('4 dk bekleme ve günde en fazla 2 gösterim; ertesi gün sıfırlanır', () async {
    final pacer = await loadedPacer();
    clock = clock.add(const Duration(hours: 3));
    await pacer.recordShown();
    expect(pacer.check(), InterstitialSkipReason.cooldown);
    clock = clock.add(const Duration(minutes: 4));
    expect(pacer.check(), isNull);
    await pacer.recordShown();
    clock = clock.add(const Duration(hours: 1));
    expect(pacer.check(), InterstitialSkipReason.dailyCap);
    expect(pacer.shownToday, 2);

    clock = DateTime(2026, 10, 27, 9);
    expect(pacer.shownToday, 0);
    expect(pacer.check(), isNull);
  });

  test('CoinProvider kurallara uyar: korumada reklam açılmaz, sonra açılır', () async {
    final ads = _CountingAdService();
    final pacer = await loadedPacer();
    final coins = CoinProvider(adService: ads, interstitialPacer: pacer, now: now);

    expect(await coins.showInterstitialAd(InterstitialPlacement.dailyReward), isFalse);
    expect(ads.interstitials, 0);

    clock = clock.add(const Duration(hours: 3));
    expect(await coins.showInterstitialAd(InterstitialPlacement.dailyReward), isTrue);
    expect(await coins.showInterstitialAd(InterstitialPlacement.journalSaved), isFalse);
    expect(ads.interstitials, 1);
    coins.dispose();
  });

  test('Pro / reklamsız kullanıcıda kural sayılmadan reklam yok', () async {
    final ads = _CountingAdService();
    final pacer = await loadedPacer();
    clock = clock.add(const Duration(hours: 5));
    final coins = CoinProvider(
      adService: ads,
      interstitialPacer: pacer,
      now: now,
      isPro: () => true,
    );
    expect(await coins.showInterstitialAd(InterstitialPlacement.goalCycle), isFalse);
    expect(ads.interstitials, 0);
    expect(pacer.shownToday, 0);
    coins.dispose();
  });
}
