import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Paywall tanıtım ekranının (bkz. `screens/paywall_screen.dart`,
/// `docs/subscribe_model.md`) ne zaman gösterileceğini belirleyen kural.
///
/// **2026 güncellemesi — kullanıcı raporu: "çok sık/rahatsız edici
/// çıkıyor".** İlk sürüm YALNIZCA oturum bazlı bir sayaçtı (her 3. Mağaza
/// ziyaretinde, kalıcılık YOK — uygulama yeniden açılınca sıfırlanıyordu).
/// Kullanıcı Mağaza'yı sık ziyaret ettikçe (ör. kostüm/tema satın alırken)
/// bu, HER OTURUMDA yeniden tetiklenip rahatsız edici bir sıklığa yol açtı.
/// Artık İKİ kısıtlama BİRLİKTE uygulanıyor:
///  1. En az [_visitsPerAttempt] Mağaza ziyareti (eskiden 3, şimdi 5) —
///     "ara sıra" isteğini hâlâ karşılıyor.
///  2. En son gösterimden bu yana en az [_cooldown] (3 gün) geçmiş olması —
///     bu artık `SharedPreferences` ile KALICI (uygulama kapatılıp yeniden
///     açılsa bile hatırlanıyor), çünkü kullanıcı deneyimini asıl bozan
///     OTURUMLAR ARASI tekrardı, tek bir oturum içindeki sıklık değil.
class AdFreePromoTrigger {
  AdFreePromoTrigger._();

  static const _prefsKey = 'adFreePromoLastShownAtMillis';
  static const _visitsPerAttempt = 5;
  static const _cooldown = Duration(days: 3);

  static int _storeVisitCount = 0;
  static DateTime? _lastShownAt;
  static bool _loaded = false;

  /// `main()`'de, `runApp`'tan ÖNCE bir kez çağrılır — en son gösterim
  /// zamanını kalıcı depodan belleğe yükler. Yüklenene kadar
  /// [shouldShowOnStoreVisit] hiçbir zaman `true` DÖNMEZ — bu, kalıcı
  /// veriyi henüz görmeden (ör. yükleme tamamlanmadan bir Mağaza ziyareti
  /// olursa) yanlışlıkla erken/sık göstermeyi engelleyen güvenli bir
  /// varsayılan.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_prefsKey);
      if (millis != null) {
        _lastShownAt = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {
      // Kalıcı depo okunamadı (ör. `flutter_test` ortamı, platform
      // channel'ı olmayan bir bağlam) — `_lastShownAt` `null` kalır,
      // yalnızca ziyaret sayacına göre karar verilir.
    }
    _loaded = true;
  }

  /// Mağaza sekmesi her aktif hale geldiğinde (bkz. `StoreScreen.isActive`)
  /// çağrılır.
  static bool shouldShowOnStoreVisit() {
    _storeVisitCount++;
    if (!_loaded) return false;
    if (_storeVisitCount % _visitsPerAttempt != 0) return false;
    final lastShown = _lastShownAt;
    if (lastShown != null && DateTime.now().difference(lastShown) < _cooldown) {
      return false;
    }
    _lastShownAt = DateTime.now();
    unawaited(_persistLastShown());
    return true;
  }

  static Future<void> _persistLastShown() async {
    final lastShownAt = _lastShownAt;
    if (lastShownAt == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, lastShownAt.millisecondsSinceEpoch);
    } catch (_) {
      // Yazılamazsa (ör. test ortamı) sorun değil — yalnızca kalıcılık
      // kaybolur, bir sonraki oturumda yeniden gösterilebilir hâle gelir.
    }
  }

  /// Yalnızca testler için — sayaç VE bellekteki kalıcı-olmayan durum
  /// sıfırdan başlasın diye. `loaded`/`lastShownAt` parametreleri,
  /// [initialize]'ın kalıcı depodan yüklediği durumu simüle etmek için.
  static void resetForTest({bool loaded = true, DateTime? lastShownAt}) {
    _storeVisitCount = 0;
    _loaded = loaded;
    _lastShownAt = lastShownAt;
  }
}
