// AuthLinkProvider'ın Google hesap bağlama/giriş/çıkış davranışını test
// eder — gerçek `google_sign_in`/`firebase_auth` platform kanalına hiç
// dokunulmuyor, `GoogleAuthService`'in enjekte edilebilir bir sahte
// implementasyonu kullanılıyor (bkz. `manifest_journal_screen_test.dart`'taki
// AYNI "gerçek servis, testte enjekte edilebilir sahte" deseni).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/auth_link_provider.dart';
import 'package:dijital_kanka/services/google_auth_service.dart';

class _FakeGoogleAuthService extends GoogleAuthService {
  _FakeGoogleAuthService({this.linked = false, this.email});

  bool linked;
  String? email;

  String? nextLinkEmail;
  Object? linkError;
  int linkCallCount = 0;

  GoogleSignInOutcome? nextSignInOutcome;
  int signInCallCount = 0;

  String? nextSignOutUid;
  int signOutCallCount = 0;

  @override
  Future<String?> linkCurrentUser() async {
    linkCallCount++;
    if (linkError != null) throw linkError!;
    if (nextLinkEmail != null) {
      linked = true;
      email = nextLinkEmail;
    }
    return nextLinkEmail;
  }

  @override
  Future<GoogleSignInOutcome?> signIn() async {
    signInCallCount++;
    return nextSignInOutcome;
  }

  @override
  bool get isCurrentUserLinked => linked;

  @override
  String? get linkedEmail => email;

  @override
  Future<String?> signOut() async {
    signOutCallCount++;
    return nextSignOutUid;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthLinkProvider', () {
    test('Varsayılan durum: bağlı değil, yükleniyor değil', () async {
      final provider = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLinked, false);
      expect(provider.linkedEmail, null);
      expect(provider.isLinking, false);
      expect(provider.hasSeenLinkPrompt, false);
    });

    test(
      'linkWithGoogle başarılı olunca isLinked/linkedEmail güncellenir',
      () async {
        final service = _FakeGoogleAuthService()
          ..nextLinkEmail = 'kanka@example.com';
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        final result = await provider.linkWithGoogle();

        expect(result, true);
        expect(provider.isLinked, true);
        expect(provider.linkedEmail, 'kanka@example.com');
        expect(service.linkCallCount, 1);
      },
    );

    test(
      'linkWithGoogle kullanıcı vazgeçerse (email null) false döner, '
      'bağlı kalmaz',
      () async {
        final service = _FakeGoogleAuthService();
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        final result = await provider.linkWithGoogle();

        expect(result, false);
        expect(provider.isLinked, false);
      },
    );

    test(
      'linkWithGoogle GoogleAccountAlreadyLinkedElsewhereException fırlatırsa '
      'çağırana YAYILIR, isLinking yine de false\'a döner',
      () async {
        final service = _FakeGoogleAuthService()
          ..linkError = const GoogleAccountAlreadyLinkedElsewhereException();
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        await expectLater(
          provider.linkWithGoogle(),
          throwsA(isA<GoogleAccountAlreadyLinkedElsewhereException>()),
        );
        expect(provider.isLinking, false);
      },
    );

    test(
      '2026 bug düzeltmesi — linkWithGoogle GoogleSignInMissingIdTokenException '
      'fırlatırsa (idToken null geldi, kullanıcı VAZGEÇMEDİ) çağırana YAYILIR, '
      'SESSİZCE false DÖNMEZ',
      () async {
        final service = _FakeGoogleAuthService()
          ..linkError = const GoogleSignInMissingIdTokenException();
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        await expectLater(
          provider.linkWithGoogle(),
          throwsA(isA<GoogleSignInMissingIdTokenException>()),
        );
        expect(provider.isLinking, false);
      },
    );

    test(
      '2026 bug düzeltmesi — linkWithGoogle GoogleSignInReauthFailedException '
      'fırlatırsa (Google "[16] Account reauth failed" diyor, kullanıcı '
      'VAZGEÇMEDİ) çağırana YAYILIR, SESSİZCE false DÖNMEZ',
      () async {
        final service = _FakeGoogleAuthService()
          ..linkError = const GoogleSignInReauthFailedException(
            '[16] Account reauth failed.',
          );
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        await expectLater(
          provider.linkWithGoogle(),
          throwsA(isA<GoogleSignInReauthFailedException>()),
        );
        expect(provider.isLinking, false);
      },
    );

    test('signInWithGoogle servisin döndürdüğü outcome\'u aynen döner', () async {
      final service = _FakeGoogleAuthService()
        ..nextSignInOutcome = const GoogleSignInOutcome(
          uid: 'recovered-uid',
          email: 'eski@example.com',
        );
      final provider = AuthLinkProvider(googleAuthService: service);
      await Future<void>.delayed(Duration.zero);

      final outcome = await provider.signInWithGoogle();

      expect(outcome?.uid, 'recovered-uid');
      expect(outcome?.email, 'eski@example.com');
      expect(service.signInCallCount, 1);
    });

    test(
      'signOut servisi çağırır, YENİ anonim uid\'i döner ve isLinking '
      'işlem sırasında true, sonra false olur',
      () async {
        final service = _FakeGoogleAuthService(linked: true, email: 'a@b.com')
          ..nextSignOutUid = 'fresh-anon-uid';
        final provider = AuthLinkProvider(googleAuthService: service);
        await Future<void>.delayed(Duration.zero);

        expect(provider.isLinking, false);
        final future = provider.signOut();
        expect(provider.isLinking, true);
        final newUid = await future;

        expect(newUid, 'fresh-anon-uid');
        expect(service.signOutCallCount, 1);
        expect(provider.isLinking, false);
      },
    );

    test(
      'markLinkPromptSeen bir kez çağrılınca hasSeenLinkPrompt kalıcı olur',
      () async {
        final provider = AuthLinkProvider(
          googleAuthService: _FakeGoogleAuthService(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(provider.hasSeenLinkPrompt, false);

        await provider.markLinkPromptSeen();
        expect(provider.hasSeenLinkPrompt, true);

        final reloaded = AuthLinkProvider(
          googleAuthService: _FakeGoogleAuthService(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(reloaded.hasSeenLinkPrompt, true);
      },
    );
  });
}
