// ZFloatingButton'ın giyili kostüme göre doğru Z Coin görselini gösterdiğini
// test eder: Altın Zibo giyiliyken altıntema, Elmas Kaplama Zibo giyiliyken
// elmastema, diğer TÜM kostümlerde (veya kostümsüzken) standart görsel.
// Buton boyutu (SizedBox 64x64) hiçbirinde değişmiyor — üç PNG de AYNI
// 374x374 tuvale kırpıldığı için (bkz. tool/process_coin_theme.dart,
// CLAUDE.md "Alt Gezinme Çubuğu").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/widgets/z_floating_button.dart';

Widget _buildTestApp(CostumeProvider costumeProvider) {
  return ChangeNotifierProvider.value(
    value: costumeProvider,
    child: MaterialApp(
      home: Scaffold(
        body: ZFloatingButton(onTap: () {}, label: 'Z butonu'),
      ),
    ),
  );
}

String _currentAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Kostümsüzken veya poz seti olmayan bir kostüm giyiliyken standart Z '
    'Coin görseli gösterilir',
    (tester) async {
      final costumeProvider = CostumeProvider();
      await tester.pumpWidget(_buildTestApp(costumeProvider));
      await tester.pump();

      expect(_currentAsset(tester), 'assets/images/bottom_bar_z_coin.png');
    },
  );

  testWidgets('Altın Zibo giyiliyken altıntema görseli gösterilir', (
    tester,
  ) async {
    final costumeProvider = CostumeProvider();
    await costumeProvider.markOwned('zibo_altin');
    await costumeProvider.toggleEquipped('zibo_altin');

    await tester.pumpWidget(_buildTestApp(costumeProvider));
    await tester.pump();

    expect(
      _currentAsset(tester),
      'assets/images/bottom_bar_z_coin_altintema.png',
    );
  });

  testWidgets('Elmas Kaplama Zibo giyiliyken elmastema görseli gösterilir', (
    tester,
  ) async {
    final costumeProvider = CostumeProvider();
    await costumeProvider.markOwned('zibo_elmas');
    await costumeProvider.toggleEquipped('zibo_elmas');

    await tester.pumpWidget(_buildTestApp(costumeProvider));
    await tester.pump();

    expect(
      _currentAsset(tester),
      'assets/images/bottom_bar_z_coin_elmastema.png',
    );
  });

  testWidgets(
    'Diğer bir kostüm (ör. Sporcu Zibo) giyiliyken standart görsel kalır',
    (tester) async {
      final costumeProvider = CostumeProvider();
      await costumeProvider.markOwned('zibo_sporcu');
      await costumeProvider.toggleEquipped('zibo_sporcu');

      await tester.pumpWidget(_buildTestApp(costumeProvider));
      await tester.pump();

      expect(_currentAsset(tester), 'assets/images/bottom_bar_z_coin.png');
    },
  );

  testWidgets(
    'Kostüm çıkarılınca (Altın -> kostümsüz) standart görsele döner',
    (tester) async {
      final costumeProvider = CostumeProvider();
      await costumeProvider.markOwned('zibo_altin');
      await costumeProvider.toggleEquipped('zibo_altin');

      await tester.pumpWidget(_buildTestApp(costumeProvider));
      await tester.pump();
      expect(
        _currentAsset(tester),
        'assets/images/bottom_bar_z_coin_altintema.png',
      );

      // Aynı karta tekrar dokununca çıkarılır (bkz. toggleEquipped).
      await costumeProvider.toggleEquipped('zibo_altin');
      await tester.pump();

      expect(_currentAsset(tester), 'assets/images/bottom_bar_z_coin.png');
    },
  );
}
