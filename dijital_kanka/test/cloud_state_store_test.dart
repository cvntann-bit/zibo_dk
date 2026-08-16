// CloudStateStore'un yerel/Firestore/migrasyon mantığını test eder:
// - uid yoksa tamamen yerel (SharedPreferences) kalır, Firestore'a hiç dokunmaz.
// - uid varsa ve Firestore'da henüz veri yoksa, yereldeki (varsa) eski veriyi
//   Firestore'a göç ettirir.
// - uid varsa ve Firestore'da zaten veri varsa, onu döner.
// - save() her zaman hem yerele hem (uid varsa) Firestore'a yazar.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/services/cloud_state_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CloudStateStore', () {
    test('uid yoksa load() yerelden okur, Firestore hiç kullanılmaz', () async {
      SharedPreferences.setMockInitialValues({
        'testKey': '{"balance": 42}',
      });
      final firestore = FakeFirebaseFirestore();
      final store = CloudStateStore(prefsKey: 'testKey', firestore: firestore);

      final data = await store.load();

      expect(data, {'balance': 42});
      final snapshot = await firestore.collection('users').get();
      expect(snapshot.docs, isEmpty); // Firestore'a hiç yazılmadı
    });

    test('uid yoksa save() yalnızca yerele yazar', () async {
      final firestore = FakeFirebaseFirestore();
      final store = CloudStateStore(prefsKey: 'testKey', firestore: firestore);

      await store.save({'balance': 10});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('testKey'), '{"balance":10}');
      final snapshot = await firestore.collection('users').get();
      expect(snapshot.docs, isEmpty);
    });

    test(
      'uid var, Firestore boş, yerelde eski veri var: load() Firestore\'a göç ettirir',
      () async {
        SharedPreferences.setMockInitialValues({
          'testKey': '{"balance": 100}',
        });
        final firestore = FakeFirebaseFirestore();
        final store = CloudStateStore(prefsKey: 'testKey', uid: 'user1', firestore: firestore);

        final data = await store.load();

        expect(data, {'balance': 100});
        final doc = await firestore
            .collection('users')
            .doc('user1')
            .collection('state')
            .doc('testKey')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data(), {'balance': 100});
      },
    );

    test('uid var, Firestore boş, yerelde de veri yok: load() null döner', () async {
      final firestore = FakeFirebaseFirestore();
      final store = CloudStateStore(prefsKey: 'testKey', uid: 'user1', firestore: firestore);

      final data = await store.load();

      expect(data, isNull);
    });

    test(
      'uid var, Firestore\'da zaten veri var: load() Firestore\'daki değeri döner (yereli yok sayar)',
      () async {
        SharedPreferences.setMockInitialValues({
          'testKey': '{"balance": 999}', // eski/farklı yerel değer
        });
        final firestore = FakeFirebaseFirestore();
        await firestore
            .collection('users')
            .doc('user1')
            .collection('state')
            .doc('testKey')
            .set({'balance': 250});
        final store = CloudStateStore(prefsKey: 'testKey', uid: 'user1', firestore: firestore);

        final data = await store.load();

        expect(data, {'balance': 250});
      },
    );

    test('uid varsa save() hem yerele hem Firestore\'a yazar', () async {
      final firestore = FakeFirebaseFirestore();
      final store = CloudStateStore(prefsKey: 'testKey', uid: 'user1', firestore: firestore);

      await store.save({'balance': 77});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('testKey'), '{"balance":77}');
      final doc = await firestore
          .collection('users')
          .doc('user1')
          .collection('state')
          .doc('testKey')
          .get();
      expect(doc.data(), {'balance': 77});
    });

    test(
      'İki farklı kullanıcı (uid) aynı prefsKey ile birbirinden izole veri tutar',
      () async {
        final firestore = FakeFirebaseFirestore();
        final storeA = CloudStateStore(prefsKey: 'testKey', uid: 'userA', firestore: firestore);
        final storeB = CloudStateStore(prefsKey: 'testKey', uid: 'userB', firestore: firestore);

        await storeA.save({'balance': 1});
        await storeB.save({'balance': 2});

        final docA = await firestore
            .collection('users')
            .doc('userA')
            .collection('state')
            .doc('testKey')
            .get();
        final docB = await firestore
            .collection('users')
            .doc('userB')
            .collection('state')
            .doc('testKey')
            .get();
        expect(docA.data(), {'balance': 1});
        expect(docB.data(), {'balance': 2});
      },
    );
  });
}
