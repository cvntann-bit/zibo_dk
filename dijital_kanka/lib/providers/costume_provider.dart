import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_state_store.dart';

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
}
