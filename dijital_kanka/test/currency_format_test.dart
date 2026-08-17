import 'package:dijital_kanka/utils/currency_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCurrencyAmount', () {
    test('TRY: iki basamaklı tam sayı kısmı', () {
      expect(formatCurrencyAmount(19.99, 'TRY'), '19,99 ₺');
      expect(formatCurrencyAmount(44.99, 'TRY'), '44,99 ₺');
      expect(formatCurrencyAmount(84.99, 'TRY'), '84,99 ₺');
    });

    test('TRY: üç basamaklı tam sayı kısmı', () {
      expect(formatCurrencyAmount(159.99, 'TRY'), '159,99 ₺');
    });

    test('TRY: binlik ayracı doğru yerleştirilir', () {
      expect(formatCurrencyAmount(1499.99, 'TRY'), '1.499,99 ₺');
    });

    test('bilinmeyen para birimi kodu için genel geri düşüş', () {
      expect(formatCurrencyAmount(9.99, 'USD'), '9,99 USD');
    });

    // 2026 güncellemesi — Zibo ADS fiyatının arayüz diline göre uyarlanması
    // (bkz. CLAUDE.md "Zibo ADS" bölümü) için eklenen `languageCode`
    // parametresi: yalnızca sayı biçimini (ondalık/binlik ayracı) değiştirir,
    // para birimi/sembolü DEĞİŞMEZ.
    test('languageCode: "en" iken ondalık nokta, binlik virgül kullanılır', () {
      expect(
        formatCurrencyAmount(159.90, 'TRY', languageCode: 'en'),
        '159.90 ₺',
      );
      expect(
        formatCurrencyAmount(1499.99, 'TRY', languageCode: 'en'),
        '1,499.99 ₺',
      );
    });

    test('languageCode verilmezse (varsayılan) Türkçe biçim kullanılır', () {
      expect(formatCurrencyAmount(159.90, 'TRY'), '159,90 ₺');
    });

    test('languageCode: "es" iken Türkçe ile AYNI (virgül ondalık) biçim kullanılır', () {
      expect(
        formatCurrencyAmount(159.90, 'TRY', languageCode: 'es'),
        '159,90 ₺',
      );
    });
  });
}
