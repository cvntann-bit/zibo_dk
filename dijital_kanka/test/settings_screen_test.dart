// Ayarlar sayfasındaki Google hesabı bölümünü test eder: hesap bağlı
// DEĞİLKEN jenerik ikon gösterilip Çıkış Yap/Hesap Değiştir butonları HİÇ
// görünmüyor (bkz. CLAUDE.md "Google Hesap Bağlama" — anonim bir hesaptan
// "çıkış yapmak" geri dönüşsüz veri kaybı olurdu); hesap BAĞLIYKEN Google
// logosu + iki buton görünüyor ve doğru AuthLinkProvider metotlarını
// tetikliyor. Gerçek `google_sign_in`/`firebase_auth` platform kanalına hiç
// dokunulmuyor — `auth_link_provider_test.dart`'taki AYNI sahte
// `GoogleAuthService` deseni burada da kullanılıyor.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/app_streak_provider.dart';
import 'package:dijital_kanka/providers/auth_link_provider.dart';
import 'package:dijital_kanka/providers/founder_badge_provider.dart';
import 'package:dijital_kanka/providers/locale_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/theme_provider.dart';
import 'package:dijital_kanka/screens/settings_screen.dart';
import 'package:dijital_kanka/services/google_auth_service.dart';
import 'package:dijital_kanka/utils/auth_switch.dart';

class _FakeGoogleAuthService extends GoogleAuthService {
  _FakeGoogleAuthService({this.linked = false, this.email});

  bool linked;
  String? email;

  GoogleSignInOutcome? nextSignInOutcome;
  int signInCallCount = 0;

  String? nextSignOutUid;
  int signOutCallCount = 0;

  @override
  Future<String?> linkCurrentUser() async => null;

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

Widget _buildTestApp(AuthLinkProvider authLink) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => AppStreakProvider()),
      ChangeNotifierProvider(create: (_) => FounderBadgeProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider.value(value: authLink),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    switchToUid.value = null;

    // Gerçekçi telefon viewport'u (widget_test.dart'ın `setUp()`'ıyla AYNI
    // desen, bkz. CLAUDE.md "Test kalıpları") — varsayılan 800x600
    // masaüstü-oranlı test yüzeyi, Çıkış Yap/Hesap Değiştir butonlarının
    // yan yana sığıp SIĞMADIĞINI (RenderFlex overflow) GİZLEYEBİLİRDİ.
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher as TestPlatformDispatcher;
    for (final view in dispatcher.views) {
      view.physicalSize = const Size(412, 915);
      view.devicePixelRatio = 1.0;
    }
    addTearDown(() {
      for (final view in dispatcher.views) {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      }
    });
  });

  testWidgets(
    'Hesap bağlı DEĞİLKEN: jenerik link ikonu görünür, Çıkış Yap/Hesap '
    'Değiştir butonları HİÇ görünmez',
    (tester) async {
      final authLink = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(),
      );
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text('Çıkış Yap'), findsNothing);
      expect(find.text('Hesap Değiştir'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hesap BAĞLIYKEN: Google logosu + Çıkış Yap/Hesap Değiştir butonları '
    'görünür, gerçekçi dar viewport\'ta RenderFlex overflow OLMAZ',
    (tester) async {
      final authLink = AuthLinkProvider(
        googleAuthService: _FakeGoogleAuthService(
          linked: true,
          email: 'kanka@example.com',
        ),
      );
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('kanka@example.com'), findsOneWidget);
      expect(find.text('Çıkış Yap'), findsOneWidget);
      expect(find.text('Hesap Değiştir'), findsOneWidget);
      // `pumpAndSettle()` bir RenderFlex overflow'unu varsayılan olarak
      // sessizce geçebiliyor (bkz. CLAUDE.md "Test kalıpları") —
      // `takeException()` ile açıkça kontrol ediliyor.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Çıkış Yap: onay diyaloğunda vazgeçilirse signOut ÇAĞRILMAZ',
    (tester) async {
      final service = _FakeGoogleAuthService(linked: true, email: 'a@b.com')
        ..nextSignOutUid = 'fresh-uid';
      final authLink = AuthLinkProvider(googleAuthService: service);
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Çıkış Yap'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Çıkış yapmak istediğine emin misin?'),
        findsOneWidget,
      );

      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(service.signOutCallCount, 0);
      expect(switchToUid.value, null);
    },
  );

  testWidgets(
    'Çıkış Yap: onaylanınca signOut çağrılır ve switchToUid YENİ uid\'e '
    'güncellenir',
    (tester) async {
      final service = _FakeGoogleAuthService(linked: true, email: 'a@b.com')
        ..nextSignOutUid = 'fresh-anon-uid';
      final authLink = AuthLinkProvider(googleAuthService: service);
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Çıkış Yap'));
      await tester.pumpAndSettle();
      // Diyalogdaki onay butonu da "Çıkış Yap" metnini taşıyor (bkz.
      // google_link_action.dart) — `findsNWidgets(2)` (satırdaki buton +
      // diyalog butonu), sonuncusuna dokunuyoruz.
      await tester.tap(find.text('Çıkış Yap').last);
      await tester.pumpAndSettle();

      expect(service.signOutCallCount, 1);
      expect(switchToUid.value, 'fresh-anon-uid');
    },
  );

  testWidgets(
    'Hesap Değiştir: onay istemeden doğrudan signIn çağrılır ve switchToUid '
    'seçilen hesabın uid\'ine güncellenir',
    (tester) async {
      final service = _FakeGoogleAuthService(linked: true, email: 'a@b.com')
        ..nextSignInOutcome = const GoogleSignInOutcome(
          uid: 'other-account-uid',
          email: 'baska@example.com',
        );
      final authLink = AuthLinkProvider(googleAuthService: service);
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hesap Değiştir'));
      await tester.pumpAndSettle();

      expect(service.signInCallCount, 1);
      expect(switchToUid.value, 'other-account-uid');
    },
  );

  testWidgets(
    'Hesap Değiştir: kullanıcı hesap seçiciyi iptal ederse (signIn null '
    'döner) switchToUid DEĞİŞMEZ',
    (tester) async {
      final service = _FakeGoogleAuthService(linked: true, email: 'a@b.com');
      final authLink = AuthLinkProvider(googleAuthService: service);
      await tester.pumpWidget(_buildTestApp(authLink));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hesap Değiştir'));
      await tester.pumpAndSettle();

      expect(service.signInCallCount, 1);
      expect(switchToUid.value, null);
    },
  );
}
