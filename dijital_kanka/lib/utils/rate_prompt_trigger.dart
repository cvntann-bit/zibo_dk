import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Bizi Google Play'de Puanla" penceresinin (bkz. `rate_prompt_dialog.dart`)
/// ne zaman çıkacağını belirleyen kurallar — `AdFreePromoTrigger` ile AYNI
/// desen (statik durum + `SharedPreferences` + yüklenmeden ASLA göstermeyen
/// güvenli varsayılan; `main()` dışında `initialize` çağrılmayan testlerde
/// pencere hiç çıkmaz).
///
/// Mutlu anlarda (7 günlük hedef, para/birikim girişi, günlük kayıtlar,
/// rozet) çağrılır. Kurallar (kullanıcı onaylı mockup, 2026-09-24):
///  - Her mutlu anda [chance] ihtimalle.
///  - Gösterimden sonra en az [cooldown] tekrar çıkmaz.
///  - Uygulamanın açıldığı ilk 2 gün (toplam < [minDaysOpened]) çıkmaz.
///  - [markCompleted] sonrası (Puanla / yıldız / "Zaten puanladım") ASLA.
///    Google, kullanıcının gerçekten puan verip vermediğini uygulamaya
///    bildirmiyor — "puanladı" sayılmanın en yakın karşılığı bu.
class RatePromptTrigger {
  RatePromptTrigger._();

  static const _completedKey = 'ratePromptCompleted';
  static const _lastShownKey = 'ratePromptLastShownAtMillis';

  static const double chance = 0.2;
  static const Duration cooldown = Duration(days: 5);
  static const int minDaysOpened = 3;

  static bool _loaded = false;
  static bool _completed = false;
  static DateTime? _lastShownAt;
  static double Function() _random = Random().nextDouble;
  static DateTime Function() _now = DateTime.now;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed = prefs.getBool(_completedKey) ?? false;
      final millis = prefs.getInt(_lastShownKey);
      if (millis != null) {
        _lastShownAt = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {
      // Okunamadı — varsayılanlarla devam (en kötü ihtimalle bir kez fazla
      // gösterilebilir, çökme yok).
    }
    _loaded = true;
  }

  /// `true` dönerse çağıran pencereyi GÖSTERMELİ — gösterim zamanı burada
  /// kaydedilir (bekleme süresi başlar). [daysOpened] yalnızca ucuz
  /// kontroller geçildikten sonra çağrılır.
  static bool shouldShow({required int Function() daysOpened}) {
    if (!_loaded || _completed) return false;
    final last = _lastShownAt;
    if (last != null && _now().difference(last) < cooldown) return false;
    if (daysOpened() < minDaysOpened) return false;
    if (_random() >= chance) return false;
    _lastShownAt = _now();
    unawaited(_persist());
    return true;
  }

  static void markCompleted() {
    _completed = true;
    unawaited(_persist());
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, _completed);
      final last = _lastShownAt;
      if (last != null) await prefs.setInt(_lastShownKey, last.millisecondsSinceEpoch);
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest({
    bool loaded = false,
    bool completed = false,
    DateTime? lastShownAt,
    double Function()? random,
    DateTime Function()? now,
  }) {
    _loaded = loaded;
    _completed = completed;
    _lastShownAt = lastShownAt;
    _random = random ?? Random().nextDouble;
    _now = now ?? DateTime.now;
  }

  @visibleForTesting
  static bool get isCompleted => _completed;
}
