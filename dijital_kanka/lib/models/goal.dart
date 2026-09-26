/// Bir hedefin 7 günlük döngüsünde tek bir gün kutucuğunun görsel/etkileşim
/// durumu — tamamı gerçek takvim tarihine göre hesaplanır.
enum GoalDayStatus {
  /// İşaretlenmiş (geçmişte veya bugün).
  done,

  /// Tarihi geçmiş ama işaretlenmemiş — kaçırılmış.
  missed,

  /// Bugünün tarihi — tek işaretlenebilir kutucuk.
  today,

  /// Tarihi henüz gelmemiş — kilitli, dokunulamaz.
  upcoming,

  /// Kaçırılmış ama Streak Freeze ile dondurulmuş — döngü sıfırlanmadan
  /// devam eder, 7/7'ye sayılır (mavi ❄️).
  frozen,
}

/// Kullanıcının takip ettiği tek bir hedef. Güncel 7 günlük döngü,
/// [cycleStartDate] (Gün 1'in gerçek takvim tarihi) ve o döngüde işaretlenmiş
/// tarihlerin kümesiyle temsil edilir; gün numaraları asla kendi başına bir
/// sayaç değil, hep bir tarihe karşılık gelir.
class Goal {
  Goal({
    required this.id,
    required this.name,
    required DateTime cycleStartDate,
  }) : cycleStartDate = dateOnly(cycleStartDate),
       completedDates = <DateTime>{},
       frozenDates = <DateTime>{};

  static const int daysPerCycle = 7;

  final String id;
  String name;

  /// Güncel döngüde Gün 1'in tarihi (saat bileşeni olmadan, gece yarısı).
  DateTime cycleStartDate;

  /// Güncel döngüde işaretlenmiş (tamamlanmış) tarihler.
  Set<DateTime> completedDates;

  /// Güncel döngüde Streak Freeze ile dondurulmuş (kaçırılmış ama
  /// korunan) tarihler.
  Set<DateTime> frozenDates;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime dateForDay(int dayIndex) =>
      cycleStartDate.add(Duration(days: dayIndex));

  GoalDayStatus statusForDay(int dayIndex, DateTime today) {
    final date = dateForDay(dayIndex);
    if (completedDates.contains(date)) return GoalDayStatus.done;
    if (frozenDates.contains(date)) return GoalDayStatus.frozen;
    if (date.isBefore(today)) return GoalDayStatus.missed;
    if (date.isAtSameMomentAs(today)) return GoalDayStatus.today;
    return GoalDayStatus.upcoming;
  }

  /// Gerçekten işaretlenen gün sayısı.
  int get completedCount => completedDates.length;

  /// Döngü ilerlemesi: işaretlenen + dondurulan günler (7/7'ye bunlar sayılır).
  int get progressCount => completedDates.length + frozenDates.length;

  bool isCovered(DateTime date) => completedDates.contains(date) || frozenDates.contains(date);
}
