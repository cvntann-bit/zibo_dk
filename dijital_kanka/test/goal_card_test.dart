// GoalCard'ın gün kutucuklarını KÜMÜLATİF numaralandırdığını (1-7, sonra
// 8-14, sonra 15-21...) doğrudan (RootScreen'in tam ağacını kurmadan) test
// eder — bkz. CLAUDE.md "Hedef Takibi" bölümündeki kullanıcı isteği: "hedef
// silinmesin, döngü tamamlanınca numaralar SIFIRLANMASIN, ardışık devam
// etsin." `GoalsProvider.completedCyclesFor`'un kendi eşik/sınır davranışı
// zaten `goals_provider_test.dart`'ta tam kapsandığı için burada yalnızca
// GoalCard'ın bu sayıyı DOĞRU şekilde görüntülediği doğrulanıyor.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/goal.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/widgets/goal_card.dart';

Widget _buildTestApp(GoalsProvider goals, CoinProvider coin, DateTime today) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GoalsProvider>.value(value: goals),
      ChangeNotifierProvider<CoinProvider>.value(value: coin),
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
        body: GoalCard(goal: goals.goals.first, today: today),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'İlk döngüde gün kutucukları 1-7 gösterir; döngü TAMAMLANIP ikinci '
    'döngü başlayınca numaralar SIFIRLANMADAN 8-14\'e devam eder',
    (tester) async {
      var currentDate = DateTime(2026, 1, 5);
      final goals = GoalsProvider(now: () => currentDate);
      final coin = CoinProvider(now: () => currentDate);
      // Bilerek çıplak `await Future<void>.delayed(Duration.zero)` YOK —
      // `testWidgets()`'ın fake-async ortamında bu SONSUZA KADAR hanglenir
      // (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümündeki AYNI gotcha,
      // gerçekten yaşandı: 10 dakikalık test timeout'una çarptı). Taze
      // `SharedPreferences.setMockInitialValues({})` ile `_loadFromPrefs()`
      // zaten `decoded == null` dalına düşüp `_goals`'a hiç dokunmadan
      // dönüyor, bu yüzden `addGoal` SONRASINDA gelen `pumpWidget`/
      // `pumpAndSettle()` yeterli — ayrı bir bekleyişe gerek yok.
      goals.addGoal('Günde 30 dakika kitap oku');

      await tester.pumpWidget(_buildTestApp(goals, coin, currentDate));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('8'), findsNothing);

      // Yedi günü ardışık gerçek tarihlerle işaretleyip döngüyü tamamla —
      // `goals_provider_test.dart`'taki `completeOneCycle()` deseninin
      // AYNISI.
      for (var day = 0; day < Goal.daysPerCycle; day++) {
        goals.toggleToday(goals.goals.first.id);
        if (day < Goal.daysPerCycle - 1) {
          currentDate = currentDate.add(const Duration(days: 1));
          goals.reconcileForToday();
        }
      }
      await tester.pumpAndSettle();

      // Yeni (ikinci) döngü — kutucuklar 1-7'ye DÖNMEDEN 8-14 göstermeli.
      expect(find.text('1'), findsNothing);
      expect(find.text('7'), findsNothing);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    },
  );
}
