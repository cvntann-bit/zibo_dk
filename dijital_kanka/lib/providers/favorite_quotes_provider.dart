import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının Ana Sayfa'daki konuşma balonundan kalp ikonuyla favorilediği
/// sözleri tutar (bkz. `FavoriteQuoteButton`) — `DreamJournalProvider` ile
/// aynı `CloudStateStore` kalıcılık deseni.
///
/// Söz metni, favorilendiği ANDAKİ hâliyle (kullanıcının o an seçili olan
/// hitap tercihiyle, bkz. `applyAddressTerm`) saklanır — `GoalCompletion`'daki
/// "anlık görüntü" mantığıyla aynı gerekçe: kullanıcı sonradan hitap
/// tercihini değiştirirse geçmişte favorilediği söz olduğu gibi kalır.
class FavoriteQuotesProvider extends ChangeNotifier {
  FavoriteQuotesProvider({String? uid})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'favoriteQuotes';

  final CloudStateStore _store;
  final List<String> _quotes = [];

  /// En son favorilenen en üstte.
  List<String> get quotes => List.unmodifiable(_quotes);

  bool isFavorite(String quote) => _quotes.contains(quote);

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded == null) return;
    try {
      final rawList = decoded['quotes'] as List;
      _quotes
        ..clear()
        ..addAll(rawList.cast<String>());
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  Future<void> _save() => _store.save({'quotes': _quotes});

  void toggleFavorite(String quote) {
    if (!_quotes.remove(quote)) {
      _quotes.insert(0, quote);
    }
    notifyListeners();
    _save();
  }
}
