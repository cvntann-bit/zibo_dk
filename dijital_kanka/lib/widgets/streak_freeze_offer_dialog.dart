import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/app_streak_provider.dart';
import '../providers/coin_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';

/// **Faz 4 (B3)** — kullanıcı TAM 1 gün kaçırıp uygulamayı açtığında
/// (`AppStreakProvider.isStreakAtRisk`), `RootScreen` bu diyaloğu
/// `recordOpenForToday()` çağırmadan ÖNCE gösterir. Zibo Pro/Pro+ ise önce
/// aylık ücretsiz hak sunulur (`remainingFreeStreakFreezes`); yoksa (veya
/// free kullanıcıysa) `CoinEconomy.streakFreeze` (80 ZC) karşılığı satın
/// alma seçeneği sunulur. "Vazgeç" seçilirse (veya kapatılırsa) hiçbir şey
/// değişmez — `RootScreen` ardından normal `recordOpenForToday()`'i çağırıp
/// seriyi 1'e sıfırlar.
class StreakFreezeOfferDialog extends StatelessWidget {
  const StreakFreezeOfferDialog({super.key});

  Future<void> _useFreeFreeze(BuildContext context) async {
    final streak = context.read<AppStreakProvider>();
    final l10n = AppLocalizations.of(context)!;
    final newStreak = streak.currentStreak + 1;
    streak.repairMissedDayWithFreeze(usedFreeQuota: true);
    Navigator.of(context).pop();
    await showInfoDialog(context, l10n.streakFreezeRepairedMessage(newStreak));
  }

  Future<void> _useCoins(BuildContext context) async {
    final coins = context.read<CoinProvider>();
    if (coins.balance < CoinEconomy.streakFreeze) {
      showInsufficientCoinsWarning(context);
      return;
    }
    final streak = context.read<AppStreakProvider>();
    final l10n = AppLocalizations.of(context)!;
    final success = coins.spendStreakFreeze();
    if (!success) {
      showInsufficientCoinsWarning(context);
      return;
    }
    final newStreak = streak.currentStreak + 1;
    streak.repairMissedDayWithFreeze(usedFreeQuota: false);
    Navigator.of(context).pop();
    await showInfoDialog(context, l10n.streakFreezeRepairedMessage(newStreak));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final streak = context.watch<AppStreakProvider>();
    final remainingFree = streak.remainingFreeStreakFreezes;
    final quota = streak.freeStreakFreezeQuota;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.streakFreezeOfferTitle),
        content: Text(l10n.streakFreezeOfferBody(streak.currentStreak)),
        actions: [
          TextButton(
            key: const Key('streakFreezeDeclineButton'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.streakFreezeOfferDeclineButton),
          ),
          if (remainingFree > 0)
            FilledButton(
              key: const Key('streakFreezeUseFreeButton'),
              onPressed: () => _useFreeFreeze(context),
              child: Text(
                l10n.streakFreezeOfferFreeButton(remainingFree, quota),
              ),
            )
          else
            FilledButton(
              key: const Key('streakFreezeUseCoinsButton'),
              onPressed: () => _useCoins(context),
              child: Text(
                l10n.streakFreezeOfferCoinButton(CoinEconomy.streakFreeze),
              ),
            ),
        ],
      ),
    );
  }
}
