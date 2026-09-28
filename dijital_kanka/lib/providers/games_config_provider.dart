import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/games_config.dart';

/// Oyun Salonu rakamlarını sağlar: önce [GamesConfig.defaults], ardından
/// (Firebase varsa) Firestore `config/games` dokümanı bir kez okunup
/// varsayılanların üstüne uygulanır — puan/tavan/hak değişiklikleri
/// uygulama güncellemesi olmadan, bir sonraki açılışta yansır.
///
/// `uid` yoksa (Firebase kullanılamıyor, testler) yalnızca varsayılanlar.
/// Okuma hatası sessizce yutulur — oyunlar varsayılanlarla çalışmaya devam
/// eder. `firestore.rules`'da `config/games` için giriş yapmış herkese
/// yalnızca OKUMA izni var; yazma yalnızca Firebase konsolundan.
class GamesConfigProvider extends ChangeNotifier {
  GamesConfigProvider({String? uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance) {
    if (_firestore != null) _fetch();
  }

  final FirebaseFirestore? _firestore;
  GamesConfig _config = GamesConfig.defaults;

  GamesConfig get config => _config;

  Future<void> _fetch() async {
    try {
      final snap = await _firestore!.collection('config').doc('games').get();
      if (!snap.exists) return;
      _config = GamesConfig.fromJson(snap.data());
      notifyListeners();
    } catch (e) {
      debugPrint('GamesConfigProvider: config/games okunamadı, varsayılanlar kullanılıyor ($e)');
    }
  }
}
