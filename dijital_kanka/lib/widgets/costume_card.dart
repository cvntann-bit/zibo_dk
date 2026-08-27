import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../models/costume_unlock_requirement.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/water_provider.dart';
import '../utils/coin_feedback.dart';

/// Mağaza > Kostümler ızgarasındaki tek bir kostüm kartı. Üç durumu var:
/// kilitli (satın alınmamış — dim görsel + kilit rozeti + "Satın Al"),
/// sahip olunan ama giyili değil ("Sahip olunan" rozeti, dokununca giyer),
/// giyili (vurgulu kenarlık + "Giyili" rozeti, dokununca çıkarır).
class CostumeCard extends StatelessWidget {
  const CostumeCard({super.key, required this.costume});

  final Costume costume;

  void _buy(BuildContext context) {
    final coins = context.read<CoinProvider>();
    if (coins.balance < costume.price) {
      showInsufficientCoinsWarning(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final localizedName = costume.localizedName(l10n);
    coins.spendOnCostume(costumeName: localizedName, cost: costume.price);
    context.read<CostumeProvider>().markOwned(costume.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.costumePurchasedMessage(localizedName))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedName = costume.localizedName(l10n);
    final colorScheme = Theme.of(context).colorScheme;
    final costumeProvider = context.watch<CostumeProvider>();
    final owned = costumeProvider.isOwned(costume.id);
    final equipped = costumeProvider.isEquipped(costume.id);
    // Kilitliyken "X yaparak ücretsiz aç" ilerlemesini göstermek için — bkz.
    // altta `_unlockProgressText`. `owned` iken bu iki provider'ı izlemenin
    // hiçbir maliyeti yok (zaten `MultiProvider` ağacında hazırlar) ama
    // yalnızca kilitli dalda KULLANILIYOR.
    final goals = context.watch<GoalsProvider>();
    final water = context.watch<WaterProvider>();

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Opacity(
                opacity: owned ? 1 : 0.45,
                child: Image.asset(
                  costume.imageAsset,
                  height: 92,
                  semanticLabel: localizedName,
                ),
              ),
              if (!owned)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizedName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (equipped)
            _Badge(
              label: l10n.costumeEquippedBadge,
              icon: Icons.check_circle,
              background: colorScheme.primary,
              foreground: colorScheme.onPrimary,
            )
          else if (owned)
            _Badge(
              label: l10n.costumeOwnedBadge,
              icon: Icons.check,
              background: colorScheme.secondaryContainer,
              foreground: colorScheme.onSecondaryContainer,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/zibo_coin.png', width: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.storeCoinAmount(costume.price),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _buy(context),
                child: Text(l10n.storeBuyButton),
              ),
            ),
            // 2026 güncellemesi — kullanıcı isteği: "hem fiyatı hem de X
            // yaparak ücretsiz aç bilgisini BİRLİKTE göster." Fiyat/buton
            // satırı DEĞİŞMİYOR, yalnızca altına kompakt bir ilerleme satırı
            // ekleniyor — bkz. `CostumeProvider.reconcileGoalUnlocks`
            // (gerçek otomatik açma, burada YALNIZCA gösterim var).
            if (costume.unlockRequirement != null) ...[
              const SizedBox(height: 6),
              Text(
                _unlockProgressText(
                  l10n,
                  costume.unlockRequirement!,
                  goals,
                  water,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: equipped
          ? BorderSide(color: colorScheme.primary, width: 2)
          : BorderSide.none,
    );

    if (!owned) {
      return Card(shape: shape, child: content);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: Semantics(
        button: true,
        label: equipped
            ? l10n.costumeUnequipSemanticLabel(localizedName)
            : l10n.costumeEquipSemanticLabel(localizedName),
        child: InkWell(
          onTap: () =>
              context.read<CostumeProvider>().toggleEquipped(costume.id),
          child: content,
        ),
      ),
    );
  }
}

/// Kilitli bir kostüm kartındaki "X yaparak ücretsiz aç" satırı — `req.type`'a
/// göre doğru provider'dan o anki ilerlemeyi okuyup doğru ARB metnini seçer.
/// `CostumeProvider.reconcileGoalUnlocks`'taki AYNI küçük `switch`'in salt
/// GÖSTERİM amaçlı bir kopyası (bkz. o metodun dokümantasyonu — bilerek
/// paylaşılan bir yardımcıya çıkarılmadı, üç satırlık bir eşleme için ayrı
/// bir soyutlama gereksiz dolaylılık eklerdi). `current`, `target`'ı
/// AŞMAYACAK şekilde kırpılıyor — `reconcileGoalUnlocks` henüz çalışmadan
/// (ör. Mağaza'ya bu turda ilk kez girilmeden) önceki tek bir karede
/// "6/5" gibi mantıksız bir görünüm olmasın diye.
String _unlockProgressText(
  AppLocalizations l10n,
  CostumeUnlockRequirement req,
  GoalsProvider goals,
  WaterProvider water,
) {
  final rawCurrent = switch (req.type) {
    CostumeUnlockType.goalStreak => goals.longestStreak,
    CostumeUnlockType.goalCompletions => goals.completions.length,
    CostumeUnlockType.waterDaysCompleted => water.completedDaysCount,
  };
  final current = rawCurrent > req.target ? req.target : rawCurrent;
  return switch (req.type) {
    CostumeUnlockType.goalStreak => l10n.costumeUnlockViaStreak(
      current,
      req.target,
    ),
    CostumeUnlockType.goalCompletions => l10n.costumeUnlockViaCompletions(
      current,
      req.target,
    ),
    CostumeUnlockType.waterDaysCompleted => l10n.costumeUnlockViaWater(
      current,
      req.target,
    ),
  };
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
