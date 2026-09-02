// BadgeCoordinator'ın GoalsProvider/AppStreakProvider değiştiğinde
// BadgeProvider.reconcileConsistencyBadges'i OTOMATİK tetiklediğini
// doğrudan (widget pump'lamadan) test eder — HomeWidgetSyncCoordinator
// testlerindeki "sahte/gerçek provider'ları kur, addListener'ın gerçekten
// tetiklendiğini doğrula" deseniyle aynı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/app_streak_provider.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/services/badge_coordinator.dart';
import 'package:dijital_kanka/utils/badge_celebration_signal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingBadgePopup.value = null;
  });

  group('BadgeCoordinator', () {
    late DateTime currentDate;
    late BadgeProvider badges;
    late GoalsProvider goals;
    late AppStreakProvider appStreak;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      badges = BadgeProvider();
      goals = GoalsProvider(now: () => currentDate);
      appStreak = AppStreakProvider(now: () => currentDate);
      await Future<void>.delayed(Duration.zero);
    });

    test(
      'Constructor EAGER bir ilk reconcile yapar — kuruluş anında zaten '
      'karşılanmış bir koşul hemen ödüllendirilir',
      () {
        appStreak.recordOpenForToday(); // seri 1, henüz 7 değil
        for (var i = 1; i < 7; i++) {
          currentDate = currentDate.add(const Duration(days: 1));
          appStreak.recordOpenForToday();
        }
        expect(appStreak.currentStreak, 7);
        expect(badges.isEarned('week_streak'), isFalse);

        BadgeCoordinator(badges: badges, goals: goals, appStreak: appStreak);

        expect(badges.isEarned('week_streak'), isTrue);
      },
    );

    test(
      'AppStreakProvider SONRADAN değişince koordinatör otomatik reconcile '
      'eder',
      () {
        final coordinator = BadgeCoordinator(
          badges: badges,
          goals: goals,
          appStreak: appStreak,
        );
        expect(badges.isEarned('week_streak'), isFalse);

        for (var i = 0; i < 7; i++) {
          currentDate = currentDate.add(const Duration(days: 1));
          appStreak.recordOpenForToday();
        }

        expect(badges.isEarned('week_streak'), isTrue);
        coordinator.dispose();
      },
    );

    test('dispose() sonrası listener\'lar tetiklenmez', () {
      final coordinator = BadgeCoordinator(
        badges: badges,
        goals: goals,
        appStreak: appStreak,
      );
      coordinator.dispose();

      for (var i = 0; i < 7; i++) {
        currentDate = currentDate.add(const Duration(days: 1));
        appStreak.recordOpenForToday();
      }

      expect(badges.isEarned('week_streak'), isFalse);
    });
  });
}
