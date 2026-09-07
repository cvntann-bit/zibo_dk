# ARŞİV — Firestore/CloudStateStore, Güvenilir zaman, Google Hesap Bağlama, Coin Ekonomisi Güvenliği, Davet Et

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 5944–6827).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

## Firestore veri kalıcılığı, Anonymous Auth ve güvenilir zaman ([cloud_state_store.dart](lib/services/cloud_state_store.dart), [trusted_time_service.dart](lib/services/trusted_time_service.dart), [trusted_time_provider.dart](lib/providers/trusted_time_provider.dart))

- **Kullanıcı isteği:** Tüm kullanıcı verisi (coin bakiyesi, hedefler, günlük ödüller, su takibi,
  şükran/ruh hali/manifest günlükleri, kostüm/tema sahipliği, para&birikim kayıtları, rüya günlüğü,
  bildirim/dil/koyu-tema tercihleri — kullanıcının seçtiği EN KAPSAMLI kapsam) artık yalnızca
  cihazın yerel `SharedPreferences`'ında değil, `Firebase Anonymous Auth`'tan gelen bir `uid`'ye
  bağlı olarak Firestore'da da tutuluyor — isim/şifre YOK, cihaz otomatik bir kimlik alıyor. Ayrıca
  "bugün" artık cihaz saati yerine Firestore'un sunucu zaman damgasından türetiliyor (aşağıya
  bakın) — kullanıcı telefonun tarihini ileri alarak günlük ödülleri/streak'leri tekrar
  tetikleyemiyor.
- **`CloudStateStore` — tek, paylaşılan bir soyutlama.** Her provider'ın kendi `_loadFromPrefs`/
  `_save`'inin YERİNE geçen küçük bir yardımcı sınıf (`AdService`/`NotificationService` ile aynı
  "gerçek implementasyon, testte enjekte edilebilir" felsefesi, ama bir servis değil bir Map
  okuma/yazma sarmalayıcısı): `load()` önce Firestore'u (`users/{uid}/state/{prefsKey}`) dener,
  orada veri yoksa yereldeki (bu güncellemeden ÖNCEki) eski veriyi okuyup Firestore'a göç ettirir —
  kullanıcı mevcut ilerlemesini KAYBETMEDEN buluta geçer. `save()` HER ZAMAN önce yerele
  (`SharedPreferences`, AYNI eski anahtar/JSON biçimiyle) yazar, ardından (varsa) Firestore'a — yerel
  yazı hem çevrimdışı güvenlik ağı hem de Firestore'un kendisi (`uid == null`) veya testler için TEK
  gerçek kaynak.
  - **`uid` `null` ise (Firebase kullanılamıyor VEYA test ortamı) davranış TAMAMEN eskisiyle
    aynı** — saf `SharedPreferences`, Firestore'a hiç dokunulmaz. Her provider'ın constructor'ı
    `uid` parametresini OPSİYONEL alır ve HİÇBİR provider testi bunu vermez — bu yüzden ~150
    mevcut test hiçbir değişiklik gerektirmeden saf-yerel modda çalışmaya devam ediyor;
    `const DijitalKankaApp()` da (widget_test.dart'taki çoğu çağrı) değişmeden derleniyor.
  - **Test:** `test/cloud_state_store_test.dart` (`FakeFirebaseFirestore` ile: uid yoksa yerelde
    kalır, uid var+Firestore boş+yerelde eski veri var → göç eder, uid var+Firestore'da veri var →
    onu döner (yereli yok sayar), save() her ikisine de yazar, iki farklı uid birbirinden izole).
- **Üç migrasyon varyantı** (mevcut provider'ların eski kalıcılık biçimine göre):
  - **Varyant A — tek anahtarlı JSON blob (çoğunluk):** `CoinProvider`, `GoalsProvider`,
    `DailyRewardsProvider`, `WaterProvider`, `DreamJournalProvider`, `MoneyProvider` gibi zaten
    `{...}` biçiminde bir JSON map yazıyordu — mekanik swap: `prefs.getString`+`jsonDecode` yerine
    `_store.load()`, `prefs.setString`+`jsonEncode` yerine `_store.save({...})`. **Bu ilk
    migrasyondan SONRA eklenen provider'lar** (`ProfileProvider`/`profileState`,
    `FavoriteQuotesProvider`/`favoriteQuotes`, `OnboardingProvider`/`onboardingState` — bkz. ilgili
    bölümler) baştan bu desenle YAZILDI, ayrıca bir göç adımına hiç ihtiyaç duymadılar.
  - **Varyant A-türevi — düz JSON listesi (GratitudeProvider/MoodProvider/ManifestProvider):** Bu
    üçü `CloudStateStore`'dan ÖNCE anahtarları altında bir MAP değil düz bir JSON LİSTESİ
    (`[...]`) saklıyordu — `CloudStateStore` yalnızca `Map<String, dynamic>` okuyabildiği için
    (`_loadLocal`'daki `jsonDecode(saved) as Map<String, dynamic>` bir listede fırlatıp `null`
    döner), her birine `_loadLegacyRawList()` adında küçük bir yardımcı eklendi: `_store.load()`
    `null` dönerse bu ham listeyi doğrudan okuyup `{'entries': [...]}` biçiminde sarıp
    `_store.save()` ile göç ettiriyor.
  - **Varyant B — iki-anahtarlı eski format → tek Firestore doküman:** `CostumeProvider`
    (`ownedCostumeIds`+`equippedCostumeId` → `costumeState`), `AppThemeProvider`
    (`ownedAppThemeIds`+`equippedAppThemeId` → `appThemeState`), `NotificationProvider`
    (`notificationFrequency`+`notificationTimes` → `notificationState`). `_store.load()` yeni
    birleşik anahtarda veri bulamazsa provider İÇİNDE eski iki anahtar okunup birleştirilir ve
    `_store.save(...)` ile hem yeni yerel biçime hem Firestore'a yazılır — `WaterProvider`'ın
    zaten sahip olduğu "eski format tanıma" deseninin (bkz. "Su Takibi" bölümü) aynısı.
  - **Varyant C — tek skaler değer:** `ThemeProvider` (`isDarkMode`, bool), `LocaleProvider`
    (`languageCode`, String) eskiden `prefs.setBool`/`prefs.setString` ile HAM (JSON olmayan)
    değer yazıyordu — `CloudStateStore` yalnızca JSON map okuduğu için bu da `_loadLocal`'da
    sessizce `null`'a düşer (bkz. altta); değer `{'value': ...}` tek-alanlı bir map'e sarılıp
    açılıyor, eski ham değer `_loadLegacyBool`/`_loadLegacyString` ile ayrıca okunup göç ettiriliyor.
  - **Gotcha — `CloudStateStore._loadLocal`, `prefs.getString(prefsKey)` OKUMASININ KENDİSİNİ de
    try/catch içine almalı:** Varyant C'de eski değer `setBool`/`setString` (ham) ile yazılmıştı;
    aynı anahtarı `getString` ile okumaya çalışmak (`shared_preferences` paketinin tip kontrolü
    yüzünden) `TypeError` FIRLATIR, `null` DÖNMEZ — yalnızca `jsonDecode`'u saran bir try/catch
    yeterli değildi, `prefs.getString(...)` çağrısının kendisi de try bloğunun İÇİNE alınmalıydı.
    Bu, `flutter test`'te gerçek bir çökme olarak yakalandı (`type 'String' is not a subtype of
    type 'bool?'`) ve düzeltildi.
- **Anonymous Auth (`main.dart`):** `main()` içinde `Firebase.initializeApp()` sonrası
  `FirebaseAuth.instance.currentUser` kontrol edilir; `null` ise `signInAnonymously()` ile yeni bir
  kimlik oluşturulur — Firebase Auth SDK'sı bunu kendi yerel deposunda kalıcı tuttuğu için sonraki
  açılışlarda AYNI `uid` korunur. `uid`, `DijitalKankaApp(uid: uid)` üzerinden düz bir `String?`
  olarak (reaktif bir provider DEĞİL — oturum boyunca değişmiyor) `TrustedTimeProvider` HARİÇ
  TÜM 17 provider'ın `create:` callback'ine geçiriliyor (bkz. "Mimari özet" bölümündeki güncel
  18 provider listesi).
- **Güvenilir zaman artık Firestore sunucu zaman damgasını da deniyor:**
  `FirestoreTrustedTimeService` paylaşılan bir `_serverTime/ping` belgesine
  `FieldValue.serverTimestamp()` ile yazıp hemen SUNUCUDAN (`Source.server`, yerel önbellekten
  DEĞİL) geri okuyor — belge içeriği önemsiz, yalnızca sunucunun atadığı zaman damgası önemli.
  `TrustedTimeProvider` artık `uid` alıyor: `uid != null` iken YENİ `CompositeTrustedTimeService
  ([FirestoreTrustedTimeService(), HttpDateTrustedTimeService()])` (önce Firestore, o başarısız
  olursa — ör. henüz kural/ağ hazır değilse — HTTP `Date` başlığına düşer), `uid == null` iken
  hâlâ yalnızca `HttpDateTrustedTimeService()` (önceki davranışla birebir aynı, regresyon yok).
  `TrustedTimeProvider`'ın geri kalan TÜM mantığı (monotonik taban, cooldown,
  `WidgetsBindingObserver`) DEĞİŞMEDİ — yalnızca `now()`'ın beslendiği ağ kaynağı değişti.
- **Bulunan gerçek bug — `now()`'ın "taban" mantığı yalnızca GERİYE alınan saate karşı
  koruyordu, İLERİYE alınana karşı hiç işe yaramıyordu:** Bu Firestore migrasyonu gerçek
  cihazda test edilirken kullanıcı tarihi ileri aldığında Günlük Giriş Ödülleri'nin VE
  Şükran Günlüğü/Su Takibi gibi diğer "güne bağlı" ödüllerin hâlâ tekrar tetiklenebildiğini
  bildirdi — yani bu özelliğin ASIL var oluş sebebi olan güvenlik açığı bir önceki oturumdan
  beri hiç kapanmamıştı. Kök neden: eski `now()` "cihaz saati taban değerden ileriyse cihaz
  saatini kabul et" diyordu — kullanıcı saati ileri aldığında `deviceUtc` HER ZAMAN tabanın
  "ilerisinde" sayılıp doğrudan kabul ediliyordu (yalnızca cihaz saati GERİYE alındığında
  taban devreye giriyordu). **Düzeltme:** bir doğrulama (`_lastVerifiedUtc`) varsa `now()`
  ARTIK cihaz saatine HİÇ bakmıyor, yalnızca `verified.add(_stopwatch.elapsed)` kullanıyor —
  `Stopwatch` donanım saatine dayalı olduğu için cihazın TARİH ayarından bağımsız kalıyor,
  ileri/geri alınsın fark etmez. Cihaz saati yalnızca İLK doğrulama tamamlanmadan önceki çok
  kısa "bootstrap" penceresinde geçici olarak okunuyor. Gerçek cihazda tekrar test edildi:
  tarih 2-3 gün ileri alınıp uygulama yeniden açıldığında (internet açıkken) artık hiçbir
  ödül tekrar tetiklenmiyor. **Ders:** bu tür "taban/floor" karşılaştırmalarında hangi
  yöndeki sapmaya karşı korunmak istendiği açıkça düşünülmeli — "büyük olanı kabul et" gibi
  simetrik bir kural, yalnızca TEK yöndeki saldırıya karşı korumak isteniyorsa yanlış
  sonuç verir.
- **[firestore.rules](firestore.rules)** — proje kökünde: `users/{uid}/**` yalnızca
  `request.auth.uid == uid` eşleşen istekler tarafından okunup yazılabilir; `_serverTime/{document}`
  kimliği doğrulanmış HERHANGİ bir kullanıcı tarafından okunup yazılabilir (ping mekanizması için).
  **Bu dosya otomatik deploy EDİLMEZ** (bu ortamda Firebase CLI/login yok) — kullanıcının Firebase
  Console > Firestore Database > Rules sekmesine yapıştırıp yayınlaması gerekiyor.
- **Kullanıcının YAPMASI gereken Firebase Console ön koşulları** (asistan yapamaz — konsol erişimi
  gerektiriyor):
  1. Firestore Database'i oluştur: Console > Firestore Database > "Create database" (production mode).
  2. Anonymous Auth'u aç: Console > Authentication > Sign-in method > Anonymous > Enable.
  3. Yukarıdaki `firestore.rules` içeriğini Console > Firestore Database > Rules'a yapıştırıp yayınla.
- **Test etme adımları (kullanıcı için):**
  1. Mevcut sürümde bir ekran görüntüsü al (coin bakiyesi, hedef ilerlemesi vb.).
  2. Yeni APK'yı kur, aç → AYNI değerler görünmeli (yerelden Firestore'a göç kanıtı).
  3. Firebase Console > Authentication'da BİR anonim kullanıcı belirmeli.
  4. Firebase Console > Firestore Database'de `users/{uid}/state/...` altında `coinState`, `goals`,
     `dailyRewards` vb. dokümanlar, uygulamadaki değerlerle eşleşen verilerle görünmeli.
  5. **Asıl güvenlik testi:** Günlük Giriş Ödülleri'nden bugünü al → telefonun tarihini 2-3 gün
     ileri al (gerçek zaman GEÇMEDEN) → popup'ı tekrar aç → HÂLÂ "bugün aldın, yarın gel" demeli
     (yeni bir gün AÇILMAMALI). Tarihi geri al.
  6. **Offline testi:** Uçak modunu aç, uygulamayı aç → önceki veriler (Firestore'un kendi yerel
     önbelleği + bizim `SharedPreferences` yedeğimiz sayesinde) görünmeye devam etmeli.

## Google Hesap Bağlama ([google_auth_service.dart](lib/services/google_auth_service.dart), [auth_link_provider.dart](lib/providers/auth_link_provider.dart), [auth_switch.dart](lib/utils/auth_switch.dart), [google_link_action.dart](lib/utils/google_link_action.dart), [google_link_promo_sheet.dart](lib/widgets/google_link_promo_sheet.dart))

- **2026 yeni özellik.** Kullanıcı isteği: Anonymous Auth'a dayalı kullanıcı verisi (özellikle
  satın alınan Zibo Coin'ler) cihaz değişikliğinde/uygulama silinip yeniden kurulduğunda kaybolmasın
  diye, kullanıcı isteğe bağlı olarak anonim hesabını bir Google hesabına BAĞLAYABİLSİN — sonra yeni
  bir cihazda aynı Google hesabıyla GİRİŞ YAPIP eski verisini kurtarabilsin. Dört parça: (1) Firebase
  Authentication'a Google Sign-In sağlayıcısı, (2) Profil + Ayarlar'da bir "Google ile Bağla" satırı,
  (3) Mağaza'da İLK gerçek coin satın alma denemesinde gösterilen (zorunlu OLMAYAN) bir teşvik
  sheet'i, (4) yeni cihazda "Google ile Giriş Yap" ile eski hesabı kurtarma.
- **`google_sign_in: ^7.0.0`** (`flutter pub get` ile `7.2.0`'a çözüldü) — bu sürüm paketin
  Credential Manager tabanlı, TAMAMEN yeniden yazılmış v7 API'si (eski `signIn()`/`signInSilently()`
  metotları YOK). Singleton `GoogleSignIn.instance`, kullanılmadan ÖNCE `await GoogleSignIn.instance.
  initialize()`'ın TAM OLARAK bir kez tamamlanmış olması ŞART (paketin kendi dokümantasyonu).
  `authenticate()` `null` DÖNMEZ — başarısız/iptal olursa `GoogleSignInException` (kod
  `GoogleSignInExceptionCode.canceled` dahil) FIRLATIR. `idToken` (nullable `String?`,
  `account.authentication.idToken`) — temel akışta expose edilen TEK token, ayrı bir
  `authorizeScopes()` çağrısı GEREKMEDİ (uygulama Google'dan yalnızca kimlik doğrulaması istiyor,
  ekstra bir Google API kapsamı değil).
- **`GoogleAuthService`** (`AdService`/`NotificationService` ile AYNI "gerçek + fake, testte
  enjekte edilebilir" desen — hem `google_sign_in` hem `firebase_auth`'un `link`/`signInWith`
  çağrıları platform kanalına/ağa dokunduğu için `flutter_test`'te KULLANILAMAZ):
  - `linkCurrentUser()` — şu an oturum açık (genelde anonim) kullanıcıyı Google hesabına
    **`user.linkWithCredential(credential)`** ile bağlar — bu, AYNI Firebase uid'ini KORUR, tüm
    mevcut veri (`users/{uid}/...` altında) hiç dokunulmadan kalır. `signInWithCredential`'DAN
    (ki bu SESSİON'U DEĞİŞTİRİR, farklı bir uid'e geçebilir) BİLEREK FARKLI — "bağlama" akışının
    kullanıcının MEVCUT verisini KORUMASI gerektiği için doğru API budur.
  - Bu Google hesabı ZATEN başka bir Firebase kullanıcısına bağlıysa (`credential-already-in-use`/
    `email-already-in-use` Firebase hata kodları) `GoogleAccountAlreadyLinkedElsewhereException`
    fırlatılır — Firebase'in kendi dokümantasyonu buradan kurtarmanın yolunun `signInWithCredential`
    ile O HESABA GEÇMEK olduğunu söylüyor; arayüz bunu yakalayıp kullanıcıya sorar (bkz. altta
    `handleGoogleLinkTap`).
  - `signIn()` — Google ile GİRİŞ yapar (mevcut anonim oturumun YERİNE geçer,
    `FirebaseAuth.instance.signInWithCredential`) — yeni bir cihazda önceden bağlanmış bir hesabı
    KURTARMAK için. Bu Google hesabı daha önce HİÇ kullanılmadıysa tamamen yeni/boş bir Firebase
    kullanıcısı oluşur (kullanıcının "önceden bağlıydıysa" beklentisiyle tutarlı — bağlı DEĞİLSE
    zaten kurtarılacak bir şey yok).
  - `isCurrentUserLinked`/`linkedEmail` — SENKRON getter'lar, `FirebaseAuth.instance.currentUser.
    providerData`'da `google.com` sağlayıcısını arıyor.
  - `FirebaseGoogleAuthService` gerçek implementasyon; `FakeGoogleAuthService` (const, HER ZAMAN
    "bağlı değil", tüm çağrılar no-op) test/güvenli-varsayılan implementasyonu.
- **`AuthLinkProvider` — KRİTİK güvenlik deseni, `CoinProvider`'ın `adService` varsayılanıyla
  BİREBİR AYNI mantık.** Constructor'ın `googleAuthService` parametresi verilMEZse varsayılan
  **`FakeGoogleAuthService`** (GERÇEK `FirebaseGoogleAuthService` DEĞİL). **Neden kritik:**
  `flutter_test` `Firebase.initializeApp()`'i HİÇ çağırmıyor — eğer varsayılan gerçek servis
  olsaydı, `AuthLinkProvider`'ın constructor'ı `_refreshLinkStatus()` içinde SENKRON olarak
  `FirebaseAuth.instance.currentUser`'ı okuyup `[core/no-app]` fırlatır, `DijitalKankaApp` kuran
  HER TEK test ANINDA çökerdi. Üç katmanlı savunma: (1) `AuthLinkProvider`'ın KENDİ varsayılanı
  `FakeGoogleAuthService`; (2) `main.dart`'ın `DijitalKankaApp.build()`'i yalnızca ÜRETİMDE açıkça
  `FirebaseGoogleAuthService()` veriyor (`CoinProvider`/`AdMobAdService` ile AYNI "sağlam varsayılan,
  kompozisyon kökünde override" deseni); (3) `FirebaseGoogleAuthService.isCurrentUserLinked`/
  `linkedEmail` getter'ları KENDİLERİ de try/catch'e sarılı (ikinci güvenlik ağı — `main.dart`'ın
  gerçek servisi HER ZAMAN kullanması yüzünden, servisin kendisi de Firebase'siz bir ortamda güvenle
  "bağlı değil" dönebilmeli).
  - `isLinked`/`linkedEmail` Firebase Auth'un KENDİSİNDEN canlı okunuyor (ayrı bir yerel kopya
    TUTULMUYOR — Firebase Auth zaten tek gerçek kaynak).
  - `hasSeenLinkPrompt` (bool) — Mağaza'daki ilk-satın-alma teşvik sheet'inin BİR KEZ (kabul
    edilsin ya da "Şimdilik Atla" densin FARK ETMEZ) gösterilip gösterilmediği —
    `CloudStateStore(prefsKey: 'googleLinkPromptState', uid: uid)` ile `ThemeProvider.isDarkMode`
    ile AYNI Varyant C ("tek skaler değer, `{'value': ...}` sarmalı") deseninde kalıcı.
  - `linkWithGoogle()`/`signInWithGoogle()` — `isLinking` bool'unu (arayüzün bir yükleniyor
    göstergesi için izleyebileceği) yönetiyor, ikisi de `GoogleAuthService`'e ince bir sarmalayıcı.
- **`main.dart`'a bağlama:** `AuthLinkProvider`, `MultiProvider` listesinde `TrustedTimeProvider`'dan
  HEMEN SONRA (diğer HİÇBİR provider ona `create:` callback'inden bağımlı olmadığı için konumu
  esnek, ama erken tutuldu) `AuthLinkProvider(uid: uid, googleAuthService: FirebaseGoogleAuthService())`
  ile ekleniyor.
- **Uid-değiştirme mekanizması — yeni cihazda "Google ile Giriş Yap" TÜM uygulamayı yeni bir uid'le
  yeniden kurmalı.** Kullanıcı `signInWithGoogle()` çağırdığında dönen `GoogleSignInOutcome.uid`
  eski (mevcut cihazın anonim) uid'den FARKLI bir Firebase kullanıcısı olabilir — bu durumda TÜM
  `MultiProvider` ağacının (coin/hedefler/kostümler/vb. HEPSİ `uid`'e göre `CloudStateStore`
  kuruyor) yeni uid ile SIFIRDAN kurulması gerekiyor, tek bir provider'ın state'ini değiştirmek
  yetmez.
  - **`lib/utils/auth_switch.dart`** — `final ValueNotifier<String?> switchToUid = ValueNotifier
    <String?>(null);` — `homeTabRequest`/`isHomeTabActive` ile AYNI "basit paylaşılan global sinyal"
    deseni (widget ağacının dışından da yazılabilmesi gerekiyor, `AuthLinkProvider`/
    `GoogleAuthService` bir widget değil).
  - **`main.dart`'ta YENİ `_AppRoot` (StatefulWidget)`** — `runApp(DijitalKankaApp(uid: uid))`
    yerine artık `runApp(_AppRoot(initialUid: uid))` çağrılıyor. `_AppRoot.build()`:
    ```dart
    return KeyedSubtree(key: ValueKey(_uid), child: DijitalKankaApp(uid: _uid));
    ```
    `initState`'te `switchToUid.addListener(...)` ile dinliyor; sinyal `null`-olmayan bir değere
    değişince `setState(() => _uid = newUid)` yapıyor. **`KeyedSubtree`'nin DEĞİŞEN `Key`'i** —
    projede zaten `ProfileScreen`'in "İstatistiklerim" bölümünün sekmeye HER girişte yeniden
    animasyonlanması için kullanılan AYNI teknik (bkz. "Profil" bölümündeki `_statsReplayKey`
    notu) — burada TEPEDE uygulanıyor: Flutter, `Key` değişince TÜM alt ağacı (dolayısıyla
    `DijitalKankaApp`'in kurduğu HER provider'ı) söküp SIFIRDAN yeniden kuruyor, yeni `uid` ile.
    Bu, "yeni cihazda Google ile giriş yapınca eski hesabın TÜM verisi (coin, hedefler, kostümler)
    görünsün" isteğini TEK bir mekanizmayla karşılıyor — 19 provider'ın hiçbirine elle bir
    "uid değişti, yeniden yükle" metodu eklemeye GEREK KALMADI.
  - **`lib/utils/google_link_action.dart`'taki `handleGoogleLinkTap(context)`** (Profil VE
    Ayarlar'daki satırların PAYLAŞTIĞI ortak handler) — `linkWithGoogle()`'ı çağırır; eğer
    `GoogleAccountAlreadyLinkedElsewhereException` fırlatılırsa (bu Google hesabı zaten BAŞKA bir
    Firebase kullanıcısına bağlıysa) bir `AlertDialog` ile kullanıcıya "bu hesap zaten bağlı, o
    hesaba GEÇMEK ister misin?" diye sorar — onaylanırsa `signInWithGoogle()` çağrılıp dönen
    `outcome.uid`, `switchToUid.value`'ya yazılır (yukarıdaki mekanizmayı tetikler).
- **UI giriş noktaları — Profil VE Ayarlar'da AYNI satır, İKİ AYRI konumdan erişilebilir olsun diye
  bilerek TEKRARLANDI** (kullanıcı isteği "Profil sayfasına VE ayarlar kısmına" — TEK bir yere değil):
  - **`profile_screen.dart`** — "Zibo ile Bağın" listesinin SEKİZİNCİ (son) satırı, "Profil Kartını
    Paylaş"ın hemen ardından. Diğer 7 satırla AYNI `_ProfileLinkRow` görsel dili (ikon + başlık +
    canlı alt metin + sağ ok), ama `onTap` yeni bir sayfa PUSH ETMİYOR — doğrudan
    `handleGoogleLinkTap(context)` çağırıyor (diyalog/SnackBar geri bildirimini kendisi yönetiyor).
    İkon/başlık/alt metin `authLink.isLinked`'e göre koşullu: bağlı değilse `Icons.link_rounded` +
    "Google ile Bağla" + genel teşvik metni; bağlıysa `Icons.verified_user_rounded` + "Google Hesabın
    Bağlı" (`googleLinkRowTitleLinked`) + bağlı e-posta.
  - **`settings_screen.dart`** — "Genel" kartına, Dil satırının hemen ardına (bir `Divider`'la
    ayrılmış) DÖRDÜNCÜ bir `ListTile` — AYNI koşullu ikon/başlık/alt metin, AYNI
    `handleGoogleLinkTap(context)` çağrısı.
- **Mağaza'daki ilk-satın-alma teşvik sheet'i (`google_link_promo_sheet.dart`)** —
  `store_screen.dart`'ın `_PackageCardState._buy(BuildContext context)`'i, GERÇEK satın alma
  çağrısından (`purchaseCoinPackage`) ÖNCE `!authLink.isLinked && !authLink.hasSeenLinkPrompt`
  kontrolü yapıyor; ikisi de doğruysa ÖNCE `markLinkPromptSeen()` (bir daha hiç gösterilmesin),
  SONRA `showGoogleLinkPromoSheet(context)` — `ad_free_promo_sheet.dart` ile AYNI
  `showModalBottomSheet` deseni. **Kullanıcının açık isteği "zorunlu tutma, güçlü şekilde teşvik
  et"** — sheet "Şimdilik Atla" (`Key('googleLinkPromoSkipButton')`) ile HER ZAMAN atlanabilir,
  dışarı dokunma/sürükleme tutamacıyla da kapanabilir; sheet HANGİ yolla kapanırsa kapansın
  (bağlandı/atlandı/iptal), asıl satın alma akışı sheet kapandıktan SONRA NORMAL ŞEKİLDE devam
  ediyor — satın alma sheet'in sonucuna hiç bağlı değil. "Google ile Bağla" butonuna
  (`Key('googleLinkPromoLinkButton')`) basınca sheet kapanıp `handleGoogleLinkTap(context)`
  çağrılıyor (Profil/Ayarlar'daki satırla AYNI handler, aynı "zaten başka hesaba bağlı" akışı dahil).
- **ARB — 13 yeni anahtar (TR/EN/ES), `onboardingClosingMessage`'dan hemen sonra:**
  `googleLinkRowTitleUnlinked`, `googleLinkRowTitleLinked`, `googleLinkRowSubtitle`,
  `googleLinkSuccessMessage`, `googleLinkFailedMessage`, `googleAlreadyLinkedDialogTitle`,
  `googleAlreadyLinkedDialogBody`, `googleSignInInsteadButton`, `googleSignInSuccessMessage`,
  `googleSignInFailedMessage`, `googleLinkPromoTitle`, `googleLinkPromoBody`,
  `googleLinkPromoSkipButton`. `flutter gen-l10n` çalıştırıldı.
- **Test:** `profile_screen_test.dart`/`widget_test.dart`'ın `_buildAppWithClock()` yardımcı
  fonksiyonlarına `AuthLinkProvider` eklendi (`RootScreen`'in ihtiyaç duyduğu HER provider kuralı,
  bkz. "Test kalıpları" bölümü — `ProfileScreen`/`SettingsScreen` artık `context.watch<
  AuthLinkProvider>()` çağırdığı için eklenmezse `ProviderNotFoundException` o testten SONRAKİ
  TÜM testleri kademeli olarak kırar). Mağaza'daki İLK coin paketi satın alma testi
  (`widget_test.dart`, "Mağazadan paket satın alınca bakiye artar") artık yeni teşvik sheet'ini
  `Key('googleLinkPromoSkipButton')` ile atlayıp SONRA satın alma başarısını doğruluyor — sheet
  taze bir `AuthLinkProvider`'ın (bağlı değil, `hasSeenLinkPrompt: false`) İLK satın alma denemesini
  YAKALADIĞI için bu adım gerekli, aksi halde satın alma akışı sheet açıkken beklemede kalıp
  başarı SnackBar'ı hiç görünmüyordu. `flutter test` tam yeşil: **262/262.**
- **Kullanıcının YAPMASI gereken Firebase Console ön koşulları** (asistan yapamaz — konsol erişimi
  gerektiriyor):
  1. **Google sağlayıcısını aç:** Firebase Console > Authentication > Sign-in method > Google >
     Enable (bir destek e-postası seçmen istenecek).
  2. **SHA-1/SHA-256 parmak izini ekle:** Firebase Console > Project settings > (uygulamanın
     Android girdisi) > "Add fingerprint". `google_sign_in`'in Credential Manager tabanlı akışı
     Android'de bu parmak izine göre `google-services.json`'a otomatik gömülen bir OAuth istemci
     yapılandırmasına dayanıyor — parmak izi eklenmeden Google ile bağlama/giriş SESSİZCE
     başarısız olur (kullanıcıya `null`/iptal olarak görünür, gerçek bir hata mesajı gelmez).
     Bu makinedeki **DEBUG** anahtarın (yalnızca `flutter run`/`flutter build apk --debug` ile
     üretilen APK'lar için geçerli) parmak izleri:
     - SHA-1: `AD:E5:CB:35:ED:DF:E0:C0:EE:44:25:2A:A8:C1:50:5D:7E:81:55:5B`
     - SHA-256: `30:36:63:CF:68:C7:81:F5:3D:CE:A3:90:DA:F0:21:30:42:A1:BE:47:E0:31:36:B5:56:77:7A:3E:35:65:71:F6`
     (`keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey
     -storepass android -keypass android` ile yeniden üretilebilir — DEĞİŞMEZ, aynı makinede her
     zaman aynı çıkar.) **Release (Play Store'a yüklenecek) bir APK/AAB için AYRI bir release
     keystore'un KENDİ parmak izini de EKLEMEK gerekecek** — bu adım henüz yapılmadı, release
     imzalama süreci kurulunca (ayrı bir görev) tekrar ele alınmalı.
  3. **`google-services.json`'ı yeniden indir (parmak izi eklendikten SONRA)** ve
     `android/app/google-services.json`'ın ÜZERİNE yaz — parmak izi eklemek dosyanın içeriğini
     (OAuth istemci bilgisini) değiştiriyor, eski dosyayla devam etmek bağlamayı yine sessizce
     başarısız kılar.
- **Kullanıcının kendi cihazında doğrulaması gereken adımlar (asistan gerçek Google hesap
  kimlik doğrulamasını KENDİ ADINA YAPAMAZ — hesap seçme/parola/2FA ekranları kullanıcının kendi
  etkileşimini gerektiriyor):**
  1. Yukarıdaki üç Firebase Console adımını tamamla.
  2. Uygulamayı aç, Profil (veya Ayarlar) > "Google ile Bağla"ya dokun → Google hesap seçici
     açılmalı → bir hesap seç → satır "Google Hesabın Bağlı — {email}" olarak güncellenmeli.
  3. Firebase Console > Authentication'da o kullanıcının artık `Anonymous` DEĞİL, hem anonim hem
     `Google` sağlayıcısını (bağlı, aynı uid) gösterdiğini doğrula.
  4. Mağaza'dan (henüz hesap bağlanmamış TAZE bir kurulumda) bir coin paketi satın almayı dene →
     bağlama teşvik sheet'i açılmalı, "Şimdilik Atla" ile satın alma normal devam etmeli; sheet'i
     tekrar tetiklemek için Mağaza'ya İKİNCİ kez girip satın almayı denemeli — bu sefer sheet
     GÖRÜNMEMELİ (`hasSeenLinkPrompt` artık `true`).
  5. **Asıl kurtarma testi:** Bağlanmış hesapla bir miktar coin/kostüm/hedef biriktir → uygulamayı
     TAMAMEN kaldır → yeniden kur (veya ikinci bir cihaz kullan) → ilk açılışta Onboarding'i geç →
     Profil/Ayarlar'dan "Google ile Giriş Yap"a dokun (henüz bağlı olmayan taze bir anonim hesapta
     bu seçenek `handleGoogleLinkTap` yerine `signInWithGoogle` akışını mı yoksa aynı satırı mı
     kullanacağı — bkz. altta "bilinen sınırlama" — netleştirilmeli) → AYNI Google hesabını seç →
     uygulama TÜM eski veriyle (coin bakiyesi, kostümler, hedefler) yeniden açılmalı.
- **Eski "bilinen sınırlama" notu — 2026 İKİNCİ güncellemeyle ÇÖZÜLDÜ (bkz. hemen altta):** Bu
  bölümün önceki hâli, "her zaman görünen, açık bir 'Google ile Giriş Yap' girişi yok, yalnızca
  dolaylı yoldan (bağlamayı dene → zaten bağlı → geç?) erişilebiliyor" diye not düşmüştü.
  Kullanıcının bu turda istediği "Hesap Değiştir" butonu TAM OLARAK bu boşluğu dolduruyor — artık
  HER ZAMAN görünen, doğrudan `signInWithGoogle()`'ı tetikleyen bir giriş noktası var.
- **2026 İKİNCİ güncelleme — Ayarlar'a Google logosu + "Çıkış Yap"/"Hesap Değiştir" butonları.**
  Kullanıcı isteği (verbatim özet): (1) bağlı hesabın yanında `assets/images/Google__G__logo.svg`
  ikonu görünsün, (2) "Çıkış Yap" ve "Hesap Değiştir" butonları eklensin, (3) Çıkış Yap onay
  diyaloğundan sonra Firebase Auth oturumunu kapatıp kullanıcıyı Google giriş ekranına
  yönlendirsin, uygulama arayüzü başlangıç haline dönsün, aynı hesapla tekrar girişte veri geri
  gelsin, (4) Hesap Değiştir doğrudan Google hesap seçiciyi açsın — yeni hesap boş profil, eski
  hesap kayıtlı verisiyle açılsın, (5) linkWithCredential mantığı korunsun (veri kaybı yok), (6)
  işlemler sırasında kısa bir yükleniyor göstergesi.
  - **`flutter_svg: ^2.2.1`** (`2.3.0`'a çözüldü) eklendi — `Image.asset` SVG render EDEMEZ,
    `assets/images/` glob'u zaten SVG'yi de kapsıyordu (yalnızca PNG'ler için değil), ek bir
    pubspec `assets:` girdisi GEREKMEDİ.
  - **`settings_screen.dart`'taki Google ListTile'ının `leading`'i artık KOŞULLU:** bağlıyken
    `SvgPicture.asset('assets/images/Google__G__logo.svg')`, bağlı DEĞİLKEN eskisi gibi
    `Icons.link_rounded` — logo YALNIZCA gerçekten bağlı bir hesabı temsil etsin diye.
  - **"Çıkış Yap"/"Hesap Değiştir" butonları BİLEREK YALNIZCA `authLink.isLinked` iken
    gösteriliyor** — SAF anonim (hiç bağlanmamış) bir hesapta "çıkış yapmak" GERİ DÖNÜŞSÜZ veri
    kaybı olurdu: anonim kimlik bilgileri taşınabilir/tekrar kullanılabilir DEĞİL, bu yüzden o
    hesaba bir daha ASLA giriş yapılamaz. Bu, kullanıcının isteğinde AÇIKÇA belirtilmemişti ama
    veri kaybını önlemek için gerekli bir güvenlik kısıtlaması olarak eklendi.
  - **Yalnızca Ayarlar'a eklendi, Profil'e EKLENMEDİ** — kullanıcının isteği kelimesi kelimesine
    "Ayarlar sayfasındaki Google hesabı bölümüne" diyordu; Profil'deki "Zibo ile Bağın" satırı
    HİÇ değişmedi (hâlâ yalnızca `handleGoogleLinkTap`, tek satır, buton yok) — bilinçli bir
    asimetri, kullanıcı isterse aynı butonlar Profil'e de eklenebilir.
  - **`GoogleAuthService`'e YENİ `Future<String?> signOut()` eklendi** — `linkCurrentUser()`/
    `signIn()`'in aksine `null` DÖNMÜYOR: Firebase Auth'u kapatıp HEMEN ardından
    `FirebaseAuth.instance.signInAnonymously()` ile TAZE bir anonim oturum açıyor ve o oturumun
    uid'ini dönüyor — "çıkış yaptıktan sonra uygulama HER ZAMAN geçerli bir oturumla devam
    etmeli" gerekçesiyle (`main()`'in soğuk başlangıçta zaten yaptığı "kullanıcı yoksa anonim
    oluştur" adımının BİREBİR aynısı). `FakeGoogleAuthService.signOut()` no-op, `null` döner.
  - **KRİTİK teknik keşif — `_authenticate()` artık `authenticate()`'ten ÖNCE `_signIn.
    signOut()` çağırıyor.** `google_sign_in` v7'nin (Credential Manager tabanlı) `GoogleSignIn.
    instance.authenticate()` metodu paketin KENDİ önbelleğinde bir "şu an oturum açık kullanıcı"
    varsa bunu SESSİZCE yeniden kullanabiliyor — "Hesap Değiştir" butonunun asıl amacı (FARKLI bir
    hesap seçebilmek) bu önbellek temizlenmeden GÜVENİLİR ÇALIŞMAZDI (kullanıcı "değiştir"e basıp
    hiçbir seçici GÖRMEDEN aynı hesaba geri dönebilirdi). Paketin kaynak kodu okunup (`google_sign_in-
    7.2.0/lib/google_sign_in.dart`) `authenticate()`'ten AYRI, gerçekten "sessiz/lightweight" bir
    `attemptLightweightAuthentication()` metodu OLDUĞU doğrulandı — bu, `authenticate()`'in KENDİSİNİN
    her zaman etkileşimli/UI-gösteren bir akış OLMASI gerektiğini teyit ediyor, ama pratikte
    Android'in Credential Manager'ı yine de "tek hesap varsa" otomatik seçebiliyor; `_signIn.
    signOut()` bu riski ortadan kaldırıyor. Bu değişiklik `_authenticate()`'in PAYLAŞILAN özel bir
    yardımcı olması sayesinde `linkCurrentUser()`/`signIn()`'in (dolayısıyla "Google ile Bağla" VE
    "zaten bağlı, o hesaba geç" akışlarının) ÜÇÜNÜN de hesap seçicisini artık HER ZAMAN taze
    gösteriyor — zararsız, arguably daha doğru bir yan etki.
  - **`AuthLinkProvider.signOut()`** — `linkWithGoogle()`/`signInWithGoogle()` ile AYNI
    `isLinking` bool'unu (işlem sırasında `true`) paylaşıyor, `_service.signOut()`'a ince bir
    sarmalayıcı, dönen YENİ uid'i aynen geçiriyor.
  - **`utils/google_link_action.dart`'a İKİ yeni fonksiyon:**
    - `handleSignOutTap(context)` — onay diyaloğu (`googleSignOutConfirmTitle`/`Body`, "İptal"/
      "Çıkış Yap" butonları) → onaylanırsa `authLink.signOut()` → dönen uid'i `switchToUid`'e
      yazar. **Başarı SnackBar'ı BİLEREK YOK** — `switchToUid` ataması TÜM `MultiProvider`
      ağacını (`main.dart`'taki `_AppRoot`) ANINDA söküp yeniden kurduğu için gösterilecek bir
      SnackBar'ın widget'ı zaten anında yok oluyor; kullanıcı Onboarding'in yeniden görünmesiyle
      zaten "çıkış yapıldığını" net anlıyor ("uygulama arayüzü başlangıç haline dönsün" isteği
      TAM OLARAK bu — taze anonim uid'in Firestore'da hiç `onboardingState` belgesi olmadığı
      için `_AppStartupGate` Onboarding'i BAŞTAN gösteriyor).
    - `handleSwitchAccountTap(context)` — onay diyaloğu YOK (kullanıcı isteğinde yalnızca Çıkış
      Yap için istenmişti) — doğrudan `authLink.signInWithGoogle()`'ı çağırıp `_offerSignInInstead`
      ile BİREBİR aynı başarı/hata SnackBar mesajlarını (`googleSignInSuccessMessage`/
      `googleSignInFailedMessage` — YENİ anahtar EKLENMEDİ, zaten var olan mesajlar aynı
      operasyonu (`signIn()`) tanımladığı için yeniden kullanıldı) paylaşıyor.
  - **Veri kaybı YOK — `linkWithCredential` mantığına hiç dokunulmadı.** Kullanıcının isteği
    "sıfırdan yeni kullanıcı oluşturma" demişti — bu zaten önceki oturumda `linkCurrentUser()`'ın
    (`user.linkWithCredential`) AYNI uid'i koruyarak yaptığı şeydi, bu turda DEĞİŞMEDİ. "Çıkış
    Yap"/"Hesap Değiştir" ikisi de `signInWithCredential`/`signInAnonymously` kullanıyor
    (SESSİON DEĞİŞTİRME), `linkWithCredential` (SESSİON KORUMA) DEĞİL — bu ayrım bilinçli: ikisi
    de kullanıcının BİLEREK farklı bir kimliğe GEÇMEK istediği senaryolar, "mevcut anonim veriyi
    koru" senaryosu DEĞİL.
  - **Yükleniyor göstergesi** — `authLink.isLinking` `true` iken buton `Row`'unun YERİNE küçük
    bir `CircularProgressIndicator` render ediliyor (`ThemeProvider`/diğer provider'ların
    `context.watch` ile canlı izlenmesiyle AYNI reaktif desen) — ayrı bir state/dialog GEREKMEDİ.
  - **Test:** YENİ `test/auth_link_provider_test.dart` (mutable/kontrol edilebilir bir sahte
    `GoogleAuthService` ile: varsayılan durum, `linkWithGoogle` başarı/iptal/"zaten bağlı"
    istisnası, `signInWithGoogle` outcome geçişi, YENİ `signOut` — `isLinking`'in işlem
    SIRASINDA `true`, sonra `false` olduğu dahil —, `hasSeenLinkPrompt` kalıcılığı) + YENİ
    `test/settings_screen_test.dart` (`profile_screen_test.dart`'taki "bağımsız test uygulaması +
    enjekte edilebilir sahte servis" deseniyle: bağlı DEĞİLKEN SVG/butonlar HİÇ görünmez;
    bağlıyken SVG + iki buton görünür VE gerçekçi dar viewport'ta [412×915, bkz. "Test kalıpları"
    bölümündeki genel gotcha] `RenderFlex overflow` OLMADIĞI `tester.takeException()` ile açıkça
    doğrulanıyor; Çıkış Yap iptal edilirse `signOut` ÇAĞRILMAZ; onaylanırsa çağrılır VE
    `switchToUid` güncellenir; Hesap Değiştir `signIn`'i çağırıp `switchToUid`'i seçilen hesabın
    uid'ine günceller; Hesap Değiştir iptal edilirse (seçici `null` döner) `switchToUid` DEĞİŞMEZ).
    `switchToUid` global `ValueNotifier`'ı `setUp()`'ta `null`'a sıfırlanıyor (`AdFreePromoTrigger.
    resetForTest()` ile AYNI "paylaşılan global sinyali testler arası izole et" gerekçesi — bu,
    `switchToUid`'i test eden İLK dosya, önceden hiç test edilmemişti). **Toplam: 275 test.**
  - **Doğrulama:** `flutter build apk --debug` + cihaza kurulum + `adb shell monkey`/`pidof` ile
    çöküş olmadan açıldığı doğrulandı. **Web preview'da CanvasKit tıklama etkileşimi bu ortamda
    güvenilir çalışmadığı için** (bkz. "Temalar"/"Su Takibi" bölümlerindeki AYNI önceden belgelenmiş
    gotcha) Onboarding'den geçip Ayarlar'a gerçekten dokunarak GÖRSEL doğrulama YAPILAMADI — bunun
    yerine widget testindeki gerçekçi-viewport `RenderFlex overflow` kontrolüne güvenildi.
    **Kullanıcının kendi cihazında GÖRSEL olarak doğrulaması + tamamlaması gereken (asistan
    gerçek Google hesap kimlik doğrulamasını/hesap seçimini KENDİ ADINA YAPAMAZ):**
    1. Ayarlar'da bağlı bir hesapla Google logosunun + iki butonun doğru göründüğü, iki buton
       yan yana metinlerinin (özellikle "Hesap Değiştir") KIRPILMADAN/TAŞMADAN sığdığı.
    2. "Çıkış Yap" → onay diyaloğu → onayla → uygulamanın GERÇEKTEN Onboarding'e (taze/boş
       duruma) döndüğü.
    3. Aynı Google hesabıyla Ayarlar/Profil'den "Google ile Bağla"ya tekrar dokunup "o hesaba
       geçmek ister misin?" diyaloğunu onaylayınca ESKİ verinin (coin, hedefler, kostümler)
       GERÇEKTEN geri geldiği.
    4. "Hesap Değiştir"e basınca GERÇEKTEN bir Google hesap seçicinin açıldığı (önceki hesabı
       sessizce ATLAMADAN) ve farklı bir hesap seçilince o hesabın (yeni ise boş, eskiyse kayıtlı)
       verisiyle uygulamanın yeniden açıldığı.
- **2026 GÜNCELLEMESİ — gerçek cihazda bulunan bug: "Google ile Bağla" butonuna basınca HİÇBİR ŞEY
  olmuyordu (ne hata ne başarı).** Kullanıcı release APK'yı gerçek cihazına kurup ilk kez denedi ve
  butonun tepki vermediğini bildirdi. `adb logcat` ile canlı teşhis edildi:
  - **Kök neden — `_authenticate()`'in `on GoogleSignInException { return null; }` bloğu HER TÜRLÜ
    hata kodunu (yalnızca kullanıcının BİLEREK vazgeçmesini DEĞİL) sessizce "iptal" gibi
    yorumluyordu.** `handleGoogleLinkTap`'in `if (!context.mounted || !linked) return;` satırı da
    `null`/`false` durumunda HİÇBİR görsel geri bildirim vermiyordu — bu ikisi birleşince, GERÇEK
    bir hata (yapılandırma sorunu, zaman aşımı, cihaz durumu) ile kullanıcının kasıtlı iptali
    ARASINDA ARAYÜZDE HİÇBİR FARK yoktu, ikisi de "buton hiçbir şey yapmıyor" gibi görünüyordu.
  - **İkinci bir gerçek risk — `_signIn.signOut()` (authenticate()'ten HEMEN ÖNCE, "Hesap
    Değiştir"in her zaman taze bir seçici göstermesi için eklenmişti) bu cihazda (Samsung/
    Credential Manager) nadiren yanıt vermeden takılabiliyordu**, bu da TÜM zincirin (signOut()
    dahil) sonsuza kadar beklemesine yol açabilirdi.
  - **Düzeltme (`google_auth_service.dart`, `_authenticate()`):**
    1. Hem `_signIn.signOut()` (5sn) hem `_signIn.authenticate()` (25sn) çağrılarına `.timeout(...)`
       eklendi — cihaz/eklenti yanıt vermese bile akış sonsuza kadar TAKILI KALMAZ, bir zaman
       aşımı sonrası `GoogleSignInException(code: interrupted)` fırlatılır.
    2. **`GoogleSignInException` yakalama mantığı DARALTILDI** — yalnızca `code ==
       GoogleSignInExceptionCode.canceled` (kullanıcının GERÇEKTEN geri tuşuna basması/dışarı
       dokunması) sessizce `null`'a düşüyor; DİĞER TÜM kodlar (`interrupted`,
       `clientConfigurationError`, `providerConfigurationError`, `uiUnavailable`, `userMismatch`,
       `unknownError` — bkz. `google_sign_in_platform_interface`'in `GoogleSignInExceptionCode`
       enum'u) artık `rethrow` ediliyor. Bu istisna `linkCurrentUser()`/`AuthLinkProvider.
       linkWithGoogle()` üzerinden hiç yakalanmadan `handleGoogleLinkTap`'in mevcut `catch (_) {
       showSnackBar(googleLinkFailedMessage) }` bloğuna ulaşıyor — kullanıcı artık GERÇEK bir
       hatada görünür bir mesaj görüyor, sessiz bir "hiçbir şey olmadı" değil.
  - **Bu turda AÇIĞA ÇIKAN, KOD DIŞI bir ikinci sorun — cihaz taraflı bir Google Play Services
    arızası:** Düzeltmeden sonra kullanıcı GERÇEKTEN "Bağlanırken sorun oluştu" mesajını gördü
    (önceki sessiz davranışın YERİNE) — `adb logcat` bunun ardındaki gerçek native hatayı ortaya
    çıkardı: `GoogleApiManager: SecurityException: Unknown calling package name
    'com.google.android.gms'` + `ConnectionResult{statusCode=DEVELOPER_ERROR, ...}`. **İmza/SHA-1
    kaydı AYRICA doğrulandı ve DOĞRU olduğu teyit edildi** (`apksigner verify --print-certs` ile
    kurulu release APK'nın SHA-1'i `cde69544d15a5d9e2cb6f4bc2be5cde6125344a3`, `google-services.
    json`'daki kayıtlı `certificate_hash` ile BİREBİR eşleşiyor) — yani bu, uygulamanın Firebase/
    OAuth yapılandırmasında bir hata DEĞİL, cihazın KENDİ Google Play Services durumuyla ilgili
    (bilinen bir GMS iç IPC/binder kimlik doğrulama arızası sınıfı — genelde Play Services önbelleğini
    temizlemek/güncellemek veya cihazı yeniden başlatmakla çözülür). **Kullanıcıya bu üç adım
    (yeniden başlat → Play Services önbelleğini temizle → Play Services'i güncelle) önerildi**,
    sonucu bu turda DOĞRULANAMADI (cihaz taraflı bir adım, asistan yapamaz).
  - **Ders:** bir servis sınıfının `on SomeException { return null; }` gibi GENİŞ bir istisna
    yakalama bloğu, o istisna türünün İÇİNDE birden fazla farklı anlam taşıyan bir kod/alt tür
    (burada: `canceled` vs. diğer TÜM hata kodları) varsa, farklı anlamları AYNI sessiz sonuca
    indirger — kullanıcıya "gerçek hata" ile "kasıtlı vazgeçme" arasındaki farkı KAYBETTİRİR. Böyle
    bir birleşik istisna tipiyle çalışırken, hangi ALT kodun/durumun GERÇEKTEN sessiz kalması
    gerektiğini AÇIKÇA seçip geri kalanını çağırana FIRLATIN.
  - **Bu değişiklik `FirebaseGoogleAuthService`'in kendisi (platform kanalı + Firebase'e dokunduğu
    için) `flutter_test`'te DOĞRUDAN test EDİLEMİYOR** (bkz. bölümün başındaki "flutter_test'te
    KULLANILAMAZ" notu) — yalnızca `flutter test`'in TAMAMININ (299/299) hâlâ geçtiği doğrulandı
    (bu dosyaya dokunan hiçbir test YOK, değişiklik güvenle izole).
- **2026 GÜNCELLEMESİ — ASIL kök neden bulundu: `google-services.json`'a Google'ın KENDİ "Uygulama
  İmzalama Anahtarı" (App Signing Key) sertifikası HİÇ eklenmemişti.** Yukarıdaki turda "İmza/SHA-1
  kaydı AYRICA doğrulandı ve DOĞRU" denilmişti — bu SINIRLI bir doğrulamaydı: yalnızca `adb install`
  ile SIDELOAD edilen (bizim `upload-keystore.jks` ile imzaladığımız) test APK'sının imzasını
  kontrol ediyordu. **Play Store'dan indiren GERÇEK test kullanıcıları farklı bir APK alıyor** —
  Google'ın "Play App Signing" modeli (bkz. "Release İmzalama" bölümü — yeni uygulamalar için
  ZORUNLU) uygulamayı Play Store'a dağıtmadan ÖNCE, bizim upload sertifikamızdan TAMAMEN FARKLI,
  Google'ın KENDİ yönettiği bir "App Signing Key" ile YENİDEN İMZALIYOR. Firebase'e o zamana kadar
  yalnızca upload sertifikamızın SHA-1'i kayıtlıydı — Play Store üzerinden kuran kullanıcıların
  cihazındaki uygulamanın GERÇEK imzası (App Signing Key) Firebase'de HİÇ tanınmıyordu, bu yüzden
  Google Sign-In OAuth doğrulaması o kullanıcılar için SESSİZCE reddediliyordu (kullanıcı raporu:
  "birden fazla kullanıcı" etkileniyordu — TEK bir cihazın GMS arızası değil, SİSTEMİK bir sorundu).
  - **Bulma yöntemi — Play Console'da (kullanıcıyla birlikte, ekran görüntüleriyle adım adım):**
    Play Console > Google Play ile korunanlar > "Google Play Store koruması" kartını genişlet >
    "Uygulama imzalama anahtarını koru" satırındaki **"Google Play Uygulama İmzalama'yı yönetin"**
    linkine tıklanınca `.../keymanagement` sayfası açılıyor — orada "Uygulama imzalama anahtarı"
    (Kullanımda) bölümünün **"Klasik anahtar"** sütunundaki SHA-1/SHA-256 butonlarına tıklanınca
    GERÇEK değerler açığa çıkıyor. **Bu sayfa Google tarafından TAŞINMIŞ** — eski "Uygulama
    bütünlüğü" (App integrity) sol menü linki artık yalnızca "ayarlarınız taşındı, Google Play ile
    korunanlar sayfasında" diyen bir yönlendirme sayfası; doğru yer artık "Google Play ile
    korunanlar" ana sayfası.
    - App Signing Key SHA-1: `00:76:5C:11:96:CD:FC:B3:43:D9:D3:31:68:B8:32:BA:5D:3F:D2:77`
    - App Signing Key SHA-256: `85:98:CD:68:6C:62:A9:F3:17:07:95:E7:86:5E:A9:73:4E:F5:87:15:5E:F4:13:EC:1C:54:E0:75:DD:CF:81:24`
    (Upload key'in `CD:E6:95:44...` SHA-1'inden TAMAMEN FARKLI — kanıt buydu.)
  - **Düzeltme:** Kullanıcı bu iki parmak izini Firebase Console'a (Project settings > Your apps >
    Android uygulaması > Add fingerprint) EKLEYİP `google-services.json`'ı yeniden indirdi;
    `android/app/google-services.json`'a üçüncü bir `oauth_client` girdisi
    (`certificate_hash: "00765c1196cdfcb343d9d33168b832ba5d3fd277"`, App Signing Key'in
    tire'siz/küçük harfli hâli) olarak eklendiği diff'te doğrulandı. Dosya projeye kopyalanıp
    `flutter test` (299/299) + `flutter build appbundle --release` ile yeniden derlendi
    (versionCode 1.1.0+6'ya yükseltildi).
  - **Ders — genelleştirilebilir bir Play Store dağıtım deseni:** Play App Signing AÇIKKEN (yeni
    uygulamalar için varsayılan/zorunlu), Firebase/Google Sign-In gibi SHA-sertifika tabanlı HER
    entegrasyon için İKİ AYRI sertifika parmak izinin kaydedilmesi GEREKİR — (1) geliştiricinin
    KENDİ upload/imzalama sertifikası (yerel derlemeler + `adb install` ile sideload testleri için)
    VE (2) Google'ın Play Console > Google Play ile korunanlar > Uygulama imzalama sayfasından
    alınan "App Signing Key" sertifikası (Play Store'dan GERÇEKTEN indiren kullanıcılar için). Yalnızca
    birini eklemek, "kendi imzaladığın test APK'nda çalışıyor ama gerçek Play Store kullanıcılarında
    ÇALIŞMIYOR" gibi kafa karıştırıcı, SESSİZ bir başarısızlığa yol açar — bu iki sertifikanın
    FARKLI olduğu unutulup yalnızca biri kontrol edilirse (bu arc'ta tam olarak olan buydu) kök
    neden gözden kaçabilir.
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILAMADI** (Play Store dağıtımının yeni sertifikayı
    yansıtması zaman alabilir + kullanıcının kendi test kullanıcılarıyla doğrulaması gerekiyor) —
    yalnızca yapılandırmanın DOĞRU eklendiği (Firebase Console + `google-services.json` diff'i)
    kod seviyesinde doğrulandı. **Kullanıcının yapması gereken:** yeni AAB'yi (1.1.0+6) Kapalı
    Test'e yükleyip, testçilerin GÜNCELLENMİŞ sürümü Play Store'dan aldıktan sonra Google ile
    bağlanmayı tekrar denemesi.
- **2026 GÜNCELLEMESİ — App Signing Key düzeltmesinden SONRA bile sorun devam etti ("bağlanmıyor
  yine aynı sorun var"); ASIL kök neden bulundu ve DOĞRULANDI: `default_web_client_id` string
  kaynağı R8'in kaynak küçültücüsü (`isShrinkResources = true`, bkz. "Release İmzalama" bölümü)
  tarafından release build'lerden SESSİZCE SİLİNİYORDU — Push Bildirimi Özel Sesi bölümünde
  belgelenen `zibo_notification.wav` bug'ıyla BİREBİR AYNI kök neden sınıfı.**
  - **Teşhis:** `google_sign_in_android` eklentisinin native tarafı (`GoogleSignInPlugin.java`),
    Dart'ın `initialize()`'ı açıkça bir `serverClientId` GEÇMEDİĞİ durumda, `context.getResources().
    getIdentifier("default_web_client_id", "string", ...)` ile bu kaynağı yalnızca METİN İSMİYLE,
    ÇALIŞMA ZAMANINDA okuyor — `google-services` Gradle plugin'inin `google-services.json`'daki Web
    client'tan OTOMATİK ürettiği bu string'e Java/Kotlin/XML'de HİÇBİR statik `R.string.x` referansı
    YOK. R8'in statik kullanım analizi bu reflection tabanlı okumayı GÖREMEDİĞİ için kaynağı
    "kullanılmıyor" sanıp release APK'dan siliyordu — `aapt2 dump resources` ile bu ampirik olarak
    DOĞRULANDI (kaynak gerçekten APK'da yoktu). Sonuç: `serverClientId` boş kalıp Android'in
    `CredentialManager`'ı (bu alanı ZORUNLU tutuyor) isteği Google'ın sunucusuna hiç GÖNDERMEDEN
    reddediyordu — bu da Google Cloud Console'un OAuth metrikleri panelinde hiçbir hata/istek
    verisinin GÖRÜNMEMESİNİ (istek sunucuya hiç ulaşmadığı için) açıklıyor, ve neden yalnızca DEBUG
    build'lerin (küçültme kapalı) çalışıp TÜM release build'lerin (App Signing Key'den BAĞIMSIZ,
    hangi sertifika imzalarsa imzalasın) aynı şekilde başarısız olduğunu tam olarak izah ediyor.
  - **Bu noktaya varmadan ÖNCE elenen ihtimaller** (kanıtla): device-side GMS bozulması (BİRDEN
    FAZLA farklı fiziksel cihazda aynı hata görüldüğü için elendi), API key Android kısıtlamaları
    (Cloud Console'da "None" — elendi), OAuth consent screen "Testing" modu (Console'da "In
    production" — elendi), OAuth client "app ownership unverified" uyarısı (üç client için de
    "not applicable... not a Google Play Store app" diyordu — muhtemelen alakasız/eksik bir Google
    özelliği, elendi), `GoogleApiManager: SecurityException: Unknown calling package name` +
    `DEVELOPER_ERROR` logcat hatası (İLK GÜÇLÜ ŞÜPHELİ olarak kovalandı ama WebSearch ile Google'ın
    AdMob SDK destek ekibinin KENDİ ifadesiyle birçok alakasız uygulamada görülen, zararsız bir
    arka-plan log gürültüsü olduğu doğrulanıp elendi).
  - **Düzeltme — `android/app/src/main/res/raw/keep.xml`'e `@string/default_web_client_id`
    eklendi** (mevcut `@raw/zibo_notification` girdisiyle AYNI dosya, aynı `tools:keep` listesi) —
    R8'e bu kaynağa DOKUNMAMASINI açıkça söylüyor.
  - **Doğrulama İKİ aşamalı yapıldı:** (1) statik — düzeltmeden SONRA yeniden derlenen
    `app-release.apk`'da `aapt2 dump resources` ile `string/default_web_client_id`'in ARTIK
    GERÇEKTEN var olduğu teyit edildi (düzeltmeden ÖNCE aynı komutla YOK olduğu doğrulanmıştı); (2)
    canlı — bu release-imzalı (upload key, aynı R8/küçültme yapılandırmasıyla) APK, Play Store'da
    kurulu olan (App Signing Key ile imzalı) sürüm KALDIRILIP `adb install -r` ile bağlı bir Xiaomi
    test cihazına (`8b9a14f1`) kurulup açıldı, kullanıcı "Google ile Bağla"ya bastı ve **"bağlandı"**
    diye doğruladı — sorun KALICI olarak çözüldü.
  - **Ders — genelleştirilebilir bir Android/R8 kalıbı, `zibo_notification.wav` bug'ıyla İKİNCİ
    somut örneği:** herhangi bir native platform eklentisinin bir Android kaynağına yalnızca bir
    STRING/İSİM üzerinden ÇALIŞMA ZAMANINDA reflection ile referans verdiği HER durumda (raw ses
    dosyaları, generated string'ler, drawable'lar vb.), release build'de `isShrinkResources = true`
    açıkken bu kaynak SESSİZCE silinme riski taşır — derleme hatası/uyarısı YOK, yalnızca çalışma
    zamanında sessiz bir eksiklik. Yeni bir "yalnızca isimle okunan" kaynak eklenirken PROAKTİF
    olarak `res/raw/keep.xml`'e eklemek (dosya adı `raw/` klasöründe olsa da `tools:keep`
    içeriğine `@string/`/`@drawable/` gibi başka kaynak türleri de eklenebiliyor), bu sınıf bug'ı
    SAATLERCE teşhis etmekten çok daha ucuza mal oluyor.
  - **Sürüm 1.1.0+7'ye yükseltildi**, bu düzeltmeyi içeren yeni bir AAB derlenip Play Console'un
    Kapalı Test track'ine yüklenmeye hazır.
- **2026 GÜNCELLEMESİ — Play Store'a yayınlandıktan SONRA gelen yeni bir rapor: "hesap seçme ekranı
  geliyor, hesabıma dokunuyorum ama hiçbir şey olmuyor."** Önceki turdaki düzeltme (yalnızca
  `GoogleSignInException.canceled` sessiz kalsın, diğerleri fırlatılsın) bu YENİ senaryoyu
  KAPSAMIYORDU çünkü bu sefer HİÇBİR İSTİSNA fırlatılmıyordu — `authenticate()` BAŞARIYLA
  tamamlanıyor, yalnızca dönen hesabın `idToken`'ı `null` geliyordu.
  - **Teşhis — canlı `adb logcat` ile (bağlı cihaz + `logcat -G 16M` ile büyütülmüş buffer,
    yalnızca ilgili etiketlere filtrelenmiş: `flutter`/`GoogleApiManager`/`ActivityTaskManager`
    vb. — cihazın sensör/ekran log gürültüsü varsayılan buffer'ı saniyeler içinde dolduruyordu, ilk
    filtresiz denemede asıl kanıt kaybolmuştu):** `ActivityTaskManager` log'ları hesap seçici
    akışının (`HiddenActivity` → `SignInCredentialChooserActivity` →
    `GoogleSignInActivity` → `HiddenActivity` → `MainActivity`) TAM OLARAK normal, hatasız
    şekilde açılıp kapandığını gösteriyordu (native tarafta HİÇBİR sorun yok) — ama bu SIRADA
    (ve SONRASINDA) `flutter` etiketli TEK BİR log satırı bile YOKTU. Bu, akışın Dart tarafında
    bir İSTİSNA olmadan, SESSİZCE `null` döndüğünü kanıtlıyordu.
  - **Kök neden — `_authenticate()`'in `if (idToken == null) return null;` satırı.** Bu satır
    `idToken`'ın `null` gelmesini kullanıcının vazgeçmesiyle AYNI kategoriye koyup sessizce
    `null` döndürüyordu — ama bu İKİSİ TAMAMEN FARKLI durumlar: kullanıcı vazgeçtiğinde
    `authenticate()` zaten `GoogleSignInException(code: canceled)` FIRLATIYOR (ayrı bir kod
    yoluyla ele alınıyor); BURADAKİ durum ise `authenticate()`'in BAŞARIYLA bir hesap
    döndürüp yalnızca ID token'ın eksik gelmesi — muhtemelen geçici bir Credential
    Manager/Play Services tuhaflığı (kesin ikincil kök neden belirsiz, ama BELİRTİ artık net).
    Sonuç: `linkCurrentUser()` → `null`, `AuthLinkProvider.linkWithGoogle()` → `false`,
    `handleGoogleLinkTap`'in `if (!context.mounted || !linked) return;` satırı da HİÇBİR
    mesaj göstermeden sessizce çıkıyordu — kullanıcıya "buton hiçbir şey yapmıyor" gibi
    görünen TAM OLARAK bu rapor.
  - **Düzeltme — YENİ `GoogleSignInMissingIdTokenException`** (`google_auth_service.dart`):
    `idToken == null` artık sessizce `null` DÖNMÜYOR, bu YENİ, açıkça adlandırılmış istisnayı
    FIRLATIYOR — `handleGoogleLinkTap`'in genel `catch (e, st)` bloğuna kadar yayılıp hem
    görünür bir hata mesajı (`googleLinkFailedMessage`) gösteriyor HEM DE `debugPrint` ile
    logcat'e düşüyor (bir dahaki sefere bu durum tekrarlanırsa kanıt ANINDA elde olacak,
    ayrıca bir filtreli `adb logcat` seansı kurmaya gerek kalmayacak). **Ders — önceki turdaki
    AYNI dersin bir varyasyonu:** bir akışın "başarı" ve "kullanıcı vazgeçmesi" dışında
    ÜÇÜNCÜ bir sonucu (kısmi/eksik başarı) olabiliyorsa, bu üçüncü durumu ikiden BİRİNE
    (özellikle "sessiz" olana) indirgemek gerçek bir hatayı görünmez kılar — her farklı sonuç
    türü kendi açık kod yoluna sahip olmalı.
  - **Cihazda GERÇEK dünya sideload testi bu turda YAPILMADI** — cihazda kurulu olan sürüm artık
    kullanıcının GERÇEK, Play Store'dan güncellediği ve kendi verisini taşıyan canlı kurulumu
    (9 coin, İspanyolca arayüz — kullanıcının kendi testleri sırasında birikmiş) olduğu için,
    onu debug build ile ÜZERİNE YAZMAK (`adb install -r` bir imza uyuşmazlığı verip önce
    `uninstall` gerektirirdi, bu da bu veriyi SİLERDİ) BİLEREK YAPILMADI. Düzeltme yalnızca
    `flutter test`'teki (303/303) yeni bir testle (`auth_link_provider_test.dart` —
    `GoogleSignInMissingIdTokenException`'ın `linkWithGoogle()`'dan sessizce yutulmadan
    YAYILDIĞINI doğruluyor) doğrulandı. **Kullanıcının Play Store güncellemesini aldıktan
    SONRA gerçek cihazında doğrulaması gereken:** sorun tekrar olursa artık en azından görünür
    bir "Bağlanırken sorun oluştu" mesajı görmeli (sessiz kalmamalı) — sorun TAMAMEN ortadan
    kalkıp kalkmadığı (idToken'ın neden bazen eksik geldiği) ayrıca izlenmeli.
- **2026 GÜNCELLEMESİ — ASIL/KESİN kök neden nihayet bulundu ve DÜZELTİLDİ: App Signing Key
  SHA-1'i Firebase'e YANLIŞ değerle kaydedilmişti.** Yukarıdaki `GoogleSignInMissingIdTokenException`
  düzeltmesi Play Store'a yayınlandıktan SONRA bile kullanıcı AYNI sorunu bildirmeye devam etti,
  ama artık SESSİZ değildi — görünür "Bağlanırken bir sorun oluştu" mesajı çıkıyordu (önceki
  düzeltmenin ÇALIŞTIĞININ kanıtı). Kullanıcı "bu debug'ta çalışıyor, kesin R8 küçültmesinden
  kaynaklanıyor" diye ısrar etti (bu projede AYNI bug sınıfının — `default_web_client_id` — daha
  önce GERÇEKTEN yaşanmış olması yüzünden makul bir şüpheydi).
  - **R8 hipotezi KONTROLLÜ olarak test edildi ve ELENDİ:** `isMinifyEnabled`/`isShrinkResources`
    GEÇİCİ olarak `false` yapılıp AYNI Play Store dağıtım yoluyla (App Signing Key ile) yeni bir
    sürüm yayınlandı — sorun BİREBİR AYNI şekilde devam etti. Bu, R8'i kesin olarak devre dışı
    bıraktı: aranan şey R8'in sildiği bir kaynak DEĞİLDİ.
  - **Asıl kanıt — geniş kapsamlı (`*:W`, tüm etiketler, yalnızca uyarı+ seviyesi) canlı `adb
    logcat` yakalamasında** hesap seçici kapanmadan HEMEN ÖNCE şu satırlar bulundu:
    ```
    W Auth    : [GetTokenResponseHandler] Server returned error: This android application is
    not registered to use OAuth2.0, please confirm the package name and SHA-1 certificate
    fingerprint match what you registered in Google Developer Console...
    W Auth.Api.Credentials: [AccountReauth_flowRunner] Flow failed.
    cmia: [8] Unknown error [status=UNREGISTERED_ON_API_CONSOLE].
    ```
    **`UNREGISTERED_ON_API_CONSOLE`** — Google'ın kendi sunucusu, bu APK'yı imzalayan sertifikanın
    Cloud Console'da KAYITLI OLMADIĞINI söylüyordu.
  - **Kesin doğrulama — cihazda GERÇEKTEN kurulu olan APK'nın imza sertifikası doğrudan çekilip
    ölçüldü** (`adb shell pm path` ile APK yolu bulunup `adb pull` ile indirildi, `apksigner
    verify --print-certs` ile imzası okundu): GERÇEK SHA-1 `EB:AA:2E:93:01:06:D6:DB:54:1D:9A:BC:
    53:7D:B4:9A:61:F3:CF:32` (SHA-256 `46:99:DC:0B:1A:DD:48:98:20:2D:71:88:31:48:E6:E4:68:A0:D8:
    0A:3A:15:81:C0:22:2A:18:6F:AA:59:75:C8`) — bu, `google-services.json`'da o ana kadar kayıtlı
    OLAN ÜÇ sertifikanın (upload key `CD:E6:95:44:...`, debug key `AD:E5:CB:35:...`, ve daha
    önce "App Signing Key" diye eklenen `00:76:5C:11:...`) HİÇBİRİYLE eşleşmiyordu.
  - **Önceki turda Play Console'dan kopyalanan `00:76:5C:11:...` değeri YANLIŞTI** — muhtemelen
    Play Console'un "Uygulama imzalama anahtarı" sayfasındaki "Yükleme anahtarı sertifikası" ile
    "Uygulama imzalama anahtarı sertifikası" satırlarının (veya anahtar rotasyonu/"Klasik anahtar"
    dışındaki bir varyantın) karıştırılmasından kaynaklandı — kesin sebep önemli değil, önemli olan
    GERÇEK sertifikanın artık cihazdan bizzat ÖLÇÜLMÜŞ olması (bir ekran görüntüsünden elle
    kopyalamaya değil, `apksigner`'ın kendi çıktısına dayanıyor — bu YÖNTEM daha güvenilir).
  - **Düzeltme:** kullanıcı bu GERÇEK SHA-1/SHA-256'yı Firebase Console'a ("Add fingerprint")
    ekleyip `google-services.json`'ı yeniden indirdi — dosyada artık DÖRDÜNCÜ bir `oauth_client`
    girdisi (`certificate_hash: ebaa2e930106d6db541d9abc537db49a61f3cf32`) var. R8 de (hipotez
    elendiği için) `true`'ya GERİ ALINDI.
  - **Ders — genelleştirilebilir, bu bug sınıfının EN KESİN teşhis yöntemi:** Play App Signing
    kullanan bir uygulamada Google Sign-In/Firebase SHA-sertifika sorunu yaşanıyorsa, Play
    Console ekran görüntülerinden SHA-1/SHA-256 elle KOPYALAMAK yerine, GERÇEKTEN dağıtılan APK'yı
    (`adb shell pm path` + `adb pull`) çekip `apksigner verify --print-certs` ile İMZASINI
    DOĞRUDAN ÖLÇMEK çok daha güvenilir — Play Console'un çok katmanlı, kafa karıştırıcı arayüzünde
    yanlış satırı kopyalamak (bu oturumda tam olarak olan buydu) kolay, ama cihazdan ölçülen bir
    sertifika ASLA yanlış olamaz.
  - **Doğrulama bu turda YAPILAMADI** — düzeltme henüz yeni bir sürüme (bir sonraki version code)
    paketlenip yayınlanmadı; kullanıcının Play Store güncellemesini aldıktan SONRA "Google ile
    Bağla"yı tekrar denemesi gerekiyor.

## Coin Ekonomisi Güvenliği (Mod APK / Hile Koruması) ([firestore.rules](firestore.rules))

- **2026 — kullanıcı isteği: coin ekonomisini mod APK/hile koruması için sağlamlaştır.** Bu
  bölüm dört ayrı sorunun (rapor + kısmi düzeltme + iki YAPILMASI GEREKENLER notu) sonucu.
- **1) MEVCUT DURUM RAPORU — coin mantığı %100 İSTEMCİ TARAFINDA çalışıyor, hiçbir sunucu tarafı
  doğrulama YOK.** İncelemenin sonucu net:
  - `CoinProvider` (bir `ChangeNotifier`, sunucu değil) TÜM kazanma/harcama mantığını
    (`_earn`/`_spend` ve bunları çağıran `earnX()`/`spendX()`/`purchaseCoinPackage()`/
    `watchAdAndSpinWheel()` metotlarının HEPSİ) doğrudan cihazda çalıştırıyor, sonucu
    (`{balance, totalEarned, totalSpent, transactions, ...}`) `CloudStateStore.save()` ile
    OLDUĞU GİBİ Firestore'a yazıyor.
  - **Satın alma:** `purchaseCoinPackage()` → `MockPurchaseService.purchaseCoinPackage()` — gerçek
    bir ödeme SDK'sı/makbuz doğrulaması YOK, yalnızca 600ms gecikmeyle HER ZAMAN `true` dönen bir
    sahte (bkz. "Şu an mock/placeholder olan şeyler" bölümü). Gerçek IAP henüz bağlanmadığı için
    bugün İTİBARİYLE doğrulanacak gerçek bir makbuz da YOK — ama gerçek IAP bağlandığında bu
    boşluk KRİTİK hale gelecek (bkz. altta 3. madde).
  - **Reklam karşılığı coin (Şans Çarkı + Mağaza'nın Ücretsiz kartı):** `AppodealAdService.
    showRewardedAd()`'ın ödül sinyali (`onRewardedVideoFinished`/`onRewardedVideoClosed`, bkz.
    "AdMob → Appodeal geçişi" bölümü) gerçek Appodeal SDK'sından geliyor (bu, saf bir
    istemci-tarafı flag'den daha güvenilir — reklam SDK'sının kendi gösterim mantığına bağlı)
    ama YİNE DE istemci tarafında değerlendiriliyor, sunucu tarafı doğrulama (SSV) YOK (bkz. altta
    4. madde — Appodeal'in kendisi de S2S/postback tabanlı bir doğrulama sunuyor, AdMob'un SSV'siyle
    AYNI mimari karara [Cloud Functions] bağlı, henüz kurulmadı).
  - **Eskiden Firestore güvenlik kuralları (`firestore.rules`) `coinState` dahil TÜM
    `users/{uid}/state/**` belgelerine `request.auth.uid == uid` sağlandığı sürece SINIRSIZ
    okuma/yazma izni veriyordu** — yani kimliği doğrulanmış (anonim dahil) HERHANGİ bir istemci,
    kendi `coinState` belgesini Firestore SDK'sı/REST API'siyle DOĞRUDAN, uygulamanın kendi UI'ından
    hiç geçmeden, istediği HERHANGİ bir değere ayarlayabiliyordu — bu, APK'yı modlamaya bile GEREK
    KALMADAN (bir proxy/REST çağrısıyla) mümkün bir saldırı yüzeyiydi. **Bu, `flutter test`'te
    kapsanan bir şey DEĞİL** (testler `FakeFirebaseFirestore` kullanıyor, GERÇEK rules motorunu
    hiç çalıştırmıyor) — yalnızca kod okuması + `firestore.rules` dosyasının kendisi incelenerek
    tespit edildi.
  - **Sonuç:** coin bakiyesi bugün itibariyle **tamamen istemciye güvenilen (client-authoritative)**
    bir sistem. Bu, Firestore migrasyonundan ÖNCE zaten (yalnızca yerel `SharedPreferences`'ta,
    kök erişimiyle/kayıt düzenleyicilerle değiştirilebilir) DOĞRUYDU — Firestore'a taşınması bunu
    KÖTÜLEŞTİRMEDİ (yerel veri her zaman değiştirilebilirdi) ama İYİLEŞTİRMEDİ de: rules hiçbir ek
    doğrulama yapmıyordu.
- **2) YAPILAN — `firestore.rules`'a `coinState`'e özel bir doğrulama katmanı eklendi (KISMİ
  düzeltme, TAM çözüm DEĞİL).** Kullanıcının 1. maddedeki "istemcinin doğrudan yazma iznini
  kaldır, yalnızca sunucu tarafı mutasyona izin ver" isteği **HARFİYEN uygulanmadı** — bunun
  yerine gerçekçi bir ORTA YOL seçildi, gerekçesiyle:
  - **Neden TAM lockdown (coinState'e HİÇBİR istemci yazma izni vermemek) ŞİMDİ yapılamaz/
    yapılmadı:** Projenin bugünkü mimarisinde coin verisini Firestore'a yazan TEK yol
    `CoinProvider` → `CloudStateStore.save()` → doğrudan `_doc.set(data)`. Sunucu tarafı bir
    mutasyon yolu (Cloud Function) YOK — proje kullanıcının kendi tercihiyle Blaze (ücretli) plana
    GEÇMEDİ (bkz. "Push Bildirimleri" bölümündeki "Blaze plan GEREKMİYOR" kararı, GitHub Actions +
    Admin SDK'ya geçilme gerekçesi). `coinState`'e `allow write: if false` yazıp bunun YERİNE
    KOYACAK bir Cloud Function OLMADAN yayınlamak, TÜM kazanma/harcama işlemlerinin Firestore'a
    yazımını SESSİZCE engellerdi (`CloudStateStore.save()`'in try/catch'i `PERMISSION_DENIED`
    hatasını yutar, yerel `SharedPreferences` yine de güncellenir — yani oyun İÇİNDE hiçbir hata
    GÖRÜNMEZ, yalnızca coin verisi bir daha ASLA Firestore'a senkronize OLMAZ). **Bunun en somut,
    en zararlı sonucu:** bir önceki oturumda eklenen Google Hesap Bağlama özelliğinin TAM OLARAK
    var oluş sebebi — "coin bakiyesi cihaz değişince kaybolmasın" — SESSİZCE BOZULURDU: kullanıcı
    Google ile bağlanıp yeni bir cihazda giriş yapsa bile, o andan sonraki HİÇBİR coin
    kazanma/harcama Firestore'a yansımayacağı için cihazlar arası bakiye SENKRONİZE OLMAKTAN
    çıkardı (yalnızca bağlama ANINDAKİ dondurulmuş bir bakiye kurtarılabilirdi). Bu yüzden TAM
    lockdown, YALNIZCA bir Cloud Function ile BİRLİKTE (aynı anda) yapılmalı — tek başına asla.
  - **Bunun yerine yapılan — `firestore.rules`'daki `match /users/{userId}/state/coinState`
    bloğu:** İstemcinin coinState'e YAZABİLECEĞİ değerleri KISITLIYOR (tam olarak
    ENGELLEMİYOR):
    1. **Şekil doğrulaması** — `balance`/`totalEarned`/`totalSpent` negatif olmayan tam sayı
       OLMAK ZORUNDA (`is int && >= 0`).
    2. **Monotonluk** — bir `update`'te `totalEarned`/`totalSpent` yalnızca ARTABİLİR, asla
       AZALAMAZ (CoinProvider'ın gerçek kodunun `_earn`/`_spend`'in ikisinin de bu alanları
       yalnızca `+=` ile değiştirdiği, hiçbir yolun `-=` yapmadığı gerçeğinin bir yansıması).
    3. **Matematiksel tutarlılık** — `Δbalance == ΔtotalEarned - ΔtotalSpent` (yine
       `_earn`/`_spend`'in gerçek davranışının rules'a kodlanmış hali — biri BALANCE'ı VE ilgili
       total'i HER ZAMAN AYNI miktarda birlikte değiştiriyor).
    4. **Tek-yazım tutar sınırı** — bir TEK `update`'te kazanılabilecek miktar ≤ 10000 (en büyük
       coin paketi), harcanabilecek miktar ≤ 33000 (en pahalı kostüm, Elmas Kaplama) — her
       `earn*`/`spend*` çağrısı KENDİ `_save()`'ini ANINDA tetiklediği için (bkz.
       `CoinProvider._record`) bu sınırlar HER ZAMAN tam olarak "bir mekanik = bir yazım"a
       karşılık geliyor, birikmiş/toplu bir yazım asla olmuyor.
    5. **İLK senkronizasyon (`create`, `CloudStateStore`'un yerelden Firestore'a TEK SEFERLİK
       göçü)** delta kuralına TABİ DEĞİL (geçmiş bilinmiyor) — yalnızca şekil + gevşek bir üst
       sınır (≤200000, bugünkü test ölçeğinin çok üzerinde, yalnızca bariz fabrikasyonu engelleyen
       bir "akıl sağlığı" kontrolü).
    6. **`delete` tamamen YASAK** — bir istemcinin `coinState`'i silip SIFIRDAN, gevşek `create`
       kuralına göre yeniden yaratarak delta kısıtlamasını "resetlemesi" engellendi.
  - **Bu KISMİ bir düzeltme — KESİNLİKLE "sunucu tarafı yetki" DEĞİL, bir HIZ ENGELLEYİCİ (speed
    bump).** Açıkça neyi ÇÖZMEDİĞİ:
    - **Sürdürülen/scripted saldırıya karşı KORUMASIZ:** Bir saldırgan, rules'un izin verdiği
      "kural dostu" küçük artışları (ör. `dailyCheckIn` = 5 ZC'lik bir yazım deseni) bir betikle
      SINIRSIZ SAYIDA TEKRARLAYARAK zamanla İSTEDİĞİ kadar büyük bir bakiyeye ulaşabilir —
      rules'un HİÇBİR "zaman/sıklık" hafızası YOK (her istek bağımsız değerlendirilir), bu yüzden
      "günde en fazla X kez" gibi bir sınırı rules TEK BAŞINA UYGULAYAMAZ (uygulamanın kendi
      `wheelSpinsUsedToday`/`adWatchesUsedToday`/`hasSeenLinkPrompt` gibi sayaçları da AYNI
      `coinState` belgesinin İÇİNDE, yani İSTEMCİNİN kontrolündeki alanlar — bir saldırgan bu
      sayaçları da her yazımda "bugün henüz hiç kullanmadım" gösterecek şekilde sıfırlayabilir).
    - **Kostüm/tema SAHİPLİK listeleri (`ownedCostumeIds`/`ownedAppThemeIds`) hâlâ TAMAMEN
      korumasız** — bir istemci ödeme yapmadan doğrudan bir id ekleyip "sahip" olabilir. Bunun
      rules-only bir çözümü (`costumes.dart`/`app_themes.dart`'taki id listesiyle SÜREKLİ senkron
      tutulması gereken bir izin listesi) BİLEREK YAZILMADI — hem kırılgan (yeni bir kostüm
      eklendiğinde rules'u güncellemeyi unutmak sessizce ya YENİ kostümü kilitli bırakır ya da
      HİÇBİR koruma sağlamaz) hem de asıl sorunu (client-authoritative mimari) çözmüyor.
    - **TEK gerçek/tam çözüm: coin mutasyon mantığının TAMAMEN sunucu tarafına (Cloud Functions)
      taşınması** — istemci yalnızca "check-in yaptım"/"reklamı izledim"/"bu kostümü satın almak
      istiyorum" gibi bir NİYET bildirir, gerçek bakiye değişimini bir Cloud Function (Admin SDK
      ile, rules'u BYPASS ederek) yapar ve istemci coinState'e ARTIK HİÇ YAZAMAZ (yalnızca okur).
      **Bu, Blaze (ücretli) plana geçiş GEREKTİRİYOR** — projenin şu anki mimarisi (bkz. "Push
      Bildirimleri" bölümü) kullanıcının BİLEREK Blaze'den kaçınıp GitHub Actions'a geçtiği bir
      karar üzerine kurulu. **Bu, yalnızca kullanıcının verebileceği bir maliyet/mimari kararı** —
      asistan bu kararı kullanıcı adına VERMEDİ, yalnızca yukarıdaki ücretsiz/rules-only kısmi
      önlemi uyguladı.
  - **DOĞRULANMADI — bu ortamda Firebase CLI/emulator YOK** (bkz. "Push Bildirimleri" bölümündeki
    aynı sınırlama), rules dosyasının SÖZ DİZİMİ/MANTIĞI gerçek bir Firestore rules motorunda hiç
    ÇALIŞTIRILMADI. `flutter test`'teki `cloud_state_store_test.dart`/`coin_provider_test.dart`
    `FakeFirebaseFirestore` kullandığı için (rules'ı hiç değerlendirmez) bu testler rules
    değişikliğinden ETKİLENMEDİ ve HİÇBİR ŞEY DOĞRULAMIYOR. **Kullanıcının Console'a yapıştırıp
    yayınlamadan ÖNCE Firebase Console > Firestore Database > Rules > "Rules Playground"
    simülatörüyle en az şu senaryoları test etmesi ÖNERİLİR:** (a) kendi uid'inle normal bir
    coin kazanma/harcama yazımı hâlâ İZİN VERİLİYOR mu, (b) `balance`'ı doğrudan (totalEarned/
    totalSpent'e uymayan) rastgele büyük bir değere ayarlamaya çalışan bir yazım REDDEDİLİYOR mu.
    Yayınladıktan SONRA da uygulamada gerçek bir coin kazanma/harcama işlemi yapıp Firestore
    Console'da `coinState` belgesinin GERÇEKTEN güncellendiğini doğrulamak (bkz. "Firestore veri
    kalıcılığı" bölümündeki test adımları) — rules'ta bir mantık hatası varsa bu, coin
    senkronizasyonunun SESSİZCE durmasına yol açabilir, aynı yukarıdaki "TAM lockdown" riskiyle
    AYNI sınıf bir tehlike.
- **3) YAPILMASI GEREKENLER — gerçek IAP bağlanırken:** bkz. "Şu an mock/placeholder olan şeyler"
  bölümündeki `MockPurchaseService` maddesine eklenen YAPILMASI GEREKENLER notu — ÖZET: satın alma
  makbuzu Google Play Developer API'ye karşı SUNUCU TARAFINDA doğrulanmadan `CoinProvider._earn()`
  ÇAĞRILMAMALI, istemcinin "satın alma başarılı" callback'i TEK BAŞINA yeterli değil.
- **4) YAPILMASI GEREKENLER — reklam karşılığı coin için AdMob SSV:** bkz. "AdMob Entegrasyonu"
  bölümüne eklenen YAPILMASI GEREKENLER notu — ÖZET: `ServerSideVerificationOptions` kurulup
  ödülün coin'e çevrilmesi bir SSV callback'e (istemciye DEĞİL) taşınmalı, özellikle ödül
  miktarı/reklam sıklığı büyürse.
- **ŞİMDİ (mock/test aşamasında) yapılabilenler vs. GERÇEK IAP/AdMob'u bekleyenler — kullanıcının
  sorduğu ayrım:**
  - **ŞİMDİ yapılabilir ve yapıldı:** `firestore.rules`'daki şekil/monotonluk/delta doğrulaması
    (2. madde) — Cloud Functions'a veya gerçek IAP/AdMob'a bağımlı DEĞİL, salt Firestore rules
    dili ile, ücretsiz (Spark plan) yazılabilir bir kod-seviyesi kısıtlama.
  - **ŞİMDİ yapılamaz, gerçek IAP'ı BEKLİYOR:** IAP makbuz doğrulaması (3. madde) — doğrulanacak
    gerçek bir makbuz, gerçek IAP SDK'sı bağlanmadan YOK; bugün yazılacak bir "doğrulama" kodu
    test edilemez/anlamsız olurdu.
  - **ŞİMDİ yapılamaz ama AdMob ZATEN gerçek, yalnızca SSV'ye geçilmedi:** AdMob SSV (4. madde) —
    teknik olarak ŞİMDİ de yazılabilir (AdMob hesabı zaten gerçek) ama kendi bir backend endpoint'i
    (SSV callback'ini karşılayacak bir sunucu — yine Cloud Function veya GitHub Actions'ın
    gerçek-zamanlı olmayan doğasına UYMAYAN bir gerçek-zamanlı HTTP endpoint'i) gerektiriyor —
    bu da aynı "Blaze plan mı, başka bir backend mi" kararına bağlı, bu yüzden pratikte 2. madde
    ile AYNI mimari karara (Cloud Functions) kadar ERTELENMESİ öneriliyor (ikisini AYRI AYRI değil
    aynı backend çalışmasıyla BİRLİKTE çözmek daha verimli).
  - **Kullanıcının kararı bekleniyor:** Blaze plana geçip coin mutasyonunu (VE IAP/AdMob
    doğrulamasını) tam olarak Cloud Functions'a taşımak mı, yoksa şimdilik yalnızca bu rules-only
    kısmi önlemle (+ launch öncesi gerçek IAP/AdMob geldiğinde zorunlu olarak eklenecek doğrulama)
    devam etmek mi — asistan bu maliyet/mimari kararını veremez, yalnızca seçenekleri VE her
    birinin ne sağlayıp ne sağlamadığını belgeliyor.

## Davet Et (Referral) Sistemi ([referral_provider.dart](lib/providers/referral_provider.dart), [referral_screen.dart](lib/screens/referral_screen.dart), workspace kökü [notification-scripts/src/processReferralRewards.js](../notification-scripts/src/processReferralRewards.js) + [.github/workflows/process-referral-rewards.yml](../.github/workflows/process-referral-rewards.yml))

- **2026 yeni özellik — büyüme (growth) mekanizması.** Kullanıcı isteği: her kullanıcıya özel bir
  davet kodu/link oluştur (Firebase kullanıcı ID'sine bağlı), davet edilen kişi kodu girip
  kullanınca HEM davet eden HEM davet edilen belirli miktarda ücretsiz ZC kazansın, WhatsApp/
  Instagram'a tek tıkla paylaşım butonu olsun. Kullanıcının onayladığı kapsam kararı: **basit metin
  kodu** — Play Store Install Referrer ile otomatik algılama/deep-link KAPSAM DIŞI bırakıldı (yeni
  bir native paket + uygulamanın gerçekten Play Store'da YAYINDA olmasını gerektiriyordu, o an
  test edilemezdi).
- **Mimari — davet kodu = kullanıcının kendi Firebase uid'i.** Ayrı bir kod üretme/çakışma
  yönetimi/lookup tablosu GEREKMİYOR — `ReferralProvider.referralCode` doğrudan `uid`'i döner.
  `ReferralScreen` bu kodu kopyalama + `ShareService.shareText` (YENİ metot — mevcut
  `shareImageBytes`'tan FARKLI, hiçbir görsel/dosya olmadan salt metin paylaşan basit bir yol,
  davet mesajı için) ile WhatsApp/Instagram'a gönderiyor. Davet edilen kişi bu kodu **elle girip**
  kullanıyor (gerçek bir "kaydolma" ekranı yok, uygulama zaten Anonymous Auth ile otomatik kimlik
  alıyor — bkz. "Firestore veri kalıcılığı" bölümü).
- **Ödül kredisi neden ANINDA DEĞİL — mevcut Firestore rules'un doğal bir sonucu.** İKİ AYRI
  kullanıcının (davet eden + davet edilen) coin bakiyesini AYNI ANDA değiştirmek gerekiyor, ama
  `firestore.rules` yalnızca `request.auth.uid == userId` olan kullanıcının KENDİ `coinState`
  belgesine yazmasına izin veriyor (bkz. "Coin Ekonomisi Güvenliği" bölümü) — davet edilenin
  cihazı davet edenin bakiyesine DOĞRUDAN yazamaz. Bu, projenin genelinde zaten kabul edilmiş
  "hassas coin mutasyonları GitHub Actions + Admin SDK'ya taşınsın" felsefesiyle (bkz. Push
  Bildirimleri bölümü) TUTARLI bir çözümle aşıldı:
  1. `ReferralProvider.redeemCode(code)` KENDİ `users/{uid}/state/referralState` belgesini
     (`{redeemed: true, referrerUid: code}` — AYNI ZAMANDA "zaten kullanıldı" bayrağı) yazar
     (kendi belgesi — mevcut rules'a hiç dokunmadan izinli).
  2. AYRICA yeni, dar kapsamlı bir top-level `referralRedemptions/{autoId}` koleksiyonuna
     `{referrerUid, refereeUid, status: 'pending', createdAt: serverTimestamp()}` kaydı ekler —
     `firestore.rules`'a EKLENEN yeni bir kural bunu yalnızca "kimliği doğrulanmış biri KENDİ
     `refereeUid`'siyle, kendisinden FARKLI bir `referrerUid`'e" (self-referral rules seviyesinde
     de engelleniyor — istemci kontrolünün YANI SIRA ikinci bir savunma katmanı) create-only olarak
     yapabilsin diye sınırlıyor; okuma/güncelleme/silme TAMAMEN kapalı.
  3. **YENİ** `notification-scripts/src/processReferralRewards.js` — diğer 5 bildirim betiğiyle
     AYNI `firebase-admin` deseni, `status == 'pending'` kayıtları tarayıp `referrerUid !=
     refereeUid` VE her iki uid de GERÇEKTEN var mı doğruluyor (Admin SDK ile, rules'u atlayarak),
     geçerliyse HER İKİ tarafın `coinState` belgesine `CoinEconomy.referral` (zaten TANIMLIYDı —
     100 ZC — ve `CoinProvider.earnReferral()` de zaten vardı ama HİÇ ÇAĞRILMIYORDU; bu özellik onu
     ilk kez devreye soktu) kadar ekleyip `CoinProvider._save()`'in ürettiği JSON şekliyle BİREBİR
     uyumlu bir işlem kaydı (`reason: 'Arkadaş daveti'`) da ekliyor, kaydı `'completed'` yapıyor;
     geçersizse `'rejected'` yapıp asla tekrar işlemiyor. **`cleanupStaleAnonymousUsers.js`'in
     AKSİNE `DRY_RUN` varsayılanı `false`** — bu betik EKLEYİCİ/DÜŞÜK RİSKLİ (yalnızca coin bakiyesi
     ARTIRIYOR, hiçbir şey SİLMİYOR) ve `.github/workflows/process-referral-rewards.yml`'in
     `schedule:`'ıyla (diğer bildirim workflow'larıyla AYNI saatlik desen, dakika `:28` — GitHub'ın
     "yoğun" dediği `:00/:15/:30/:45`'ten kaçınmak için) GERÇEK otomasyonla çalışması amaçlanıyor;
     her çalıştırmada elle onay beklemek otomasyonun amacını bozardı. Yine de `workflow_dispatch`
     ilk sağlık kontrolü için `dry_run: true` seçeneği sunuyor.
  4. **Bilinçli olarak YAPILMAYAN bir client-side kontrol:** `redeemCode` girilen kodun GERÇEKTEN
     var olan bir kullanıcıya ait olup olmadığını istemci tarafında DOĞRULAMAZ — kök `users/{uid}`
     dokümanı yalnızca SAHİBİ tarafından okunabiliyor (`isOwner()`), bu kısıtlamayı gevşetmeden bir
     istemcinin "bu uid var mı" diye sorgulamasının güvenli bir yolu yok (bu turda KAPSAM DIŞI
     bırakıldı — mevcut kuralı değiştirmek yeni bir manuel Firebase Console adımı + genişleyen
     saldırı yüzeyi demek olurdu). Geçersiz/uydurma bir kod girilirse istek yine de "gönderildi"
     denir, asıl doğrulama backend betiğinde yapılır — geçersizse sessizce kredilenMEZ.
  5. **Bilinen/kabul edilen sınırlama:** betik AYNI ANDA iki kez çalışırsa (örtüşen manuel + otomatik
     tetikleme) teorik olarak aynı kayıt iki kez kredilenebilir (Firestore transaction/lock
     KULLANILMIYOR) — projenin genelindeki client-authoritative ekonomi risk kabulüyle AYNI
     kategoride (bkz. "Coin Ekonomisi Güvenliği" bölümü), kapsam dışı bırakıldı.
- **Profil ekranına yeni satır:** "Arkadaşını Davet Et" (`Icons.person_add_alt_1_rounded`),
  "Profil Kartını Paylaş" satırının HEMEN ardına eklendi — mevcut `_ProfileLinkRow` widget'ı
  AYNEN yeniden kullanıldı, yeni bir görsel bileşen YAZILMADI. Alt metin canlı: kod henüz
  kullanılmadıysa genel bir davet mesajı, kullanılmışsa `referralAlreadyRedeemedStatus`.
- **`ReferralScreen`** — kod gösterimi (kopyala + paylaş butonları) + (henüz redeem edilmediyse)
  bir kod giriş alanı + "Kullan" butonu. Kullanıcı zaten bir kod kullanmışsa giriş alanı YERİNE bir
  onay kartı gösterilir. `ReferralProvider.isRedeeming` diğer provider'lardaki `isLinking` deseniyle
  AYNI — gönderim sırasında küçük bir yükleniyor göstergesi.
- **Test:** YENİ `referral_provider_test.dart` — `fake_cloud_firestore` ile (kendi kodunu kullanma
  reddedilir, boş kod reddedilir, geçerli bir kod `referralRedemptions`'a doğru şekilli bir
  `pending` kaydı bırakır, ikinci bir redeem denemesi reddedilir, uid yokken özellik tamamen devre
  dışı, durum kalıcı) + `widget_test.dart`'ın "Zibo ile Bağın" senaryosuna yeni bir adım (testte
  `uid` her zaman `null` olduğu için — gerçek Firebase test ortamında hiç initialize edilmiyor —
  yalnızca "özellik kullanılamıyor" durumu doğrulanabiliyor; asıl redeem mantığı yukarıdaki
  provider testinde kapsanıyor). **Gotcha (gerçekten yaşandı):** `ReferralProvider`'ın kurucusu
  enjekte edilen `firestore`'u kendi `_firestore` alanına atıyordu ama `CloudStateStore`'a
  FORWARDLAMAYI unutmuştu — `CloudStateStore`'un kendi `firestore ?? (uid == null ? null :
  FirebaseFirestore.instance)` düşüşü devreye girip `uid` doluyken gerçek `FirebaseFirestore.
  instance`'a ulaşmaya çalışıp `[core/no-app]` hatasıyla çöküyordu (testte İLK çalıştırmada
  yakalandı). **Ders:** bir provider birden fazla Firestore-bağımlı bileşen (kendi `_firestore`
  alanı + bir `CloudStateStore`) barındırıyorsa, enjekte edilen `firestore` parametresi HER İKİSİNE
  de (ayrı ayrı) geçirilmeli — birini unutmak yalnızca O bileşenin testte "gerçek Firebase'e
  ulaşmaya çalışıp çökme" riskini taşır. **Toplam: 324 test.**
- **Doğrulandı (2026-08-28):** kullanıcı güncel `firestore.rules` içeriğini (bu güncellemeyle
  eklenen `referralRedemptions` bloğu dahil) Firebase Console > Firestore Database > Rules'a
  yapıştırıp yayınladı — bu blok eklenmeden davet kodu gönderme adımı `PERMISSION_DENIED` ile
  SESSİZCE başarısız olurdu (`CloudStateStore`/`ReferralProvider`'ın try/catch'i hatayı yutuyordu).
  **Gotcha (canlı yaşandı):** kullanıcı ilk denemede yeni kuralları eski içeriğin ALTINA
  yapıştırdı — dosyada iki `rules_version`/`service cloud.firestore {}` bloğu oluşup editör hata
  işaretledi; düzeltme `Ctrl+A` ile TÜM içeriği silip yalnızca YENİ bloğu yapıştırmaktı (Firebase
  Console'un rules editörü bir "üzerine ekleme" değil "TAMAMEN değiştirme" bekliyor — bu ders
  gelecekteki rules güncellemeleri için de geçerli). Ardından `gh workflow run
  process-referral-rewards.yml -f dry_run=true` ile GitHub Actions'tan elle tetiklenip log'u
  kontrol edildi: betik hatasız çalıştı (`Başlıyor — DRY_RUN=true` → `0 bekleyen davet kaydı
  bulundu.` → `Bitti — 0 davet kredilenecekti...`) — "0 bekleyen kayıt" BEKLENEN bir sonuç
  (özellik yeni yayınlandı, henüz kimse gerçek bir kod göndermedi), asıl doğrulanan şey betiğin
  Firebase Admin SDK'ya bağlanıp `referralRedemptions` koleksiyonunu hatasız sorgulayabildiği.
  **Hâlâ YAPILMAMIŞ:** gerçek bir uçtan-uca test (iki hesapla kod gönderip `dry_run: false` ile
  tetikleyerek her iki tarafın da coin aldığını Firestore Console'da doğrulamak) — kullanıcı
  isterse ileride yapabilir.

