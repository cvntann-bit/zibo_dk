// ReferralProvider'ın davet kodu (= kullanıcının kendi uid'i) gösterimini
// VE redeemCode() mantığını doğrudan (widget pump'lamadan) test eder:
// kendi kodunu kullanma reddedilir, boş kod reddedilir, geçerli bir kod
// `referralRedemptions` koleksiyonuna doğru şekilli bir "pending" kaydı
// bırakır, ikinci bir redeem denemesi reddedilir, uid yokken özellik
// tamamen devre dışı kalır, ve durum kalıcıdır (yeniden başlatmada hatırlanır).
// Asıl coin kredisi burada test EDİLMİYOR — bu, `notification-scripts/src/
// processReferralRewards.js`'in (Node ortamı bu projede yok, bkz. CLAUDE.md)
// sorumluluğunda, yalnızca istemci tarafının doğru "işlem talebi" bıraktığı
// doğrulanıyor.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/referral_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReferralProvider', () {
    test('Davet kodu kendi uid\'idir, başlangıçta hiçbir kod kullanılmamıştır', () async {
      final provider = ReferralProvider(
        uid: 'uidA',
        firestore: FakeFirebaseFirestore(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.referralCode, 'uidA');
      expect(provider.hasRedeemed, isFalse);
      expect(provider.redeemedFromUid, isNull);
    });

    test('Kendi kodunu kullanmaya çalışmak reddedilir', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = ReferralProvider(uid: 'uidA', firestore: firestore);
      await Future<void>.delayed(Duration.zero);

      final result = await provider.redeemCode('uidA');

      expect(result, ReferralRedeemResult.selfCode);
      expect(provider.hasRedeemed, isFalse);
      final snap = await firestore.collection('referralRedemptions').get();
      expect(snap.docs, isEmpty);
    });

    test('Boş bir kod reddedilir', () async {
      final provider = ReferralProvider(
        uid: 'uidA',
        firestore: FakeFirebaseFirestore(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await provider.redeemCode(''), ReferralRedeemResult.invalidCode);
      expect(await provider.redeemCode('   '), ReferralRedeemResult.invalidCode);
      expect(provider.hasRedeemed, isFalse);
    });

    test(
      'Geçerli bir kod başarıyla gönderilir ve referralRedemptions\'a doğru '
      'şekilli bir "pending" kaydı bırakır',
      () async {
        final firestore = FakeFirebaseFirestore();
        final provider = ReferralProvider(uid: 'uidB', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        final result = await provider.redeemCode('uidA');

        expect(result, ReferralRedeemResult.success);
        expect(provider.hasRedeemed, isTrue);
        expect(provider.redeemedFromUid, 'uidA');

        final snap = await firestore.collection('referralRedemptions').get();
        expect(snap.docs, hasLength(1));
        final data = snap.docs.first.data();
        expect(data['referrerUid'], 'uidA');
        expect(data['refereeUid'], 'uidB');
        expect(data['status'], 'pending');
      },
    );

    test('Zaten bir kod kullanmış kullanıcı ikinci kez kod gönderemez', () async {
      final firestore = FakeFirebaseFirestore();
      final provider = ReferralProvider(uid: 'uidB', firestore: firestore);
      await Future<void>.delayed(Duration.zero);
      await provider.redeemCode('uidA');

      final secondResult = await provider.redeemCode('uidC');

      expect(secondResult, ReferralRedeemResult.alreadyRedeemed);
      expect(provider.redeemedFromUid, 'uidA'); // ilk kod korunur
      final snap = await firestore.collection('referralRedemptions').get();
      expect(snap.docs, hasLength(1)); // ikinci bir kayıt EKLENMEDİ
    });

    test('uid yoksa (Firebase kullanılamıyor) özellik tamamen devre dışıdır', () async {
      final provider = ReferralProvider();
      await Future<void>.delayed(Duration.zero);

      expect(provider.referralCode, isNull);
      expect(
        await provider.redeemCode('herhangi-bir-kod'),
        ReferralRedeemResult.unavailable,
      );
    });

    test(
      'Durum kalıcıdır — uygulama yeniden başlatılsa bile (yeni '
      'ReferralProvider, AYNI Firestore) hasRedeemed hatırlanır',
      () async {
        final firestore = FakeFirebaseFirestore();
        final first = ReferralProvider(uid: 'uidB', firestore: firestore);
        await Future<void>.delayed(Duration.zero);
        await first.redeemCode('uidA');

        final restarted = ReferralProvider(uid: 'uidB', firestore: firestore);
        await Future<void>.delayed(Duration.zero);

        expect(restarted.hasRedeemed, isTrue);
        expect(restarted.redeemedFromUid, 'uidA');
      },
    );
  });
}
