/// Su Takibi'nde kullanıcının su içme birimi — bardak veya şişe. Her birinin
/// ml değeri `WaterProvider`'da AYRI ayarlanabilir (bkz. `glassMl`/`bottleMl`).
enum WaterUnit { glass, bottle }

/// Su Takibi'nde tek bir güne ait kayıt. `goalUnitCount`, o günkü hedefi
/// AYRI olarak saklıyor (kullanıcının o an geçerli tercihini değil) — bu
/// sayede kullanıcı ileride hedefini değiştirirse geçmiş günlerin
/// "tamamlandı" durumu geriye dönük olarak bozulmaz. Aynı gerekçeyle [unit]
/// ve [mlPerUnit] da o günkü ayarların anlık görüntüsü.
class WaterEntry {
  const WaterEntry({
    required this.date,
    required this.unitCount,
    required this.goalUnitCount,
    required this.unit,
    required this.mlPerUnit,
    this.rewardClaimed = false,
  });

  final DateTime date;
  final int unitCount;
  final int goalUnitCount;
  final WaterUnit unit;
  final int mlPerUnit;
  final bool rewardClaimed;

  bool get isCompleted => unitCount >= goalUnitCount;
  int get consumedMl => unitCount * mlPerUnit;
  int get goalMl => goalUnitCount * mlPerUnit;

  WaterEntry copyWith({
    int? unitCount,
    int? goalUnitCount,
    WaterUnit? unit,
    int? mlPerUnit,
    bool? rewardClaimed,
  }) => WaterEntry(
    date: date,
    unitCount: unitCount ?? this.unitCount,
    goalUnitCount: goalUnitCount ?? this.goalUnitCount,
    unit: unit ?? this.unit,
    mlPerUnit: mlPerUnit ?? this.mlPerUnit,
    rewardClaimed: rewardClaimed ?? this.rewardClaimed,
  );
}
