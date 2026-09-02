// clearLocalAccountData()'nın hesaba özgü anahtarları silip cihaz
// tercihlerini (dark mode/dil/ses efektleri) KORUDUĞUNU doğrudan (widget
// pump'lamadan) test eder — bkz. CLAUDE.md "Google Hesap Bağlama"
// bölümündeki "Çıkış Yap sonrası eski hesabın verisi sızıyordu" bug notu.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/utils/local_account_data.dart';

void main() {
  test(
    'clearLocalAccountData: TÜM hesap verisi anahtarlarını siler, cihaz '
    'tercihlerine (isDarkMode/languageCode/soundEffectsState) VE hesap '
    'DIŞI güvenlik/throttle önbelleklerine (trustedTimeLastVerifiedUtc/'
    'adFreePromoLastShownAtMillis) DOKUNMAZ',
    () async {
      final seeded = <String, Object>{
        for (final key in localAccountDataKeys) key: '{"dummy": true}',
        'isDarkMode': true,
        'languageCode': 'en',
        'soundEffectsState': '{"value": false}',
        'trustedTimeLastVerifiedUtc': '2026-01-01T00:00:00.000Z',
        'adFreePromoLastShownAtMillis': 123456789,
      };
      SharedPreferences.setMockInitialValues(seeded);
      final prefs = await SharedPreferences.getInstance();
      for (final key in localAccountDataKeys) {
        expect(prefs.containsKey(key), isTrue, reason: '$key seed edilmeliydi');
      }

      await clearLocalAccountData();

      for (final key in localAccountDataKeys) {
        expect(
          prefs.containsKey(key),
          isFalse,
          reason: '$key clearLocalAccountData() sonrası SİLİNMİŞ olmalıydı',
        );
      }
      // Cihaz tercihleri VE hesap dışı önbellekler DOKUNULMADAN kalmalı.
      expect(prefs.getBool('isDarkMode'), isTrue);
      expect(prefs.getString('languageCode'), 'en');
      expect(prefs.getString('soundEffectsState'), '{"value": false}');
      expect(
        prefs.getString('trustedTimeLastVerifiedUtc'),
        '2026-01-01T00:00:00.000Z',
      );
      expect(prefs.getInt('adFreePromoLastShownAtMillis'), 123456789);
    },
  );

  test(
    'localAccountDataKeys listesi tekrarsız VE boş değil',
    () {
      expect(localAccountDataKeys, isNotEmpty);
      expect(localAccountDataKeys.toSet().length, localAccountDataKeys.length);
    },
  );
}
