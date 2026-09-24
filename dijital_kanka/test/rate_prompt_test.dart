// "Bizi Google Play'de Puanla" penceresi: tetikleme kuralları
// (RatePromptTrigger) + pencere butonlarının kalıcı kapanış davranışı.
// Play Store açılışı (`url_launcher`) test ortamında asılı kalabildiği için
// yıldız / Puanla yolu burada TIKLANMIYOR.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/app_streak_provider.dart';
import 'package:dijital_kanka/utils/rate_prompt_trigger.dart';
import 'package:dijital_kanka/widgets/rate_prompt_dialog.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(RatePromptTrigger.resetForTest);

  group('RatePromptTrigger kuralları', () {
    test('initialize edilmeden (testler, güvenli varsayılan) ASLA göstermez', () {
      RatePromptTrigger.resetForTest(random: () => 0);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 10), isFalse);
    });

    test('şans tutarsa ve şartlar uygunsa gösterir', () {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0.19, now: () => now);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 3), isTrue);
    });

    test('%20 şans tutmazsa göstermez', () {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0.2, now: () => now);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 10), isFalse);
    });

    test('ilk 2 gün (toplam açılış < 3) göstermez', () {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0, now: () => now);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 2), isFalse);
    });

    test('gösterimden sonra 5 gün boyunca tekrar göstermez, sonra gösterir', () {
      var clock = now;
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0, now: () => clock);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);

      clock = now.add(const Duration(days: 4, hours: 23));
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isFalse);

      clock = now.add(const Duration(days: 5));
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);
    });

    test('markCompleted sonrası bir daha ASLA göstermez', () {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0, now: () => now);
      RatePromptTrigger.markCompleted();
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 30), isFalse);
    });

    test('kalıcılık: tamamlanma ve son gösterim yeniden başlatmada hatırlanır', () async {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0, now: () => now);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);
      RatePromptTrigger.markCompleted();
      await Future<void>.delayed(Duration.zero);

      RatePromptTrigger.resetForTest(random: () => 0, now: () => now);
      await RatePromptTrigger.initialize();

      expect(RatePromptTrigger.isCompleted, isTrue);
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 30), isFalse);
    });
  });

  group('RatePromptDialog', () {
    Widget buildApp() {
      return ChangeNotifierProvider(
        create: (_) => AppStreakProvider(),
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showRatePromptDialog(context),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsOneWidget);
    }

    testWidgets('mockup öğelerinin hepsi görünür, taşma yok', (tester) async {
      await openDialog(tester);
      expect(find.text("Google Play'de Puanla"), findsOneWidget);
      expect(find.text('Daha Sonra'), findsOneWidget);
      expect(find.text('Zaten puanladım'), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        expect(find.byKey(ValueKey('ratePromptStar$i')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Daha Sonra" kapatır ama kalıcı olarak TAMAMLAMAZ', (tester) async {
      RatePromptTrigger.resetForTest(loaded: true);
      await openDialog(tester);
      await tester.tap(find.text('Daha Sonra'));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
      expect(RatePromptTrigger.isCompleted, isFalse);
    });

    testWidgets('✕ kapatır ama kalıcı olarak TAMAMLAMAZ', (tester) async {
      RatePromptTrigger.resetForTest(loaded: true);
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('ratePromptCloseButton')));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
      expect(RatePromptTrigger.isCompleted, isFalse);
    });

    testWidgets('"Zaten puanladım" kapatır ve bir daha çıkmaz', (tester) async {
      RatePromptTrigger.resetForTest(loaded: true);
      await openDialog(tester);
      await tester.tap(find.text('Zaten puanladım'));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
      expect(RatePromptTrigger.isCompleted, isTrue);
    });

    testWidgets('maybeShowRatePrompt uygulama henüz 3 gün açılmadıysa pencereyi AÇMAZ', (tester) async {
      RatePromptTrigger.resetForTest(loaded: true, random: () => 0, now: () => now);
      final provider = AppStreakProvider(now: () => DateTime(2026, 9, 1));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => maybeShowRatePrompt(context),
                  child: const Text('mutlu an'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Henüz 3 gün açılmadı → çıkmaz.
      await tester.tap(find.text('mutlu an'));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
    });
  });
}
