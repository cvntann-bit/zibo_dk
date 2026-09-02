// WaterTrackingScreen'in bir birim YENİ işaretlendiğinde (geri alma DEĞİL)
// SoundEffectsService.playWaterDrop()'u çağırdığını, ve Ayarlar'daki "Ses
// Efektleri" tercihi kapalıyken bunu ATLADIĞINI doğrular —
// `home_screen_sound_test.dart`'taki "bağımsız test uygulaması + sahte
// servis enjeksiyonu" deseniyle AYNI (gerçek `audioplayers` platform
// kanalına HİÇ dokunulmuyor).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/water_tracking_screen.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';

class _RecordingSoundEffectsService extends SoundEffectsService {
  int waterDropCallCount = 0;

  @override
  Future<void> playZiboTap() async {}

  @override
  Future<void> playCoinReward() async {}

  @override
  Future<void> playCoinPurchase() async {}

  @override
  Future<void> playGoalComplete() async {}

  @override
  Future<void> playCostumeBuy() async {}

  @override
  Future<void> playThemeBuy() async {}

  @override
  Future<void> playWaterDrop() async => waterDropCallCount++;

  @override
  Future<void> playBadgeWin() async {}

  @override
  void dispose() {}
}

Widget _buildTestApp(SoundEffectsService soundEffectsService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CoinProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
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
      home: WaterTrackingScreen(soundEffectsService: soundEffectsService),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // `_WaterGlass` yalnızca bir `Icon` gösteriyor (görünür bir "1" metni
  // YOK, yalnızca `Semantics(label:)` — bkz. water_tracking_screen.dart) —
  // varsayılan birim `WaterUnit.glass` olduğu için boş/dolu ikonları
  // `Icons.water_drop_outlined`/`Icons.water_drop`.

  testWidgets(
    'Ses Efektleri açıkken bir birim işaretlenince playWaterDrop çağrılır',
    (tester) async {
      final service = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      // İlk boş birime dokunmak — "doldur" dalı, ses çalmalı.
      await tester.tap(find.byIcon(Icons.water_drop_outlined).first);
      await tester.pump();

      expect(service.waterDropCallCount, 1);
    },
  );

  testWidgets(
    'Dolu bir birime dokunup geri alınca playWaterDrop TEKRAR ÇAĞRILMAZ',
    (tester) async {
      final service = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.water_drop_outlined).first); // doldur
      await tester.pump();
      expect(service.waterDropCallCount, 1);

      await tester.tap(find.byIcon(Icons.water_drop).first); // geri al (artık dolu ikon)
      await tester.pump();

      expect(service.waterDropCallCount, 1);
    },
  );

  testWidgets(
    'Ses Efektleri kapalıyken bir birim işaretlenince playWaterDrop ÇAĞRILMAZ',
    (tester) async {
      final service = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(WaterTrackingScreen));
      await Provider.of<SoundEffectsProvider>(
        element,
        listen: false,
      ).setEnabled(false);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.water_drop_outlined).first);
      await tester.pump();

      expect(service.waterDropCallCount, 0);
    },
  );
}
