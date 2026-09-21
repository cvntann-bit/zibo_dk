import '../models/coin_package.dart';
import '../models/subscription_offer.dart';
import '../models/subscription_tier.dart';

/// Play Console'da tanımlı 4 satın alınabilir abonelik teklifi — 2 ürün
/// (`zibo_pro`, `zibo_proplus`) × 2 temel plan (`monthly`, `yearly-plan`).
/// `coinPackages` (`lib/data/coin_packages.dart`) ile AYNI "sabit veri
/// listesi" deseni. [SubscriptionOffer.fallbackPrice] değerleri Play
/// Console'a girilen KDV dahil referans fiyatlarla BİREBİR (bkz.
/// `docs/subscribe_model.md`).
const subscriptionOffers = [
  SubscriptionOffer(
    productId: 'zibo_pro',
    basePlanId: 'monthly',
    tier: SubscriptionTier.pro,
    isYearly: false,
    fallbackPrice: PackagePrice(amount: 59.90),
  ),
  SubscriptionOffer(
    productId: 'zibo_pro',
    basePlanId: 'yearly-plan',
    tier: SubscriptionTier.pro,
    isYearly: true,
    fallbackPrice: PackagePrice(amount: 449.90),
  ),
  SubscriptionOffer(
    productId: 'zibo_proplus',
    basePlanId: 'monthly',
    tier: SubscriptionTier.proPlus,
    isYearly: false,
    fallbackPrice: PackagePrice(amount: 99.90),
  ),
  SubscriptionOffer(
    productId: 'zibo_proplus',
    basePlanId: 'yearly-plan',
    tier: SubscriptionTier.proPlus,
    isYearly: true,
    fallbackPrice: PackagePrice(amount: 749.90),
  ),
];
