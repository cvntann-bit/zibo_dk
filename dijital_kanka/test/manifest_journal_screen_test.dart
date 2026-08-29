// Manifest Günlüğü akışını test eder: fotoğraf seç + niyet yaz + kaydet ->
// giriş anında geçmiş listesine eklenir, form BOŞ ve AÇIK kalır (kullanıcı
// hemen yeni bir giriş daha ekleyebilir), coin ödülü YALNIZCA o günün ilk
// tamamlanan girişinde verilir, aynı gün içindeki sonraki girişler coin'i
// tekrar tetiklemez ama yine de ayrı birer kayıt olarak eklenir. Gerçek
// image_picker/path_provider platform kanallarına hiç dokunulmaz — bkz.
// zibo_share_sheet_test.dart'taki aynı "enjekte edilebilir servis" deseni.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/manifest_journal_screen.dart';
import 'package:dijital_kanka/services/photo_picker_service.dart';

class _FakePhotoService extends PhotoPickerService {
  _FakePhotoService();

  String? nextPickedPath = '/fake/tmp/photo1.jpg';
  int pickCount = 0;
  int saveCount = 0;
  final List<String> deletedPaths = [];

  @override
  Future<String?> pickFromGallery() async {
    pickCount++;
    return nextPickedPath;
  }

  @override
  Future<String> saveToPermanentStorage(String sourcePath) async {
    saveCount++;
    return '/fake/permanent/photo_$saveCount.jpg';
  }

  @override
  Future<void> deletePhoto(String path) async {
    deletedPaths.add(path);
  }
}

Widget _buildTestApp(
  PhotoPickerService photoService, {
  DateTime Function()? now,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CoinProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => ManifestProvider(now: now)),
      ChangeNotifierProvider(create: (_) => ProfileProvider(now: now)),
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
      home: ManifestJournalScreen(photoService: photoService),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Varsayılan test görüntü alanı (800x600, geniş-kısa "masaüstü" oranı)
    // gerçek bir telefon ekranını hiç yansıtmıyor — fotoğraf seçici alanın
    // `AspectRatio(1)` ile genişliğe eşit yükseklik alması bu geniş/kısa
    // viewport'ta hit-test'in ulaşamayacağı kadar aşağı taşırıyordu (bkz.
    // widget_test.dart'taki aynı gotcha ve CLAUDE.md test notları). Telefona
    // yakın (dar/uzun) bir viewport bunu gerçek cihaz davranışına yaklaştırır.
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
    'Fotoğraf seçilip niyet yazılınca kaydedilir, 5 Zibo Coin kazanılır ve '
    'form boş/açık kalır',
    (tester) async {
      final fakeService = _FakePhotoService();
      await tester.pumpWidget(_buildTestApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Bir fotoğraf seç'), findsOneWidget);
      // Fotoğraf seçilmeden Kaydet pasif. `skipOffstage: false` GEREKİYOR —
      // SpeechBubble'ın minimum boyutu (bkz. speech_bubble.dart, köşe
      // butonlarının kısa sözlerde metinle iç içe girmesini önleyen 2026
      // düzeltmesi) sayfayı bu gerçekçi telefon viewport'unda "Kaydet"
      // butonu ListView'ın lazy-realize penceresinin biraz dışında kalacak
      // kadar uzatıyor — `find.byType`'ın varsayılan `skipOffstage: true`'su
      // bu yüzden onu "yok" sayıyordu. `onPressed`'i yalnızca OKUYUP/DOĞRUDAN
      // çağırdığımız (gerçek bir `tester.tap()` hit-test'i GEREKMEDİĞİ) için
      // görünürlüğü önemsemeden `skipOffstage: false` ile bulmak yeterli —
      // ayrıca kaydırmaya gerek yok.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('manifestPhotoPickerArea')));
      await tester.pumpAndSettle();
      expect(fakeService.pickCount, 1);

      await tester.enterText(
        find.byType(TextField),
        'Bol bereket ve huzur diliyorum.',
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed,
        isNotNull,
      );
      tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed!();
      await tester.pumpAndSettle();

      expect(fakeService.saveCount, 1);
      expect(find.text('+5 Zibo Coin kazandın!'), findsOneWidget);

      final coinProvider = Provider.of<CoinProvider>(
        tester.element(find.byType(ManifestJournalScreen)),
        listen: false,
      );
      expect(coinProvider.balance, 5);

      // Form BOŞ ve AÇIK kaldı — kullanıcı hemen yeni bir giriş ekleyebilir
      // (fotoğraf seçme ipucu geri döndü, TextField'ın kendi metni find.text
      // ile eşleşmez — bu yüzden aşağıdaki tek eşleşme yalnızca geçmiş
      // kartından gelir).
      expect(find.text('Bir fotoğraf seç'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed,
        isNull,
      );

      // Kaydedilen giriş geçmiş listesine ANINDA eklendi — büyütülmüş Zibo
      // görseli (bkz. CLAUDE.md "Zibo Poz/Animasyon Sistemi") sayfayı
      // uzattığı için galeri kartı artık gerçekçi viewport'ta İLK ekranda
      // görünmüyor; `GridView.builder` (shrinkWrap'e rağmen HÂLÂ lazy inşa
      // ediyor) bu yüzden `scrollUntilVisible` gerekiyor.
      await tester.scrollUntilVisible(
        find.text('Bol bereket ve huzur diliyorum.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );

  testWidgets(
    'Aynı gün ikinci bir giriş eklemek İLKİNİN üzerine yazmaz, coin tekrar '
    'vermez ve her iki giriş de geçmişte ayrı ayrı görünür',
    (tester) async {
      final fakeService = _FakePhotoService();
      await tester.pumpWidget(_buildTestApp(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manifestPhotoPickerArea')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'İlk niyetim');
      await tester.pumpAndSettle();
      tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed!();
      await tester.pumpAndSettle();

      final coinProvider = Provider.of<CoinProvider>(
        tester.element(find.byType(ManifestJournalScreen)),
        listen: false,
      );
      expect(coinProvider.balance, 5);
      expect(fakeService.saveCount, 1);

      // Form boş — yeni bir fotoğraf seç ve ikinci bir giriş ekle.
      fakeService.nextPickedPath = '/fake/tmp/photo2.jpg';
      await tester.tap(find.byKey(const Key('manifestPhotoPickerArea')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'İkinci niyetim');
      await tester.pumpAndSettle();
      tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false)).onPressed!();
      await tester.pumpAndSettle();

      expect(fakeService.saveCount, 2);
      // Coin bakiyesi DEĞİŞMEDİ — ikinci giriş coin tekrar tetiklemedi.
      expect(coinProvider.balance, 5);
      expect(find.text('Bugünün girişi kaydedildi.'), findsOneWidget);
      // Hiçbir fotoğraf silinmedi — ikinci giriş birincinin ÜZERİNE YAZMADI.
      expect(fakeService.deletedPaths, isEmpty);

      // İki giriş de geçmiş listesinde ayrı ayrı görünüyor (bkz. yukarıdaki
      // scrollUntilVisible notu — büyütülmüş Zibo görseli galeriyi ilk
      // ekranın altına itiyor).
      await tester.scrollUntilVisible(
        find.text('İlk niyetim'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('İkinci niyetim'), findsOneWidget);
    },
  );

  testWidgets(
    'Bugün için zaten bir kayıt olsa bile ekran açılışında form BOŞ olur, '
    'mevcut kayıt geçmişte görünür',
    (tester) async {
      final currentDate = DateTime(2026, 1, 5);
      // Ekran hiç açılmadan ÖNCE bugüne ait bir kayıt olsun (ör. kullanıcı
      // sayfayı kapatıp aynı gün tekrar açtı) — provider'a doğrudan
      // yazılıyor, gereksiz bir "yeniden mount" karmaşıklığından kaçınmak
      // için.
      final manifestProvider = ManifestProvider(now: () => currentDate)
        ..addEntry(
          photoPath: '/fake/permanent/existing.jpg',
          intentionText: 'Bugünkü niyetim',
        );
      final fakeService = _FakePhotoService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CoinProvider()),
            ChangeNotifierProvider(create: (_) => CostumeProvider()),
            ChangeNotifierProvider.value(value: manifestProvider),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
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
            home: ManifestJournalScreen(photoService: fakeService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form boş açıldı (prefill YOK) — fotoğraf seçme ipucu hâlâ görünür.
      expect(find.text('Bir fotoğraf seç'), findsOneWidget);
      // Ama mevcut kayıt geçmiş listesinde görünüyor (bkz. yukarıdaki
      // scrollUntilVisible notu).
      await tester.scrollUntilVisible(
        find.text('Bugünkü niyetim'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    },
  );
}
