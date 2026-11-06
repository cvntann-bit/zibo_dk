import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/home_config.dart';
import '../models/home_need.dart';
import '../models/subscription_tier.dart';
import '../services/cloud_state_store.dart';

/// Zibo'nun dört ihtiyacı (tokluk, temizlik, enerji, mutluluk) ve günlük
/// ücretsiz yemek hakkı. docs/zibo_world_roadmap.md Faz 1.
///
/// **Tembel düşüş:** saklanan değer ve zamanı tutulur, güncel değer her
/// okumada geçen süreden hesaplanır — arka planda zamanlayıcı yok, uygulama
/// kapalıyken geçen süre de sayılır. Bir değişiklikten önce güncel değerler
/// kalıcı hale getirilir ([_settle]).
///
/// **Gerçek zamanlı uyku (Faz 0 kararı):** [startSleep] başlangıç anını yazar;
/// enerji o andan itibaren geçen süreye göre dolar, uyku sürerken enerji
/// düşmez. Saat geri alınırsa geçen süre 0 sayılır.
///
/// `now`, güne bağlı diğer provider'lar gibi `TrustedTimeProvider`'a bağlanır
/// (cihaz saatini ileri alarak ihtiyaç doldurulamasın, günlük hak
/// sıfırlanamasın).
class HomeNeedsProvider extends ChangeNotifier {
  HomeNeedsProvider({
    String? uid,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
    HomeConfig Function()? config,
    SubscriptionTier Function()? tier,
  }) : _now = now ?? DateTime.now,
       _config = config ?? (() => HomeConfig.defaults),
       _tier = tier ?? (() => SubscriptionTier.free),
       _store = CloudStateStore(prefsKey: _prefsKey, uid: uid, firestore: firestore) {
    _ready = _loadFromPrefs();
  }

  static const _prefsKey = 'homeNeedsState';
  static const _startLevel = 80.0;

  final DateTime Function() _now;
  final HomeConfig Function() _config;
  final SubscriptionTier Function() _tier;
  final CloudStateStore _store;

  final Map<HomeNeed, double> _stored = {for (final need in HomeNeed.values) need: _startLevel};
  DateTime? _updatedAt;
  DateTime? _sleepStartedAt;
  double _sleepStartEnergy = _startLevel;
  String? _freeFoodDay;
  int _freeFoodsUsed = 0;
  int _adFoodsUsed = 0;

  // Rozet sayaçları (kalıcı, ömür boyu). Uyku yalnız en az [_sleepCountMin]
  // enerji kazanıp uyanınca sayılır — ışığı aç/kapa ile kasılmasın.
  int _feedCount = 0;
  int _bathCount = 0;
  int _sleepCount = 0;
  int _careDays = 0;
  String? _lastCareDay;
  double _sleepBaseEnergy = _startLevel;
  static const _sleepCountMin = 30.0;

  int get feedCount => _feedCount;
  int get bathCount => _bathCount;
  int get sleepCount => _sleepCount;
  int get careDays => _careDays;

  late final Future<void> _ready;
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Kayıt yüklenince tamamlanır (testler bekler).
  Future<void> get ready => _ready;

  bool get isAsleep => _sleepStartedAt != null;

  double _hoursSince(DateTime? from) {
    if (from == null) return 0;
    final minutes = _now().difference(from).inSeconds / 60;
    return minutes <= 0 ? 0 : minutes / 60;
  }

  /// Güncel değer (0–100), geçen süreye göre hesaplanır.
  double level(HomeNeed need) {
    final config = _config();
    if (need == HomeNeed.energy && isAsleep) {
      final speed = config.sleepSpeedFor(_tier());
      final gained = _hoursSince(_sleepStartedAt) * 60 / config.sleepMinutesToFull * 100 * speed;
      return (_sleepStartEnergy + gained).clamp(0, 100).toDouble();
    }
    final stored = _stored[need]!;
    final rate = (config.decayPerHour[need] ?? 0) * config.decayFactorFor(_tier());
    final decayed = stored - rate * _hoursSince(_updatedAt);
    if (stored <= config.minLevel) return stored;
    return decayed < config.minLevel ? config.minLevel : decayed;
  }

  int percent(HomeNeed need) => level(need).round();

  /// En düşük ihtiyaç — Zibo bu odada durur ve onu ister.
  HomeNeed get lowest {
    var best = HomeNeed.values.first;
    for (final need in HomeNeed.values) {
      if (level(need) < level(best)) best = need;
    }
    return best;
  }

  String get _todayKey {
    final d = _now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int get freeFoodsLeft {
    final limit = _config().freeFoodsFor(_tier());
    final used = _freeFoodDay == _todayKey ? _freeFoodsUsed : 0;
    return (limit - used).clamp(0, limit);
  }

  /// Gün değiştiyse ücretsiz ve reklam yemeği sayaçları sıfırlanır.
  void _rollFoodDay() {
    if (_freeFoodDay == _todayKey) return;
    _freeFoodDay = _todayKey;
    _freeFoodsUsed = 0;
    _adFoodsUsed = 0;
  }

  /// Bugün ödüllü reklamla alınabilecek ek ücretsiz yemek — yalnız ücretsiz
  /// kullanıcı ve yalnız ücretsiz yemekleri bitince.
  int get adFoodsLeft {
    if (_tier() != SubscriptionTier.free || freeFoodsLeft > 0) return 0;
    final limit = _config().adFoodsPerDay;
    final used = _freeFoodDay == _todayKey ? _adFoodsUsed : 0;
    return (limit - used).clamp(0, limit);
  }

  /// Reklam sonuna kadar izlenince: bir ücretsiz yemek hakkı geri gelir.
  bool grantAdFood() {
    if (adFoodsLeft <= 0) return false;
    _rollFoodDay();
    _adFoodsUsed++;
    _freeFoodsUsed--;
    notifyListeners();
    _save();
    return true;
  }

  /// Ücretsiz yemek hakkından bir tane düşer; hak yoksa false.
  bool useFreeFood() {
    if (freeFoodsLeft <= 0) return false;
    _rollFoodDay();
    _freeFoodsUsed++;
    notifyListeners();
    _save();
    return true;
  }

  /// İhtiyacı [amount] kadar artırır (en fazla 100).
  void add(HomeNeed need, double amount) {
    _settle();
    if (need == HomeNeed.energy && isAsleep) {
      _sleepStartEnergy = (_sleepStartEnergy + amount).clamp(0, 100).toDouble();
    } else {
      _stored[need] = (_stored[need]! + amount).clamp(0, 100).toDouble();
    }
    notifyListeners();
    _save();
  }

  /// Bugün ilk bakım ise bakım günü sayacı artar.
  void _markCareDay() {
    final today = _todayKey;
    if (_lastCareDay == today) return;
    _lastCareDay = today;
    _careDays++;
  }

  /// Mutfakta Zibo bir yemeği yediğinde (rozet sayacı).
  void recordFeed() {
    _feedCount++;
    _markCareDay();
    notifyListeners();
    _save();
  }

  /// Banyoda havluyla kurulanıp tertemiz olunca (rozet sayacı).
  void recordBath() {
    _bathCount++;
    _markCareDay();
    notifyListeners();
    _save();
  }

  void startSleep() {
    if (isAsleep) return;
    _settle();
    _sleepStartedAt = _now();
    _sleepStartEnergy = _stored[HomeNeed.energy]!;
    _sleepBaseEnergy = _sleepStartEnergy;
    _markCareDay();
    notifyListeners();
    _save();
  }

  void wake() {
    if (!isAsleep) return;
    _settle();
    if (_sleepStartEnergy - _sleepBaseEnergy >= _sleepCountMin) _sleepCount++;
    _stored[HomeNeed.energy] = _sleepStartEnergy;
    _sleepStartedAt = null;
    notifyListeners();
    _save();
  }

  /// Ekranlar dakikada bir çağırır — değerler zamanla değiştiği için.
  void refresh() => notifyListeners();

  /// Güncel değerleri saklanan değer yapar, zamanı şimdiye çeker. Uyku
  /// sürüyorsa enerji yeni bir başlangıç noktasından devam eder.
  void _settle() {
    final now = _now();
    for (final need in HomeNeed.values) {
      if (need == HomeNeed.energy && isAsleep) continue;
      _stored[need] = level(need);
    }
    if (isAsleep) {
      _sleepStartEnergy = level(HomeNeed.energy);
      _sleepStartedAt = now;
    }
    _updatedAt = now;
  }

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      try {
        final levels = data['levels'];
        if (levels is Map) {
          for (final entry in levels.entries) {
            final need = HomeNeed.fromId('${entry.key}');
            if (need != null && entry.value is num) _stored[need] = (entry.value as num).toDouble().clamp(0, 100).toDouble();
          }
        }
        _updatedAt = DateTime.tryParse('${data['updatedAt'] ?? ''}');
        _sleepStartedAt = DateTime.tryParse('${data['sleepStartedAt'] ?? ''}');
        _sleepStartEnergy = (data['sleepStartEnergy'] as num?)?.toDouble() ?? _stored[HomeNeed.energy]!;
        _freeFoodDay = data['freeFoodDay'] as String?;
        _freeFoodsUsed = (data['freeFoodsUsed'] as num?)?.toInt() ?? 0;
        _adFoodsUsed = (data['adFoodsUsed'] as num?)?.toInt() ?? 0;
        _feedCount = (data['feedCount'] as num?)?.toInt() ?? 0;
        _bathCount = (data['bathCount'] as num?)?.toInt() ?? 0;
        _sleepCount = (data['sleepCount'] as num?)?.toInt() ?? 0;
        _careDays = (data['careDays'] as num?)?.toInt() ?? 0;
        _lastCareDay = data['lastCareDay'] as String?;
        _sleepBaseEnergy = (data['sleepBaseEnergy'] as num?)?.toDouble() ?? _sleepStartEnergy;
      } catch (_) {
        // Bozuk kayıt: varsayılanlarla devam (diğer provider'larla aynı kural).
      }
    }
    _updatedAt ??= _now();
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() => _store.save({
    'levels': {for (final need in HomeNeed.values) need.id: _stored[need]},
    'updatedAt': _updatedAt?.toIso8601String(),
    'sleepStartedAt': _sleepStartedAt?.toIso8601String(),
    'sleepStartEnergy': _sleepStartEnergy,
    'freeFoodDay': _freeFoodDay,
    'freeFoodsUsed': _freeFoodsUsed,
    'adFoodsUsed': _adFoodsUsed,
    'feedCount': _feedCount,
    'bathCount': _bathCount,
    'sleepCount': _sleepCount,
    'careDays': _careDays,
    'lastCareDay': _lastCareDay,
    'sleepBaseEnergy': _sleepBaseEnergy,
  });
}
