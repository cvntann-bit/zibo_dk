import 'package:flutter/foundation.dart';

/// Appodeal SDK'sı YENİ bir banner reklamı önbelleğe aldığında (`main.dart`'taki
/// GLOBAL `onBannerLoaded` callback'i) artırılır — `pendingBadgePopup`/
/// `pendingLevelUp` ile AYNI "basit, widget ağacının dışından da yazılabilen
/// global `ValueNotifier`" deseni.
///
/// **Neden gerekli:** `AppodealBanner` widget'ının native tarafı (bkz. paket
/// kaynağı `AppodealAdView.kt`) kendi `Appodeal.show(activity, BANNER_VIEW,
/// placement)` çağrısını YALNIZCA PlatformView OLUŞTURULDUĞU anda (widget'ın
/// `initState`'i) yapıyor — SDK o anda henüz bir reklamı önbelleğe almamışsa
/// bu ilk deneme sessizce başarısız olur ve widget BİR DAHA denemez.
/// `BannerAdSlot` bu sinyali dinleyip `AppodealBanner`'a YENİ bir `Key`
/// vererek (bkz. o dosya) PlatformView'ı YENİDEN oluşturmaya zorluyor —
/// bu da native `init{}`'in (dolayısıyla `Appodeal.show`'un) tekrar
/// çalışmasını sağlıyor.
///
/// **KRİTİK — `Appodeal.show(AppodealAdType.Banner)` (Dart tarafından
/// doğrudan çağrılan, KLASİK/`Appodeal.BANNER` tipi) burada KASITLI olarak
/// KULLANILMIYOR:** bu, `AppodealBanner` widget'ının kullandığı
/// `Appodeal.BANNER_VIEW` tipinden TAMAMEN FARKLI bir reklam yuvası —
/// Appodeal'ın native SDK'sı `Appodeal.BANNER`'ı, herhangi bir konteynere
/// gömülü OLMADAN, ekranın ALT kenarına sabit bir kaplama (overlay) olarak
/// gösteriyor. Önceki bir düzeltme yanlışlıkla bu çağrıyı kullanmıştı — sonuç,
/// asıl (doğru konumlandırılmış, gömülü) banner'ın YANINDA, ekranın en
/// altında alt navigasyon çubuğunu kapatan İKİNCİ, istenmeyen bir reklam
/// (kullanıcı raporu, 2026-09-22). Bu tip KARIŞTIRILMAMALI.
final ValueNotifier<int> bannerAdReloadSignal = ValueNotifier<int>(0);
