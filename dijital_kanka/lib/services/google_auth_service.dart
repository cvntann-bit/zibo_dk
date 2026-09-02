import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/local_account_data.dart';

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

/// **2026 bug düzeltmesi — gerçek kullanıcı raporu: hesap seçiyorum ama
/// hiçbir şey olmuyor.** `_authenticate()`'in `authenticate()` çağrısı
/// BAŞARIYLA bir hesap döndürüp `account.authentication.idToken`'ın `null`
/// geldiği (kullanıcının GERÇEKTEN vazgeçmesinden — `GoogleSignInException
/// (code: canceled)` — TAMAMEN FARKLI bir durum) anda fırlatılır. Canlı
/// `adb logcat` ile doğrulandı: hesap seçici tam olarak normal açılıp
/// kapanıyor (native taraf hatasız), ama Dart tarafında `debugPrint` dahil
/// HİÇBİR log satırı basılmıyordu — eski kod bu durumu SESSİZCE `null`'a
/// düşürüyor, bu da `linkWithGoogle()`'ın `false` dönüp `handleGoogleLinkTap`'in
/// hiçbir mesaj göstermeden çıkmasına yol açıyordu (kullanıcıya "buton
/// hiçbir şey yapmıyor" gibi görünüyordu — `GoogleSignInException`'ın TÜM
/// kodlarını sessizce yutan ÖNCEKİ bug'ın BİREBİR aynı sınıfı, bkz.
/// CLAUDE.md "Google Hesap Bağlama" bölümü). Artık `handleGoogleLinkTap`'in
/// genel `catch` bloğuna kadar fırlatılıp görünür bir hata mesajı gösteriyor
/// VE `debugPrint` ile logcat'e düşüyor — bir dahaki sefere bu durum tekrar
/// yaşanırsa kanıt hemen elde olacak.
/// **2026 bug düzeltmesi — canlı `adb logcat` ile KANITLANDI (bkz. CLAUDE.md
/// "Google Hesap Bağlama" bölümü):** `GoogleSignInException.code ==
/// GoogleSignInExceptionCode.canceled` HER ZAMAN kullanıcının BİLEREK
/// vazgeçmesi ANLAMINA GELMİYOR. Gerçek bir kullanıcı raporunda `description`
/// alanı `"[16] Account reauth failed."` çıktı — bu, Google'ın KENDİSİNİN
/// seçilen hesabı YENİDEN DOĞRULAYAMADIĞI (reauth) GERÇEK bir hata; eklenti
/// bu native durumu da (eski Google API'sindeki `CommonStatusCodes.
/// CANCELED = 16` ile aynı sayısal koda sahip olduğu için) AYNI `canceled`
/// koduna eşliyor. **Uygulama tarafında DÜZELTİLEMEZ** — hesabın/cihazın
/// Google Play Hizmetleri tarafındaki durumuyla ilgili bir sorun; kullanıcının
/// cihazında Google hesabını kaldırıp yeniden eklemesi, Google Play
/// Hizmetleri'ni güncellemesi/önbelleğini temizlemesi, veya (sorunun hesaba
/// mı cihaza mı özgü olduğunu ayırt etmek için) farklı bir Google hesabıyla
/// denemesi gerekebilir.
class GoogleSignInReauthFailedException implements Exception {
  const GoogleSignInReauthFailedException(this.description);

  final String description;

  @override
  String toString() => 'GoogleSignInReauthFailedException: $description';
}

class GoogleSignInMissingIdTokenException implements Exception {
  const GoogleSignInMissingIdTokenException();

  @override
  String toString() =>
      'GoogleSignInMissingIdTokenException: authenticate() bir hesap döndürdü '
      'ama idToken null geldi (kullanıcının vazgeçmesi DEĞİL — bkz. sınıf '
      'dokümantasyonu).';
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
      // Gerçek cihazda (Samsung/Credential Manager) bu çağrının nadiren
      // yanıt vermeden takılabildiği gözlemlendi — bir zaman aşımı ile
      // aşağıdaki authenticate() çağrısının HER ZAMAN denenmesini garanti
      // ediyoruz.
      await _signIn.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Önbellek zaten boşsa/eklenti bunu desteklemiyorsa sessizce devam —
      // asıl kritik olan aşağıdaki authenticate() çağrısı.
    }
    try {
      final account = await _signIn.authenticate().timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.interrupted,
          description: 'authenticate() timed out',
        ),
      );
      final idToken = account.authentication.idToken;
      // TANI AMAÇLI — authenticate()'in GERÇEKTEN bir hesapla başarıyla
      // döndüğünü VE idToken'ın olup olmadığını doğrulamak için.
      debugPrint(
        'GoogleAuthService._authenticate authenticate() OK: '
        'email=${account.email} idToken=${idToken == null ? 'NULL' : 'present (${idToken.length} chars)'}',
      );
      // `idToken == null` kullanıcının vazgeçmesi DEĞİL — bkz.
      // GoogleSignInMissingIdTokenException dokümantasyonu.
      if (idToken == null) throw const GoogleSignInMissingIdTokenException();
      return fb_auth.GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      // Yalnızca kullanıcının BİLEREK vazgeçmesi (geri tuşu/dışarı dokunma)
      // sessizce `null`'a düşer — diğer TÜM hata kodları (yapılandırma
      // hatası, kesinti, yukarıdaki zaman aşımı vb.) ÇAĞIRANA fırlatılıyor
      // ki arayüz görünür bir hata mesajı göstersin. **Önceki davranış
      // (HER `GoogleSignInException`'ı sessizce yutmak) gerçek bir hatayı
      // "buton hiçbir şey yapmıyor" gibi gösteriyordu — kullanıcı geri
      // bildirimiyle bulundu.**
      // TANI AMAÇLI — kullanıcı GERÇEKTEN bir hesap seçtiği halde `canceled`
      // kodunun dönüp dönmediğini doğrulamak için (bkz. CLAUDE.md "Google
      // Hesap Bağlama" bölümündeki en son not). Bu satır `canceled` DAHİL
      // HER koddan ÖNCE, sessizce yutulmadan ÖNCE çalışıyor.
      debugPrint(
        'GoogleAuthService._authenticate GoogleSignInException: '
        'code=${e.code} description=${e.description} details=${e.details}',
      );
      // `canceled` kodu her zaman GERÇEK bir kullanıcı vazgeçmesi DEĞİL —
      // bkz. GoogleSignInReauthFailedException dokümantasyonu.
      final description = e.description ?? '';
      if (description.toLowerCase().contains('reauth')) {
        throw GoogleSignInReauthFailedException(description);
      }
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<String?> linkCurrentUser() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final credential = await _authenticate();
    // TANI AMAÇLI — `_authenticate()`'in gerçekten `null` (sessiz vazgeçme)
    // döndüğünü mü, yoksa devam edip `linkWithCredential`'a mı ulaştığını
    // ayırt etmek için.
    debugPrint(
      'GoogleAuthService.linkCurrentUser: credential=${credential == null ? 'NULL (sessiz çıkış)' : 'present, linkWithCredential çağrılıyor'}',
    );
    if (credential == null) return null;
    try {
      final result = await user.linkWithCredential(credential);
      debugPrint(
        'GoogleAuthService.linkCurrentUser: linkWithCredential OK, email=${result.user?.email}',
      );
      return result.user?.email;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint(
        'GoogleAuthService.linkCurrentUser linkWithCredential FirebaseAuthException: '
        'code=${e.code} message=${e.message}',
      );
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
    // **2026 bug düzeltmesi — gerçek kullanıcı raporu: "çıkış yapınca
    // coinlerim/temalarım/kostümlerim/verilerim olduğu gibi kalıyor".**
    // Bkz. `local_account_data.dart`'ın tam dokümantasyonu — yeni anonim
    // uid'in Firestore belgesi GERÇEKTEN boş olsa bile, `CloudStateStore`'un
    // `uid`'den BAĞIMSIZ paylaşılan yerel önbelleği ESKİ hesabın verisini
    // bu YENİ hesaba "göç ettirip" sessizce geri getiriyordu — bu satır
    // olmadan "sıfır veriyle başlama" beklentisi TUTMUYORDU.
    await clearLocalAccountData();
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
