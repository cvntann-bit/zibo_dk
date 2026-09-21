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
/// ile aynı guard.
///
/// **2026-09-22 düzeltmesi #2 — [isActive] neden gerekli:** `AppodealBanner`
/// widget'ının native tarafı (paket kaynağı `AppodealAdView.kt`) Appodeal'ın
/// TEK/paylaşılan banner görünümünü kullanıyor (`Appodeal.getBannerView()` —
/// STATİK bir `WeakReference` ile önbelleğe alınmış, uygulama genelinde TEK
/// bir native `View` örneği). Bir `AppodealBanner` PlatformView'ı
/// oluşturulduğunda bu paylaşılan görünümü ÖNCEKİ ebeveyninden koparıp
/// KENDİSİNE alıyor — yani AYNI ANDA MONTE olan birden fazla `BannerAdSlot`
/// arasında (ör. Ana Sayfa VE Hedefler sekmeleri, `IndexedStack` İKİSİNİ DE
/// SÜREKLİ monte tutuyor) yalnızca EN SON oluşturulan/yeniden oluşturulan
/// GERÇEKTEN reklam gösterebiliyor, diğerleri sessizce BOŞ kalıyor (kullanıcı
/// raporu: "anasayfada gözükmüyor ama tema değiştirince geldi" — tam da tema
/// değişikliğinin tetiklediği ağaç-genelinde yeniden kuruluş, Ana Sayfa'nın
/// `AppodealBanner`'ını yeniden oluşturup paylaşılan görünümü GERİ ÇALMIŞTI).
///
/// Çözüm: yalnızca GERÇEKTEN görünür olan sekme `AppodealBanner`'ı
/// oluştursun — [isActive] `false` iken hiçbir platform view kurulmuyor
/// (paylaşılan görünümü "çalma" riski yok), `true` olduğunda İSE bu YENİ bir
/// widget türü olduğu için (önceki build `SizedBox.shrink()` döndürüyordu)
/// Flutter otomatik olarak taze bir `AppodealBanner` kurup paylaşılan
/// görünümü BU yerleşime geri kazandırıyor — elle bir "claim" mekanizması
/// GEREKMİYOR. Yalnızca `IndexedStack` SEKMELERİNDE (Ana Sayfa/Hedefler)
/// anlamlı — `Navigator.push` ile açılan diğer modüller zaten yalnızca
/// görünürken monte olduğu için varsayılan `true` yeterli.
///
/// **`Appodeal.show(AppodealAdType.Banner)` KASITLI olarak KULLANILMIYOR**
/// (bkz. `bannerAdReloadSignal` dokümantasyonu) — bu, `AppodealBanner`'ın
/// kullandığı gömülü `BANNER_VIEW` tipinden FARKLI bir yuva olup ekranın alt
/// kenarına sabit, istenmeyen İKİNCİ bir reklam kaplaması gösteriyordu.
/// Reklamın gecikmeli yüklenmesi durumunda (ilk deneme sırasında henüz
/// önbelleğe alınmış bir reklam yoksa) yeniden denemek için bunun yerine
/// [bannerAdReloadSignal]'ı dinleyip `AppodealBanner`'a YENİ bir `Key`
/// veriyoruz.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key, this.isActive = true});

  /// Bu yerleşimin şu an GERÇEKTEN görünen sekme/ekran olup olmadığı — bkz.
  /// sınıf dokümantasyonu.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

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
