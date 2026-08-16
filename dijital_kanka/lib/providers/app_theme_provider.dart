import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının satın aldığı kod-tabanlı temaları ve o an aktif olanı tutan
/// tek kaynak. `CostumeProvider` ile BİREBİR AYNI desen (owned set + tek bir
/// equipped/aktif id) — coin harcamasından bağımsız, satın alma işlemini
/// yürütmek çağıran widget'ın sorumluluğunda (bkz. `ThemeOptionCard`).
/// `CloudStateStore` ile kalıcı — [uid] varsa Firestore'a da yazılır,
/// `SharedPreferences` her zaman yerel yedek.
class AppThemeProvider extends ChangeNotifier {
  AppThemeProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'appThemeState';
  // ÇOK ESKİ (Firestore migrasyonundan ÖNCEki) iki ayrı SharedPreferences
  // anahtarı — yalnızca BİR KEZLİK yerel-format göçü için okunuyor (bkz.
  // `_loadLegacyFormat`, `CostumeProvider`'daki aynı desenin birebir aynısı).
  static const _legacyOwnedPrefsKey = 'ownedAppThemeIds';
  static const _legacyEquippedPrefsKey = 'equippedAppThemeId';

  final CloudStateStore _store;

  Set<String> _ownedIds = {};
  String? _equippedId;

  Set<String> get ownedIds => Set.unmodifiable(_ownedIds);
  String? get equippedId => _equippedId;

  bool isOwned(String id) => _ownedIds.contains(id);
  bool isEquipped(String id) => _equippedId == id;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe.
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
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

  /// Sahip olunan bir temaya dokunma davranışı: aktif değilse uygular,
  /// zaten aktifse kaldırır (varsayılan görünüme döner). Tek seferde en
  /// fazla bir tema aktif olabilir (yeni bir tema uygulamak eskisinin
  /// yerini otomatik alır, çünkü `_equippedId` tek bir değer tutar).
  Future<void> toggleEquipped(String id) async {
    if (!_ownedIds.contains(id)) return;
    _equippedId = _equippedId == id ? null : id;
    notifyListeners();
    await _save();
  }
}
