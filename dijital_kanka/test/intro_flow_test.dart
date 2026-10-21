// Zibo intro akışı (hikâye → isim → bildirim izni → final): lib/screens/onboarding/intro_flow_screen.dart.
// Bildirim izninin GERÇEK isteği dışarıdan verilir; burada sahte callback ile sonuç/dallanma test edilir.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/screens/onboarding/intro_flow_screen.dart';

IntroResult? _result;

Widget _host(Future<bool> Function() ask) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            _result = await Navigator.of(context).push<IntroResult>(
              MaterialPageRoute<IntroResult>(
                builder: (_) =>
                    IntroFlowScreen(requestNotificationPermission: ask),
              ),
            );
          },
          child: const Text('aç'),
        ),
      ),
    ),
  ),
);

Future<void> _toName(WidgetTester tester, Future<bool> Function() ask) async {
  _result = null;
  await tester.pumpWidget(_host(ask));
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('storySkip')),
  ); // hikâyeyi atla → isim adımı
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'isim boşken devam kapalı; isim yazılınca bildirim adımı kendi adıyla selamlar',
    (tester) async {
      await _toName(tester, () async => true);
      expect(find.text('Sana ne diye hitap edeyim?'), findsOneWidget);
      FilledButton cont() => tester.widget<FilledButton>(
        find.byKey(const Key('introNameContinue')),
      );
      expect(cont().onPressed, isNull);

      await tester.enterText(find.byKey(const Key('introNameField')), 'Ayşe');
      await tester.pump();
      expect(cont().onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('introNameContinue')));
      await tester.pumpAndSettle();

      expect(find.text('Tanıştığıma memnun oldum, Ayşe!'), findsOneWidget);
      expect(find.byKey(const Key('introNotifAllow')), findsOneWidget);
      expect(find.byKey(const Key('introNotifLater')), findsOneWidget);
    },
  );

  testWidgets(
    'İzin Ver → izin istenir, olumlu final metni, sonuç isim + izin=true',
    (tester) async {
      var asked = 0;
      await _toName(tester, () async {
        asked++;
        return true;
      });
      await tester.enterText(find.byKey(const Key('introNameField')), 'Ayşe');
      await tester.pump();
      await tester.tap(find.byKey(const Key('introNameContinue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('introNotifAllow')));
      await tester.pumpAndSettle();

      expect(asked, 1);
      expect(
        find.text(
          'Harika! Artık sana daha kolay ulaşabilirim. Hadi başlayalım!',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('introFinish')));
      await tester.pumpAndSettle();
      expect(_result?.name, 'Ayşe');
      expect(_result?.notificationsGranted, isTrue);
    },
  );

  testWidgets(
    'Şimdi Değil → izin İSTENMEZ, "sonra Ayarlar" metni, sonuç izin=false',
    (tester) async {
      var asked = 0;
      await _toName(tester, () async {
        asked++;
        return true;
      });
      await tester.enterText(
        find.byKey(const Key('introNameField')),
        '  Mehmet ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('introNameContinue')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('introNotifLater')));
      await tester.tap(find.byKey(const Key('introNotifLater')));
      await tester.pumpAndSettle();

      expect(asked, 0);
      expect(find.textContaining('Ayarlar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('introFinish')));
      await tester.pumpAndSettle();
      expect(_result?.name, 'Mehmet'); // baştaki/sondaki boşluk kırpılır
      expect(_result?.notificationsGranted, isFalse);
    },
  );

  testWidgets(
    'sistem izni reddedilirse (callback false) final "sonra Ayarlar" metnine düşer',
    (tester) async {
      await _toName(tester, () async => false);
      await tester.enterText(find.byKey(const Key('introNameField')), 'Ece');
      await tester.pump();
      await tester.tap(find.byKey(const Key('introNameContinue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('introNotifAllow')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ayarlar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('introFinish')));
      await tester.pumpAndSettle();
      expect(_result?.notificationsGranted, isFalse);
    },
  );
}
