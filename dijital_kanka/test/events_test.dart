// Zibo Dünyası Faz 6 (docs/zibo_world_roadmap.md): etkinlikler — takvim
// kutuları, tekrar açma koruması, güvenilir gün, ödüllerin uygulanması.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/home_item.dart';
import 'package:dijital_kanka/models/zibo_event.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/events_provider.dart';
import 'package:dijital_kanka/providers/home_decor_provider.dart';
import 'package:dijital_kanka/screens/events_screen.dart';

import 'fake_audioplayers_platform.dart';

ZiboEvent _calendar({bool catchUp = true, bool enabled = true, String type = 'takvim'}) => ZiboEvent(
  id: 'yilbasi',
  type: type,
  enabled: enabled,
  title: const {'tr': 'Yılbaşı takvimi', 'en': 'Advent calendar'},
  description: const {},
  start: DateTime(2026, 12, 1),
  end: DateTime(2026, 12, 25),
  days: [
    for (var i = 0; i < 25; i++) i == 24 ? const EventReward(itemKey: 'salon:kose:cam') : const EventReward(zc: 20),
  ],
  catchUp: catchUp,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeAudioplayersPlatform();
  });

  group('ZiboEvent.fromJson', () {
    test('geçerli doküman okunur, bozuk alanlar güvenli', () {
      final e = ZiboEvent.fromJson('x', {
        'type': 'takvim',
        'enabled': true,
        'title': {'tr': 'Takvim', 'es': 'Calendario'},
        'start': '2026-12-01',
        'end': '2026-12-03',
        'days': [
          {'zc': 50},
          {'item': 'salon:kose:cam'},
          {'zc': 999999, 'item': 'bozuk'},
        ],
      })!;
      expect(e.days[0].zc, 50);
      expect(e.days[1].itemKey, 'salon:kose:cam');
      expect(e.days[2].zc, EventReward.maxZc);
      expect(e.days[2].itemKey, isNull);
      expect(e.catchUp, isTrue);
      expect(e.titleFor(const Locale('es')), 'Calendario');
      expect(e.titleFor(const Locale('en')), 'Takvim');
    });

    test('tarihsiz ya da ters tarihli doküman yok sayılır', () {
      expect(ZiboEvent.fromJson('x', {'start': '2026-12-05', 'end': '2026-12-01'}), isNull);
      expect(ZiboEvent.fromJson('x', {'type': 'takvim'}), isNull);
    });
  });

  group('EventsProvider', () {
    late DateTime clock;

    Future<EventsProvider> make(List<ZiboEvent> events) async {
      final p = EventsProvider(now: () => clock);
      await p.ready;
      p.setEvents(events);
      return p;
    }

    test('başlamadan önce yaklaşan, başlayınca aktif; bilinmeyen tür ve kapalı gizli', () async {
      clock = DateTime(2026, 11, 20, 12);
      final p = await make([_calendar(), _calendar(type: 'yaris'), _calendar(enabled: false)]);
      expect(p.active, isEmpty);
      expect(p.upcoming.length, 1);
      expect(p.openableCount, 0);
      clock = DateTime(2026, 12, 1, 9);
      expect(p.active.length, 1);
      expect(p.upcoming, isEmpty);
    });

    test('bugünün kutusu açılır, ikinci kez açılmaz, gelecek kilitli', () async {
      clock = DateTime(2026, 12, 3, 9);
      final p = await make([_calendar()]);
      final e = p.active.single;
      expect(p.todayIndex(e), 2);
      expect(p.canOpen(e, 3), isFalse); // yarın
      expect(p.open(e, 2)?.zc, 20);
      expect(p.open(e, 2), isNull);
      expect(p.isOpened(e, 2), isTrue);
    });

    test('kaçırılan günler catchUp ile sonradan açılır, kapalıyken açılmaz', () async {
      clock = DateTime(2026, 12, 3, 9);
      final p = await make([_calendar()]);
      expect(p.openableCount, 3);
      final strict = await make([_calendar(catchUp: false)]);
      final e = strict.active.single;
      expect(strict.canOpen(e, 0), isFalse);
      expect(strict.canOpen(e, 2), isTrue);
    });

    test('etkinlik bitince kutu açılmaz; açılan günler kayıtta kalır', () async {
      clock = DateTime(2026, 12, 2, 9);
      final p = await make([_calendar()]);
      p.open(p.active.single, 1);
      await Future<void>.delayed(Duration.zero);
      final q = await make([_calendar()]);
      expect(q.isOpened(_calendar(), 1), isTrue);
      clock = DateTime(2026, 12, 26, 9);
      expect(q.canOpen(_calendar(), 5), isFalse);
      expect(q.active, isEmpty);
    });

    test('Firestore\'dan yalnızca açık etkinlikler okunur', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('events').doc('a').set({
        'type': 'takvim',
        'enabled': true,
        'title': {'tr': 'A'},
        'start': '2026-12-01',
        'end': '2026-12-02',
        'days': [
          {'zc': 5},
        ],
      });
      await db.collection('events').doc('b').set({
        'type': 'takvim',
        'enabled': false,
        'start': '2026-12-01',
        'end': '2026-12-02',
      });
      clock = DateTime(2026, 12, 1);
      final p = EventsProvider(firestore: db, now: () => clock);
      await p.ready;
      expect(p.active.map((e) => e.id), ['a']);
    });
  });

  testWidgets('Etkinlikler ekranı: kutuyu aç → ZC ve eşya ödülü uygulanır', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    var clock = DateTime(2026, 12, 25, 9);
    final events = EventsProvider(now: () => clock);
    final decor = HomeDecorProvider();
    final coins = CoinProvider(now: () => clock, isSoundEnabled: () => false);
    await tester.runAsync(() async {
      await events.ready;
      await decor.ready;
      while (!coins.isReady) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    events.setEvents([_calendar()]);
    final start = coins.balance;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: events),
          ChangeNotifierProvider.value(value: decor),
          ChangeNotifierProvider.value(value: coins),
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
          home: const EventsScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Yılbaşı takvimi'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('1. gün'));
    await tester.pumpAndSettle();
    expect(find.text('+20 ZC'), findsOneWidget);
    await tester.tap(find.text('Harika'));
    await tester.pumpAndSettle();
    expect(coins.balance, start + 20);

    await tester.ensureVisible(find.bySemanticsLabel('25. gün'));
    await tester.tap(find.bySemanticsLabel('25. gün'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni eşya: Yılbaşı çamı'), findsOneWidget);
    await tester.tap(find.text('Harika'));
    await tester.pumpAndSettle();
    expect(decor.isOwned(HomeRoom.living, 'kose', 'cam'), isTrue);
    expect(events.openableCount, 23);
  });
}
