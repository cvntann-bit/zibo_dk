// WidgetsScreen'in dokuz modülü listelediğini VE her satırdaki "Ekle"
// butonunun enjekte edilen sahte `HomeWidgetService.requestPin`'i doğru
// modülle çağırdığını doğrudan (gerçek `home_widget` platform kanalına
// dokunmadan) test eder — bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü,
// `manifest_journal_screen_test.dart`'taki AYNI "bağımsız test uygulaması +
// sahte servis enjeksiyonu" deseni.

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
  testWidgets('Dokuz modülün hepsi kendi başlığıyla listelenir', (tester) async {
    await tester.pumpWidget(_buildTestApp(_FakeHomeWidgetService()));
    await tester.pumpAndSettle();

    // Dokuz kart varsayılan test yüzeyine sığmıyor — listeyi GERÇEK EKRANDAKİ
    // sırasıyla (yukarıdan aşağıya) kaydırarak doğrula (bkz. CLAUDE.md "Test
    // kalıpları" bölümündeki `scrollUntilVisible` tek-yönlü kaydırma
    // gotcha'sı — geriye dönük bir sıralama sessizce kırılabilir).
    const titlesInOrder = [
      'Hedef Takibi',
      'Su Takibi',
      'Şükran Günlüğü',
      'Ruh Hali Takibi',
      'Manifest Günlüğü',
      'Rüya Günlüğü',
      'Para ve Birikim',
      'Günlük Giriş Ödülleri',
      'Zibo\'nun Sözü',
    ];
    // Her başlığın kendi "Ekle" butonunu ANINDA (scroll edildiği anda,
    // toplu bir sayım yerine) doğrula — dokuzuncu karta kadar kaydırınca
    // `ListView`'ın Sliver tabanlı lazy-build mekanizması (bkz. CLAUDE.md
    // "Test kalıpları" bölümü) en üstteki kartları ARTIK İNŞA EDİLMİŞ
    // ağaçtan çıkarabiliyor — tüm kaydırma bittikten SONRA global bir
    // `findsNWidgets(9)` bu yüzden GERÇEK bir uygulama hatası olmadan
    // (yalnızca o anki cache penceresi yüzünden) başarısız olabiliyordu.
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

  testWidgets('"Ekle"ye basınca doğru modül için requestPin çağrılır', (tester) async {
    final service = _FakeHomeWidgetService();
    await tester.pumpWidget(_buildTestApp(service));
    await tester.pumpAndSettle();

    // İlk kart Hedef Takibi'ne ait — ilk "Ekle" butonu ona karşılık gelir.
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
    await tester.pumpAndSettle();

    expect(service.pinRequests, [ZiboWidgetModule.goals]);
    expect(find.text('Widget eklendi! Ana ekranını kontrol et.'), findsOneWidget);
  });

  testWidgets('requestPin false dönerse başarısızlık mesajı gösterilir', (tester) async {
    final service = _FakeHomeWidgetService()..nextResult = false;
    await tester.pumpWidget(_buildTestApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ekle').first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Widget eklenemedi'),
      findsOneWidget,
    );
  });
}
