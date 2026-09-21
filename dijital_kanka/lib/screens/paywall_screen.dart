import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/subscription_products.dart';
import '../l10n/app_localizations.dart';
import '../models/coin_package.dart';
import '../models/subscription_offer.dart';
import '../models/subscription_tier.dart';
import '../providers/ad_free_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/info_dialog.dart';

/// Reklamsız Zibo'nun SABİT/görsel yer tutucu fiyatı — eskiden (SİLİNEN)
/// `ad_free_promo_sheet.dart`'ta yaşıyordu, bkz. `docs/subscribe_model.md`.
/// Yalnızca Play Store'un canlı fiyatı gelmediyse gösterilen bir İLK TAHMİN.
/// `store_screen.dart`'ın `_AdFreeCard`'ı da AYNI sabiti kullanıyor — tek bir
/// yerden değişsin diye PUBLIC.
const adFreeFallbackPrice = PackagePrice(amount: 159.90);

/// Play Console'daki KALICI (managed) reklamsız ürün ID'si —
/// `AdFreeProvider.productId` ile BİREBİR aynı olmalı; bu ekran satın alma
/// durumunu izlemek için ayrıca bir string tutuyor çünkü tek-seferlik ürün
/// [SubscriptionOffer] modeline UYMUYOR (abonelik değil).
const _adFreeProductId = 'remove_ads_lifetime';

/// Zibo Pro / Zibo Pro+ / tek seferlik reklamsız paketin satıldığı TEK,
/// kapsamlı paywall ekranı — bkz. `docs/subscribe_model.md`. Eskiden yalnızca
/// reklamsız paket satan dar bir bottom sheet'in (`ad_free_promo_sheet.dart`,
/// SİLİNDİ) YERİNE geçti; TÜM eski giriş noktaları (Ayarlar, Ana Sayfa'da
/// Zibo'ya art arda dokunma, Mağaza'daki kalıcı kart + periyodik ziyaret
/// promosu) artık bu ekranı açıyor.
///
/// **Görsel parçalar KASITLI olarak küçük, ayrı private widget'lara
/// bölündü** (`_PaywallHeaderBanner`, `_PlanCard`, `_PerkRow`) — ileride
/// yalnızca görsel/asset değişikliği yapılacaksa (kullanıcı isteği) tek bir
/// widget'ı düzenlemek yeterli olsun diye.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isYearly = false;

  /// Şu an satın alma/yükseltme işlemi SÜREN ürünün kimliği — yalnızca O
  /// butonun kendi yükleniyor göstergesini çizmek için (`ad_free_promo_
  /// sheet.dart`'taki `_purchasing` bool'unun 3 karta genelleşmiş hâli).
  String? _purchasingProductId;

  /// Play Store'dan sorgulanan canlı fiyatlar — anahtar `productId-basePlanId`
  /// (bkz. `_offerKey`). Gelmeyen teklifler [SubscriptionOffer.fallbackPrice]'a
  /// düşer.
  final Map<String, String> _liveSubscriptionPrices = {};
  String? _liveAdFreePrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrices());
  }

  static String _offerKey(SubscriptionOffer offer) =>
      '${offer.productId}-${offer.basePlanId}';

  Future<void> _loadLivePrices() async {
    final adFreePrice = await context.read<AdFreeProvider>().queryLocalizedPrice();
    if (mounted && adFreePrice != null) {
      setState(() => _liveAdFreePrice = adFreePrice);
    }
    final subscription = context.read<SubscriptionProvider>();
    for (final offer in subscriptionOffers) {
      final price = await subscription.queryLocalizedPrice(offer);
      if (mounted && price != null) {
        setState(() => _liveSubscriptionPrices[_offerKey(offer)] = price);
      }
    }
  }

  SubscriptionOffer _offerFor(SubscriptionTier tier) {
    return subscriptionOffers.firstWhere(
      (o) => o.tier == tier && o.isYearly == _isYearly,
    );
  }

  String _subscriptionPriceLabel(SubscriptionOffer offer, AppLocalizations l10n, String languageCode) {
    final live = _liveSubscriptionPrices[_offerKey(offer)];
    if (live != null) return live;
    final suffix = offer.isYearly ? l10n.paywallPerYearSuffix : l10n.paywallPerMonthSuffix;
    return '${offer.fallbackPrice.formattedForLocale(languageCode)}$suffix';
  }

  String _adFreePriceLabel(String languageCode) =>
      _liveAdFreePrice ?? adFreeFallbackPrice.formattedForLocale(languageCode);

  Future<void> _buyAdFree() async {
    setState(() => _purchasingProductId = _adFreeProductId);
    final success = await context.read<AdFreeProvider>().purchase();
    await _handlePurchaseResult(success, isUpgrade: false);
  }

  Future<void> _subscribe(SubscriptionOffer offer) async {
    setState(() => _purchasingProductId = offer.productId);
    final success = await context.read<SubscriptionProvider>().purchase(offer);
    await _handlePurchaseResult(success, isUpgrade: false);
  }

  Future<void> _upgrade(SubscriptionOffer offer) async {
    setState(() => _purchasingProductId = offer.productId);
    final success = await context.read<SubscriptionProvider>().upgradeToProPlus(offer);
    await _handlePurchaseResult(success, isUpgrade: true);
  }

  Future<void> _handlePurchaseResult(bool success, {required bool isUpgrade}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _purchasingProductId = null);
    if (success) {
      final message = isUpgrade
          ? l10n.paywallUpgradeSuccessMessage
          : l10n.paywallPurchaseSuccessMessage;
      await showInfoDialog(context, message);
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      final message = isUpgrade
          ? l10n.paywallUpgradeErrorMessage
          : l10n.paywallPurchaseErrorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    final subscription = context.watch<SubscriptionProvider>();

    final proOffer = _offerFor(SubscriptionTier.pro);
    final proPlusOffer = _offerFor(SubscriptionTier.proPlus);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallAppBarTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _PaywallHeaderBanner(),
            const SizedBox(height: 20),
            Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.paywallBillingToggleMonthly),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.paywallBillingToggleYearly),
                  ),
                ],
                selected: {_isYearly},
                onSelectionChanged: (selection) =>
                    setState(() => _isYearly = selection.first),
              ),
            ),
            const SizedBox(height: 20),
            // Tek seferlik reklamsız kart — kullanıcı zaten Pro/Pro+ ise
            // GİZLİ (Pro zaten reklamları kaldırıyor, ayrıca göstermek kafa
            // karıştırır — bkz. `docs/subscribe_model.md`).
            if (!subscription.isPro)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _PlanCard(
                  buttonKey: const Key('paywallOneTimeButton'),
                  title: l10n.paywallOneTimeTitle,
                  perks: [l10n.paywallOneTimeBenefit],
                  priceLabel: _adFreePriceLabel(languageCode),
                  badgeText: isAdFree ? l10n.storeAdFreeCardPurchasedLabel : null,
                  buttonLabel: l10n.paywallBuyButton,
                  isLoading: _purchasingProductId == _adFreeProductId,
                  onTap: isAdFree ? null : _buyAdFree,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _PlanCard(
                buttonKey: const Key('paywallProButton'),
                title: l10n.paywallProTitle,
                perks: [
                  l10n.paywallProPerkNoForcedAds,
                  l10n.paywallProPerkCoinBonus,
                  l10n.paywallProPerkStreakFreeze,
                  l10n.paywallProPerkWheelNoAds,
                  l10n.paywallProPerkUnlimitedHistory,
                  l10n.paywallProPerkNotificationTime,
                ],
                priceLabel: _subscriptionPriceLabel(proOffer, l10n, languageCode),
                badgeText: subscription.isProPlus
                    ? l10n.paywallAlreadyProPlusBadge
                    : subscription.isPro
                    ? l10n.paywallCurrentPlanBadge
                    : null,
                buttonLabel: l10n.paywallSubscribeButton,
                isLoading: _purchasingProductId == proOffer.productId,
                onTap: subscription.isPro ? null : () => _subscribe(proOffer),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _PlanCard(
                buttonKey: const Key('paywallProPlusButton'),
                title: l10n.paywallProPlusTitle,
                highlightLabel: l10n.paywallMostPopularBadge,
                perks: [
                  l10n.paywallProPlusPerkAllOfPro,
                  l10n.paywallProPlusPerkCoinBonus,
                  l10n.paywallProPlusPerkStreakFreeze,
                  l10n.paywallProPlusPerkExclusiveItem,
                  l10n.paywallProPlusPerkProfileBadge,
                  l10n.paywallProPlusPerkWatermark,
                  l10n.paywallProPlusPerkTrendChart,
                  l10n.paywallProPlusPerkMoneyAnalysis,
                  l10n.paywallProPlusPerkNotificationSounds,
                ],
                priceLabel: _subscriptionPriceLabel(proPlusOffer, l10n, languageCode),
                badgeText: subscription.isProPlus
                    ? l10n.paywallAlreadyProPlusBadge
                    : null,
                buttonLabel: subscription.isPro
                    ? l10n.paywallUpgradeButton
                    : l10n.paywallSubscribeButton,
                isLoading: _purchasingProductId == proPlusOffer.productId,
                onTap: subscription.isProPlus
                    ? null
                    : subscription.isPro
                    ? () => _upgrade(proPlusOffer)
                    : () => _subscribe(proPlusOffer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üstteki dikkat çekici kırmızı şerit — eski `ad_free_promo_sheet.dart`'ın
/// `_RedBanner`'ından TAŞINDI (bkz. sınıf dokümantasyonu), uygulamanın aktif
/// temasından/koyu-açık modundan BİLEREK BAĞIMSIZ, sabit kırmızı.
class _PaywallHeaderBanner extends StatelessWidget {
  const _PaywallHeaderBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.paywallBannerTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.paywallBannerSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Üç seçeneğin (Tek Seferlik/Pro/Pro+) ORTAK kart iskeleti — başlık, isteğe
/// bağlı öne-çıkarma rozeti ([highlightLabel], her zaman görünür), perk
/// listesi, fiyat, ve ya bir buton ya da bir durum rozeti ([badgeText]
/// verilirse [onTap]/[buttonLabel] YOK SAYILIR — "zaten bu planı kullanıyor/
/// yükseltemez" durumları için).
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.buttonKey,
    required this.title,
    required this.perks,
    required this.priceLabel,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
    this.badgeText,
    this.highlightLabel,
  });

  /// Testlerin doğru karttaki butona basabilmesi için — kart başına benzersiz
  /// (`paywallOneTimeButton`/`paywallProButton`/`paywallProPlusButton`).
  final Key buttonKey;

  final String title;
  final List<String> perks;
  final String priceLabel;
  final String buttonLabel;
  final bool isLoading;

  /// `null` → buton devre dışı (zaten bu plandaysa/işlemi başlatamıyorsa).
  final VoidCallback? onTap;

  /// Kullanıcının bu plana göre DURUMUNU gösteren rozet (ör. "Mevcut Planın")
  /// — verilirse buton YERİNE gösterilir.
  final String? badgeText;

  /// Kartın üstündeki, DURUMDAN bağımsız pazarlama rozeti (ör. "En Popüler")
  /// — her zaman görünür, `badgeText`'ten FARKLI amaç.
  final String? highlightLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showButton = badgeText == null;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlightLabel != null
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlightLabel != null) ...[
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    highlightLabel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final perk in perks) ...[
              _PerkRow(text: perk),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: showButton
                  ? FilledButton(
                      key: buttonKey,
                      onPressed: isLoading ? null : onTap,
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(buttonLabel),
                    )
                  : OutlinedButton(
                      onPressed: null,
                      child: Text(badgeText!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kart içindeki tek bir fayda satırı — ikon + metin.
class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
