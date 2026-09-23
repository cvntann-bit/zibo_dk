import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/paywall_comparison.dart';

void main() {
  const tr = Locale('tr');
  const en = Locale('en');
  const es = Locale('es');

  test('Üç havuz da (TR/EN/ES) BİREBİR aynı sayıda satır içerir', () {
    expect(paywallComparisonRowsEn.length, paywallComparisonRowsTr.length);
    expect(paywallComparisonRowsEs.length, paywallComparisonRowsTr.length);
  });

  test('Her dildeki satır etiketleri tekrarsız', () {
    for (final pool in [
      paywallComparisonRowsTr,
      paywallComparisonRowsEn,
      paywallComparisonRowsEs,
    ]) {
      final labels = pool.map((row) => row.label).toSet();
      expect(labels.length, pool.length);
    }
  });

  test('paywallComparisonRowsForLocale doğru havuzu döner', () {
    expect(paywallComparisonRowsForLocale(tr), paywallComparisonRowsTr);
    expect(paywallComparisonRowsForLocale(en), paywallComparisonRowsEn);
    expect(paywallComparisonRowsForLocale(es), paywallComparisonRowsEs);
  });

  test('Bilinmeyen bir dil için Türkçe\'ye düşer', () {
    expect(paywallComparisonRowsForLocale(const Locale('fr')), paywallComparisonRowsTr);
  });

  test('Her satırda free/pro/proPlus değerleri boş değil', () {
    for (final pool in [
      paywallComparisonRowsTr,
      paywallComparisonRowsEn,
      paywallComparisonRowsEs,
    ]) {
      for (final row in pool) {
        expect(row.free, isNotEmpty);
        expect(row.pro, isNotEmpty);
        expect(row.proPlus, isNotEmpty);
      }
    }
  });
}
