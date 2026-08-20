// Basit smoke testleri: ana ekranın ilk hâlini, Zibo'ya dokununca mesajın
// değiştiğini, Hedef Takibi/Ayarlar içeriklerini ve coin kazanma/harcama/
// yetersiz bakiye akışlarını doğrular. Hedef Takibi'nin tarihe bağlı 7 günlük
// döngü mantığının ayrıntılı testleri goals_provider_test.dart içinde.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/goal_quotes.dart';
import 'package:dijital_kanka/data/money_quotes.dart';
import 'package:dijital_kanka/data/wheel_prizes.dart';
import 'package:dijital_kanka/data/zibo_messages.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/main.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/auth_link_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/daily_rewards_provider.dart';
import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/notification_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/theme_provider.dart';
import 'package:dijital_kanka/providers/trusted_time_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/profile_screen.dart';
import 'package:dijital_kanka/screens/root_screen.dart';
import 'package:dijital_kanka/screens/wheel_screen.dart';
import 'package:dijital_kanka/services/ad_service.dart';
import 'package:dijital_kanka/services/notification_service.dart';
import 'package:dijital_kanka/utils/ad_free_promo_trigger.dart';
import 'package:dijital_kanka/utils/tab_navigation.dart';

/// Gerçek [DijitalKankaApp] ile aynı kurulum, ama testte tarihi kontrol
/// edebilmek için [GoalsProvider]'a sahte bir saat enjekte eder.
Widget _buildAppWithClock(DateTime Function() now) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TrustedTimeProvider()),
      ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthLinkProvider()),
      ChangeNotifierProvider(create: (_) => CoinProvider(now: now)),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => DailyRewardsProvider(now: now)),
      ChangeNotifierProvider(create: (_) => FavoriteQuotesProvider()),
      ChangeNotifierProvider(create: (_) => GoalsProvider(now: now)),
      ChangeNotifierProvider(create: (_) => GratitudeProvider(now: now)),
      ChangeNotifierProvider(create: (_) => ManifestProvider(now: now)),
      ChangeNotifierProvider(create: (_) => MoneyProvider(now: now)),
      ChangeNotifierProvider(
        create: (_) =>
            NotificationProvider(notificationService: const FakeNotificationService()),
      ),
      ChangeNotifierProvider(create: (_) => ProfileProvider(now: now)),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider(now: now)),
      ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
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
      home: const RootScreen(),
    ),
  );
}

/// Uygulama İLK açılışta HER ZAMAN onboarding akışını gösterdiği için
/// (bkz. `OnboardingProvider`/`main.dart` `_AppStartupGate`), RootScreen
/// içeriğini bekleyen HER test önce bunu atlatmalı: isim adımına bir test
/// ismi yazıp "Devam Et"e basılır, ardından ilk modül tanıtım adımındaki
/// "Geç" ile akış tamamlanır (`OnboardingProvider.completeOnboarding()`
/// tetiklenir, `_AppStartupGate` doğrudan `RootScreen`'e geçer).
Future<void> _pumpPastOnboarding(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), 'Test Kullanıcı');
  // `enterText` kendi başına bir frame pump'lamıyor — `ValueListenableBuilder`
  // ile izlenen "Devam Et" butonunun enabled durumu bu `pump()` olmadan
  // güncellenmemiş halde kalıp buton hâlâ devre dışıymış gibi (onPressed:
  // null) tıklanabiliyordu (fiziksel tap başarılı ama sayfa ilerlemiyordu).
  await tester.pump();
  await tester.tap(find.text('Devam Et'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Geç'));
  await tester.pumpAndSettle();
}

/// Alt gezinme çubuğundaki Z butonuna basıp ek modüller menüsünü açar (bkz.
/// main_bottom_bar.dart/modules_menu_sheet.dart) — bar tamamen görsel
/// tabanlı olduğu için (ikon/etiketler PNG'nin içinde, gerçek Text widget'ı
/// yok) sekmeler VE Z butonu `find.bySemanticsLabel(...)` ile bulunuyor,
/// `find.text(...)` ile değil.
Future<void> _openModulesMenu(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Ek modülleri aç'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // AdFreePromoTrigger oturum bazlı, STATIK bir sayaç (bkz. o dosyadaki
    // dokümantasyon) — testler AYNI süreçte art arda koştuğu için, sıfırlanmazsa
    // bir testteki Mağaza ziyaretleri SONRAKİ testlerin sayacını kirletir.
    AdFreePromoTrigger.resetForTest();
    // isHomeTabActive global bir ValueNotifier (bkz. tab_navigation.dart) —
    // bir testin sekme geçişleri diğerinin başlangıç durumunu kirletmesin
    // diye her testte Ana Sayfa'ya sabitleniyor.
    isHomeTabActive.value = true;
    final dispatcher =
        TestWidgetsFlutterBinding.instance.platformDispatcher
            as TestPlatformDispatcher;
    // WheelTriggerButton'ın sürekli tekrar eden dönme animasyonu (bkz.
    // wheel_trigger_button.dart), MediaQuery'nin disableAnimations
    // bayrağına saygı duyacak şekilde yazıldı — kapatılmazsa hiç
    // "settle" olmadığı için pumpAndSettle() sonsuza kadar beklerdi.
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    // Varsayılan test görüntü alanı (800x600, geniş-kısa "masaüstü" oranı)
    // gerçek bir telefon ekranını hiç yansıtmıyor. `MainBottomBar` genişliğe
    // göre sabit bir en-boy oranıyla (bkz. main_bottom_bar.dart) yüksekliğini
    // hesapladığı için bu düşük/geniş viewport'ta orantısız derecede yer
    // kaplayıp içeriği sıkıştırıyor ve hit-test'leri bozuyordu — telefona
    // yakın (dar/uzun) bir viewport kullanmak bunu gerçek cihaz davranışına
    // yaklaştırıyor.
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
    'Onboarding: isim girilir, 7 modül tanıtılır, kapanışta isim geçer, '
    'tamamlanınca isim Profil\'e ve hitap tercihine yazılmış olarak Ana '
    "Sayfa açılır",
    (WidgetTester tester) async {
      await tester.pumpWidget(const DijitalKankaApp());
      await tester.pumpAndSettle();

      // İsim adımı: alan boşken "Devam Et" devre dışı.
      final continueButton = find.widgetWithText(FilledButton, 'Devam Et');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Ayşe');
      await tester.pump();
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // İlk modül tanıtımı: Hedef Takibi.
      expect(find.text('Hedef Takibi'), findsOneWidget);

      // Kalan 6 modülü + kapanış ekranına ulaşana kadar "İleri" ile ilerle
      // (Hedef Takibi/Su Takibi/Şükran/Ruh Hali/Manifest/Mağaza/Profil = 7
      // modül; Hedef Takibi'ndeyiz, kapanışa ulaşmak için 7 "İleri" gerekir).
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('İleri'));
        await tester.pumpAndSettle();
      }

      // Kapanış ekranı: girilen isim mesajda geçiyor.
      expect(find.textContaining('Ayşe'), findsWidgets);
      final startButton = find.text('Hadi Başlayalım!');
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Onboarding bitti — doğrudan Ana Sayfa açıldı.
      expect(find.bySemanticsLabel('Ana Sayfa'), findsOneWidget);

      // Girilen isim hem Profil'in isim alanına hem hitap tercihine
      // varsayılan olarak yazılmış olmalı.
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Ayşe'), findsOneWidget);
    },
  );

  testWidgets('Ana sayfa Zibo görselini ve ilk sözü gösterir', (
    WidgetTester tester,
  ) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());

    expect(find.byKey(const Key('ziboCharacterImage')), findsOneWidget);
    expect(find.text(ziboMessagesTr.first), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // başlangıç coin bakiyesi
  });

  testWidgets('Zibo\'ya dokununca söz değişir ve aynı söz tekrar etmez', (
    WidgetTester tester,
  ) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());
    // Zibo görselinin gerçek piksel boyutları decode edilmeden RenderImage
    // yüksekliği 0 kalabiliyor (bkz. CLAUDE.md test tuzakları) — tap()'in
    // hesapladığı merkez bu yüzden görselin dışına düşüp başka bir widget'ı
    // vurabiliyor. Kısa bir gerçek zaman beklemesi (runAsync, fake-time
    // pump'ların aksine) decode'un tamamlanmasına izin veriyor.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ziboCharacterImage')));
    await tester.pumpAndSettle();

    expect(find.text(ziboMessagesTr.first), findsNothing);
  });

  testWidgets(
    'Hedef Takibi sekmesi başlangıçta BOŞTUR (2026 güncellemesi — otomatik '
    'örnek hedef artık eklenmiyor); kullanıcı kendi hedefini ekleyince 7 gün '
    'kutucuğu görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();

      expect(find.text(goalQuotesTr.first), findsOneWidget);
      // Kullanıcı henüz hiçbir hedef eklemedi — hiçbir GoalCard yok,
      // yalnızca "Yeni Hedef Ekle" butonu görünüyor.
      expect(find.text('0/7 gün'), findsNothing);
      expect(find.text('Yeni Hedef Ekle'), findsOneWidget);

      await tester.tap(find.text('Yeni Hedef Ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Günde 30 dakika kitap oku',
      );
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();

      expect(find.text('Günde 30 dakika kitap oku'), findsOneWidget);
      expect(find.text('0/7 gün'), findsOneWidget);
      for (var day = 1; day <= 7; day++) {
        expect(find.text('$day'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Hedef Takibi konuşma balonundaki söz 5 saniyede bir otomatik değişir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();

      expect(find.text(goalQuotesTr.first), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      expect(find.text(goalQuotesTr.first), findsNothing);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Sadece bugünün kutucuğu tıklanabilir; gelecek günler kilitli, ödül gerçek 7. günde gelir',
    (WidgetTester tester) async {
      var currentDate = DateTime(2026, 1, 5);
      await tester.pumpWidget(_buildAppWithClock(() => currentDate));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();

      final goalsElement = tester.element(find.byType(RootScreen));
      final goalsProvider = Provider.of<GoalsProvider>(
        goalsElement,
        listen: false,
      );
      // 2026 güncellemesi: GoalsProvider artık otomatik bir örnek hedef
      // EKLEMİYOR (kullanıcı isteği) — test kendi hedefini açıkça ekliyor.
      goalsProvider.addGoal('Günde 30 dakika kitap oku');
      await tester.pumpAndSettle();

      // Gün 1 (bugün) tıklanabilir.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('1/7 gün'), findsOneWidget);

      // Gün 2'nin tarihi henüz gelmedi; tıklamak hiçbir şey yapmamalı
      // (aynı anda hem "1" hem "2" görünüyor olabilir, bu yüzden Gün 2'nin
      // ilerlemeyi değiştirmediğini kontrol ediyoruz).
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('1/7 gün'), findsOneWidget);

      // Kalan 6 günü, her defasında gerçekten bir gün ileri giderek
      // işaretle.
      for (var day = 2; day <= 7; day++) {
        currentDate = currentDate.add(const Duration(days: 1));
        goalsProvider.reconcileForToday();
        await tester.pumpAndSettle();

        await tester.tap(find.text('$day'));
        await tester.pumpAndSettle();
      }

      expect(
        find.textContaining('7 günlük hedefi tamamladın'),
        findsOneWidget,
      );
      expect(find.text('50'), findsOneWidget); // AppBar'daki güncel bakiye
      expect(find.text('0/7 gün'), findsOneWidget); // yeni döngü hazır

      // Tamamlanan Hedefler ikonu yalnızca Hedefler sekmesindeyken görünür
      // ve tamamlanma kaydı hedef adı altında gruplu şekilde görünür.
      await tester.tap(find.byTooltip('Tamamlanan Hedefler'));
      await tester.pumpAndSettle();
      expect(find.text('Günde 30 dakika kitap oku'), findsOneWidget);
      expect(find.text('1 haftalık tamamlama'), findsOneWidget);
      expect(find.text('1 tamamlama'), findsOneWidget);
    },
  );

  testWidgets(
    'Bir gün kaçırılırsa uygulama arka plandan öne gelince döngü sıfırlanır ve kullanıcı bilgilendirilir',
    (WidgetTester tester) async {
      var currentDate = DateTime(2026, 1, 5);
      await tester.pumpWidget(_buildAppWithClock(() => currentDate));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();
      // 2026 güncellemesi: GoalsProvider artık otomatik bir örnek hedef
      // EKLEMİYOR — test kendi hedefini açıkça ekliyor.
      final goalsProvider = Provider.of<GoalsProvider>(
        tester.element(find.byType(RootScreen)),
        listen: false,
      );
      goalsProvider.addGoal('Günde 30 dakika kitap oku');
      await tester.pumpAndSettle();
      await tester.tap(find.text('1')); // Gün 1'i işaretle
      await tester.pumpAndSettle();
      expect(find.text('1/7 gün'), findsOneWidget);

      // Salı hiç açılmadı; Çarşamba oldu ve uygulama (kapatılmadan, arka
      // planda) yeniden öne geliyor — provider ve widget durumu (Gün 1'in
      // işaretli olması dahil) korunuyor, yalnızca tarih ilerliyor.
      currentDate = currentDate.add(const Duration(days: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.textContaining('bir gün kaçırıldı'), findsOneWidget);
      expect(find.text('0/7 gün'), findsOneWidget); // döngü sıfırlandı
    },
  );

  testWidgets('Yeni hedef eklenebilir', (WidgetTester tester) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());

    await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni Hedef Ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Her gün 10.000 adım at');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.text('Her gün 10.000 adım at'), findsOneWidget);
  });

  testWidgets(
    'Para ve Birikim Zibo başlığını, kategorileri ve ilk sözü gösterir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Para ve Birikim artık bir alt sekme DEĞİL — Z butonunun açtığı
      // modül menüsünden push ediliyor (bkz. CLAUDE.md "Alt Gezinme
      // Çubuğu" — Profil↔Birikim yer değiştirme notu).
      await _openModulesMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Harcamalar ve Birikimler'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Harcamalar ve Birikimler'));
      await tester.pumpAndSettle();

      expect(find.text(moneyQuotesTr.first), findsOneWidget);

      // Liste kaydırılabilir (lazy) olduğu için alttaki kartların ağaca
      // girmesi için önce görünür hale getirmemiz gerekiyor.
      await tester.scrollUntilVisible(find.text('💰 Gelen Para'), 200);

      expect(find.text('💸 Harcamalar'), findsOneWidget);
      expect(find.text('📈 Birikimler'), findsOneWidget);
      expect(find.text('💰 Gelen Para'), findsOneWidget);
      expect(find.text('Henüz kayıt yok'), findsNWidgets(3));

      // Zamanlayıcıyı durdurmak için ekrandan geri çık (pushed bir rota
      // olduğu için `dispose()` çağrılır, artık `isActive`/sekme değişimi
      // gerekmiyor).
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Bir kategoriye kayıt eklenince listede ve toplamda görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await _openModulesMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Harcamalar ve Birikimler'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Harcamalar ve Birikimler'));
      await tester.pumpAndSettle();

      final expenseCard = find.ancestor(
        of: find.text('💸 Harcamalar'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: expenseCard, matching: find.text('Ekle')),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Market');
      await tester.enterText(textFields.at(1), '150,50');
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();

      expect(find.text('Market'), findsOneWidget);
      // Harcamalar kırmızı renkte "-" işaretiyle gösteriliyor.
      expect(find.text('-₺150.50'), findsOneWidget);
      expect(find.text('Toplam: ₺150.50'), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Para ve Birikim konuşma balonundaki söz 5 saniyede bir otomatik değişir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await _openModulesMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Harcamalar ve Birikimler'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Harcamalar ve Birikimler'));
      await tester.pumpAndSettle();

      expect(find.text(moneyQuotesTr.first), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      expect(find.text(moneyQuotesTr.first), findsNothing);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Mağaza + ikonuyla açılır, paketleri ve ücretsiz reklam kartını gösterir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();

      // Biri sayfanın kendi başlığı, biri alt gezinme çubuğundaki
      // (kod-tabanlı, bkz. main_bottom_bar.dart) sekme etiketi.
      expect(find.text('Mağaza'), findsNWidgets(2));
      expect(find.text('Reklam İzle'), findsOneWidget);
      expect(find.text('100 ZC'), findsOneWidget);
      expect(find.text('250 ZC'), findsOneWidget);
      expect(find.text('500 ZC'), findsOneWidget);
      expect(find.text('1000 ZC'), findsOneWidget);
      expect(find.text('10000 ZC'), findsOneWidget);

      // "Satın Al" yerine gerçek (şimdilik sabit/görsel) TL fiyatları
      // gösterilmeli (bkz. CoinPackage.price / PackagePrice.formatted).
      expect(find.text('19,99 ₺'), findsOneWidget);
      expect(find.text('44,99 ₺'), findsOneWidget);
      expect(find.text('84,99 ₺'), findsOneWidget);
      expect(find.text('159,99 ₺'), findsOneWidget);
      expect(find.text('1.499,99 ₺'), findsOneWidget);
    },
  );

  testWidgets('Mağazadan paket satın alınca bakiye artar', (
    WidgetTester tester,
  ) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());

    await tester.tap(find.byTooltip('Coin satın al'));
    await tester.pumpAndSettle();

    // Not: IndexedStack sekmesi içindeki (kaydırılmayan, iç içe) GridView
    // kartlarında flutter_test'in koordinat tabanlı tap()'i gerçek bir
    // hit-test uyuşmazlığı bildiriyor (gerçek tarayıcıda tıklama sorunsuz
    // çalışıyor — bu test ortamına özgü bir düzen tuhaflığı). Bu yüzden
    // butonun onPressed'ini doğrudan çağırıyoruz.
    final package100Card = find.ancestor(
      of: find.text('100 ZC'),
      matching: find.byType(Card),
    );
    final buyButton = tester.widget<FilledButton>(
      find.descendant(of: package100Card, matching: find.byType(FilledButton)),
    );
    buyButton.onPressed!();
    await tester.pumpAndSettle();

    // İLK gerçek satın alma denemesi olduğu için (hesap Google'a henüz
    // bağlı değil) önce Google-bağlama teşvik sheet'i açılıyor (bkz.
    // `StoreScreen._PackageCardState._buy`) — asıl satın alma bu sheet
    // kapanana kadar beklemede kalıyor, "Şimdilik Atla"ya basıp devam
    // ettiriyoruz.
    expect(find.byKey(const Key('googleLinkPromoSkipButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('googleLinkPromoSkipButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('100 Zibo Coin hesabına eklendi'), findsOneWidget);
    // Mağaza artık bir sekme olduğu için başlık çubuğu (ve dolayısıyla
    // coin bakiyesi) sayfadan ayrılmadan hep görünür durumda.
    expect(find.text('100'), findsOneWidget); // AppBar'daki güncel bakiye
  });

  testWidgets('Mağazadan reklam izleyince 20 Zibo Coin kazanılır', (
    WidgetTester tester,
  ) async {
    // Gerçek AdMobAdService, flutter_test'in platform kanalına dokunamadığı
    // bir ortamda reklam yükleyemez (bkz. main.dart'taki DijitalKankaApp.
    // adService dokümantasyonu) — bu senaryo "reklam izlenince ödül
    // veriliyor mu" akışını test ettiği için MockAdService (her zaman
    // başarılı) enjekte ediliyor.
    await _pumpPastOnboarding(
      tester,
      const DijitalKankaApp(adService: MockAdService()),
    );

    await tester.tap(find.byTooltip('Coin satın al'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('İzle'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('20 Zibo Coin hesabına eklendi'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Zibo ADS (reklamsız deneyim) tanıtımı 5. Mağaza ziyaretinde görünür, '
    'Satın Al mockup mesajı gösterir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      Future<void> visitStoreThenLeave() async {
        await tester.tap(find.byTooltip('Coin satın al'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
        await tester.pumpAndSettle();
      }

      // 1-4. ziyaretler — AdFreePromoTrigger'ın eşiğine (5, bkz.
      // ad_free_promo_trigger.dart) henüz ulaşılmadı.
      for (var i = 0; i < 4; i++) {
        await visitStoreThenLeave();
        expect(find.text('Zibo ADS'), findsNothing);
      }

      // 5. ziyaret — tanıtım sheet'i açılmalı (cooldown de sıfır — bkz.
      // setUp()'taki AdFreePromoTrigger.resetForTest()).
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      expect(find.text('Zibo ADS'), findsOneWidget);
      expect(find.text('Reklamsız Deneyim'), findsOneWidget);
      expect(find.text('Reklam yok'), findsOneWidget);
      expect(find.text('Kesintisiz kullanım'), findsOneWidget);

      // "Satın Al" — gerçek bir işlem YAPMAZ, yalnızca mockup mesajı
      // gösterip sheet'i kapatır (bkz. CLAUDE.md "Zibo ADS" bölümü).
      await tester.tap(find.byKey(const Key('adFreePromoBuyButton')));
      await tester.pumpAndSettle();
      expect(find.text('Zibo ADS'), findsNothing);
      expect(
        find.textContaining('Reklamsız deneyim çok yakında sunulacak'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Zibo ADS tanıtımı "Belki Sonra" ile mesaj göstermeden kapanır',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      Future<void> visitStoreThenLeave() async {
        await tester.tap(find.byTooltip('Coin satın al'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
        await tester.pumpAndSettle();
      }

      for (var i = 0; i < 4; i++) {
        await visitStoreThenLeave();
      }
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      expect(find.text('Zibo ADS'), findsOneWidget);

      await tester.tap(find.byKey(const Key('adFreePromoDismissButton')));
      await tester.pumpAndSettle();
      expect(find.text('Zibo ADS'), findsNothing);
      expect(
        find.textContaining('Reklamsız deneyim çok yakında sunulacak'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Zibo ADS: cooldown süresi dolmadan aynı Mağaza ziyaret örüntüsü '
    'tanıtımı TEKRAR göstermez',
    (WidgetTester tester) async {
      // AdFreePromoTrigger.resetForTest ile "az önce gösterildi" durumu
      // simüle ediliyor — 5. ziyarette eşik dolsa bile 3 günlük cooldown
      // (bkz. ad_free_promo_trigger.dart) henüz geçmediği için sheet
      // AÇILMAMALI.
      AdFreePromoTrigger.resetForTest(lastShownAt: DateTime.now());

      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      Future<void> visitStoreThenLeave() async {
        await tester.tap(find.byTooltip('Coin satın al'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
        await tester.pumpAndSettle();
      }

      for (var i = 0; i < 4; i++) {
        await visitStoreThenLeave();
      }
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      expect(find.text('Zibo ADS'), findsNothing);
    },
  );

  testWidgets('Ayarlar dişli ikonuyla açılır ve satırları gösterir', (
    WidgetTester tester,
  ) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();

    // Bildirimler kartı GEÇİCİ olarak rafa kaldırıldı (bkz.
    // notification_provider.dart'taki notificationsFeatureEnabled ve
    // CLAUDE.md "Bildirimler" bölümündeki MIUI tanısı) — bu yüzden burada
    // artık gösterilmiyor.
    expect(find.text('Bildirimler'), findsNothing);
    expect(find.text('Dil'), findsOneWidget);
    // Varsayılan dil Türkçe — Dil satırının alt metni bunu yansıtmalı.
    expect(find.text('Türkçe'), findsOneWidget);
    // Coin Test Paneli (geçici) kullanıcı isteğiyle tamamen kaldırıldı.
    expect(find.text('Coin Test Paneli (geçici)'), findsNothing);

    // Genel/Destek/Uygulama Hakkında bölüm başlıkları + içerikleri (bkz.
    // CLAUDE.md "Ayarlar" bölümü). **2026 güncellemesi — "Push Bildirimleri"
    // bölümü (başlık + dört tek tek anahtar) TAMAMEN kaldırıldı** — kullanıcı
    // isteği: bu ayrı bir bölüm olarak gereksizdi (bkz. CLAUDE.md "Push
    // Bildirimleri" bölümündeki not).
    expect(find.text('Genel'), findsOneWidget);
    expect(find.text('Push Bildirimleri'), findsNothing);
    expect(find.text('Günlük Motivasyon'), findsNothing);
    expect(find.text('Streak Hatırlatması'), findsNothing);
    expect(find.text('Günlük Ödül Hatırlatması'), findsNothing);
    expect(find.text('Seni Özledik'), findsNothing);
    await tester.scrollUntilVisible(find.text('Destek'), 300);
    expect(find.text('Destek'), findsOneWidget);
    expect(find.text('Bize Ulaşın'), findsOneWidget);
    expect(find.text('contact@getzibo.com'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Uygulama Hakkında'), 300);
    expect(find.text('Uygulama Hakkında'), findsOneWidget);
    expect(find.text('Sürüm'), findsOneWidget);
    expect(find.text('Web Sitesi'), findsOneWidget);
    expect(find.text('getzibo.com'), findsOneWidget);
    expect(find.text('Gizlilik Politikası'), findsOneWidget);
    expect(find.text('Kullanım Koşulları'), findsOneWidget);
  });

  testWidgets(
    'Ayarlar > Gizlilik Politikası ve Kullanım Koşulları yer tutucu sayfa açar',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();

      // "Gizlilik Politikası"/"Kullanım Koşulları" ilk lazy-build aralığının
      // dışında kalabiliyor (bkz. yukarıdaki AYNI ders). Kaydırma sonrası
      // satır AppBar'a çok yakın kalıp koordinat
      // tabanlı `tester.tap()`in hit-test'i şaşırabildiği için (bkz. "Test
      // kalıpları" bölümündeki GridView/hit-test uyuşmazlığı deseni)
      // `ListTile.onTap`'i DOĞRUDAN çağırıyoruz.
      await tester.scrollUntilVisible(find.text('Gizlilik Politikası'), 300);
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Gizlilik Politikası'),
              matching: find.byType(ListTile),
            ),
          )
          .onTap!();
      await tester.pumpAndSettle();
      expect(
        find.text('Bu içerik yakında burada olacak.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Kullanım Koşulları'), 300);
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Kullanım Koşulları'),
              matching: find.byType(ListTile),
            ),
          )
          .onTap!();
      await tester.pumpAndSettle();
      expect(
        find.text('Bu içerik yakında burada olacak.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Dil seçici: İngilizce seçilince arayüz her yerde İngilizce\'ye döner',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Sheet kapandı, Ayarlar sayfası artık İngilizce.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Ana Sayfa / alt gezinme çubuğu da tutarlı şekilde İngilizce.
      // Not: alt gezinme çubuğunun 3. sekmesi artık Profil (eskiden
      // Birikim'in yeri, bkz. CLAUDE.md "Alt Gezinme Çubuğu" — Profil↔
      // Birikim yer değiştirme notu).
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text(ziboMessagesEn.first), findsOneWidget);
    },
  );

  testWidgets(
    'Koyu Tema anahtarı açılınca uygulama koyu temaya geçer',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      expect(
        Theme.of(tester.element(find.byType(RootScreen))).brightness,
        Brightness.light,
      );

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();

      expect(find.text('Koyu Tema'), findsOneWidget);
      // Ayarlar sayfasında birden fazla `Switch` var (Koyu Tema/Ses
      // Efektleri), bu yüzden `find.byType(Switch)` belirsiz — spesifik
      // `SwitchListTile`'ı başlığından buluyoruz.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Koyu Tema'));
      await tester.pumpAndSettle();

      // Ayarlar sayfası RootScreen'in ÜSTÜNE push edildiği için RootScreen
      // artık ekranda GÖRÜNMÜYOR (yalnızca state korunuyor) — varsayılan
      // `find.byType` (skipOffstage: true) bu yüzden onu bulamıyor, elle
      // `skipOffstage: false` verilmesi gerekiyor.
      expect(
        Theme.of(
          tester.element(find.byType(RootScreen, skipOffstage: false)),
        ).brightness,
        Brightness.dark,
      );

      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('isDarkMode')!) as Map<String, dynamic>;
      expect(saved['value'], isTrue);
    },
  );

  testWidgets('Günlük check-in ile coin kazanılır ve başlıktaki bakiye artar', (
    WidgetTester tester,
  ) async {
    await _pumpPastOnboarding(tester, const DijitalKankaApp());

    // Geçici Coin Test Paneli kaldırıldığı için (kullanıcı isteği) kazanma
    // akışı doğrudan CoinProvider üzerinden tetikleniyor — GoalsProvider'ı
    // `_buildAppWithClock` testlerinde doğrudan manipüle etme deseniyle aynı.
    final coinsElement = tester.element(find.byType(RootScreen));
    Provider.of<CoinProvider>(coinsElement, listen: false).earnDailyCheckIn();
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget); // AppBar'daki güncel bakiye
  });

  testWidgets(
    'Kostüm satın alınıp giyilebilir; Ana Sayfa\'daki görsel değişir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kostümler'));
      await tester.pumpAndSettle();

      expect(find.text('Hippi Zibo'), findsOneWidget);
      // Not: "Sporcu Zibo" da 440 ZC olduğu için fiyat metni tüm ağaçta tek
      // değil — bu yüzden bu kontrol Hippi Zibo kartına özel yapılıyor.
      final hippiCard = find.ancestor(
        of: find.text('Hippi Zibo'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: hippiCard, matching: find.text('440 ZC')),
        findsOneWidget,
      );

      // Not: IndexedStack sekmesi içindeki (kaydırılmayan, iç içe) GridView
      // kartlarında flutter_test'in koordinat tabanlı tap()'i gerçek bir
      // hit-test uyuşmazlığı bildiriyor (bkz. yukarıdaki "paket satın
      // alınca" testi) — bu yüzden buton/InkWell'lere doğrudan erişiyoruz.
      FilledButton buyButton() => tester.widget<FilledButton>(
        find.descendant(of: hippiCard, matching: find.byType(FilledButton)),
      );

      // Bakiye yok — satın almaya çalışınca uyarı çıkar, hiçbir şey
      // değişmez.
      buyButton().onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Yetersiz Zibo Coin'), findsOneWidget);

      // 440 ZC için yeterli bakiyeyi kazan (5 × Arkadaş daveti = 500).
      // Geçici Coin Test Paneli kaldırıldığı için (kullanıcı isteği) doğrudan
      // CoinProvider üzerinden tetikleniyor.
      final coinsElement = tester.element(find.byType(RootScreen));
      final coinProvider = Provider.of<CoinProvider>(
        coinsElement,
        listen: false,
      );
      for (var i = 0; i < 5; i++) {
        coinProvider.earnReferral();
      }
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget); // AppBar'daki güncel bakiye

      buyButton().onPressed!();
      await tester.pumpAndSettle();

      expect(find.textContaining('Hippi Zibo satın alındı'), findsOneWidget);
      expect(find.text('60'), findsOneWidget); // 500 - 440 = 60
      expect(find.text('Sahip olunan'), findsOneWidget);

      InkWell hippiInkWell() => tester.widget<InkWell>(
        find.descendant(of: hippiCard, matching: find.byType(InkWell)),
      );

      // Sahip olunan karta dokununca giyilir.
      hippiInkWell().onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Giyili'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      final equippedImage = tester.widget<Image>(
        find.byKey(const Key('ziboCharacterImage')),
      );
      expect(
        (equippedImage.image as AssetImage).assetName,
        'assets/images/zibo_hippi_pose1.png',
      );

      // Aynı kostüm Hedef Takibi sekmesindeki VE Para ve Birikim'deki
      // (artık Z butonu modül menüsünden push edilen bir ekran, bkz.
      // CLAUDE.md "Alt Gezinme Çubuğu") Zibo görselinde de yansımalı.
      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();
      expect(
        (tester
                    .widget<Image>(find.byKey(const Key('ziboGoalTrackingImage')))
                    .image
                as AssetImage)
            .assetName,
        'assets/images/zibo_hippi_pose1.png',
      );

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      await _openModulesMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Harcamalar ve Birikimler'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Harcamalar ve Birikimler'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byKey(const Key('ziboMoneyImage'))).image
                as AssetImage)
            .assetName,
        'assets/images/zibo_hippi_pose1.png',
      );
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();

      // Giyili karta tekrar dokununca çıkarılır, varsayılan görsele döner.
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kostümler'));
      await tester.pumpAndSettle();
      hippiInkWell().onTap!();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      final defaultImage = tester.widget<Image>(
        find.byKey(const Key('ziboCharacterImage')),
      );
      // Kostümsüz Zibo artık sabit tek görsel (zibo_yeni.png) yerine
      // varsayılan poz setinin (bkz. costume_poses.dart) ilk karesiyle
      // açılıyor — bkz. CLAUDE.md "Zibo Poz/Animasyon Sistemi" bölümü.
      expect(
        (defaultImage.image as AssetImage).assetName,
        'assets/images/zibo_df_pose1.png',
      );
    },
  );

  testWidgets(
    '2026 kostüm paketi (Kral Zibo) satın alınıp giyilebilir; poz seti '
    'Ana Sayfa\'da devreye girer',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kostümler'));
      await tester.pumpAndSettle();

      expect(find.text('Kral Zibo'), findsOneWidget);
      final kingCard = find.ancestor(
        of: find.text('Kral Zibo'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: kingCard, matching: find.text('1045 ZC')),
        findsOneWidget,
      );

      FilledButton buyButton() => tester.widget<FilledButton>(
        find.descendant(of: kingCard, matching: find.byType(FilledButton)),
      );

      final coinsElement = tester.element(find.byType(RootScreen));
      final coinProvider = Provider.of<CoinProvider>(
        coinsElement,
        listen: false,
      );
      // 1045 ZC için yeterli bakiyeyi kazan (11 × Arkadaş daveti = 1100).
      for (var i = 0; i < 11; i++) {
        coinProvider.earnReferral();
      }
      await tester.pumpAndSettle();

      buyButton().onPressed!();
      await tester.pumpAndSettle();
      expect(find.textContaining('Kral Zibo satın alındı'), findsOneWidget);

      InkWell kingInkWell() => tester.widget<InkWell>(
        find.descendant(of: kingCard, matching: find.byType(InkWell)),
      );
      kingInkWell().onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Giyili'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      final equippedImage = tester.widget<Image>(
        find.byKey(const Key('ziboCharacterImage')),
      );
      // Kral Zibo'nun poz seti costume_poses.dart'a eklendi — kostüm
      // giyilince Ana Sayfa artık statik `zibo_king.png` yerine poz
      // setinin ilk karesini gösteriyor (poseStep=0).
      expect(
        (equippedImage.image as AssetImage).assetName,
        'assets/images/zibo_king_pose1.png',
      );
    },
  );

  testWidgets(
    'Tema satın alınıp uygulanabilir; Ana Sayfa\'nın arka planı değişir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Uygulama öncesi: arka plan gradyanı yok.
      expect(find.byKey(const Key('homeThemeGradientBackground')), findsNothing);

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();

      expect(find.text('Gün Batımı'), findsOneWidget);
      final sunsetCard = find.ancestor(
        of: find.text('Gün Batımı'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: sunsetCard, matching: find.text('250 ZC')),
        findsOneWidget,
      );

      // IndexedStack içindeki GridView kartlarında koordinat tabanlı tap()
      // güvenilir olmadığı için (bkz. kostüm testindeki aynı not) buton/
      // InkWell'lere doğrudan erişiliyor.
      FilledButton buyButton() => tester.widget<FilledButton>(
        find.descendant(of: sunsetCard, matching: find.byType(FilledButton)),
      );

      final coinsElement = tester.element(find.byType(RootScreen));
      final coinProvider = Provider.of<CoinProvider>(
        coinsElement,
        listen: false,
      );
      // 250 ZC için yeterli bakiyeyi kazan (3 × Arkadaş daveti = 300).
      for (var i = 0; i < 3; i++) {
        coinProvider.earnReferral();
      }
      await tester.pumpAndSettle();

      buyButton().onPressed!();
      await tester.pumpAndSettle();

      expect(find.textContaining('Gün Batımı teması satın alındı'), findsOneWidget);
      expect(find.text('Sahip olunan'), findsOneWidget);

      InkWell sunsetInkWell() => tester.widget<InkWell>(
        find.descendant(of: sunsetCard, matching: find.byType(InkWell)),
      );

      // Sahip olunan karta dokununca uygulanır.
      sunsetInkWell().onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Aktif'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('homeThemeGradientBackground')), findsOneWidget);

      // Tema yalnızca Ana Sayfa'nın gradyan arka planını DEĞİL, MaterialApp
      // seviyesindeki ColorScheme'i (dolayısıyla TÜM ekranları — sekmeler VE
      // Z-menüsünden push edilen modüller) değiştiriyor mu diye doğrulanıyor
      // (bkz. CLAUDE.md "Temalar" bölümü — bu app-wide etki daha önce hiç
      // otomatik testle kapsanmamıştı, yalnızca gerçek cihazda elle
      // doğrulanmıştı). "Gün Batımı"nın açık mod `lightPrimary`'si
      // `0xFFD9531D` (bkz. app_themes.dart).
      const sunsetLightPrimary = Color(0xFFD9531D);
      Color primaryColorAt(Finder within) =>
          Theme.of(tester.element(within)).colorScheme.primary;

      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      expect(
        primaryColorAt(find.byType(ProfileScreen)),
        sunsetLightPrimary,
      );

      await _openModulesMenu(tester);
      await tester.scrollUntilVisible(
        find.text('Su Takibi'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Su Takibi'));
      await tester.pumpAndSettle();
      expect(
        primaryColorAt(find.byType(Scaffold).first),
        sunsetLightPrimary,
      );
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // Aktif karta tekrar dokununca kaldırılır, arka plan varsayılana döner.
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();
      sunsetInkWell().onTap!();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('homeThemeGradientBackground')), findsNothing);
    },
  );

  testWidgets(
    'Premium/Animasyonlu tema (Kış Teması) satın alınıp uygulanınca tüm '
    'sayfalarda canlı parçacık katmanı görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();

      // 2026 güncellemesi — Standart/Premium ayrımı kaldırıldı, artık TEK
      // bir fiyata-göre-sıralı liste (bkz. store_screen.dart _ThemesSection).
      expect(find.text('Kış Teması'), findsOneWidget);

      final winterCard = find.ancestor(
        of: find.text('Kış Teması'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: winterCard, matching: find.text('700 ZC')),
        findsOneWidget,
      );

      FilledButton buyButton() => tester.widget<FilledButton>(
        find.descendant(of: winterCard, matching: find.byType(FilledButton)),
      );

      final coinsElement = tester.element(find.byType(RootScreen));
      final coinProvider = Provider.of<CoinProvider>(
        coinsElement,
        listen: false,
      );
      // 700 ZC için yeterli bakiyeyi kazan (7 × Arkadaş daveti = 700).
      for (var i = 0; i < 7; i++) {
        coinProvider.earnReferral();
      }
      await tester.pumpAndSettle();

      buyButton().onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Kış Teması teması satın alındı'),
        findsOneWidget,
      );

      InkWell winterInkWell() => tester.widget<InkWell>(
        find.descendant(of: winterCard, matching: find.byType(InkWell)),
      );

      // Uygulamadan ÖNCE Ana Sayfa'da canlı parçacık katmanı YOK.
      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeParticleEffect')), findsNothing);

      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();
      winterInkWell().onTap!();
      await tester.pumpAndSettle();

      // Uygulandıktan SONRA Ana Sayfa'da canlı parçacık katmanı görünüyor —
      // `main.dart`'ın `builder:` zincirindeki `AnimatedThemeOverlay` TÜM
      // sayfaların renk paletini/arka planını sarar, ama HAREKETLİ katman
      // BİLEREK yalnızca Ana Sayfa'da (bkz. CLAUDE.md "Temalar" bölümündeki
      // 2026 güncellemesi — `isHomeTabActive`).
      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeParticleEffect')), findsOneWidget);

      // Başka bir sekmede (Hedefler) katman GÖRÜNMEZ — yalnızca Ana Sayfa'ya
      // özel.
      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeParticleEffect')), findsNothing);

      // Ana Sayfa'ya geri dönünce katman tekrar görünür.
      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeParticleEffect')), findsOneWidget);

      // Kaldırınca katman de kaybolur.
      await tester.tap(find.byTooltip('Coin satın al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();
      winterInkWell().onTap!();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeParticleEffect')), findsNothing);
    },
  );

  testWidgets(
    'Şans Çarkı: reklam izleyip çevirince ağırlıklı bir ödül kazanılır ve bakiyeye eklenir',
    (WidgetTester tester) async {
      // bkz. yukarıdaki "Mağazadan reklam izleyince..." testindeki AYNI
      // gerekçe — gerçek AdMobAdService testte reklam yükleyemez.
      await _pumpPastOnboarding(
        tester,
        const DijitalKankaApp(adService: MockAdService()),
      );

      // Sol kenardaki sürekli dönen tetikleyici yalnızca Ana Sayfa
      // sekmesinde görünür (varsayılan seçili sekme burada zaten Ana Sayfa).
      await tester.tap(find.byTooltip('Şans Çarkı'));
      await tester.pumpAndSettle();

      expect(find.text('Şans Çarkı'), findsOneWidget); // popup başlığı

      // "Reklam İzle ve Çevir" metni/ikonu artık zibo_cark_frame.png
      // görselinin içinde hazır geliyor (ayrı bir Text/Icon widget'ı yok);
      // dokunma alanı WheelScreen içindeki Key('wheelSpinButton') ile
      // işaretli InkWell (kapatma IconButton'ı da bir InkWell içerdiği için
      // find.byType(InkWell) artık tekil değil).
      final spinInkWell = find.byKey(const Key('wheelSpinButton'));
      tester.widget<InkWell>(spinInkWell).onTap!();
      await tester.pumpAndSettle();

      final resultFinder = find.textContaining('Zibo Coin kazandın!');
      expect(resultFinder, findsOneWidget);
      final resultText = tester.widget<Text>(resultFinder).data!;
      final wonAmount = int.parse(
        RegExp(
          r'(\d+) Zibo Coin kazandın!',
        ).firstMatch(resultText)!.group(1)!,
      );
      expect(wheelPrizes.map((p) => p.amount), contains(wonAmount));

      final coinProvider = Provider.of<CoinProvider>(
        tester.element(find.byType(RootScreen)),
        listen: false,
      );
      expect(coinProvider.balance, wonAmount);

      await tester.tap(find.text('Harika!'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpAndSettle();

      expect(find.text('$wonAmount'), findsOneWidget); // AppBar bakiyesi
    },
  );

  testWidgets(
    'Şans Çarkı tetikleyicisi yalnızca Ana Sayfa sekmesinde görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      expect(find.byTooltip('Şans Çarkı'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Şans Çarkı'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Şans Çarkı'), findsOneWidget);
    },
  );

  testWidgets(
    'Günlük Giriş Ödülleri: bugünün kutucuğuna dokununca ödül alınır ve bakiyeye eklenir',
    (WidgetTester tester) async {
      // Gerçek AdMobAdService, flutter_test'in platform kanalına dokunamadığı
      // bir ortamda reklam yükleyemez ve `showInterstitialAd()`'ın kendi
      // 8sn'lik zaman aşımı Timer'ı test bitiminde hâlâ askıda kalıp
      // "A Timer is still pending" hatasına yol açar (bkz. CLAUDE.md "Zibo
      // Coin ekonomisi" — günlük giriş ödülü artık claim sonrası bir geçiş
      // reklamı tetikliyor) — bu yüzden burada da (Mağaza'nın reklam izleme
      // testindeki AYNI gerekçeyle) MockAdService enjekte ediliyor.
      await _pumpPastOnboarding(
        tester,
        const DijitalKankaApp(adService: MockAdService()),
      );

      // Sağ kenardaki tetikleyici, Şans Çarkı'nın simetriği — yalnızca Ana
      // Sayfa sekmesinde (varsayılan seçili sekme burada zaten Ana Sayfa).
      await tester.tap(find.byTooltip('Günlük Ödüller'));
      await tester.pumpAndSettle();

      expect(find.text('Günlük Giriş Ödülleri'), findsOneWidget); // popup başlığı
      expect(find.text('Gün 1'), findsOneWidget);

      await tester.tap(find.text('Gün 1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bugün 5 Zibo Coin aldın'), findsOneWidget);

      final coinProvider = Provider.of<CoinProvider>(
        tester.element(find.byType(RootScreen)),
        listen: false,
      );
      expect(coinProvider.balance, 5);

      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget); // AppBar bakiyesi
    },
  );

  testWidgets(
    'Günlük Giriş Ödülleri tetikleyicisi yalnızca Ana Sayfa sekmesinde görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      expect(find.byTooltip('Günlük Ödüller'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Hedef Takibi'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Günlük Ödüller'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Günlük Ödüller'), findsOneWidget);
    },
  );

  // "Yetersiz bakiyeyle harcama denendiğinde uyarı gösterilir" testi
  // kaldırıldı — yalnızca geçici Coin Test Paneli'nin (kullanıcı isteğiyle
  // silindi) harcama butonlarını tetikliyordu. Aynı davranış hâlâ iki yerde
  // kapsanıyor: `_spend`/insufficient-balance mantığı provider seviyesinde
  // coin_provider_test.dart'ta, "Yetersiz Zibo Coin" uyarısının GERÇEK UI
  // akışında (kilitli kostüm satın alma) gösterildiği ise yukarıdaki
  // "Kostüm satın alınıp giyilebilir" testinde doğrulanıyor.

  testWidgets(
    'Rüya Günlüğü: rüya eklenebilir, düzenlenebilir ve silinebilir',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Rüya Günlüğü artık AppBar'da değil, Z butonunun açtığı modül
      // menüsünde (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü).
      await _openModulesMenu(tester);
      await tester.tap(find.text('Rüya Günlüğü'));
      await tester.pumpAndSettle();

      expect(find.text('Rüya Günlüğü'), findsOneWidget); // AppBar başlığı
      expect(
        find.text('Henüz bir rüya yazmadın. Bugün gördüğün bir rüya var mı?'),
        findsOneWidget,
      );

      // Yeni rüya ekle.
      await tester.tap(find.text('Yeni Rüya Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Rüya'), findsOneWidget); // form AppBar başlığı
      await tester.enterText(find.byType(TextField).at(0), 'Uçmak');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Gökyüzünde uçtuğumu gördüm.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Listeye dönüldü, yeni kayıt görünüyor.
      expect(find.text('Uçmak'), findsOneWidget);
      expect(
        find.text('Henüz bir rüya yazmadın. Bugün gördüğün bir rüya var mı?'),
        findsNothing,
      );

      // Kayda dokununca düzenleme formu açılır, alanlar önceden dolu gelir.
      await tester.tap(find.text('Uçmak'));
      await tester.pumpAndSettle();

      expect(find.text('Rüyayı Düzenle'), findsOneWidget);
      expect(find.text('Uçmak'), findsOneWidget);
      expect(find.text('Gökyüzünde uçtuğumu gördüm.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).at(0),
        'Uçmak (düzenlendi)',
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Uçmak (düzenlendi)'), findsOneWidget);

      // Sil: kayda tekrar dokun, sil ikonuna bas, onay diyaloğunu onayla.
      await tester.tap(find.text('Uçmak (düzenlendi)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();

      expect(find.text('Rüyayı sil?'), findsOneWidget);
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(
        find.text('Henüz bir rüya yazmadın. Bugün gördüğün bir rüya var mı?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Şükran Günlüğü: 3 cümle yazılıp kaydedilince gün kilitlenir ve 2 Zibo Coin kazanılır',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Şükran Günlüğü artık Ayarlar'da değil, Z butonunun açtığı modül
      // menüsünde (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü).
      await _openModulesMenu(tester);
      await tester.tap(find.text('Şükran Günlüğü'));
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(FilledButton, 'Kaydet');
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), 'Sağlığım');
      await tester.enterText(find.byType(TextField).at(1), 'Ailem');
      await tester.enterText(find.byType(TextField).at(2), 'Güzel bir kahve');
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Form yerine "tamamlandı" kartı görünüyor, coin kazanma mesajı geldi.
      expect(find.text('Bugün tamamlandı!'), findsOneWidget);
      expect(find.text('+2 Zibo Coin kazandın!'), findsOneWidget);

      // Yazılan üç şükran artık kartın kendisinde de GÖRÜNÜYOR (eskiden bir
      // daha hiç görünmüyordu — bkz. CLAUDE.md "Şükran Günlüğü" 2026
      // güncellemesi).
      expect(find.text('Sağlığım'), findsOneWidget);
      expect(find.text('Ailem'), findsOneWidget);
      expect(find.text('Güzel bir kahve'), findsOneWidget);

      // Düzenle ikonuna basıp bir şükranı değiştirmek geçmişteki/bugünkü
      // kaydı GÜNCELLİYOR (yeni bir kayıt oluşturmuyor).
      await tester.tap(find.byTooltip('Düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Sağlığım ve huzurum');
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();
      expect(find.text('Sağlığım ve huzurum'), findsOneWidget);
      expect(find.text('Sağlığım'), findsNothing);

      // Rüya Günlüğü'nün aksine Şükran Günlüğü artık doğrudan Ana Sayfa'dan
      // (Z menüsü üzerinden) push edildiği için tek "Geri" yeter.
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget); // AppBar'daki güncel bakiye
    },
  );

  testWidgets(
    'Günlük Ruh Hali Takibi: emoji seçilince otomatik kaydedilir ve geçmişte görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Günlük Ruh Hali Takibi artık Ayarlar'da değil, Z butonunun açtığı
      // modül menüsünde (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü).
      await _openModulesMenu(tester);
      await tester.tap(find.text('Günlük Ruh Hali Takibi'));
      await tester.pumpAndSettle();

      expect(find.text('Son 7 Gün'), findsOneWidget);
      expect(find.text('Geçmiş'), findsOneWidget);
      expect(find.text('Henüz bir kayıt yok.'), findsOneWidget);

      // Bu noktada listede hiç kayıt yok, o yüzden emoji yalnızca seçim
      // sırasında bir kez geçiyor — dokunmak tekil eşleşir.
      await tester.tap(find.text('🙂'));
      await tester.pumpAndSettle();

      // Kaydedildi: geçmiş listesinde artık bir kayıt var (boş durum metni gitti).
      expect(find.text('Henüz bir kayıt yok.'), findsNothing);
      expect(find.text('İyi'), findsOneWidget); // geçmiş listesindeki etiket
    },
  );

  testWidgets(
    'Su Takibi: 8 bardak işaretlenince hedef tamamlanır ve 2 Zibo Coin kazanılır',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Su Takibi, diğer üç modül gibi Z butonunun açtığı modül menüsünden
      // erişiliyor (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü).
      await _openModulesMenu(tester);
      await tester.tap(find.text('Su Takibi'));
      await tester.pumpAndSettle();

      expect(find.text('0/8 bardak'), findsOneWidget);
      expect(find.text('0 ml / 2000 ml'), findsOneWidget);

      // Varsayılan hedef 8 bardak — her boş bardağa sırayla dokunmak
      // sayacı birer birer arttırır (bkz. WaterProvider.incrementUnit).
      for (var i = 1; i <= 8; i++) {
        await tester.tap(find.bySemanticsLabel('$i. bardak, boş'));
        await tester.pumpAndSettle();
      }

      expect(find.text('8/8 bardak'), findsOneWidget);
      expect(
        find.text('Günlük su hedefini tamamladın! +2 Zibo Coin kazandın!'),
        findsOneWidget,
      );
      expect(find.text('Bugün su hedefini tamamladın, harikasın kanka!'), findsOneWidget);

      // Coin farming koruması: bir bardağı boşaltıp tekrar doldurmak
      // (böylece hedefe İKİNCİ KEZ ulaşmak) yeniden coin vermemeli — bkz.
      // WaterProvider.incrementUnit'teki rewardClaimed mantığı.
      await tester.tap(find.bySemanticsLabel('8. bardak, dolu'));
      await tester.pumpAndSettle();
      expect(find.text('7/8 bardak'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('8. bardak, boş'));
      await tester.pumpAndSettle();
      expect(find.text('8/8 bardak'), findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      // Bakiye yalnızca 2 (tek seferlik ödül) — farm denemesi ikinci kez
      // eklemedi.
      expect(find.text('2'), findsOneWidget); // AppBar'daki güncel bakiye
    },
  );

  testWidgets(
    'Profil: isim yazılıp kaydedilir, kaydedilir ve kalır; istatistik kartları görünür',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Profil artık ÜÇÜNCÜ alt sekme (bkz. CLAUDE.md "Alt Gezinme Çubuğu"
      // — Profil↔Birikim yer değiştirme notu), diğer sekmeler gibi
      // doğrudan `find.bySemanticsLabel(...)` ile erişiliyor, Z butonu
      // modül menüsü üzerinden DEĞİL.
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('İstatistiklerim'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Zibo Dostu');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Başka bir sekmeye geçip geri dönünce isim hâlâ kalıcı depodan
      // yüklenmeli (IndexedStack sekmeyi hiç dispose etmiyor, ama yine de
      // gerçek kalıcılığı — yalnızca bellek durumunu değil — doğrulamak
      // için önce Ana Sayfa'ya geçiliyor).
      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Zibo Dostu'), findsOneWidget);

      // İstikrar kartı — 2026 güncellemesi: GoalsProvider artık ilk
      // kurulumda otomatik bir örnek hedef EKLEMİYOR (kullanıcı isteği),
      // bu yüzden bu testte kart "veri yok" (teşvik mesajlı) durumda
      // görünür; assertion yalnızca kategori BAŞLIĞININ (hasData durumundan
      // BAĞIMSIZ, her zaman görünen) varlığını doğruluyor.
      // `scrollable:` açıkça `ProfileScreen`'in kendi listesine daraltılıyor
      // — aksi halde arkada hâlâ monte duran `RootScreen`'in IndexedStack
      // sekmelerindeki diğer Scrollable'larla "Too many elements" hatası
      // veriyordu. `ProfileScreen` içinde de İKİ Scrollable var (dıştaki
      // `ListView` + isim `TextField`'ının kendi iç `EditableText`
      // kaydırıcısı) — `.first` dıştaki (asıl sayfayı kaydıran) olanı seçer,
      // çünkü ağaçta ATA olan önce gelir.
      await tester.scrollUntilVisible(
        find.text('İstikrar'),
        200,
        scrollable: find
            .descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable))
            .first,
      );
      expect(find.text('İstikrar'), findsOneWidget);
    },
  );

  testWidgets(
    'Profil: "Zibo ile Bağın" satırları — favori söz, hitap tercihi, bağ '
    'seviyesi, en uzun seri, coin özeti ve kostüm dolabı çalışır',
    (WidgetTester tester) async {
      await _pumpPastOnboarding(tester, const DijitalKankaApp());

      // Ana Sayfa'daki kalp ikonuna dokunup ilk sözü favorile.
      final firstQuote = ziboMessagesTr.first;
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsWidgets);

      Finder profileScrollable() => find
          .descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable))
          .first;

      // IndexedStack içindeki iç içe kaydırılabilir listelerde koordinat
      // tabanlı tap() hit-test uyuşmazlığı yaşayabiliyor (bkz. CLAUDE.md
      // "Test kalıpları" — GridView/InkWell notu) — bu yüzden satırlara
      // ListTile/InkWell'in `onTap`'ini doğrudan çağırarak dokunuyoruz.
      void tapRow(String rowTitle) {
        tester
            .widget<ListTile>(
              find.ancestor(of: find.text(rowTitle), matching: find.byType(ListTile)),
            )
            .onTap!();
      }

      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();

      // NOT: `scrollUntilVisible` yalnızca TEK yönde (aşağı) kaydırabiliyor
      // (bkz. flutter_test kaynağı — `delta`nın işareti ile `Scrollable.
      // axisDirection`'a göre sabit bir `moveStep` hesaplanıyor, öncekine geri
      // dönemiyor) — bu yüzden aşağıdaki satırlar "Zibo ile Bağın"
      // bölümündeki GERÇEK sırayla (Bağ Seviyesi → En Uzun Seri → Kostüm
      // Dolabı → Coin Özeti → Hitap Tercihi → Favori Sözler) YUKARIDAN
      // AŞAĞIYA ziyaret ediliyor; sıralama karıştırılırsa (ör. önce alttaki
      // bir satıra gidip SONRA üstteki bir satırı aramak) `dragUntilVisible`
      // 50 deneme boyunca YANLIŞ yöne kaydırıp `Bad state: No element`
      // hatasıyla çöker (gerçekten yaşandı — Google hesap bağlama satırı
      // listenin SONUNA eklenince toplam içerik artık tek ekrana sığmıyor,
      // önceki karışık sıralama bu yüzden kırıldı).

      // Zibo ile Bağ Seviyesi: taze bir kurulumda 0 gün → "Yeni Kanka".
      await tester.scrollUntilVisible(
        find.text('Zibo ile Bağ Seviyesi'),
        200,
        scrollable: profileScrollable(),
      );
      tapRow('Zibo ile Bağ Seviyesi');
      await tester.pumpAndSettle();
      expect(find.text('Yeni Kanka'), findsOneWidget);
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // En Uzun Seri Rekoru sayfası açılır.
      await tester.scrollUntilVisible(
        find.text('En Uzun Seri Rekoru'),
        200,
        scrollable: profileScrollable(),
      );
      tapRow('En Uzun Seri Rekoru');
      await tester.pumpAndSettle();
      expect(find.text("Hedef Takibi'ndeki en uzun kesintisiz serin"), findsOneWidget);
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // Kostüm Dolabı: hiç kostüm sahiplenilmemişken teşvik mesajı gösterir,
      // dokununca Mağaza'nın Kostümler segmentine gider (kullanıcının
      // istediği istisna davranış — yeni sayfa AÇMAK yerine önizleme).
      await tester.scrollUntilVisible(
        find.text('Henüz bir kostümün yok — Mağaza\'dan birini seç!'),
        200,
        scrollable: profileScrollable(),
      );
      tester
          .widget<InkWell>(
            find.ancestor(
              of: find.text('Kostüm Dolabı'),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Hippi Zibo'), findsOneWidget);
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // Zibo Coin Özeti: taze bir kurulumda ikisi de 0 ZC.
      await tester.scrollUntilVisible(
        find.text('Zibo Coin Özeti'),
        200,
        scrollable: profileScrollable(),
      );
      tapRow('Zibo Coin Özeti');
      await tester.pumpAndSettle();
      expect(find.text('0 ZC'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      // Hitap Tercihi: serbest metin kutusuna "Reis" yazılınca satırın alt
      // metni anında güncellenir (bkz. 2026 güncellemesi — hazır seçenekler
      // yerine serbest metin kutusu).
      await tester.scrollUntilVisible(
        find.text('Hitap Tercihi'),
        200,
        scrollable: profileScrollable(),
      );
      tapRow('Hitap Tercihi');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Reis');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.text('Zibo sana "Reis" diyor'), findsOneWidget);

      // Favori Sözler satırı canlı sayacı gösterir; dokununca söz listede
      // görünür.
      await tester.scrollUntilVisible(
        find.text('1 favori söz'),
        200,
        scrollable: profileScrollable(),
      );
      tapRow('Favori Sözler');
      await tester.pumpAndSettle();
      expect(find.text(firstQuote), findsOneWidget);
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
    },
  );
}
