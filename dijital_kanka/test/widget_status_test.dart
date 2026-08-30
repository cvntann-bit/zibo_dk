// Ana ekran widget'larının içerik hesaplama mantığını (bkz. CLAUDE.md
// "Ana Ekran Widget'ları" bölümü) doğrudan (widget/provider kurmadan) test
// eder — kalan fonksiyonların hepsi saf, yalnızca birkaç ilkel değer alıyor.
// **2026 güncellemesi** — beş "basit günlük/checkbox" widget'ının
// (goals/gratitude/mood/manifest/dream) durum fonksiyonları koddan
// kaldırıldığı için buradaki testleri de kaldırıldı, bkz. `widget_status.dart`.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/l10n/app_localizations_tr.dart';
import 'package:dijital_kanka/utils/widget_status.dart';

void main() {
  final l10n = AppLocalizationsTr();

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

  group('motivationWidgetStatus', () {
    test('quote\'u olduğu gibi primary\'e taşır, secondary boş', () {
      final status = motivationWidgetStatus(l10n, quote: 'Zor günler geçer, sen kalıcısın.');
      expect(status.primary, 'Zor günler geçer, sen kalıcısın.');
      expect(status.secondary, '');
      expect(status.progress, isNull);
    });
  });
}
