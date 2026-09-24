import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import 'sticker_style.dart';

/// **2026-09-24 — Pro+ grafik kilidi için PAYLAŞILAN görsel dil.** Kullanıcı
/// isteği: grafikler artık Pro+ olmayan kullanıcıdan TAMAMEN gizlenmiyor
/// (eski `if (isProPlus) ...` deseni — bkz. `MoodTrendDetailChart`'ın önceki
/// sürümü/`money_screen.dart`'ın eski `_AdvancedAnalysisSection` gate'i),
/// bunun yerine GERÇEK grafik bulanıklaştırılıp üstüne 🔒 rozeti + "Zibo
/// Pro+'a Bugün Geç" yazısı bindiriliyor — dokununca `PaywallScreen`'e
/// yönlendiriyor. `AdBlurOverlay`'in (`ad_blur_overlay.dart`) AYNI
/// `BackdropFilter`/`ImageFilter.blur` deseni, yalnızca tüm uygulama yerine
/// TEK bir grafiğin kendi alanına sarılmış hali.
///
/// **Yalnızca [child]'ı (ör. bir grafiğin `SizedBox`'ı) sar** — başlık/
/// granülarite toggle'ı gibi ÇEVRESİNDEKİ kontrolleri SARMA: kullanıcı bölümün
/// var olduğunu ve neyi kaçırdığını görsün diye başlık/toggle her zaman net
/// kalır, yalnızca asıl çizim bulanıklaşır.
class LockedFeatureOverlay extends StatelessWidget {
  const LockedFeatureOverlay({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          IgnorePointer(child: child),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: colorScheme.surface.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: stickerCircleDecoration(
                              fill: colorScheme.primary,
                              borderWidth: 2.5,
                            ),
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Center(
                                child: Text('🔒', style: TextStyle(fontSize: 19, height: 1)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lockedChartCta,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontVariations: const [FontVariation('wght', 800)],
                              fontSize: 12.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
