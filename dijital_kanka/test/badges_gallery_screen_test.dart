// BadgesGalleryScreen'in kazanılan/kazanılmamış rozetleri doğru görsel
// durumda gösterdiğini VE gerçekçi dar bir telefon viewport'unda
// `RenderFlex overflow` OLMADIĞINI doğrular — bu projede defalarca
// tekrarlanan "yeni grid kartı ekleyince childAspectRatio overflow'u" bug
// sınıfına karşı somut bir regresyon testi (bkz. CLAUDE.md "Test kalıpları").

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/consistency_badges.dart';
import 'package:dijital_kanka/data/hidden_badges.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/screens/badges_gallery_screen.dart';

Widget _buildTestApp(BadgeProvider badges) {
  return ChangeNotifierProvider<BadgeProvider>.value(
    value: badges,
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
      home: const BadgesGalleryScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher
            as TestPlatformDispatcher;
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
    'Hiç rozet kazanılmamışken: HEPSİ gri tonlu görünür, ad+koşul yine de '
    'görünür, overflow olmaz',
    (tester) async {
      final badges = BadgeProvider();
      await tester.pumpWidget(_buildTestApp(badges));
      await tester.pumpAndSettle();

      expect(find.text('İlk Adım'), findsOneWidget);
      expect(find.text('7 gün üst üste giriş yap'), findsOneWidget);
      // 2026 güncellemesi — Modül Ustalığı Rozetleri eklendiği için artık
      // yalnızca `consistencyBadges` DEĞİL, `allBadges`'in TAMAMI (iki
      // kategori) HİÇ kazanılmamış durumda gri tonlu render ediliyor.
      // **2026 İKİNCİ güncelleme — Gizli/Eğlenceli Rozetler İSTİSNA:**
      // kazanılmamış hidden badge'ler `ColorFiltered`'a TABİ DEĞİL (bkz.
      // `_BadgeGalleryCard`'daki `hiddenLocked` kontrolü) — üçü de bu
      // sayımdan DIŞARIDA.
      expect(
        find.byType(ColorFiltered),
        findsNWidgets(allBadges.length - hiddenBadges.length),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bir rozet kazanılınca: o kart renkli/net görünür (ColorFiltered '
    'kaybolur), diğerleri gri kalır',
    (tester) async {
      final badges = BadgeProvider();
      badges.reconcileConsistencyBadges(
        hasCompletedFirstGoalCycle: true,
        appOpenStreak: 0,
      );
      await tester.pumpWidget(_buildTestApp(badges));
      await tester.pumpAndSettle();

      expect(
        find.byType(ColorFiltered),
        findsNWidgets(allBadges.length - hiddenBadges.length - 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Gizli/Eğlenceli Rozetler: kazanılmadan ÖNCE isim/koşul/ödül yerine '
    'gizemli "???" etiketi + paylaşılan gizem görseli gösterir, gerçek '
    'içerik hiçbir yerde SIZMAZ',
    (tester) async {
      final badges = BadgeProvider();
      await tester.pumpWidget(_buildTestApp(badges));
      await tester.pumpAndSettle();

      // Üç gizli rozetin gerçek adı/koşulu HİÇ görünmüyor.
      expect(find.text('Gece Kuşu'), findsNothing);
      expect(find.text('Erken Kuş'), findsNothing);
      expect(find.text('Denge Ustası'), findsNothing);
      expect(
        find.text('Gece yarısı ile sabah 05:00 arası 30 kez uygulamayı aç'),
        findsNothing,
      );
      // Yerine "???" etiketi üçü için de İKİŞER kez (isim + koşul slotu)
      // görünüyor — toplam 6.
      expect(find.text('???'), findsNWidgets(6));
      // 2026 İKİNCİ güncelleme — ÖDÜL MİKTARI İSTİSNA, kazanılmadan önce
      // de HER ÜÇ kart için görünür (kullanıcının netleştirmesi).
      expect(find.text('777 ZC'), findsNWidgets(3));
      expect(find.text('Gizli Rozetler'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Gizli/Eğlenceli Rozetler: KAZANILDIKTAN sonra diğer TÜM rozetlerle '
    'BİREBİR aynı şekilde gerçek görsel/isim/koşul/ödül gösterir',
    (tester) async {
      final badges = BadgeProvider();
      badges.reconcileHiddenBadges(
        nightOwlDaysCount: 30,
        earlyBirdDaysCount: 0,
        hasAllModulesToday: false,
      );
      await tester.pumpWidget(_buildTestApp(badges));
      await tester.pumpAndSettle();

      expect(find.text('Gece Kuşu'), findsOneWidget);
      expect(
        find.text('Gece yarısı ile sabah 05:00 arası 30 kez uygulamayı aç'),
        findsOneWidget,
      );
      // 2026 İKİNCİ güncelleme — "777 ZC" ARTIK kazanılmamış iki rozette
      // de görünüyor (ödül miktarı gizli DEĞİL) — toplam üçü de gösteriyor.
      expect(find.text('777 ZC'), findsNWidgets(3));
      // Kazanılmamış diğer iki gizli rozet HÂLÂ "???" gösteriyor (4 = 2×2).
      expect(find.text('???'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    },
  );
}
