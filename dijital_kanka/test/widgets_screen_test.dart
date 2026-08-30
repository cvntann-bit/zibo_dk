// WidgetsScreen'in beş modülü listelediğini VE her satırdaki "Ekle"
// butonunun (a) enjekte edilen sahte `HomeWidgetService.requestPin`'i
// doğru modülle (arka planda, sonucunu BEKLEMEDEN) çağırdığını, (b) HER
// ZAMAN (requestPin'in sonucundan BAĞIMSIZ) manuel ekleme talimatlarını
// gösteren bir bottom sheet açtığını doğrudan (gerçek `home_widget`
// platform kanalına dokunmadan) test eder — bkz. CLAUDE.md "Ana Ekran
// Widget'ları" bölümü, `manifest_journal_screen_test.dart`'taki AYNI
// "bağımsız test uygulaması + sahte servis enjeksiyonu" deseni.
// **2026 güncellemesi** — beş "basit günlük/checkbox" widget'ı kaldırılıp
// yerine [ZiboWidgetModule.profileStats] geldi, listedeki modül sayısı
// 9 → 5. **2026 İKİNCİ güncelleme** — `requestPin()`'in `true` dönmesinin
// GERÇEK bir ekleme GARANTİ ETMEDİĞİ gerçek cihazda kanıtlanınca (bkz. o
// bölümdeki MIUI bulgusu), "Ekle" artık bir başarı/başarısızlık SnackBar'ı
// GÖSTERMİYOR — bunun yerine HER ZAMAN manuel ekleme talimatlarını
// gösteriyor, eski `nextResult`/SnackBar testleri buna göre değişti.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/screens/widgets_screen.dart';
import 'package:dijital_kanka/services/home_widget_service.dart';
import 'package:dijital_kanka/utils/widget_module.dart';

class _FakeHomeWidgetService implements HomeWidgetService {
  final List<ZiboWidgetModule> pinRequests = [];
  bool nextResult = true;

  @override
  Future<void> pushStatus(
    ZiboWidgetModule module, {
    required String title,
    required String primary,
    required String secondary,
    int? progress,
  }) async {}

  @override
  Future<void> pushCarousel(
    ZiboWidgetModule module, {
    required String title,
    required List<CarouselItem> items,
  }) async {}

  @override
  Future<bool> requestPin(ZiboWidgetModule module) async {
    pinRequests.add(module);
    return nextResult;
  }
}

Widget _buildTestApp(HomeWidgetService service) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('tr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: WidgetsScreen(homeWidgetService: service),
  );
}

void main() {
  testWidgets('Beş modülün hepsi kendi başlığıyla listelenir', (tester) async {
    await tester.pumpWidget(_buildTestApp(_FakeHomeWidgetService()));
    await tester.pumpAndSettle();

    // Listeyi GERÇEK EKRANDAKİ sırasıyla (yukarıdan aşağıya) kaydırarak
    // doğrula (bkz. CLAUDE.md "Test kalıpları" bölümündeki
    // `scrollUntilVisible` tek-yönlü kaydırma gotcha'sı — geriye dönük bir
    // sıralama sessizce kırılabilir).
    const titlesInOrder = [
      'Su Takibi',
      'Para ve Birikim',
      'Günlük Giriş Ödülleri',
      'Zibo\'nun Sözü',
      'İstatistiklerim',
    ];
    // Her başlığın kendi "Ekle" butonunu ANINDA (scroll edildiği anda,
    // toplu bir sayım yerine) doğrula — bkz. CLAUDE.md "Test kalıpları"
    // bölümündeki `ListView`'ın Sliver tabanlı lazy-build/cache-eviction
    // dersi.
    for (final title in titlesInOrder) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
          matching: find.widgetWithText(FilledButton, 'Ekle'),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    '"Ekle"ye basınca doğru modül için requestPin ARKA PLANDA çağrılır VE talimat sheet\'i açılır',
    (tester) async {
      final service = _FakeHomeWidgetService();
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      // İlk kart Su Takibi'ne ait — ilk "Ekle" butonu ona karşılık gelir.
      await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
      await tester.pumpAndSettle();

      expect(service.pinRequests, [ZiboWidgetModule.water]);
      // Eski başarı SnackBar'ı ARTIK YOK — bunun yerine üç adımlı talimat
      // sheet'i (bkz. `widgetsScreenAddSheetTitle`/`AddStep1-3`).
      expect(
        find.text('Widget eklendi! Ana ekranını kontrol et.'),
        findsNothing,
      );
      expect(find.text('Ana Ekranına Nasıl Eklenir?'), findsOneWidget);
      expect(
        find.text('Ana ekranının boş bir alanına parmağını basılı tut.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Açılan menüden "Widget\'lar" (bazı cihazlarda "Araçlar") seçeneğine dokun.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Listede Zibo\'yu bulup istediğin widget\'ı ana ekranına sürükle.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'requestPin false dönse bile AYNI talimat sheet\'i açılır (sonuca bağlı DEĞİL) ve "Anladım" kapatır',
    (tester) async {
      final service = _FakeHomeWidgetService()..nextResult = false;
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
      await tester.pumpAndSettle();

      expect(find.text('Ana Ekranına Nasıl Eklenir?'), findsOneWidget);
      expect(find.textContaining('Widget eklenemedi'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Anladım'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Ekranına Nasıl Eklenir?'), findsNothing);
    },
  );
}
