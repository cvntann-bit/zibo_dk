import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

import '../providers/ad_free_provider.dart';
import '../utils/banner_ad_reload_signal.dart';

/// Kalıcı (sürekli gösterilen) 320×50 banner reklam — Ana Sayfa ve diğer
/// modül ekranlarına tek tek, farklı konumlarda yerleştiriliyor (2026 yeni
/// özellik). Appodeal'ın banner widget'ı SABİT 320×50 boyutunda (AdMob'un
/// "smart banner"ının aksine tam ekran genişliğine YAYILMIYOR) — bu yüzden
/// [Center] ile ortalanıyor, aksi halde sol kenara yapışık kalırdı.
///
/// **"Reklamsız Zibo" satın alanlarda TAMAMEN gizleniyor** — `AdFreeProvider`
/// ile aynı guard, `CoinProvider.showInterstitialAd()`'ın Ana Sayfa'daki
/// art arda dokunma akışında zaten kullandığı deseni burada da uyguluyoruz.
/// Bunun için Appodeal'a AYRICA bir `show`/`hide` çağrısı GEREKMİYOR —
/// `AppodealBanner` widget'ı ağaçtan tamamen kaldırılınca (aşağıdaki
/// `SizedBox.shrink()` dalı) PlatformView zaten dispose olup native reklam
/// görünümünü kaldırıyor.
///
/// **2026-09-22 düzeltmesi — `Appodeal.show(AppodealAdType.Banner)`'ı
/// KASITLI olarak KULLANMIYORUZ** (bkz. `bannerAdReloadSignal`
/// dokümantasyonundaki UZUN gerekçe): bu, `AppodealBanner`'ın kullandığı
/// gömülü `BANNER_VIEW` tipinden FARKLI bir yuva olup ekranın alt kenarına
/// sabit, istenmeyen İKİNCİ bir reklam kaplaması gösteriyordu. Reklamın
/// gecikmeli yüklenmesi durumunda YENİDEN denemek için bunun yerine
/// [bannerAdReloadSignal]'ı dinleyip `AppodealBanner`'a YENİ bir `Key`
/// veriyoruz — bu, widget'ın native tarafını (dolayısıyla KENDİ doğru
/// `Appodeal.show(BANNER_VIEW, ...)` çağrısını) yeniden tetikliyor.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    if (isAdFree) return const SizedBox.shrink();

    // `AppodealBanner` kendi kendini `adSize`'a göre boyutlandırıyor (paket
    // içinde zaten bir `SizedBox.fromSize` ile sarılı) — burada yalnızca
    // yatayda ortalamak yeterli.
    return ValueListenableBuilder<int>(
      valueListenable: bannerAdReloadSignal,
      builder: (context, reloadToken, _) {
        return Center(
          child: AppodealBanner(
            key: ValueKey(reloadToken),
            adSize: AppodealBannerSize.BANNER,
          ),
        );
      },
    );
  }
}
