import '../models/goal.dart';
import '../models/money_entry.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/water_provider.dart';

/// Profil ekranındaki "İstatistiklerim" bölümünün dört sabit kategorisi.
enum ProfileStatCategory { money, gratitudeManifest, consistency, selfCareHealth }

/// Bir kategorinin hesaplanmış durumu — 0-10 ortalama puan (dairesel
/// gösterge için) + son 8 haftalık ham trend değerleri (küçük çizgi grafik
/// için, kategoriye göre anlamı değişir: para için haftalık net
/// birikim tutarı, diğerleri için haftalık "iyi gün/kayıt" sayısı — grafik
/// widget'ı kendi min/max'ına göre ölçeklediği için ortak bir birim
/// gerekmiyor). [hasData] `false` ise kullanıcı bu kategoride HİÇ kayıt
/// girmemiş demektir — [score]/[trendPoints] anlamsızdır (0/boş).
class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.hasData,
    this.score = 0,
    this.trendPoints = const [],
  });

  final ProfileStatCategory category;
  final bool hasData;
  final double score;
  final List<double> trendPoints;
}

/// Dört kategorinin puanını/trendini kaynak provider'ların GÜNCEL durumundan
/// canlı hesaplar — ayrı bir kalıcı state DEĞİL (bkz. `ProfileScreen`, hepsi
/// `context.watch` ile izlenen provider'lar değiştiğinde otomatik yeniden
/// hesaplanır). Formüller kasıtlı olarak basit/açıklanabilir tutuldu —
/// "mükemmel" bir finans/alışkanlık skoru değil, kullanıcıya kabaca bir
/// yön göstermesi yeterli.
class ProfileStats {
  const ProfileStats._();

  /// Trend grafiklerinin kapsadığı hafta sayısı (bu hafta dahil).
  static const trendWeeks = 8;

  static List<CategoryStat> compute({
    required MoneyProvider money,
    required GratitudeProvider gratitude,
    required ManifestProvider manifest,
    required GoalsProvider goals,
    required WaterProvider water,
    required DateTime now,
  }) {
    return [
      _moneyStat(money, now),
      _gratitudeManifestStat(gratitude, manifest, now),
      _consistencyStat(goals, now),
      _selfCareHealthStat(water, now),
    ];
  }

  /// **Para Yönetimi:** iki bileşenin ağırlıklı ortalaması —
  /// (1) %70 ağırlık: birikim oranı (`birikim / (birikim + harcama)`).
  /// %50 birikim oranı tam puan (10) sayılır — kişisel finansta sık
  /// önerilen "en az %20 biriktir" kuralının üzerinde, cömert ama makul
  /// bir hedef, tam %100 birikim (hiç harcama yok) şart koşulmuyor.
  /// (2) %30 ağırlık: son 4 haftanın kaçında en az bir kayıt girilmiş —
  /// düzenli takip alışkanlığını ödüllendirir.
  static CategoryStat _moneyStat(MoneyProvider money, DateTime now) {
    final expenses = money.entriesFor(MoneyCategory.expense);
    final savings = money.entriesFor(MoneyCategory.saving);
    if (expenses.isEmpty && savings.isEmpty) {
      return const CategoryStat(category: ProfileStatCategory.money, hasData: false);
    }

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSaving = savings.fold(0.0, (sum, e) => sum + e.amount);
    final denominator = totalExpense + totalSaving;
    final savingsRatio = denominator == 0 ? 0.0 : totalSaving / denominator;
    final ratioScore = (savingsRatio / 0.5 * 10).clamp(0.0, 10.0);

    final allDates = [...expenses, ...savings].map((e) => e.date).toList();
    final weekly4 = _weeklyCounts(allDates, now, weeks: 4);
    final weeksWithEntries = weekly4.where((count) => count > 0).length;
    final consistencyScore = (weeksWithEntries / 4) * 10;

    final score = (ratioScore * 0.7 + consistencyScore * 0.3).clamp(0.0, 10.0);

    // Grafik: haftalık net birikim (birikim - harcama) — negatif de olabilir.
    final weeklyNet = _weeklyNetAmounts(savings, expenses, now);

    return CategoryStat(
      category: ProfileStatCategory.money,
      hasData: true,
      score: score,
      trendPoints: weeklyNet,
    );
  }

  /// **Şükür ve Manifest:** son 30 günün kaçında Şükran Günlüğü VE kaçında
  /// Manifest Günlüğü kullanıldığının (farklı gün sayısı, aynı gün birden
  /// fazla manifest girişi tek gün sayılır) ortalama oranı.
  static CategoryStat _gratitudeManifestStat(
    GratitudeProvider gratitude,
    ManifestProvider manifest,
    DateTime now,
  ) {
    if (gratitude.entries.isEmpty && manifest.history.isEmpty) {
      return const CategoryStat(category: ProfileStatCategory.gratitudeManifest, hasData: false);
    }

    final windowStart = _daysAgo(now, 29);
    final gratitudeDays = _distinctDaysInWindow(
      gratitude.entries.map((e) => e.date),
      windowStart,
    );
    final manifestDays = _distinctDaysInWindow(
      manifest.history.map((e) => e.date),
      windowStart,
    );

    final gratitudeRatio = gratitudeDays.length / 30;
    final manifestRatio = manifestDays.length / 30;
    final score = ((gratitudeRatio + manifestRatio) / 2 * 10).clamp(0.0, 10.0);

    final allDates = [
      ...gratitude.entries.map((e) => e.date),
      ...manifest.history.map((e) => e.date),
    ];
    final weekly = _weeklyCounts(allDates, now, weeks: trendWeeks);

    return CategoryStat(
      category: ProfileStatCategory.gratitudeManifest,
      hasData: true,
      score: score,
      trendPoints: weekly.map((e) => e.toDouble()).toList(),
    );
  }

  /// **İstikrar:** iki bileşenin ağırlıklı ortalaması —
  /// (1) %60 ağırlık: aktif hedeflerin GÜNCEL döngüdeki ortalama ilerlemesi
  /// (`completedCount / 7`) — kullanıcının ŞU AN ne kadar yolunda olduğunu
  /// yansıtan, gerçek zamanlı sinyal.
  /// (2) %40 ağırlık: son 8 haftada tamamlanan TAM 7-günlük döngü sayısı,
  /// 3 tamamlama = tam puan olacak şekilde oranlanır (`totalCompletions / 3`)
  /// — bir döngüyü baştan sona tamamlamak zaten yüksek bir bar olduğu için
  /// (7 gün kesintisiz), iki ayda 3 kez başarmak "tutarlı kullanıcı" için
  /// makul/ulaşılabilir bir eşik (8 haftada 8 TAM tamamlama isteyen eski
  /// formül neredeyse hiç kimsenin ulaşamayacağı kadar katıydı).
  ///
  /// **2026 bug düzeltmesi — gerçek kullanıcı raporu: "İstikrar çalışmıyor."**
  /// Eski formül (%40 güncel + %60 geçmiş, geçmiş bileşeni 8/8 TAM
  /// tamamlama gerektiriyordu) günlük olarak düzenli check-in yapan ama
  /// henüz hiç 7 günü kesintisiz TAMAMLAMAMIŞ (bir gün bile kaçırmak
  /// `GoalsProvider`'ın döngüyü ANINDA sıfırlaması yüzünden çok kolay
  /// gerçekleşiyor) bir kullanıcı için puanı SÜREKLİ neredeyse 0'da
  /// tutuyordu — kullanıcı aktif olarak kullanıyor olsa bile "çalışmıyor"
  /// gibi görünüyordu. Ağırlıklar ters çevrilip geçmiş eşiği gevşetildi ki
  /// gerçek (kusursuz olmasa da) katılım anlamlı bir puana yansısın — tıpkı
  /// Para Yönetimi'nin %50 birikim oranını zaten tam puan sayması gibi.
  static CategoryStat _consistencyStat(GoalsProvider goals, DateTime now) {
    final hasActiveGoals = goals.goals.isNotEmpty;
    final hasCompletions = goals.completions.isNotEmpty;
    if (!hasActiveGoals && !hasCompletions) {
      return const CategoryStat(category: ProfileStatCategory.consistency, hasData: false);
    }

    final currentRatio = hasActiveGoals
        ? goals.goals
                  .map((g) => g.completedCount / Goal.daysPerCycle)
                  .reduce((a, b) => a + b) /
              goals.goals.length
        : 0.0;

    final completionDates = goals.completions.map((c) => c.completionDate).toList();
    final weekly = _weeklyCounts(completionDates, now, weeks: trendWeeks);
    final totalCompletions = weekly.fold(0, (sum, count) => sum + count);
    final historicalRatio = (totalCompletions / 3).clamp(0.0, 1.0);

    final score = ((currentRatio * 0.6 + historicalRatio * 0.4) * 10).clamp(0.0, 10.0);

    return CategoryStat(
      category: ProfileStatCategory.consistency,
      hasData: true,
      score: score,
      trendPoints: weekly.map((e) => e.toDouble()).toList(),
    );
  }

  /// **Öz Saygı ve Sağlık:** son 30 gündeki GÜNLÜK KISMİ ilerleme
  /// oranlarının (`unitCount / goalUnitCount`, 1.0'da kırpılır) ortalaması —
  /// kayıt hiç girilmemiş günler 0 oranla sayılır (30 sabit payda), böylece
  /// yalnızca birkaç gün kullanıp bırakmak yapay olarak yüksek bir puana
  /// yol açmaz.
  ///
  /// **2026 bug düzeltmesi — gerçek kullanıcı raporu: "Öz Saygı ve Sağlık
  /// çalışmıyor."** Eski formül günü YALNIZCA hedefe %100 ulaşılmışsa
  /// (`isCompleted`, ikili/hepsi-ya-da-hiçbiri) sayıyordu — günde 8
  /// bardaktan 5-6'sını içen ama nadiren tam 8'e ulaşan (gerçekçi, yaygın
  /// bir kullanım deseni) bir kullanıcı HER GÜN 0 kredi alıyor, puan
  /// SÜREKLİ 0'a yakın kalıyordu. Artık her günün KISMİ oranı doğrudan
  /// sayılıyor (ör. 6/8 bardak = 0.75 kredi) — gerçek (kusursuz olmasa da)
  /// katılım artık puana yansıyor.
  static CategoryStat _selfCareHealthStat(WaterProvider water, DateTime now) {
    final today = water.todayEntry;
    final allEntries = [...water.history, if (today != null) today];
    if (allEntries.isEmpty) {
      return const CategoryStat(category: ProfileStatCategory.selfCareHealth, hasData: false);
    }

    final windowStart = _daysAgo(now, 29);
    final recent = allEntries.where((e) => !e.date.isBefore(windowStart)).toList();
    final totalRatio = recent.fold(
      0.0,
      (sum, e) => sum + (e.goalUnitCount == 0 ? 0.0 : (e.unitCount / e.goalUnitCount).clamp(0.0, 1.0)),
    );
    final score = (totalRatio / 30 * 10).clamp(0.0, 10.0);

    final weekly = _weeklyCounts(
      recent.where((e) => e.isCompleted).map((e) => e.date).toList(),
      now,
      weeks: trendWeeks,
    );

    return CategoryStat(
      category: ProfileStatCategory.selfCareHealth,
      hasData: true,
      score: score,
      trendPoints: weekly.map((e) => e.toDouble()).toList(),
    );
  }

  static DateTime _daysAgo(DateTime now, int days) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: days));
  }

  static Set<DateTime> _distinctDaysInWindow(
    Iterable<DateTime> dates,
    DateTime windowStart,
  ) {
    return dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => !d.isBefore(windowStart))
        .toSet();
  }

  static DateTime _mondayOf(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
  }

  /// [dates]'i Pazartesi başlangıçlı haftalara böler, son [weeks] haftayı
  /// (bu hafta dahil, EN ESKİDEN EN YENİYE sıralı) her haftadaki kayıt
  /// SAYISI olarak döner — grafik/tutarlılık hesaplarının paylaştığı ortak
  /// bucketing mantığı.
  static List<int> _weeklyCounts(
    List<DateTime> dates,
    DateTime now, {
    required int weeks,
  }) {
    final thisMonday = _mondayOf(now);
    final buckets = List<int>.filled(weeks, 0);
    for (final date in dates) {
      final weekIndex = thisMonday.difference(_mondayOf(date)).inDays ~/ 7;
      final bucketIndex = weeks - 1 - weekIndex;
      if (bucketIndex >= 0 && bucketIndex < weeks) {
        buckets[bucketIndex]++;
      }
    }
    return buckets;
  }

  static List<double> _weeklyNetAmounts(
    List<MoneyEntry> savings,
    List<MoneyEntry> expenses,
    DateTime now,
  ) {
    final thisMonday = _mondayOf(now);
    final buckets = List<double>.filled(trendWeeks, 0);
    void addAll(List<MoneyEntry> entries, double sign) {
      for (final entry in entries) {
        final weekIndex = thisMonday.difference(_mondayOf(entry.date)).inDays ~/ 7;
        final bucketIndex = trendWeeks - 1 - weekIndex;
        if (bucketIndex >= 0 && bucketIndex < trendWeeks) {
          buckets[bucketIndex] += entry.amount * sign;
        }
      }
    }

    addAll(savings, 1);
    addAll(expenses, -1);
    return buckets;
  }
}
