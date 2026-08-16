import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/goals_provider.dart';

/// "En Uzun Seri Rekoru" satırının açtığı sayfa — Hedef Takibi'ndeki
/// (bkz. `GoalsProvider.longestStreak`) en uzun kesintisiz seriyi gösterir.
class LongestStreakScreen extends StatelessWidget {
  const LongestStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final longestStreak = context.watch<GoalsProvider>().longestStreak;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.longestStreakScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$longestStreak',
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.longestStreakScreenSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.longestStreakEncouragement,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
