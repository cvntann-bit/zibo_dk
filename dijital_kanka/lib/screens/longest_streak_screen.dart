import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_streak_provider.dart';
import '../widgets/streak_freeze_balance_card.dart';

/// "En Uzun Seri Rekoru" satırının açtığı sayfa — uygulamayı HER GÜN açma
/// serisinin (bkz. `AppStreakProvider.longestStreakEver`) hiç azalmayan
/// rekorunu gösterir. **Faz 6 düzeltmesi** — eskiden yanlışlıkla
/// `GoalsProvider.longestStreak` okunuyordu (Hedef Takibi'nin KENDİ 7 günlük
/// döngüsü, `Goal.daysPerCycle` her tamamlandığında sıfırlanır — yapısal
/// olarak 7'yi asla geçemiyordu).
class LongestStreakScreen extends StatelessWidget {
  const LongestStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final longestStreak = context.watch<AppStreakProvider>().longestStreakEver;

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
            const StreakFreezeBalanceCard(),
            const SizedBox(height: 16),
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
