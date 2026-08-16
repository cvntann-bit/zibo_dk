import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_state_store.dart';

/// Uygulamanın desteklediği dil kodları — sırayla Ayarlar'daki dil
/// seçicisinde bu sırayla listelenir.
const supportedLanguageCodes = ['tr', 'en', 'es'];

/// Kullanıcının dil tercihini tutan ve kalıcı olarak saklayan tek kaynak —
/// `ThemeProvider` ile birebir aynı desen (`CloudStateStore`, tek skaler
/// değer `{'value': ...}` olarak sarılı). Varsayılan Türkçe: uygulamanın
/// önceki sabit `Locale('tr')` davranışıyla aynı, kullanıcı hiç dil
/// değiştirmediyse davranış değişmez.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'languageCode';

  final CloudStateStore _store;

  Locale _locale = const Locale('tr');
  Locale get locale => _locale;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe, başlangıç
  /// yükleme ekranı bunu da bekliyor.
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Firestore migrasyonundan ÖNCE bu anahtar altında düz bir string
      // (`prefs.setString`, JSON değil) saklanıyordu — `CloudStateStore`
      // `jsonDecode` ile açmaya çalıştığı için bu ÇOK ESKİ biçimi burada
      // ayrıca tanıyıp yeni sarmalanmış biçime göç ettiriyoruz (bkz.
      // `ThemeProvider`'daki aynı gerekçeli göç deseni).
      final legacy = await _loadLegacyString();
      if (legacy != null) {
        data = {'value': legacy};
        await _store.save(data);
      }
    }
    final saved = data?['value'] as String?;
    if (saved != null && supportedLanguageCodes.contains(saved)) {
      _locale = Locale(saved);
    }
    _isReady = true;
    notifyListeners();
  }

  Future<String?> _loadLegacyString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _store.save({'value': locale.languageCode});
  }
}
