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
///
/// Görsel: uygulamadaki HER dialog (`wheelResultTitle`, `showInfoDialog` vb.)
/// bilerek düz `AlertDialog` kabuğu kullanıyor — buradaki "Çizgi Roman
/// Çıkartması" teması bu YÜZDEN dialog'un kendi ÇERÇEVESİNE (sticker
/// border/gölge) DEĞİL, İÇERİĞİNE uygulanıyor: `streak_freeze_icon.webp`
/// (Zibo Pro+ materyalleri) + Baloo2 başlık tipografisi, ekranlardaki
/// kartlarla AYNI dil.
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
    final colorScheme = Theme.of(context).colorScheme;
    final streak = context.watch<AppStreakProvider>();
    final remainingFree = streak.remainingFreeStreakFreezes;
    final quota = streak.freeStreakFreezeQuota;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/streak_freeze_icon.webp', width: 88),
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
        content: Text(
          l10n.streakFreezeOfferBody(streak.currentStreak),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.4,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // `SizedBox(width: double.infinity)` — `OverflowBar`'ın (AlertDialog
          // actions'ın varsayılan yerleşimi) birden fazla sonsuz-genişlikli
          // çocuğu YAN YANA sığdıramayıp otomatik ALT ALTA dizmesinden
          // yararlanıyor: iki tam-genişlik buton, "Vazgeç"i küçük bir metin
          // butonu olarak sıkıştırmak yerine.
          SizedBox(
            width: double.infinity,
            child: remainingFree > 0
                ? FilledButton(
                    key: const Key('streakFreezeUseFreeButton'),
                    onPressed: () => _useFreeFreeze(context),
                    child: Text(
                      l10n.streakFreezeOfferFreeButton(remainingFree, quota),
                    ),
                  )
                : FilledButton(
                    key: const Key('streakFreezeUseCoinsButton'),
                    onPressed: () => _useCoins(context),
                    child: Text(
                      l10n.streakFreezeOfferCoinButton(CoinEconomy.streakFreeze),
                    ),
                  ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: const Key('streakFreezeDeclineButton'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.streakFreezeOfferDeclineButton),
            ),
          ),
        ],
      ),
    );
  }
}
