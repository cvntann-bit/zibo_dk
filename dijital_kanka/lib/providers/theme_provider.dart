import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının koyu/açık tema tercihini tutan ve kalıcı olarak saklayan tek
/// kaynak. `CloudStateStore` ile kalıcı — [uid] varsa Firestore'a da yazılır,
/// `SharedPreferences` her zaman yerel yedek. Tek bir bool değeri
/// `CloudStateStore`'un beklediği `Map<String, dynamic>` biçimine
/// `{'value': ...}` olarak sarılıp/açılıyor.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'isDarkMode';

  final CloudStateStore _store;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// İlk yükleme (Firestore/yerel) tamamlandı mı — bkz.
  /// [main.dart]'taki başlangıç yükleme ekranı, `RootScreen`'i göstermeden
  /// önce bunun `true` olmasını bekliyor ki kullanıcı varsayılan (açık)
  /// temadan gerçek tercihe aniden "zıplayan" bir geçiş görmesin.
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Firestore migrasyonundan ÖNCE bu anahtar altında düz bir bool
      // (`prefs.setBool`) saklanıyordu — `CloudStateStore` yalnızca JSON
      // map okuyabildiği için bu ÇOK ESKİ biçimi burada ayrıca tanıyıp
      // yeni sarmalanmış biçime göç ettiriyoruz (bkz. `GratitudeProvider`
      // ile aynı gerekçeli göç deseni).
      final legacy = await _loadLegacyBool();
      if (legacy != null) {
        data = {'value': legacy};
        await _store.save(data);
      }
    }
    final saved = data?['value'] as bool?;
    if (saved != null) {
      _isDarkMode = saved;
    }
    _isReady = true;
    notifyListeners();
  }

  Future<bool?> _loadLegacyBool() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey);
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    await _store.save({'value': value});
  }
}
