import 'package:flutter/foundation.dart';

import '../models/water_entry.dart';
import '../services/cloud_state_store.dart';

const _defaultGlassMl = 250;
const _defaultBottleMl = 500;
const _defaultGoalMl = 2000;
const _minGoalMl = 500;
const _maxGoalMl = 10000;
const _minMlPerUnit = 50;
const _maxMlPerUnit = 2000;

/// Su Takibi'ndeki günlük kayıtları tutan tek kaynak. `MoodProvider` ile
/// birebir aynı desen: her güne AYRI bir kayıt düşer, "bugün" her zaman
/// `_now()`'a göre türetilir — bu yüzden gün değiştiğinde ayrı bir "sıfırla"
/// adımına gerek YOK, dünün kaydı listede kalır (kaybolmaz), bugünün
/// sayacı `todayCount` üzerinden otomatik olarak 0'dan başlar.
///
/// Hedef, kanonik olarak ml cinsinden ([goalMl]) tutulur — bu sayede
/// kullanıcı birimi (bardak/şişe) veya birim başına ml değerini
/// değiştirdiğinde günlük hedef (ör. "2 litre") sabit kalır, yalnızca
/// [goalUnitCount] (o birimle kaç adet gerektiği) yeniden hesaplanır.
class WaterProvider extends ChangeNotifier {
  /// [now], `GoalsProvider`/`MoodProvider`'la aynı gerekçeyle enjekte
  /// edilebilir: testte "gün değişince sayaç sıfırlanır" davranışını
  /// gerçek saatin geçmesini beklemeden doğrulayabilmek için.
  WaterProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'waterState';

  final DateTime Function() _now;
  final CloudStateStore _store;
  final List<WaterEntry> _entries = [];

  WaterUnit _unit = WaterUnit.glass;
  int _glassMl = _defaultGlassMl;
  int _bottleMl = _defaultBottleMl;
  int _goalMl = _defaultGoalMl;

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  WaterUnit get unit => _unit;
  int get glassMl => _glassMl;
  int get bottleMl => _bottleMl;
  int get mlPerUnit => _unit == WaterUnit.glass ? _glassMl : _bottleMl;
  int get goalMl => _goalMl;

  /// Güncel birimle hedefe ulaşmak için gereken adet — ml cinsinden
  /// [goalMl]'den türetilir (kanonik kaynak [goalMl]'dir, bu değer değil).
  int get goalUnitCount => (_goalMl / mlPerUnit).ceil().clamp(1, 1 << 20);

  /// Bugüne ait kayıt (henüz hiç dokunulmadıysa `null`).
  WaterEntry? get todayEntry {
    for (final entry in _entries) {
      if (entry.date == _today) return entry;
    }
    return null;
  }

  int get todayCount => todayEntry?.unitCount ?? 0;
  bool get isTodayComplete => todayCount >= goalUnitCount;

  /// Bugünün coin ödülü daha önce verildi mi — bkz. `incrementUnit`
  /// dokümantasyonu, bir kez `true` olunca gün bitene kadar öyle kalır.
  bool get isTodayRewardClaimed => todayEntry?.rewardClaimed ?? false;

  /// Bugün HARİÇ, en yeni kayıt en üstte olacak şekilde geçmiş kayıtlar.
  List<WaterEntry> get history {
    final past = _entries.where((e) => e.date != _today).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(past);
  }

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded == null) return;
    try {
      final unitName = decoded['unit'] as String?;
      _unit = WaterUnit.values.firstWhere(
        (u) => u.name == unitName,
        orElse: () => WaterUnit.glass,
      );
      _glassMl = (decoded['glassMl'] as num?)?.toInt() ?? _defaultGlassMl;
      _bottleMl = (decoded['bottleMl'] as num?)?.toInt() ?? _defaultBottleMl;
      // Eski (birim/ml kavramından önceki) kayıtlı veri 'goalGlasses' adında
      // düz bir bardak sayısı tutuyordu — bulunursa 250ml/bardak varsayımıyla
      // ml'e çevrilir; yeni format zaten doğrudan 'goalMl' taşır.
      if (decoded.containsKey('goalMl')) {
        _goalMl = (decoded['goalMl'] as num).toInt();
      } else if (decoded.containsKey('goalGlasses')) {
        _goalMl = (decoded['goalGlasses'] as num).toInt() * _defaultGlassMl;
      } else {
        _goalMl = _defaultGoalMl;
      }
      final rawEntries = decoded['entries'] as List? ?? const [];
      _entries
        ..clear()
        ..addAll(rawEntries.map((raw) => _entryFromJson(raw as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  WaterEntry _entryFromJson(Map<String, dynamic> raw) {
    final unitName = raw['unit'] as String?;
    final entryUnit = WaterUnit.values.firstWhere(
      (u) => u.name == unitName,
      orElse: () => WaterUnit.glass,
    );
    // Eski format 'glassCount'/'goalGlasses' taşır (birim her zaman bardak,
    // ml her zaman 250 varsayılırdı); yeni format 'unitCount'/'goalUnitCount'
    // + 'mlPerUnit' taşır.
    final unitCount = (raw['unitCount'] as num?)?.toInt() ?? (raw['glassCount'] as num?)?.toInt() ?? 0;
    final goalUnitCount = (raw['goalUnitCount'] as num?)?.toInt() ?? (raw['goalGlasses'] as num?)?.toInt() ?? 8;
    final mlPerUnit = (raw['mlPerUnit'] as num?)?.toInt() ?? _defaultGlassMl;
    return WaterEntry(
      date: DateTime.parse(raw['date'] as String),
      unitCount: unitCount,
      goalUnitCount: goalUnitCount,
      unit: entryUnit,
      mlPerUnit: mlPerUnit,
      rewardClaimed: raw['rewardClaimed'] as bool? ?? false,
    );
  }

  Future<void> _save() async {
    await _store.save({
      'unit': _unit.name,
      'glassMl': _glassMl,
      'bottleMl': _bottleMl,
      'goalMl': _goalMl,
      'entries': _entries
          .map(
            (e) => {
              'date': e.date.toIso8601String(),
              'unitCount': e.unitCount,
              'goalUnitCount': e.goalUnitCount,
              'unit': e.unit.name,
              'mlPerUnit': e.mlPerUnit,
              'rewardClaimed': e.rewardClaimed,
            },
          )
          .toList(),
    });
  }

  /// [rewardClaimed] verilmezse bugünün MEVCUT kaydındaki değeri korur —
  /// yani birim sayısı/hedef değişse bile "ödül zaten verildi" durumu
  /// kendiliğinden sıfırlanmaz (bkz. `incrementUnit`/goal-ayar metotları).
  void _upsertToday(int unitCount, {bool? rewardClaimed}) {
    final existing = todayEntry;
    _entries.removeWhere((e) => e.date == _today);
    _entries.add(
      WaterEntry(
        date: _today,
        unitCount: unitCount,
        goalUnitCount: goalUnitCount,
        unit: _unit,
        mlPerUnit: mlPerUnit,
        rewardClaimed: rewardClaimed ?? existing?.rewardClaimed ?? false,
      ),
    );
  }

  /// Bir birim (bardak/şişe) su içildiğini işaretler. Hedef zaten
  /// tamamlanmışsa hiçbir şey yapmaz. Bu dokunuşun hedefi TAM O AN
  /// tamamlayıp tamamlamadığını VE bugünün ödülü henüz alınmadığını döner —
  /// çağıran taraf (bkz. `WaterTrackingScreen`) `GratitudeJournalScreen`'in
  /// `saveToday()` kullanma deseniyle AYNI şekilde, yalnızca `true`
  /// döndüğünde `CoinProvider.earnWaterGoal()`'ı çağırır.
  ///
  /// **Bilerek günde yalnızca bir kez `true` döner** — kullanıcı hedefi
  /// doldurup bir birimi geri alıp (`decrementUnit`) tekrar doldurarak, ya
  /// da hedefi tamamladıktan SONRA hedefi yükselterek sınırsız coin
  /// kazanamasın diye (`WaterEntry.rewardClaimed` bir kez `true` olunca gün
  /// bitene kadar öyle kalır).
  bool incrementUnit() {
    final current = todayCount;
    final goal = goalUnitCount;
    if (current >= goal) return false;
    final next = current + 1;
    final alreadyClaimed = todayEntry?.rewardClaimed ?? false;
    final justCompleted = next >= goal && !alreadyClaimed;
    _upsertToday(next, rewardClaimed: alreadyClaimed || justCompleted);
    notifyListeners();
    _save();
    return justCompleted;
  }

  /// Yanlışlıkla fazla dokunulduysa geri almak için — bugünün sayacını bir
  /// azaltır (0'ın altına inmez). Hedef tamamlandıktan SONRA geri alınırsa
  /// coin GERİ ALINMAZ (basit tutuldu, kullanıcı zaten kazandığı coin'i
  /// harcamış olabilir — `GoalsProvider`'ın tamamlanmış bir döngüyü geri
  /// almaması gibi bilinçli bir sadeleştirme).
  void decrementUnit() {
    final current = todayCount;
    if (current <= 0) return;
    _upsertToday(current - 1);
    notifyListeners();
    _save();
  }

  /// Takip birimini değiştirir (bardak/şişe). Günlük hedef ml cinsinden
  /// SABİT kalır (bkz. sınıf dokümantasyonu) — yalnızca kaç adet gerektiği
  /// yeni birime göre yeniden hesaplanır. Bugünün ham dokunuş sayısı
  /// (`todayCount`) bilerek dönüştürülmez — basit tutuldu, tıpkı
  /// `decrementUnit`'in coin'i geri almaması gibi.
  Future<void> setUnit(WaterUnit newUnit) async {
    if (newUnit == _unit) return;
    _unit = newUnit;
    final today = todayEntry;
    if (today != null) _upsertToday(today.unitCount);
    notifyListeners();
    await _save();
  }

  Future<void> setGlassMl(int ml) async {
    final clamped = ml.clamp(_minMlPerUnit, _maxMlPerUnit);
    if (clamped == _glassMl) return;
    _glassMl = clamped;
    final today = todayEntry;
    if (today != null && _unit == WaterUnit.glass) _upsertToday(today.unitCount);
    notifyListeners();
    await _save();
  }

  Future<void> setBottleMl(int ml) async {
    final clamped = ml.clamp(_minMlPerUnit, _maxMlPerUnit);
    if (clamped == _bottleMl) return;
    _bottleMl = clamped;
    final today = todayEntry;
    if (today != null && _unit == WaterUnit.bottle) _upsertToday(today.unitCount);
    notifyListeners();
    await _save();
  }

  Future<void> _setGoalMl(int ml) async {
    final clamped = ml.clamp(_minGoalMl, _maxGoalMl);
    if (clamped == _goalMl) return;
    _goalMl = clamped;
    // Bugünün kaydı varsa yeni hedefi yansıtacak şekilde güncelle (geçmiş
    // günlerin kendi goalUnitCount'u — bkz. WaterEntry dokümantasyonu —
    // bilerek DOKUNULMUYOR).
    final today = todayEntry;
    if (today != null) _upsertToday(today.unitCount);
    notifyListeners();
    await _save();
  }

  /// Hedefi güncel birimle adet olarak ayarlar (ör. "8 bardak").
  Future<void> setGoalUnitCount(int count) => _setGoalMl(count * mlPerUnit);
}
