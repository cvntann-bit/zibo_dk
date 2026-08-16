/// Bir hedefin bir 7 günlük döngüyü BAŞARIYLA tamamladığı ana ait kalıcı
/// kayıt. `Goal.completedDates`/`cycleStartDate` bir döngü bitince
/// SIFIRLANIP yeni döngüye hazırlandığı için (bkz.
/// `GoalsProvider.toggleToday`), bu kayıt olmadan geçmiş tamamlanmaların
/// HİÇBİR İZİ kalmazdı. [goalName], tamamlanma ANINDAKİ ismin bir anlık
/// görüntüsü — hedef sonradan yeniden adlandırılsa/silinse bile geçmiş
/// kaydı bozulmasın diye `goalId` yerine bu alan gruplamada kullanılıyor.
class GoalCompletion {
  const GoalCompletion({
    required this.goalId,
    required this.goalName,
    required this.cycleStartDate,
    required this.completionDate,
  });

  final String goalId;
  final String goalName;

  /// Tamamlanan döngünün Gün 1'inin tarihi.
  final DateTime cycleStartDate;

  /// Döngünün 7. (son) gününün işaretlendiği gerçek takvim tarihi.
  final DateTime completionDate;
}
