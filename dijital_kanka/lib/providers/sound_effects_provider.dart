import 'package:flutter/material.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının uygulama içi kısa ses efektlerini (şimdilik yalnızca Zibo
/// dokunma sesi, bkz. `SoundEffectsService`) açık/kapalı tercihini tutan ve
/// kalıcı olarak saklayan tek kaynak — `ThemeProvider` ile BİREBİR AYNI
/// Varyant C (`CloudStateStore`, tek bool, `{'value': ...}` sarmalı) deseni.
class SoundEffectsProvider extends ChangeNotifier {
  SoundEffectsProvider({String? uid})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'soundEffectsState';

  final CloudStateStore _store;

  bool _enabled = true;
  bool get enabled => _enabled;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    final saved = data?['value'] as bool?;
    if (saved != null) {
      _enabled = saved;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    await _store.save({'value': value});
  }
}
