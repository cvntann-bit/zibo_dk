// HomeScreen'in Zibo'ya art arda hızlı (5 kez, birkaç saniye içinde)
// dokunulunca bir reklam VEYA (daha düşük ihtimalle) Reklamsız Zibo
// tanıtım sheet'ini gösterdiğini, ikisinin ASLA aynı anda tetiklenmediğini
// ve eşik dolmadan (4 dokunuşta) hiçbir şeyin tetiklenmediğini doğrular —
// `home_screen_sound_test.dart`'taki "bağımsız test uygulaması + sahte
// servis enjeksiyonu" deseniyle AYNI.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/ad_free_provider.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/custom_messages_provider.dart';
import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/home_quick_widgets_provider.dart';
import 'package:dijital_kanka/providers/mood_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/theme_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/home_screen.dart';
import 'package:dijital_kanka/services/ad_service.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';

/// `nextDouble()`'ın hep aynı sabit değeri döndürmesi için — `wheel_prizes_
/// test.dart`'taki `_FixedRandom` ile AYNI desen.
class _FixedRandom implements Random {
  const _FixedRandom(this._value);
  final double _value;

  @override
  double nextDouble() => _value;

  @override
  int nextInt(int max) => (max * _value).floor();

  @override
  bool nextBool() => _value >= 0.5;
}

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

Widget _buildTestApp({required Random random, required AdService adService}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdFreeProvider()),
      ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ChangeNotifierProvider(create: (_) => CoinProvider(adService: adService)),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => CustomMessagesProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteQuotesProvider()),
      ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ChangeNotifierProvider(create: (_) => HomeQuickWidgetsProvider()),
      ChangeNotifierProvider(create: (_) => MoodProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      home: HomeScreen(
        adPromoRandom: random,
        soundEffectsService: const FakeSoundEffectsService(),
      ),
    ),
  );
}

Future<void> _tapZiboNTimes(WidgetTester tester, int count) async {
  // Image.asset() providers boot olduktan hemen sonra yükseklik=0
  // raporlayabiliyor — bkz. widget_test.dart'taki AYNI gotcha.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  for (var i = 0; i < count; i++) {
    await tester.tap(find.byKey(const Key('ziboCharacterImage')));
    await tester.pump();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Zibo\'ya art arda 5 kez dokununca (yüksek random değeri) geçiş reklamı gösterilir',
    (tester) async {
      final adService = _RecordingAdService();
      await tester.pumpWidget(
        _buildTestApp(random: const _FixedRandom(0.9), adService: adService),
      );
      await _tapZiboNTimes(tester, 5);
      await tester.pumpAndSettle();

      expect(adService.interstitialCallCount, 1);
      expect(find.byKey(const Key('paywallOneTimeButton')), findsNothing);
    },
  );

  testWidgets(
    'Zibo\'ya art arda 5 kez dokununca (düşük random değeri) paywall açılır, reklam GÖSTERİLMEZ',
    (tester) async {
      final adService = _RecordingAdService();
      await tester.pumpWidget(
        _buildTestApp(random: const _FixedRandom(0.1), adService: adService),
      );
      await _tapZiboNTimes(tester, 5);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('paywallOneTimeButton')), findsOneWidget);
      expect(adService.interstitialCallCount, 0);
    },
  );

  testWidgets(
    '4 dokunuşta (eşik dolmadan) ne reklam ne de paywall tetiklenir',
    (tester) async {
      final adService = _RecordingAdService();
      await tester.pumpWidget(
        _buildTestApp(random: const _FixedRandom(0.9), adService: adService),
      );
      await _tapZiboNTimes(tester, 4);
      await tester.pumpAndSettle();

      expect(adService.interstitialCallCount, 0);
      expect(find.byKey(const Key('paywallOneTimeButton')), findsNothing);
    },
  );
}
