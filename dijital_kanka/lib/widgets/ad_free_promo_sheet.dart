import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_package.dart';
import '../providers/ad_free_provider.dart';
import '../utils/info_dialog.dart';

/// Reklamsız Zibo'nun SABİT/görsel yer tutucu fiyatı — `CoinPackage`'ın
/// zaten taşıdığı [PackagePrice] modeli yeniden kullanılıyor. Yalnızca Play
/// Store'un canlı fiyatı (bkz. `AdFreeProvider.queryLocalizedPrice`) HENÜZ
/// gelmediyse gösterilen bir İLK TAHMİN — **KDV/vergi dahil GERÇEK fiyat
/// FARKLI olabilir** (2026-09-12 kullanıcı raporu: bu sabit 159,90 TL
/// gösteriyordu ama Play'in kendi ödeme ekranı 189,90 TL çıkardı). Coin
/// paketlerindeki `CoinPackage.price`/`_PackageCardState._livePrice` ile
/// AYNI "sessiz arka plan iyileştirmesi" deseni — canlı fiyat gelince
/// yerini alır, gelmezse (mağaza kullanılamıyor, test ortamı) bu sabit
/// kalır.
const adFreePromoPrice = PackagePrice(amount: 159.90);

/// "Zibo ADS" (reklamsız deneyim) tanıtım ekranı — bkz. CLAUDE.md "Zibo
/// ADS" bölümü. 2026 güncellemesi: "Satın Al" artık [AdFreeProvider]
/// üzerinden GERÇEK bir Play Billing (KALICI/`remove_ads_lifetime`) akışı
/// başlatıyor (eskiden yalnızca bir "Yakında!" mesajı gösteren mockup'tı —
/// bkz. `adFreePromoComingSoon`, HÂLÂ kullanılmayan bir ARB anahtarı olarak
/// duruyor, proje konvansiyonu gereği silinmedi). `showModulesMenuSheet` ile
/// AYNI `showModalBottomSheet` deseni — kullanıcı isteğiyle KAPATILABİLİR
/// (zorunlu değil), sürükleme tutamacı + kapatma butonu ikisi de var.
Future<void> showAdFreePromoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _AdFreePromoSheetBody(outerContext: context),
  );
}

/// Sheet'in gövdesi — `StatefulWidget` olmasının TEK sebebi Play Store'dan
/// canlı fiyat sorgusu ([AdFreeProvider.queryLocalizedPrice]) VE satın alma
/// sırasında butonun kendi "yükleniyor" durumu (bkz. `_PackageCardState`
/// ile AYNI desen, store_screen.dart).
class _AdFreePromoSheetBody extends StatefulWidget {
  const _AdFreePromoSheetBody({required this.outerContext});

  /// Sheet'i açan EKRANIN context'i — sheet kapandıktan SONRA da sonuç
  /// mesajını (SnackBar/dialog) gösterebilmek için AYRI tutuluyor. Bu
  /// widget'ın KENDİ `context`'i, `Navigator.pop()` çağrıldığı ANDA
  /// unmount olacağı için o iş için kullanılamaz.
  final BuildContext outerContext;

  @override
  State<_AdFreePromoSheetBody> createState() => _AdFreePromoSheetBodyState();
}

class _AdFreePromoSheetBodyState extends State<_AdFreePromoSheetBody> {
  bool _purchasing = false;
  String? _livePrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrice());
  }

  Future<void> _loadLivePrice() async {
    final price = await context.read<AdFreeProvider>().queryLocalizedPrice();
    if (mounted && price != null) setState(() => _livePrice = price);
  }

  Future<void> _buy() async {
    final l10n = AppLocalizations.of(context)!;
    final adFree = context.read<AdFreeProvider>();
    setState(() => _purchasing = true);
    final success = await adFree.purchase();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!widget.outerContext.mounted) return;
    if (success) {
      await showInfoDialog(widget.outerContext, l10n.adFreePromoPurchaseSuccess);
    } else {
      await showDialog<void>(
        context: widget.outerContext,
        builder: (dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😞', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                l10n.adFreePromoPurchaseFailed,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.adFreePromoPurchaseFailedDismissButton),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 2026 güncellemesi — "Satın Al" buton YAZISI yerine fiyat gösteriliyor
    // (kullanıcı isteği). Sayı biçimi arayüz diline göre uyarlanıyor (bkz.
    // `PackagePrice.formattedForLocale`/`formatCurrencyAmount`).
    final priceLabel =
        _livePrice ??
        adFreePromoPrice.formattedForLocale(
          Localizations.localeOf(context).languageCode,
        );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RedBanner(l10n: l10n),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Benefit(
                    icon: Icons.block,
                    label: l10n.adFreePromoBenefitNoAds,
                  ),
                  const SizedBox(height: 12),
                  _Benefit(
                    icon: Icons.bolt_outlined,
                    label: l10n.adFreePromoBenefitUninterrupted,
                  ),
                  const SizedBox(height: 12),
                  _Benefit(
                    icon: Icons.favorite_outline,
                    label: l10n.adFreePromoBenefitSupport,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('adFreePromoBuyButton'),
                      onPressed: _purchasing ? null : _buy,
                      child: _purchasing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(priceLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('adFreePromoDismissButton'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.adFreePromoDismissButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üstteki dikkat çekici kırmızı şerit — kullanıcı isteğiyle uygulamanın
/// aktif temasından/koyu-açık modundan BİLEREK BAĞIMSIZ, sabit kırmızı
/// (gerçek dünyadaki promosyon banner'ları da genelde kendi marka rengini
/// korur, o an aktif uygulama temasına uymaz).
class _RedBanner extends StatelessWidget {
  const _RedBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
              Text(
                l10n.adFreePromoTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.adFreePromoSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
