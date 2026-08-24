import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/monthly_stats_snapshot.dart';
import '../providers/profile_stats_archive_provider.dart';
import '../utils/profile_stats.dart';

/// Profil'deki "Geçmiş Ay İstatistikleri" satırının açtığı sayfa — arşivlenmiş
/// her ayı (en yeni en üstte) dört kategorinin o aydaki puanıyla listeler
/// (bkz. `ProfileStatsArchiveProvider` dokümantasyonu — canlı rolling-window
/// hesaplamadan bağımsız, ay değişiminde alınan bir anlık görüntü).
class MonthlyStatsHistoryScreen extends StatelessWidget {
  const MonthlyStatsHistoryScreen({super.key});

  static String statTitle(AppLocalizations l10n, ProfileStatCategory category) {
    switch (category) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final snapshots = context.watch<ProfileStatsArchiveProvider>().snapshots;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.monthlyStatsScreenTitle)),
      body: SafeArea(
        child: snapshots.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.monthlyStatsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                itemCount: snapshots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _MonthlySnapshotCard(snapshot: snapshots[index], locale: locale),
              ),
      ),
    );
  }
}

class _MonthlySnapshotCard extends StatelessWidget {
  const _MonthlySnapshotCard({required this.snapshot, required this.locale});

  final MonthlyStatsSnapshot snapshot;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final monthName = monthNamesForLocale(locale)[snapshot.month - 1];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName ${snapshot.year}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final category in ProfileStatCategory.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(MonthlyStatsHistoryScreen.statTitle(l10n, category)),
                    Text(
                      snapshot.scoreFor(category)?.toStringAsFixed(1) ?? '–',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: snapshot.scoreFor(category) != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
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
