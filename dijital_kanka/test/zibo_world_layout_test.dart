// Zibo Dünyası giriş ekranı yerleşimi: dikeyde world_bg, yan çevrilmiş
// tablette world_bg_wide (docs/tablet_optimization.md, 2026-11-07).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/events_provider.dart';
import 'package:dijital_kanka/providers/home_needs_provider.dart';
import 'package:dijital_kanka/screens/zibo_world_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpWorld(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeNeedsProvider()),
          ChangeNotifierProvider(create: (_) => EventsProvider()),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ZiboWorldScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  Set<String> bgAssets(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((i) => i.image)
      .whereType<AssetImage>()
      .map((a) => a.assetName)
      .where((n) => n.contains('world_bg'))
      .toSet();

  testWidgets('dikey ekranda dikey görsel', (tester) async {
    await pumpWorld(tester, const Size(412, 800));
    expect(bgAssets(tester), {'assets/images/world/world_bg.webp'});
  });

  testWidgets('yan çevrilmiş tablette yatay görsel, binalar ekranda ve dokunulabilir', (tester) async {
    const screen = Size(1200, 744);
    await pumpWorld(tester, screen);
    expect(bgAssets(tester), {'assets/images/world/world_bg_wide.webp'});
    // Beş binanın hepsi ekranın içinde.
    for (final asset in ['world_friends', 'world_leaderboard', 'world_events', 'world_games', 'world_home']) {
      final img = find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains(asset),
      );
      expect(img, findsOneWidget, reason: asset);
      final r = tester.getRect(img);
      expect(r.left >= 0 && r.right <= screen.width && r.top >= 0 && r.bottom <= screen.height, isTrue, reason: '$asset $r');
    }
  });
}
