// Instagram Takip Kartı: tek "Instagram'ı Aç" butonu, ödül kullanıcı
// uygulamadan gerçekten çıkıp (paused) geri dönünce (resumed) verilir.
// `url_launcher` platform kanalına dokunulmuyor — sahte `launcher` enjekte.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/coin_economy.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/instagram_follow_provider.dart';
import 'package:dijital_kanka/widgets/instagram_follow_card.dart';

class _Harness {
  final coins = CoinProvider();
  final instagram = InstagramFollowProvider();
  final launchedUris = <Uri>[];
  bool launchResult = true;

  Widget build() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: coins),
        ChangeNotifierProvider.value(value: instagram),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InstagramFollowCard(
            launcher: (uri) async {
              launchedUris.add(uri);
              return launchResult;
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _leaveAndReturn(WidgetTester tester) async {
  final binding = tester.binding;
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('"Takip Ettim" butonu YOK, yalnızca "Instagram\'ı Aç" var', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.text('Takip Ettim'), findsNothing);
    expect(find.text("Instagram'ı Aç"), findsOneWidget);
  });

  testWidgets(
    'Instagram açılıp uygulamaya dönülünce ödül otomatik verilir ve kart gizlenir',
    (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      final balanceBefore = h.coins.balance;

      await tester.tap(find.text("Instagram'ı Aç"));
      await tester.pump();
      expect(h.launchedUris.single.toString(), 'https://www.instagram.com/zibo.app');
      expect(h.instagram.claimed, isFalse);

      await _leaveAndReturn(tester);

      expect(h.instagram.claimed, isTrue);
      expect(h.coins.balance, balanceBefore + CoinEconomy.instagramFollowReward);
      expect(find.text('Ödülün hesabına eklendi! 🎉'), findsOneWidget);
    },
  );

  testWidgets('Butona basmadan uygulamaya dönmek ödül VERMEZ', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _leaveAndReturn(tester);

    expect(h.instagram.claimed, isFalse);
  });

  testWidgets('Uygulamadan çıkmadan (yalnızca inactive) dönmek ödül VERMEZ', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Instagram'ı Aç"));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(h.instagram.claimed, isFalse);
  });

  testWidgets('Instagram açılamazsa sonraki dönüşte ödül VERİLMEZ', (tester) async {
    final h = _Harness()..launchResult = false;
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Instagram'ı Aç"));
    await tester.pumpAndSettle();
    await _leaveAndReturn(tester);

    expect(h.instagram.claimed, isFalse);
  });
}
