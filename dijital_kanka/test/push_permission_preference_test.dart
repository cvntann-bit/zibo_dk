// Intro'da bildirim "Şimdi Değil" seçimi, açılıştaki FCM izin isteğine saygı göstermesi için kalıcı saklanır.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/services/push_permission_preference.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'anahtar yoksa (mevcut kullanıcılar) reddedilmiş SAYILMAZ → izin eskisi gibi istenir',
    () async {
      expect(await PushPermissionPreference.isDeclined(), isFalse);
    },
  );

  test('"Şimdi Değil" kalıcı saklanır, izin verilince geri alınır', () async {
    await PushPermissionPreference.setDeclined(true);
    expect(await PushPermissionPreference.isDeclined(), isTrue);
    await PushPermissionPreference.setDeclined(false);
    expect(await PushPermissionPreference.isDeclined(), isFalse);
  });
}
