// FounderBadgeProvider'ın canlı sayaç izlemesini VE claimIfEligible()'ın
// atomik-transaction mantığını doğrudan (widget pump'lamadan) test eder:
// sayaç dokümanı henüz yoksa özellik sessizce devre dışı kalır, dolu
// (500) iken kimse rozet kazanamaz, zaten sahip olan bir kullanıcı ikinci
// kez sayacı artırmaz, başarılı bir kazanım hem sayacı hem kullanıcının
// costumeState'ini doğru şekilde günceller, ve uid yokken (Firebase
// kullanılamıyor) özellik tamamen devre dışıdır — `referral_provider_
// test.dart`'taki AYNI `fake_cloud_firestore` deseni.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/providers/founder_badge_provider.dart';

void main() {
  group('FounderBadgeProvider', () {
    test('uid yoksa özellik tamamen devre dışıdır', () async {
      final provider = FounderBadgeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoaded, isFalse);
      expect(await provider.claimIfEligible(), isFalse);
    });

    test(
      'founderBadgeStatus/status dokümanı henüz seed edilmediyse '
      'canlı sayaç yüklenmez VE kazanma denemesi sessizce false döner',
      () async {
        final firestore = FakeFirebaseFirestore();
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isLoaded, isFalse);
        expect(await provider.claimIfEligible(), isFalse);
      },
    );

    test(
      'Sayaç dokümanı gerçek zamanlı (canlı) izleniyor — dışarıdan '
      'değişince claimedCount/remainingSlots/isSoldOut güncellenir',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 12,
        });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isLoaded, isTrue);
        expect(provider.claimedCount, 12);
        expect(provider.remainingSlots, 488);
        expect(provider.isSoldOut, isFalse);

        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 500,
        });
        await Future<void>.delayed(Duration.zero);

        expect(provider.claimedCount, 500);
        expect(provider.remainingSlots, 0);
        expect(provider.isSoldOut, isTrue);
      },
    );

    test(
      'Kontenjan (500) doluyken kimse rozet kazanamaz, sayaç DEĞİŞMEZ',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 500,
        });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        final won = await provider.claimIfEligible();

        expect(won, isFalse);
        final snap = await firestore
            .collection('founderBadgeStatus')
            .doc('status')
            .get();
        expect(snap.data()!['count'], 500);
      },
    );

    test(
      'Kontenjan varken başarılı bir kazanım — sayaç +1 artar VE '
      'costumeState.ownedIds\'e founder_badge eklenir',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 10,
        });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        final won = await provider.claimIfEligible();

        expect(won, isTrue);
        final statusSnap = await firestore
            .collection('founderBadgeStatus')
            .doc('status')
            .get();
        expect(statusSnap.data()!['count'], 11);

        final costumeSnap = await firestore
            .collection('users')
            .doc('uidA')
            .collection('state')
            .doc('costumeState')
            .get();
        expect(costumeSnap.data()!['ownedIds'], contains('founder_badge'));
      },
    );

    test(
      'Zaten kostüm sahipliği olan (equippedId dolu) bir kullanıcıda '
      'mevcut equippedId KORUNUR — üzerine yazılmaz',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 3,
        });
        await firestore
            .collection('users')
            .doc('uidA')
            .collection('state')
            .doc('costumeState')
            .set({
              'ownedIds': ['zibo_hippi'],
              'equippedId': 'zibo_hippi',
            });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        await provider.claimIfEligible();

        final costumeSnap = await firestore
            .collection('users')
            .doc('uidA')
            .collection('state')
            .doc('costumeState')
            .get();
        expect(
          costumeSnap.data()!['ownedIds'],
          containsAll(['zibo_hippi', 'founder_badge']),
        );
        expect(costumeSnap.data()!['equippedId'], 'zibo_hippi');
      },
    );

    test(
      'Zaten founder_badge sahibi olan bir kullanıcı ikinci kez '
      'çağırınca sayacı BİR DAHA artırmaz (idempotent)',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 7,
        });
        await firestore
            .collection('users')
            .doc('uidA')
            .collection('state')
            .doc('costumeState')
            .set({
              'ownedIds': ['founder_badge'],
              'equippedId': null,
            });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        final won = await provider.claimIfEligible();

        expect(won, isFalse);
        final statusSnap = await firestore
            .collection('founderBadgeStatus')
            .doc('status')
            .get();
        expect(statusSnap.data()!['count'], 7);
      },
    );

    test(
      'isClaiming, claimIfEligible() sürerken true, tamamlanınca false',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('founderBadgeStatus').doc('status').set({
          'count': 1,
        });
        final provider = FounderBadgeProvider(uid: 'uidA', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isClaiming, isFalse);
        final future = provider.claimIfEligible();
        expect(provider.isClaiming, isTrue);
        await future;
        expect(provider.isClaiming, isFalse);
      },
    );
  });
}
