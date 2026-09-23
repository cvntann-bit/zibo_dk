import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart' show defaultZiboImage;
import '../data/paywall_comparison.dart';
import '../data/paywall_quotes.dart';
import '../data/subscription_products.dart';
import '../l10n/app_localizations.dart';
import '../models/coin_package.dart';
import '../models/subscription_offer.dart';
import '../models/subscription_tier.dart';
import '../providers/ad_free_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/info_dialog.dart';
import '../widgets/sticker_style.dart';

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
/// kapsamlı paywall ekranı — bkz. `docs/subscribe_model.md`. Görsel dil
/// uygulamanın "sticker" temasına (bkz. `sticker_style.dart`) uyarlandı: Zibo
/// karakteri + dönen teşvik balonu, yan yana Pro/Pro+ kartları (Pro+ öne
/// çıkarılmış), Ücretsiz/Pro/Pro+ karşılaştırma tablosu.
///
/// **Bilerek DIŞARIDA bırakılan iki perk** (bkz. `paywall_comparison.dart`
/// dokümantasyonu): "Bildirim saatini kişiselleştir" (hiç implement
/// edilmedi) ve "Ayda 1 Pro'ya özel kostüm/tema" (asla eklenmeyecek). Ayrıca
/// "Paylaşım kartlarında özel Pro+ filigranı" da artık YANLIŞ — share-card
/// güncellemesinden sonra HER tier kendi logosunu görüyor, Pro+'a özel bir
/// filigran yok. Bu üç ARB anahtarı proje konvansiyonu gereği SİLİNMEDİ,
/// yalnızca burada REFERANS edilmiyor.
///
/// **Kapatma kontrolü KASITLI olarak her zaman görünür/erişilebilir** (sağ
/// üstte küçük bir X) — Play Store politikası satın almaya teşvik ederken
/// kapatmayı gizlemeyi/zorlaştırmayı yasaklıyor.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  bool _isYearly = false;

  /// Şu an satın alma/yükseltme işlemi SÜREN ürünün kimliği — yalnızca O
  /// butonun kendi yükleniyor göstergesini çizmek için.
  String? _purchasingProductId;

  /// Play Store'dan sorgulanan canlı fiyatlar — anahtar `productId-basePlanId`
  /// (bkz. `_offerKey`). Gelmeyen teklifler [SubscriptionOffer.fallbackPrice]'a
  /// düşer.
  final Map<String, String> _liveSubscriptionPrices = {};
  String? _liveAdFreePrice;

  int _quoteIndex = 0;
  Timer? _quoteTimer;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  /// Karakterin "nefes" hareketi + Satın Al butonlarının nabız/parlama
  /// animasyonu AYNI kontrolcüden geliyor. BİLEREK `repeat()` DEĞİL, sonlu
  /// sayıda (`_maxAmbientPulseCycles`) döngüden sonra kendini durduruyor —
  /// sonsuz tekrarlayan bir `AnimationController` `WidgetTester.pumpAndSettle()`
  /// çağrısını SONSUZA KADAR "yerleşmedi" bırakır (bkz. `test/CLAUDE.md`
  /// `Timer.periodic` rezonans notu — AYNI kısıt gerçek bir animasyon
  /// kontrolcüsü için de geçerli), bu ekranı açan mevcut `widget_test.dart`
  /// testlerinin HEPSİ `pumpAndSettle()` kullanıyor.
  static const _maxAmbientPulseCycles = 3;
  int _ambientPulseCycles = 0;
  late final AnimationController _ambientPulseController;
  late final Animation<double> _ambientPulseScale;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrices());

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));

    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener(_onAmbientPulseStatusChanged);
    _ambientPulseScale = Tween<double>(begin: 1, end: 1.045).animate(
      CurvedAnimation(parent: _ambientPulseController, curve: Curves.easeInOut),
    );
    _ambientPulseController.forward();

    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _quoteIndex++);
    });
  }

  void _onAmbientPulseStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _ambientPulseController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _ambientPulseCycles++;
      if (_ambientPulseCycles < _maxAmbientPulseCycles) {
        _ambientPulseController.forward();
      }
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _entranceController.dispose();
    _ambientPulseController.dispose();
    super.dispose();
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
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    final subscription = context.watch<SubscriptionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final proOffer = _offerFor(SubscriptionTier.pro);
    final proPlusOffer = _offerFor(SubscriptionTier.proPlus);

    final quotes = paywallQuotesForLocale(locale);
    final quoteText = quotes[_quoteIndex % quotes.length];
    final comparisonRows = paywallComparisonRowsForLocale(locale);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primaryContainer, colorScheme.surface],
            stops: const [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _entranceFade,
                child: SlideTransition(
                  position: _entranceSlide,
                  child: SingleChildScrollView(
                    // Sayfa TEK bir uzun kaydırma alanı — içerik sabit/sınırlı
                    // olduğu için (dev listesi değil) `ListView` yerine
                    // `SingleChildScrollView` BİLEREK seçildi: `ListView`'ın
                    // sliver tabanlı "onstage" izleme mantığı, alt kısımdaki
                    // (tek seferlik satır, karşılaştırma tablosu) öğeleri ilk
                    // kaydırmadan ÖNCE `WidgetTester.pumpAndSettle()`
                    // sonrasında bile "onstage" saymayabiliyor (bkz.
                    // `test/CLAUDE.md`) — tüm içerik BAŞTAN inşa edilsin diye.
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      const SizedBox(height: 32),
                      _PaywallHero(
                        quoteText: quoteText,
                        breathScale: _ambientPulseScale,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          l10n.paywallSocialProofLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: _BillingToggle(
                          isYearly: _isYearly,
                          monthlyLabel: l10n.paywallBillingToggleMonthly,
                          yearlyLabel: l10n.paywallBillingToggleYearly,
                          onChanged: (value) => setState(() => _isYearly = value),
                        ),
                      ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PlanCard(
                                buttonKey: const Key('paywallProButton'),
                                title: l10n.paywallProTitle,
                                perks: [
                                  l10n.paywallProPerkNoForcedAds,
                                  l10n.paywallProPerkCoinBonus,
                                  l10n.paywallProPerkStreakFreeze,
                                  l10n.paywallProPerkWheelNoAds,
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
                                ctaPulseScale: _ambientPulseScale,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlanCard(
                                buttonKey: const Key('paywallProPlusButton'),
                                title: l10n.paywallProPlusTitle,
                                highlightLabel: l10n.paywallMostPopularBadge,
                                emphasized: true,
                                perks: [
                                  l10n.paywallProPlusPerkCoinBonus,
                                  l10n.paywallProPlusPerkStreakFreeze,
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
                                ctaPulseScale: _ambientPulseScale,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tek seferlik reklamsız satır — kullanıcı zaten Pro/
                      // Pro+ ise GİZLİ (Pro zaten reklamları kaldırıyor, ayrıca
                      // göstermek kafa karıştırır — bkz. `docs/subscribe_model.md`).
                      if (!subscription.isPro) ...[
                        const SizedBox(height: 12),
                        _OneTimeAdFreeRow(
                          buttonKey: const Key('paywallOneTimeButton'),
                          title: l10n.paywallOneTimeTitle,
                          benefit: l10n.paywallOneTimeBenefit,
                          priceLabel: _adFreePriceLabel(languageCode),
                          badgeText: isAdFree ? l10n.storeAdFreeCardPurchasedLabel : null,
                          buttonLabel: l10n.paywallBuyButton,
                          isLoading: _purchasingProductId == _adFreeProductId,
                          onTap: isAdFree ? null : _buyAdFree,
                        ),
                      ],
                      const SizedBox(height: 22),
                      _ComparisonTable(
                        title: l10n.paywallCompareTableTitle,
                        columnFree: l10n.paywallCompareColumnFree,
                        columnPro: l10n.paywallCompareColumnPro,
                        columnProPlus: l10n.paywallCompareColumnProPlus,
                        rows: comparisonRows,
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: StickerIconButton(
                  icon: Icons.close_rounded,
                  tooltip: l10n.paywallCloseTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  iconColor: colorScheme.onSurface,
                  size: 34,
                  iconSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üstte Zibo karakteri (hafif nefes animasyonu) + altında dönen teşvik
/// balonu (`paywallQuotesForLocale`, birkaç saniyede bir ilerler — bkz.
/// `manifest_journal_screen.dart`'ın `_showNewQuote`'uyla AYNI desen).
class _PaywallHero extends StatelessWidget {
  const _PaywallHero({required this.quoteText, required this.breathScale});

  final String quoteText;
  final Animation<double> breathScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ScaleTransition(
          scale: breathScale,
          child: Image.asset(defaultZiboImage, height: 104),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Container(
            key: ValueKey(quoteText),
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: stickerDecoration(
              fill: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              borderWidth: 2.5,
              shadowOffset: const Offset(3, 3),
            ),
            child: Text(
              quoteText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: const [FontVariation('wght', 700)],
                fontSize: 13.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Aylık/Yıllık seçimi için sticker haplı toggle — eski `SegmentedButton<bool>`
/// yerine, kartların/balonun sticker diliyle görsel olarak tutarlı.
class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isYearly,
    required this.monthlyLabel,
    required this.yearlyLabel,
    required this.onChanged,
  });

  final bool isYearly;
  final String monthlyLabel;
  final String yearlyLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        borderWidth: 2.5,
        shadowOffset: const Offset(3, 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _segment(context, label: monthlyLabel, selected: !isYearly, onTap: () => onChanged(false)),
            ),
            Flexible(
              child: _segment(context, label: yearlyLabel, selected: isYearly, onTap: () => onChanged(true)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: 12.5,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pro/Pro+ kartlarının ORTAK iskeleti — başlık, fiyat, kısa öne-çıkan perk
/// listesi (tam karşılaştırma alttaki tabloda), fiyat ve buton/rozet.
/// [emphasized] (Pro+) daha kalın kontur + altın dolgu + üstte taşan
/// [highlightLabel] rozeti alır.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.buttonKey,
    required this.title,
    required this.perks,
    required this.priceLabel,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
    required this.ctaPulseScale,
    this.badgeText,
    this.highlightLabel,
    this.emphasized = false,
  });

  /// Testlerin doğru karttaki butona basabilmesi için — kart başına benzersiz
  /// (`paywallProButton`/`paywallProPlusButton`).
  final Key buttonKey;

  final String title;
  final List<String> perks;
  final String priceLabel;
  final String buttonLabel;
  final bool isLoading;

  /// `null` → buton devre dışı (zaten bu plandaysa/işlemi başlatamıyorsa).
  final VoidCallback? onTap;

  /// Kullanıcının bu plana göre DURUMUNU gösteren rozet — verilirse buton
  /// YERİNE gösterilir.
  final String? badgeText;

  /// Kartın üstünden taşan pazarlama rozeti (ör. "En Popüler").
  final String? highlightLabel;
  final bool emphasized;
  final Animation<double> ctaPulseScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showButton = badgeText == null;
    final fill = emphasized ? colorScheme.primaryContainer : colorScheme.surfaceContainerLowest;

    final card = Container(
      padding: EdgeInsets.fromLTRB(12, highlightLabel != null ? 20 : 14, 12, 14),
      decoration: stickerDecoration(
        fill: fill,
        borderRadius: BorderRadius.circular(18),
        borderWidth: emphasized ? 3.5 : 2.5,
        shadowOffset: emphasized ? const Offset(5, 5) : const Offset(3, 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: emphasized ? 16.5 : 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            priceLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: emphasized ? 15 : 13.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          for (final perk in perks) ...[
            _PerkRow(text: perk, emphasized: emphasized),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
          showButton
              ? ScaleTransition(
                  scale: ctaPulseScale,
                  child: stickerButtonShadow(
                    child: FilledButton(
                      key: buttonKey,
                      style: stickerFilledButtonStyle(context, fontSize: emphasized ? 13 : 12),
                      onPressed: isLoading ? null : onTap,
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(buttonLabel),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: null,
                  child: Text(badgeText!, textAlign: TextAlign.center),
                ),
        ],
      ),
    );

    if (highlightLabel == null) return card;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  border: Border.all(color: kStickerOutline, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  highlightLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 800)],
                    fontSize: 10.5,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kart içindeki tek bir öne-çıkan fayda satırı — ikon + kısa metin.
class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: emphasized ? 14 : 13, color: colorScheme.primary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: emphasized ? 11 : 10.2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartların ALTINDAKİ, de-emphasize edilmiş tek seferlik reklamsız satır —
/// tam kart yerine ince bir sticker satırı (görsel ağırlık bilerek Pro/Pro+'a
/// verildi, tek seferlik seçenek hâlâ erişilebilir ama öne çıkarılmıyor).
class _OneTimeAdFreeRow extends StatelessWidget {
  const _OneTimeAdFreeRow({
    required this.buttonKey,
    required this.title,
    required this.benefit,
    required this.priceLabel,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
    this.badgeText,
  });

  final Key buttonKey;
  final String title;
  final String benefit;
  final String priceLabel;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showButton = badgeText == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        borderWidth: 2,
        shadowOffset: const Offset(2, 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 12.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit,
                  style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            priceLabel,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: 12.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          showButton
              ? FilledButton(
                  key: buttonKey,
                  style: stickerFilledButtonStyle(context, radius: 8, fontSize: 11.5),
                  onPressed: isLoading ? null : onTap,
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(buttonLabel),
                )
              : Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ],
      ),
    );
  }
}

/// Ücretsiz/Pro/Pro+ karşılaştırma tablosu — `paywallComparisonRowsForLocale`
/// içeriğini üç sütunlu bir sticker kartında gösterir.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.title,
    required this.columnFree,
    required this.columnPro,
    required this.columnProPlus,
    required this.rows,
  });

  final String title;
  final String columnFree;
  final String columnPro;
  final String columnProPlus;
  final List<PaywallComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StickerCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              _headerCell(context, columnFree),
              _headerCell(context, columnPro),
              _headerCell(context, columnProPlus),
            ],
          ),
          const Divider(height: 16, thickness: 1.5, color: kStickerOutline),
          for (var i = 0; i < rows.length; i++) ...[
            _ComparisonRowTile(row: rows[i]),
            if (i != rows.length - 1)
              Divider(height: 14, thickness: 1, color: colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: 2,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontVariations: const [FontVariation('wght', 700)],
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ComparisonRowTile extends StatelessWidget {
  const _ComparisonRowTile({required this.row});

  final PaywallComparisonRow row;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _valueCell(context, row.free),
          _valueCell(context, row.pro),
          _valueCell(context, row.proPlus),
        ],
      ),
    );
  }

  Widget _valueCell(BuildContext context, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCross = value == '✗';
    return Expanded(
      flex: 2,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isCross
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}
