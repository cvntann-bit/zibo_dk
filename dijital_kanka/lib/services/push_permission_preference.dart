import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı intro'daki bildirim adımında "Şimdi Değil" dediyse (ya da sistem izni reddettiyse) açılıştaki
/// FCM izin isteği (`PushNotificationService.initialize`) BUNA saygı göstermeli: aksi halde onboarding biter
/// bitmez sistem penceresi çıkıp kullanıcının seçimini yok sayardı. Anahtar yoksa (mevcut kullanıcılar) davranış
/// DEĞİŞMEZ — izin eskisi gibi istenir.
class PushPermissionPreference {
  const PushPermissionPreference._();

  static const _key = 'introNotifDeclined';

  static Future<void> setDeclined(bool declined) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, declined);
    } catch (_) {
      // Yazılamadı — en kötü ihtimalle izin bir kez daha sorulur.
    }
  }

  /// `true` → açılışta sistem izin penceresini GÖSTERME.
  static Future<bool> isDeclined() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }
}
