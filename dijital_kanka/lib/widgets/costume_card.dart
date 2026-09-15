import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import '../utils/zibo_event_signal.dart';
import 'sticker_style.dart';

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

    showInfoDialog(context, l10n.costumePurchasedMessage(localizedName));
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
          Padding(
            // Kilit rozeti kartın DIŞINA taşıyor (mockup'ın `top:-6px;
            // right:-6px`) — üstte yeterli boşluk bırakılmazsa Stack'in
            // `clipBehavior:none` taşması bir üstteki kartla çakışır.
            padding: const EdgeInsets.only(top: 6, right: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 78,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E7CE),
                    border: Border.all(color: kStickerOutline, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Opacity(
                    opacity: owned ? 1 : 0.45,
                    child: Image.asset(
                      costume.imageAsset,
                      height: 68,
                      semanticLabel: localizedName,
                    ),
                  ),
                ),
                if (!owned)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: kStickerOutline, width: 2),
                      ),
                      child: const Text('🔒', style: TextStyle(fontSize: 11, height: 1)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (equipped)
            StickerStatusPill(label: l10n.costumeEquippedBadge, filled: true)
          else if (owned)
            StickerStatusPill(label: l10n.costumeOwnedBadge)
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/zibo_coin.webp', width: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.storeCoinAmount(costume.price),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            stickerButtonShadow(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: stickerFilledButtonStyle(context),
                  onPressed: () => _buy(context),
                  child: Text(l10n.storeBuyButton),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final decoration = stickerDecoration(
      fill: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      borderWidth: equipped ? 4 : 3,
      outline: equipped ? colorScheme.primary : kStickerOutline,
    ).copyWith(
      // Mockup'ta giyili karttaki kalın altın kontur SIRASINDA gölge yine
      // SABİT koyu renkte kalıyor (`stickerDecoration`'ın `outline` param'ı
      // ikisini birden değiştirdiği için burada gölge ELLE koyu renge geri
      // döndürülüyor).
      boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(4, 4))],
    );

    final radius = BorderRadius.circular(16);
    // Dıştaki `Card` GÖRSEL OLARAK şeffaf (gerçek dolgu/kontur/gölge içteki
    // `Container`'dan geliyor) — SADECE `widget_test.dart`'ın onlarca yerde
    // kullandığı `find.ancestor(..., matching: find.byType(Card))` deseni
    // bozulmasın diye korunuyor (bkz. `hippiCard`/`kingCard` vb.).
    if (!owned) {
      return Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
        child: Container(decoration: decoration, child: content),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(decoration: decoration, child: content),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Semantics(
                button: true,
                label: equipped
                    ? l10n.costumeUnequipSemanticLabel(localizedName)
                    : l10n.costumeEquipSemanticLabel(localizedName),
                child: InkWell(
                  borderRadius: radius,
                  onTap: () =>
                      context.read<CostumeProvider>().toggleEquipped(costume.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
