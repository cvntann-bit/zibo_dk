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
import 'package:dijital_kanka/providers/ad_free_provider.dart';
import 'package:dijital_kanka/providers/app_streak_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/goal_tracking_screen.dart';
import 'package:dijital_kanka/services/ad_service.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';
import 'package:dijital_kanka/widgets/goal_confetti_burst.dart';

class _RecordingAdService extends AdService {
  int interstitialCallCount = 0;

  @override
  Future<bool> showRewardedAd() async => true;

  @override
  Future<bool> showInterstitialAd() async {
    interstitialCallCount++;
    return true;
  }
}

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
  Future<void> playBadgeWin() async {}

  @override
  void dispose() {}
}

Widget _buildTestApp(
  SoundEffectsService soundEffectsService, {
  AdService? adService,
  DateTime Function()? now,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdFreeProvider()),
      ChangeNotifierProvider(create: (_) => AppStreakProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(
        create: (_) => GoalsProvider(now: now ?? DateTime.now),
      ),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
      if (adService != null)
        ChangeNotifierProvider(create: (_) => CoinProvider(adService: adService)),
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

  testWidgets(
    '7 günlük döngü TAMAMLANINCA geçilebilir reklam yalnızca kutlama '
    '(titreşim+konfeti) BİTTİKTEN SONRA gösterilir, ara günlerde HİÇ '
    'gösterilmez',
    (tester) async {
      var currentDate = DateTime(2026, 1, 5);
      final ads = _RecordingAdService();
      await tester.pumpWidget(
        _buildTestApp(
          _RecordingSoundEffectsService(),
          adService: ads,
          now: () => currentDate,
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(GoalTrackingScreen));
      final goalsProvider = Provider.of<GoalsProvider>(element, listen: false);
      goalsProvider.addGoal('Günde 30 dakika kitap oku');
      await tester.pumpAndSettle();

      // Gün 1-6: hiçbiri döngüyü TAMAMLAMIYOR, reklam HİÇ tetiklenmemeli.
      for (var day = 1; day <= 6; day++) {
        await tester.tap(find.text('$day'));
        // Kutlama animasyonunu (titreşim+konfeti, ~4sn) tamamen bitirip bir
        // sonraki güne geçiyoruz. **`pumpAndSettle(Duration(seconds: 5))`
        // KULLANILMIYOR BİLEREK** — bu ekranın KENDİ konuşma balonu sözü de
        // AYNI 5 saniyelik `Timer.periodic` ile dönüyor (bkz. goal_tracking_
        // screen.dart) ve SpeechBubble artık söz değişiminde bir fade geçişi
        // kullanıyor (bkz. speech_bubble.dart) — `pumpAndSettle`'ın 5sn'lik
        // HER adımı bu timer'ı TAM o anda yeniden tetikleyip fade animasyonunu
        // baştan başlatıyor, bu da `pumpAndSettle`'ın asla "settle"
        // olamamasına (sonsuz döngü/`pumpAndSettle timed out`) yol açıyordu.
        // Bunun yerine, kendi başına asla yeniden tetiklenmeyen TEK SEFERLİK
        // `pump()` çağrılarıyla (5000ms'e TAM denk gelmeyen adımlarla) aynı
        // ~4sn'yi geçiyoruz.
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 500));
        expect(ads.interstitialCallCount, 0);
        currentDate = currentDate.add(const Duration(days: 1));
        goalsProvider.reconcileForToday();
        await tester.pumpAndSettle();
      }

      // Gün 7 — döngüyü TAMAMLAYAN dokunuş.
      await tester.tap(find.text('7'));
      await tester.pump(); // titreşim ANINDA başlar
      expect(ads.interstitialCallCount, 0);

      // Titreşimin (2sn) TAM ortasında — kutlama hâlâ sürüyor, reklam HENÜZ
      // gösterilmemeli (tam ekran reklam kutlamayı KESMEMELİ).
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ads.interstitialCallCount, 0);

      // Titreşim bitip (2sn) konfeti başladı, ama konfeti (2sn) HENÜZ
      // bitmedi — reklam hâlâ gösterilmemeli.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(GoalConfettiBurst), findsOneWidget);
      expect(ads.interstitialCallCount, 0);

      // Konfeti (toplam ~4sn) tamamen bitti — reklam TAM ŞİMDİ, tam bir
      // kez gösterilmiş olmalı.
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(GoalConfettiBurst), findsNothing);
      expect(ads.interstitialCallCount, 1);
    },
  );
}
