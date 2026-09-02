import '../providers/app_streak_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/goals_provider.dart';

/// İstikrar Rozetleri'nin kazanma kontrolünü, ilgili kaynak veri (Hedef
/// Takibi'nin tamamlanma geçmişi + uygulama-açma serisi) her güncellendiğinde
/// OTOMATİK tetikleyen koordinatör — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
/// `HomeWidgetSyncCoordinator`'ın AYNI "constructor'dan değil PARAMETRE olarak
/// al, dışarıdan `addListener` ekle" deseni: bu obje `BadgeProvider`/
/// `GoalsProvider`/`AppStreakProvider`'a KALICI bağımlı değil, yalnızca
/// onları dinleyip [BadgeProvider.reconcileConsistencyBadges]'i çağırıyor.
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
  }) {
    goals.addListener(_reconcile);
    appStreak.addListener(_reconcile);
    _reconcile();
  }

  final BadgeProvider badges;
  final GoalsProvider goals;
  final AppStreakProvider appStreak;

  void _reconcile() {
    badges.reconcileConsistencyBadges(
      hasCompletedFirstGoalCycle: goals.completions.isNotEmpty,
      appOpenStreak: appStreak.currentStreak,
    );
  }

  void dispose() {
    goals.removeListener(_reconcile);
    appStreak.removeListener(_reconcile);
  }
}
