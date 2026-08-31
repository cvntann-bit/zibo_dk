import 'package:flutter/foundation.dart';

/// Tam ekran reklamın (rewarded/interstitial, `AppodealAdService` —
/// bkz. CLAUDE.md "AdMob Entegrasyonu" bölümündeki Appodeal geçiş notu)
/// gösterilirken `true` olan, reklam SDK'sından bağımsız global bir sinyal
/// — `homeTabRequest`/`isHomeTabActive` (bkz. `tab_navigation.dart`) ile
/// AYNI "basit, paylaşılan `ValueNotifier`" deseni. Reklam servisi bir
/// widget OLMADIĞI için (saf bir servis sınıfı) `context`'e erişemiyor — bu
/// yüzden `Provider` yerine widget ağacının dışından da yazılabilen bu
/// global değişken kullanılıyor. `AdBlurOverlay` (bkz. `widgets/
/// ad_blur_overlay.dart`) bunu dinleyip `true` iken tüm uygulamanın üzerine
/// bir bulanıklaştırma/perde katmanı bindiriyor — AdMob'da yaşanan "reklam
/// tam ekranı kaplamıyor" bug'ının yedek (fallback) çözümü, hangi reklam
/// SDK'sı kullanılırsa kullanılsın geçerliliğini koruyor.
final ValueNotifier<bool> isAdShowing = ValueNotifier<bool>(false);
