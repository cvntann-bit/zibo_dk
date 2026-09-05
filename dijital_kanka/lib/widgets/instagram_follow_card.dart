import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_theme_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/instagram_follow_provider.dart';
import '../utils/badge_special_reward.dart';

/// 2026 yeni özellik — Instagram Takip Kartı ve Ödülü (bkz. CLAUDE.md).
/// Profil'de, ödül henüz alınmamışsa gösterilen bir teşvik kartı — kullanıcı
/// "Instagram'ı Aç" ile @zibo.app hesabına yönlendirilir, "Takip Ettim"e
/// basınca (gerçek takip doğrulaması teknik olarak MÜMKÜN OLMADIĞI için
/// kullanıcı BEYANINA dayalı, `InstagramFollowProvider.markClaimed()` ile
/// tek seferlik kalıcı bir bayrakla korunan) 100 ZC + rastgele bir standart
/// tema + rastgele düşük fiyatlı bir kostüm veriliyor.
///
/// **Ödül alındıktan sonra kart TAMAMEN GİZLENİR** (`SizedBox.shrink()`) —
/// kullanıcının "ara sıra gösterilsin" isteği, gerçek olasılıksal bir
/// zamanlama yerine BASİTÇE "henüz alınmadığı sürece görünür" olarak
/// yorumlandı (bkz. CLAUDE.md'deki kapsam kararı notu).
class InstagramFollowCard extends StatefulWidget {
  const InstagramFollowCard({super.key});

  @override
  State<InstagramFollowCard> createState() => _InstagramFollowCardState();
}

class _InstagramFollowCardState extends State<InstagramFollowCard> {
  bool _isClaiming = false;

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://www.instagram.com/zibo.app');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Instagram uygulaması/tarayıcı açılamadı — sessizce yok say, diğer
      // `url_launcher` kullanımlarındaki (Ayarlar > "Bize Ulaşın" vb.) AYNI
      // "başarısızlık kritik değil" felsefesi.
    }
  }

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      final marked = await context.read<InstagramFollowProvider>().markClaimed();
      // Zaten alınmış (teorik olarak — kart zaten `claimed == true` iken
      // hiç render edilmiyor, bkz. build()) — ikinci bir güvenlik katmanı.
      if (!marked || !mounted) return;
      context.read<CoinProvider>().earnInstagramFollowReward();

      final appTheme = context.read<AppThemeProvider>();
      final theme = pickRandomUnownedStandardTheme(appTheme.ownedIds);
      if (theme != null) unawaited(appTheme.markOwned(theme.id));

      final costumeProvider = context.read<CostumeProvider>();
      final costume = pickRandomUnownedLowPricedCostume(
        costumeProvider.ownedIds,
      );
      if (costume != null) unawaited(costumeProvider.markOwned(costume.id));

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.instagramFollowRewardGrantedMessage)),
        );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimed = context.watch<InstagramFollowProvider>().claimed;
    if (claimed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.instagramFollowCardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.instagramFollowCardBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openInstagram,
                    child: Text(l10n.instagramFollowOpenButton),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isClaiming ? null : _claim,
                    child: _isClaiming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.instagramFollowClaimButton),
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
