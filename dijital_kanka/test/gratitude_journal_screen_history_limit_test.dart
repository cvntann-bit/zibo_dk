// Faz 3 (D1) doğrulaması: Zibo Pro/Pro+ olmayan kullanıcı Şükran Günlüğü
// geçmişinde yalnızca son 30 günü görür, 30 günden eski kayıtlar
// SİLİNMEDEN yalnızca ekrandan gizlenir ve yerine HistoryLimitUpsellCard
// gösterilir; Pro/Pro+ kullanıcı TÜM geçmişi (eskiler dahil) görür ve
// kart hiç görünmez. Kullanıcının gerçek cihazında henüz 30 günden eski
// kaydı olmadığı için bu senaryo elle test edilemiyor — bu test onun
// yerine geçiyor. Aynı filtre/kart kalıbı Ruh Hali Takibi ve Manifest
// Günlüğü ekranlarında da BİREBİR kullanılıyor (bkz. mood_tracking_screen.
// dart / manifest_journal_screen.dart) — üçü de aynı kod şeklini
// paylaştığı için yalnızca en basit ekran (Şükran, günde tek kayıt, düz
// liste) burada kapsanıyor.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/localized_calendar_names.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/subscription_tier.dart';
import 'package:dijital_kanka/providers/ad_free_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/gratitude_journal_screen.dart';
import 'package:dijital_kanka/widgets/banner_ad_slot.dart';

Widget _buildTestApp(GratitudeProvider gratitudeProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdFreeProvider()),
      ChangeNotifierProvider(create: (_) => CoinProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider.value(value: gratitudeProvider),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
      home: GratitudeJournalScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Free kullanıcı 30 günden eski kaydı GÖRMEZ, yükseltme kartı çıkar; '
    'Pro kullanıcı TÜM geçmişi görür, kart çıkmaz',
    (tester) async {
      // `GratitudeProvider.saveToday()` "bugün"ü constructor'a enjekte
      // edilen `now` üzerinden hesaplıyor (bkz. dokümantasyonu) — burada bu
      // kapanışın yakaladığı DEĞİŞKENİ iki çağrı arasında değiştirerek AYNI
      // provider'a hem 45 gün önceki hem de bugünün kaydını ekliyoruz.
      var simulatedNow = DateTime.now().subtract(const Duration(days: 45));
      final provider = GratitudeProvider(now: () => simulatedNow);
      provider.saveToday(text1: 'Eski 1', text2: 'Eski 2', text3: 'Eski 3');

      simulatedNow = DateTime.now();
      provider.saveToday(text1: 'Yeni 1', text2: 'Yeni 2', text3: 'Yeni 3');

      const locale = Locale('tr');
      final oldDateLabel = formatLongDate(
        DateTime.now().subtract(const Duration(days: 45)),
        locale,
      );
      final todayDateLabel = formatLongDate(DateTime.now(), locale);

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pumpAndSettle();

      // Düz `ListView(children:)` viewport-dışı öğeleri GEÇ İNŞA EDER (bkz.
      // test/CLAUDE.md) — bir satırın gerçekten FİLTRELENDİĞİNİ (yoksa
      // yalnızca ekran dışı olduğunu) doğru ölçebilmek için listenin
      // SONUNA (BannerAdSlot, en son öğe) kadar kaydırılıyor; bu, arada
      // kalan TÜM geçmiş satırlarının da inşa edilmesini sağlıyor.
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byType(BannerAdSlot),
        300,
        scrollable: scrollable,
      );

      expect(find.text(todayDateLabel), findsOneWidget);
      expect(find.text(oldDateLabel), findsNothing);
      expect(find.text("Pro'ya Geç"), findsOneWidget);

      // --- Pro kullanıcı ---
      await tester
          .element(find.byType(GratitudeJournalScreen))
          .read<SubscriptionProvider>()
          .debugSetTier(SubscriptionTier.pro);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(BannerAdSlot),
        300,
        scrollable: scrollable,
      );

      expect(find.text(todayDateLabel), findsOneWidget);
      expect(find.text(oldDateLabel), findsOneWidget);
      expect(find.text("Pro'ya Geç"), findsNothing);
    },
  );
}
