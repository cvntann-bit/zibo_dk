// Kostüm nadirliği (rarity): veri bütünlüğü, merkezi renk tanımı, yazı kontrastı ve
// kartın satın alma durumu davranışı (bkz. data/rarity_colors.dart, widgets/costume_card.dart).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/costume_poses.dart';
import 'package:dijital_kanka/data/costumes.dart';
import 'package:dijital_kanka/data/rarity_colors.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/costume.dart';
import 'package:dijital_kanka/models/costume_rarity.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/widgets/costume_card.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('kostüm ID\'leri benzersiz; her nadirlik kademesinde en az bir kostüm var', () {
    final ids = costumes.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final r in CostumeRarity.values) {
      expect(costumes.where((c) => c.rarity == r), isNotEmpty, reason: '$r boş');
    }
  });

  test('liste fiyata göre ucuzdan pahalıya sıralı (Instagram ödülü "ucuz üçte bir" varsayımı)', () {
    for (var i = 1; i < costumes.length; i++) {
      expect(costumes[i].price >= costumes[i - 1].price, isTrue,
          reason: '${costumes[i].id} (${costumes[i].price}) < ${costumes[i - 1].id}');
    }
  });

  test('her kostümün kapak görseli ve poz dosyaları diskte var ve .jpg/.png DEĞİL', () {
    for (final c in costumes) {
      expect(c.imageAsset.endsWith('.webp'), isTrue, reason: c.imageAsset);
      expect(File(c.imageAsset).existsSync(), isTrue, reason: 'eksik: ${c.imageAsset}');
      for (final pose in costumePoses[c.id] ?? const <String>[]) {
        expect(pose.endsWith('.webp'), isTrue, reason: pose);
        expect(File(pose).existsSync(), isTrue, reason: 'eksik poz: $pose');
      }
    }
  });

  test('çerçeve renkleri kullanıcının belirlediği değerler; yalnızca Mitik parlar', () {
    expect(RarityStyle.of(CostumeRarity.common).color, const Color(0xFF9E9E9E));
    expect(RarityStyle.of(CostumeRarity.rare).color, const Color(0xFF2196F3));
    expect(RarityStyle.of(CostumeRarity.epic).color, const Color(0xFF9C27B0));
    expect(RarityStyle.of(CostumeRarity.legendary).color, const Color(0xFFFFC107));
    expect(RarityStyle.of(CostumeRarity.mythic).color, const Color(0xFFFF6A00));
    for (final r in CostumeRarity.values) {
      expect(RarityStyle.of(r).glowShadows.isNotEmpty, r == CostumeRarity.mythic);
    }
  });

  test('nadirlik metin rengi açık (krem) ve koyu zeminde okunur (kontrast ≥ 3), etiket üstü yazı ≥ 4.5', () {
    const lightBg = Color(0xFFFFFDF7), darkBg = Color(0xFF1C1B1F);
    for (final r in CostumeRarity.values) {
      final s = RarityStyle.of(r);
      expect(_contrast(s.labelColor(Brightness.light), lightBg), greaterThanOrEqualTo(3.0), reason: '$r açık');
      expect(_contrast(s.labelColor(Brightness.dark), darkBg), greaterThanOrEqualTo(3.0), reason: '$r koyu');
      expect(_contrast(s.onColor, s.color), greaterThanOrEqualTo(4.5), reason: '$r etiket üstü yazı');
    }
  });

  Future<void> pumpCard(WidgetTester tester, Costume costume) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CostumeProvider()),
          ChangeNotifierProvider(create: (_) => CoinProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(body: SizedBox(width: 170, height: 260, child: CostumeCard(costume: costume))),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('satılabilir kostümde nadirlik etiketi, fiyat ve "Satın Al" görünür', (tester) async {
    await pumpCard(tester, costumes.firstWhere((c) => c.id == 'zibo_king'));
    expect(find.text('Efsanevi'), findsOneWidget);
    expect(find.text('Satın Al'), findsOneWidget);
  });

  testWidgets('rozet/Pro/sınırlı süre kostümünde fiyat ve "Satın Al" ÇIKMAZ, etiket çıkar', (tester) async {
    const labels = {
      CostumeAcquisition.badge: 'Rozetle kazan',
      CostumeAcquisition.pro: 'Pro',
      CostumeAcquisition.limited: 'Sınırlı süre',
    };
    for (final e in labels.entries) {
      await pumpCard(
        tester,
        Costume(
          id: 'test_${e.key.name}',
          imageAsset: 'assets/images/zibo_king.webp',
          name: 'Test',
          price: 999,
          rarity: CostumeRarity.mythic,
          acquisition: e.key,
        ),
      );
      expect(find.text('Satın Al'), findsNothing, reason: '${e.key}');
      expect(find.text(e.value), findsOneWidget, reason: '${e.key}');
      expect(find.text('Mitik'), findsOneWidget);
    }
  });

  testWidgets('kart dış çerçevesi nadirlik renginde', (tester) async {
    for (final r in CostumeRarity.values) {
      await pumpCard(
        tester,
        Costume(
          id: 'test_${r.name}',
          imageAsset: 'assets/images/zibo_king.webp',
          name: 'Test',
          price: 999,
          rarity: r,
        ),
      );
      final framed = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final d = c.decoration;
            return d is BoxDecoration && d.border is Border && (d.border! as Border).top.color == RarityStyle.of(r).color;
          });
      expect(framed, isNotEmpty, reason: '$r çerçeve rengi bulunamadı');
    }
  });
}
