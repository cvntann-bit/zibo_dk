import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_provider.dart';

/// "Zibo Coin Özeti" satırının açtığı sayfa — şimdiye kadar kazanılan ve
/// harcanan TOPLAM Zibo Coin miktarını gösterir (bkz.
/// `CoinProvider.totalEarned`/`totalSpent`, işlem geçmişinden BAĞIMSIZ,
/// hiç budanmayan ömür boyu sayaçlar).
class CoinSummaryScreen extends StatelessWidget {
  const CoinSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coin = context.watch<CoinProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coinSummaryScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _CoinSummaryCard(
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF43A047),
              label: l10n.coinSummaryTotalEarnedLabel,
              amount: coin.totalEarned,
            ),
            const SizedBox(height: 16),
            _CoinSummaryCard(
              icon: Icons.trending_down_rounded,
              color: const Color(0xFFE53935),
              label: l10n.coinSummaryTotalSpentLabel,
              amount: coin.totalSpent,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinSummaryCard extends StatelessWidget {
  const _CoinSummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Icon(icon, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.coinSummaryAmount(amount),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
