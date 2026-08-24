// CurrencyProvider'ın Para ve Birikim modülü için seçili para birimi
// tercihini doğru tuttuğunu ve SharedPreferences üzerinden kalıcı olarak
// sakladığını (uygulama yeniden başlatılsa bile hatırlandığını) doğrudan
// (widget pump'lamadan) test eder — ThemeProvider testleriyle aynı desen.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/currency_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Varsayılan para birimi TRY\'dir', () async {
    final provider = CurrencyProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.currencyCode, 'TRY');
    expect(provider.currency.symbol, '₺');
  });

  test('setCurrencyCode hem durumu hem kalıcı depoyu günceller', () async {
    final provider = CurrencyProvider();
    await provider.setCurrencyCode('USD');

    expect(provider.currencyCode, 'USD');
    expect(provider.currency.symbol, '\$');

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('currencyState')!) as Map<String, dynamic>;
    expect(saved['value'], 'USD');
  });

  test('Geçersiz bir para birimi kodu sessizce reddedilir', () async {
    final provider = CurrencyProvider();
    await provider.setCurrencyCode('XYZ');

    expect(provider.currencyCode, 'TRY');
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni CurrencyProvider) kaydedilen tercih hatırlanır',
    () async {
      final firstLaunch = CurrencyProvider();
      await firstLaunch.setCurrencyCode('EUR');

      final secondLaunch = CurrencyProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.currencyCode, 'EUR');
      expect(secondLaunch.currency.symbol, '€');
    },
  );
}
