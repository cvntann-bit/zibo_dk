import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/home_config.dart';

/// Zibo'nun Evi rakamlarını sağlar — `GamesConfigProvider` ile aynı desen:
/// önce [HomeConfig.defaults], Firebase varsa `config/home` bir kez okunup
/// üstüne uygulanır. Okuma hatası sessizce yutulur, ev varsayılanlarla çalışır.
/// Yazma yalnızca yönetici (`firestore.rules` `isAdmin()`).
class HomeConfigProvider extends ChangeNotifier {
  HomeConfigProvider({String? uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance) {
    if (_firestore != null) _fetch();
  }

  final FirebaseFirestore? _firestore;
  HomeConfig _config = HomeConfig.defaults;

  HomeConfig get config => _config;

  Future<void> _fetch() async {
    try {
      final snap = await _firestore!.collection('config').doc('home').get();
      if (!snap.exists) return;
      _config = HomeConfig.fromJson(snap.data());
      notifyListeners();
    } catch (e) {
      debugPrint('HomeConfigProvider: config/home okunamadı, varsayılanlar kullanılıyor ($e)');
    }
  }
}
