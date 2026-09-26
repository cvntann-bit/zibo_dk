import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/app_streak_provider.dart';
import '../providers/coin_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import 'streak_freeze_balance_card.dart' show streakFreezeIconAsset;

/// Dün kaçırılan günü kurtarma teklifi. `RootScreen` her açılışta/öne
/// gelişte, iki provider da yüklendikten SONRA gösterir: "Zibo'yu açma"
/// serisi risk altındaysa ([appStreakAtRisk]) ve/veya dünü işaretlenmemiş
/// hedefler varsa ([atRiskGoalNames]). TEK bir Streak Freeze dünü HER YERDE
/// kurtarır — iki ayrı pencere/iki ayrı ödeme yok.
///
/// Ana buton sırasıyla ilk mevcut kaynağı sunar: (1) Pro/Pro+ aylık ücretsiz
/// hak, (2) Mağaza stoğu, (3) anında `CoinEconomy.streakFreezeInstantRepair`
/// ZC. Kullanılırsa `true`, "Vazgeç" seçilirse `false` döner; hedeflerin
/// dondurulması/sıfırlanması `RootScreen`'de `GoalsProvider.
/// resolveYesterdayFreeze` ile yapılır.
class StreakFreezeOfferDialog extends StatelessWidget {
  const StreakFreezeOfferDialog({
    super.key,
    this.appStreakAtRisk = true,
    this.atRiskGoalNames = const [],
  });

  final bool appStreakAtRisk;
  final List<String> atRiskGoalNames;

  bool _consume(AppStreakProvider streak, StreakFreezeSource source) => appStreakAtRisk
      ? streak.repairMissedDayWithFreeze(source: source)
      : streak.consumeFreezeForGoals(source: source);

  Future<void> _accept(BuildContext context, StreakFreezeSource source) async {
    final streak = context.read<AppStreakProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (source == StreakFreezeSource.coins) {
      final coins = context.read<CoinProvider>();
      if (coins.balance < CoinEconomy.streakFreezeInstantRepair || !coins.spendStreakFreeze()) {
        showInsufficientCoinsWarning(context);
        return;
      }
    }
    final newStreak = streak.currentStreak + 1;
    if (!_consume(streak, source)) return;
    final navigator = Navigator.of(context);
    navigator.pop(true);
    await showInfoDialog(
      navigator.context,
      appStreakAtRisk
          ? l10n.streakFreezeRepairedMessage(newStreak)
          : l10n.streakFreezeGoalsRepairedMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final streak = context.watch<AppStreakProvider>();
    final remainingFree = streak.remainingFreeStreakFreezes;
    final quota = streak.freeStreakFreezeQuota;
    final owned = streak.ownedStreakFreezes;
    final goals = atRiskGoalNames.join(', ');

    final body = appStreakAtRisk
        ? [
            l10n.streakFreezeOfferBody(streak.currentStreak),
            if (atRiskGoalNames.isNotEmpty) l10n.streakFreezeOfferGoalsLine(goals),
          ].join('\n\n')
        : l10n.streakFreezeOfferGoalsOnlyBody(goals);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(streakFreezeIconAsset, width: 88),
            const SizedBox(height: 14),
            Text(
              l10n.streakFreezeOfferTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: 19,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // `SizedBox(width: double.infinity)` — `OverflowBar`'ın birden fazla
          // sonsuz-genişlikli çocuğu otomatik ALT ALTA dizmesinden yararlanıyor.
          SizedBox(
            width: double.infinity,
            child: remainingFree > 0
                ? FilledButton(
                    key: const Key('streakFreezeUseFreeButton'),
                    onPressed: () => _accept(context, StreakFreezeSource.freeQuota),
                    child: Text(l10n.streakFreezeOfferFreeButton(remainingFree, quota)),
                  )
                : owned > 0
                ? FilledButton(
                    key: const Key('streakFreezeUseOwnedButton'),
                    onPressed: () => _accept(context, StreakFreezeSource.owned),
                    child: Text(l10n.streakFreezeOfferOwnedButton(owned)),
                  )
                : FilledButton(
                    key: const Key('streakFreezeUseCoinsButton'),
                    onPressed: () => _accept(context, StreakFreezeSource.coins),
                    child: Text(
                      l10n.streakFreezeOfferCoinButton(CoinEconomy.streakFreezeInstantRepair),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const Key('streakFreezeDeclineButton'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.streakFreezeOfferDeclineButton),
            ),
          ),
        ],
      ),
    );
  }
}
