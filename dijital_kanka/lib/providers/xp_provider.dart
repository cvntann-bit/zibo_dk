import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/xp_level.dart';
import '../services/cloud_state_store.dart';
import '../utils/level_up_signal.dart';

/// 2026 yeni özellik — genel Level/XP sistemi. Kullanıcının yaptığı HER
/// anlamlı aksiyon (bkz. `CoinProvider._earn`'e eklenen `onXpEarned` kancası
/// + Ruh Hali/Paylaşım/Odak Sayacı'ndaki doğrudan çağrılar) burada birikip
/// [LevelProgress]'e (bkz. `xp_level.dart`) dönüşür.
///
/// **Diğer TÜM provider'larla AYNI `CloudStateStore` (Varyant A: tek anahtar,
/// `{'totalXp': ...}`) deseni** — `ReferralProvider`/`FavoriteQuotesProvider`
/// ile birebir aynı iskelet.
///
/// **XP kaynağı — `CoinProvider._earn()` üzerinden 1:1 (kazanılan ZC kadar
/// XP), artı bazı coin-DIŞI aksiyonlar için doğrudan [addXp] çağrıları:**
/// Ruh Hali Takibi (günün İLK check-in'i), paylaşım başarısı, Odak Sayacı
/// seans tamamlama. Coin SATIN ALMA (`purchaseCoinPackage`) BİLEREK XP
/// VERMİYOR — gerçek parayla coin almak bir "başarı" değil, bu yüzden
/// `_earn(..., awardXp: false)` ile bastırılıyor (bkz. `CoinProvider`
/// dokümantasyonu, `playRewardSound: false` ile AYNI ayrım felsefesi).
class XpProvider extends ChangeNotifier {
  XpProvider({this.uid, FirebaseFirestore? firestore})
    : _store = CloudStateStore(
        prefsKey: _prefsKey,
        uid: uid,
        firestore: firestore,
      ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'xpState';

  final String? uid;
  final CloudStateStore _store;

  int _totalXp = 0;
  int get totalXp => _totalXp;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe (Profil'deki
  /// seviye/XP çubuğunun sıfırdan gerçek değere aniden "zıplamasını"
  /// önlemek, `_AppStartupGate`'in bu turda gate'lemediği, daha küçük bir
  /// bilgi parçası olduğu için burada yalnızca kendi tüketicileri için).
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Şu anki seviye + o seviyedeki ilerleme — bkz. `xp_level.dart`.
  LevelProgress get progress => levelProgressForTotalXp(_totalXp);

  int get level => progress.level;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      _totalXp = data['totalXp'] as int? ?? 0;
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() => _store.save({'totalXp': _totalXp});

  /// [amount] kadar XP ekler. Bir veya daha fazla seviye eşiği aşılırsa
  /// [pendingLevelUp]'a ULAŞILAN YENİ seviyeyi yazar (kutlama overlay'ini
  /// tetikler) — `amount <= 0` ise no-op.
  void addXp(int amount) {
    if (amount <= 0) return;
    final oldLevel = level;
    _totalXp += amount;
    notifyListeners();
    _save();
    final newLevel = level;
    if (newLevel > oldLevel) {
      pendingLevelUp.value = newLevel;
    }
  }
}
