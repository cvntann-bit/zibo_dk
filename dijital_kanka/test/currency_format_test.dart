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
  });
}
