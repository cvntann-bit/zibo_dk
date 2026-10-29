import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/in_app_message.dart';

/// Yönetici panelinin uygulama içi mesaj kartları (`inAppMessages`) — açılışta BİR KEZ okunur
/// (`GamesConfigProvider` ile aynı uzaktan-okuma deseni). Görülen kart id'leri YALNIZCA yerelde
/// (`SharedPreferences`) tutulur: kart başına buluta yazım maliyeti olmasın; yeniden kurulumda
/// süresi bitmemiş bir kartın tekrar görünmesi kabul edilebilir.
///
/// Kartı NE ZAMAN göstereceğine `RootScreen` karar verir (Ana Sayfa seçili + üstte başka
/// pencere yokken), bkz. `RootScreen._maybeShowInAppMessage`.
class InAppMessageProvider extends ChangeNotifier {
  InAppMessageProvider({String? uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance) {
    _load();
  }

  static const _seenKey = 'inAppMessageSeenIds';
  static const _maxSeen = 50;

  final FirebaseFirestore? _firestore;
  List<InAppMessage> _messages = const [];
  List<String> _seenIds = const [];

  List<InAppMessage> get messages => _messages;
  Set<String> get seenIds => _seenIds.toSet();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seenIds = prefs.getStringList(_seenKey) ?? const [];
    } catch (_) {}
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      // Tek alanlı aralık sorgusu (bileşik indeks gerekmez); başlangıç/kitle/dil süzgeci istemcide.
      final snap = await firestore
          .collection('inAppMessages')
          .where('endAt', isGreaterThan: Timestamp.now())
          .limit(10)
          .get();
      _messages = [
        for (final doc in snap.docs) ?InAppMessage.fromFirestore(doc.id, doc.data()),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('InAppMessageProvider: inAppMessages okunamadı ($e)');
    }
  }

  Future<void> markSeen(String id) async {
    if (_seenIds.contains(id)) return;
    _seenIds = [..._seenIds, id];
    if (_seenIds.length > _maxSeen) _seenIds = _seenIds.sublist(_seenIds.length - _maxSeen);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenKey, _seenIds);
    } catch (_) {}
  }
}
