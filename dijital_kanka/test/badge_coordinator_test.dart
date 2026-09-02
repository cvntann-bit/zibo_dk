// BadgeCoordinator'ın GoalsProvider/AppStreakProvider (İstikrar),
// Gratitude/Water/Mood/Money/Manifest/Dream (Modül Ustalığı) VE Costume/
// AppTheme (Koleksiyon) provider'ları değiştiğinde BadgeProvider.
// reconcileConsistencyBadges/reconcileModuleMasteryBadges/
// reconcileCollectionBadges'i OTOMATİK tetiklediğini doğrudan (widget
// pump'lamadan) test eder — HomeWidgetSyncCoordinator testlerindeki "sahte/
// gerçek provider'ları kur, addListener'ın gerçekten tetiklendiğini
// doğrula" deseniyle aynı. Modüle özel eşik/kazanma mantığının kendisi
// `badge_provider_test.dart`ta zaten kapsamlı test edildiği için burada
// yalnızca "koordinatör GERÇEKTEN dinliyor mu" doğrulanıyor — provider'ların
// HEPSİ için ayrı ayrı senaryo YAZILMADI, MoneyProvider/CostumeProvider
// (en basit, tarih kilidi olmayan) birer TEMSİLCİ olarak yeterli.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/costumes.dart';
import 'package:dijital_kanka/models/money_entry.dart';
import 'package:dijital_kanka/providers/app_streak_provider.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/dream_journal_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/mood_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
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
    late GratitudeProvider gratitude;
    late WaterProvider water;
    late MoodProvider mood;
    late MoneyProvider money;
    late ManifestProvider manifest;
    late DreamJournalProvider dream;
    late CostumeProvider costume;
    late AppThemeProvider appTheme;

    setUp(() async {
      currentDate = DateTime(2026, 1, 5);
      badges = BadgeProvider();
      goals = GoalsProvider(now: () => currentDate);
      appStreak = AppStreakProvider(now: () => currentDate);
      gratitude = GratitudeProvider(now: () => currentDate);
      water = WaterProvider(now: () => currentDate);
      mood = MoodProvider(now: () => currentDate);
      money = MoneyProvider(now: () => currentDate);
      manifest = ManifestProvider(now: () => currentDate);
      dream = DreamJournalProvider();
      costume = CostumeProvider();
      appTheme = AppThemeProvider();
      await Future<void>.delayed(Duration.zero);
    });

    BadgeCoordinator buildCoordinator() => BadgeCoordinator(
      badges: badges,
      goals: goals,
      appStreak: appStreak,
      gratitude: gratitude,
      water: water,
      mood: mood,
      money: money,
      manifest: manifest,
      dream: dream,
      costume: costume,
      appTheme: appTheme,
    );

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

        buildCoordinator();

        expect(badges.isEarned('week_streak'), isTrue);
      },
    );

    test(
      'AppStreakProvider SONRADAN değişince koordinatör otomatik reconcile '
      'eder',
      () {
        final coordinator = buildCoordinator();
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
      final coordinator = buildCoordinator();
      coordinator.dispose();

      for (var i = 0; i < 7; i++) {
        currentDate = currentDate.add(const Duration(days: 1));
        appStreak.recordOpenForToday();
      }

      expect(badges.isEarned('week_streak'), isFalse);
    });

    test(
      'Constructor EAGER ilk reconcile Modül Ustalığı rozetlerini de '
      'kapsıyor — kuruluştan ÖNCE zaten karşılanmış bir eşik hemen '
      'ödüllendirilir',
      () {
        for (var i = 0; i < 20; i++) {
          money.addEntry(
            MoneyCategory.saving,
            name: 'Kayıt $i',
            amount: 10,
            currencyCode: 'TRY',
          );
        }
        expect(money.totalEntryCount, 20);
        expect(badges.isEarned('savings_master'), isFalse);

        buildCoordinator();

        expect(badges.isEarned('savings_master'), isTrue);
      },
    );

    test(
      'MoneyProvider SONRADAN değişince koordinatör Modül Ustalığı '
      'rozetini de reconcile eder',
      () {
        final coordinator = buildCoordinator();
        expect(badges.isEarned('savings_master'), isFalse);

        for (var i = 0; i < 20; i++) {
          money.addEntry(
            MoneyCategory.saving,
            name: 'Kayıt $i',
            amount: 10,
            currencyCode: 'TRY',
          );
        }

        expect(badges.isEarned('savings_master'), isTrue);
        coordinator.dispose();
      },
    );

    test(
      'dispose() sonrası Modül Ustalığı provider değişiklikleri de '
      'tetiklenmez',
      () {
        final coordinator = buildCoordinator();
        coordinator.dispose();

        for (var i = 0; i < 20; i++) {
          money.addEntry(
            MoneyCategory.saving,
            name: 'Kayıt $i',
            amount: 10,
            currencyCode: 'TRY',
          );
        }

        expect(badges.isEarned('savings_master'), isFalse);
      },
    );

    test(
      'Constructor EAGER ilk reconcile Koleksiyon rozetlerini de kapsıyor '
      '— kuruluştan ÖNCE zaten karşılanmış bir eşik hemen ödüllendirilir',
      () {
        for (final c in costumes.take(5)) {
          costume.markOwned(c.id);
        }
        expect(costume.ownedRealCostumeCount, 5);
        expect(badges.isEarned('collector'), isFalse);

        buildCoordinator();

        expect(badges.isEarned('collector'), isTrue);
      },
    );

    test(
      'CostumeProvider SONRADAN değişince koordinatör Koleksiyon rozetini '
      'de reconcile eder',
      () {
        final coordinator = buildCoordinator();
        expect(badges.isEarned('collector'), isFalse);

        for (final c in costumes.take(5)) {
          costume.markOwned(c.id);
        }

        expect(badges.isEarned('collector'), isTrue);
        coordinator.dispose();
      },
    );

    test(
      'dispose() sonrası Koleksiyon provider değişiklikleri de tetiklenmez',
      () {
        final coordinator = buildCoordinator();
        coordinator.dispose();

        for (final c in costumes.take(5)) {
          costume.markOwned(c.id);
        }

        expect(badges.isEarned('collector'), isFalse);
      },
    );
  });
}
