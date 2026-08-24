import '../utils/profile_stats.dart';

/// Bir ayın sonunda (bkz. `ProfileStatsArchiveProvider`) o anki CANLI
/// "İstatistiklerim" sonucunun (bkz. `ProfileStats.compute`) donmuş bir
/// kopyası. `ProfileStats.compute`'un kendisi (rolling-window formülleri)
/// hiç DEĞİŞTİRİLMEDİ — bu yalnızca ay değişimi anında o formüllerin
/// döndürdüğü sonucu arşivliyor.
class MonthlyStatsSnapshot {
  const MonthlyStatsSnapshot({
    required this.year,
    required this.month,
    required this.scores,
  });

  final int year;

  /// 1 (Ocak) - 12 (Aralık).
  final int month;

  /// `ProfileStatCategory.name` → puan (0-10) eşlemesi. O kategoride veri
  /// yoksa (`CategoryStat.hasData == false`) map'te hiç anahtar bulunmaz.
  final Map<String, double> scores;

  double? scoreFor(ProfileStatCategory category) => scores[category.name];
}
