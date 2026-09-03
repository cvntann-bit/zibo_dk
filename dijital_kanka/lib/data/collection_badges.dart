import '../models/badge_definition.dart';

/// Koleksiyon Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Dördü de
/// sahip olunan kostüm/tema SAYISINA bağlı — kaynağı (satın alma VEYA bir
/// rozetle hediye edilme, bkz. `data/badge_gift_rewards.dart`) ÖNEMSİZ,
/// yalnızca SAHİPLİK sayılıyor (bkz. `BadgeProvider.
/// reconcileCollectionBadges`'in `CostumeProvider.ownedRealCostumeCount`/
/// `ownsAllCostumes` kullanımı).
///
/// **`full_wardrobe` — BİLEREK bir kostüm/tema hediyesi TAŞIMIYOR.**
/// Önceki bir turda bu rozet ZC'ye ek olarak rastgele bir tema hediye
/// ediyordu (`hasSpecialReward: true`) — kullanıcı, "Rozet Kazanımına
/// Kostüm/Tema Hediyesi Ekle" turunda verdiği KAPSAMLI/kesin dokuz-rozet
/// eşlemesinde "Tam Gardırop"u AÇIKÇA "yalnızca ZC" listesine dahil edip
/// bu özel ödülü İPTAL etti — bkz. `models/badge_gift_reward.dart`/
/// `data/badge_gift_rewards.dart`.
///
/// Görseller kullanıcının masaüstündeki `rozetler/Koleksiyon rozetleri`
/// klasöründen `tool/process_collection_badge_images.dart` ile (dosya
/// adları AYNEN korunarak, yalnızca 512px'e küçültülerek) `assets/images/`e
/// kopyalandı.
const collectionBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'collector',
    category: BadgeCategory.collection,
    imageAsset: 'assets/images/koleksiyoncu_rozet.png',
    zcReward: 30,
  ),
  ZiboBadgeDefinition(
    id: 'fashion_icon',
    category: BadgeCategory.collection,
    imageAsset: 'assets/images/moda_ikonu_rozet.png',
    zcReward: 75,
  ),
  ZiboBadgeDefinition(
    id: 'full_wardrobe',
    category: BadgeCategory.collection,
    imageAsset: 'assets/images/tam_gardrop_rozet.png',
    zcReward: 200,
  ),
  ZiboBadgeDefinition(
    id: 'theme_hunter',
    category: BadgeCategory.collection,
    imageAsset: 'assets/images/tema_avcisi_rozet.png',
    zcReward: 25,
  ),
];
