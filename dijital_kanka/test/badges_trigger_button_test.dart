// BadgesTriggerButton'ın (a) disableAnimations açıkken sonsuz pumpAndSettle'a
// yol AÇMADIĞINI (bkz. CLAUDE.md "Şans Çarkı" bölümündeki tekrarlayan
// gotcha), (b) dokununca ARA bir pop-up OLMADAN doğrudan BadgesGalleryScreen'i
// açtığını doğrular.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/screens/badges_gallery_screen.dart';
import 'package:dijital_kanka/widgets/badges_trigger_button.dart';

Widget _buildTestApp() {
  return ChangeNotifierProvider<BadgeProvider>(
    create: (_) => BadgeProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Center(child: BadgesTriggerButton())),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher
            as TestPlatformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  testWidgets(
    'Dokununca ARA bir pop-up olmadan doğrudan Rozetler Galerisi açılır',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BadgesTriggerButton));
      await tester.pumpAndSettle();

      expect(find.byType(BadgesGalleryScreen), findsOneWidget);
    },
  );
}
