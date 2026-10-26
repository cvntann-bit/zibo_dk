// "Bugünün vitrini" 24 saatlik kostüm denemesi (2026-10-26): nadirliğe göre
// gereken video sayısı, günde bir deneme, süre bitince eski kostüme dönüş,
// satın alınınca denemenin bitmesi ve kalıcılık.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/costumes.dart';
import 'package:dijital_kanka/models/costume_rarity.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/utils/zibo_event_signal.dart';

void main() {
  late DateTime clock;
  DateTime now() => clock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingZiboEvent.value = null;
    clock = DateTime(2026, 10, 26, 10);
  });

  Future<CostumeProvider> ready() async {
    final provider = CostumeProvider(now: now);
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  String idOf(CostumeRarity rarity) =>
      costumes.firstWhere((c) => c.rarity == rarity).id;

  test('gereken video sayısı: mitik 5, efsanevi 3, epik 2, diğerleri 1', () {
    expect(CostumeProvider.trialAdsRequiredFor(CostumeRarity.mythic), 5);
    expect(CostumeProvider.trialAdsRequiredFor(CostumeRarity.legendary), 3);
    expect(CostumeProvider.trialAdsRequiredFor(CostumeRarity.epic), 2);
    expect(CostumeProvider.trialAdsRequiredFor(CostumeRarity.rare), 1);
    expect(CostumeProvider.trialAdsRequiredFor(CostumeRarity.common), 1);
  });

  test('mitik kostüm 5. videoda açılır, giydirilir ama SAHİPLİK sayılmaz', () async {
    final provider = await ready();
    final id = idOf(CostumeRarity.mythic);
    for (var i = 1; i < 5; i++) {
      expect(await provider.registerTrialAdWatched(id), isFalse);
      expect(provider.trialAdsWatched(id), i);
    }
    expect(await provider.registerTrialAdWatched(id), isTrue);
    expect(provider.isTrialActive(id), isTrue);
    expect(provider.isEquipped(id), isTrue);
    expect(provider.isOwned(id), isFalse);
    expect(provider.canWear(id), isTrue);
    expect(provider.trialRemaining, const Duration(hours: 24));
    expect(provider.canStartTrialToday, isFalse);
    provider.dispose();
  });

  test('video ilerlemesi ertesi gün sıfırlanır', () async {
    final provider = await ready();
    final id = idOf(CostumeRarity.legendary);
    await provider.registerTrialAdWatched(id);
    expect(provider.trialAdsWatched(id), 1);
    clock = DateTime(2026, 10, 27, 10);
    expect(provider.trialAdsWatched(id), 0);
    provider.dispose();
  });

  test('günde tek deneme; süre bitince önceki kostüm geri gelir ve Zibo haber verir', () async {
    final provider = await ready();
    final previous = idOf(CostumeRarity.common);
    await provider.markOwned(previous);
    await provider.toggleEquipped(previous);
    final trial = idOf(CostumeRarity.rare);

    expect(await provider.registerTrialAdWatched(trial), isTrue);
    expect(provider.equippedId, trial);
    expect(await provider.startTrial(idOf(CostumeRarity.epic)), isFalse);

    clock = clock.add(const Duration(hours: 24));
    provider.reconcileTrial();
    expect(provider.isTrialActive(trial), isFalse);
    expect(provider.canWear(trial), isFalse);
    expect(provider.equippedId, previous);
    expect(pendingZiboEvent.value, ZiboEventType.costumeTrialEnded);

    clock = DateTime(2026, 10, 27, 11);
    expect(provider.canStartTrialToday, isTrue);
    provider.dispose();
  });

  test('deneme sırasında satın alınan kostüm kalıcı olur, deneme biter', () async {
    final provider = await ready();
    final id = idOf(CostumeRarity.common);
    await provider.registerTrialAdWatched(id);
    await provider.markOwned(id);
    expect(provider.activeTrialId, isNull);
    clock = clock.add(const Duration(days: 2));
    provider.reconcileTrial();
    expect(provider.equippedId, id);
    expect(pendingZiboEvent.value, isNull);
    provider.dispose();
  });

  test('deneme yeniden açılışta korunur; kapalıyken süre dolduysa açılışta biter', () async {
    final first = await ready();
    final id = idOf(CostumeRarity.rare);
    await first.registerTrialAdWatched(id);
    first.dispose();

    final reopened = await ready();
    expect(reopened.isTrialActive(id), isTrue);
    expect(reopened.equippedId, id);
    reopened.dispose();

    clock = clock.add(const Duration(hours: 25));
    final later = await ready();
    expect(later.isTrialActive(id), isFalse);
    expect(later.equippedId, isNull);
    later.dispose();
  });

  test('vitrin kostümü sahip olunmayanlardan seçilir; deneme sürerken o kostümdür', () async {
    final provider = await ready();
    final featured = provider.featuredTrialCostume!;
    expect(provider.isOwned(featured.id), isFalse);
    await provider.registerTrialAdWatched(featured.id);
    if (CostumeProvider.trialAdsRequiredFor(featured.rarity) == 1) {
      expect(provider.featuredTrialCostume!.id, featured.id);
    }
    provider.dispose();
  });
}
