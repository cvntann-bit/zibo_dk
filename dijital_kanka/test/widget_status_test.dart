// Ana ekran widget'larının içerik hesaplama mantığını (bkz. CLAUDE.md
// "Ana Ekran Widget'ları" bölümü) doğrudan (widget/provider kurmadan) test
// eder — sekiz fonksiyonun hepsi saf, yalnızca birkaç ilkel değer alıyor.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/l10n/app_localizations_tr.dart';
import 'package:dijital_kanka/utils/widget_status.dart';

void main() {
  final l10n = AppLocalizationsTr();

  group('goalsWidgetStatus', () {
    test('hiç hedef yokken "—" + boş durum ipucu, ilerleme çubuğu gizli', () {
      final status = goalsWidgetStatus(l10n, doneToday: 0, totalGoals: 0);
      expect(status.primary, '—');
      expect(status.secondary, l10n.widgetGoalsEmptyHint);
      expect(status.progress, isNull);
    });

    test('hedef varken X/Y oranı ve doğru yüzde ilerleme', () {
      final status = goalsWidgetStatus(l10n, doneToday: 2, totalGoals: 4);
      expect(status.primary, '2/4');
      expect(status.secondary, l10n.widgetGoalsActiveHint);
      expect(status.progress, 50);
    });
  });

  group('waterWidgetStatus', () {
    test('bardak sayısı/hedefi ve birim etiketini doğru gösterir', () {
      final status = waterWidgetStatus(
        l10n,
        todayCount: 6,
        goalUnitCount: 8,
        unitLabel: l10n.waterUnitGlass,
      );
      expect(status.primary, '6/8');
      expect(status.secondary, l10n.widgetWaterHint(l10n.waterUnitGlass));
      expect(status.progress, 75);
    });

    test('hedef tamamlanınca ilerleme 100\'de kırpılır (fazlası taşmaz)', () {
      final status = waterWidgetStatus(
        l10n,
        todayCount: 10,
        goalUnitCount: 8,
        unitLabel: l10n.waterUnitGlass,
      );
      expect(status.progress, 100);
    });
  });

  group('gratitudeWidgetStatus', () {
    test('bugün tamamlanmışsa tik + "tamamlandı" metni', () {
      final status = gratitudeWidgetStatus(l10n, isTodayComplete: true);
      expect(status.primary, '✓');
      expect(status.secondary, l10n.widgetGratitudeDoneHint);
      expect(status.progress, isNull);
    });

    test('bugün henüz yazılmamışsa boş durum', () {
      final status = gratitudeWidgetStatus(l10n, isTodayComplete: false);
      expect(status.primary, '—');
      expect(status.secondary, l10n.widgetGratitudeEmptyHint);
    });
  });

  group('moodWidgetStatus', () {
    test('bugün bir emoji seçilmişse onu gösterir', () {
      final status = moodWidgetStatus(l10n, todayMoodEmoji: '🙂');
      expect(status.primary, '🙂');
      expect(status.secondary, l10n.widgetMoodSetHint);
    });

    test('henüz seçim yoksa boş durum', () {
      final status = moodWidgetStatus(l10n, todayMoodEmoji: null);
      expect(status.primary, '—');
      expect(status.secondary, l10n.widgetMoodEmptyHint);
    });
  });

  group('manifestWidgetStatus', () {
    test('bugün giriş varsa sayı + aktif ipucu', () {
      final status = manifestWidgetStatus(l10n, entriesToday: 2);
      expect(status.primary, '2');
      expect(status.secondary, l10n.widgetManifestActiveHint);
    });

    test('bugün hiç giriş yoksa boş ipucu', () {
      final status = manifestWidgetStatus(l10n, entriesToday: 0);
      expect(status.primary, '0');
      expect(status.secondary, l10n.widgetManifestEmptyHint);
    });
  });

  group('dreamWidgetStatus', () {
    test('kayıt varsa toplam sayı + aktif ipucu', () {
      final status = dreamWidgetStatus(l10n, totalDreams: 12);
      expect(status.primary, '12');
      expect(status.secondary, l10n.widgetDreamActiveHint);
    });

    test('hiç kayıt yoksa boş ipucu', () {
      final status = dreamWidgetStatus(l10n, totalDreams: 0);
      expect(status.secondary, l10n.widgetDreamEmptyHint);
    });
  });

  group('moneyWidgetStatus', () {
    test('formatlanmış net tutarı olduğu gibi taşır', () {
      final status = moneyWidgetStatus(l10n, formattedNetAmount: '1.250,00 ₺');
      expect(status.primary, '1.250,00 ₺');
      expect(status.secondary, l10n.widgetMoneyHint);
      expect(status.progress, isNull);
    });
  });

  group('dailyRewardsWidgetStatus', () {
    test('güncel gün numarasını VE ilerlemeyi doğru hesaplar', () {
      final status = dailyRewardsWidgetStatus(
        l10n,
        todayIndex: 2,
        daysPerCycle: 7,
        isTodayClaimed: false,
      );
      expect(status.primary, l10n.widgetDailyRewardsPrimary(3));
      expect(status.secondary, l10n.widgetDailyRewardsAvailableHint);
      expect(status.progress, ((3 / 7) * 100).round());
    });

    test('bugün zaten alınmışsa "alındı" ipucu gösterir', () {
      final status = dailyRewardsWidgetStatus(
        l10n,
        todayIndex: 6,
        daysPerCycle: 7,
        isTodayClaimed: true,
      );
      expect(status.secondary, l10n.widgetDailyRewardsClaimedHint);
    });

    test(
      'KRİTİK — güvenilir-zaman anomalisiyle todayIndex döngü DIŞINA taşarsa '
      '(negatif ya da daysPerCycle\'ı aşan) 0..daysPerCycle-1 aralığına kırpılır, '
      'asla "Gün 19/7" gibi anlamsız bir şey göstermez',
      () {
        final negative = dailyRewardsWidgetStatus(
          l10n,
          todayIndex: -3,
          daysPerCycle: 7,
          isTodayClaimed: false,
        );
        expect(negative.primary, l10n.widgetDailyRewardsPrimary(1));

        final overflow = dailyRewardsWidgetStatus(
          l10n,
          todayIndex: 19,
          daysPerCycle: 7,
          isTodayClaimed: false,
        );
        expect(overflow.primary, l10n.widgetDailyRewardsPrimary(7));
      },
    );
  });
}
