import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Google ile hesap bağlama/giriş sonucu — bkz. [GoogleAuthService.signIn].
class GoogleSignInOutcome {
  const GoogleSignInOutcome({required this.uid, required this.email});

  /// Yeni oturumun (bağlanan/kurtarılan hesabın) Firebase uid'i —
  /// çağıran taraf bunu `switchToUid` sinyaline vermeli (bkz.
  /// `utils/auth_switch.dart` + `main.dart`).
  final String uid;
  final String? email;
}

/// [GoogleAuthService.linkCurrentUser] bu Google hesabının ZATEN başka bir
/// Firebase kullanıcısına bağlı/kayıtlı olduğunu tespit ederse fırlatılır
/// (Firebase'in kendi `credential-already-in-use`/`email-already-in-use`
/// hata kodları — bkz. `firebase_auth`'un `User.linkWithCredential`
/// dokümantasyonu: "You can recover from this error by signing in with
/// `credential` directly via `signInWithCredential`"). Arayüz bunu
/// yakalayıp kullanıcıya "o hesaba GEÇMEK ister misin?" diye sormalı (bkz.
/// `utils/google_link_action.dart`).
class GoogleAccountAlreadyLinkedElsewhereException implements Exception {
  const GoogleAccountAlreadyLinkedElsewhereException();
}

/// Google ile hesap bağlama/giriş işlemlerinin soyut arayüzü — `AdService`/
/// `SoundEffectsService` ile AYNI "gerçek implementasyon, testte enjekte
/// edilebilir sahte" deseni. Hem `google_sign_in` (native Credential
/// Manager/Sign In akışı) hem `firebase_auth`'un `linkWithCredential`/
/// `signInWithCredential` çağrıları platform kanalına/ağa dokunduğu için
/// `flutter_test`'te KULLANILAMAZ.
abstract class GoogleAuthService {
  const GoogleAuthService();

  /// Şu an oturum açık (genelde anonim) Firebase kullanıcısını Google
  /// hesabına BAĞLAR — AYNI uid korunur, TÜM mevcut veri (coin, hedefler,
  /// kostümler, her şey) `users/{uid}/...` altında kalmaya devam eder,
  /// KAYBOLMAZ. Başarılıysa bağlanan hesabın email'ini döner; kullanıcı
  /// akışı iptal ederse `null`. Bu Google hesabı ZATEN başka bir Firebase
  /// kullanıcısına bağlıysa [GoogleAccountAlreadyLinkedElsewhereException]
  /// fırlatır.
  Future<String?> linkCurrentUser();

  /// Google ile GİRİŞ YAPAR (mevcut anonim oturumun YERİNE geçer) — yeni
  /// bir cihazda, önceden Google'a bağlanmış eski bir hesabı KURTARMAK
  /// için. Başarılıysa yeni Firebase kullanıcısının uid + email bilgisini
  /// döner (bu Google hesabı daha önce hiç kullanılmadıysa TAMAMEN yeni,
  /// boş bir hesap oluşur); kullanıcı akışı iptal ederse `null`.
  Future<GoogleSignInOutcome?> signIn();

  /// Şu an oturum açık Firebase kullanıcısının Google sağlayıcısına bağlı
  /// olup OLMADIĞI.
  bool get isCurrentUserLinked;

  /// Bağlıysa Google hesabının email'i, değilse `null`.
  String? get linkedEmail;

  /// Firebase Auth oturumunu VE Google Sign-In eklentisinin kendi
  /// önbelleğini kapatıp YENİ bir anonim oturum açar — "Çıkış Yap" akışı
  /// (bkz. `utils/google_link_action.dart`'taki `handleSignOutTap`).
  /// Bilerek `linkCurrentUser`/`signIn` gibi `null` DÖNMÜYOR — çıkış
  /// yapıldıktan sonra uygulamanın HER ZAMAN geçerli (boş/taze) bir
  /// oturumla devam etmesi gerektiği için (bu, `main()`'in soğuk
  /// başlangıçta zaten yaptığı "kullanıcı yoksa anonim oluştur" adımının
  /// aynısı). Başarılıysa YENİ anonim kullanıcının uid'ini döner; çağıran
  /// taraf bunu `switchToUid` sinyaline verip TÜM uygulamanın taze bir
  /// başlangıç durumuyla yeniden kurulmasını tetiklemeli.
  Future<String?> signOut();
}

class FirebaseGoogleAuthService extends GoogleAuthService {
  FirebaseGoogleAuthService();

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;

  /// `GoogleSignIn.instance.initialize()` TAM OLARAK bir kez çağrılmalı ve
  /// başka HİÇBİR metottan önce tamamlanmalı (bkz. paketin kendi
  /// dokümantasyonu: "Clients must call this method exactly once... before
  /// calling any other methods"). Android'de `clientId`/`serverClientId`
  /// GEÇİLMİYOR — Credential Manager tabanlı akış bunu `google-services.
  /// json`'daki (uygulamanın paket adı + Firebase Console'a eklenen SHA-1
  /// parmak izine göre otomatik üretilen) OAuth istemci yapılandırmasından
  /// KENDİSİ okuyor.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize();
    _initialized = true;
  }

  /// Google ile etkileşimli giriş akışını başlatıp bir Firebase
  /// [fb_auth.AuthCredential]'ına çevirir. Kullanıcı akışı iptal ederse
  /// (geri tuşu, dışarı dokunma vb.) `GoogleSignInException(code: canceled)`
  /// fırlatılır — burada YAKALANIP `null` olarak normalize ediliyor ki
  /// [linkCurrentUser]/[signIn] çağıranları TEK bir "vazgeçme" sinyaliyle
  /// (`null` dönüş) uğraşsın, `GoogleSignInException`'ın kendi ayrıntılı
  /// hata kodu enum'uyla DEĞİL.
  ///
  /// **`_signIn.signOut()` ÖNCE çağrılır** — eklentinin kendi "şu an
  /// oturum açık kullanıcı" önbelleğini temizler ki `authenticate()` HER
  /// ZAMAN gerçek bir hesap seçici gösterisin, önceki çağrıdan kalan bir
  /// hesabı sessizce yeniden KULLANMASIN. Bu, "Hesap Değiştir" akışının
  /// (bkz. `AuthLinkProvider.signInWithGoogle`) güvenilir çalışması için
  /// GEREKLİ — aksi halde kullanıcı zaten bağlı bir hesaptan "hesap
  /// değiştirmek" istediğinde eklenti aynı hesabı hiç sormadan geri
  /// dönebilirdi. Bağlama (`linkCurrentUser`) akışını da AYNI şekilde
  /// (zararsızca) daha öngörülebilir hale getiriyor.
  Future<fb_auth.AuthCredential?> _authenticate() async {
    await _ensureInitialized();
    try {
      await _signIn.signOut();
    } catch (_) {
      // Önbellek zaten boşsa/eklenti bunu desteklemiyorsa sessizce devam —
      // asıl kritik olan aşağıdaki authenticate() çağrısı.
    }
    try {
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return null;
      return fb_auth.GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<String?> linkCurrentUser() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final credential = await _authenticate();
    if (credential == null) return null;
    try {
      final result = await user.linkWithCredential(credential);
      return result.user?.email;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        throw const GoogleAccountAlreadyLinkedElsewhereException();
      }
      rethrow;
    }
  }

  @override
  Future<GoogleSignInOutcome?> signIn() async {
    final credential = await _authenticate();
    if (credential == null) return null;
    final result = await fb_auth.FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = result.user;
    if (user == null) return null;
    return GoogleSignInOutcome(uid: user.uid, email: user.email);
  }

  /// **Güvenlik notu:** `AuthLinkProvider`'ın constructor'ı bu getter'ı
  /// SENKRON olarak (widget ağacı kurulurken) okuyor — `Firebase.
  /// initializeApp()` hiç çağrılmamışsa (ör. `flutter_test`, bkz.
  /// `AuthLinkProvider` dokümantasyonundaki "Kritik" notu) `FirebaseAuth.
  /// instance` SENKRON olarak `[core/no-app]` fırlatır. try/catch BURADA
  /// (yalnızca provider'ın kendi varsayılan-servis güvenliğine güvenmek
  /// yerine) İKİNCİ bir savunma katmanı — `main.dart` her zaman bu GERÇEK
  /// servisi kullandığı için, servisin KENDİSİ de Firebase'siz bir ortamda
  /// güvenle "bağlı değil" dönebilmeli.
  @override
  bool get isCurrentUserLinked {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      return user.providerData.any(
        (info) => info.providerId == fb_auth.GoogleAuthProvider.PROVIDER_ID,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  String? get linkedEmail {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      for (final info in user.providerData) {
        if (info.providerId == fb_auth.GoogleAuthProvider.PROVIDER_ID) {
          return info.email ?? user.email;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> signOut() async {
    try {
      await _ensureInitialized();
      await _signIn.signOut();
    } catch (_) {
      // Eklentinin kendi önbelleğini temizleyemesek bile Firebase Auth
      // tarafını kapatmaya/yeniden anonim oturum açmaya devam ediyoruz —
      // kritik olan Firebase oturumu, Google eklentisinin önbelleği
      // yalnızca "bir sonraki hesap seçicinin taze görünmesi" için.
    }
    await fb_auth.FirebaseAuth.instance.signOut();
    final result = await fb_auth.FirebaseAuth.instance.signInAnonymously();
    return result.user?.uid;
  }
}

/// Test/geliştirme için sahte implementasyon — HİÇBİR ZAMAN bağlı DEĞİL,
/// çağrılar no-op olarak `null` döner (diğer `Fake*Service` sınıflarıyla
/// AYNI desen).
class FakeGoogleAuthService extends GoogleAuthService {
  const FakeGoogleAuthService();

  @override
  Future<String?> linkCurrentUser() async => null;

  @override
  Future<GoogleSignInOutcome?> signIn() async => null;

  @override
  bool get isCurrentUserLinked => false;

  @override
  String? get linkedEmail => null;

  @override
  Future<String?> signOut() async => null;
}
