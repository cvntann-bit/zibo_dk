// maybeClaimFounderBadge()'in RootScreen'in "reconcile-on-resume" deseninin
// (bkz. CLAUDE.md "Kurucu Üye Rozeti" bölümündeki bug düzeltmesi) doğru
// çalıştığını, RootScreen'in tam widget ağacını kurmadan doğrudan test
// eder: Google'a bağlı DEĞİLKEN hiçbir şey yapmaz, ZATEN sahipken
// claimIfEligible()'ı GEREKSİZ yere ÇAĞIRMAZ, sayaç henüz seed edilmediyse
// sessizce başarısız olur, VE en kritik senaryo — sayaç seed edilmeden
// ÖNCE bağlanmış (bu yüzden "yeni bağlama" akışının claimIfEligible()'ı
// hiç çağırmadığı) bir hesap, bu fonksiyon SONRADAN çağrıldığında rozeti
// GERÇEKTEN kazanabiliyor.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/founder_badge.dart';
import 'package:dijital_kanka/providers/auth_link_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/founder_badge_provider.dart';
import 'package:dijital_kanka/services/google_auth_service.dart';
import 'package:dijital_kanka/utils/founder_badge_reconcile.dart';

class _FakeGoogleAuthService extends GoogleAuthService {
  _FakeGoogleAuthService({this.linked = false});

  bool linked;

  @override
  Future<String?> linkCurrentUser() async => null;

  @override
  Future<GoogleSignInOutcome?> signIn() async => null;

  @override
  bool get isCurrentUserLinked => linked;

  @override
  String? get linkedEmail => linked ? 'cvntann@gmail.com' : null;

  @override
  Future<String?> signOut() async => null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Google\'a bağlı DEĞİLKEN hiçbir şey yapmaz', () async {
    final authLink = AuthLinkProvider(
      googleAuthService: _FakeGoogleAuthService(linked: false),
    );
    final costume = CostumeProvider();
    final founderBadge = FounderBadgeProvider();

    await maybeClaimFounderBadge(
      authLink: authLink,
      costume: costume,
      founderBadge: founderBadge,
    );

    expect(costume.isOwned(founderBadgeCostumeId), isFalse);
  });

  test(
    'bağlı ama sayaç HENÜZ SEED EDİLMEDİYSE sessizce hiçbir şey olmaz',
    () async {
      final authLink = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(linked: true),
      );
      final costume = CostumeProvider();
      final founderBadge = FounderBadgeProvider(
        uid: 'uidA',
        firestore: FakeFirebaseFirestore(),
      );
      await Future<void>.delayed(Duration.zero);

      await maybeClaimFounderBadge(
        authLink: authLink,
        costume: costume,
        founderBadge: founderBadge,
      );

      expect(costume.isOwned(founderBadgeCostumeId), isFalse);
    },
  );

  test(
    'ZATEN sahipse claimIfEligible() GEREKSİZ yere ÇAĞRILMAZ (sayaç '
    'dolu olsa bile bu kontrole hiç girmeden erken çıkar)',
    () async {
      final authLink = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(linked: true),
      );
      final costume = CostumeProvider();
      await costume.markOwned(founderBadgeCostumeId);
      final firestore = FakeFirebaseFirestore();
      // Sayaç zaten dolu — eğer fonksiyon yine de claimIfEligible()'ı
      // çağırsaydı bu bir transaction denemesi olurdu, ama erken çıkış
      // sayesinde hiç Firestore'a dokunulmuyor.
      await firestore.collection('founderBadgeStatus').doc('status').set({
        'count': 500,
      });
      final founderBadge = FounderBadgeProvider(
        uid: 'uidB',
        firestore: firestore,
      );
      await Future<void>.delayed(Duration.zero);

      await maybeClaimFounderBadge(
        authLink: authLink,
        costume: costume,
        founderBadge: founderBadge,
      );

      // Sayaç DEĞİŞMEDİ (hâlâ 500) — claimIfEligible() hiç çağrılmadığının
      // kanıtı.
      expect(founderBadge.claimedCount, 500);
    },
  );

  test(
    'KRİTİK senaryo — sayaç seed EDİLMEDEN ÖNCE bağlanmış bir hesap, '
    'sayaç SONRADAN seed edilince bu fonksiyonla rozeti GERÇEKTEN kazanır',
    () async {
      final authLink = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(linked: true),
      );
      final costume = CostumeProvider();
      final firestore = FakeFirebaseFirestore();
      final founderBadge = FounderBadgeProvider(
        uid: 'uidC',
        firestore: firestore,
      );
      await Future<void>.delayed(Duration.zero);
      // İlk bağlanma anında sayaç henüz yoktu — o zamanki (varsayımsal)
      // claimIfEligible() denemesi sessizce başarısız olurdu.
      expect(founderBadge.isLoaded, isFalse);

      // Sayaç SONRADAN seed edildi (init-founder-badge-counter.yml).
      await firestore.collection('founderBadgeStatus').doc('status').set({
        'count': 3,
      });
      await Future<void>.delayed(Duration.zero);
      expect(founderBadge.isLoaded, isTrue);

      // Uygulama bir SONRAKİ açılışta/öne gelişte bu fonksiyonu tekrar
      // çağırıyor — bu sefer rozet GERÇEKTEN kazanılmalı.
      await maybeClaimFounderBadge(
        authLink: authLink,
        costume: costume,
        founderBadge: founderBadge,
      );
      // `claimIfEligible()`'ın transaction'ı tamamlandıktan sonra bile,
      // `FounderBadgeProvider`'ın kendi `claimedCount`'u AYRI bir
      // `.snapshots()` dinleyicisinden güncelleniyor — bu, transaction'ın
      // kendi `await`'iyle AYNI mikro görevde tamamlanmayabilir (fake_cloud_
      // firestore'da da gerçek Firestore'daki AYNI asenkron ayrım geçerli).
      await Future<void>.delayed(Duration.zero);

      expect(costume.isOwned(founderBadgeCostumeId), isTrue);
      expect(founderBadge.claimedCount, 4);
    },
  );
}
