import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import 'sticker_style.dart';

/// **Faz 3 (D1)** — Şükran Günlüğü/Ruh Hali Takibi/Manifest Günlüğü geçmiş
/// listelerinin sonunda, free kullanıcı 30 günden eski kayıtlara
/// ULAŞAMADIĞINDA gösterilen ortak yükseltme kartı — üç ekran de AYNI
/// widget'ı kullanır (kod tekrarı yok). Görsel dil `store_screen.dart`'ın
/// `_StorePromoCard`/`_StorePromoCta`'sıyla AYNI (ikon çemberi + başlık/alt
/// metin + altın CTA butonu) — o widget'lar private olduğu için burada
/// bağımsız, basitleştirilmiş bir kopyası var (statik CTA, fiyat sorgusu
/// YOK). Dokununca `PaywallScreen`'i açar; hangi kayıtların
/// gösterilip/gizleneceğine KARAR VERMEZ, o ekranların kendi işi.
class HistoryLimitUpsellCard extends StatelessWidget {
  const HistoryLimitUpsellCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: stickerDecoration(
          fill: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: stickerCircleDecoration(
                fill: colorScheme.primary,
                borderWidth: 2.5,
                shadowOffset: Offset.zero,
              ),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Center(
                  child: Text('🔒', style: TextStyle(fontSize: 16, height: 1)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.historyLimitCardTitle,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.historyLimitCardSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            stickerButtonShadow(
              child: Material(
                color: colorScheme.primary,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: kStickerOutline, width: 2.5),
                      borderRadius: radius,
                    ),
                    child: Text(
                      l10n.historyLimitCardButton,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontSize: 12,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
