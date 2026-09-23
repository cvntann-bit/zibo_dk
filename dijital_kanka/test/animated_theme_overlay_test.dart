// AnimatedThemeOverlay'in davranışını test eder: animationType none iken
// parçacık katmanı hiç eklenmiyor; bir animasyon türü aktifken katman
// ekleniyor VE altındaki içeriğe dokunmaları engellemiyor (IgnorePointer);
// disableAnimations (hareketi azalt) açıkken sürekli tekrar eden
// AnimationController hiç çalışmıyor — bu, pumpAndSettle()'ın sonsuza kadar
// beklememesini SAĞLAYAN mekanizma (bkz. WheelTriggerButton/ZFloatingButton
// ile aynı desen, CLAUDE.md "Temalar" bölümü).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/models/app_theme_option.dart';
import 'package:dijital_kanka/utils/tab_navigation.dart';
import 'package:dijital_kanka/widgets/animated_theme_overlay.dart';

Widget _buildTestApp(
  ThemeAnimationType type, {
  bool isDark = false,
  VoidCallback? onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedThemeOverlay(
        animationType: type,
        isDark: isDark,
        child: Center(
          child: ElevatedButton(
            onPressed: onTap ?? () {},
            child: const Text('Alttaki buton'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    // `isHomeTabActive` global bir ValueNotifier (bkz. tab_navigation.dart) —
    // bu dosya `RootScreen`'i hiç kurmadığı için (bağımsız bir test uygulaması
    // kullanıyor) sekme geçişleriyle güncellenmiyor; katmanın varsayılan
    // olarak GÖRÜNÜR test edilmesi için burada açıkça `true`'ya sabitleniyor
    // (aksi halde başka bir test dosyasının bıraktığı `false` değeri buraya
    // sızabilirdi).
    isHomeTabActive.value = true;
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher
            as TestPlatformDispatcher;
    // WheelTriggerButton'daki AYNI desen: sürekli tekrar eden animasyon
    // olmadan pumpAndSettle() sonsuza dek beklerdi.
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  testWidgets(
    'animationType none iken parçacık katmanı eklenmiyor, child değişmeden gösterilir',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(ThemeAnimationType.none));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('themeParticleEffect')), findsNothing);
      expect(find.text('Alttaki buton'), findsOneWidget);
    },
  );

  for (final type in [
    ThemeAnimationType.snow,
    ThemeAnimationType.galaxy,
    ThemeAnimationType.confetti,
    ThemeAnimationType.hearts,
    ThemeAnimationType.notes,
    ThemeAnimationType.tropical,
    ThemeAnimationType.petals,
  ]) {
    testWidgets(
      '$type aktifken parçacık katmanı eklenir, disableAnimations ile pumpAndSettle donmaz',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(type));
        // pumpAndSettle()'ın burada TAMAMLANMASI (timeout olmaması) zaten
        // disableAnimations'a saygı gösterildiğinin kanıtı — controller
        // repeat() ediyor olsaydı bu ASLA "settle" olmazdı.
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('themeParticleEffect')), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Parçacık katmanı dokunuşları engellemez — altındaki buton hâlâ tıklanabilir',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestApp(ThemeAnimationType.snow, onTap: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alttaki buton'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'Koyu/açık mod parametresi (isDark) hatasız çalışır (galaksi teması)',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(ThemeAnimationType.galaxy, isDark: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('themeParticleEffect')), findsOneWidget);
    },
  );

  testWidgets(
    // Faz 6 KRİTİK bug düzeltmesi — Crashlytics'te "tema değiştirince
    // çöküyor" olarak bildirilen `_dependents.isEmpty` assertion'ının
    // regresyon testi. Kök neden: `build()` eskiden `animationType == none`
    // iken `widget.child`'ı DOĞRUDAN, aksi halde AYNI child'ı bir `Stack`'in
    // İÇİNDE döndürüyordu — child'ın ağaçtaki derinliği bu iki durum
    // arasında DEĞİŞTİĞİ için Flutter'ın element uzlaştırması alt ağacı
    // yıkıp yeniden kuruyordu. `child` burada TÜM UYGULAMAYI (Navigator
    // dahil) temsil ettiği için gerçek senaryoda bu assertion'ı tetikliyordu
    // — bu testte küçük bir widget ağacıyla AYNI geçişi (`none` → bir
    // animasyon türü → `none`) simüle edip hiçbir assertion FIRLATILMADAN
    // tamamlandığını doğruluyor.
    'animationType none ile bir animasyon türü arasında GEÇİŞ YAPMAK '
    '(_dependents.isEmpty assertion regresyonu) çökmez',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(ThemeAnimationType.none));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_buildTestApp(ThemeAnimationType.snow));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('themeParticleEffect')), findsOneWidget);

      await tester.pumpWidget(_buildTestApp(ThemeAnimationType.none));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('themeParticleEffect')), findsNothing);

      // Ana Sayfa'dan başka bir sekmeye geçiş de AYNI yapısal dalı tetikler
      // (bkz. `build()`'teki `isHomeTabActive` kontrolü) — bu geçiş de
      // çökmemeli. `_syncRunningState`'in `setState`'i bir
      // `addPostFrameCallback` ÜZERİNDEN geldiği için birkaç `pump()`
      // gerekebiliyor — burada asıl doğrulanan şey KESİN widget varlığı
      // değil, assertion FIRLAMADAN tamamlanması.
      await tester.pumpWidget(_buildTestApp(ThemeAnimationType.snow));
      await tester.pumpAndSettle();
      isHomeTabActive.value = false;
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      isHomeTabActive.value = true;
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
