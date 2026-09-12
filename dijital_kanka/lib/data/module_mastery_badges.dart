import '../models/badge_definition.dart';

/// Modül Ustalığı Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// `consistencyBadges`'in AKSİNE (streak/uygulama-açma serisi) altısı da
/// bir modülün TOPLAM kayıt sayısına bağlı — ARDIŞIK olmak ZORUNDA DEĞİL,
/// kullanıcı istediği zaman aralığında bu sayıya ulaşabilir (bkz.
/// `BadgeProvider.reconcileModuleMasteryBadges`).
///
/// Görseller kullanıcının masaüstündeki `rozetler/modul ustalıgı
/// rozetleri` klasöründen `tool/process_module_mastery_badge_images.dart`
/// ile (dosya adları AYNEN korunarak, yalnızca 512px'e küçültülerek)
/// `assets/images/`e kopyalandı.
const moduleMasteryBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'grateful_heart',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/sükran_rozeti.webp',
    zcReward: 55,
  ),
  ZiboBadgeDefinition(
    id: 'water_hero',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/su_kahramani_rozet.webp',
    zcReward: 55,
  ),
  ZiboBadgeDefinition(
    id: 'mood_chronicler',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/ruh_hali_rozet.webp',
    zcReward: 55,
  ),
  ZiboBadgeDefinition(
    id: 'savings_master',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/birikim_ustasi_rozet.webp',
    zcReward: 45,
  ),
  ZiboBadgeDefinition(
    id: 'dreamer',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/hayalperest_rozet.webp',
    zcReward: 40,
  ),
  ZiboBadgeDefinition(
    id: 'dream_interpreter',
    category: BadgeCategory.moduleMastery,
    imageAsset: 'assets/images/ruya_yorumcusu_rozet.webp',
    zcReward: 40,
  ),
];
