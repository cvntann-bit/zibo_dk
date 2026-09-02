// BadgeCelebrationOverlay'in `pendingBadgePopup` sinyalini tüketip konfeti +
// kutlama kartını gösterdiğini, "Ödülü Al" butonunun rozeti claimed yaptığını
// + coin eklediğini + sinyali sıfırladığını + Rozetler Galerisi'ni açtığını
// (rootNavigatorKey üzerinden) doğrular — bkz. CLAUDE.md "Rozet Sistemi"
// bölümü.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/app_themes.dart';
import 'package:dijital_kanka/data/collection_badges.dart';
import 'package:dijital_kanka/data/consistency_badges.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/screens/badges_gallery_screen.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';
import 'package:dijital_kanka/utils/badge_celebration_signal.dart';
import 'package:dijital_kanka/utils/root_navigator_key.dart';
import 'package:dijital_kanka/widgets/badge_celebration_overlay.dart';

class _RecordingSoundEffectsService extends SoundEffectsService {
  int playBadgeWinCallCount = 0;

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
  Future<void> playWaterDrop() async {}

  @override
  Future<void> playBadgeWin() async {
    playBadgeWinCallCount++;
  }

  @override
  void dispose() {}
}

Widget _buildTestApp(
  BadgeProvider badges,
  CoinProvider coin, {
  SoundEffectsService? soundEffectsService,
  AppThemeProvider? appTheme,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BadgeProvider>.value(value: badges),
      ChangeNotifierProvider<CoinProvider>.value(value: coin),
      ChangeNotifierProvider<SoundEffectsProvider>(
        create: (_) => SoundEffectsProvider(),
      ),
      ChangeNotifierProvider<AppThemeProvider>.value(
        value: appTheme ?? AppThemeProvider(),
      ),
    ],
    child: MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => BadgeCelebrationOverlay(
        soundEffectsService:
            soundEffectsService ?? const FakeSoundEffectsService(),
        child: child!,
      ),
      home: const Scaffold(body: Center(child: Text('Ana İçerik'))),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingBadgePopup.value = null;
  });

  final firstStep = consistencyBadges.firstWhere((b) => b.id == 'first_step');

  testWidgets(
    'pendingBadgePopup ayarlanınca kutlama kartı rozet adı/koşulu/ödülüyle '
    'görünür',
    (tester) async {
      final badges = BadgeProvider();
      final coin = CoinProvider();
      await tester.pumpWidget(_buildTestApp(badges, coin));
      await tester.pumpAndSettle();

      pendingBadgePopup.value = firstStep;
      await tester.pump();

      expect(find.text('İlk Adım'), findsOneWidget);
      expect(find.text('İlk 7 günlük hedef döngünü tamamla'), findsOneWidget);
      expect(find.text('10 ZC'), findsOneWidget);
      expect(find.text('Ödülü Al'), findsOneWidget);
    },
  );

  testWidgets(
    '"Ödülü Al"a basınca: rozet claimed olur, coin eklenir, sinyal '
    'sıfırlanır, Rozetler Galerisi açılır',
    (tester) async {
      final badges = BadgeProvider();
      final coin = CoinProvider();
      await tester.pumpWidget(_buildTestApp(badges, coin));
      await tester.pumpAndSettle();

      badges.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: true,
        appOpenStreak: 0,
      );
      await tester.pump();
      expect(pendingBadgePopup.value?.id, 'first_step');

      final balanceBefore = coin.balance;
      await tester.tap(find.text('Ödülü Al'));
      await tester.pumpAndSettle();

      expect(badges.isClaimed('first_step'), isTrue);
      expect(coin.balance, balanceBefore + firstStep.zcReward);
      expect(pendingBadgePopup.value, isNull);
      expect(find.byType(BadgesGalleryScreen), findsOneWidget);
    },
  );

  testWidgets(
    'pendingBadgePopup ayarlanınca konfeti ile TAM EŞ ZAMANLI playBadgeWin '
    'çağrılır',
    (tester) async {
      final badges = BadgeProvider();
      final coin = CoinProvider();
      final sound = _RecordingSoundEffectsService();
      await tester.pumpWidget(
        _buildTestApp(badges, coin, soundEffectsService: sound),
      );
      await tester.pumpAndSettle();

      expect(sound.playBadgeWinCallCount, 0);

      pendingBadgePopup.value = firstStep;
      await tester.pump();

      expect(sound.playBadgeWinCallCount, 1);
    },
  );

  final fullWardrobe = collectionBadges.firstWhere(
    (b) => b.id == 'full_wardrobe',
  );

  testWidgets(
    '"Tam Gardırop" (hasSpecialReward) için "Ödülü Al"a basınca sahip '
    'OLUNMAYAN bir tema RASTGELE hediye edilir ve SnackBar ile duyurulur',
    (tester) async {
      final badges = BadgeProvider();
      final coin = CoinProvider();
      final appTheme = AppThemeProvider();
      await tester.pumpWidget(
        _buildTestApp(badges, coin, appTheme: appTheme),
      );
      await tester.pumpAndSettle();
      expect(appTheme.ownedIds, isEmpty);

      badges.reconcileCollectionBadges(
        ownedCostumeCount: 0,
        ownsAllCostumes: true,
        ownedThemeCount: 0,
      );
      await tester.pump();
      expect(pendingBadgePopup.value?.id, 'full_wardrobe');

      await tester.tap(find.text('Ödülü Al'));
      await tester.pumpAndSettle();

      expect(badges.isClaimed('full_wardrobe'), isTrue);
      expect(appTheme.ownedIds, hasLength(1));
      expect(appThemes.map((t) => t.id), contains(appTheme.ownedIds.single));
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets(
    'hasSpecialReward TAŞIMAYAN bir rozette (ör. İlk Adım) hiçbir tema '
    'hediye EDİLMEZ',
    (tester) async {
      final badges = BadgeProvider();
      final coin = CoinProvider();
      final appTheme = AppThemeProvider();
      await tester.pumpWidget(
        _buildTestApp(badges, coin, appTheme: appTheme),
      );
      await tester.pumpAndSettle();

      pendingBadgePopup.value = firstStep;
      await tester.pump();
      await tester.tap(find.text('Ödülü Al'));
      await tester.pumpAndSettle();

      expect(appTheme.ownedIds, isEmpty);
    },
  );
}
