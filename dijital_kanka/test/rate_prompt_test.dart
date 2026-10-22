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
import 'package:dijital_kanka/services/review_service.dart';
import 'package:dijital_kanka/utils/rate_prompt_trigger.dart';
import 'package:dijital_kanka/widgets/rate_prompt_dialog.dart';
import 'package:dijital_kanka/widgets/rate_us_sheet.dart';

class _FakeReviewService extends ReviewService {
  _FakeReviewService({this.shown = true});

  final bool shown;
  int calls = 0;

  @override
  Future<bool> requestReview() async {
    calls++;
    return shown;
  }
}

void main() {
  final now = DateTime(2026, 9, 24, 12);

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(RatePromptTrigger.resetForTest);

  group('RatePromptTrigger kuralları', () {
    test(
      'initialize edilmeden (testler, güvenli varsayılan) ASLA göstermez',
      () {
        RatePromptTrigger.resetForTest(random: () => 0);
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 10), isFalse);
      },
    );

    test('şans tutarsa ve şartlar uygunsa gösterir (Faz S: %35)', () {
      RatePromptTrigger.resetForTest(
        loaded: true,
        random: () => 0.34,
        now: () => now,
      );
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 2), isTrue);
    });

    test('%35 şans tutmazsa göstermez', () {
      RatePromptTrigger.resetForTest(
        loaded: true,
        random: () => 0.35,
        now: () => now,
      );
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 10), isFalse);
    });

    test('ilk gün (toplam açılış < 2) göstermez', () {
      RatePromptTrigger.resetForTest(
        loaded: true,
        random: () => 0,
        now: () => now,
      );
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 1), isFalse);
    });

    test(
      'gösterimden sonra 3 gün boyunca tekrar göstermez, sonra gösterir',
      () {
        var clock = now;
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => clock,
        );
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);

        clock = now.add(const Duration(days: 2, hours: 23));
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isFalse);

        clock = now.add(const Duration(days: 3));
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);
      },
    );

    test(
      'Puanla/yıldıza DOKUNULDUYSA 45 gün sorulmaz (kalıcı kapanış DEĞİL), sonra yeniden sorulur',
      () {
        var clock = now;
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => clock,
        );
        RatePromptTrigger.markRateTapped();
        expect(RatePromptTrigger.isCompleted, isFalse);

        clock = now.add(const Duration(days: 44));
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 50), isFalse);

        clock = now.add(const Duration(days: 45));
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 50), isTrue);
      },
    );

    test('yaşam boyu en fazla 8 gösterim', () {
      var clock = now;
      RatePromptTrigger.resetForTest(
        loaded: true,
        random: () => 0,
        now: () => clock,
      );
      var shown = 0;
      for (var i = 0; i < 20; i++) {
        if (RatePromptTrigger.shouldShow(daysOpened: () => 50)) shown++;
        clock = clock.add(const Duration(days: 4));
      }
      expect(shown, RatePromptTrigger.maxShows);
    });

    test('markCompleted sonrası bir daha ASLA göstermez', () {
      RatePromptTrigger.resetForTest(
        loaded: true,
        random: () => 0,
        now: () => now,
      );
      RatePromptTrigger.markCompleted();
      expect(RatePromptTrigger.shouldShow(daysOpened: () => 30), isFalse);
    });

    test(
      'kalıcılık: tamamlanma ve son gösterim yeniden başlatmada hatırlanır',
      () async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);
        RatePromptTrigger.markCompleted();
        await Future<void>.delayed(Duration.zero);

        RatePromptTrigger.resetForTest(random: () => 0, now: () => now);
        await RatePromptTrigger.initialize();

        expect(RatePromptTrigger.isCompleted, isTrue);
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 30), isFalse);
      },
    );

    test(
      'kalıcılık: dokunma zamanı ve gösterim sayısı yeniden başlatmada hatırlanır',
      () async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 5), isTrue);
        RatePromptTrigger.markRateTapped();
        await Future<void>.delayed(Duration.zero);

        RatePromptTrigger.resetForTest(
          random: () => 0,
          now: () => now.add(const Duration(days: 10)),
        );
        await RatePromptTrigger.initialize();
        expect(
          RatePromptTrigger.shouldShow(daysOpened: () => 30),
          isFalse,
        ); // 45 gün dolmadı
      },
    );
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

    testWidgets('"Daha Sonra" kapatır ama kalıcı olarak TAMAMLAMAZ', (
      tester,
    ) async {
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

    Future<void> openWith(WidgetTester tester, ReviewService service) async {
      await tester.pumpWidget(
        MaterialApp(
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
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RatePromptDialog(reviewService: service),
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'yıldıza dokununca UYGULAMA-İÇİ yorum istenir, 45 gün beklenir, KALICI kapanış YOK',
      (tester) async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
        final fake = _FakeReviewService(shown: true);
        await openWith(tester, fake);

        await tester.tap(find.byKey(const ValueKey('ratePromptStar5')));
        await tester
            .pump(); // yıldız animasyonu: Future.delayed(450 ms) açıkça ilerletilir
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(fake.calls, 1);
        expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
        expect(
          RatePromptTrigger.isCompleted,
          isFalse,
        ); // eskiden dokunmak kalıcı kapatıyordu
        expect(
          RatePromptTrigger.shouldShow(daysOpened: () => 50),
          isFalse,
        ); // 45 gün bekleme başladı
      },
    );

    testWidgets(
      'Google pencereyi göstermediyse (false) Play Store sayfasına düşer, çökmez',
      (tester) async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
        final fake = _FakeReviewService(shown: false);
        await openWith(tester, fake);

        await tester.tap(find.byKey(const ValueKey('ratePromptStar4')));
        await tester
            .pump(); // yıldız animasyonu: Future.delayed(450 ms) açıkça ilerletilir
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(fake.calls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ayarlar "Bizi Puanlayın" yıldızı UYGULAMA-İÇİ yorumu çağırır, 45 gün bekleme başlar',
      (tester) async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
        final fake = _FakeReviewService(shown: true);
        await tester.pumpWidget(
          MaterialApp(
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
                    onPressed: () =>
                        showRateUsSheet(context, reviewService: fake),
                    child: const Text('aç'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('aç'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('5'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(fake.calls, 1);
        expect(RatePromptTrigger.isCompleted, isFalse);
        expect(RatePromptTrigger.shouldShow(daysOpened: () => 50), isFalse);
      },
    );

    test(
      'InAppReviewService: 600 ms\'den kısa süren istek "gösterilmedi" sayılır (kota sezgisi)',
      () {
        expect(
          InAppReviewService.looksShown(const Duration(milliseconds: 100)),
          isFalse,
        );
        expect(
          InAppReviewService.looksShown(const Duration(milliseconds: 599)),
          isFalse,
        );
        expect(
          InAppReviewService.looksShown(const Duration(milliseconds: 600)),
          isTrue,
        );
        expect(
          InAppReviewService.looksShown(const Duration(seconds: 8)),
          isTrue,
        );
      },
    );

    testWidgets('"Zaten puanladım" kapatır ve bir daha çıkmaz', (tester) async {
      RatePromptTrigger.resetForTest(loaded: true);
      await openDialog(tester);
      await tester.tap(find.text('Zaten puanladım'));
      await tester.pumpAndSettle();
      expect(find.text("Zibo'yla Aran Nasıl?"), findsNothing);
      expect(RatePromptTrigger.isCompleted, isTrue);
    });

    testWidgets(
      'maybeShowRatePrompt uygulama henüz 2 gün açılmadıysa pencereyi AÇMAZ',
      (tester) async {
        RatePromptTrigger.resetForTest(
          loaded: true,
          random: () => 0,
          now: () => now,
        );
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
      },
    );
  });
}
