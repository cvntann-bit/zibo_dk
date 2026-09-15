import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_theme_option.dart';
import '../providers/app_theme_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import '../utils/zibo_event_signal.dart';
import 'starry_gradient_background.dart';
import 'sticker_style.dart';
import 'theme_particle_effect.dart';

/// Mağaza > Temalar ızgarasındaki tek bir tema kartı. `CostumeCard` ile
/// BİREBİR AYNI üç durum mantığı (kilitli / sahip olunan ama aktif değil /
/// aktif) — yalnızca görsel önizleme bir `Image.asset` değil, temanın o an
/// açık/koyu moda göre doğru gradyanını gösteren küçük bir kutu.
class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({super.key, required this.theme});

  final AppThemeOption theme;

  void _buy(BuildContext context) {
    final coins = context.read<CoinProvider>();
    if (coins.balance < theme.price) {
      showInsufficientCoinsWarning(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final localizedName = theme.localizedName(l10n);
    coins.spendOnTheme(themeName: localizedName, cost: theme.price);
    context.read<AppThemeProvider>().markOwned(theme.id);
    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // Ana Sayfa'nın konuşma balonu bir SONRAKİ seçiminde bu özel kutlama
    // havuzundan bir söz gösterecek — bkz. `zibo_event_signal.dart`.
    pendingZiboEvent.value = ZiboEventType.costumeOrThemeUnlocked;

    showInfoDialog(context, l10n.themePurchasedMessage(localizedName));
  }

  /// Önizleme kutusunun içine bindirilecek dekoratif katman — en fazla
  /// BİRİ geçerli olabilir (statik yıldız desenİ SADECE "Gece Gökyüzü" için,
  /// canlı-görünen ama burada SABİT parçacık önizlemesi SADECE Premium/
  /// Animasyonlu temalar için). `AlwaysStoppedAnimation` asla
  /// `notifyListeners` tetiklemediği için bu önizleme Mağaza'nın tüm
  /// kartlarında AÇIK kalsa bile hiçbir ekstra animasyon/CPU maliyeti
  /// getirmiyor (bkz. `ThemeParticleEffect` dokümantasyonu).
  Widget? _previewOverlay(bool isDark) {
    if (theme.isStarryInDark && isDark) {
      return const StarryGradientBackground(child: SizedBox.expand());
    }
    if (theme.isPremiumAnimated) {
      return ThemeParticleEffect(
        type: theme.animationType,
        progress: const AlwaysStoppedAnimation(0.35),
        isDark: isDark,
        // Küçük kart önizlemesi için canlı kaplamadaki varsayılanların
        // (bkz. ThemeParticleEffect.build) kabaca yarısı — statik olduğu
        // için performans önemli değil, sadece görsel olarak taşmasın diye.
        particleCount: switch (theme.animationType) {
          ThemeAnimationType.confetti => 10,
          ThemeAnimationType.petals => 12,
          ThemeAnimationType.tropical => 10,
          _ => 14,
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedName = theme.localizedName(l10n);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final appThemeProvider = context.watch<AppThemeProvider>();
    final owned = appThemeProvider.isOwned(theme.id);
    final active = appThemeProvider.isEquipped(theme.id);
    final previewColors = theme.colorsFor(isDark);

    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Opacity(
          opacity: owned ? 1 : 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: previewColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _previewOverlay(isDark),
          ),
        ),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Kilit/Premium rozetleri kartın DIŞINA taşıyor (mockup'ın
            // `top:-6px`) — bkz. `CostumeCard`'daki AYNI desen.
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: kStickerOutline, width: 2),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: preview,
                ),
                if (theme.isPremiumAnimated)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: kStickerOutline, width: 2),
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 10, height: 1)),
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
          if (active)
            StickerStatusPill(label: l10n.themeActiveBadge, filled: true)
          else if (owned)
            StickerStatusPill(label: l10n.themeOwnedBadge)
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/zibo_coin.webp', width: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.storeCoinAmount(theme.price),
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
      borderWidth: active ? 4 : 3,
      outline: active ? colorScheme.primary : kStickerOutline,
    ).copyWith(
      // Mockup'ta aktif karttaki kalın altın kontur SIRASINDA gölge yine
      // SABİT koyu renkte kalıyor (bkz. `CostumeCard`'daki AYNI not).
      boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(4, 4))],
    );

    final radius = BorderRadius.circular(16);
    // Dıştaki `Card` GÖRSEL OLARAK şeffaf — SADECE `widget_test.dart`'ın
    // `find.ancestor(..., matching: find.byType(Card))` deseni (bkz.
    // `kingCard`/`sunsetCard`/`winterCard`) bozulmasın diye korunuyor.
    if (!owned) {
      return Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
        child: Semantics(
          label: l10n.themeLockedSemanticLabel(localizedName, theme.price),
          child: Container(decoration: decoration, child: content),
        ),
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
                label: active
                    ? l10n.themeRemoveSemanticLabel(localizedName)
                    : l10n.themeApplySemanticLabel(localizedName),
                child: InkWell(
                  borderRadius: radius,
                  onTap: () =>
                      context.read<AppThemeProvider>().toggleEquipped(theme.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
