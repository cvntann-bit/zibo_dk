# 004 — Anonim auth + opsiyonel Google linking; uid değişimi `KeyedSubtree` ile

## Context
Kullanıcı hesabı olmadan başlamalı ama verisini (özellikle satın alınan coin) cihaz değişince
kurtarabilmeli. İsim/şifre YOK.

## Decision
- **Firebase Anonymous Auth** varsayılan — `main()`'de `currentUser == null` ise `signInAnonymously()`.
- **Google linking** isteğe bağlı: `GoogleAuthService.linkCurrentUser()` → `user.linkWithCredential(credential)`. Bu AYNI Firebase uid'ini KORUR — tüm mevcut veri (`users/{uid}/...`) dokunulmadan kalır.
- **Yeni cihazda kurtarma / hesap değiştir / çıkış**: `signInWithCredential` / `signInAnonymously` → uid DEĞİŞİR. Yeni uid `switchToUid` global `ValueNotifier`'a yazılır → `main.dart`'taki `_AppRoot` `KeyedSubtree(key: ValueKey(uid))`'in key'ini değiştirir → Flutter TÜM provider ağacını yeni uid ile SIFIRDAN kurar.

## Neden
- `linkWithCredential` (SESSİON KORUMA) vs `signInWithCredential` (SESSİON DEĞİŞTİRME) ayrımı bilinçli: "bağla" mevcut veriyi korur, "giriş yap/değiştir" kullanıcının bilerek farklı bir kimliğe geçtiği senaryodur.
- 40 provider'a elle "uid değişti, yeniden yükle" metodu eklemek yerine tek bir `KeyedSubtree` remount noktası — `RootScreen`'in `context.read` çağrıları asla eski uid'in provider'larına yanlışlıkla bağlanamaz.

## Sonuçlar / Kısıtlar
- **`AuthLinkProvider`/`GoogleAuthService`'in KENDİ varsayılanı `FakeGoogleAuthService`** (GERÇEK `FirebaseGoogleAuthService` DEĞİL) — `flutter_test` `Firebase.initializeApp()`'i çağırmadığı için gerçek servis constructor'da `[core/no-app]` fırlatıp `DijitalKankaApp` kuran HER testi çökertirdi. Yalnızca `main.dart` gerçek servisi verir. `FirebaseGoogleAuthService`'in getter'ları da ayrıca try/catch'li (ikinci güvenlik ağı).
- **"Çıkış Yap" `clearLocalAccountData()` çağırmak ZORUNDA** (bkz. `lib/utils/local_account_data.dart`) — yerel `SharedPreferences` anahtarları uid'e scope'lu değil; yoksa `CloudStateStore` migrasyon mantığı eski hesabın verisini yeni anonim oturuma miras bırakır. Cihaz/UI tercihleri (`isDarkMode`/`languageCode`/`soundEffectsState`) BİLEREK korunur (standart uygulama davranışı).
- **SAF anonim (hiç bağlanmamış) bir hesapta "çıkış yap" GÖSTERİLMEZ** — anonim kimlik taşınamaz, o hesaba bir daha giriş yapılamaz = geri dönüşsüz veri kaybı.
- **`_authenticate()` her çağrıda önce `_signIn.signOut()`** + 5sn/25sn timeout — v7 `google_sign_in` Credential Manager'ı tek hesap varsa otomatik seçebiliyor, "Hesap Değiştir"in gerçekten seçici göstermesi için önbellek temizlenmeli.
- `idToken == null` (başarılı auth ama token eksik) → `GoogleSignInMissingIdTokenException` fırlatılır (SESSİZCE `null` dönmez — kullanıcı "buton hiçbir şey yapmıyor" görmemeli). Yalnızca `GoogleSignInExceptionCode.canceled` sessiz kalır.
- **Play App Signing aktifken İKİ SHA sertifikası Firebase'e kayıtlı olmalı:** (1) upload/imzalama sertifikası (yerel `adb install` testleri), (2) Google'ın Play App Signing Key'i (Play Store'dan indiren gerçek kullanıcılar). İkincisini Play Console ekran görüntüsünden kopyalama — dağıtılan APK'yı `adb pull` edip `apksigner verify --print-certs` ile ÖLÇ.

## İlgili
`docs/history/backend-auth-security-referral.md` (uzun bug zinciri) · `docs/decisions/003`
