import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_theme_option.dart';
import '../providers/app_theme_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/coin_feedback.dart';
import '../utils/zibo_event_signal.dart';
import 'starry_gradient_background.dart';
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.themePurchasedMessage(localizedName))),
      );
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
      borderRadius: BorderRadius.circular(14),
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
          Stack(
            alignment: Alignment.topRight,
            children: [
              preview,
              if (theme.isPremiumAnimated)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (!owned)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
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
          if (active)
            _Badge(
              label: l10n.themeActiveBadge,
              icon: Icons.check_circle,
              background: colorScheme.primary,
              foreground: colorScheme.onPrimary,
            )
          else if (owned)
            _Badge(
              label: l10n.themeOwnedBadge,
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
                  l10n.storeCoinAmount(theme.price),
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
      side: active
          ? BorderSide(color: colorScheme.primary, width: 2)
          : BorderSide.none,
    );

    if (!owned) {
      return Card(
        shape: shape,
        child: Semantics(
          label: l10n.themeLockedSemanticLabel(localizedName, theme.price),
          child: content,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: Semantics(
        button: true,
        label: active
            ? l10n.themeRemoveSemanticLabel(localizedName)
            : l10n.themeApplySemanticLabel(localizedName),
        child: InkWell(
          onTap: () =>
              context.read<AppThemeProvider>().toggleEquipped(theme.id),
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
