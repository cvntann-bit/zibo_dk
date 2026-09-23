import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/paywall_quotes.dart';

void main() {
  const tr = Locale('tr');
  const en = Locale('en');
  const es = Locale('es');

  test('Üç havuz da (TR/EN/ES) BİREBİR aynı uzunlukta (index-tabanlı seçim güvenli)', () {
    expect(paywallQuotesEn.length, paywallQuotesTr.length);
    expect(paywallQuotesEs.length, paywallQuotesTr.length);
  });

  test('Her havuzda tekrar yok', () {
    for (final pool in [paywallQuotesTr, paywallQuotesEn, paywallQuotesEs]) {
      expect(pool.toSet().length, pool.length);
    }
  });

  test('paywallQuotesForLocale doğru havuzu döner', () {
    expect(paywallQuotesForLocale(tr), paywallQuotesTr);
    expect(paywallQuotesForLocale(en), paywallQuotesEn);
    expect(paywallQuotesForLocale(es), paywallQuotesEs);
  });

  test('Bilinmeyen bir dil için Türkçe\'ye düşer', () {
    expect(paywallQuotesForLocale(const Locale('fr')), paywallQuotesTr);
  });
}
