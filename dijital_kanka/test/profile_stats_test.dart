// ProfileStats.compute()'un dört kategori formülünün (bkz. profile_stats.dart
// içindeki dokümantasyon) mantıklı/tutarlı davrandığını doğrular: hiç veri
// yokken doğru "veri yok" durumunu, daha iyi davranışın her zaman daha
// yüksek puan ürettiğini ve uç durumlarda (tam tamamlama, hiç veri)
// beklenen tam değerleri.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/money_entry.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/utils/profile_stats.dart';

CategoryStat _statFor(List<CategoryStat> stats, ProfileStatCategory category) =>
    stats.firstWhere((s) => s.category == category);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Hiçbir modülde veri yokken (kullanıcı hiç hedef eklemediyse dahil, bkz. '
    '2026 güncellemesi — GoalsProvider artık otomatik bir örnek hedef '
    'eklemiyor) TÜM kategoriler "veri yok" döner',
    () async {
      final money = MoneyProvider();
      final gratitude = GratitudeProvider();
      final manifest = ManifestProvider();
      final goals = GoalsProvider();
      final water = WaterProvider();
      await Future<void>.delayed(Duration.zero);

      final stats = ProfileStats.compute(
        money: money,
        gratitude: gratitude,
        manifest: manifest,
        goals: goals,
        water: water,
        now: DateTime(2026, 3, 16),
      );

      expect(_statFor(stats, ProfileStatCategory.money).hasData, isFalse);
      expect(_statFor(stats, ProfileStatCategory.gratitudeManifest).hasData, isFalse);
      expect(_statFor(stats, ProfileStatCategory.selfCareHealth).hasData, isFalse);
      expect(_statFor(stats, ProfileStatCategory.consistency).hasData, isFalse);
    },
  );

  test(
    'Kullanıcı en az bir hedef ekleyince İstikrar kategorisi puanlı "veri '
    'var" döner',
    () async {
      final money = MoneyProvider();
      final gratitude = GratitudeProvider();
      final manifest = ManifestProvider();
      final goals = GoalsProvider();
      final water = WaterProvider();
      await Future<void>.delayed(Duration.zero);
      goals.addGoal('Günde 30 dakika kitap oku');

      final stats = ProfileStats.compute(
        money: money,
        gratitude: gratitude,
        manifest: manifest,
        goals: goals,
        water: water,
        now: DateTime(2026, 3, 16),
      );

      final consistency = _statFor(stats, ProfileStatCategory.consistency);
      expect(consistency.hasData, isTrue);
      expect(consistency.score, 0);
    },
  );

  test(
    'Para Yönetimi: yüksek birikim oranı, yüksek harcama oranından her zaman '
    'daha yüksek puan alır',
    () async {
      final mostlySaving = MoneyProvider(now: () => DateTime(2026, 3, 16));
      await Future<void>.delayed(Duration.zero);
      mostlySaving.addEntry(MoneyCategory.saving, name: 'Birikim', amount: 1000, currencyCode: 'TRY');

      // İki provider AYNI (varsayılan uid==null) yerel SharedPreferences
      // deposunu paylaşır — ikinci provider'ın ilkinin verisini yanlışlıkla
      // yüklememesi için mock depoyu burada sıfırlıyoruz (gerçek
      // uygulamada asla iki MoneyProvider AYNI ANDA var olmaz, bu yalnızca
      // testin kendi izolasyon ihtiyacı).
      SharedPreferences.setMockInitialValues({});
      final mostlySpending = MoneyProvider(now: () => DateTime(2026, 3, 16));
      await Future<void>.delayed(Duration.zero);
      mostlySpending.addEntry(MoneyCategory.expense, name: 'Harcama', amount: 1000, currencyCode: 'TRY');

      final statsSaving = ProfileStats.compute(
        money: mostlySaving,
        gratitude: GratitudeProvider(),
        manifest: ManifestProvider(),
        goals: GoalsProvider(),
        water: WaterProvider(),
        now: DateTime(2026, 3, 16),
      );
      final statsSpending = ProfileStats.compute(
        money: mostlySpending,
        gratitude: GratitudeProvider(),
        manifest: ManifestProvider(),
        goals: GoalsProvider(),
        water: WaterProvider(),
        now: DateTime(2026, 3, 16),
      );

      final savingScore = _statFor(statsSaving, ProfileStatCategory.money).score;
      final spendingScore = _statFor(statsSpending, ProfileStatCategory.money).score;

      expect(savingScore, greaterThan(spendingScore));
      // %100 birikim oranı -> ratioScore tam puan (10) * %70 + tutarlılık
      // (tek haftada tek kayıt: 1/4 hafta) * %30 = 7 + 0.75 = 7.75.
      expect(savingScore, closeTo(7.75, 0.01));
      // %0 birikim oranı -> ratioScore 0 + AYNI tutarlılık payı 0.75.
      expect(spendingScore, closeTo(0.75, 0.01));
    },
  );

  test(
    'İstikrar: 2026 bug düzeltmesi — bir haftanın YARISINDAN FAZLASINI '
    'check-in yapan (ama hiç tam 7 gün TAMAMLAMAMIŞ) bir kullanıcı artık '
    'anlamlı bir puan alır (eski formül bunu neredeyse 0\'da tutuyordu)',
    () async {
      var current = DateTime(2026, 3, 10);
      final goals = GoalsProvider(now: () => current);
      await Future<void>.delayed(Duration.zero);
      goals.addGoal('Günde 30 dakika kitap oku');
      final goalId = goals.goals.first.id;

      // 4 gün art arda işaretlendi (döngü TAMAMLANMADI — 5-7. günler boş).
      for (var i = 0; i < 4; i++) {
        goals.toggleToday(goalId);
        current = current.add(const Duration(days: 1));
      }

      final stats = ProfileStats.compute(
        money: MoneyProvider(),
        gratitude: GratitudeProvider(),
        manifest: ManifestProvider(),
        goals: goals,
        water: WaterProvider(),
        now: current,
      );

      final consistency = _statFor(stats, ProfileStatCategory.consistency);
      expect(consistency.hasData, isTrue);
      // 4/7 gün * %60 ağırlık * 10 = ~3.43 (hiç tam tamamlama yok, geçmiş
      // bileşeni 0). Eski formülde bu ~1.71 idi — kullanıcı raporunun tam
      // konusu buydu.
      expect(consistency.score, closeTo(3.43, 0.1));
      expect(consistency.score, greaterThan(3));
    },
  );

  test(
    'Öz Saygı ve Sağlık: 2026 bug düzeltmesi — hedefin YARISINI her gün '
    'düzenli olarak tamamlayan (ama ASLA %100\'e ulaşmayan) bir kullanıcı '
    'artık anlamlı bir puan alır (eski formül bunu 0\'da tutuyordu)',
    () async {
      var current = DateTime(2026, 2, 15);
      final water = WaterProvider(now: () => current);
      await Future<void>.delayed(Duration.zero);

      // 30 gün boyunca HER GÜN hedefin tam yarısını içiyor (8 bardaklık
      // varsayılan hedefin 4'ü) — ASLA tam tamamlamıyor.
      for (var i = 0; i < 30; i++) {
        current = DateTime(2026, 2, 15).add(Duration(days: i));
        water.incrementUnit();
        water.incrementUnit();
        water.incrementUnit();
        water.incrementUnit();
      }

      final stats = ProfileStats.compute(
        money: MoneyProvider(),
        gratitude: GratitudeProvider(),
        manifest: ManifestProvider(),
        goals: GoalsProvider(),
        water: water,
        now: DateTime(2026, 3, 16),
      );

      final waterStat = _statFor(stats, ProfileStatCategory.selfCareHealth);
      expect(waterStat.hasData, isTrue);
      // Her gün 4/8 = 0.5 kısmi kredi -> ortalama 0.5 -> puan 5.0. Eski
      // (ikili/hepsi-ya-da-hiçbiri) formülde bu 0 idi (hiçbir gün %100
      // tamamlanmadığı için).
      expect(waterStat.score, closeTo(5.0, 0.1));
    },
  );

  test('Öz Saygı ve Sağlık: son 30 günün tamamı hedefi tamamlarsa puan tam 10 olur', () async {
    var current = DateTime(2026, 2, 15);
    final water = WaterProvider(now: () => current);
    await Future<void>.delayed(Duration.zero);

    for (var i = 0; i < 30; i++) {
      current = DateTime(2026, 2, 15).add(Duration(days: i));
      while (!water.isTodayComplete) {
        water.incrementUnit();
      }
    }

    final stats = ProfileStats.compute(
      money: MoneyProvider(),
      gratitude: GratitudeProvider(),
      manifest: ManifestProvider(),
      goals: GoalsProvider(),
      water: water,
      now: DateTime(2026, 3, 16),
    );

    final waterStat = _statFor(stats, ProfileStatCategory.selfCareHealth);
    expect(waterStat.hasData, isTrue);
    expect(waterStat.score, closeTo(10, 0.01));
    expect(waterStat.trendPoints, hasLength(ProfileStats.trendWeeks));
  });

  test(
    'Şükür ve Manifest: Şükran Günlüğü kullanılınca "veri yok" durumundan çıkar '
    've puan 0\'dan büyük olur',
    () async {
      final gratitude = GratitudeProvider(now: () => DateTime(2026, 3, 16));
      await Future<void>.delayed(Duration.zero);
      gratitude.saveToday(text1: 'a', text2: 'b', text3: 'c');

      final stats = ProfileStats.compute(
        money: MoneyProvider(),
        gratitude: gratitude,
        manifest: ManifestProvider(),
        goals: GoalsProvider(),
        water: WaterProvider(),
        now: DateTime(2026, 3, 16),
      );

      final stat = _statFor(stats, ProfileStatCategory.gratitudeManifest);
      expect(stat.hasData, isTrue);
      expect(stat.score, greaterThan(0));
      expect(stat.score, lessThanOrEqualTo(10));
    },
  );

  test('Tüm kategorilerin puanı her zaman 0-10 aralığında kalır', () async {
    final money = MoneyProvider(now: () => DateTime(2026, 3, 16));
    await Future<void>.delayed(Duration.zero);
    money.addEntry(MoneyCategory.saving, name: 'Büyük birikim', amount: 999999, currencyCode: 'TRY');

    final stats = ProfileStats.compute(
      money: money,
      gratitude: GratitudeProvider(),
      manifest: ManifestProvider(),
      goals: GoalsProvider(),
      water: WaterProvider(),
      now: DateTime(2026, 3, 16),
    );

    for (final stat in stats) {
      expect(stat.score, inInclusiveRange(0, 10));
    }
  });
}
