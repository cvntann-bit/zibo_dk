import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// Uygulamanın İLK açılışta gösterdiği tanıtım akışının (bkz.
/// `OnboardingScreen`) tamamlanıp tamamlanmadığını tutan tek kaynak.
/// `CloudStateStore` ile kalıcı — diğer tüm provider'larla aynı desen
/// (tek anahtarlı JSON blob, `onboardingState`).
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({String? uid})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'onboardingState';

  final CloudStateStore _store;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe:
  /// `_AppStartupGate` bu alan `true` olana kadar hiçbir şey göstermemeli,
  /// aksi halde kullanıcı bir an için Ana Sayfa'yı görüp hemen ardından
  /// onboarding akışına "zıplayabilir" (veya tam tersi).
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    _isCompleted = data?['completed'] as bool? ?? false;
    _isReady = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_isCompleted) return;
    _isCompleted = true;
    notifyListeners();
    await _store.save({'completed': true});
  }
}
