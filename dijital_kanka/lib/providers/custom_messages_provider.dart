import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının Ana Sayfa'daki konuşma balonu için kendi yazdığı özel
/// mesajları tutar — `FavoriteQuotesProvider` ile aynı `CloudStateStore`
/// kalıcılık deseni (tek anahtarlı, düz bir string listesi).
///
/// Bu mesajlar Zibo'nun standart söz havuzunu (`zibo_messages.dart`)
/// DEĞİŞTİRMEZ — havuza EKLENİR, `HomeScreen` ikisini birleştirip rastgele
/// seçim yapıyor (bkz. `HomeScreen._pickNewMessageIndex`).
class CustomMessagesProvider extends ChangeNotifier {
  CustomMessagesProvider({String? uid})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'customMessagesState';

  final CloudStateStore _store;
  final List<String> _messages = [];

  /// En son eklenen en üstte.
  List<String> get messages => List.unmodifiable(_messages);

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded == null) return;
    try {
      final rawList = decoded['messages'] as List;
      _messages
        ..clear()
        ..addAll(rawList.cast<String>());
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  Future<void> _save() => _store.save({'messages': _messages});

  /// Boş/yalnızca boşluk içeren metinler sessizce reddedilir (diğer TÜM
  /// metin-girişi provider'larıyla aynı `trim()` koruması).
  void addMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _messages.insert(0, trimmed);
    notifyListeners();
    _save();
  }

  void removeMessage(String text) {
    if (!_messages.remove(text)) return;
    notifyListeners();
    _save();
  }
}
