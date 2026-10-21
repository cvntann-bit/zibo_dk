// Zibo intro hikâyesi (bkz. docs/onboarding_story.md, lib/screens/onboarding/story_intro_screen.dart):
// 5 slayt dokunarak ilerler, "Geç" atlatır, akış isim → karşılama ile biter.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/screens/onboarding/story_intro_screen.dart';

Widget _host({Locale locale = const Locale('tr')}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StoryIntroScreen()),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('tr'),
  }) async {
    await tester.pumpWidget(_host(locale: locale));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('5 slayt dokunarak ilerler, son dokunuş hikâyeyi kapatır', (
    tester,
  ) async {
    await open(tester);
    expect(
      find.text('Eskiden düzensiz ve soluk bir hayatım vardı…'),
      findsOneWidget,
    );
    expect(find.text('Devam etmek için dokun'), findsOneWidget);

    final stage = find.byKey(const Key('storyStage'));
    final expected = [
      'Ta ki… bir gün her şeyden sıkılıp, kendimin en iyi versiyonuna ulaşmaya karar verdiğim ana kadar.',
      'İşte o an her şey değişti.',
      'Sonra kendime bir söz verdim: bu yolda kendinin en iyi versiyonuna ulaşmaya karar veren herkesin kankası olacağım.',
      'Demek buradasın. O zaman başlayalım!',
    ];
    for (final line in expected) {
      await tester.tap(stage);
      await tester.pumpAndSettle();
      expect(find.text(line), findsOneWidget, reason: line);
    }
    // 5. slayttan sonraki dokunuş rotayı kapatır.
    await tester.tap(stage);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('storyStage')), findsNothing);
    expect(find.text('aç'), findsOneWidget);
  });

  testWidgets('"Geç" her slaytta hikâyeyi hemen kapatır', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('storyStage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('storySkip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('storyStage')), findsNothing);
  });

  testWidgets('metinler İngilizce ve İspanyolca da var', (tester) async {
    await open(tester, locale: const Locale('en'));
    expect(
      find.text('I used to live a messy, washed-out life…'),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
  });
}
