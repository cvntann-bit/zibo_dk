// "Zibonu Paylaş" akışını test eder: paylaş ikonuna basınca sheet açılır,
// gradyan seçimi değişir, "Paylaş"a basınca PNG baytları ve doğru metinle
// enjekte edilen sahte ShareService'e ulaşır. Gerçek share_plus platform
// channel'ına hiç dokunulmaz (MissingPluginException fırlatırdı).
//
// Not: RenderRepaintBoundary.toImage() gerçek raster işine bağlı olduğu için
// FakeAsync'in senkron saatiyle tıkanabilir; bu yüzden "Paylaş"a basılan
// senaryo tester.runAsync(...) içinde çalıştırılıyor.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/badge_provider.dart';
import 'package:dijital_kanka/providers/referral_provider.dart';
import 'package:dijital_kanka/providers/xp_provider.dart';
import 'package:dijital_kanka/services/share_service.dart';
import 'package:dijital_kanka/widgets/share_zibo_button.dart';

class _FakeShareService extends ShareService {
  _FakeShareService();

  Uint8List? lastBytes;
  String? lastFileName;
  String? lastText;
  int callCount = 0;

  @override
  Future<void> shareImageBytes(
    Uint8List bytes, {
    required String fileName,
    String? text,
  }) async {
    callCount++;
    lastBytes = bytes;
    lastFileName = fileName;
    lastText = text;
  }

  // 2026 — Davet Et (referral) özelliği ShareService'e shareText ekledi;
  // bu dosya yalnızca shareImageBytes'ı test ediyor, no-op override yeterli.
  @override
  Future<void> shareText(String text) async {}
}

const _testMessage = 'Bugün küçük bir adım, yarın büyük bir fark.';

Widget _buildTestApp(ShareService shareService) {
  // 2026 — Sosyal/Paylaşım Rozetleri: ZiboShareSheet._share() artık başarılı
  // bir paylaşımdan sonra context.read<BadgeProvider>()/
  // context.read<ReferralProvider>() çağırıyor (bkz. reconcileSocialBadges
  // hook'u) — bu bağımsız test uygulamasının ikisini de sağlaması gerekiyor,
  // aksi halde ProviderNotFoundException sessizce yutulup sheet HİÇ kapanmaz.
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BadgeProvider()),
      ChangeNotifierProvider(create: (_) => ReferralProvider()),
      ChangeNotifierProvider(create: (_) => XpProvider()),
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
        body: Center(
          child: ShareZiboButton(
            message: _testMessage,
            shareService: shareService,
          ),
        ),
      ),
    ),
  );
}

void main() {
  // google_fonts varsayılan olarak ağdan font indirmeye çalışır; testte hem
  // yavaşlık hem de ağ olmayan ortamlarda kararsızlık yaratmasın diye
  // kapatılıp yerel yedek (fallback) fontla devam edilmesi sağlanıyor.
  GoogleFonts.config.allowRuntimeFetching = false;

  // 2026 — BadgeProvider/ReferralProvider (bkz. yukarıdaki MultiProvider
  // notu) CloudStateStore üzerinden SharedPreferences'a dokunuyor —
  // mock'lanmadan `SharedPreferences.getInstance()` bir
  // MissingPluginException fırlatır (diğer TÜM provider testlerindeki AYNI
  // gereklilik).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Paylaş ikonuna basınca sheet açılır ve önizlemede söz görünür',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(_FakeShareService()));

      await tester.tap(find.byTooltip('Bu sözü paylaş'));
      await tester.pumpAndSettle();

      expect(find.text('Zibonu Paylaş'), findsOneWidget);
      expect(find.text(_testMessage), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
    },
  );

  testWidgets('Farklı bir gradyan swatch\'ına basınca seçim değişir', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(_FakeShareService()));
    await tester.tap(find.byTooltip('Bu sözü paylaş'));
    await tester.pumpAndSettle();

    Color? borderColorAt(int index) {
      final container = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).elementAt(index);
      final decoration = container.decoration as BoxDecoration;
      return decoration.border?.top.color;
    }

    // Varsayılan olarak ilk swatch ("Gece Kahvesi") seçili, ikincisi değil.
    expect(borderColorAt(0), isNot(Colors.transparent));
    expect(borderColorAt(1), Colors.transparent);

    await tester.tap(find.byType(AnimatedContainer).at(1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(borderColorAt(0), Colors.transparent);
    expect(borderColorAt(1), isNot(Colors.transparent));
  });

  testWidgets('Farklı bir yazı stiline basınca seçim değişir', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(_FakeShareService()));
    await tester.tap(find.byTooltip('Bu sözü paylaş'));
    await tester.pumpAndSettle();

    // İlk 8 AnimatedContainer arka plan swatch'ları; yazı stili
    // kartçıkları ondan sonra gelir (bkz. zibo_share_sheet.dart'taki sıra).
    const backgroundCount = 8;

    Color? borderColorAt(int index) {
      final container = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .elementAt(backgroundCount + index);
      final decoration = container.decoration as BoxDecoration;
      return decoration.border?.top.color;
    }

    expect(borderColorAt(0), isNot(Colors.transparent));
    expect(borderColorAt(1), Colors.transparent);

    // Bu kartçık sheet'in altına yakın, kaydırılabilir gövdenin görünür
    // alanının dışında kalabiliyor — tester.tap() koordinat hit-test
    // uyuşmazlığı yaşıyor (bkz. CLAUDE.md test tuzakları). Kartçığı saran
    // InkWell'in onTap'ini doğrudan çağırmak daha güvenilir.
    final targetContainer = find.byType(AnimatedContainer).at(
      backgroundCount + 1,
    );
    final targetInkWell = find
        .ancestor(of: targetContainer, matching: find.byType(InkWell))
        .first;
    tester.widget<InkWell>(targetInkWell).onTap!();
    await tester.pump(const Duration(milliseconds: 200));

    expect(borderColorAt(0), Colors.transparent);
    expect(borderColorAt(1), isNot(Colors.transparent));
  });

  testWidgets(
    'Paylaş\'a basınca fake ShareService\'e PNG baytları ve doğru metin ulaşır',
    (tester) async {
      final fakeService = _FakeShareService();
      await tester.pumpWidget(_buildTestApp(fakeService));
      await tester.tap(find.byTooltip('Bu sözü paylaş'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        // tester.tap(find.text(...)) burada (iç içe SingleChildScrollView +
        // modal bottom sheet birleşimi yüzünden) koordinat hit-test
        // uyuşmazlığı yaşıyor — widget_test.dart'taki GridView/IndexedStack
        // tuzağıyla aynı kategoride. Butonun onPressed'ini doğrudan çağırmak
        // (bkz. CLAUDE.md test tuzakları) daha güvenilir.
        //
        // onPressed'in statik dönüş tipi VoidCallback (void) olduğu için
        // _share()'in gerçek Future'ını buradan alıp await edemiyoruz;
        // toImage() Flutter'a yeni bir frame planlamadığından pumpAndSettle
        // de onu beklemeden erken döner. Bu yüzden tamamlanmayı gerçek
        // zamanlı olarak (fakeService'in kaydettiği çağrıyı yoklayarak)
        // bekliyoruz.
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
        for (var i = 0; i < 20 && fakeService.callCount == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
        await tester.pumpAndSettle();
      });

      expect(fakeService.callCount, 1);
      expect(fakeService.lastFileName, 'zibo_soz.png');
      expect(fakeService.lastText, _testMessage);
      // PNG dosya imzası: 0x89 'P' 'N' 'G'.
      expect(fakeService.lastBytes, isNotNull);
      expect(fakeService.lastBytes!.length, greaterThan(8));
      expect(fakeService.lastBytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

      // Başarılı paylaşımdan sonra sheet kapanır.
      expect(find.text('Zibonu Paylaş'), findsNothing);
    },
  );
}
