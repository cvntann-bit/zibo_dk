// HomeScreen'in Zibo'ya dokununca (mevcut poz/söz değişim animasyonuyla
// AYNI anda) SoundEffectsService.playZiboTap()'i çağırdığını, ve Ayarlar'daki
// "Ses Efektleri" tercihi kapalıyken bunu ATLADIĞINI doğrular —
// manifest_journal_screen_test.dart'taki "bağımsız test uygulaması + sahte
// servis enjeksiyonu" deseniyle AYNI (gerçek `audioplayers` platform
// kanalına HİÇ dokunulmuyor).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/theme_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/home_screen.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';

class _RecordingSoundEffectsService extends SoundEffectsService {
  int playCallCount = 0;

  @override
  Future<void> playZiboTap() async {
    playCallCount++;
  }

  @override
  Future<void> playCoinReward() async {}

  @override
  Future<void> playCoinPurchase() async {}

  @override
  Future<void> playGoalComplete() async {}

  @override
  void dispose() {}
}

Widget _buildTestApp(SoundEffectsService soundEffectsService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteQuotesProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
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
      home: HomeScreen(soundEffectsService: soundEffectsService),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Ses Efektleri açıkken Zibo\'ya dokununca playZiboTap çağrılır',
    (tester) async {
      final service = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();
      // Image.asset() providers boot olduktan hemen sonra yükseklik=0
      // raporlayabiliyor (gerçek codec decode'u pumpAndSettle()'ın taradığı
      // sahte-zaman penceresinin dışında kalıyor) — bkz. CLAUDE.md "Test
      // kalıpları" bölümündeki aynı gotcha.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ziboCharacterImage')));
      await tester.pump();

      expect(service.playCallCount, 1);
    },
  );

  testWidgets(
    'Ses Efektleri kapalıyken Zibo\'ya dokununca playZiboTap ÇAĞRILMAZ',
    (tester) async {
      final service = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(HomeScreen));
      await Provider.of<SoundEffectsProvider>(
        element,
        listen: false,
      ).setEnabled(false);
      await tester.pump();

      await tester.tap(find.byKey(const Key('ziboCharacterImage')));
      await tester.pump();

      expect(service.playCallCount, 0);
    },
  );
}
