import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/consistency_badges.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_definition.dart';
import '../providers/badge_provider.dart';

/// Rozetler Galerisi — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Kazanılan
/// rozetler net/renkli, kazanılmamış rozetler gri tonlu/soluk görünür ama
/// adı ve kazanma koşulu HER ZAMAN görünür kalır (bu kural "gizli" rozetler
/// kategorisine — henüz eklenmedi — uygulanmayacak, ayrıca ele alınacak).
///
/// Şimdilik yalnızca "İstikrar Rozetleri" kategorisi var — `allBadges`
/// büyüdükçe bu ekran kategoriye göre gruplayıp yeni bölüm başlıkları
/// gösterecek şekilde genişletilebilir (bkz. `consistency_badges.dart`'taki
/// "yeni kategori eklendiğinde yalnızca `allBadges`'e eklenmesi yeterli" notu
/// — bu ekran şimdiden tek bir kategoriyi sabit varsaymıyor, `_categoryTitle`
/// switch'i genişletilebilir).
class BadgesGalleryScreen extends StatelessWidget {
  const BadgesGalleryScreen({super.key});

  String _categoryTitle(AppLocalizations l10n, BadgeCategory category) {
    switch (category) {
      case BadgeCategory.consistency:
        return l10n.badgeCategoryConsistency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesGalleryTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _categoryTitle(l10n, BadgeCategory.consistency),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // 2026 güncellemesi — kullanıcı "genel olarak çerçeve dikdörtgen
              // şeklinde uzun, biraz kısaltalım" dedi: kartın FİKSE yüksekliği
              // (aspect ratio'dan gelen) kısa metinli rozetlerde altta boşluk
              // bırakıyordu. Görsel/metin/ödül satırı BİR ÖNCEKİ turda
              // büyütüldüğü için 0.5'ten biraz DAHA BÜYÜK (0.62) bir orana
              // çıkarılıp hem kart kısaltıldı hem büyümüş içerik için yeterli
              // pay bırakıldı — `badges_gallery_screen_test.dart` overflow
              // olmadığını doğruluyor.
              childAspectRatio: 0.62,
              children: [
                for (final badge in consistencyBadges)
                  _BadgeGalleryCard(badge: badge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _greyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _BadgeGalleryCard extends StatelessWidget {
  const _BadgeGalleryCard({required this.badge});

  final ZiboBadgeDefinition badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earned = context.watch<BadgeProvider>().isEarned(badge.id);

    // Kullanıcı isteği: rozet görseli biraz DAHA büyütülsün, çok değil
    // (88 → 108 → 118).
    final image = Image.asset(badge.imageAsset, width: 118, height: 118);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            earned
                ? image
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
                    child: Opacity(opacity: 0.5, child: image),
                  ),
            const SizedBox(height: 10),
            // Kullanıcı isteği: "alttaki yazıların boyutunu büyüt" —
            // ad titleSmall → titleMedium'a, açıklama bodySmall →
            // bodyMedium'a büyütüldü.
            Text(
              badge.localizedName(l10n),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: earned ? null : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                badge.localizedRequirement(l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Kullanıcı isteği: en altta kaç Zibo Coin ödülü olduğu, Zibo
            // Coin ikonu PNG'siyle birlikte gösterilsin — `CoinBalanceWidget`/
            // `CostumeCard`'daki AYNI `assets/images/zibo_coin.png` kullanımı.
            // 2026 güncellemesi: hem ikon hem metin büyütüldü ("10zc/30zc
            // ve zc ikonunun boyutunu büyüt").
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/zibo_coin.png', width: 20, height: 20),
                const SizedBox(width: 5),
                Text(
                  l10n.storeCoinAmount(badge.zcReward),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: earned
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
