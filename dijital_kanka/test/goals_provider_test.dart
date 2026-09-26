// GoalsProvider'ın tarihe bağlı 7 günlük döngü mantığını doğrudan (widget
// pump'lamadan) test eder: her gün kendi gerçek takvim tarihine karşılık
// gelmeli, yalnızca bugün işaretlenebilmeli, kaçırılan bir gün döngüyü
// sıfırlamalı ve ödül yalnızca gerçek 7. günde verilmeli.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/goal.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';

void main() {
  group('GoalsProvider - tarih bazlı takip', () {
    late DateTime currentDate;
    late GoalsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      currentDate = DateTime(2026, 1, 5); // Pazartesi
      provider = GoalsProvider(now: () => currentDate);
      // GoalsProvider artık SharedPreferences'tan asenkron yükleniyor (bkz.
      // _loadFromPrefs) — ilk (boş) yüklemenin bitmesini bekle, SONRA testin
      // ihtiyaç duyduğu hedefi elle ekle. 2026 güncellemesi: provider artık
      // ilk kurulumda otomatik bir örnek hedef EKLEMİYOR (kullanıcı isteği —
      // "kullanıcı sıfırdan başlasın"), bu yüzden test setup'ı kendi
      // hedefini açıkça oluşturuyor.
      await Future<void>.delayed(Duration.zero);
      provider.addGoal('Günde 30 dakika kitap oku');
    });

    test('Yeni hedefte Gün 1 bugündür, kalan günler henüz açılmamıştır', () {
      final goal = provider.goals.first;

      expect(goal.statusForDay(0, provider.today), GoalDayStatus.today);
      for (var day = 1; day < Goal.daysPerCycle; day++) {
        expect(goal.statusForDay(day, provider.today), GoalDayStatus.upcoming);
      }
    });

    test('Bugünü işaretleyince Gün 1 tamamlanır, ertesi gün Gün 2 açılır', () {
      final goal = provider.goals.first;

      final completed = provider.toggleToday(goal.id);
      expect(completed, isFalse);
      expect(goal.statusForDay(0, provider.today), GoalDayStatus.done);
      expect(goal.statusForDay(1, provider.today), GoalDayStatus.upcoming);

      currentDate = currentDate.add(const Duration(days: 1));
      provider.reconcileForToday();

      expect(goal.statusForDay(0, provider.today), GoalDayStatus.done);
      expect(goal.statusForDay(1, provider.today), GoalDayStatus.today);
    });

    test('Gelecek bir günü erken işaretlemeye çalışmak hiçbir şey yapmaz', () {
      final goal = provider.goals.first;

      // toggleToday her zaman "bugünü" işaretler; Gün 2'nin tarihi henüz
      // gelmediği için bugün Gün 1 iken tekrar tekrar çağırmak bile Gün
      // 2'yi asla açmaz — döngü ancak gerçek zaman geçince ilerler.
      provider.toggleToday(goal.id);
      provider.toggleToday(goal.id); // bunu geri alır (kaldırır)
      expect(goal.completedDates, isEmpty);
      expect(goal.statusForDay(1, provider.today), GoalDayStatus.upcoming);
    });

    test(
      'Bir gün atlanırsa (uygulama hiç açılmazsa) önce Streak Freeze kararı beklenir, '
      'vazgeçilince döngü bugünden sıfırlanır',
      () {
        final goal = provider.goals.first;
        provider.toggleToday(goal.id); // Gün 1 (Pzt) tamam

        // Salı hiç açılmadı, doğrudan Çarşamba'ya geçiliyor.
        currentDate = currentDate.add(const Duration(days: 2));

        // Karar verilmeden sıfırlanmaz (RootScreen önce freeze teklif eder).
        expect(provider.reconcileForToday(), isEmpty);
        final resetNames = provider.resolveYesterdayFreeze(frozen: false).resetNames;

        expect(resetNames, [goal.name]);
        expect(goal.cycleStartDate, provider.today);
        expect(goal.completedDates, isEmpty);
        expect(goal.statusForDay(0, provider.today), GoalDayStatus.today);
      },
    );

    test(
      '7 günü gerçek ardışık tarihlerle tamamlayınca döngü biter ve 50 coin tetiklenir',
      () {
        final goal = provider.goals.first;
        var lastResult = false;

        for (var day = 0; day < Goal.daysPerCycle; day++) {
          lastResult = provider.toggleToday(goal.id);
          if (day < Goal.daysPerCycle - 1) {
            expect(lastResult, isFalse, reason: 'Gün ${day + 1} erken tamamlanmamalı');
            currentDate = currentDate.add(const Duration(days: 1));
            provider.reconcileForToday();
          }
        }

        expect(lastResult, isTrue); // yalnızca gerçek 7. günde true döner
        expect(goal.completedDates, isEmpty); // yeni döngü hazır
        expect(goal.cycleStartDate, currentDate.add(const Duration(days: 1)));

        // Döngü sıfırlanmadan önce kalıcı bir tamamlanma kaydı düşmüş olmalı.
        expect(provider.completions, hasLength(1));
        final completion = provider.completions.first;
        expect(completion.goalId, goal.id);
        expect(completion.goalName, goal.name);
        expect(completion.completionDate, currentDate);
      },
    );

    test(
      'longestStreak, bir döngü tamamlanınca 7\'ye çıkar ve sonraki daha '
      'kısa bir seri onu düşürmez',
      () {
        final goal = provider.goals.first;

        expect(provider.longestStreak, 0);

        for (var day = 0; day < Goal.daysPerCycle; day++) {
          provider.toggleToday(goal.id);
          if (day < Goal.daysPerCycle - 1) {
            currentDate = currentDate.add(const Duration(days: 1));
            provider.reconcileForToday();
          }
        }
        expect(provider.longestStreak, Goal.daysPerCycle);

        // Yeni döngüde yalnızca 2 gün işaretleyip bırak — rekor düşmemeli.
        currentDate = currentDate.add(const Duration(days: 1));
        provider.reconcileForToday();
        provider.toggleToday(goal.id);
        currentDate = currentDate.add(const Duration(days: 1));
        provider.reconcileForToday();
        provider.toggleToday(goal.id);

        expect(provider.longestStreak, Goal.daysPerCycle);
      },
    );

    test(
      'longestStreak kalıcı depoya yazılır; uygulama yeniden başlatılsa '
      'bile (yeni GoalsProvider) hatırlanır',
      () async {
        final goal = provider.goals.first;
        provider.toggleToday(goal.id);
        currentDate = currentDate.add(const Duration(days: 1));
        provider.reconcileForToday();
        provider.toggleToday(goal.id);
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = GoalsProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.longestStreak, 2);
      },
    );

    test(
      'Aynı hedef ikinci bir 7 günlük döngüyü de tamamlarsa İKİNCİ bir '
      'tamamlanma kaydı eklenir, birincisi kaybolmaz',
      () {
        final goal = provider.goals.first;

        void completeOneCycle() {
          for (var day = 0; day < Goal.daysPerCycle; day++) {
            provider.toggleToday(goal.id);
            if (day < Goal.daysPerCycle - 1) {
              currentDate = currentDate.add(const Duration(days: 1));
              provider.reconcileForToday();
            }
          }
        }

        completeOneCycle();
        currentDate = currentDate.add(const Duration(days: 1));
        provider.reconcileForToday();
        completeOneCycle();

        expect(provider.completions, hasLength(2));
        // En yeni tamamlanma en üstte, ikinci döngü birincisinden 7 gün
        // sonra biter (aradaki 1 günlük "reconcile" boşluğu + 6 ilerleme).
        expect(
          provider.completions.first.completionDate,
          provider.completions.last.completionDate.add(const Duration(days: 7)),
        );
        // 2026 güncellemesi — kullanıcı isteği: gün numaraları döngü
        // tamamlanınca 1'e dönmesin, ardışık devam etsin (bkz.
        // `completedCyclesFor` dokümantasyonu, `GoalCard`'ın bunu
        // `* Goal.daysPerCycle + gün + 1` ile GÖRÜNTÜLEME için kullandığı).
        expect(provider.completedCyclesFor(goal.id), 2);
      },
    );

    test(
      'completedCyclesFor: taze bir hedefte 0, YALNIZCA gerçekten '
      'TAMAMLANAN döngülerde artar — kaçırılıp SIFIRLANAN bir döngü '
      'saymaz',
      () {
        final goal = provider.goals.first;
        expect(provider.completedCyclesFor(goal.id), 0);

        // Gün 1'i işaretleyip Gün 2'yi kaçır — döngü sıfırlanır, ama HİÇ
        // tamamlanmadığı için sayaç ARTMAZ.
        provider.toggleToday(goal.id);
        currentDate = currentDate.add(const Duration(days: 2));
        provider.reconcileForToday();
        expect(provider.completedCyclesFor(goal.id), 0);

        // Başka bir hedefin tamamlanması BU hedefin sayacını ETKİLEMEZ.
        provider.addGoal('Diğer hedef');
        final otherGoal = provider.goals.last;
        for (var day = 0; day < Goal.daysPerCycle; day++) {
          provider.toggleToday(otherGoal.id);
          if (day < Goal.daysPerCycle - 1) {
            currentDate = currentDate.add(const Duration(days: 1));
            provider.reconcileForToday();
          }
        }
        expect(provider.completedCyclesFor(otherGoal.id), 1);
        expect(provider.completedCyclesFor(goal.id), 0);
      },
    );

    test('Aynı gün içinde art arda dokunmak döngüyü asla erken tamamlatmaz', () {
      final goal = provider.goals.first;

      // Gerçek hayatta yalnızca "bugün" var; bu yüzden 7 kere üst üste
      // çağırmak sadece Gün 1'i işaretleyip geri almayı tekrarlar.
      for (var i = 0; i < 7; i++) {
        final result = provider.toggleToday(goal.id);
        expect(result, isFalse);
      }
      expect(goal.completedCount, 1); // 7 çağrı = 4 işaretleme + 3 geri alma
    });

    test(
      'Yeni hedef eklemek ve işaretlemek kalıcı depoya yazar; uygulama '
      'yeniden başlatılsa bile (yeni GoalsProvider) hatırlanır',
      () async {
        provider.addGoal('Her gün 10.000 adım at');
        final newGoal = provider.goals.last;
        provider.toggleToday(newGoal.id);

        // "Uygulamayı kapatıp aç": aynı kalıcı depoyu okuyan yeni bir
        // GoalsProvider oluştur.
        final secondLaunch = GoalsProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.goals.length, provider.goals.length);
        final restored = secondLaunch.goals.firstWhere(
          (g) => g.name == 'Her gün 10.000 adım at',
        );
        expect(restored.completedDates, {currentDate});
      },
    );

    test(
      'Tamamlanma kayıtları kalıcı depoya yazılır; uygulama yeniden '
      'başlatılsa bile (yeni GoalsProvider) hatırlanır',
      () async {
        final goal = provider.goals.first;
        for (var day = 0; day < Goal.daysPerCycle; day++) {
          provider.toggleToday(goal.id);
          if (day < Goal.daysPerCycle - 1) {
            currentDate = currentDate.add(const Duration(days: 1));
            provider.reconcileForToday();
          }
        }
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = GoalsProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.completions, hasLength(1));
        expect(secondLaunch.completions.first.goalName, goal.name);
      },
    );

    test(
      'hasAnyRecordToday: bugün HİÇBİR hedef işaretlenmemişse false, '
      'HERHANGİ biri işaretlenince true döner (Denge Ustası — Gizli/'
      'Eğlenceli Rozetler)',
      () {
        expect(provider.hasAnyRecordToday, isFalse);

        provider.toggleToday(provider.goals.first.id);

        expect(provider.hasAnyRecordToday, isTrue);
      },
    );
  });
}
