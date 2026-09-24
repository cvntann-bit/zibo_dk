// Manifest süsleme editörü: sticker ekleme/silme, filigran, premium çerçeve
// kilidi (Zibo Coin ile açma), kostüm sticker kilidi ve dışa aktarım.
// Paylaşım/galeri platform kanallarına dokunulmuyor — sahte servisler.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/manifest_frames.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/manifest_entry.dart';
import 'package:dijital_kanka/models/subscription_tier.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/manifest_decor_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/screens/manifest_editor_screen.dart';
import 'package:dijital_kanka/services/photo_picker_service.dart';
import 'package:dijital_kanka/services/share_service.dart';
import 'package:dijital_kanka/widgets/manifest_frame_view.dart';

class _FakeShareService extends ShareService {
  final shared = <Uint8List>[];

  @override
  Future<void> shareImageBytes(Uint8List bytes, {required String fileName, String? text}) async {
    shared.add(bytes);
  }

  @override
  Future<void> shareText(String text) async {}
}

class _FakePhotoService extends PhotoPickerService {
  int pickCalls = 0;

  @override
  Future<String?> pickFromGallery() async {
    pickCalls++;
    return null;
  }

  @override
  Future<String> saveToPermanentStorage(String sourcePath) async => sourcePath;

  @override
  Future<void> deletePhoto(String path) async {}
}

ManifestEntry _textEntry(String id, String text) =>
    ManifestEntry(id: id, date: DateTime(2026, 9, 20), photoPath: null, intentionText: text);

class _Harness {
  final coins = CoinProvider();
  final decor = ManifestDecorProvider();
  final subscription = SubscriptionProvider();
  final share = _FakeShareService();
  final photos = _FakePhotoService();

  Widget build({List<ManifestEntry>? collage}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: coins),
        ChangeNotifierProvider.value(value: decor),
        ChangeNotifierProvider.value(value: subscription),
        ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: collage != null
            ? ManifestEditorScreen.collage(
                collageEntries: collage,
                shareService: share,
                gallerySaver: (bytes, name) async => true,
                photoService: photos,
              )
            : ManifestEditorScreen(
                entry: ManifestEntry(
                  id: '1',
                  date: DateTime(2026, 9, 24),
                  photoPath: null,
                  intentionText: 'Hayalimdeki ev',
                ),
                shareService: share,
                gallerySaver: (bytes, name) async => true,
                photoService: photos,
              ),
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher as TestPlatformDispatcher;
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

  testWidgets('açılır, fotoğrafsız kayıtta niyet yazısı tuvalde, ücretsiz kullanıcıda filigran var, taşma yok',
      (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.text('Manifestini Süsle'), findsOneWidget);
    expect(find.text('Hayalimdeki ev'), findsOneWidget);
    expect(find.byKey(const Key('manifestEditorWatermark')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pro kullanıcıda filigran yok', (tester) async {
    final h = _Harness();
    await h.subscription.debugSetTier(SubscriptionTier.pro);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manifestEditorWatermark')), findsNothing);
  });

  testWidgets('Zibo sticker\'ı eklenir, seçiliyken ✕ ile silinir', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manifestEditorTab_sticker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('manifestSticker_${freeZiboStickerAssets.first}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manifestStickerDelete')), findsOneWidget);
    expect(find.image(AssetImage(freeZiboStickerAssets.first)), findsNWidgets(2)); // tepsi + tuval

    await tester.tap(find.byKey(const Key('manifestStickerDelete')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manifestStickerDelete')), findsNothing);
    expect(find.image(AssetImage(freeZiboStickerAssets.first)), findsOneWidget); // yalnız tepsi
  });

  testWidgets('hazır olumlama yazısı tuvale eklenir', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manifestEditorTab_text')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oluyor ✨'));
    await tester.pumpAndSettle();

    // Kontur + dolgu için iki Text katmanı + tepsideki chip.
    expect(find.text('Oluyor ✨'), findsNWidgets(3));
  });

  testWidgets('premium çerçeve: coin yetersizse açılmaz, paylaşım penceresi açılmaz', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _scrollTrayTo(tester, const Key('manifestFrame_gold'));
    await tester.tap(find.byKey(const Key('manifestFrame_gold')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('manifestFrameLockedPill')), findsOneWidget);

    await tester.tap(find.byKey(const Key('manifestEditorShareButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manifestFrameUnlockConfirm')));
    await tester.pumpAndSettle();

    expect(h.decor.isFrameUnlocked(ManifestFrame.gold), isFalse);
    expect(find.byKey(const Key('manifestExportShare')), findsNothing);
  });

  testWidgets('premium çerçeve 250 ZC ile açılır, kilit kalkar', (tester) async {
    final h = _Harness();
    h.coins.earnBadgeReward(300, 'test');
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await _scrollTrayTo(tester, const Key('manifestFrame_gold'));
    await tester.tap(find.byKey(const Key('manifestFrame_gold')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manifestFrameLockedPill')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manifestFrameUnlockConfirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('infoDialogOkButton')));
    await tester.pumpAndSettle();

    expect(h.decor.isFrameUnlocked(ManifestFrame.gold), isTrue);
    expect(h.coins.balance, 50);
    expect(find.byKey(const Key('manifestFrameLockedPill')), findsNothing);
  });

  testWidgets('sahip olunmayan kostümün sticker\'ı eklenmez, açıklama çıkar', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manifestEditorTab_sticker')));
    await tester.pumpAndSettle();
    final locked = find.byKey(const Key('manifestSticker_zibo_hippi'));
    await tester.dragUntilVisible(locked, find.byType(ListView).last, const Offset(-250, 0));
    await tester.pumpAndSettle();
    await tester.tap(locked);
    await tester.pumpAndSettle();

    expect(find.textContaining('kostümüne sahip olunca'), findsOneWidget);
    expect(find.byKey(const Key('manifestStickerDelete')), findsNothing);
  });

  testWidgets('Paylaş → pencere → Paylaş: PNG üretilip paylaşım servisine gider', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manifestEditorShareButton')));
    await tester.pumpAndSettle();
    expect(find.text('Manifestin hazır! 🎉'), findsOneWidget);
    expect(find.textContaining('zibo'), findsWidgets);

    await tester.tap(find.byKey(const Key('manifestExportShare')));
    // `toImage()` gerçek raster işi — fake-async dışında bekle (test/CLAUDE.md).
    for (var i = 0; i < 20 && h.share.shared.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }

    expect(h.share.shared, hasLength(1));
    expect(h.share.shared.single.sublist(1, 4), [0x50, 0x4E, 0x47]); // "PNG"
  });

  testWidgets('16 çerçevenin hepsi tepsi boyutunda ve 4:5/9:16 tuvalde hatasız çizilir', (tester) async {
    expect(ManifestFrame.values, hasLength(16));
    for (final size in const [Size(44, 44), Size(320, 400), Size(230, 409)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final frame in ManifestFrame.values)
                    SizedBox.fromSize(
                      size: size,
                      child: ManifestFrameView(
                        frame: frame,
                        width: size.width,
                        caption: '24 Eylül 2026 · Hayalimdeki ev',
                        photo: const ColoredBox(color: Color(0xFF7FB6C9)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'boyut: $size');
    }
  });

  testWidgets('yeni ücretli çerçeveler kilitli, ücretsizler açık başlar', (tester) async {
    final decor = ManifestDecorProvider();
    for (final frame in [ManifestFrame.hearts, ManifestFrame.notebook, ManifestFrame.album, ManifestFrame.pop, ManifestFrame.stamp]) {
      expect(decor.isFrameUnlocked(frame), isTrue, reason: frame.id);
    }
    for (final frame in [ManifestFrame.neon, ManifestFrame.floral, ManifestFrame.night, ManifestFrame.royal, ManifestFrame.zibo]) {
      expect(decor.isFrameUnlocked(frame), isFalse, reason: frame.id);
      expect(frame.price, inInclusiveRange(250, 400));
    }
  });

  testWidgets('gruplu emoji tepsisinden sticker eklenir', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manifestEditorTab_sticker')));
    await tester.pumpAndSettle();
    final rocket = find.byKey(const Key('manifestEmoji_🚀'));
    await tester.dragUntilVisible(rocket, find.byType(ListView).last, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Hedef & başarı'), findsOneWidget);
    await tester.tap(rocket);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manifestStickerDelete')), findsOneWidget);
    expect(find.text('🚀'), findsNWidgets(2)); // tepsi + tuval
  });

  group('Kolaj modu', () {
    testWidgets('açılışta kutular manifestlerden otomatik dolar, çerçeve sekmesi yok, taşma yok',
        (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build(collage: [_textEntry('1', 'Deniz kenarı ev'), _textEntry('2', 'Kendi işim')]));
      await tester.pumpAndSettle();

      expect(find.text('Kolaj Yap'), findsOneWidget);
      expect(find.text('Deniz kenarı ev'), findsOneWidget);
      expect(find.text('Kendi işim'), findsOneWidget);
      expect(find.byKey(const Key('manifestEditorTab_frame')), findsNothing);
      expect(find.byKey(const Key('manifestEditorTab_template')), findsOneWidget);
      // Varsayılan 3'lü şablon: 3 kutu.
      expect(find.byKey(const Key('manifestCollageTile_2')), findsOneWidget);
      expect(find.byKey(const Key('manifestCollageTile_3')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('şablon değişince kutu sayısı değişir, içerik korunur', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build(collage: [_textEntry('1', 'Deniz kenarı ev')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manifestTemplate_six')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manifestCollageTile_5')), findsOneWidget);
      expect(find.text('Deniz kenarı ev'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('boş kutuya dokununca seçici açılır, seçilen manifest kutuya yerleşir', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build(collage: [_textEntry('1', 'Deniz kenarı ev'), _textEntry('2', 'Kendi işim')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manifestCollageTile_2')));
      await tester.pumpAndSettle();
      expect(find.text('Bu kutuya fotoğraf seç'), findsOneWidget);
      expect(find.byKey(const Key('manifestCollageFromGallery')), findsOneWidget);

      await tester.tap(find.byKey(const Key('manifestCollagePick_1')));
      await tester.pumpAndSettle();

      expect(find.text('Bu kutuya fotoğraf seç'), findsNothing);
      expect(find.text('Deniz kenarı ev'), findsNWidgets(2));
    });

    testWidgets('galeri seçeneği fotoğraf seçici servisini çağırır, iptalde kutu boş kalır', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build(collage: [_textEntry('1', 'Deniz kenarı ev')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manifestCollageTile_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manifestCollageFromGallery')));
      await tester.pumpAndSettle();

      expect(h.photos.pickCalls, 1);
      expect(find.text('Dokun, fotoğraf seç'), findsWidgets);
    });

    testWidgets('kolajda paylaşım çerçeve kilidi sormadan PNG üretir', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.build(collage: [_textEntry('1', 'Deniz kenarı ev')]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manifestEditorShareButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manifestExportShare')));
      for (var i = 0; i < 20 && h.share.shared.isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }

      expect(h.share.shared, hasLength(1));
    });
  });
}

/// Tepsi yatay ve tembel (lazy) — sağda kalan öğeye dokunmadan önce kaydır.
Future<void> _scrollTrayTo(WidgetTester tester, Key key) async {
  await tester.dragUntilVisible(find.byKey(key), find.byType(ListView).last, const Offset(-200, 0));
  await tester.pumpAndSettle();
}
