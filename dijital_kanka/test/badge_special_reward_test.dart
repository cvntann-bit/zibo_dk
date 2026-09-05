// pickRandomUnownedLowPricedCostume'un (Instagram Takip Ödülü'nün kostüm
// hediyesi, bkz. CLAUDE.md "Instagram Takip Kartı ve Ödülü" bölümü) saf/
// deterministik davranışını doğrudan test eder.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/costumes.dart';
import 'package:dijital_kanka/utils/badge_special_reward.dart';

void main() {
  test('Sahip olunmayan bir düşük fiyatlı kostüm rastgele döner', () {
    final costume = pickRandomUnownedLowPricedCostume(
      {},
      random: Random(1),
    );
    expect(costume, isNotNull);
    // Ucuzdan pahalıya sıralı listenin İLK ÜÇTE BİRİNDEN olmalı.
    final cutoff = (costumes.length / 3).ceil();
    final lowPricedIds = costumes.take(cutoff).map((c) => c.id).toSet();
    expect(lowPricedIds, contains(costume!.id));
  });

  test('Zaten sahip olunan düşük fiyatlı kostümler ADAY LİSTESİNDEN çıkar', () {
    final cutoff = (costumes.length / 3).ceil();
    final lowPriced = costumes.take(cutoff).toList();
    // Hepsi hariç bir tanesi sahiplenilmiş olsun.
    final ownedIds = lowPriced.skip(1).map((c) => c.id).toSet();

    final costume = pickRandomUnownedLowPricedCostume(
      ownedIds,
      random: Random(2),
    );

    expect(costume?.id, lowPriced.first.id);
  });

  test('Düşük fiyatlı kostümlerin HEPSİNE sahip olununca null döner', () {
    final cutoff = (costumes.length / 3).ceil();
    final ownedIds = costumes.take(cutoff).map((c) => c.id).toSet();

    final costume = pickRandomUnownedLowPricedCostume(ownedIds);

    expect(costume, isNull);
  });

  test('Pahalı (üst üçte iki) kostümler ASLA seçilmez', () {
    final cutoff = (costumes.length / 3).ceil();
    final expensiveIds = costumes.skip(cutoff).map((c) => c.id).toSet();

    for (var seed = 0; seed < 10; seed++) {
      final costume = pickRandomUnownedLowPricedCostume(
        {},
        random: Random(seed),
      );
      expect(expensiveIds, isNot(contains(costume?.id)));
    }
  });
}
