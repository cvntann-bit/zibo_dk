// FocusTimerScreen'in immersive (kapkaranlık) çalışma modunu — Başlat'a
// basınca ekranın tamamen siyaha döndüğü, mod seçici/toplam süre kartı gibi
// dikkat dağıtıcı hiçbir şeyin GÖRÜNMEDİĞİ, ve isHomeTabActive'in ekran
// açıkken false'a sabitlenip kapanınca eski değerine döndüğü — doğrudan
// test eder. `manifest_journal_screen_test.dart` ile AYNI "bağımsız test
// uygulaması" deseni.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/focus_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/xp_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/focus_timer_screen.dart';
import 'package:dijital_kanka/utils/tab_navigation.dart';

Widget _buildTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => FocusProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => XpProvider()),
      ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale('tr'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FocusTimerScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    isHomeTabActive.value = true;
    // Gerçekçi telefon viewport'u (widget_test.dart'ın `setUp()`'ıyla AYNI
    // desen, bkz. CLAUDE.md "Test kalıpları") — varsayılan 800x600
    // masaüstü-oranlı test yüzeyi, Zibo görseli + söz balonu eklendikten
    // sonra "Başlat" butonunun `ListView`'ın lazy-realize penceresinin
    // dışında kalmasına yol açıyordu.
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

  testWidgets('Başlangıçta kurulum ekranı (mod seçici + Başlat) görünür', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Serbest'), findsOneWidget);
    expect(find.text('Başlat'), findsOneWidget);
    expect(find.text('Toplam Odak Süren'), findsOneWidget);
  });

  testWidgets(
    'Başlat\'a basınca ekran karanlık moda geçer — mod seçici/toplam süre '
    'kartı GİZLENİR, yalnızca sayaç + soluk Bitir metni görünür',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Başlat'));
      await tester.pump();

      expect(find.text('Serbest'), findsNothing);
      expect(find.text('Toplam Odak Süren'), findsNothing);
      expect(find.text('Bitir ve Kaydet'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    },
  );

  testWidgets(
    'Odak modundayken isHomeTabActive false\'a sabitlenir, ekrandan '
    'çıkınca eski değerine döner',
    (tester) async {
      isHomeTabActive.value = true;
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(isHomeTabActive.value, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(isHomeTabActive.value, isTrue);
    },
  );

  testWidgets('Sayaç saniye ilerledikçe artar ve Bitir ile kaydedilir', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Başlat'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 65));

    await tester.tap(find.text('Bitir ve Kaydet'));
    await tester.pump();

    // Karanlık moddan çıkılıp kurulum ekranına dönülmeli.
    expect(find.text('Serbest'), findsOneWidget);
    expect(find.textContaining('odaklandın'), findsOneWidget);
  });
}
