// BadgeProvider'ın İstikrar Rozetleri kazanma/kalıcılık mantığını doğrudan
// (widget pump'lamadan) test eder — DailyRewardsProvider/GoalsProvider'ın
// enjekte edilebilir saat deseniyle AYNI ruhta, ama bu provider saat almıyor
// (bkz. `reconcileConsistencyBadges`'in girdileri zaten dışarıdan hesaplanmış
// saf değerler — `hasCompletedFirstGoalCycle`/`appOpenStreak`).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/utils/badge_celebration_signal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // `pendingBadgePopup` global bir ValueNotifier — testler arasında
    // sızmasın diye her testten önce sıfırlanıyor (`AdFreePromoTrigger.
    // resetForTest()`/`switchToUid` ile AYNI "paylaşılan global sinyali
    // izole et" gerekçesi).
    pendingBadgePopup.value = null;
  });

  group('BadgeProvider', () {
    late BadgeProvider provider;

    setUp(() async {
      provider = BadgeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    test('Yeni provider hiçbir rozet kazanmamış başlar', () {
      expect(provider.isEarned('first_step'), isFalse);
      expect(provider.isEarned('week_streak'), isFalse);
      expect(provider.isReady, isTrue);
    });

    test('Eşik dolmadan hiçbir rozet kazanılmaz', () {
      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: false,
        appOpenStreak: 3,
      );

      expect(provider.isEarned('first_step'), isFalse);
      expect(provider.isEarned('week_streak'), isFalse);
      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'hasCompletedFirstGoalCycle true olunca İlk Adım kazanılır + kutlama '
      'sinyali ayarlanır',
      () {
        provider.reconcileConsistencyBadges(
          hasCompletedFirstGoalCycle: true,
          appOpenStreak: 0,
        );

        expect(provider.isEarned('first_step'), isTrue);
        expect(provider.isClaimed('first_step'), isFalse);
        expect(pendingBadgePopup.value?.id, 'first_step');
      },
    );

    test('appOpenStreak >= 7 iken 1 Haftalık Seri kazanılır', () {
      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: false,
        appOpenStreak: 7,
      );

      expect(provider.isEarned('week_streak'), isTrue);
      expect(pendingBadgePopup.value?.id, 'week_streak');
    });

    test(
      'appOpenStreak tek seferde 30a sıçrarsa hem week hem month kazanılır, '
      'kutlama sinyali EN SONuncuya (month_streak) ayarlanır',
      () {
        provider.reconcileConsistencyBadges(
          hasCompletedFirstGoalCycle: false,
          appOpenStreak: 30,
        );

        expect(provider.isEarned('week_streak'), isTrue);
        expect(provider.isEarned('month_streak'), isTrue);
        expect(pendingBadgePopup.value?.id, 'month_streak');
      },
    );

    test('Zaten kazanılmış bir rozet tekrar kazanılamaz/tekrar bildirmez', () {
      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: false,
        appOpenStreak: 7,
      );
      pendingBadgePopup.value = null;

      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: false,
        appOpenStreak: 7,
      );

      expect(pendingBadgePopup.value, isNull);
    });

    test('markClaimed kazanılmamış bir rozette no-op', () async {
      await provider.markClaimed('first_step');

      expect(provider.isClaimed('first_step'), isFalse);
    });

    test('markClaimed kazanılan bir rozeti kalıcı olarak claimed yapar', () async {
      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: true,
        appOpenStreak: 0,
      );

      await provider.markClaimed('first_step');

      expect(provider.isClaimed('first_step'), isTrue);
    });

    test('Kalıcılık: kazanılan + alınan rozet yeniden başlatmada hatırlanır', () async {
      provider.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: true,
        appOpenStreak: 7,
      );
      await provider.markClaimed('first_step');

      final reloaded = BadgeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(reloaded.isEarned('first_step'), isTrue);
      expect(reloaded.isClaimed('first_step'), isTrue);
      expect(reloaded.isEarned('week_streak'), isTrue);
      expect(reloaded.isClaimed('week_streak'), isFalse);
    });
  });

  group('BadgeProvider — reconcileModuleMasteryBadges', () {
    late BadgeProvider provider;

    setUp(() async {
      provider = BadgeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    void reconcile({
      int gratitude = 0,
      int water = 0,
      int mood = 0,
      int money = 0,
      int manifest = 0,
      int dream = 0,
    }) {
      provider.reconcileModuleMasteryBadges(
        gratitudeCount: gratitude,
        waterDaysCount: water,
        moodCount: mood,
        moneyCount: money,
        manifestCount: manifest,
        dreamCount: dream,
      );
    }

    test('Eşik dolmadan hiçbir modül ustalığı rozeti kazanılmaz', () {
      reconcile(gratitude: 29, water: 29, mood: 29, money: 19, manifest: 14, dream: 14);

      expect(provider.isEarned('grateful_heart'), isFalse);
      expect(provider.isEarned('water_hero'), isFalse);
      expect(provider.isEarned('mood_chronicler'), isFalse);
      expect(provider.isEarned('savings_master'), isFalse);
      expect(provider.isEarned('dreamer'), isFalse);
      expect(provider.isEarned('dream_interpreter'), isFalse);
      expect(pendingBadgePopup.value, isNull);
    });

    test('gratitudeCount >= 30 iken Şükreden Kalp kazanılır', () {
      reconcile(gratitude: 30);

      expect(provider.isEarned('grateful_heart'), isTrue);
      expect(pendingBadgePopup.value?.id, 'grateful_heart');
    });

    test('waterDaysCount >= 30 iken Su Kahramanı kazanılır', () {
      reconcile(water: 30);

      expect(provider.isEarned('water_hero'), isTrue);
      expect(pendingBadgePopup.value?.id, 'water_hero');
    });

    test('moneyCount >= 20 iken Birikim Ustası kazanılır', () {
      reconcile(money: 20);

      expect(provider.isEarned('savings_master'), isTrue);
      expect(pendingBadgePopup.value?.id, 'savings_master');
    });

    test('manifestCount >= 15 iken Hayalperest kazanılır', () {
      reconcile(manifest: 15);

      expect(provider.isEarned('dreamer'), isTrue);
      expect(pendingBadgePopup.value?.id, 'dreamer');
    });

    test('dreamCount >= 15 iken Rüya Yorumcusu kazanılır', () {
      reconcile(dream: 15);

      expect(provider.isEarned('dream_interpreter'), isTrue);
      expect(pendingBadgePopup.value?.id, 'dream_interpreter');
    });

    test(
      'Aynı reconcile çağrısında BİRDEN FAZLA rozet kazanılırsa kutlama '
      'sinyali listedeki EN SONuncuya (dream_interpreter) ayarlanır',
      () {
        reconcile(gratitude: 30, water: 30, mood: 30, money: 20, manifest: 15, dream: 15);

        expect(provider.isEarned('grateful_heart'), isTrue);
        expect(provider.isEarned('water_hero'), isTrue);
        expect(provider.isEarned('mood_chronicler'), isTrue);
        expect(provider.isEarned('savings_master'), isTrue);
        expect(provider.isEarned('dreamer'), isTrue);
        expect(provider.isEarned('dream_interpreter'), isTrue);
        expect(pendingBadgePopup.value?.id, 'dream_interpreter');
      },
    );

    test('Zaten kazanılmış bir modül ustalığı rozeti tekrar bildirmez', () {
      reconcile(gratitude: 30);
      pendingBadgePopup.value = null;

      reconcile(gratitude: 30);

      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'Kalıcılık: kazanılan modül ustalığı rozeti yeniden başlatmada '
      'hatırlanır',
      () async {
        reconcile(dream: 15);
        await provider.markClaimed('dream_interpreter');

        final reloaded = BadgeProvider();
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.isEarned('dream_interpreter'), isTrue);
        expect(reloaded.isClaimed('dream_interpreter'), isTrue);
      },
    );
  });

  group('BadgeProvider — reconcileCollectionBadges', () {
    late BadgeProvider provider;

    setUp(() async {
      provider = BadgeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    void reconcile({
      int costumeCount = 0,
      bool ownsAll = false,
      int themeCount = 0,
    }) {
      provider.reconcileCollectionBadges(
        ownedCostumeCount: costumeCount,
        ownsAllCostumes: ownsAll,
        ownedThemeCount: themeCount,
      );
    }

    test('Eşik dolmadan hiçbir koleksiyon rozeti kazanılmaz', () {
      reconcile(costumeCount: 4, themeCount: 2);

      expect(provider.isEarned('collector'), isFalse);
      expect(provider.isEarned('fashion_icon'), isFalse);
      expect(provider.isEarned('full_wardrobe'), isFalse);
      expect(provider.isEarned('theme_hunter'), isFalse);
      expect(pendingBadgePopup.value, isNull);
    });

    test('ownedCostumeCount >= 5 iken Koleksiyoncu kazanılır', () {
      reconcile(costumeCount: 5);

      expect(provider.isEarned('collector'), isTrue);
      expect(pendingBadgePopup.value?.id, 'collector');
    });

    test(
      'ownedCostumeCount >= 10 iken Koleksiyoncu VE Moda İkonu BİRLİKTE '
      'kazanılır, kutlama sinyali EN SONuncuya (fashion_icon) ayarlanır',
      () {
        reconcile(costumeCount: 10);

        expect(provider.isEarned('collector'), isTrue);
        expect(provider.isEarned('fashion_icon'), isTrue);
        expect(pendingBadgePopup.value?.id, 'fashion_icon');
      },
    );

    test('ownsAllCostumes true iken Tam Gardırop kazanılır', () {
      reconcile(ownsAll: true);

      expect(provider.isEarned('full_wardrobe'), isTrue);
      expect(pendingBadgePopup.value?.id, 'full_wardrobe');
    });

    test('ownedThemeCount >= 3 iken Tema Avcısı kazanılır', () {
      reconcile(themeCount: 3);

      expect(provider.isEarned('theme_hunter'), isTrue);
      expect(pendingBadgePopup.value?.id, 'theme_hunter');
    });

    test('Zaten kazanılmış bir koleksiyon rozeti tekrar bildirmez', () {
      reconcile(themeCount: 3);
      pendingBadgePopup.value = null;

      reconcile(themeCount: 3);

      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'Kalıcılık: kazanılan koleksiyon rozeti yeniden başlatmada hatırlanır',
      () async {
        reconcile(ownsAll: true);
        await provider.markClaimed('full_wardrobe');

        final reloaded = BadgeProvider();
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.isEarned('full_wardrobe'), isTrue);
        expect(reloaded.isClaimed('full_wardrobe'), isTrue);
      },
    );
  });

  group('BadgeProvider — reconcileLoyaltyBadges', () {
    late BadgeProvider provider;

    setUp(() async {
      provider = BadgeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    void reconcile({int totalDaysOpened = 0, int daysSinceFirstUsed = 0}) {
      provider.reconcileLoyaltyBadges(
        totalDaysOpened: totalDaysOpened,
        daysSinceFirstUsed: daysSinceFirstUsed,
      );
    }

    test('Eşik dolmadan hiçbir sadakat rozeti kazanılmaz', () {
      reconcile(totalDaysOpened: 6, daysSinceFirstUsed: 364);

      expect(provider.isEarned('first_week'), isFalse);
      expect(provider.isEarned('loyal_friend'), isFalse);
      expect(provider.isEarned('anniversary'), isFalse);
      expect(pendingBadgePopup.value, isNull);
    });

    test('totalDaysOpened >= 7 iken İlk Hafta kazanılır', () {
      reconcile(totalDaysOpened: 7);

      expect(provider.isEarned('first_week'), isTrue);
      expect(pendingBadgePopup.value?.id, 'first_week');
    });

    test(
      'totalDaysOpened >= 100 iken İlk Hafta VE Sadık Dost BİRLİKTE '
      'kazanılır, kutlama sinyali EN SONuncuya (loyal_friend) ayarlanır',
      () {
        reconcile(totalDaysOpened: 100);

        expect(provider.isEarned('first_week'), isTrue);
        expect(provider.isEarned('loyal_friend'), isTrue);
        expect(pendingBadgePopup.value?.id, 'loyal_friend');
      },
    );

    test('daysSinceFirstUsed >= 365 iken Yıl Dönümü kazanılır', () {
      reconcile(daysSinceFirstUsed: 365);

      expect(provider.isEarned('anniversary'), isTrue);
      expect(pendingBadgePopup.value?.id, 'anniversary');
    });

    test('Zaten kazanılmış bir sadakat rozeti tekrar bildirmez', () {
      reconcile(totalDaysOpened: 7);
      pendingBadgePopup.value = null;

      reconcile(totalDaysOpened: 7);

      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'Kalıcılık: kazanılan sadakat rozeti yeniden başlatmada hatırlanır',
      () async {
        reconcile(daysSinceFirstUsed: 365);
        await provider.markClaimed('anniversary');

        final reloaded = BadgeProvider();
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.isEarned('anniversary'), isTrue);
        expect(reloaded.isClaimed('anniversary'), isTrue);
      },
    );
  });

  group('BadgeProvider — reconcileSocialBadges', () {
    late BadgeProvider provider;

    setUp(() async {
      provider = BadgeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    void reconcile({
      bool hasSharedAtLeastOnce = false,
      int successfulReferralCount = 0,
    }) {
      provider.reconcileSocialBadges(
        hasSharedAtLeastOnce: hasSharedAtLeastOnce,
        successfulReferralCount: successfulReferralCount,
      );
    }

    test('Eşik dolmadan hiçbir sosyal rozet kazanılmaz', () {
      reconcile(successfulReferralCount: 0);

      expect(provider.isEarned('first_share'), isFalse);
      expect(provider.isEarned('ambassador'), isFalse);
      expect(provider.isEarned('community_founder'), isFalse);
      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'hasSharedAtLeastOnce true olunca İlk Paylaşım kazanılır + kutlama '
      'sinyali ayarlanır',
      () {
        reconcile(hasSharedAtLeastOnce: true);

        expect(provider.isEarned('first_share'), isTrue);
        expect(pendingBadgePopup.value?.id, 'first_share');
      },
    );

    test('successfulReferralCount >= 1 iken Elçi kazanılır', () {
      reconcile(successfulReferralCount: 1);

      expect(provider.isEarned('ambassador'), isTrue);
      expect(pendingBadgePopup.value?.id, 'ambassador');
    });

    test(
      'successfulReferralCount >= 5 iken Elçi VE Topluluk Kurucusu '
      'BİRLİKTE kazanılır, kutlama sinyali EN SONuncuya '
      '(community_founder) ayarlanır',
      () {
        reconcile(successfulReferralCount: 5);

        expect(provider.isEarned('ambassador'), isTrue);
        expect(provider.isEarned('community_founder'), isTrue);
        expect(pendingBadgePopup.value?.id, 'community_founder');
      },
    );

    test('Zaten kazanılmış bir sosyal rozet tekrar bildirmez', () {
      reconcile(hasSharedAtLeastOnce: true);
      pendingBadgePopup.value = null;

      reconcile(hasSharedAtLeastOnce: true);

      expect(pendingBadgePopup.value, isNull);
    });

    test(
      'Kalıcılık: kazanılan sosyal rozet yeniden başlatmada hatırlanır',
      () async {
        reconcile(successfulReferralCount: 5);
        await provider.markClaimed('community_founder');

        final reloaded = BadgeProvider();
        await Future<void>.delayed(Duration.zero);

        expect(reloaded.isEarned('community_founder'), isTrue);
        expect(reloaded.isClaimed('community_founder'), isTrue);
      },
    );
  });
}
