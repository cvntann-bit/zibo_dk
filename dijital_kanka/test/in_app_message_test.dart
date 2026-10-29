import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/in_app_message.dart';
import 'package:dijital_kanka/providers/in_app_message_provider.dart';
import 'package:dijital_kanka/widgets/in_app_message_card.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 10, 29, 12);

Map<String, dynamic> _doc({
  String audience = 'all',
  DateTime? start,
  DateTime? end,
  Map<String, Object?>? texts,
  String? onlyUid,
}) => {
  'startAt': Timestamp.fromDate(start ?? _now.subtract(const Duration(hours: 1))),
  'endAt': Timestamp.fromDate(end ?? _now.add(const Duration(days: 3))),
  'emoji': '🎉',
  'audience': audience,
  'texts': texts ??
      {
        'tr': {'title': 'Merhaba', 'body': 'Yeni özellik geldi'},
      },
  'onlyUid': ?onlyUid,
};

InAppMessage _msg(String id, Map<String, dynamic> data) => InAppMessage.fromFirestore(id, data)!;

InAppMessage? _pick(
  List<InAppMessage> messages, {
  bool isPro = false,
  String lang = 'tr',
  String? uid = 'u1',
  Set<String> seen = const {},
}) => pickInAppMessage(messages, now: _now, uid: uid, isPro: isPro, languageCode: lang, seenIds: seen);

void main() {
  group('InAppMessage.fromFirestore', () {
    test('geçerli belgeyi okur, boş dil metinlerini atar', () {
      final m = _msg('a', _doc(texts: {
        'tr': {'title': ' Merhaba ', 'body': 'Metin'},
        'en': {'title': '', 'body': 'x'},
      }));
      expect(m.texts.keys, ['tr']);
      expect(m.texts['tr']!.title, 'Merhaba');
      expect(m.emoji, '🎉');
    });

    test('tarih ya da metin eksikse null', () {
      expect(InAppMessage.fromFirestore('a', {'texts': {}}), isNull);
      expect(InAppMessage.fromFirestore('a', _doc(texts: {})), isNull);
    });
  });

  group('pickInAppMessage', () {
    test('dil, kitle ve tarih süzgeci', () {
      final all = _msg('all', _doc());
      expect(_pick([all])?.id, 'all');
      expect(_pick([all], lang: 'es'), isNull, reason: 'İspanyolca metin yok');

      final pro = _msg('pro', _doc(audience: 'pro'));
      expect(_pick([pro]), isNull);
      expect(_pick([pro], isPro: true)?.id, 'pro');

      final free = _msg('free', _doc(audience: 'free'));
      expect(_pick([free], isPro: true), isNull);

      final future = _msg('f', _doc(start: _now.add(const Duration(hours: 1))));
      final ended = _msg('e', _doc(end: _now));
      expect(_pick([future, ended]), isNull);
    });

    test('onlyUid yalnızca o hesaba', () {
      final m = _msg('t', _doc(onlyUid: 'u1'));
      expect(_pick([m])?.id, 't');
      expect(_pick([m], uid: 'u2'), isNull);
    });

    test('görülen atlanır, en yeni başlayan seçilir', () {
      final older = _msg('old', _doc(start: _now.subtract(const Duration(days: 2))));
      final newer = _msg('new', _doc(start: _now.subtract(const Duration(hours: 2))));
      expect(_pick([older, newer])?.id, 'new');
      expect(_pick([older, newer], seen: {'new'})?.id, 'old');
    });
  });

  group('InAppMessageProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('süresi bitmemiş kartları okur, görüleni kalıcı işaretler', () async {
      final firestore = FakeFirebaseFirestore();
      final real = DateTime.now();
      await firestore.collection('inAppMessages').doc('live').set(
        _doc(start: real.subtract(const Duration(hours: 1)), end: real.add(const Duration(days: 1))),
      );
      await firestore.collection('inAppMessages').doc('old').set(
        _doc(start: real.subtract(const Duration(days: 9)), end: real.subtract(const Duration(days: 2))),
      );

      final provider = InAppMessageProvider(uid: 'u1', firestore: firestore);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.messages.map((m) => m.id), ['live']);

      await provider.markSeen('live');
      final reloaded = InAppMessageProvider(uid: 'u1', firestore: firestore);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reloaded.seenIds, {'live'});
    });

    test('uid yoksa Firestore okunmaz', () async {
      final provider = InAppMessageProvider();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(provider.messages, isEmpty);
    });
  });

  testWidgets('kart başlık/metni gösterir, Tamam ile kapanır', (tester) async {
    final message = _msg('a', _doc());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showInAppMessageCard(context, message: message, languageCode: 'tr'),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppMessageCard')), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
    expect(find.text('Yeni özellik geldi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inAppMessageOkButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppMessageCard')), findsNothing);
  });
}
