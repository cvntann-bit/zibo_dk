import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_package.dart';
import '../providers/ad_free_provider.dart';

/// Reklamsız Zibo'nun gösterilen fiyatı — `CoinPackage`'ın zaten taşıdığı
/// [PackagePrice] modeli yeniden kullanılıyor (bkz. o dosyadaki "ileride
/// ülkeye göre farklı para birimi" notu — AYNI genişletme yolu burada da
/// geçerli, şimdilik tek bir sabit TRY değeri). 159,90 ₺ kullanıcının
/// verdiği gerçek fiyat.
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
  final l10n = AppLocalizations.of(context)!;
  // 2026 güncellemesi — "Satın Al" buton YAZISI yerine gerçek fiyat
  // gösteriliyor (kullanıcı isteği). Sayı biçimi arayüz diline göre uyarlanıyor
  // (bkz. `PackagePrice.formattedForLocale`/`formatCurrencyAmount`) — para
  // birimi henüz TRY'de sabit, yalnızca ondalık/binlik ayracı değişiyor.
  final priceLabel = adFreePromoPrice.formattedForLocale(
    Localizations.localeOf(context).languageCode,
  );

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
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
                        onPressed: () async {
                          // `AdFreeProvider` `sheetContext`'in DIŞARIDAKİ
                          // `context`'inden okunuyor (sheet kapandıktan
                          // SONRA da sonuç mesajını göstermek için) — ikisi
                          // de AYNI `MultiProvider` ağacında, `read` hangi
                          // context'ten yapılırsa yapılsın aynı örneği verir.
                          final adFree = context.read<AdFreeProvider>();
                          Navigator.of(sheetContext).pop();
                          final success = await adFree.purchase();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? l10n.adFreePromoPurchaseSuccess
                                      : l10n.adFreePromoPurchaseFailed,
                                ),
                              ),
                            );
                        },
                        child: Text(priceLabel),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        key: const Key('adFreePromoDismissButton'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
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
    },
  );
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
