import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_themes.dart';
import '../data/coin_packages.dart';
import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/app_theme_option.dart';
import '../models/coin_economy.dart';
import '../models/coin_package.dart';
import '../providers/coin_provider.dart';
import '../utils/ad_free_promo_trigger.dart';
import '../widgets/ad_free_promo_sheet.dart';
import '../widgets/costume_card.dart';
import '../widgets/theme_option_card.dart';

/// Mağaza'nın üç segmenti — dışarıdan (ör. Profil > Kostüm Dolabı
/// önizlemesi) doğrudan bir segmentle açılabilmesi için public.
enum StoreSection { coins, costumes, themes }

/// Zibo Coin satın alma ve kostüm mağazası. Alt gezinme çubuğundaki
/// "Mağaza" sekmesi ve başlık çubuğundaki '+' ikonu (aynı sekmeye geçer)
/// buraya götürür; diğer sekmeler gibi RootScreen'in ortak başlık çubuğunu
/// paylaşır, kendi Scaffold/AppBar'ı yoktur.
///
/// İki segment tek sayfada birleşiyor (ayrı bir alt gezinme sekmesi/sayfa
/// yerine): "coin satın alma" ve "coin harcama" akışları aynı girişten
/// (Mağaza) doğal olarak ulaşılabilir kalsın, alt gezinme çubuğu da 4 öğede
/// sabit kalsın diye.
class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    this.initialSection = StoreSection.coins,
    this.isActive = true,
  });

  /// Profil > Kostüm Dolabı önizlemesi gibi yerlerden doğrudan "Kostümler"
  /// segmentiyle açılabilmesi için — varsayılan davranış (Mağaza sekmesi/'+'
  /// ikonu) DEĞİŞMEDİ, hep "Coin Al" ile açılır.
  final StoreSection initialSection;

  /// Bu sekmenin şu anda görünen sekme olup olmadığı — `GoalTrackingScreen`
  /// ile AYNI desen (bkz. `RootScreen`'in `IndexedStack`'i, sekmeler hiç
  /// unmount edilmiyor). "Zibo ADS" tanıtım sheet'inin (bkz.
  /// `ad_free_promo_sheet.dart`) HER Mağaza ziyaretinde (ilk mount'ta değil,
  /// her sekmeye GEÇİŞTE) tetiklenebilmesi için gerekli. `costume_closet_
  /// preview.dart` gibi Mağaza'yı push edilen AYRI bir sayfa olarak açan
  /// yerlerde varsayılan `true` yeterli (o bağlamda zaten tek başına
  /// görünüyor).
  final bool isActive;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late StoreSection _section = widget.initialSection;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _maybeShowAdFreePromo();
  }

  @override
  void didUpdateWidget(covariant StoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _maybeShowAdFreePromo();
  }

  /// Görsel mockup tanıtımı (bkz. CLAUDE.md "Zibo ADS" bölümü) — her Mağaza
  /// ziyaretinde DEĞİL, `AdFreePromoTrigger`'ın basit sayacına göre ARA SIRA
  /// gösterilir. `addPostFrameCallback` ile ertelendi çünkü `initState`/
  /// `didUpdateWidget` sırasında henüz build tamamlanmadan `showModalBottomSheet`
  /// çağırmak (özellikle `didUpdateWidget`'ta, bir üst widget'ın kendi
  /// build'i sürerken) güvenli değil.
  void _maybeShowAdFreePromo() {
    if (!AdFreePromoTrigger.shouldShowOnStoreVisit()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAdFreePromoSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(l10n.storeTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<StoreSection>(
          segments: [
            ButtonSegment(
              value: StoreSection.coins,
              label: Text(l10n.storeCoinsTabLabel),
            ),
            ButtonSegment(
              value: StoreSection.costumes,
              label: Text(l10n.storeCostumesTabLabel),
            ),
            ButtonSegment(
              value: StoreSection.themes,
              label: Text(l10n.storeThemesTabLabel),
            ),
          ],
          selected: {_section},
          onSelectionChanged: (selection) =>
              setState(() => _section = selection.first),
        ),
        const SizedBox(height: 20),
        switch (_section) {
          StoreSection.coins => const _BuyCoinsSection(),
          StoreSection.costumes => const _CostumesSection(),
          StoreSection.themes => const _ThemesSection(),
        },
      ],
    );
  }
}

class _BuyCoinsSection extends StatelessWidget {
  const _BuyCoinsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.storeFreeSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const _WatchAdCard(),
        const SizedBox(height: 24),
        Text(
          l10n.storePackagesSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (final package in coinPackages) _PackageCard(package: package),
          ],
        ),
      ],
    );
  }
}

class _CostumesSection extends StatelessWidget {
  const _CostumesSection();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Kilitli kartlar (görsel + isim + fiyat + "Satın Al" butonu) sahip
      // olunan kartlardan (görsel + isim + rozet) daha uzun — en uzun durumu
      // taşırmayacak kadar düşük bir oran seçildi.
      childAspectRatio: 0.66,
      children: [
        for (final costume in costumes) CostumeCard(costume: costume),
      ],
    );
  }
}

class _ThemesSection extends StatelessWidget {
  const _ThemesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // Standart (statik gradyan) vs Premium/Animasyonlu (bkz.
    // AppThemeOption.isPremiumAnimated) — AYRI bölümlerde, kullanıcı
    // isteğiyle ("bu animasyonlu temaları ayrı bir bölüm altında göster").
    final standardThemes = appThemes
        .where((theme) => !theme.isPremiumAnimated)
        .toList();
    final premiumThemes = appThemes
        .where((theme) => theme.isPremiumAnimated)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.storeThemesStandardSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _ThemesGrid(themes: standardThemes),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              l10n.storeThemesPremiumSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.storeThemesPremiumSectionSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _ThemesGrid(themes: premiumThemes),
      ],
    );
  }
}

class _ThemesGrid extends StatelessWidget {
  const _ThemesGrid({required this.themes});

  final List<AppThemeOption> themes;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Kilitli/sahip olunan kartların en uzun içeriği (isim + fiyat/rozet
      // satırı + buton) taşırmayacak kadar düşük bir oran (bkz. CostumeCard/
      // manifest geçmiş kartlarındaki aynı overflow dersi).
      childAspectRatio: 0.62,
      children: [for (final theme in themes) ThemeOptionCard(theme: theme)],
    );
  }
}

void _showCoinsAddedSnackBar(BuildContext context, int amount) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.storeCoinsAdded(amount))));
}

class _WatchAdCard extends StatefulWidget {
  const _WatchAdCard();

  @override
  State<_WatchAdCard> createState() => _WatchAdCardState();
}

class _WatchAdCardState extends State<_WatchAdCard> {
  bool _loading = false;

  Future<void> _watchAd(BuildContext context) async {
    setState(() => _loading = true);
    final rewarded = await context.read<CoinProvider>().earnAdWatch();
    if (!mounted) return;
    setState(() => _loading = false);
    if (rewarded && context.mounted) {
      _showCoinsAddedSnackBar(context, CoinEconomy.adWatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.smart_display_outlined,
              size: 36,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.storeWatchAdTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.storeWatchAdSubtitle(CoinEconomy.adWatch),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _loading ? null : () => _watchAd(context),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.storeWatchAdButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  const _PackageCard({required this.package});

  final CoinPackage package;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _loading = false;

  Future<void> _buy(BuildContext context) async {
    setState(() => _loading = true);
    final success = await context.read<CoinProvider>().purchaseCoinPackage(
      widget.package,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success && context.mounted) {
      _showCoinsAddedSnackBar(context, widget.package.coinAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.package.imageAsset, width: 48, height: 48),
            const SizedBox(height: 8),
            Text(
              l10n.storeCoinAmount(widget.package.coinAmount),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : () => _buy(context),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.package.price?.formatted ?? l10n.storeBuyButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
