import 'package:flutter/foundation.dart';

import '../data/currencies.dart';
import '../services/cloud_state_store.dart';

/// Para ve Birikim modülünde kullanıcının seçtiği para birimini tutan ve
/// kalıcı olarak saklayan tek kaynak — `ThemeProvider`/`LocaleProvider` ile
/// birebir aynı desen (`CloudStateStore`, tek skaler değer `{'value': ...}`
/// olarak sarılı). Varsayılan Türk Lirası — bu modülün önceki sabit ₺
/// davranışıyla aynı, kullanıcı hiç değiştirmediyse davranış değişmez.
class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'currencyState';
  static const defaultCurrencyCode = 'TRY';

  final CloudStateStore _store;

  String _currencyCode = defaultCurrencyCode;
  String get currencyCode => _currencyCode;
  CurrencyOption get currency => currencyByCode(_currencyCode);

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    final saved = data?['value'] as String?;
    if (saved != null && currencies.any((c) => c.code == saved)) {
      _currencyCode = saved;
    }
    notifyListeners();
  }

  Future<void> setCurrencyCode(String code) async {
    if (_currencyCode == code || !currencies.any((c) => c.code == code)) return;
    _currencyCode = code;
    notifyListeners();
    await _store.save({'value': code});
  }
}
