// Zibo Dünyası Faz 4 (docs/zibo_world_roadmap.md): oda ekranındaki bakım
// oyunları — besle, yıka, uyut. Sahne 900×1200 birimlik; dokunuşlar
// RoomView'in ekrandaki yerine göre sahne koordinatından hesaplanır.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/home_item.dart';
import 'package:dijital_kanka/models/home_need.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/game_points_provider.dart';
import 'package:dijital_kanka/providers/games_config_provider.dart';
import 'package:dijital_kanka/providers/home_config_provider.dart';
import 'package:dijital_kanka/providers/home_decor_provider.dart';
import 'package:dijital_kanka/providers/home_needs_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/screens/home_room_screen.dart';
import 'package:dijital_kanka/widgets/home_art/room_view.dart';

import 'fake_audioplayers_platform.dart';

void main() {
  late HomeNeedsProvider needs;
  late HomeDecorProvider decor;
  late CoinProvider coins;
  final clock = DateTime(2026, 11, 3, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeAudioplayersPlatform();
  });

  Future<void> pumpRoom(WidgetTester tester, HomeRoom room) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    needs = HomeNeedsProvider(now: () => clock);
    decor = HomeDecorProvider();
    coins = CoinProvider(now: () => clock, isSoundEnabled: () => false);
    await tester.runAsync(() async {
      await needs.ready;
      await decor.ready;
      while (!coins.isReady) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: needs),
          ChangeNotifierProvider.value(value: decor),
          ChangeNotifierProvider(create: (_) => HomeConfigProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider(now: () => clock)),
          ChangeNotifierProvider.value(value: coins),
          ChangeNotifierProvider(create: (_) => GamePointsProvider(now: () => clock)),
          ChangeNotifierProvider(create: (_) => GamesConfigProvider()),
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
          home: HomeRoomScreen(initialRoom: room),
        ),
      ),
    );
    await tester.pump();
  }

  /// Sahne koordinatını ekran konumuna çevirir.
  Offset scenePoint(WidgetTester tester, Offset p) {
    final view = find.byType(RoomView);
    final box = tester.renderObject<RenderBox>(view);
    final s = box.size.width / 900;
    // Tam ekranda tuval sahnenin üstüne uzar (RoomScene.extraTop).
    final top = tester.widget<RoomView>(view).scene.extraTop;
    return box.localToGlobal((p + Offset(0, top)) * s);
  }

  Future<void> frames(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Bitmemiş Ticker kalmasın.
  Future<void> tearDownScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('mutfak: ücretsiz yemek tabağa gelir, ağza sürüklenince tokluk artar', (tester) async {
    await pumpRoom(tester, HomeRoom.kitchen);
    expect(needs.freeFoodsLeft, 3);
    await tester.tap(find.bySemanticsLabel('Elma, Ücretsiz · 3'));
    await tester.pump();
    expect(needs.freeFoodsLeft, 2);

    final gesture = await tester.startGesture(scenePoint(tester, const Offset(455, 760)));
    await gesture.moveTo(scenePoint(tester, const Offset(455, 700)));
    await gesture.moveTo(scenePoint(tester, const Offset(455, 630)));
    await gesture.up();
    await tester.pump();
    expect(needs.percent(HomeNeed.hunger), 92);
    expect(find.text('Ham ham, çok güzelmiş!'), findsOneWidget);
    await frames(tester, 80);
    await tearDownScreen(tester);
  });

  testWidgets('banyo: köpürt → duş → havlu, temizlik dolar', (tester) async {
    await pumpRoom(tester, HomeRoom.bath);
    expect(find.text('Zibo kirlenmiş, yıkayalım'), findsOneWidget);
    // Zibo'nun gövdesini sabunla tara.
    for (var pass = 0; pass < 4; pass++) {
      final g = await tester.startGesture(scenePoint(tester, const Offset(150, 380)));
      for (var y = 380.0; y <= 620; y += 20) {
        for (final x in [150.0, 230.0, 310.0, 390.0, 430.0]) {
          await g.moveTo(scenePoint(tester, Offset(x, y)));
        }
      }
      await g.up();
      await tester.pump();
    }
    final shower = find.widgetWithText(FilledButton, 'Duşu aç');
    expect(tester.widget<FilledButton>(shower).onPressed, isNotNull);
    tester.widget<FilledButton>(shower).onPressed!();
    await frames(tester, 130);
    final towel = find.widgetWithText(FilledButton, 'Havluyla kurula');
    expect(tester.widget<FilledButton>(towel).onPressed, isNotNull);
    tester.widget<FilledButton>(towel).onPressed!();
    await tester.pump();
    expect(needs.percent(HomeNeed.hygiene), 100);
    expect(find.text('Zibo tertemiz!'), findsOneWidget);
    await frames(tester, 120);
    await tearDownScreen(tester);
  });

  testWidgets('yatak odası: ışığı kapatınca uyur, açınca uyanır', (tester) async {
    await pumpRoom(tester, HomeRoom.bedroom);
    await tester.tap(find.text('Işığı kapat, uyut'));
    await tester.pump();
    expect(needs.isAsleep, isTrue);
    expect(find.text('Zibo uyuyor, şşş…'), findsOneWidget);
    await frames(tester, 40);
    await tester.tap(find.text('Işığı aç, uyandır'));
    await tester.pump();
    expect(needs.isAsleep, isFalse);
    await frames(tester, 300);
    await tearDownScreen(tester);
  });

  testWidgets('dekor: dene → sepet → satın al; eşya sende kalır ve takılır', (tester) async {
    await pumpRoom(tester, HomeRoom.living);
    coins.earnDailyLoginReward(1000);
    final start = coins.balance;
    await tester.tap(find.text('Dekor'));
    await tester.pump();
    expect(find.textContaining('Odadakileri al'), findsNothing);
    // Boya kategorisi açık: Gökyüzü (40 ZC) dene.
    await tester.tap(find.bySemanticsLabel('Gökyüzü, 40 ZC'));
    await tester.pump();
    expect(decor.isOwned(HomeRoom.living, 'boya', 'gok'), isFalse);
    final buy = find.widgetWithText(FilledButton, 'Odadakileri al · 40 ZC');
    expect(buy, findsOneWidget);
    tester.widget<FilledButton>(buy).onPressed!();
    await tester.pump();
    expect(coins.balance, start - 40);
    expect(decor.isOwned(HomeRoom.living, 'boya', 'gok'), isTrue);
    expect(decor.equipped(HomeRoom.living, 'boya'), 'gok');
    expect(find.text('Odan yenilendi!'), findsOneWidget);
    // Sahip olunan başlangıç boyasına dokununca ücretsiz geri takılır.
    final seftali = find.bySemanticsLabel(RegExp(r'^Şeftali, '));
    await tester.dragUntilVisible(seftali, find.byType(ListView).last, const Offset(-120, 0));
    tester.widget<InkWell>(find.descendant(of: seftali, matching: find.byType(InkWell))).onTap!();
    await tester.pump();
    expect(decor.equipped(HomeRoom.living, 'boya'), 'seftali');
    expect(coins.balance, start - 40);
    await tearDownScreen(tester);
  });

  testWidgets('dekor: ZC yetmezse satın alınmaz, deneme vazgeçilince temizlenir', (tester) async {
    await pumpRoom(tester, HomeRoom.living);
    final start = coins.balance;
    await tester.tap(find.text('Dekor'));
    await tester.pump();
    await tester.dragUntilVisible(find.bySemanticsLabel('Gece mavisi, 80 ZC'), find.byType(ListView).last, const Offset(-120, 0));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Gece mavisi, 80 ZC'));
    await tester.pump();
    final buy = find.widgetWithText(FilledButton, 'Odadakileri al · 80 ZC');
    if (start < 80) {
      tester.widget<FilledButton>(buy).onPressed!();
      await tester.pump();
      expect(find.text('Yetersiz Zibo Coin'), findsOneWidget);
      expect(decor.isOwned(HomeRoom.living, 'boya', 'gece'), isFalse);
    }
    await tester.tap(find.byTooltip('Vazgeç'));
    await tester.pump();
    expect(find.textContaining('Odadakileri al'), findsNothing);
    await tearDownScreen(tester);
  });

  testWidgets('odalar arası: kaydırınca ya da ihtiyaç çubuğuna dokununca oda değişir', (tester) async {
    await pumpRoom(tester, HomeRoom.living);
    expect(find.text('Salon'), findsWidgets);
    // Sola kaydır → sıradaki oda (yatak odası).
    await tester.fling(find.byType(RoomView), const Offset(-300, 0), 1200);
    await frames(tester, 70);
    expect(find.text('Yatak odası'), findsWidgets);
    // Tokluk çubuğu → mutfak.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Tokluk %')));
    await frames(tester, 70);
    expect(find.text('Mutfak'), findsWidgets);
    await tearDownScreen(tester);
  });
}
