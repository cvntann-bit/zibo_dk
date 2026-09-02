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
}
