import 'package:flutter/foundation.dart';

/// AdMob'un tam ekran reklamı (rewarded/interstitial, `AdMobAdService`)
/// gösterilirken `true` olan global bir sinyal — `homeTabRequest`/
/// `isHomeTabActive` (bkz. `tab_navigation.dart`) ile AYNI "basit, paylaşılan
/// `ValueNotifier`" deseni. `AdMobAdService` bir widget OLMADIĞI için (saf
/// bir servis sınıfı) `context`'e erişemiyor — bu yüzden `Provider` yerine
/// widget ağacının dışından da yazılabilen bu global değişken kullanılıyor.
/// `AdBlurOverlay` (bkz. `widgets/ad_blur_overlay.dart`) bunu dinleyip
/// `true` iken tüm uygulamanın üzerine bir bulanıklaştırma/perde katmanı
/// bindiriyor — bkz. CLAUDE.md "AdMob Entegrasyonu" bölümündeki "reklam tam
/// ekranı kaplamıyor" bug'ının yedek (fallback) çözümü.
final ValueNotifier<bool> isAdShowing = ValueNotifier<bool>(false);
