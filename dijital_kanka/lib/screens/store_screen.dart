import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_themes.dart';
import '../data/coin_packages.dart';
import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/app_theme_option.dart';
import '../models/coin_economy.dart';
import '../models/coin_package.dart';
import '../providers/auth_link_provider.dart';
import '../providers/coin_provider.dart';
import '../utils/ad_free_promo_trigger.dart';
import '../widgets/ad_free_promo_sheet.dart';
import '../widgets/costume_card.dart';
import '../widgets/google_link_promo_sheet.dart';
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
        // 2026 güncellemesi — kullanıcı isteği: "Zibo ADS" (reklamsız
        // deneyim) yalnızca ARA SIRA çıkan bir tanıtım popup'ı (bkz.
        // `AdFreePromoTrigger`/`StoreScreen._maybeShowAdFreePromo`) değil,
        // kullanıcının istediği ZAMAN satın alabileceği KALICI bir giriş
        // noktası da olsun. Bu kart AYNI `showAdFreePromoSheet(...)`'i açar
        // (periyodik tetikleyicinin sayaç/cooldown mantığı burada
        // ATLANIYOR — kullanıcı kendi isteğiyle geldiği için bekletmenin
        // anlamı yok), tam sheet içeriği (fayda listesi + fiyat + mockup
        // "Yakında!" akışı) HİÇ tekrarlanmadı.
        Text(
          l10n.storeAdFreeSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const _AdFreeCard(),
        const SizedBox(height: 24),
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
          childAspectRatio: 0.8,
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
    // 2026 güncellemesi — kullanıcı isteğiyle Standart/Premium ayrımı
    // (ayrı başlıklı iki `GridView`) KALDIRILDI: artık TÜM temalar (statik +
    // premium/animasyonlu) kategori ayrımı olmadan TEK bir listede, ucuzdan
    // pahalıya sıralı gösteriliyor. Her kartın kendi üstündeki "Premium"
    // rozeti (bkz. ThemeOptionCard, `theme.isPremiumAnimated`) hangi
    // temaların animasyonlu olduğunu KART SEVİYESİNDE göstermeye devam
    // ediyor — yalnızca üst düzey grup başlığı kayboldu.
    final sortedThemes = [...appThemes]
      ..sort((a, b) => a.price.compareTo(b.price));

    return _ThemesGrid(themes: sortedThemes);
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

/// Mağaza'nın "Reklamsız Zibo" bölümündeki kalıcı satın alma girişi —
/// `_WatchAdCard` ile AYNI görsel dil (Card + ikon + başlık/alt metin +
/// buton), ama "izleyip kazan" yerine "satın al" akışına bağlı. Basınca
/// AYNI `showAdFreePromoSheet(...)`'i açar — periyodik tanıtımın kullandığı
/// TAM fayda listesi + fiyat + mockup "Yakında!" akışı burada da birebir
/// aynı, ikinci bir kopya YAZILMADI. **Kartın kendi başlığı/alt metni
/// (`storeAdFreeCardTitle`/`storeAdFreeCardSubtitle`) BİLEREK sheet'in
/// `adFreePromoTitle`/`adFreePromoSubtitle`'ından ("Zibo ADS"/"Reklamsız
/// Deneyim") FARKLI** — aynı metni kullanmak `widget_test.dart`'taki
/// periyodik tanıtımın görünürlüğünü `find.text('Zibo ADS')` ile kontrol
/// eden testleri (kart HER ZAMAN ekranda dururken bu metin artık BİRDEN
/// FAZLA yerde bulunurdu) bozardı.
class _AdFreeCard extends StatelessWidget {
  const _AdFreeCard();

  /// "Zibo ADS" banner'ıyla AYNI sabit kırmızı (bkz. ad_free_promo_sheet.dart
  /// — kullanıcı isteğiyle uygulamanın aktif temasından BİLEREK BAĞIMSIZ),
  /// burada yalnızca ikonun rengi olarak kullanılıyor — kartın geri kalanı
  /// Mağaza'nın normal kart stiliyle (varsayılan `Card` rengi) tutarlı kalsın
  /// diye tüm kart kırmızıya boyanmadı.
  static const _brandRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // "Yakında!" mockup akışıyla AYNI fiyat kaynağı (bkz.
    // ad_free_promo_sheet.dart) — gerçek IAP bağlandığında ikisi de AYNI
    // anda güncellenecek, tek bir kaynak.
    final priceLabel = adFreePromoPrice.formattedForLocale(
      Localizations.localeOf(context).languageCode,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, size: 36, color: _brandRed),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.storeAdFreeCardTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.storeAdFreeCardSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => showAdFreePromoSheet(context),
              child: Text(priceLabel),
            ),
          ],
        ),
      ),
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
    // Günlük hak tükendiyse (bkz. CoinProvider.maxDailyAdWatches) kart
    // "pasif" görünür: alt metin uyarı mesajına döner, buton devre dışı
    // kalır — kullanıcı `_WatchAdCardState` bunu her `build()`'de canlı
    // izlediği için (context.watch) reklam izleyip hakkı tükettiği ANDA
    // (ayrı bir sayfa yenilemeye gerek kalmadan) kart otomatik güncellenir.
    final canWatch = context.watch<CoinProvider>().canWatchAdForCoinsToday;

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
                    canWatch
                        ? l10n.storeWatchAdSubtitle(CoinEconomy.adWatch)
                        : l10n.dailyAdLimitReachedMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: (_loading || !canWatch)
                  ? null
                  : () => _watchAd(context),
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

  /// Play Store'dan sorgulanan canlı fiyat metni (bkz.
  /// `CoinProvider.queryLocalizedPrice`) — `null` kaldığı sürece (mağaza
  /// henüz yanıt vermedi, ürün Play Console'da aktif değil, testte
  /// `MockPurchaseService` her zaman `null` döner) [CoinPackage.price]'taki
  /// sabit fiyat gösterilmeye devam eder, ekranda hiçbir "yükleniyor"
  /// durumu YOK — bu tamamen sessiz bir arka plan iyileştirmesi.
  String? _livePrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrice());
  }

  Future<void> _loadLivePrice() async {
    final price = await context.read<CoinProvider>().queryLocalizedPrice(
      widget.package,
    );
    if (mounted && price != null) setState(() => _livePrice = price);
  }

  Future<void> _buy(BuildContext context) async {
    // Kullanıcı isteği: İLK gerçek coin satın alma DENEMESİNDE, hesap
    // henüz Google'a bağlı değilse önce bir teşvik sheet'i göster (zorunlu
    // DEĞİL — "Şimdilik Atla" ile atlanabilir, ne yapılırsa yapılsın
    // aşağıdaki satın alma normal şekilde devam eder). `hasSeenLinkPrompt`
    // sayesinde bu YALNIZCA bir kez (ilk denemede) gösteriliyor — sonraki
    // satın almalarda tekrar sormuyor.
    final authLink = context.read<AuthLinkProvider>();
    if (!authLink.isLinked && !authLink.hasSeenLinkPrompt) {
      await authLink.markLinkPromptSeen();
      if (!context.mounted) return;
      await showGoogleLinkPromoSheet(context);
      if (!context.mounted) return;
    }

    setState(() => _loading = true);
    final success = await context.read<CoinProvider>().purchaseCoinPackage(
      widget.package,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!context.mounted) return;
    if (success) {
      _showCoinsAddedSnackBar(context, widget.package.coinAmount);
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.storePurchaseFailedMessage)),
        );
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
            SizedBox(
              width: 76 * widget.package.imageScale,
              height: 76 * widget.package.imageScale,
              child: Image.asset(
                widget.package.imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.storeCoinAmount(widget.package.coinAmount),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
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
                    : Text(
                        _livePrice ??
                            widget.package.price?.formatted ??
                            l10n.storeBuyButton,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
