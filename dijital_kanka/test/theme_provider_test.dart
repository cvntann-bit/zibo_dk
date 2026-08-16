// ThemeProvider'ın koyu/açık tema tercihini doğru tuttuğunu ve
// SharedPreferences üzerinden kalıcı olarak sakladığını (uygulama yeniden
// başlatılsa bile hatırlandığını) doğrudan (widget pump'lamadan) test eder.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Varsayılan tema açıktır', () async {
    final provider = ThemeProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isDarkMode, isFalse);
    expect(provider.themeMode, ThemeMode.light);
  });

  test('setDarkMode(true) hem durumu hem kalıcı depoyu günceller', () async {
    final provider = ThemeProvider();
    await provider.setDarkMode(true);

    expect(provider.isDarkMode, isTrue);
    expect(provider.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('isDarkMode')!) as Map<String, dynamic>;
    expect(saved['value'], isTrue);
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni ThemeProvider) kaydedilen tercih hatırlanır',
    () async {
      final firstLaunch = ThemeProvider();
      await firstLaunch.setDarkMode(true);

      // "Uygulamayı kapatıp aç": aynı kalıcı depoyu okuyan yeni bir
      // ThemeProvider oluştur.
      final secondLaunch = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.isDarkMode, isTrue);
    },
  );
}
