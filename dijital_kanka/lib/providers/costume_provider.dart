import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/costumes.dart';
import '../models/costume_unlock_requirement.dart';
import '../services/cloud_state_store.dart';
import 'goals_provider.dart';
import 'water_provider.dart';

/// Kullanıcının satın aldığı kostümleri ve o an giyili olanı tutan tek
/// kaynak. Coin harcamasından bağımsız — tıpkı [GoalsProvider]'ın
/// [CoinProvider]'a bağımlı olmaması gibi, satın alma işlemini yürütmek
/// çağıran widget'ın sorumluluğunda (bkz. [CostumeCard]); bu provider
/// yalnızca "hangi kostümler sahiplenildi / hangisi giyili" durumunu tutar.
/// `CloudStateStore` ile kalıcı (bkz. o dosyadaki dokümantasyon) — [uid]
/// varsa Firestore'a da yazılır, `SharedPreferences` her zaman yerel yedek.
class CostumeProvider extends ChangeNotifier {
  CostumeProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'costumeState';
  // ÇOK ESKİ (Firestore migrasyonundan ÖNCEki) iki ayrı SharedPreferences
  // anahtarı — yalnızca BİR KEZLİK yerel-format göçü için okunuyor (bkz.
  // `_loadLegacyFormat`), `WaterProvider`'ın eski-format tanıma deseniyle
  // aynı gerekçe (bkz. CLAUDE.md "Su Takibi" bölümü).
  static const _legacyOwnedPrefsKey = 'ownedCostumeIds';
  static const _legacyEquippedPrefsKey = 'equippedCostumeId';

  final CloudStateStore _store;

  Set<String> _ownedIds = {};
  String? _equippedId;

  Set<String> get ownedIds => Set.unmodifiable(_ownedIds);
  String? get equippedId => _equippedId;

  bool isOwned(String id) => _ownedIds.contains(id);
  bool isEquipped(String id) => _equippedId == id;

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
    }
    _isReady = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadLegacyFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_legacyOwnedPrefsKey);
    final equipped = prefs.getString(_legacyEquippedPrefsKey);
    if (owned == null && equipped == null) return null;
    return {'ownedIds': owned ?? <String>[], 'equippedId': equipped};
  }

  Future<void> _save() =>
      _store.save({'ownedIds': _ownedIds.toList(), 'equippedId': _equippedId});

  /// [id]'yi sahiplenilmiş olarak işaretler (satın alma tamamlandıktan
  /// sonra çağrılır). Zaten sahiplenilmişse hiçbir şey yapmaz.
  Future<void> markOwned(String id) async {
    if (_ownedIds.contains(id)) return;
    _ownedIds = {..._ownedIds, id};
    notifyListeners();
    await _save();
  }

  /// Sahip olunan bir kostüme dokunma davranışı: giyili değilse giydirir,
  /// zaten giyiliyse çıkarır (varsayılan Zibo görünümüne döner).
  Future<void> toggleEquipped(String id) async {
    if (!_ownedIds.contains(id)) return;
    _equippedId = _equippedId == id ? null : id;
    notifyListeners();
    await _save();
  }

  /// 2026 güncellemesi — kullanıcı isteği: "TÜM kostümler hedefle de
  /// açılabilsin." `costumes.dart`'taki (`lib/data/costumes.dart`) HER
  /// kostümü dolaşıp, henüz SAHİP OLUNMAMIŞ VE bir `unlockRequirement`
  /// taşıyanlar için ilgili provider'dan (`goals`/`water`) o anki
  /// ilerlemeyi okur; hedefe ulaşılmışsa `markOwned(id)` çağırır (satın
  /// almadan TAMAMEN bağımsız, `CostumeCard._buy`'ın çağırdığı AYNI metot).
  ///
  /// `GoalsProvider`/`WaterProvider`'ı constructor'dan değil PARAMETRE
  /// olarak alıyor — `CostumeProvider`'ın coin/sound'dan bağımsız olma
  /// felsefesiyle AYNI gerekçe (bkz. sınıf dokümantasyonu): bu provider
  /// diğer provider'lara KALICI olarak bağımlı değil, yalnızca çağıran
  /// tarafın (bkz. `StoreScreen`) o anki verilerini geçici olarak okuyor.
  /// `StoreScreen`'in Mağaza'ya her girişte çağırdığı `isActive` kancasıyla
  /// (bkz. `_maybeShowAdFreePromo` ile AYNI desen) tetiklenmesi
  /// düşünülüyor — genel bir listener/arka plan servisi GEREKMİYOR.
  ///
  /// Yeni açılan kostümlerin id listesini döner — çağıran taraf bunu bir
  /// kutlama SnackBar'ı göstermek için kullanabilir; hiçbiri açılmadıysa
  /// boş liste (no-op, `notifyListeners()`/`_save()` HİÇ tetiklenmez).
  List<String> reconcileGoalUnlocks(GoalsProvider goals, WaterProvider water) {
    final unlocked = <String>[];
    for (final costume in costumes) {
      final requirement = costume.unlockRequirement;
      if (requirement == null || isOwned(costume.id)) continue;
      final progress = switch (requirement.type) {
        CostumeUnlockType.goalStreak => goals.longestStreak,
        CostumeUnlockType.goalCompletions => goals.completions.length,
        CostumeUnlockType.waterDaysCompleted => water.completedDaysCount,
      };
      if (progress >= requirement.target) {
        markOwned(costume.id);
        unlocked.add(costume.id);
      }
    }
    return unlocked;
  }
}
