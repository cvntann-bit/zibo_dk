import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/goal_completion.dart';
import '../services/cloud_state_store.dart';

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

  /// Bugün HERHANGİ bir hedefte en az bir gün işaretlenmiş mi —
  /// "Denge Ustası" (Gizli/Eğlenceli Rozetler, bkz. `hidden_badges.dart`)
  /// rozetinin YEDİ modül kontrolünden biri.
  bool get hasAnyRecordToday =>
      _goals.any((g) => g.completedDates.contains(today));

  Future<void> _loadFromPrefs() async {
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
  List<String> reconcileForToday() {
    final resetGoalNames = <String>[];
    for (final goal in _goals) {
      if (_reconcileGoal(goal)) {
        resetGoalNames.add(goal.name);
      }
    }
    // Sıfırlama olmasa bile bildir: gün değişimi (ör. bugün artık "Gün 2"
    // olduğu için kutucuk durumlarının yeniden çizilmesi gerekebilir).
    notifyListeners();
    if (resetGoalNames.isNotEmpty) _save();
    return resetGoalNames;
  }

  bool _reconcileGoal(Goal goal) {
    var cursor = goal.cycleStartDate;
    while (cursor.isBefore(today)) {
      if (!goal.completedDates.contains(cursor)) {
        goal.cycleStartDate = today;
        goal.completedDates = {};
        return true;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return false;
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
    final cycleCompleted = goal.completedDates.length == Goal.daysPerCycle;
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
    }
    notifyListeners();
    _save();
    return cycleCompleted;
  }
}
