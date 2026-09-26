import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/goal_completion.dart';
import '../services/cloud_state_store.dart';

/// [GoalsProvider.resolveYesterdayFreeze] sonucu.
class GoalReconcileResult {
  const GoalReconcileResult({this.resetNames = const [], this.completedNames = const []});

  /// Kaçırılan gün yüzünden sıfırlanan hedefler.
  final List<String> resetNames;

  /// Dondurulan son günle 7/7'yi tamamlayıp arşive düşen hedefler.
  final List<String> completedNames;
}

/// Kullanıcının hedeflerini ve her hedefin gerçek takvim tarihlerine bağlı
/// 7 günlük döngüsünü tutan tek kaynak. `SharedPreferences` ile kalıcı —
/// tıpkı `ThemeProvider`/`CostumeProvider` gibi (JSON olarak tek bir anahtar
/// altında, çünkü liste + iç içe tarih kümeleri barındırıyor).
///
/// Coin ödülü vermek bu provider'ın işi değil — bilerek coin sistemine
/// bağımlı değil (iki state parçası birbirinden bağımsız kalsın diye);
/// [toggleToday] döngünün o işaretlemeyle tamamlanıp tamamlanmadığını
/// döner, ödülü vermek çağıran widget'ın sorumluluğunda.
///
/// [now] parametresi testte sahte bir saat enjekte edebilmek için var;
/// gerçek uygulamada varsayılan olarak cihazın gerçek tarih/saatini
/// (`DateTime.now`) kullanır.
class GoalsProvider extends ChangeNotifier {
  GoalsProvider({DateTime Function() now = DateTime.now, String? uid})
    : _now = now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'goals';

  final DateTime Function() _now;
  final CloudStateStore _store;

  /// Cihazın bugünkü tarihi (saat bileşeni olmadan).
  DateTime get today => Goal.dateOnly(_now());

  final List<Goal> _goals = [];
  List<Goal> get goals => List.unmodifiable(_goals);

  final List<GoalCompletion> _completions = [];

  /// Tamamlanan tüm 7 günlük döngüler, en yeni en üstte — "Tamamlanan
  /// Hedefler" ekranı bunu hedef adına göre gruplayıp gösterir.
  List<GoalCompletion> get completions {
    final sorted = List<GoalCompletion>.of(_completions)
      ..sort((a, b) => b.completionDate.compareTo(a.completionDate));
    return List.unmodifiable(sorted);
  }

  int _nextId = 0;

  /// Şimdiye kadar (herhangi bir hedefte, herhangi bir döngüde) ulaşılan en
  /// uzun kesintisiz günlük seri — bkz. "Profil > En Uzun Seri Rekoru".
  /// [toggleToday]'de bir gün işaretlendikçe güncellenir; bir hedefin
  /// AKTİF döngüdeki `completedDates.length`'i (döngü herhangi bir gün
  /// kaçırılırsa ANINDA sıfırlandığı için — bkz. `_reconcileGoal` — bu
  /// sayı zaten o an için gerçek bir "kesintisiz seri" sayacıdır) bu
  /// rekorla karşılaştırılıp gerekirse yükseltilir. Döngü daha sonra
  /// sıfırlansa/tamamlansa bile bu rekor GERİYE dönük olarak asla azalmaz.
  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  /// **2026 güncellemesi — kullanıcı isteği: "hedef silinmesin, döngü
  /// tamamlanınca 1-7 yerine 8-14, sonra 15-21 şeklinde ardışık devam
  /// etsin."** Bu hedefin şimdiye kadar TAMAMLANMIŞ (arşive/`completions`'a
  /// düşmüş) döngü sayısı — `GoalCard`'ın gün kutucuklarını kümülatif
  /// numaralandırması için (`completedCyclesFor(id) * Goal.daysPerCycle +
  /// gün + 1`). **Bu YALNIZCA bir GÖSTERİM hesaplaması** — döngü/veri
  /// mekaniği (7 günlük pencere, `cycleStartDate`, kaçırılan günde
  /// sıfırlama, `GoalCompletion` arşivi) HİÇ değişmedi; bir döngü
  /// TAMAMLANMADAN (yalnızca kaçırılıp sıfırlandığında) bu sayı ARTMIYOR —
  /// yeniden denenen bir döngü, bir önceki BAŞARISIZ denemeyle AYNI
  /// baştan (ör. hep 8-14) başlar, yalnızca GERÇEKTEN tamamlanan döngüler
  /// sayacı ilerletir.
  int completedCyclesFor(String goalId) =>
      _completions.where((c) => c.goalId == goalId).length;

  /// Bugün HERHANGİ bir hedefte en az bir gün işaretlenmiş mi —
  /// "Denge Ustası" (Gizli/Eğlenceli Rozetler, bkz. `hidden_badges.dart`)
  /// rozetinin YEDİ modül kontrolünden biri.
  bool get hasAnyRecordToday =>
      _goals.any((g) => g.completedDates.contains(today));

  bool _isReady = false;
  bool get isReady => _isReady;
  final _readyCompleter = Completer<void>();

  /// Kayıtlı veri yüklendiğinde tamamlanır — `AppStreakProvider.ready` ile
  /// AYNI gerekçe: yükleme bitmeden yapılan bir sıfırlama/kayıt, kayıtlı
  /// veriyi ezip ilerlemeyi SİLERDİ.
  Future<void> get ready => _readyCompleter.future;

  /// Streak Freeze kararının (kullan/vazgeç) en son hangi gün için verildiği.
  /// Bugün için karar VERİLMEDEN, yalnızca dünü kaçırmış hedefler
  /// sıfırlanmaz — kullanıcıya önce dondurma teklif edilir.
  DateTime? _freezeDecisionDate;

  Future<void> _loadFromPrefs() async {
    try {
      await _loadFromStore();
    } finally {
      _isReady = true;
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      notifyListeners();
    }
  }

  Future<void> _loadFromStore() async {
    final decoded = await _store.load();
    if (decoded == null) {
      // İlk kurulum: BOŞ listeyle başla — kullanıcı isteği ("otomatik
      // gösterilen örnek hedefi kaldıralım, kullanıcı sıfırdan başlasın").
      // Önceden burada `addGoal('Günde 30 dakika kitap oku')` ile örnek bir
      // hedef ekleniyordu.
      return;
    }
    try {
      _nextId = decoded['nextId'] as int;
      _longestStreak = decoded['longestStreak'] as int? ?? 0;
      for (final raw in decoded['goals'] as List) {
        final map = raw as Map<String, dynamic>;
        final goal = Goal(
          id: map['id'] as String,
          name: map['name'] as String,
          cycleStartDate: DateTime.parse(map['cycleStartDate'] as String),
        );
        goal.completedDates = (map['completedDates'] as List)
            .map((d) => DateTime.parse(d as String))
            .toSet();
        // Oku-zamanı-göç-et: bu alan 2026-09-26'dan önceki kayıtlarda yok.
        goal.frozenDates = ((map['frozenDates'] as List?) ?? const [])
            .map((d) => DateTime.parse(d as String))
            .toSet();
        _goals.add(goal);
      }
      final rawCompletions = decoded['completions'] as List? ?? const [];
      _completions.addAll(
        rawCompletions.map(
          (raw) => GoalCompletion(
            goalId: (raw as Map<String, dynamic>)['goalId'] as String,
            goalName: raw['goalName'] as String,
            cycleStartDate: DateTime.parse(raw['cycleStartDate'] as String),
            completionDate: DateTime.parse(raw['completionDate'] as String),
          ),
        ),
      );
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et,
      // uygulamanın çökmesindense veri kaybı tercih edilir.
    }
  }

  Future<void> _save() async {
    await _store.save({
      'nextId': _nextId,
      'longestStreak': _longestStreak,
      'goals': _goals
          .map(
            (g) => {
              'id': g.id,
              'name': g.name,
              'cycleStartDate': g.cycleStartDate.toIso8601String(),
              'completedDates': g.completedDates
                  .map((d) => d.toIso8601String())
                  .toList(),
              'frozenDates': g.frozenDates
                  .map((d) => d.toIso8601String())
                  .toList(),
            },
          )
          .toList(),
      'completions': _completions
          .map(
            (c) => {
              'goalId': c.goalId,
              'goalName': c.goalName,
              'cycleStartDate': c.cycleStartDate.toIso8601String(),
              'completionDate': c.completionDate.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  void addGoal(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _goals.add(Goal(id: '${_nextId++}', name: trimmed, cycleStartDate: today));
    notifyListeners();
    _save();
  }

  void removeGoal(String id) {
    _goals.removeWhere((goal) => goal.id == id);
    notifyListeners();
    _save();
  }

  /// Her hedefi bugünün gerçek tarihine göre yeniden değerlendirir:
  /// döngüde, bugünden önce olup işaretlenmemiş bir gün varsa (kullanıcı o
  /// gün uygulamayı hiç açmadıysa) o gün kaçırılmış sayılır, döngü bugünden
  /// itibaren yeniden Gün 1'den başlar. Uygulama her açıldığında/öne
  /// geldiğinde bir kez çağrılması yeterlidir — arka planda geçen günleri
  /// de bu şekilde (saklanan bir sayaç değil, gerçek tarih karşılaştırması
  /// ile) doğru yakalar.
  ///
  /// Kaçırılan gün yüzünden sıfırlanan hedeflerin adlarını döner; boşsa
  /// hiçbir şey sıfırlanmamış demektir.
  ///
  /// **Streak Freeze:** Bugün için dondurma kararı henüz verilmediyse
  /// ([resolveYesterdayFreeze] çağrılmadıysa), YALNIZCA dünü kaçırmış
  /// hedefler ([goalsAtRiskToday]) sıfırlanmaz — önce kullanıcıya dondurma
  /// teklif edilir. 2+ gün kaçırılmış hedefler her zaman sıfırlanır.
  /// Yükleme bitmeden çağrılırsa hiçbir şey yapmaz (kayıtlı veriyi ezmesin).
  List<String> reconcileForToday() => _reconcile().resetNames;

  GoalReconcileResult _reconcile() {
    if (!_isReady) return const GoalReconcileResult();
    final decided = _freezeDecisionDate == today;
    final resetGoalNames = <String>[];
    final completedGoalNames = <String>[];
    for (final goal in _goals) {
      if (!decided && _isAtRisk(goal)) continue;
      if (_archiveIfCycleFilled(goal)) {
        completedGoalNames.add(goal.name);
      } else if (_reconcileGoal(goal)) {
        resetGoalNames.add(goal.name);
      }
    }
    // Sıfırlama olmasa bile bildir: gün değişimi (ör. bugün artık "Gün 2"
    // olduğu için kutucuk durumlarının yeniden çizilmesi gerekebilir).
    notifyListeners();
    if (resetGoalNames.isNotEmpty || completedGoalNames.isNotEmpty) _save();
    return GoalReconcileResult(resetNames: resetGoalNames, completedNames: completedGoalNames);
  }

  bool _reconcileGoal(Goal goal) {
    var cursor = goal.cycleStartDate;
    while (cursor.isBefore(today)) {
      if (!goal.isCovered(cursor)) {
        goal.cycleStartDate = today;
        goal.completedDates = {};
        goal.frozenDates = {};
        return true;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return false;
  }

  /// Döngünün 7 günü (işaretli + donmuş) dolmuş ama işaretlemeyle
  /// tamamlanmamışsa — ör. 7. gün dondurulduysa — arşivler ve yeni döngüyü
  /// bugünden başlatır.
  bool _archiveIfCycleFilled(Goal goal) {
    if (goal.progressCount < Goal.daysPerCycle) return false;
    final lastDay = goal.dateForDay(Goal.daysPerCycle - 1);
    if (!lastDay.isBefore(today)) return false;
    _completions.add(
      GoalCompletion(
        goalId: goal.id,
        goalName: goal.name,
        cycleStartDate: goal.cycleStartDate,
        completionDate: lastDay,
      ),
    );
    goal.cycleStartDate = today;
    goal.completedDates = {};
    goal.frozenDates = {};
    return true;
  }

  DateTime get _yesterday => today.subtract(const Duration(days: 1));

  /// Yalnızca DÜN kaçırılmış (ondan önceki tüm günleri işaretli/donmuş) ve
  /// korunacak ilerlemesi olan hedef — Streak Freeze ile kurtarılabilir.
  bool _isAtRisk(Goal goal) {
    final yesterday = _yesterday;
    if (goal.cycleStartDate.isAfter(yesterday)) return false;
    if (goal.isCovered(yesterday)) return false;
    if (goal.completedDates.isEmpty) return false;
    var cursor = goal.cycleStartDate;
    while (cursor.isBefore(yesterday)) {
      if (!goal.isCovered(cursor)) return false;
      cursor = cursor.add(const Duration(days: 1));
    }
    return true;
  }

  /// Bugün için dondurma kararı bekleyen (dünü kaçırmış) hedefler.
  List<Goal> get goalsAtRiskToday {
    if (!_isReady || _freezeDecisionDate == today) return const [];
    return _goals.where(_isAtRisk).toList();
  }

  /// Kullanıcının bugünkü Streak Freeze kararını uygular: [frozen] ise dünü
  /// kaçırmış hedeflerin o günü dondurulur (mavi ❄️, sıfırlanmaz); değilse
  /// normal sıfırlama çalışır. Ardından tüm hedefler bugüne göre uzlaştırılır.
  GoalReconcileResult resolveYesterdayFreeze({required bool frozen}) {
    if (!_isReady) return const GoalReconcileResult();
    if (frozen) {
      final yesterday = _yesterday;
      for (final goal in goalsAtRiskToday) {
        goal.frozenDates.add(yesterday);
      }
      _save();
    }
    _freezeDecisionDate = today;
    return _reconcile();
  }

  /// Bugünü işaretler/işaretini kaldırır. Yalnızca döngünün gerçekten
  /// güncel açık günü bugünse etkili olur (erken/geç tarihli günler
  /// işaretlenemez). Bu işaretlemeyle döngü tamamlandıysa (7/7) yeni bir
  /// döngü yarından başlayacak şekilde hazırlanır ve true döner — ödülü
  /// vermek çağıran widget'ın sorumluluğunda.
  bool toggleToday(String goalId) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final todayIndex = today.difference(goal.cycleStartDate).inDays;
    if (todayIndex < 0 || todayIndex >= Goal.daysPerCycle) return false;

    if (goal.completedDates.contains(today)) {
      goal.completedDates.remove(today);
      notifyListeners();
      _save();
      return false;
    }

    goal.completedDates.add(today);
    if (goal.completedDates.length > _longestStreak) {
      _longestStreak = goal.completedDates.length;
    }
    // Donmuş günler de 7/7'ye sayılır (kullanıcı isteği: "donsun ve devam
    // etsin, sıfırlanmasın").
    final cycleCompleted = goal.progressCount == Goal.daysPerCycle;
    if (cycleCompleted) {
      // Döngü sıfırlanmadan ÖNCE kalıcı bir tamamlanma kaydı düş — aksi
      // halde `completedDates`/`cycleStartDate` hemen ardından sıfırlanınca
      // bu tamamlanmanın hiçbir izi kalmaz (bkz. GoalCompletion dokümantasyonu).
      _completions.add(
        GoalCompletion(
          goalId: goal.id,
          goalName: goal.name,
          cycleStartDate: goal.cycleStartDate,
          completionDate: today,
        ),
      );
      goal.cycleStartDate = today.add(const Duration(days: 1));
      goal.completedDates = {};
      goal.frozenDates = {};
    }
    notifyListeners();
    _save();
    return cycleCompleted;
  }
}
