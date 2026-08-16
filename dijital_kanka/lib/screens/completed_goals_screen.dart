import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/goal_completion.dart';
import '../providers/goals_provider.dart';

const _turkishMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_turkishMonths[date.month - 1]} ${date.year}';

/// Tamamlanan tüm 7 günlük hedef döngülerini hedef ADINA göre gruplayıp
/// gösteren ekran — `GoalTrackingScreen`'in aksine sekme değil, Hedefler
/// sekmesindeyken başlık çubuğunda beliren bir kupa ikonundan push edilir
/// (bkz. `RootScreen`). Her grup kendi tamamlanma kayıtlarını taşır, hedefler
/// birbirine karışmaz (bkz. CLAUDE.md "Hedefler" 2026 güncellemesi).
class CompletedGoalsScreen extends StatelessWidget {
  const CompletedGoalsScreen({super.key});

  Map<String, List<GoalCompletion>> _groupByGoalName(
    List<GoalCompletion> completions,
  ) {
    // `completions` zaten en yeni en üstte sıralı geliyor (bkz.
    // GoalsProvider.completions) — bu sırayla eklemek hem grup İÇİ sırayı
    // (en yeni tamamlama üstte) hem grupların KENDİ sırasını (en son
    // tamamlanan hedef grubu en üstte) otomatik doğru verir, `Map` ekleme
    // sırasını koruduğu için ayrı bir sıralamaya gerek yok.
    final grouped = <String, List<GoalCompletion>>{};
    for (final completion in completions) {
      grouped.putIfAbsent(completion.goalName, () => []).add(completion);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final completions = context.watch<GoalsProvider>().completions;
    final grouped = _groupByGoalName(completions);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.completedGoalsScreenTitle)),
      body: SafeArea(
        child: completions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    l10n.completedGoalsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final entry in grouped.entries) ...[
                    _GoalCompletionGroup(goalName: entry.key, completions: entry.value),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Tek bir hedefin adı altında gruplanmış tamamlanma kayıtları — başlık
/// (hedef adı + kaç kez tamamlandığı) + her tamamlanma için bir satır.
class _GoalCompletionGroup extends StatelessWidget {
  const _GoalCompletionGroup({required this.goalName, required this.completions});

  final String goalName;
  final List<GoalCompletion> completions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goalName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.completedGoalsGroupCount(completions.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < completions.length; i++) ...[
              _GoalCompletionRow(completion: completions[i]),
              if (i < completions.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tek bir tamamlanma kaydı: "1 haftalık tamamlama" rozeti + tarih aralığı.
class _GoalCompletionRow extends StatelessWidget {
  const _GoalCompletionRow({required this.completion});

  final GoalCompletion completion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 14, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                l10n.completedGoalsBadgeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.completedGoalsDateRange(
                _formatDate(completion.cycleStartDate),
                _formatDate(completion.completionDate),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
