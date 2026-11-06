import '../models/badge_definition.dart';

/// Zibo'nun Evi bakım rozetleri (2026-11-06, docs/zibo_images_needed.md C).
/// Koşullar `BadgeProvider.reconcileHomeBadges`'te; sayaçlar
/// `HomeNeedsProvider` (besleme/yıkama/uyku/bakım günü) ve
/// `HomeDecorProvider.purchasedDecorCount`.
const homeBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'home_first_bite',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_ilk_lokma_rozet.webp',
    zcReward: 15,
  ),
  ZiboBadgeDefinition(
    id: 'home_chef',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_sef_rozet.webp',
    zcReward: 40,
  ),
  ZiboBadgeDefinition(
    id: 'home_squeaky_clean',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_mis_gibi_rozet.webp',
    zcReward: 40,
  ),
  ZiboBadgeDefinition(
    id: 'home_sleepyhead',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_uykucu_rozet.webp',
    zcReward: 40,
  ),
  ZiboBadgeDefinition(
    id: 'home_caretaker',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_bakici_rozet.webp',
    zcReward: 75,
  ),
  ZiboBadgeDefinition(
    id: 'home_decorator',
    category: BadgeCategory.home,
    imageAsset: 'assets/images/ev_dekorator_rozet.webp',
    zcReward: 50,
  ),
];
