// GoalTrackingScreen'in bugünün hedef kutucuğu YENİ işaretlendiğinde (2026
// GÜNCELLEMESİ — yeniden tasarlanan zamanlama): playGoalComplete()'in
// dokunma ANINDA (titreşimle AYNI anda) çağrıldığını VE konfeti
// patlamasının (`GoalConfettiBurst`) yalnızca titreşim bitince (2 saniye
// SONRA) başladığını doğrular — `home_screen_sound_test.dart`'taki
// "bağımsız test uygulaması + sahte servis enjeksiyonu" deseniyle AYNI.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/goal_tracking_screen.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';
import 'package:dijital_kanka/widgets/goal_confetti_burst.dart';

class _RecordingSoundEffectsService extends SoundEffectsService {
  int goalCompleteCallCount = 0;

  @override
  Future<void> playZiboTap() async {}

  @override
  Future<void> playCoinReward() async {}

  @override
  Future<void> playCoinPurchase() async {}

  @override
  Future<void> playGoalComplete() async => goalCompleteCallCount++;

  @override
  Future<void> playCostumeBuy() async {}

  @override
  Future<void> playThemeBuy() async {}

  @override
  Future<void> playWaterDrop() async {}

  @override
  void dispose() {}
}

Widget _buildTestApp(SoundEffectsService soundEffectsService) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
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
      home: Scaffold(
        body: GoalTrackingScreen(
          isActive: true,
          soundEffectsService: soundEffectsService,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Bugünün kutucuğu YENİ işaretlenince ses ANINDA çalar, konfeti TAM 2 saniye sonra başlar',
    (tester) async {
      final sound = _RecordingSoundEffectsService();
      await tester.pumpWidget(_buildTestApp(sound));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(GoalTrackingScreen));
      Provider.of<GoalsProvider>(
        element,
        listen: false,
      ).addGoal('Günde 30 dakika kitap oku');
      await tester.pumpAndSettle();

      expect(find.byType(GoalConfettiBurst), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pump(); // titreşim + ses ANINDA başlar, konfeti HENÜZ değil

      expect(sound.goalCompleteCallCount, 1);
      expect(find.byType(GoalConfettiBurst), findsNothing);

      // 2 saniyeden AZ bir süre — konfeti hâlâ başlamamış olmalı, ses
      // tekrar ÇAĞRILMAMIŞ olmalı (yalnızca dokunma anında bir kez çalar).
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(GoalConfettiBurst), findsNothing);
      expect(sound.goalCompleteCallCount, 1);

      // 2 saniye (titreşim süresi) tamamlandı — konfeti şimdi başlamış
      // olmalı.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(GoalConfettiBurst), findsOneWidget);
      expect(sound.goalCompleteCallCount, 1);

      // Konfeti animasyonu (2000ms) tamamlanana kadar bekleyip testi
      // temiz bir şekilde bitir (askıda kalan zamanlayıcı/animasyon
      // olmadığından emin olmak için) — konfeti kaldırılmış olmalı.
      await tester.pumpAndSettle(const Duration(milliseconds: 2500));
      expect(find.byType(GoalConfettiBurst), findsNothing);
    },
  );
}
