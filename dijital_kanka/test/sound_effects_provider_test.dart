// SoundEffectsProvider'ın ses efektleri açık/kapalı tercihini doğru
// tuttuğunu ve SharedPreferences üzerinden kalıcı olarak sakladığını
// (uygulama yeniden başlatılsa bile hatırlandığını) doğrudan (widget
// pump'lamadan) test eder — ThemeProvider testleriyle BİREBİR AYNI desen.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/sound_effects_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Varsayılan olarak ses efektleri açıktır', () async {
    final provider = SoundEffectsProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.enabled, isTrue);
  });

  test('setEnabled(false) hem durumu hem kalıcı depoyu günceller', () async {
    final provider = SoundEffectsProvider();
    await provider.setEnabled(false);

    expect(provider.enabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(prefs.getString('soundEffectsState')!) as Map<String, dynamic>;
    expect(saved['value'], isFalse);
  });

  test(
    'Uygulama yeniden başlatılsa bile (yeni SoundEffectsProvider) kaydedilen tercih hatırlanır',
    () async {
      final firstLaunch = SoundEffectsProvider();
      await firstLaunch.setEnabled(false);

      final secondLaunch = SoundEffectsProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.enabled, isFalse);
    },
  );
}
