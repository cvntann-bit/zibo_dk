import '../models/badge_definition.dart';

/// Koleksiyon Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Dördü de
/// sahip olunan kostüm/tema SAYISINA bağlı — kaynağı (satın alma VEYA
/// hedefle/başarıyla ücretsiz açma, bkz. `CostumeProvider.
/// reconcileGoalUnlocks`) ÖNEMSİZ, yalnızca SAHİPLİK sayılıyor (bkz.
/// `BadgeProvider.reconcileCollectionBadges`'in `CostumeProvider.
/// ownedRealCostumeCount`/`ownsAllCostumes` kullanımı).
///
/// **`full_wardrobe` — `hasSpecialReward: true`, kullanıcının açık isteği:**
/// standart ZC ödülüne EK olarak, mağazada asla satılmayan, yalnızca bu
/// rozetle kazanılabilen özel bir "Tamamlayıcı" kostüm/rozet verilecek.
/// Görsel/detaylar AYRI bir turda netleştirilecek — bkz.
/// `ZiboBadgeDefinition.hasSpecialReward` dokümantasyonundaki "ŞU AN
/// yalnızca bir YER TUTUCU" notu.
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
    hasSpecialReward: true,
  ),
  ZiboBadgeDefinition(
    id: 'theme_hunter',
    category: BadgeCategory.collection,
    imageAsset: 'assets/images/tema_avcisi_rozet.png',
    zcReward: 25,
  ),
];
