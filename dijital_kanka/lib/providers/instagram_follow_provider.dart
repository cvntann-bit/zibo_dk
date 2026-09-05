import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// 2026 yeni özellik — Instagram Takip Kartı ve Ödülü (bkz. CLAUDE.md).
/// Gerçek bir takip doğrulaması teknik olarak mümkün olmadığı için (Instagram
/// bunu üçüncü parti bir uygulamaya asla açmıyor), bu tamamen kullanıcı
/// BEYANINA dayalı, TEK SEFERLİK bir işlem — `ThemeProvider`/`OnboardingProvider`
/// ile AYNI "tek bir kalıcı bool bayrak" (Varyant C) `CloudStateStore` deseni.
///
/// **Tekrar tekrar ödül toplamayı önleyen tek koruma [markClaimed]'in
/// idempotent kontrolüdür** — `_claimed` bir kez `true` olduktan sonra
/// [markClaimed] HER ZAMAN `false` döner, çağıran taraf (bkz.
/// `instagram_follow_card.dart`) bu durumda coin/kostüm/tema ÖDÜLLERİNİN
/// HİÇBİRİNİ vermez. Kart ayrıca `claimed == true` iken kendini TAMAMEN
/// gizler (bkz. widget dokümantasyonu) — bu yüzden gerçek kullanımda bu yola
/// hiç girilmiyor, ama API seviyesinde çift bir güvenlik katmanı.
class InstagramFollowProvider extends ChangeNotifier {
  InstagramFollowProvider({this.uid, FirebaseFirestore? firestore})
    : _store = CloudStateStore(
        prefsKey: _prefsKey,
        uid: uid,
        firestore: firestore,
      ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'instagramFollowState';

  final String? uid;
  final CloudStateStore _store;

  bool _claimed = false;
  bool get claimed => _claimed;

  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      _claimed = data['claimed'] as bool? ?? false;
    }
    _isReady = true;
    notifyListeners();
  }

  /// Ödülü SADECE BİR KEZ işaretler — zaten `claimed` ise `false` döner ve
  /// hiçbir şey değişmez (çağıran taraf bu durumda GERÇEK ödülü [CoinProvider.
  /// earnInstagramFollowReward] / kostüm-tema hediyesini VERMEMELİ).
  Future<bool> markClaimed() async {
    if (_claimed) return false;
    _claimed = true;
    notifyListeners();
    await _store.save({'claimed': true});
    return true;
  }
}
