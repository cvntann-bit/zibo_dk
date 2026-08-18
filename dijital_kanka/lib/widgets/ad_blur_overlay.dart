import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/ad_overlay_state.dart';

/// AdMob'un tam ekran reklamı (rewarded/interstitial) AÇIKKEN uygulamanın
/// kendi arayüzünün üzerine bir bulanıklaştırma (blur) + koyu perde katmanı
/// bindiren, YEDEK (fallback) bir güvenlik önlemi.
///
/// **Neden gerekli — asıl (native/manifest seviyesindeki) düzeltme yetersiz
/// kalırsa diye:** Android 15'in zorunlu edge-to-edge davranışı + AdMob'un
/// kendi `AdActivity` bileşeninin (Google'ın SDK'sından gelen, bizim
/// manifest'imize otomatik birleşen) varsayılan YARI SAYDAM teması bir araya
/// gelince, reklam gösterilirken ekranın üst kısmında (durum çubuğu
/// şeridinde) altındaki `MainActivity`'nin içeriği — Zibo'nun kendi AppBar'ı
/// (coin sayacı/+/ayarlar ikonu) — görünür kalabiliyor (bkz. CLAUDE.md
/// "AdMob Entegrasyonu" bölümü — kullanıcının gerçek cihazda ekran
/// görüntüsüyle bildirdiği bir bug). Asıl düzeltme
/// `android/app/src/main/AndroidManifest.xml`'de
/// `com.google.android.gms.ads.AdActivity`'nin KENDİ temasını
/// `tools:replace="android:theme"` ile `windowOptOutEdgeToEdgeEnforcement`
/// içeren bir temayla değiştirmek (Google AdMob destek ekibinin resmi
/// önerisi, bkz. CLAUDE.md) — ama bu native/manifest seviyesinde bir
/// düzeltme olduğu için cihaz/OEM/Android sürümüne göre davranışı
/// değişebilir, %100 garantili DEĞİL. Bu widget o düzeltme YETERSİZ kalırsa
/// (ör. belirli bir cihaz/sürüm kombinasyonunda) kullanıcının en azından NET
/// bir arayüz karışıklığı GÖRMEMESİNİ sağlayan, TAMAMEN Flutter tarafında
/// kontrol edilen (native davranışa bağımlı OLMAYAN, bu yüzden garantili
/// çalışan) bir ikinci katman.
///
/// `MaterialApp.builder`'ın EN DIŞINDA sarılıyor (bkz. `main.dart`) — bu
/// katmanın altındaki HER ŞEYİ (AppBar dahil) kapsaması için.
class AdBlurOverlay extends StatelessWidget {
  const AdBlurOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isAdShowing,
      builder: (context, showing, cachedChild) {
        return Stack(
          children: [
            cachedChild!,
            if (showing)
              Positioned.fill(
                // `AbsorbPointer` — reklam kendi Activity'sinde dokunuşları
                // zaten yakalıyor olması gerekiyor, ama bu katman altındaki
                // gerçek arayüze YANLIŞLIKLA bir dokunuşun sızmasını
                // (ör. çok kısa bir geçiş anında) da savunmacı bir şekilde
                // engelliyor.
                child: AbsorbPointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.scrim.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      // `child` (Flutter'ın kendi `builder` parametresi, `ValueListenableBuilder`'ın
      // AYRI önbelleklediği alt ağaç) — `isAdShowing` değiştiğinde bu alt
      // ağaç YENİDEN İNŞA EDİLMİYOR, yalnızca üstteki blur katmanı ekleniyor/
      // kaldırılıyor; performans için önemli çünkü bu, TÜM uygulama ağacı.
      child: child,
    );
  }
}
