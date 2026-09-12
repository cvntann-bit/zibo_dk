// ZiboAnimatedImage'ın poz gösterim davranışını test eder: poz seti olmayan
// bir kostüm sabit tek görsele düşer, [poseStep] değişince (dışarıdan,
// örn. ZiboPoseProvider'dan) doğru pozu gösterir ve crossfade tetikler,
// kostüm değişince yeni kostümün poz setinin BAŞINDAN başlar (ANINDA, fade
// olmadan). 2026 güncellemesi: widget artık kendi İÇSEL zamanlayıcısına
// sahip DEĞİL — hangi poz gösterileceği tamamen dışarıdan [poseStep]
// parametresiyle kontrol ediliyor (bkz. CLAUDE.md "Zibo Poz/Animasyon
// Sistemi").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/widgets/zibo_animated_image.dart';

Widget _buildTestApp({
  required String? costumeId,
  required int poseStep,
  required String fallback,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ZiboAnimatedImage(
        imageKey: const Key('testZiboImage'),
        costumeId: costumeId,
        poseStep: poseStep,
        fallbackImage: fallback,
        height: 64,
      ),
    ),
  );
}

String _currentAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byKey(const Key('testZiboImage'))).image
            as AssetImage)
        .assetName;

void main() {
  testWidgets(
    'Poz seti olmayan bir kostüm tek statik görsele düşer, poseStep '
    'değişse de değişmez',
    (WidgetTester tester) async {
      // 2026 güncellemesi: artık costume_poses.dart'taki 11 gerçek
      // kostümün TÜMÜNÜN poz seti var (bkz. costume_poses.dart) — bu
      // yüzden fallback davranışını test etmek için costumes.dart'ta hiç
      // karşılığı olmayan UYDURMA bir id kullanılıyor. posesForCostume()
      // yalnızca costumePoses Map'ine bakıyor, costumes.dart'a karşı
      // doğrulama yapmıyor, bu yüzden bu senaryo hâlâ geçerli.
      const costumeId = 'zibo_test_kostumu_poz_seti_yok';
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: costumeId,
          poseStep: 0,
          fallback: 'assets/images/zibo_hippi.webp',
        ),
      );
      await tester.pump();

      expect(_currentAsset(tester), 'assets/images/zibo_hippi.webp');

      await tester.pumpWidget(
        _buildTestApp(
          costumeId: costumeId,
          poseStep: 7,
          fallback: 'assets/images/zibo_hippi.webp',
        ),
      );
      await tester.pumpAndSettle();

      expect(_currentAsset(tester), 'assets/images/zibo_hippi.webp');
    },
  );

  testWidgets(
    'Kostümsüz (varsayılan) Zibo poseStep %5 ile doğru pozu gösterir',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: null,
          poseStep: 0,
          fallback: 'assets/images/zibo_yeni.webp',
        ),
      );
      await tester.pump();
      expect(_currentAsset(tester), 'assets/images/zibo_df_pose1.webp');

      await tester.pumpWidget(
        _buildTestApp(
          costumeId: null,
          poseStep: 1,
          fallback: 'assets/images/zibo_yeni.webp',
        ),
      );
      await tester.pumpAndSettle();
      expect(_currentAsset(tester), 'assets/images/zibo_df_pose2.webp');

      // 5 pozluk listenin sonuna kadar ilerleyip başa (pose1) sarmalı.
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: null,
          poseStep: 5,
          fallback: 'assets/images/zibo_yeni.webp',
        ),
      );
      await tester.pumpAndSettle();
      expect(_currentAsset(tester), 'assets/images/zibo_df_pose1.webp');
    },
  );

  testWidgets(
    'Kostüm değişince yeni kostümün pozu ANINDA (fade beklemeden) gösterilir',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: 'zibo_sporcu',
          poseStep: 2,
          fallback: 'assets/images/zibo_sporcu.webp',
        ),
      );
      await tester.pump();
      expect(_currentAsset(tester), 'assets/images/zibo_sporcu_pose3.webp');

      // Kostüm değişti (poseStep AYNI kaldı — ZiboPoseProvider paylaşılan
      // TEK bir sayaç, kostüme özel değil) — yeni kostümün (rapçi) o anki
      // poseStep'e karşılık gelen karesi, fade'i BEKLEMEDEN, bir sonraki
      // pump'ta ANINDA görünmeli (iki farklı kostümün arasında çapraz
      // solma YAPILMAZ, bkz. ZiboAnimatedImage.didUpdateWidget).
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: 'zibo_rapci',
          poseStep: 2,
          fallback: 'assets/images/zibo_rapci.webp',
        ),
      );
      await tester.pump();

      expect(_currentAsset(tester), 'assets/images/zibo_rapci_pose3.webp');
    },
  );

  testWidgets(
    'Aynı kostümde poseStep değişince crossfade sonunda hedef poz gösterilir',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          costumeId: 'zibo_punk',
          poseStep: 0,
          fallback: 'assets/images/zibo_punk.webp',
        ),
      );
      await tester.pump();
      expect(_currentAsset(tester), 'assets/images/zibo_punk_pose1.webp');

      await tester.pumpWidget(
        _buildTestApp(
          costumeId: 'zibo_punk',
          poseStep: 1,
          fallback: 'assets/images/zibo_punk.webp',
        ),
      );
      // Crossfade (varsayılan 250ms x2) tamamlanana kadar bekle.
      await tester.pumpAndSettle();

      expect(_currentAsset(tester), 'assets/images/zibo_punk_pose2.webp');
    },
  );
}
