import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/profile_stats.dart';
import 'circular_score_gauge.dart';
import 'stat_trend_chart.dart';
import 'sticker_style.dart';

/// "İstatistiklerim" bölümündeki tek bir kategori kartı — başlık + (veri
/// varsa) küçük bir trend grafiği + 0-10 dairesel puan göstergesi, (veri
/// yoksa) teşvik edici bir boş durum mesajı.
class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({super.key, required this.stat});

  final CategoryStat stat;

  /// 2026-09-15 tek-vurgu güncellemesi — kategoriler artık renkle DEĞİL
  /// yalnızca emoji ile ayırt ediliyor (bkz. `docs/theme_new.md` "Onaylanan:
  /// Profil sekmesi"); grafik/gösterge rengi de HER kategoride aynı altın
  /// (`colorScheme.primary`).
  static const _emoji = {
    ProfileStatCategory.money: '💰',
    ProfileStatCategory.gratitudeManifest: '✨',
    ProfileStatCategory.consistency: '🚩',
    ProfileStatCategory.selfCareHealth: '❤️',
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: stickerCircleDecoration(
                  fill: colorScheme.primary,
                  borderWidth: 2.5,
                  shadowOffset: Offset.zero,
                ),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Text(
                      _emoji[stat.category]!,
                      style: const TextStyle(fontSize: 13, height: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                _title(l10n),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!stat.hasData)
            SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  _emptyMessage(l10n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: StatTrendChart(
                      values: stat.trendPoints,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 18),
                  CircularScoreGauge(score: stat.score, size: 52),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
