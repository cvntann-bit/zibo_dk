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
import 'package:dijital_kanka/services/share_service.dart';

class _FakeShareService extends ShareService {
  final shared = <Uint8List>[];

  @override
  Future<void> shareImageBytes(Uint8List bytes, {required String fileName, String? text}) async {
    shared.add(bytes);
  }

  @override
  Future<void> shareText(String text) async {}
}

class _Harness {
  final coins = CoinProvider();
  final decor = ManifestDecorProvider();
  final subscription = SubscriptionProvider();
  final share = _FakeShareService();

  Widget build() {
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
        home: ManifestEditorScreen(
          entry: ManifestEntry(
            id: '1',
            date: DateTime(2026, 9, 24),
            photoPath: null,
            intentionText: 'Hayalimdeki ev',
          ),
          shareService: share,
          gallerySaver: (bytes, name) async => true,
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
}
