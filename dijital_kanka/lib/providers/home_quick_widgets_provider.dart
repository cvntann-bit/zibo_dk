import 'package:flutter/material.dart';

import '../models/home_quick_module.dart';
import '../services/cloud_state_store.dart';

/// Ana Sayfa'daki iki değiştirilebilir mini widget slotunun (varsayılan:
/// Su/Hedef) hangi modülü gösterdiğini tutar. `CloudStateStore` ile kalıcı —
/// [uid] varsa Firestore'a da yazılır, `SharedPreferences` her zaman yerel
/// yedek (bkz. `ThemeProvider` ile aynı desen).
class HomeQuickWidgetsProvider extends ChangeNotifier {
  HomeQuickWidgetsProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'homeQuickModules';

  final CloudStateStore _store;

  HomeQuickModule _slot1 = HomeQuickModule.water;
  HomeQuickModule get slot1 => _slot1;

  HomeQuickModule _slot2 = HomeQuickModule.goal;
  HomeQuickModule get slot2 => _slot2;

  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    _slot1 = _moduleFromName(data?['slot1']) ?? HomeQuickModule.water;
    _slot2 = _moduleFromName(data?['slot2']) ?? HomeQuickModule.goal;
    _isReady = true;
    notifyListeners();
  }

  HomeQuickModule? _moduleFromName(Object? name) {
    if (name is! String) return null;
    for (final module in HomeQuickModule.values) {
      if (module.name == name) return module;
    }
    return null;
  }

  Future<void> setSlot1(HomeQuickModule module) async {
    if (_slot1 == module) return;
    _slot1 = module;
    notifyListeners();
    await _save();
  }

  Future<void> setSlot2(HomeQuickModule module) async {
    if (_slot2 == module) return;
    _slot2 = module;
    notifyListeners();
    await _save();
  }

  Future<void> _save() => _store.save({'slot1': _slot1.name, 'slot2': _slot2.name});
}
