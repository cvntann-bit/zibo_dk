import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/costumes.dart';
import '../models/costume.dart';
import '../models/costume_rarity.dart';
import '../services/cloud_state_store.dart';
import '../utils/zibo_event_signal.dart';

/// Kullanıcının satın aldığı kostümleri ve o an giyili olanı tutan tek
/// kaynak. Coin harcamasından bağımsız — tıpkı [GoalsProvider]'ın
/// [CoinProvider]'a bağımlı olmaması gibi, satın alma işlemini yürütmek
/// çağıran widget'ın sorumluluğunda (bkz. [CostumeCard]); bu provider
/// yalnızca "hangi kostümler sahiplenildi / hangisi giyili" durumunu tutar.
/// `CloudStateStore` ile kalıcı (bkz. o dosyadaki dokümantasyon) — [uid]
/// varsa Firestore'a da yazılır, `SharedPreferences` her zaman yerel yedek.
class CostumeProvider extends ChangeNotifier {
  CostumeProvider({String? uid, DateTime Function() now = DateTime.now})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid),
      _now = now {
    _loadFromPrefs();
  }

  /// "Bugünün vitrini" deneme süresi (ödüllü reklamla açılır).
  static const trialDuration = Duration(hours: 24);

  /// Denemeyi açmak için izlenmesi gereken ödüllü video sayısı — kullanıcı
  /// kararı (2026-10-26): pahalı kostüm = daha çok video.
  static int trialAdsRequiredFor(CostumeRarity rarity) => switch (rarity) {
    CostumeRarity.mythic => 5,
    CostumeRarity.legendary => 3,
    CostumeRarity.epic => 2,
    CostumeRarity.rare || CostumeRarity.common => 1,
  };

  static const _prefsKey = 'costumeState';
  // ÇOK ESKİ (Firestore migrasyonundan ÖNCEki) iki ayrı SharedPreferences
  // anahtarı — yalnızca BİR KEZLİK yerel-format göçü için okunuyor (bkz.
  // `_loadLegacyFormat`), `WaterProvider`'ın eski-format tanıma deseniyle
  // aynı gerekçe (bkz. CLAUDE.md "Su Takibi" bölümü).
  static const _legacyOwnedPrefsKey = 'ownedCostumeIds';
  static const _legacyEquippedPrefsKey = 'equippedCostumeId';

  final CloudStateStore _store;

  /// Deneme süresi ve "günde bir deneme" hakkı için — `main.dart`'ta
  /// `TrustedTimeProvider`'a bağlanır (saati ileri alıp hakkı yenileme yok).
  final DateTime Function() _now;

  Set<String> _ownedIds = {};
  String? _equippedId;

  // --- 24 saatlik vitrin denemesi (2026-10-26) -------------------------
  // Deneme SAHİPLİK DEĞİL: `_ownedIds`'e girmez (rozet sayımları, takas
  // vb. etkilenmez), yalnızca giyilebilir. Süre bitince kostüm çıkarılır,
  // deneme öncesi giyili olan kostüm geri giydirilir.
  String? _trialId;
  DateTime? _trialEndsAt;
  String? _preTrialEquippedId;
  String? _lastTrialDay;
  Timer? _trialTimer;

  // Denemeye doğru izlenen videolar — yalnızca o GÜN ve o kostüm için
  // geçerli (vitrin her gün değişir, ertesi gün sayaç sıfırdan başlar).
  String? _trialProgressId;
  int _trialProgressCount = 0;
  String? _trialProgressDay;

  Set<String> get ownedIds => Set.unmodifiable(_ownedIds);
  String? get equippedId => _equippedId;

  bool isOwned(String id) => _ownedIds.contains(id);
  bool isEquipped(String id) => _equippedId == id;

  /// [id] şu an süresi dolmamış bir denemede mi.
  bool isTrialActive(String id) =>
      _trialId == id && _trialEndsAt != null && _now().isBefore(_trialEndsAt!);

  /// Sahip olunan VEYA denemesi süren kostüm giyilebilir.
  bool canWear(String id) => isOwned(id) || isTrialActive(id);

  String? get activeTrialId =>
      (_trialId != null && isTrialActive(_trialId!)) ? _trialId : null;

  /// Aktif denemenin kalan süresi (yoksa `null`).
  Duration? get trialRemaining {
    final ends = _trialEndsAt;
    if (activeTrialId == null || ends == null) return null;
    return ends.difference(_now());
  }

  static String _dayString(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Bugün henüz deneme başlatılmadıysa `true` (günde bir deneme).
  bool get canStartTrialToday => _lastTrialDay != _dayString(_now());

  /// [id] için bugün izlenmiş deneme videosu sayısı.
  int trialAdsWatched(String id) =>
      (_trialProgressId == id && _trialProgressDay == _dayString(_now()))
      ? _trialProgressCount
      : 0;

  /// Ödüllü video başarıyla izlendikten SONRA çağrılır: [id] için sayacı bir
  /// artırır; gereken sayıya ([trialAdsRequiredFor]) ulaşınca denemeyi
  /// başlatır ve `true` döner. Hak yoksa / kostüm uygun değilse `false`.
  Future<bool> registerTrialAdWatched(String id) async {
    final costume = findCostumeById(id);
    if (costume == null || !costume.acquisition.isPurchasable) return false;
    if (isOwned(id) || !canStartTrialToday) return false;
    final watched = trialAdsWatched(id) + 1;
    if (watched >= trialAdsRequiredFor(costume.rarity)) {
      _trialProgressId = null;
      _trialProgressCount = 0;
      _trialProgressDay = null;
      return startTrial(id);
    }
    _trialProgressId = id;
    _trialProgressCount = watched;
    _trialProgressDay = _dayString(_now());
    notifyListeners();
    await _save();
    return false;
  }

  /// Bugünün vitrin kostümü: mağazadan satın alınabilen, henüz sahip
  /// olunmayan kostümlerden gün sırasına göre DETERMİNİSTİK biri (her gün
  /// başka kostüm). Deneme sürüyorsa o kostüm. Hepsine sahipse `null`.
  Costume? get featuredTrialCostume {
    final active = activeTrialId;
    if (active != null) return findCostumeById(active);
    final candidates = costumes
        .where((c) => c.acquisition.isPurchasable && !isOwned(c.id))
        .toList();
    if (candidates.isEmpty) return null;
    final now = _now();
    final dayIndex =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return candidates[dayIndex % candidates.length];
  }

  /// `founder_badge` gibi mağazada SATILMAYAN pseudo-kostüm id'lerini (bkz.
  /// "Kurucu Üye Rozeti" bölümü) SAYMAYAN, yalnızca `costumes.dart`'taki
  /// GERÇEK/satılabilir kostümlerden kaçının sahiplenildiğini döner —
  /// "Koleksiyoncu"/"Moda İkonu" rozetleri için (bkz. `collection_badges.
  /// dart`). Sahiplik kaynağı (satın alma VEYA bir rozetle hediye edilme,
  /// bkz. `data/badge_gift_rewards.dart`) ÖNEMSİZ, `isOwned` zaten
  /// kaynaktan bağımsız.
  int get ownedRealCostumeCount => costumes.where((c) => isOwned(c.id)).length;

  /// Mağazadaki TÜM kostümlere (kaynağı ne olursa olsun) sahip olunmuş mu —
  /// "Tam Gardırop" rozeti için. `ownedRealCostumeCount >= costumes.length`
  /// KARŞILAŞTIRMASI BİLEREK KULLANILMIYOR — kullanıcı `founder_badge`
  /// gibi satılamayan bir id'ye de sahipse bu SAYIM eşitliği YANLIŞ POZİTİF
  /// üretebilirdi (16 gerçek kostümün 15'ine + founder_badge'e sahip biri
  /// "16 sahip" görünürdü); `every` her kostümü TEK TEK doğruladığı için bu
  /// riski taşımıyor.
  bool get ownsAllCostumes => costumes.every((c) => isOwned(c.id));

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe (Ana
  /// Sayfa'daki Zibo görselinin giyili kostümü BAŞTAN doğru göstermesi,
  /// önce varsayılan görsele sonra kostüme "zıplamaması" için).
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Yeni birleşik anahtarda (`costumeState`) veri yok — ÇOK ESKİ
      // sürümlerden kalma iki ayrı anahtarı kontrol et, varsa birleştirip
      // hem yeni yerel biçime hem (varsa) Firestore'a yaz.
      data = await _loadLegacyFormat();
      if (data != null) await _store.save(data);
    }
    if (data != null) {
      _ownedIds = (data['ownedIds'] as List).cast<String>().toSet();
      _equippedId = data['equippedId'] as String?;
      // Deneme alanları eski kayıtlarda yok → null (oku-zamanı göçü).
      _trialId = data['trialId'] as String?;
      _trialEndsAt = DateTime.tryParse(data['trialEndsAt'] as String? ?? '');
      _preTrialEquippedId = data['preTrialEquippedId'] as String?;
      _lastTrialDay = data['lastTrialDay'] as String?;
      _trialProgressId = data['trialProgressId'] as String?;
      _trialProgressCount = (data['trialProgressCount'] as num?)?.toInt() ?? 0;
      _trialProgressDay = data['trialProgressDay'] as String?;
    }
    _isReady = true;
    // Uygulama kapalıyken süre dolmuş olabilir.
    if (!_expireTrialIfDue()) _scheduleTrialExpiry();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadLegacyFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_legacyOwnedPrefsKey);
    final equipped = prefs.getString(_legacyEquippedPrefsKey);
    if (owned == null && equipped == null) return null;
    return {'ownedIds': owned ?? <String>[], 'equippedId': equipped};
  }

  Future<void> _save() => _store.save({
    'ownedIds': _ownedIds.toList(),
    'equippedId': _equippedId,
    'trialId': _trialId,
    'trialEndsAt': _trialEndsAt?.toIso8601String(),
    'preTrialEquippedId': _preTrialEquippedId,
    'lastTrialDay': _lastTrialDay,
    'trialProgressId': _trialProgressId,
    'trialProgressCount': _trialProgressCount,
    'trialProgressDay': _trialProgressDay,
  });

  /// [id]'yi sahiplenilmiş olarak işaretler (satın alma tamamlandıktan
  /// sonra çağrılır). Zaten sahiplenilmişse hiçbir şey yapmaz.
  Future<void> markOwned(String id) async {
    if (_ownedIds.contains(id)) return;
    _ownedIds = {..._ownedIds, id};
    // Denenen kostüm satın alındıysa deneme biter, kostüm giyili kalır.
    if (_trialId == id) _clearTrial();
    notifyListeners();
    await _save();
  }

  /// Sahip olunan (veya denemesi süren) bir kostüme dokunma davranışı:
  /// giyili değilse giydirir, zaten giyiliyse çıkarır.
  Future<void> toggleEquipped(String id) async {
    if (!canWear(id)) return;
    _equippedId = _equippedId == id ? null : id;
    notifyListeners();
    await _save();
  }

  /// Gereken videolar izlenince ([registerTrialAdWatched]) çağrılır: [id]'yi
  /// [trialDuration] boyunca giyilebilir yapar ve giydirir. Günlük hak
  /// kullanıldıysa, kostüm zaten sahip olunansa veya satın alınamayan bir
  /// kostümse `false`.
  Future<bool> startTrial(String id) async {
    final costume = findCostumeById(id);
    if (costume == null || !costume.acquisition.isPurchasable) return false;
    if (isOwned(id) || !canStartTrialToday) return false;
    final now = _now();
    _preTrialEquippedId = _equippedId;
    _trialId = id;
    _trialEndsAt = now.add(trialDuration);
    _lastTrialDay = _dayString(now);
    _equippedId = id;
    _scheduleTrialExpiry();
    notifyListeners();
    await _save();
    return true;
  }

  /// Süre dolduysa denemeyi bitirir (uygulama ön plana dönünce de
  /// çağrılabilir). Değişiklik olmasa da dinleyicileri uyarır (bkz.
  /// providers/CLAUDE.md "notifyListeners disiplini").
  void reconcileTrial() {
    _expireTrialIfDue();
    notifyListeners();
  }

  /// Süresi dolan denemeyi kapatır: kostüm giyiliyse çıkarılıp deneme öncesi
  /// kostüm geri giydirilir, Zibo bunu Ana Sayfa'da nazikçe söyler.
  /// Bir şey değiştiyse `true`.
  bool _expireTrialIfDue() {
    final id = _trialId;
    final ends = _trialEndsAt;
    if (id == null || ends == null || _now().isBefore(ends)) return false;
    if (_equippedId == id && !isOwned(id)) {
      final previous = _preTrialEquippedId;
      _equippedId = (previous != null && isOwned(previous)) ? previous : null;
    }
    _clearTrial();
    pendingZiboEvent.value = ZiboEventType.costumeTrialEnded;
    unawaited(_save());
    return true;
  }

  void _clearTrial() {
    _trialTimer?.cancel();
    _trialTimer = null;
    _trialId = null;
    _trialEndsAt = null;
    _preTrialEquippedId = null;
  }

  void _scheduleTrialExpiry() {
    _trialTimer?.cancel();
    final remaining = trialRemaining;
    if (remaining == null) return;
    _trialTimer = Timer(remaining, () {
      if (_expireTrialIfDue()) notifyListeners();
    });
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }
}
