import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';
import '../services/google_auth_service.dart';

/// Kullanıcının anonim Firebase hesabını Google'a bağlama durumunu tutan
/// provider — `CoinProvider`/`ThemeProvider` ile AYNI "gerçek servis
/// enjekte edilebilir" felsefesi ([GoogleAuthService]).
///
/// **2026 yeni özellik.** Kullanıcı isteği: satın alınan Zibo Coin'lerin
/// (ve tüm diğer verinin) cihaz değişikliğinde kaybolmaması için Google ile
/// hesap bağlama. [isLinked]/[linkedEmail] Firebase'in KENDİSİNDEN CANLI
/// okunuyor (ayrı bir yerel kopya TUTULMUYOR — Firebase Auth zaten tek
/// gerçek kaynak) — yalnızca [hasSeenLinkPrompt] (ilk gerçek coin
/// satın alma denemesinde gösterilen teşvik sheet'inin BİR KEZ görülüp
/// görülmediği) `CloudStateStore` ile kalıcı, `ThemeProvider`'daki AYNI
/// "Varyant C tek skaler değer" deseni (bkz. o dosyadaki dokümantasyon).
class AuthLinkProvider extends ChangeNotifier {
  /// **Kritik — `CoinProvider`'ın `adService`/`SoundEffectsProvider`'ın
  /// varsayılan servisleriyle AYNI güvenlik deseni.** [googleAuthService]
  /// verilmezse VARSAYILAN olarak [FakeGoogleAuthService] (platform
  /// kanalına/Firebase'e HİÇ dokunmayan, her zaman "bağlı değil" dönen
  /// zararsız bir sahte) kullanılır — GERÇEK [FirebaseGoogleAuthService]
  /// DEĞİL. Bunun nedeni: `flutter_test` `Firebase.initializeApp()`'i HİÇ
  /// çağırmıyor (bkz. CLAUDE.md "Firestore Veri Kalıcılığı" bölümü —
  /// testler `main()`'i çalıştırmıyor), bu yüzden gerçek servisin
  /// constructor'da senkron olarak okuduğu `FirebaseAuth.instance.
  /// currentUser` bir `[core/no-app]` istisnası fırlatıp `DijitalKankaApp`
  /// kuran HER TEK testi ANINDA çökertirdi. Gerçek servis yalnızca
  /// `main.dart`'ın ÜRETİM `DijitalKankaApp` kurulumunda AÇIKÇA veriliyor —
  /// `AdMobAdService`'in `CoinProvider`'a verilme şekliyle BİREBİR aynı.
  AuthLinkProvider({GoogleAuthService? googleAuthService, String? uid})
    : _service = googleAuthService ?? const FakeGoogleAuthService(),
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _refreshLinkStatus();
    _loadHasSeenPrompt();
  }

  static const _prefsKey = 'googleLinkPromptState';

  final GoogleAuthService _service;
  final CloudStateStore _store;

  bool _isLinked = false;
  String? _linkedEmail;
  bool get isLinked => _isLinked;
  String? get linkedEmail => _linkedEmail;

  /// Google ile bağlama/giriş akışı şu an sürüyor mu — arayüz bunu bir
  /// yükleniyor göstergesi için izleyebilir.
  bool _isLinking = false;
  bool get isLinking => _isLinking;

  bool _hasSeenLinkPrompt = false;

  /// Kullanıcı Mağaza'dan ilk gerçek coin satın alma DENEMESİNDE gösterilen
  /// "hesabını bağla" teşvik sheet'ini daha önce GÖRDÜ mü (kabul etsin ya
  /// da "Şimdilik Atla" desin fark etmez, TEK sefer gösterilir) — bkz.
  /// `StoreScreen._PackageCardState._buy`.
  bool get hasSeenLinkPrompt => _hasSeenLinkPrompt;

  void _refreshLinkStatus() {
    _isLinked = _service.isCurrentUserLinked;
    _linkedEmail = _service.linkedEmail;
  }

  Future<void> _loadHasSeenPrompt() async {
    final data = await _store.load();
    _hasSeenLinkPrompt = data?['value'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> markLinkPromptSeen() async {
    if (_hasSeenLinkPrompt) return;
    _hasSeenLinkPrompt = true;
    notifyListeners();
    await _store.save({'value': true});
  }

  /// Mevcut (anonim) hesabı Google'a bağlar. Döner: `true` = başarıyla
  /// bağlandı, `false` = kullanıcı akışı iptal etti/vazgeçti. Bu Google
  /// hesabı ZATEN başka bir Firebase kullanıcısına bağlıysa
  /// [GoogleAccountAlreadyLinkedElsewhereException] fırlatır — çağıran
  /// (bkz. `utils/google_link_action.dart`) bunu yakalayıp kullanıcıya
  /// "o hesaba GEÇMEK ister misin?" diye sormalı.
  Future<bool> linkWithGoogle() async {
    _isLinking = true;
    notifyListeners();
    try {
      final email = await _service.linkCurrentUser();
      _refreshLinkStatus();
      return email != null;
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }

  /// Yeni cihazda önceden bağlanmış bir hesabı KURTARMAK için Google ile
  /// giriş yapar (mevcut anonim oturumun YERİNE geçer). Başarılı olursa
  /// dönen `GoogleSignInOutcome.uid`, çağıran tarafından `switchToUid`
  /// sinyaline (bkz. `utils/auth_switch.dart`) verilip TÜM uygulamanın o
  /// yeni uid ile yeniden kurulması tetiklenmeli — bu provider'ın kendisi
  /// bunu YAPMAZ (kendi `uid`'i sabit, `main.dart`'ın `_AppRoot`'u
  /// sorumlu).
  Future<GoogleSignInOutcome?> signInWithGoogle() async {
    _isLinking = true;
    notifyListeners();
    try {
      return await _service.signIn();
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }
}
