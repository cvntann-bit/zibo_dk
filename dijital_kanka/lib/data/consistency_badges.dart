import '../models/badge_definition.dart';
import 'collection_badges.dart';
import 'hidden_badges.dart';
import 'loyalty_badges.dart';
import 'module_mastery_badges.dart';
import 'social_badges.dart';

/// İstikrar Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Beşi de
/// `AppStreakProvider.currentStreak`'e (uygulamayı HER GÜN AÇMA serisi —
/// kullanıcının `AskUserQuestion` ile seçtiği ölçü, Hedef Takibi'nden
/// BAĞIMSIZ) bağlı, TEK istisna `first_step` (Hedef Takibi'ndeki İLK
/// tamamlanan 7 günlük döngü — `GoalsProvider.completions`).
///
/// Görseller kullanıcının masaüstündeki `rozetler/istikrar rozetleri`
/// klasöründen `tool/process_badge_images.dart` ile (dosya adları AYNEN
/// korunarak, yalnızca 512px'e küçültülerek) `assets/images/`e kopyalandı.
const consistencyBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'first_step',
    category: BadgeCategory.consistency,
    imageAsset: 'assets/images/ilk_adim_rozet.png',
    zcReward: 10,
  ),
  ZiboBadgeDefinition(
    id: 'week_streak',
    category: BadgeCategory.consistency,
    imageAsset: 'assets/images/bir_hafta_seri_rozet.png',
    zcReward: 30,
  ),
  ZiboBadgeDefinition(
    id: 'month_streak',
    category: BadgeCategory.consistency,
    imageAsset: 'assets/images/bir_aylik_seri_rozet.png',
    zcReward: 100,
  ),
  ZiboBadgeDefinition(
    id: 'iron_will',
    category: BadgeCategory.consistency,
    imageAsset: 'assets/images/demir_irade_rozet.png',
    zcReward: 250,
  ),
  ZiboBadgeDefinition(
    id: 'unyielding',
    category: BadgeCategory.consistency,
    imageAsset: 'assets/images/yilmaz_efsanevi_rozet.png',
    zcReward: 500,
  ),
];

/// TÜM kategorilerin TÜM rozetleri — [consistencyBadges] +
/// [moduleMasteryBadges] + [collectionBadges] + [loyaltyBadges] +
/// [socialBadges] + [hiddenBadges]. Yeni bir kategori eklendiğinde yalnızca
/// bu listeye eklenmesi yeterli — `BadgesGalleryScreen` bunu kategoriye
/// göre gruplayıp gösteriyor.
const allBadges = <ZiboBadgeDefinition>[
  ...consistencyBadges,
  ...moduleMasteryBadges,
  ...collectionBadges,
  ...loyaltyBadges,
  ...socialBadges,
  ...hiddenBadges,
];
