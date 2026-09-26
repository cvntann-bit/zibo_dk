// Hedefler + Streak Freeze: kullanıcı örneği — "3. gününde unuttu, Streak
// Freeze kullandı: 3. gün mavi (donmuş) olsun, 4. güne geçsin, sıfırlanmasın."

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/goal.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';

void main() {
  late DateTime clock;
  late GoalsProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 9, 1, 10); // Gün 1
    provider = GoalsProvider(now: () => clock);
    await provider.ready;
    provider.addGoal('Kitap oku');
  });

  Goal goal() => provider.goals.single;

  /// Gün 1 ve 2 işaretlenir, Gün 3 kaçırılır, Gün 4'te uygulama açılır.
  void missDayThree() {
    provider.toggleToday(goal().id); // Gün 1
    clock = DateTime(2026, 9, 2, 10);
    provider.toggleToday(goal().id); // Gün 2
    clock = DateTime(2026, 9, 4, 10); // Gün 3 (2 Eylül... 3 Eylül) kaçırıldı
  }

  test('dünü kaçırılan hedef, karar verilmeden SIFIRLANMAZ ve risk altında görünür', () {
    missDayThree();

    expect(provider.reconcileForToday(), isEmpty);
    expect(provider.goalsAtRiskToday.map((g) => g.name), ['Kitap oku']);
    expect(goal().completedCount, 2);
  });

  test('Streak Freeze kullanılınca 3. gün donar (mavi), bugün 4. gün, sıfırlanmaz', () {
    missDayThree();

    final result = provider.resolveYesterdayFreeze(frozen: true);

    expect(result.resetNames, isEmpty);
    expect(goal().statusForDay(2, provider.today), GoalDayStatus.frozen);
    expect(goal().statusForDay(3, provider.today), GoalDayStatus.today);
    expect(goal().progressCount, 3);
    expect(provider.goalsAtRiskToday, isEmpty);
  });

  test('vazgeçilirse hedef eskisi gibi sıfırlanır', () {
    missDayThree();

    final result = provider.resolveYesterdayFreeze(frozen: false);

    expect(result.resetNames, ['Kitap oku']);
    expect(goal().progressCount, 0);
    expect(goal().cycleStartDate, provider.today);
  });

  test('2 gün kaçırılınca teklif çıkmaz, doğrudan sıfırlanır', () {
    provider.toggleToday(goal().id); // Gün 1
    clock = DateTime(2026, 9, 4, 10); // Gün 2 ve 3 kaçırıldı

    expect(provider.goalsAtRiskToday, isEmpty);
    expect(provider.resolveYesterdayFreeze(frozen: false).resetNames, ['Kitap oku']);
  });

  test('hiç işaretlenmemiş (ilerlemesi olmayan) hedef için teklif çıkmaz', () {
    clock = DateTime(2026, 9, 2, 10); // Gün 1 kaçırıldı, ilerleme yok

    expect(provider.goalsAtRiskToday, isEmpty);
  });

  test('donmuş günle birlikte 7/7 işaretlenince döngü tamamlanır', () {
    missDayThree();
    provider.resolveYesterdayFreeze(frozen: true);

    var completed = false;
    for (var day = 4; day <= 7; day++) {
      clock = DateTime(2026, 9, day, 10);
      provider.resolveYesterdayFreeze(frozen: false);
      completed = provider.toggleToday(goal().id);
    }

    expect(completed, isTrue);
    expect(provider.completions, hasLength(1));
  });

  test('7. gün dondurulursa döngü tamamlanır, yeni döngü bugünden başlar', () {
    for (var day = 1; day <= 6; day++) {
      clock = DateTime(2026, 9, day, 10);
      provider.resolveYesterdayFreeze(frozen: false);
      provider.toggleToday(goal().id);
    }
    clock = DateTime(2026, 9, 8, 10); // 7. gün (7 Eylül) kaçırıldı

    expect(provider.goalsAtRiskToday, hasLength(1));
    final result = provider.resolveYesterdayFreeze(frozen: true);

    expect(result.completedNames, ['Kitap oku']);
    expect(provider.completions, hasLength(1));
    expect(goal().cycleStartDate, provider.today);
    expect(goal().progressCount, 0);
  });

  test('donmuş gün kalıcıdır (yeniden başlatınca hâlâ mavi)', () async {
    missDayThree();
    provider.resolveYesterdayFreeze(frozen: true);
    await Future<void>.delayed(Duration.zero);

    final reloaded = GoalsProvider(now: () => clock);
    await reloaded.ready;

    expect(reloaded.goals.single.statusForDay(2, reloaded.today), GoalDayStatus.frozen);
  });

  test('aynı gün ikinci açılışta tekrar teklif edilmez', () {
    missDayThree();
    provider.resolveYesterdayFreeze(frozen: true);

    expect(provider.goalsAtRiskToday, isEmpty);
  });
}
