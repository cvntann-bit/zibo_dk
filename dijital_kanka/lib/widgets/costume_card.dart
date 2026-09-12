import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/zibo_event_signal.dart';

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
    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // Ana Sayfa'nın konuşma balonu bir SONRAKİ seçiminde bu özel kutlama
    // havuzundan bir söz gösterecek — bkz. `zibo_event_signal.dart`.
    pendingZiboEvent.value = ZiboEventType.costumeOrThemeUnlocked;

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
                Image.asset('assets/images/zibo_coin.webp', width: 16),
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
