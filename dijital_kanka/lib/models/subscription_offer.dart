import 'subscription_tier.dart';

/// Play Console'da satın alınabilir TEK bir abonelik teklifi — bir ürün
/// ([productId], ör. `zibo_pro`) İÇİNDEKİ bir temel plan ([basePlanId], ör.
/// `monthly`/`yearly-plan`). `CoinPackage` ile AYNI "veri ayrı dosyada"
/// deseni — bkz. `lib/data/subscription_products.dart`.
///
/// **Play Console yapısı**: `zibo_pro`/`zibo_proplus` İKİ ayrı ürün, her biri
/// `monthly`+`yearly-plan` temel planlarına sahip — 4 düz ürün ID'si DEĞİL.
/// `in_app_purchase_android`'in `queryProductDetails({productId})` çağrısı bir
/// aboneli ürün için TEK `ProductDetails` değil, HER temel plan için AYRI bir
/// `GooglePlayProductDetails` girdisi döner (`subscriptionOfferDetails`
/// listesindeki her offer için bir tane) — bu yüzden satın alma akışı
/// [productId] + [basePlanId] ikilisiyle doğru girdiyi eşleştirmeli (bkz.
/// `iap_purchase_service.dart`).
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.productId,
    required this.basePlanId,
    required this.tier,
    required this.isYearly,
  });

  /// Play Console ürün kimliği (`zibo_pro` / `zibo_proplus`).
  final String productId;

  /// Play Console temel plan kimliği (`monthly` / `yearly-plan`).
  final String basePlanId;

  final SubscriptionTier tier;

  /// `true` → yıllık (`yearly-plan`), `false` → aylık (`monthly`) — UI'da
  /// "Aylık"/"Yıllık" etiketini seçmek için, [basePlanId] string'ini
  /// karşılaştırmak yerine.
  final bool isYearly;
}
