import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

import '../providers/ad_free_provider.dart';

/// Kalıcı (sürekli gösterilen) 320×50 banner reklam — Ana Sayfa ve diğer
/// modül ekranlarına tek tek, farklı konumlarda yerleştiriliyor (2026 yeni
/// özellik). Appodeal'ın banner widget'ı SABİT 320×50 boyutunda (AdMob'un
/// "smart banner"ının aksine tam ekran genişliğine YAYILMIYOR) — bu yüzden
/// [Center] ile ortalanıyor, aksi halde sol kenara yapışık kalırdı.
///
/// **"Reklamsız Zibo" satın alanlarda TAMAMEN gizleniyor** — `AdFreeProvider`
/// ile aynı guard, `CoinProvider.showInterstitialAd()`'ın Ana Sayfa'daki
/// art arda dokunma akışında zaten kullandığı deseni burada da uyguluyoruz.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    if (isAdFree) return const SizedBox.shrink();

    // `AppodealBanner` kendi kendini `adSize`'a göre boyutlandırıyor (paket
    // içinde zaten bir `SizedBox.fromSize` ile sarılı) — burada yalnızca
    // yatayda ortalamak yeterli.
    return const Center(
      child: AppodealBanner(adSize: AppodealBannerSize.BANNER),
    );
  }
}
