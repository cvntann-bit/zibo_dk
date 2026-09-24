import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/app_streak_provider.dart';
import 'sticker_style.dart';

const streakFreezeIconAsset = 'assets/images/streak_freeze_icon.webp';

/// Kullanıcının Mağaza'dan aldığı Streak Freeze stoğu — Hedefler sekmesi ve
/// "En Uzun Seri Rekoru" ekranında gösterilir.
class StreakFreezeBalanceCard extends StatelessWidget {
  const StreakFreezeBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final owned = context.watch<AppStreakProvider>().ownedStreakFreezes;

    return StickerCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Image.asset(streakFreezeIconAsset, width: 44, height: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.streakFreezeBalanceTitle,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.streakFreezeBalanceHint(CoinEconomy.streakFreezeStorePrice),
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
          Text(
            '×$owned',
            key: const Key('streakFreezeBalanceCount'),
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 22,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
