import '../providers/app_streak_provider.dart';
import '../providers/app_theme_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/dream_journal_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/hidden_badge_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/water_provider.dart';

/// Rozet Sistemi'nin ALTI kategorisinin de (İstikrar + Modül Ustalığı +
/// Koleksiyon + Sadakat + Sosyal/Paylaşım + Gizli/Eğlenceli) kazanma
/// kontrolünü, ilgili kaynak veri her güncellendiğinde OTOMATİK tetikleyen
/// koordinatör — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// `HomeWidgetSyncCoordinator`'ın AYNI "constructor'dan değil PARAMETRE
/// olarak al, dışarıdan `addListener` ekle" deseni: bu obje on üç
/// provider'ın (Badges, Goals, AppStreak, Gratitude, Water, Mood, Money,
/// Manifest, Dream, Costume, AppTheme, Profile, Referral, HiddenBadge)
/// HİÇBİRİNE KALICI bağımlı değil, yalnızca onları dinleyip [BadgeProvider.
/// reconcileConsistencyBadges]/[BadgeProvider.reconcileModuleMasteryBadges]/
/// [BadgeProvider.reconcileCollectionBadges]/[BadgeProvider.
/// reconcileLoyaltyBadges]/[BadgeProvider.reconcileSocialBadges]/
/// [BadgeProvider.reconcileHiddenBadges]'i çağırıyor.
///
/// **`reconcileSocialBadges`'in `hasSharedAtLeastOnce` parametresi BURADA
/// HER ZAMAN `false` geçiriliyor** — `first_share`'in TEK gerçek tetikleyicisi
/// `ZiboShareSheet._share()`'in KENDİSİ (bkz. o widget'taki AYRI çağrı); bu
/// rutin geçiş yalnızca `ambassador`/`community_founder`'ı (ReferralProvider'a
/// bağlı, DURUM-tabanlı) reaktif olarak kontrol ediyor.
///
/// **`hasAllModulesToday` ("Denge Ustası") BURADA hesaplanıp
/// `reconcileHiddenBadges`'e tek bir bool olarak geçiriliyor** — YEDİ modül
/// provider'ının ("Hedef Takibi, Şükran Günlüğü, Ruh Hali Takibi, Su
/// Takibi, Manifest Günlüğü, Rüya Günlüğü, Para ve Birikim, bkz.
/// `hidden_badges.dart`) HEPSİ zaten bu koordinatörün constructor
/// parametreleri — yeni bir provider bağımlılığı GEREKMEDİ, yalnızca
/// mevcut yedisinin "bugün bir kaydı var mı" getter'ları `&&` ile
/// birleştirildi.
///
/// `RootScreen.initState()`'te BİR KEZ oluşturulur (constructor'ın kendisi de
/// EAGER bir ilk kontrol yapar — uygulama açılışında zaten karşılanmış bir
/// koşul varsa ilk `addListener` tetiklenene kadar beklenmez), `dispose()`'da
/// listener'lar temizlenir.
class BadgeCoordinator {
  BadgeCoordinator({
    required this.badges,
    required this.goals,
    required this.appStreak,
    required this.gratitude,
    required this.water,
    required this.mood,
    required this.money,
    required this.manifest,
    required this.dream,
    required this.costume,
    required this.appTheme,
    required this.profile,
    required this.referral,
    required this.hiddenBadge,
  }) {
    goals.addListener(_reconcile);
    appStreak.addListener(_reconcile);
    gratitude.addListener(_reconcile);
    water.addListener(_reconcile);
    mood.addListener(_reconcile);
    money.addListener(_reconcile);
    manifest.addListener(_reconcile);
    dream.addListener(_reconcile);
    costume.addListener(_reconcile);
    appTheme.addListener(_reconcile);
    profile.addListener(_reconcile);
    referral.addListener(_reconcile);
    hiddenBadge.addListener(_reconcile);
    _reconcile();
  }

  final BadgeProvider badges;
  final GoalsProvider goals;
  final AppStreakProvider appStreak;
  final GratitudeProvider gratitude;
  final WaterProvider water;
  final MoodProvider mood;
  final MoneyProvider money;
  final ManifestProvider manifest;
  final DreamJournalProvider dream;
  final CostumeProvider costume;
  final AppThemeProvider appTheme;
  final ProfileProvider profile;
  final ReferralProvider referral;
  final HiddenBadgeProvider hiddenBadge;

  void _reconcile() {
    badges.reconcileConsistencyBadges(
      hasCompletedFirstGoalCycle: goals.completions.isNotEmpty,
      appOpenStreak: appStreak.currentStreak,
    );
    badges.reconcileModuleMasteryBadges(
      gratitudeCount: gratitude.entries.length,
      waterDaysCount: water.totalDaysRecorded,
      moodCount: mood.entries.length,
      moneyCount: money.totalEntryCount,
      manifestCount: manifest.history.length,
      dreamCount: dream.dreams.length,
    );
    badges.reconcileCollectionBadges(
      ownedCostumeCount: costume.ownedRealCostumeCount,
      ownsAllCostumes: costume.ownsAllCostumes,
      ownedThemeCount: appTheme.ownedIds.length,
    );
    badges.reconcileLoyaltyBadges(
      totalDaysOpened: appStreak.totalDaysOpened,
      daysSinceFirstUsed: profile.daysSinceFirstUsed(),
    );
    badges.reconcileSocialBadges(
      hasSharedAtLeastOnce: false,
      successfulReferralCount: referral.successfulReferralCount,
    );
    badges.reconcileHiddenBadges(
      nightOwlDaysCount: hiddenBadge.nightOwlDaysCount,
      earlyBirdDaysCount: hiddenBadge.earlyBirdDaysCount,
      hasAllModulesToday:
          goals.hasAnyRecordToday &&
          gratitude.isTodayComplete &&
          mood.todayMood != null &&
          water.todayEntry != null &&
          manifest.hasEntryToday &&
          dream.hasEntryToday &&
          money.hasEntryToday,
    );
  }

  void dispose() {
    goals.removeListener(_reconcile);
    appStreak.removeListener(_reconcile);
    gratitude.removeListener(_reconcile);
    water.removeListener(_reconcile);
    mood.removeListener(_reconcile);
    money.removeListener(_reconcile);
    manifest.removeListener(_reconcile);
    dream.removeListener(_reconcile);
    costume.removeListener(_reconcile);
    appTheme.removeListener(_reconcile);
    profile.removeListener(_reconcile);
    referral.removeListener(_reconcile);
    hiddenBadge.removeListener(_reconcile);
  }
}
