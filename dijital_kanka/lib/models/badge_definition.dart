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
    this.isHidden = false,
  });

  final String id;
  final BadgeCategory category;
  final String imageAsset;
  final int zcReward;

  /// **Kostüm/tema hediyesi — 2026 mimari değişikliği.** Bu rozetin
  /// standart ZC ödülüne EK olarak bir kostüm/tema hediye edip
  /// ETMEDİĞİNİ/hangisini vereceğini BURADA (bu sınıfta) TUTMUYORUZ —
  /// eski genel `hasSpecialReward` bool bayrağının YERİNE, `data/
  /// badge_gift_rewards.dart`'taki SABİT, id→hediye eşlemesi
  /// (`badgeGiftRewards[id]`) geçti. Yalnızca DOKUZ belirli rozet bir
  /// hediye taşıyor (kullanıcının açık isteği/eşleme listesi) — diğer TÜM
  /// rozetler yalnızca [zcReward] veriyor. Bkz. `BadgeCelebrationOverlay`
  /// (kazanma anındaki hediye verme mantığı) ve `BadgesGalleryScreen`
  /// (galeri kartındaki 🎁 önizleme satırı).

  /// **Gizli/Eğlenceli Rozetler'e özel — bkz. `hidden_badges.dart`.**
  /// `true` iken, bu rozet KAZANILANA kadar `BadgesGalleryScreen`'in
  /// `_BadgeGalleryCard`'ı [imageAsset]/[localizedName]/[localizedRequirement]'ı
  /// GİZLER — bunun yerine paylaşılan bir gizem görseli
  /// (`hiddenBadgeMysteryImageAsset`) + `l10n.badgeHiddenPlaceholder`
  /// ("???") gösterir, kullanıcı rozeti TESADÜFEN/KEŞFEDEREK kazansın diye
  /// (kullanıcının açık isteği). **[zcReward] İSTİSNA — HER ZAMAN görünür**
  /// (2026 İKİNCİ güncelleme, kullanıcının netleştirmesi — ilk sürümde
  /// ödül de gizliydi). **Kazanıldıktan SONRA bu bayrağın HİÇBİR etkisi
  /// kalmaz** — `BadgeCelebrationOverlay`'in kutlama popup'ı VE galerideki
  /// kart, TÜM diğer rozetlerle AYNI şekilde gerçek görsel/isim/koşul/ödülü
  /// gösterir (`_BadgeGalleryCard`'daki kontrol `badge.isHidden &&
  /// !earned`'a bağlı, yalnızca `earned` DEĞİLKEN devrede).
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
