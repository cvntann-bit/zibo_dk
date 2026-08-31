// ThemeProvider'ın görünüm tercihini (Açık/Koyu/Sistemi Takip Et) doğru
// tuttuğunu ve SharedPreferences üzerinden kalıcı olarak sakladığını
// (uygulama yeniden başlatılsa bile hatırlandığını) doğrudan (widget
// pump'lamadan) test eder. **2026 güncellemesi — Sistem Teması desteği:**
// eski düz bool (`setDarkMode`) API'si `setThemeMode(ThemeMode)`'a geçti.

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

  test('setThemeMode(dark) hem durumu hem kalıcı depoyu günceller', () async {
    final provider = ThemeProvider();
    await provider.setThemeMode(ThemeMode.dark);

    expect(provider.isDarkMode, isTrue);
    expect(provider.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('isDarkMode')!) as Map<String, dynamic>;
    expect(saved['value'], 'dark');
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni ThemeProvider) kaydedilen tercih hatırlanır',
    () async {
      final firstLaunch = ThemeProvider();
      await firstLaunch.setThemeMode(ThemeMode.dark);

      // "Uygulamayı kapatıp aç": aynı kalıcı depoyu okuyan yeni bir
      // ThemeProvider oluştur.
      final secondLaunch = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.isDarkMode, isTrue);
      expect(secondLaunch.themeMode, ThemeMode.dark);
    },
  );

  test('setThemeMode(system) aynı değeri tekrar ayarlarsa no-op olur', () async {
    final provider = ThemeProvider();
    await provider.setThemeMode(ThemeMode.system);
    await provider.setThemeMode(ThemeMode.system);

    expect(provider.themeMode, ThemeMode.system);
  });

  test(
    '2026 ÖNCESİ (Sistem Teması eklenmeden önceki) düz-bool kayıtlı veri doğru göç eder',
    () async {
      // O zamanki `_save()` biçimi: `{'value': true/false}` — `system`
      // hiç yoktu.
      SharedPreferences.setMockInitialValues({'isDarkMode': jsonEncode({'value': true})});
      final provider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
    },
  );
}
