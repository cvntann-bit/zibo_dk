import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/profile_stats.dart';
import 'circular_score_gauge.dart';
import 'stat_trend_chart.dart';

/// "İstatistiklerim" bölümündeki tek bir kategori kartı — başlık + (veri
/// varsa) küçük bir trend grafiği + 0-10 dairesel puan göstergesi, (veri
/// yoksa) teşvik edici bir boş durum mesajı.
class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({super.key, required this.stat});

  final CategoryStat stat;

  /// Her kategorinin grafik çizgi rengi — dairesel gösterge rengiyle
  /// (bkz. `CircularScoreGauge`, kırmızı-yeşil skala) BİLEREK bağımsız,
  /// yalnızca kategoriyi görsel olarak ayırt etmek için.
  static const _colors = {
    ProfileStatCategory.money: Color(0xFF1E88E5),
    ProfileStatCategory.gratitudeManifest: Color(0xFF8E24AA),
    ProfileStatCategory.consistency: Color(0xFFFB8C00),
    ProfileStatCategory.selfCareHealth: Color(0xFF43A047),
  };

  static const _icons = {
    ProfileStatCategory.money: Icons.savings_outlined,
    ProfileStatCategory.gratitudeManifest: Icons.auto_awesome_outlined,
    ProfileStatCategory.consistency: Icons.flag_outlined,
    ProfileStatCategory.selfCareHealth: Icons.favorite_outline,
  };

  String _title(AppLocalizations l10n) {
    switch (stat.category) {
      case ProfileStatCategory.money:
        return l10n.profileStatMoneyTitle;
      case ProfileStatCategory.gratitudeManifest:
        return l10n.profileStatGratitudeManifestTitle;
      case ProfileStatCategory.consistency:
        return l10n.profileStatConsistencyTitle;
      case ProfileStatCategory.selfCareHealth:
        return l10n.profileStatSelfCareTitle;
    }
  }

  String _emptyMessage(AppLocalizations l10n) {
    switch (stat.category) {
      case ProfileStatCategory.money:
        return l10n.profileStatMoneyEmpty;
      case ProfileStatCategory.gratitudeManifest:
        return l10n.profileStatGratitudeManifestEmpty;
      case ProfileStatCategory.consistency:
        return l10n.profileStatConsistencyEmpty;
      case ProfileStatCategory.selfCareHealth:
        return l10n.profileStatSelfCareEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = _colors[stat.category]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons[stat.category], color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  _title(l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!stat.hasData)
              SizedBox(
                height: 72,
                child: Center(
                  child: Text(
                    _emptyMessage(l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    Expanded(
                      child: StatTrendChart(values: stat.trendPoints, color: color),
                    ),
                    const SizedBox(width: 18),
                    CircularScoreGauge(score: stat.score, size: 64),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
