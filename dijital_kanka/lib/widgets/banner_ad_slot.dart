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
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  // `null` = henüz hiç senkronize edilmedi (ilk build henüz olmadı).
  bool? _lastShown;

  /// **İlk sürümdeki eksik — kullanıcı raporu: "reklam gözükmüyor".**
  /// `AppodealBanner` widget'ı yalnızca native tarafta BOŞ bir kap (view)
  /// oluşturuyor — Rewarded/Interstitial'daki `Appodeal.show(...)`'un AYNI
  /// karşılığı burada da AÇIKÇA çağrılmadıkça SDK o kaba HİÇBİR reklam
  /// YERLEŞTİRMİYOR (bkz. paket kaynağı `appodeal.dart` — `show()`'un kendi
  /// dokümantasyonu: "Shows [adType] advertising with [placement]"). Bu
  /// yüzden yalnızca ekranda BOŞ 320×50'lik bir alan duruyordu.
  /// `isAdFree` DEĞİŞTİĞİNDE (ilk build dahil) bir kez `show`/`hide`
  /// çağrılıyor — HER `build()`'de DEĞİL, gereksiz tekrar tekrar `show()`
  /// çağrısı önlensin diye.
  void _syncVisibility(bool isAdFree) {
    final shouldShow = !isAdFree;
    if (_lastShown == shouldShow) return;
    _lastShown = shouldShow;
    try {
      if (shouldShow) {
        Appodeal.show(AppodealAdType.Banner).catchError((_) => false);
      } else {
        Appodeal.hide(AppodealAdType.Banner);
      }
    } catch (_) {
      // Appodeal eklentisi kullanılamıyorsa (flutter_test, desteklenmeyen
      // platform) — bkz. `lib/services/CLAUDE.md`'deki AYNI "platform
      // kanalına dokunan her çağrı try/catch'li olmalı" kuralı.
    }
  }

  @override
  void dispose() {
    if (_lastShown == true) {
      try {
        Appodeal.hide(AppodealAdType.Banner);
      } catch (_) {
        // yukarıdaki AYNI gerekçe.
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    _syncVisibility(isAdFree);
    if (isAdFree) return const SizedBox.shrink();

    // `AppodealBanner` kendi kendini `adSize`'a göre boyutlandırıyor (paket
    // içinde zaten bir `SizedBox.fromSize` ile sarılı) — burada yalnızca
    // yatayda ortalamak yeterli.
    return const Center(
      child: AppodealBanner(adSize: AppodealBannerSize.BANNER),
    );
  }
}
