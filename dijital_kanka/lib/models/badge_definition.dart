import '../l10n/app_localizations.dart';

/// Rozet Sistemi'ndeki kategoriler — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// [consistency] + [moduleMastery] dolu; kullanıcının planladığı diğer
/// kategoriler (Koleksiyon, Sadakat, Sosyal/Paylaşım, Gizli/Eğlenceli) ayrı
/// ayrı turlarda eklenecek.
enum BadgeCategory { consistency, moduleMastery }

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
  });

  final String id;
  final BadgeCategory category;
  final String imageAsset;
  final int zcReward;

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
      default:
        return '';
    }
  }
}
