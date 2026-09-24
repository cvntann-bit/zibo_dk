import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/manifest_frames.dart';
import '../services/cloud_state_store.dart';

/// Manifest süsleme editöründe Zibo Coin ile açılmış premium çerçeveler.
/// `AppThemeProvider`/`CostumeProvider` ile AYNI "sahip olunan id listesi"
/// deseni. Harcamayı çağıran taraf `CoinProvider` üzerinden yapar, burası
/// yalnızca sahipliği kaydeder.
class ManifestDecorProvider extends ChangeNotifier {
  ManifestDecorProvider({String? uid, FirebaseFirestore? firestore})
    : _store = CloudStateStore(prefsKey: prefsKey, uid: uid, firestore: firestore) {
    _loadFromPrefs();
  }

  static const prefsKey = 'manifestDecorState';

  final CloudStateStore _store;
  final Set<String> _ownedFrameIds = {};

  bool isFrameUnlocked(ManifestFrame frame) =>
      !frame.isPremium || _ownedFrameIds.contains(frame.id);

  Future<void> _loadFromPrefs() async {
    try {
      final data = await _store.load();
      final ids = data?['ownedFrameIds'] as List?;
      if (ids != null) _ownedFrameIds.addAll(ids.whereType<String>());
    } catch (_) {}
    notifyListeners();
  }

  void unlockFrame(ManifestFrame frame) {
    if (!_ownedFrameIds.add(frame.id)) return;
    notifyListeners();
    _store.save({'ownedFrameIds': _ownedFrameIds.toList()});
  }
}
