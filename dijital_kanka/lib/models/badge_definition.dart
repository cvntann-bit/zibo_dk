import '../l10n/app_localizations.dart';

/// Rozet Sistemi'ndeki kategoriler — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// Altısı da dolu: [consistency] + [moduleMastery] + [collection] +
/// [loyalty] + [social] + [hidden] (Gizli/Eğlenceli — bkz. altta
/// [ZiboBadgeDefinition.isHidden]).
enum BadgeCategory { consistency, moduleMastery, collection, loyalty, social, hidden }

/// Tek bir rozetin SABİT tanımı (id, kategori, görsel, ödül) — HANGİ
/// KOŞULDA kazanıldığı BURADA DEĞİL, `BadgeProvider`'ın kategoriye özel
/// reconcile metotlarında kontrol ediliyor; bu sınıf yalnızca GÖRÜNTÜLEME/
/// ödül bilgisini taşıyor.
///
/// `Costume`/`AppThemeOption`'daki AYNI "id → ARB anahtarı" [localizedName]/
/// [localizedRequirement] deseni — isim/gereksinim metni kısa, SABİT bir
/// UI etiketi olduğu için (uzun bir içerik havuzu DEĞİL) ARB'ye ait, ham
/// bir `name` alanı burada TUTULMUYOR (bkz. "Kostümler" bölümündeki "const
/// bir veri listesindeki SABİT bir alan kullanıcıya GÖRÜNÜYORSA ARB'ye
/// taşınmalı" kuralı).
class ZiboBadgeDefinition {
  const ZiboBadgeDefinition({
    required this.id,
    required this.category,
    required this.imageAsset,
    required this.zcReward,
    this.hasSpecialReward = false,
    this.isHidden = false,
  });

  final String id;
  final BadgeCategory category;
  final String imageAsset;
  final int zcReward;

  /// Bu rozet, standart ZC ödülüne EK olarak özel bir ödül (ör. mağazada
  /// asla satılmayan bir kostüm) taşıyor mu — bkz. `collection_badges.dart`
  /// içindeki "full_wardrobe" notu. **ŞU AN yalnızca bir YER TUTUCU/bayrak
  /// — kullanıcı özel ödülün görsel/detaylarını AYRI bir turda
  /// netleştirecek.** `true` olduğunda kod tarafında HİÇBİR ŞEY otomatik
  /// olarak VERİLMİYOR (`CoinProvider`/`CostumeProvider`'a bağlı bir "özel
  /// ödül ver" çağrısı YOK) — yalnızca UI'da (galeri kartı + kutlama
  /// popup'ı) `l10n.badgeSpecialRewardComingSoon` etiketini göstermek için
  /// kullanılıyor.
  final bool hasSpecialReward;

  /// **Gizli/Eğlenceli Rozetler'e özel — bkz. `hidden_badges.dart`.**
  /// `true` iken, bu rozet KAZANILANA kadar `BadgesGalleryScreen`'in
  /// `_BadgeGalleryCard`'ı [imageAsset]/[localizedName]/[localizedRequirement]/
  /// [zcReward]'ın HİÇBİRİNİ göstermez — bunun yerine paylaşılan bir gizem
  /// görseli (`hiddenBadgeMysteryImageAsset`) + `l10n.badgeHiddenPlaceholder`
  /// ("???") gösterir, kullanıcı rozeti TESADÜFEN/KEŞFEDEREK kazansın diye
  /// (kullanıcının açık isteği). **Kazanıldıktan SONRA bu bayrağın HİÇBİR
  /// etkisi kalmaz** — `BadgeCelebrationOverlay`'in kutlama popup'ı VE
  /// galerideki kart, TÜM diğer rozetlerle AYNI şekilde gerçek görsel/isim/
  /// koşul/ödülü gösterir (`_BadgeGalleryCard`'daki kontrol
  /// `badge.isHidden && !earned`'a bağlı, yalnızca `earned` DEĞİLKEN
  /// devrede).
  final bool isHidden;

  String localizedName(AppLocalizations l10n) {
    switch (id) {
      case 'first_step':
        return l10n.badgeNameFirstStep;
      case 'week_streak':
        return l10n.badgeNameWeekStreak;
      case 'month_streak':
        return l10n.badgeNameMonthStreak;
      case 'iron_will':
        return l10n.badgeNameIronWill;
      case 'unyielding':
        return l10n.badgeNameUnyielding;
      case 'grateful_heart':
        return l10n.badgeNameGratefulHeart;
      case 'water_hero':
        return l10n.badgeNameWaterHero;
      case 'mood_chronicler':
        return l10n.badgeNameMoodChronicler;
      case 'savings_master':
        return l10n.badgeNameSavingsMaster;
      case 'dreamer':
        return l10n.badgeNameDreamer;
      case 'dream_interpreter':
        return l10n.badgeNameDreamInterpreter;
      case 'collector':
        return l10n.badgeNameCollector;
      case 'fashion_icon':
        return l10n.badgeNameFashionIcon;
      case 'full_wardrobe':
        return l10n.badgeNameFullWardrobe;
      case 'theme_hunter':
        return l10n.badgeNameThemeHunter;
      case 'first_week':
        return l10n.badgeNameFirstWeek;
      case 'loyal_friend':
        return l10n.badgeNameLoyalFriend;
      case 'anniversary':
        return l10n.badgeNameAnniversary;
      case 'first_share':
        return l10n.badgeNameFirstShare;
      case 'ambassador':
        return l10n.badgeNameAmbassador;
      case 'community_founder':
        return l10n.badgeNameCommunityFounder;
      case 'night_owl':
        return l10n.badgeNameNightOwl;
      case 'early_bird':
        return l10n.badgeNameEarlyBird;
      case 'balance_master':
        return l10n.badgeNameBalanceMaster;
      default:
        return id;
    }
  }

  String localizedRequirement(AppLocalizations l10n) {
    switch (id) {
      case 'first_step':
        return l10n.badgeRequirementFirstStep;
      case 'week_streak':
        return l10n.badgeRequirementWeekStreak;
      case 'month_streak':
        return l10n.badgeRequirementMonthStreak;
      case 'iron_will':
        return l10n.badgeRequirementIronWill;
      case 'unyielding':
        return l10n.badgeRequirementUnyielding;
      case 'grateful_heart':
        return l10n.badgeRequirementGratefulHeart;
      case 'water_hero':
        return l10n.badgeRequirementWaterHero;
      case 'mood_chronicler':
        return l10n.badgeRequirementMoodChronicler;
      case 'savings_master':
        return l10n.badgeRequirementSavingsMaster;
      case 'dreamer':
        return l10n.badgeRequirementDreamer;
      case 'dream_interpreter':
        return l10n.badgeRequirementDreamInterpreter;
      case 'collector':
        return l10n.badgeRequirementCollector;
      case 'fashion_icon':
        return l10n.badgeRequirementFashionIcon;
      case 'full_wardrobe':
        return l10n.badgeRequirementFullWardrobe;
      case 'theme_hunter':
        return l10n.badgeRequirementThemeHunter;
      case 'first_week':
        return l10n.badgeRequirementFirstWeek;
      case 'loyal_friend':
        return l10n.badgeRequirementLoyalFriend;
      case 'anniversary':
        return l10n.badgeRequirementAnniversary;
      case 'first_share':
        return l10n.badgeRequirementFirstShare;
      case 'ambassador':
        return l10n.badgeRequirementAmbassador;
      case 'community_founder':
        return l10n.badgeRequirementCommunityFounder;
      case 'night_owl':
        return l10n.badgeRequirementNightOwl;
      case 'early_bird':
        return l10n.badgeRequirementEarlyBird;
      case 'balance_master':
        return l10n.badgeRequirementBalanceMaster;
      default:
        return '';
    }
  }
}
