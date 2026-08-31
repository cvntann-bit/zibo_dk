import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/ad_overlay_state.dart';

/// Tam ekran bir reklam (rewarded/interstitial) AÇIKKEN uygulamanın kendi
/// arayüzünün üzerine bir bulanıklaştırma (blur) + koyu perde katmanı
/// bindiren, YEDEK (fallback) bir güvenlik önlemi — reklam SDK'sından
/// (Appodeal, önceden AdMob) BAĞIMSIZ.
///
/// **Kökeni — AdMob'da gerçek, cihazda doğrulanmış bir bug'dan geldi:**
/// Android 15'in zorunlu edge-to-edge davranışı + AdMob'un kendi
/// `AdActivity` bileşeninin (Google'ın SDK'sından gelen, manifest'e otomatik
/// birleşen) varsayılan YARI SAYDAM teması bir araya gelince, reklam
/// gösterilirken ekranın üst kısmında (durum çubuğu şeridinde) altındaki
/// `MainActivity`'nin içeriği — Zibo'nun kendi AppBar'ı — görünür
/// kalabiliyordu. O zamanki asıl düzeltme (`AdActivity`'nin temasını
/// `tools:replace="android:theme"` ile override etmek) AdMob'un KENDİ
/// manifest bileşenine bağlıydı — `google_mobile_ads` bu projeden TAMAMEN
/// kaldırılınca (bkz. CLAUDE.md "AdMob Entegrasyonu" bölümündeki Appodeal
/// geçiş notu) o native override de artık uygulanamaz/geçersiz hale geldi.
/// **Bu widget (Flutter-taraflı, native davranıştan bağımsız katman) BİLEREK
/// KORUNDU** — hangi reklam SDK'sı kullanılırsa kullanılsın, tam ekranı
/// düzgün kaplamayan bir reklam Activity'si için genel/garantili bir
/// güvenlik ağı olarak faydalı olmaya devam ediyor.
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
