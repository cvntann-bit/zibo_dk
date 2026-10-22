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
  static const _tappedKey = 'ratePromptTappedAtMillis';
  static const _countKey = 'ratePromptShownCount';

  // 2026-10 (Faz S — daha sık göster): 0.2/5 gün/3 gün → 0.35/3 gün/2 gün. Kullanıcı yıldız/Puanla'ya
  // dokunduysa [tappedCooldown] boyunca sorulmaz (artık kalıcı kapanış YOK: Google puan verilip verilmediğini
  // bildirmiyor, dokunmak puan vermek demek değil); yaşam boyu en fazla [maxShows] gösterim.
  static const double chance = 0.35;
  static const Duration cooldown = Duration(days: 3);
  static const Duration tappedCooldown = Duration(days: 45);
  static const int minDaysOpened = 2;
  static const int maxShows = 8;

  static bool _loaded = false;
  static bool _completed = false;
  static DateTime? _lastShownAt;
  static DateTime? _tappedAt;
  static int _shownCount = 0;
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
      final tapped = prefs.getInt(_tappedKey);
      if (tapped != null)
        _tappedAt = DateTime.fromMillisecondsSinceEpoch(tapped);
      _shownCount = prefs.getInt(_countKey) ?? 0;
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
    if (_shownCount >= maxShows) return false;
    final tapped = _tappedAt;
    if (tapped != null && _now().difference(tapped) < tappedCooldown)
      return false;
    final last = _lastShownAt;
    if (last != null && _now().difference(last) < cooldown) return false;
    if (daysOpened() < minDaysOpened) return false;
    if (_random() >= chance) return false;
    _lastShownAt = _now();
    _shownCount++;
    unawaited(_persist());
    return true;
  }

  /// Kullanıcı "Puanla"/yıldıza dokundu: [tappedCooldown] boyunca bir daha sorma (KALICI kapanış değil).
  static void markRateTapped() {
    _tappedAt = _now();
    unawaited(_persist());
  }

  /// "Zaten puanladım" / Ayarlar'daki kalıcı "Bizi puanla": bir daha ASLA sorma.
  static void markCompleted() {
    _completed = true;
    unawaited(_persist());
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, _completed);
      final last = _lastShownAt;
      if (last != null)
        await prefs.setInt(_lastShownKey, last.millisecondsSinceEpoch);
      final tapped = _tappedAt;
      if (tapped != null)
        await prefs.setInt(_tappedKey, tapped.millisecondsSinceEpoch);
      await prefs.setInt(_countKey, _shownCount);
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest({
    bool loaded = false,
    bool completed = false,
    DateTime? lastShownAt,
    DateTime? tappedAt,
    int shownCount = 0,
    double Function()? random,
    DateTime Function()? now,
  }) {
    _loaded = loaded;
    _completed = completed;
    _lastShownAt = lastShownAt;
    _tappedAt = tappedAt;
    _shownCount = shownCount;
    _random = random ?? Random().nextDouble;
    _now = now ?? DateTime.now;
  }

  @visibleForTesting
  static bool get isCompleted => _completed;
}
