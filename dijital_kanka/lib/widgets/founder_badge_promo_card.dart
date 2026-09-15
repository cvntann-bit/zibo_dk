import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_link_provider.dart';
import '../providers/founder_badge_provider.dart';
import '../utils/google_link_action.dart';
import 'sticker_style.dart';

/// Google hesap bağlama satırının HEMEN ÜSTÜNE konan, küçük bir teşvik
/// kartı — Profil'deki "Zibo ile Bağın" bölümünde VE Ayarlar'ın "Genel"
/// kartında AYNI widget kullanılıyor (bkz. CLAUDE.md "Kurucu Üye Rozeti"
/// bölümü — kullanıcının açık isteğiyle "ayrı, küçük bir uyarı kartı").
///
/// Üç durumdan HERHANGİ birinde tamamen görünmez oluyor
/// (`SizedBox.shrink()`, hiçbir yer kaplamıyor):
/// - [FounderBadgeProvider.isLoaded] `false` — canlı sayaç henüz ilk
///   anlık görüntüsünü almadı (uid yok, ağ yok, veya
///   `founderBadgeStatus/status` dokümanı henüz seed edilmedi). Yanıltıcı
///   bir "0/500" veya "500/500" ilk kare göstermemek için BİLEREK
///   böyle — veri gelene kadar sessizce bekler.
/// - [AuthLinkProvider.isLinked] `true` — kullanıcı zaten bağlı, teşvike
///   gerek yok (rozeti ya zaten kazandı ya da bağlandığı an kontenjan
///   dolmuştu, ikisi de ayrı bir mesaj gerektirmiyor).
/// - [FounderBadgeProvider.isSoldOut] `true` — 500 kişi tamamlandı,
///   kampanya kapandı.
class FounderBadgePromoCard extends StatelessWidget {
  const FounderBadgePromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authLink = context.watch<AuthLinkProvider>();
    final founderBadge = context.watch<FounderBadgeProvider>();

    if (!founderBadge.isLoaded ||
        authLink.isLinked ||
        founderBadge.isSoldOut) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: stickerDecoration(fill: colorScheme.primary, borderRadius: radius),
            child: Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 22, height: 1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.founderBadgePromoTitle,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontVariations: const [FontVariation('wght', 700)],
                          fontSize: 14,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.founderBadgePromoBody(
                          founderBadge.remainingSlots,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colorScheme.onPrimary.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: radius,
                onTap: () => handleGoogleLinkTap(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
