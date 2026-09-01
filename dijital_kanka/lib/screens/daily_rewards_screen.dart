import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../utils/zibo_event_signal.dart';

/// Günlük Giriş Ödülleri popup'ı — `WheelScreen`'in aksine tam ekran DEĞİL,
/// ortada küçük bir `Dialog` (kullanıcı isteği: "ortada bir popup açılsın").
/// 7 gün kutucuğu + üstte o anki durumu (bugünün ödülü hazır mı/alındı mı)
/// özetleyen bir metin gösterir; `context.watch` ile provider'ı doğrudan
/// izlediği için bir gün kutusuna dokunulunca TÜM içerik (durum metni +
/// kutucuk) anında güncellenir, ayrı bir state yönetimine gerek yok.
class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Popup her açıldığında bir kez daha reconcile et — uygulama arka
    // plana hiç alınmadan gün değiştiyse (nadir ama olası bir uç durum)
    // bile grid'in doğru günü göstermesini garantiler.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DailyRewardsProvider>().reconcileForToday();
    });
  }

  void _claimDay(BuildContext context, int index) {
    final provider = context.read<DailyRewardsProvider>();
    final amount = provider.claimToday();
    if (amount == null) return;
    final coin = context.read<CoinProvider>();
    coin.earnDailyLoginReward(amount);
    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // 7 günlük döngünün SON günü (index 6 = "Gün 7", en büyük tek günlük
    // ödül) alınınca Ana Sayfa'nın konuşma balonu bir SONRAKİ seçiminde
    // ayrı, daha coşkulu bir "seri bonusu" mesajı gösterecek — bkz.
    // `zibo_event_signal.dart`.
    if (index == 6) pendingZiboEvent.value = ZiboEventType.loginStreakBonus;
    // Kullanıcı isteği: günlük giriş ödülü alınınca geçilebilir (interstitial,
    // ÖDÜLLÜ DEĞİL) bir reklam gösterilsin — HomeScreen'in art arda dokunma
    // reklamıyla (bkz. `_showRapidTapPromoOrAd`) AYNI `CoinProvider.
    // showInterstitialAd()` çağrısı; coin bakiyesini/işlem geçmişini HİÇ
    // etkilemiyor, günde en fazla bir kez tetiklenir (ödül zaten günde bir
    // kez alınabildiği için).
    unawaited(coin.showInterstitialAd());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<DailyRewardsProvider>();
    final todayAmount = provider.todayAmount;

    final String statusMessage;
    if (provider.isTodayClaimed) {
      final claimedAmount =
          CoinEconomy.dailyLoginRewards[provider.todayIndex];
      statusMessage = l10n.dailyRewardsAlreadyClaimedToday(claimedAmount);
    } else if (todayAmount != null) {
      statusMessage = l10n.dailyRewardsPromptToday(
        provider.todayIndex + 1,
        todayAmount,
      );
    } else {
      // todayIndex geçici olarak aralık dışında (reconcile henüz
      // çalışmadıysa) — bir sonraki frame'de reconcile edilip düzelecek.
      statusMessage = '';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dailyRewardsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.dailyRewardsCloseTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey(statusMessage),
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var index = 0; index < CoinEconomy.dailyLoginRewards.length; index++)
                  _DayRewardBox(
                    dayNumber: index + 1,
                    amount: CoinEconomy.dailyLoginRewards[index],
                    status: provider.statusForIndex(index),
                    onTap: () => _claimDay(context, index),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRewardBox extends StatelessWidget {
  const _DayRewardBox({
    required this.dayNumber,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  final int dayNumber;
  final int amount;
  final DailyRewardDayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final String semanticLabel;
    final Color background;
    final Color foreground;
    final Color borderColor;
    final Widget statusIcon;

    switch (status) {
      case DailyRewardDayStatus.claimed:
        semanticLabel = l10n.dailyRewardsClaimedSemanticLabel(dayNumber, amount);
        background = colorScheme.primary;
        foreground = colorScheme.onPrimary;
        borderColor = colorScheme.primary;
        statusIcon = Icon(Icons.check_circle, size: 20, color: foreground);
      case DailyRewardDayStatus.today:
        semanticLabel = l10n.dailyRewardsClaimSemanticLabel(dayNumber, amount);
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        borderColor = colorScheme.primary;
        statusIcon = Icon(Icons.card_giftcard_rounded, size: 20, color: foreground);
      case DailyRewardDayStatus.upcoming:
        semanticLabel = l10n.dailyRewardsLockedSemanticLabel(dayNumber, amount);
        background = Colors.transparent;
        foreground = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        borderColor = colorScheme.outlineVariant;
        statusIcon = Icon(Icons.lock_outline, size: 18, color: foreground);
    }

    final isTappable = status == DailyRewardDayStatus.today;

    return Semantics(
      label: semanticLabel,
      button: isTappable,
      // İçerideki Text'lerin (gün numarası + tutar) kendi otomatik ürettiği
      // semantics dıştaki `label`la BİRLEŞİP birleşik/gürültülü bir etikete
      // dönüşmesin diye — bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümündeki
      // aynı gotcha.
      excludeSemantics: true,
      child: InkWell(
        onTap: isTappable ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 92,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: status != DailyRewardDayStatus.upcoming
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.dailyRewardsDayLabel(dayNumber),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              statusIcon,
              const SizedBox(height: 4),
              Text(
                l10n.storeCoinAmount(amount),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
