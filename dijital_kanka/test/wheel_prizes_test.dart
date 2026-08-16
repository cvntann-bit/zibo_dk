// wheel_prizes.dart'taki ağırlıklı veriyi ve pickWeightedPrize'ın gerçekten
// ağırlıklara göre orantılı dağılım ürettiğini doğrudan (widget pump'lamadan)
// test eder.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/wheel_prizes.dart';
import 'package:dijital_kanka/models/wheel_prize.dart';

void main() {
  test('8 dilim var, her biri gereksinimdeki ZC miktarlarından biri', () {
    expect(wheelPrizes.length, 8);
    expect(
      wheelPrizes.map((p) => p.amount).toList(),
      [2, 5, 10, 20, 50, 100, 150, 250],
    );
  });

  test('En büyük ödül (250 ZC) en düşük ağırlıklı olandır', () {
    final maxAmountPrize = wheelPrizes.reduce(
      (a, b) => a.amount > b.amount ? a : b,
    );
    final minWeight = wheelPrizes.map((p) => p.weight).reduce(min);

    expect(maxAmountPrize.amount, 250);
    expect(maxAmountPrize.weight, minWeight);
  });

  test('Küçük ödüller (2/5/10 ZC) toplamda büyük ödüllerden çok daha olası', () {
    double weightOf(int amount) =>
        wheelPrizes.firstWhere((p) => p.amount == amount).weight;

    final smallTotal = weightOf(2) + weightOf(5) + weightOf(10);
    final bigTotal = weightOf(50) + weightOf(100) + weightOf(150) + weightOf(250);

    expect(smallTotal, greaterThan(bigTotal * 5));
  });

  test('pickWeightedPrize her zaman listeden bir ödül döner', () {
    final random = Random(7);
    for (var i = 0; i < 200; i++) {
      final prize = pickWeightedPrize(wheelPrizes, random);
      expect(wheelPrizes, contains(prize));
    }
  });

  test('pickWeightedPrize düşük roll değerinde ilk ödülü seçer', () {
    final prize = pickWeightedPrize(wheelPrizes, _FixedRandom(0));
    expect(prize.amount, wheelPrizes.first.amount);
  });

  test('pickWeightedPrize roll neredeyse toplam ağırlığa eşitken son ödülü seçer', () {
    final prize = pickWeightedPrize(wheelPrizes, _FixedRandom(0.9999));
    expect(prize.amount, wheelPrizes.last.amount);
  });

  test(
    'Büyük örneklemde dağılım ağırlıklarla orantılı (istatistiksel, toleranslı)',
    () {
      const trials = 20000;
      final random = Random(12345);
      final counts = <int, int>{for (final p in wheelPrizes) p.amount: 0};

      for (var i = 0; i < trials; i++) {
        final prize = pickWeightedPrize(wheelPrizes, random);
        counts[prize.amount] = counts[prize.amount]! + 1;
      }

      final totalWeight = wheelPrizes.fold<double>(0, (s, p) => s + p.weight);
      for (final prize in wheelPrizes) {
        final expectedShare = prize.weight / totalWeight;
        final actualShare = counts[prize.amount]! / trials;
        // Geniş bir tolerans (±3 puan) — bu istatistiksel bir test, amaç
        // ağırlıkların yönünü/oranını doğrulamak, tam eşitlik değil.
        expect(
          actualShare,
          closeTo(expectedShare, 0.03),
          reason: '${prize.amount} ZC için beklenen ~$expectedShare, '
              'gerçekleşen $actualShare',
        );
      }
    },
  );
}

/// Testte `nextDouble()`'ın hep aynı sabit değeri döndürmesi için.
class _FixedRandom implements Random {
  const _FixedRandom(this._value);
  final double _value;

  @override
  double nextDouble() => _value;

  @override
  int nextInt(int max) => (max * _value).floor();

  @override
  bool nextBool() => _value >= 0.5;
}
