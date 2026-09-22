// Profil ekranını test eder: fotoğraf seçme + isim yazma kalıcı olarak
// kaydediliyor, "İstatistiklerim" bölümünde dört kategori kartı görünüyor,
// veri olmayan kategoriler teşvik mesajı gösteriyor. Gerçek image_picker/
// path_provider platform kanallarına hiç dokunulmaz — bkz.
// manifest_journal_screen_test.dart'taki aynı "enjekte edilebilir servis"
// deseni.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/founder_badge.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/auth_link_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';
import 'package:dijital_kanka/providers/focus_provider.dart';
import 'package:dijital_kanka/providers/founder_badge_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/instagram_follow_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/profile_stats_archive_provider.dart';
import 'package:dijital_kanka/providers/referral_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/trusted_time_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/providers/xp_provider.dart';
import 'package:dijital_kanka/screens/profile_screen.dart';
import 'package:dijital_kanka/services/photo_picker_service.dart';
import 'package:dijital_kanka/services/trusted_time_service.dart';

class _FakePhotoService extends PhotoPickerService {
  _FakePhotoService();

  String? nextPickedPath = '/fake/tmp/photo1.jpg';
  int saveCount = 0;
  final List<String> deletedPaths = [];

  @override
  Future<String?> pickFromGallery() async => nextPickedPath;

  @override
  Future<String> saveToPermanentStorage(String sourcePath) async {
    saveCount++;
    return '/fake/permanent/photo_$saveCount.jpg';
  }

  @override
  Future<void> deletePhoto(String path) async {
    deletedPaths.add(path);
  }
}

class _NeverSyncTimeService extends TrustedTimeService {
  const _NeverSyncTimeService();

  @override
  Future<DateTime?> fetchNetworkTime() async => null;
}

Widget _buildTestApp(PhotoPickerService photoService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => TrustedTimeProvider(timeService: const _NeverSyncTimeService()),
      ),
      ChangeNotifierProvider(create: (_) => AuthLinkProvider()),
      ChangeNotifierProvider(create: (_) => FounderBadgeProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => ProfileStatsArchiveProvider()),
      ChangeNotifierProvider(create: (_) => ReferralProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => MoneyProvider()),
      ChangeNotifierProvider(create: (_) => GratitudeProvider()),
      ChangeNotifierProvider(create: (_) => ManifestProvider()),
      ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => CoinProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteQuotesProvider()),
      ChangeNotifierProvider(create: (_) => XpProvider()),
      ChangeNotifierProvider(create: (_) => FocusProvider()),
      ChangeNotifierProvider(create: (_) => InstagramFollowProvider()),
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
      // ProfileScreen artık RootScreen'in ORTAK AppBar'ını/Scaffold'unu
      // paylaşan bir sekme (bkz. CLAUDE.md "Alt Gezinme Çubuğu" — Profil↔
      // Birikim yer değiştirme notu) — kendi Scaffold'u YOK, bu yüzden test
      // uygulaması gerçek RootScreen'in sağladığı Material ortamını (ör.
      // TextField'ın ihtiyaç duyduğu) burada elle sağlamalı.
      home: Scaffold(body: ProfileScreen(photoService: photoService)),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Varsayılan test görüntü alanı (800x600, geniş-kısa "masaüstü" oranı)
    // dört istatistik kartını + üstteki fotoğraf/isim alanını sığdırmıyor —
    // `widget_test.dart`'taki aynı gerçekçi telefon viewport'u (bkz. o
    // dosyadaki gotcha notu) burada da kullanılıyor.
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher as TestPlatformDispatcher;
    for (final view in dispatcher.views) {
      view.physicalSize = const Size(412, 1400);
      view.devicePixelRatio = 1.0;
    }
    addTearDown(() {
      for (final view in dispatcher.views) {
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      }
    });
  });

  testWidgets('Dört istatistik kartı da başlıklarıyla görünür', (tester) async {
    await tester.pumpWidget(_buildTestApp(_FakePhotoService()));
    await tester.pumpAndSettle();

    expect(find.text('Para Yönetimi'), findsOneWidget);
    expect(find.text('Şükür ve Manifest'), findsOneWidget);
    expect(find.text('İstikrar'), findsOneWidget);
    expect(find.text('Öz Saygı ve Sağlık'), findsOneWidget);
  });

  testWidgets(
    'Veri girilmemiş kategoriler (Para/Şükür-Manifest/Öz Saygı) teşvik mesajı gösterir',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(_FakePhotoService()));
      await tester.pumpAndSettle();

      expect(
        find.text("Henüz veri yok — Para ve Birikim'i kullanmaya başla!"),
        findsOneWidget,
      );
      expect(
        find.text("Henüz veri yok — Su Takibi'ni kullanmaya başla!"),
        findsOneWidget,
      );
    },
  );

  testWidgets('Fotoğrafa dokununca galeri seçilip kalıcı hale getirilir', (tester) async {
    final photoService = _FakePhotoService();
    await tester.pumpWidget(_buildTestApp(photoService));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel("Profil fotoğrafı, değiştirmek için dokun"));
    await tester.pumpAndSettle();

    expect(photoService.saveCount, 1);

    final element = tester.element(find.byType(ProfileScreen));
    final profile = Provider.of<ProfileProvider>(element, listen: false);
    expect(profile.photoPath, '/fake/permanent/photo_1.jpg');
  });

  testWidgets('İsim yazılıp gönderilince ProfileProvider\'a kaydedilir', (tester) async {
    await tester.pumpWidget(_buildTestApp(_FakePhotoService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ayşe');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ProfileScreen));
    final profile = Provider.of<ProfileProvider>(element, listen: false);
    expect(profile.name, 'Ayşe');
  });

  testWidgets(
    '"Kurucu Üye" rozeti yalnızca CostumeProvider.isOwned(founder_badge) '
    'true iken görünür',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(_FakePhotoService()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Kurucu Üye'), findsNothing);

      final element = tester.element(find.byType(ProfileScreen));
      final costume = Provider.of<CostumeProvider>(element, listen: false);
      await costume.markOwned(founderBadgeCostumeId);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Kurucu Üye'), findsOneWidget);
    },
  );
}
