import 'dart:math';

import 'package:flutter/foundation.dart';

/// Zibo'nun poz döngüsünü yöneten TEK, paylaşılan sayaç — bkz. CLAUDE.md
/// "Zibo Poz/Animasyon Sistemi" bölümü.
///
/// **2026 güncellemesi:** Otomatik zamanlayıcı tabanlı döngü (`Timer`)
/// kullanıcı geri bildirimiyle TAMAMEN kaldırıldı ("poz döngüsü çok hızlı"
/// + "diğer sayfalarda ana sayfadaki poz ne ise o olsun, sürekli
/// değişmesin"). Poz artık yalnızca Ana Sayfa'da Zibo'ya dokunulduğunda
/// (mesaj değişimiyle AYNI tetikleyici, `HomeScreen._onZiboTap`) ilerliyor
/// — ama HER dokunuşta değil, rastgele 5-10 dokunuşta bir (`registerZiboTap`).
/// Diğer yedi ekran bu SAYACI (`poseStep`) salt-okunur `context.watch` ile
/// izliyor, kendi başlarına HİÇ ilerletmiyor — hepsi her zaman Ana
/// Sayfa'yla AYNI pozu gösterir.
///
/// Kalıcı DEĞİL (`CloudStateStore` kullanmıyor) — bu saf bir görsel/UI
/// durumu, kullanıcı verisi değil; her oturum `poseStep = 0`'dan başlaması
/// sorun değil (`_AppStartupGate`'e de dahil edilmedi, bkz. "Açılış yükleme
/// ekranı" bölümü).
class ZiboPoseProvider extends ChangeNotifier {
  ZiboPoseProvider({Random? random}) : _random = random ?? Random() {
    _tapsUntilNextPose = _pickThreshold();
  }

  static const _minTapsPerPose = 5;
  static const _maxTapsPerPose = 10;

  final Random _random;
  int _poseStep = 0;
  int _tapsSinceLastPose = 0;
  late int _tapsUntilNextPose;

  /// Tüm ekranların `poses[poseStep % poses.length]` ile okuduğu paylaşılan
  /// ilerleme sayacı.
  int get poseStep => _poseStep;

  int _pickThreshold() =>
      _minTapsPerPose + _random.nextInt(_maxTapsPerPose - _minTapsPerPose + 1);

  /// Yalnızca Ana Sayfa'da Zibo'ya dokunulduğunda çağrılır. Eşik dolana
  /// kadar `notifyListeners()` ÇAĞRILMAZ (poz değişmediği için gereksiz
  /// rebuild yok) — eşiğe ulaşınca poz ilerler VE bir sonraki eşik yeniden
  /// (5-10 arası) rastgele seçilir, böylece her seferinde aynı sayıda
  /// dokunuş beklemek yerine biraz öngörülemez/doğal hissettiriyor.
  void registerZiboTap() {
    _tapsSinceLastPose++;
    if (_tapsSinceLastPose < _tapsUntilNextPose) return;
    _tapsSinceLastPose = 0;
    _tapsUntilNextPose = _pickThreshold();
    _poseStep++;
    notifyListeners();
  }
}
