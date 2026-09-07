# ARŞİV — Kurucu Üye Rozeti, Google Play Billing, Release İmzalama, Crashlytics

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 6828–7429).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

## "Kurucu Üye" Rozeti ([founder_badge.dart](lib/data/founder_badge.dart), [founder_badge_provider.dart](lib/providers/founder_badge_provider.dart), [founder_badge_promo_card.dart](lib/widgets/founder_badge_promo_card.dart), [profile_screen.dart](lib/screens/profile_screen.dart), [settings_screen.dart](lib/screens/settings_screen.dart), workspace kökü [notification-scripts/src/initFounderBadgeCounter.js](../notification-scripts/src/initFounderBadgeCounter.js) + [.github/workflows/init-founder-badge-counter.yml](../.github/workflows/init-founder-badge-counter.yml))

> **Bu bölümün İLK üç bullet'ı (aşağıda) "ilk 500 KAYIT OLAN kullanıcı, bir kerelik elle tetiklenen
> Admin SDK betiği" mimarisini anlatıyor — bu mimari 2026'da TAMAMEN DEĞİŞTİ (bkz. altta "2026
> İKİNCİ güncelleme"), `grantFounderBadges.js`/`grant-founder-badges.yml` SİLİNDİ. Bu bölüm
> SİLİNMEDİ, yalnızca projenin "geçmiş karar + neden değiştiği birlikte kalır" convansiyonuyla
> tarihsel bağlam olarak tutuluyor — `founder_badge` id'si/placeholder görsel/Profil'deki küçük
> simge notları HÂLÂ GEÇERLİ, yalnızca "kim rozeti KAZANIR ve NASIL" kısmı değişti.**

- **2026 yeni özellik.** Kullanıcı isteği: ilk 500 (kullanıcının `AskUserQuestion` ile 100/500
  arasından seçtiği eşik) kayıt olan kullanıcıya özel, satın alınamayan bir "Kurucu Üye" rozeti/
  kostümü ver; şimdilik basit bir placeholder görsel kullanılsın, kullanıcı ilerde kendi tasarımını
  hazırlayınca kodda başka HİÇBİR değişiklik gerekmeden tek bir dosyayı değiştirerek
  güncelleyebilsin; profilde bu rozeti gösteren küçük bir simge olsun.
- **`founder_badge` id'si `costumes.dart`'taki satılabilir listeye BİLEREK EKLENMEDİ** — satın
  alınamasın diye (Mağaza'nın Kostümler ızgarası yalnızca o listeyi dolaşır).
  `CostumeProvider.markOwned('founder_badge')`/`isOwned(...)` gene de SORUNSUZ çalışır çünkü o
  provider zaten satın alma-agnostik (bkz. "Kostümler" bölümü) — yalnızca sahiplik kaydını tutuyor,
  listede olup olmadığını hiç umursamıyor. `lib/data/founder_badge.dart` (YENİ, küçük bir sabitler
  dosyası) `founderBadgeCostumeId`/`founderBadgeImageAsset`'i tek yerde tutuyor.
- **Sıra sinyali — Firestore'da `createdAt` alanı YOK, TEK güvenilir/manipüle-edilemez sinyal
  Firebase Auth'un kendi `metadata.creationTime`'ı** (bkz. `cleanupStaleAnonymousUsers.js`'teki
  AYNI `auth.listUsers()` sayfalama deseni — o betik bunu "son aktivite" için kullanıyor, burada
  "ilk kayıt sırası" için).
- **YENİ, tek seferlik betik** `notification-scripts/src/grantFounderBadges.js` —
  `cleanupStaleAnonymousUsers.js`'in dry-run-varsayılan güvenlik deseniyle BİREBİR aynı: TÜM
  kullanıcıları `creationTime`'a göre sıralayıp ilk `FOUNDER_COUNT` (varsayılan 500, env var ile
  override edilebilir) uid'i alıp her biri için `users/{uid}/state/costumeState.ownedIds` dizisine
  (mevcut belgeyi okuyup) `'founder_badge'` id'sini ekliyor — `CostumeProvider._save()`'in ürettiği
  AYNI JSON şeklini üretiyor, istemci tarafında HİÇBİR özel kod gerekmiyor. **İdempotent** — zaten
  rozeti olan bir kullanıcı atlanır, bu da kullanıcının "ilk 500'ü kilitleme" kararını netleşene
  kadar betiği güvenle birkaç kez dry-run ile deneyebilmesini sağlıyor.
- **YENİ** `.github/workflows/grant-founder-badges.yml` — `cleanup-stale-anonymous-users.yml` ile
  AYNI desen: SADECE `workflow_dispatch` (periyodik DEĞİL, "bir kerelik bakım" kategorisi —
  kullanıcı ilk 500'ü kilitlemeye karar verdiğinde elle bir kez tetikler), `dry_run` girdisi
  VARSAYILAN `true`.
- **Placeholder görsel — `tool/generate_founder_badge_placeholder.dart` (YENİ).** Bu ortamda harici
  görsel üretim aracı yok, ama proje zaten `image` paketini (dev_dependency) `tool/` altında
  tek-seferlik görsel betikleri için kullanıyor (`remove_bg.dart`/`clean_app_icon.dart` emsali) —
  aynı desende, `img.fillCircle`/`img.fillPolygon` ile basit, programatik bir altın/hardal renkli
  (`ZiboShareCard`'ın dokümante edilmiş "Zibo'nun altın tonu" `0xFFF0C868` ile AYNI, palet
  tutarlılığı için) daire + beş köşeli yıldız rozeti çizip `assets/images/founder_badge.png` olarak
  kaydediyor (şeffaf arka plan). `pubspec.yaml` zaten `assets/images/` klasörünü BÜTÜN olarak dahil
  ediyor — ek bir pubspec değişikliği gerekmedi. **Kullanıcı kendi tasarımını hazırladığında
  yalnızca bu dosyanın YERİNE (aynı adla) kendi PNG'sini koyması yeterli — kodda hiçbir değişiklik
  gerekmez.**
- **Profil ekranı — küçük bir simge, TAM bir `_ProfileLinkRow` DEĞİL** (kullanıcının açık isteği
  "profilde bu rozeti gösteren küçük bir simge olsun"). Profil fotoğrafının etrafındaki `Stack`'e
  (mevcut kamera-düzenle rozetinin — `Positioned(right:0, bottom:0)` — KARŞI köşesine,
  `Positioned(left:0, top:0)`) `context.watch<CostumeProvider>().isOwned(founderBadgeCostumeId)`
  ile koşullu, küçük (28×28) bir `Image.asset` + `Tooltip` eklendi. Zibo karakterine giydirilebilir
  bir kostüm olarak DENENMEDİ (kapsam dışı — kullanıcı yalnızca profil simgesi istedi, gerçek poz
  sanatı gelene kadar ek karmaşıklığa gerek yok — bkz. "Zibo Poz/Animasyon Sistemi" bölümü, bu
  rozet o sistemin dışında).
- **Test:** `profile_screen_test.dart`'a bir senaryo eklendi (`CostumeProvider.markOwned
  ('founder_badge')` çağrılmadan ÖNCE rozet YOK, çağrıldıktan SONRA `find.byTooltip('Kurucu Üye')`
  ile görünür) — backend betiği bu ortamda çalıştırılamıyor (diğer tüm Node betikleriyle AYNI
  sınırlama), yalnızca istemci tarafı (rozetin GÖSTERİLMESİ) test edildi. **Toplam: 325 test.**
- **ARTIK GEÇERSİZ — "Kullanıcının YAPMASI gereken adım"** eski hâliyle (elle `grant-founder-
  badges.yml` tetiklemek) artık YOK, bkz. altta "2026 İKİNCİ güncelleme."

### 2026 İKİNCİ güncelleme — rozet artık "ilk 500 KAYIT OLAN"a değil, "Google hesabına bağlanan İLK 500"e, CANLI bir uygulama-içi sayaçla veriliyor

- **Kullanıcı isteği (verbatim özet):** "Kurucu Üye rozetini şuna bağla: ilk 500 kişi Google
  hesabıyla oturum açıp bağlayınca rozet kazansın, uygulama içinde bir sayaç olsun, 500 kişi
  tamamlanınca kapansın ama bilgilendirme olsun — örneğin 'Google hesabını bağla, Kurucu Üye
  rozeti kazan' gibi." İki net karar `AskUserQuestion` ile önceden alındı: (1) saya/teşvik mesajı
  Google satırının HEMEN ÜSTÜNE **ayrı, küçük bir uyarı kartı** olarak konacak (satırın alt metnine
  gömülmek YERİNE — kullanıcının kendi seçimi, "daha dikkat çekici" gerekçesiyle); (2) eski
  `grantFounderBadges.js` betiği DAHA ÖNCE gerçekten çalıştırılmıştı ama kaç kişiye gittiği
  BİLİNMİYORDU — bu yüzden yeni sayacın başlangıç değeri KÖR bir "0'dan başlat" yerine, TÜM
  kullanıcıları tarayıp gerçek sayıyı hesaplayan bir betikle (altta) belirlendi.
- **Mimari değişikliği — bir kerelik Admin SDK betiğinden, CANLI bir Firestore sayacına.** Eski
  mimari "haftalar sonra elle bir kez tetiklenen, TÜM kullanıcı listesini `creationTime`'a göre
  sıralayan" bir batch işlemdi — yeni gereksinim ("Google'a bağlanan İLK 500", ANLIK/canlı bir
  sayaçla) bu modele UYMUYORDU. Çözüm: `founderBadgeStatus/status` adında TEK bir paylaşılan
  Firestore dokümanı (`{count: int}`), [FounderBadgeProvider] tarafından `.snapshots()` ile CANLI
  izleniyor VE bir Firestore **transaction**'ı ile artırılıyor.
  - **Neden Cloud Functions'a (Blaze plan) GEREK KALMADAN atomik — Firestore'un KENDİ optimistic-
    concurrency transaction mekanizması.** `FounderBadgeProvider.claimIfEligible()` bir
    transaction İÇİNDE `count`'u okuyup `< 500` ise `count+1` yazıyor VE AYNI transaction'da
    kullanıcının `costumeState.ownedIds`'ine `founder_badge`'i ekliyor. Firestore SDK'sı AYNI
    dokümana AYNI ANDA gelen İKİ transaction'ı KENDİLİĞİNDEN serileştirip (biri "kazanır", diğeri
    ÇAKIŞMA algılanıp OTOMATİK olarak yeni bir `count` değeriyle RETRY edilir) ikisinin de aynı anda
    `499`'u okuyup ikisinin de `500`'e yazmasını engelliyor — bu proje genelinde "hassas coin/ödül
    mutasyonları Cloud Functions/GitHub Actions'a taşınsın" felsefesinin (bkz. "Coin Ekonomisi
    Güvenliği"/"Davet Et" bölümleri) YERİNE, BU SPESİFİK "ilk N kişi" problemi için Firestore'un
    KENDİ transaction garantisinin YETERLİ olduğu nadir bir durum.
  - **`firestore.rules`'daki `founderBadgeStatus/status` kuralı İKİNCİ, sunucu-taraflı bir savunma
    katmanı** — `count` yalnızca TAM +1 artabilir VE `count < 500` iken yazılabilir, `create`
    BİLEREK `false` (doküman istemcilerce ASLA oluşturulamaz, yalnızca Admin SDK betiğiyle BİR
    KEZ seed edilir). Doküman henüz seed edilmediyse `resource` `null` olacağı için `update` kuralı
    da doğal olarak reddeder — `claimIfEligible()`'ın kendi `!statusSnap.exists` kontrolüyle
    TUTARLI, çift katmanlı bir "henüz hazır değilse sessizce devre dışı kal" garantisi.
  - **`costumeState` yazımı için ayrı bir kural GEREKMEDİ** — mevcut genel `users/{uid}/state/
    {stateDoc}` kuralı (`coinState` HARİÇ tam yetkili) zaten sahibinin kendi `costumeState`'ine
    yazmasına izin veriyor; bu, "kostüm sahiplik listeleri zaten tamamen korumasız" diye ÖNCEDEN
    kabul edilmiş bir riskle (bkz. "Coin Ekonomisi Güvenliği" bölümü) AYNI kategoride — bu özellik
    YENİ bir risk EKLEMİYOR, yalnızca ZATEN var olan güven modelini kullanıyor.
  - **Kabul edilen sınırlama (kod içinde de belgeli):** bu TAM bir sunucu yetkisi DEĞİL — bir mod
    APK teorik olarak GERÇEKTEN Google'a bağlanmadan bu transaction'ı doğrudan tetikleyip bir slot
    "yakabilir". Ama bunun TEK sonucu havuzdan bir slotun boşa gitmesi (griefing), gerçek bir coin/
    ödeme KAYBI DEĞİL — düşük şiddetli, projenin genelindeki risk kabulüyle TUTARLI, üzerine
    ELEŞTİRİLMEDEN kabul edildi.
- **`FounderBadgeProvider`** (YENİ) — `ReferralProvider`'ın AYNI `firestore ?? (uid == null ? null
  : FirebaseFirestore.instance)` test-enjeksiyon deseni. `isLoaded`/`claimedCount`/`remainingSlots`/
  `isSoldOut` getter'ları — `isLoaded == false` iken (uid yok, ağ yok, VEYA doküman henüz seed
  edilmedi) UI HİÇBİR ŞEY göstermez, ne "0/500" ne "500/500" gibi yanıltıcı bir ilk kare.
  - **Kritik doğruluk kararı — `claimIfEligible()`'daki Firestore yazımı, `CostumeProvider`'ın
    bellek-içi state'ini BYPASS EDİYOR, bu yüzden çağıran taraf HEMEN ARDINDAN `CostumeProvider.
    markOwned(founderBadgeCostumeId)`'i de çağırmalı.** `CostumeProvider._save()` HER save'de
    TÜM `costumeState` dokümanının ÜZERİNE YAZIYOR (bkz. `CostumeProvider` dokümantasyonu) — eğer
    transaction'ın Firestore'a doğrudan yazdığı `founder_badge` üyeliği, `CostumeProvider`'ın
    bellek-içi `_ownedIds` listesine hiç YANSITILMAZSA, (a) Profil'deki rozet ikonu uygulama
    yeniden başlamadan GÖRÜNMEZ, VE (b) bir SONRAKİ ilgisiz `CostumeProvider._save()` (ör. başka
    bir kostüm giyme) bu Firestore yazımını SESSİZCE ÜZERİNE YAZIP KAYBEDER. Bu yüzden
    `utils/google_link_action.dart`'taki `handleGoogleLinkTap`, `claimIfEligible()` `true`
    dönerse HEMEN `context.read<CostumeProvider>().markOwned(...)`'ü de çağırıyor — `markOwned`
    idempotent olduğu için (zaten sahipse no-op) bu güvenle her zaman çağrılabilir.
  - **Transaction'ın KENDİSİ, `costumeState` dokümanının VAR OLUP olmadığına göre `tx.update`/
    `tx.set` arasında dallanıyor** (`tx.set(..., merge:true)` KULLANILMADI) — `fake_cloud_
    firestore`'un (bkz. altta test notu) transaction içindeki `set()`'in `SetOptions`'ı SESSİZCE
    YOK SAYDIĞI (tam bir overwrite'a düştüğü) gerçek bir davranış farkı PAKET KAYNAĞI okunarak
    keşfedildi — merge semantiğine HİÇ güvenmemek, doküman yoksa `equippedId: null` içeren TAM bir
    başlangıç dokümanı YAZMAK, doküman VARSA yalnızca `arrayUnion` ile `update` etmek, bu riski
    HEM gerçek Firestore'da HEM test double'ında aynı şekilde ORTADAN KALDIRDI.
- **`FounderBadgePromoCard`** (YENİ, PAYLAŞILAN widget — Profil'in "Zibo ile Bağın" bölümünde VE
  Ayarlar'ın "Genel" kartında AYNI widget kullanılıyor, kod tekrarı yok). Google satırının HEMEN
  ÜSTÜNDE (kullanıcının seçtiği yerleşim); `!isLoaded || isLinked || isSoldOut` iken `SizedBox.
  shrink()` — üç durumun HİÇBİRİNDE yer kaplamıyor. Dokununca AYNI `handleGoogleLinkTap(context)`'i
  çağırıyor (Google satırıyla BİREBİR aynı akış).
- **`handleGoogleLinkTap` — Kurucu Üye denemesi YALNIZCA "yeni/ilk kez bağlama" dalında.**
  [handleSwitchAccountTap]/`_offerSignInInstead`'in "MEVCUT bir hesabı KURTARMA" akışları BİLEREK
  DIŞARIDA — o hesap ya zaten rozete sahip ya da bağlandığı anda kontenjan doluydu, ikisi de o
  akışlarda tekrar denenecek bir şey değil. Başarı SnackBar'ı `wonFounderBadge` durumuna göre
  `googleLinkSuccessMessage` + (kazanıldıysa) `founderBadgeClaimedMessage`'ı BİRLEŞTİRİYOR.
- **Sıra sinyali artık `creationTime` DEĞİL** — canlı sayaç, Firestore transaction'ının kendi
  serileştirme sırasını kullanıyor (kim ÖNCE transaction'ı BAŞARIYLA COMMIT ederse o kazanıyor).
- **YENİ, tek seferlik betik** `notification-scripts/src/initFounderBadgeCounter.js` — ESKİ
  `grantFounderBadges.js`'in (bkz. yukarıdaki tarihsel bölüm) YERİNE geçti, TAMAMEN SİLİNDİ. Bu
  betiğin işi ARTIK rozet VERMEK değil, yeni sayacı DOĞRU başlangıç değeriyle SEED ETMEK: TÜM
  kullanıcıları (`auth.listUsers()`) tarayıp `costumeState.ownedIds` içinde `founder_badge`
  arayarak GERÇEK sayıyı (eski betiğin DAHA ÖNCE kaç kişiye rozet vermiş OLABİLECEĞİni, kullanıcının
  kendisi de tam hatırlamıyordu) hesaplıyor, `founderBadgeStatus/status`'a `{count: N}` yazıyor.
  `cleanupStaleAnonymousUsers.js` ile AYNI dry-run-varsayılan güvenlik deseni +
  **`founderBadgeStatus/status` ZATEN VARSA (canlıya alınıp gerçek kullanıcı bağlamalarıyla
  ilerliyor olabilir) `FORCE=true` AÇIKÇA verilmedikçe ÜZERİNE YAZILMAZ** — canlı bir sayacı
  yanlışlıkla sıfırlama riskine karşı ek bir güvenlik ağı.
- **YENİ** `.github/workflows/init-founder-badge-counter.yml` — `grant-founder-badges.yml`'in
  YERİNE geçti, TAMAMEN SİLİNDİ. AYNI desen: SADECE `workflow_dispatch`, `dry_run` VARSAYILAN
  `true`, ARTIK bir de `force` girdisi var (VARSAYILAN `false`).
- **Test:** YENİ `test/founder_badge_provider_test.dart` (8 test, `fake_cloud_firestore` ile —
  `referral_provider_test.dart`'taki AYNI desen): uid yokken/sayaç seed edilmeden özellik devre
  dışı, canlı sayaç dışarıdan değişince günceller, kontenjan doluyken kazanılamaz VE sayaç
  DEĞİŞMEZ, başarılı kazanımda sayaç +1 artar VE `ownedIds`'e eklenir, VAR OLAN `equippedId`
  KORUNUR [transaction'ın `set`/`update` dallanmasının doğru çalıştığının kanıtı], zaten sahip olan
  bir kullanıcı ikinci kez sayacı artırmaz [idempotent], `isClaiming` doğru geçiş yapar. `profile_
  screen_test.dart`/`settings_screen_test.dart`/`widget_test.dart`'ın `_buildAppWithClock()`'una
  `FounderBadgeProvider` eklendi (`RootScreen`'in/`ProfileScreen`'in/`SettingsScreen`'in ihtiyaç
  duyduğu HER provider kuralı, bkz. "Test kalıpları" bölümü). `flutter test` tam yeşil: **408
  test** (407 geçti + 1 önceden belgelenmiş, bu değişiklikle İLGİSİZ `audioplayers` flake'i —
  `git stash` ile ÖNCEKİ commit'e dönülüp AYNI testin AYNI şekilde başarısız olduğu doğrulandı).
- **Kullanıcının Firebase Console/GitHub Actions'ta tamamlaması gereken adımlar** (asistan yapamaz
  — Console/production Firestore erişimi gerektiriyor):
  1. Güncel `firestore.rules` içeriğini (bu turda eklenen `founderBadgeStatus/status` bloğu dahil)
     Firebase Console > Firestore Database > Rules'a yapıştırıp yayınlamak (bkz. "Firestore veri
     kalıcılığı" bölümündeki AYNI "editör TAMAMEN değiştirme bekliyor, üzerine EKLEME değil" notu).
  2. GitHub Actions'tan `init-founder-badge-counter.yml`'i ÖNCE `dry_run: true` ile tetikleyip
     log'da kaç kullanıcının eski betikten kalma `founder_badge`'e ZATEN sahip olduğunu gözden
     geçirmek, sonra `dry_run: false` ile TEKRAR tetikleyip `founderBadgeStatus/status`'u GERÇEKTEN
     seed etmek — bu adım tamamlanmadan `FounderBadgeProvider.isLoaded` HİÇBİR ZAMAN `true` OLMAZ,
     teşvik kartı hiç GÖRÜNMEZ (sessiz/güvenli bir "henüz hazır değil" durumu, kod tarafında ek bir
     şey GEREKMEZ).
  3. Gerçek cihazda: bir Google hesabına İLK KEZ bağlanıp hem başarı mesajının "🏅 Kurucu Üye
     rozetini kazandın!" ekini GERÇEKTEN gösterdiğini HEM Profil'deki rozet ikonunun ANINDA
     (uygulama yeniden başlamadan) belirdiğini doğrulamak — bu turda YALNIZCA `flutter test`/
     `flutter build apk --debug` ile doğrulandı, gerçek Google kimlik doğrulaması + canlı Firestore
     transaction'ı bu ortamda test EDİLEMEDİ.

### 2026 — sayaç seed edildikten SONRA bulunan iki gerçek düzeltme: eksik Firestore kuralı + "zaten bağlı hesap" kazanma fırsatı hiç bulamıyordu

- **1) Kart hiç görünmüyordu — `founderBadgeStatus/status` kuralı Firestore
  Console'a hiç YAYINLANMAMIŞTI.** Seed betiği (yukarıdaki 2. adım) sorunsuz
  çalıştı (Admin SDK kuralları atlıyor), ama uygulamanın kendisi (normal bir
  kullanıcı olarak) dokümanı okuyamıyordu — cihazın canlı `adb logcat`'inde
  KANITLANDI: `Firestore: Listen for founderBadgeStatus/status failed:
  Status{code=PERMISSION_DENIED, ...}`. Kullanıcı güncel `firestore.rules`
  içeriğini Console'a yapıştırıp yayınladı. **Firestore'un bir dinleyicisi
  `PERMISSION_DENIED` hatasından sonra KENDİLİĞİNDEN yeniden denemiyor** —
  kurallar yayınlandıktan SONRA bile uygulamanın (`force-stop` + yeniden
  açma ile) YENİDEN BAŞLATILMASI gerekti, ancak o zaman kart doğru
  mesaj/kalan kontenjanla ("500 hak kaldı!") göründü.
- **2) Gerçek bug — kullanıcı Google hesabını bağladı ama rozet hâlâ
  görünmedi.** Cihazın canlı logunda kanıt bulundu:
  ```
  GoogleAuthService._authenticate authenticate() OK: email=cvntann@gmail.com...
  GoogleAuthService.linkCurrentUser linkWithCredential FirebaseAuthException:
    code=credential-already-in-use message=This credential is already
    associated with a different user account.
  ```
  **Kök neden:** bu Google hesabı bu cihazda ÇOK DAHA ÖNCE (Google Hesap
  Bağlama özelliği geliştirilirken/test edilirken, Kurucu Üye rozeti
  var olmadan ÖNCE) BAŞKA bir Firebase kullanıcısına ZATEN bağlanmıştı. Bu
  yüzden "bağla"ya her basıldığında `linkCurrentUser()` DEĞİL,
  `credential-already-in-use` → "zaten bağlı, o hesaba GEÇMEK ister misin?"
  → `_offerSignInInstead`/`signInWithGoogle` akışına düşüyordu.
  `google_link_action.dart`'ın kendi dokümantasyonu BİLEREK bu akışlara
  `FounderBadgeProvider.claimIfEligible()` EKLEMEMİŞTİ ("o hesap ya zaten
  rozete sahip ya da bağlandığı anda kontenjan doluydu, tekrar denenecek
  bir şey yok" varsayımıyla) — ama bu varsayım TAM OLARAK bu senaryoda
  YANLIŞ: hesap, sayaç HENÜZ SEED EDİLMEDEN ÖNCE bağlanmıştı, bu yüzden
  o zamanki (varsa) claim denemesi sessizce başarısız olmuştu, VE bu hesap
  ARTIK bir daha ASLA "yeni/ilk kez bağlama" dalına düşmeyeceği için
  (`credential-already-in-use` HER ZAMAN "geç" akışına yönlendiriyor)
  tekrar deneme fırsatı hiç yoktu — kalıcı olarak sıkışmıştı.
  - **Düzeltme — üç ayrı çağrı sitesine (fresh link/"geç"/"Hesap
    Değiştir") elle claim eklemek YERİNE, `RootScreen`'e `AppStreakProvider`/
    `ReferralProvider` ile AYNI "reconcile-on-resume" deseni eklendi.**
    YENİ [founder_badge_reconcile.dart](lib/utils/founder_badge_reconcile.dart) —
    `maybeClaimFounderBadge({authLink, costume, founderBadge})` saf/test
    edilebilir bir üst düzey fonksiyon (RootScreen'in tam widget ağacını
    kurmadan doğrudan test edilebilsin diye, `HomeWidgetSyncCoordinator`/
    `BadgeCoordinator`'ın "provider'ları parametre olarak al" felsefesiyle
    AYNI): `authLink.isLinked` DEĞİLSE VEYA `costume` zaten `founder_badge`'e
    sahipse hiçbir şey yapmadan çıkar (gereksiz bir Firestore transaction'ı
    önlüyor), aksi halde `claimIfEligible()`'ı sessizce (idempotent,
    zararsız) yeniden dener.
    - **`RootScreen`'in `initState`'indeki MEVCUT postFrameCallback'e VE
      `didChangeAppLifecycleState`'in `resumed` dalına** (AppStreakProvider.
      recordOpenForToday()/ReferralProvider.refresh() ile AYNI iki
      tetikleme noktası) `_maybeClaimFounderBadge()` eklendi — uygulama HER
      açılışta/öne gelişte, Google'a bağlıysa VE rozet henüz sahip
      DEĞİLSE tekrar dener. **Neden burası (üç ayrı `google_link_action.dart`
      çağrı sitesi DEĞİL) doğru yer:** `RootScreen` HER ZAMAN o anki
      (doğru) uid'e bağlı TAZE provider örnekleriyle çalışıyor — bir uid
      DEĞİŞİMİ (Hesap Değiştir/"geç" akışı) `main.dart`'taki `_AppRoot`'un
      `KeyedSubtree`'sinin TÜM `RootScreen` ağacını YENİDEN kurmasını
      gerektiriyor (bkz. "Google Hesap Bağlama" bölümü), bu yüzden
      `RootScreen`'in `context.read<...>()`'i asla ESKİ/yanlış uid'in
      provider'larına yanlışlıkla bağlanamıyor — üç ayrı akışa elle
      eklemek bu garantiyi TEK TEK yeniden inşa etmeyi gerektirirdi.
  - **Test:** YENİ `test/founder_badge_reconcile_test.dart` (4 test,
    `fake_cloud_firestore` ile) — bağlı DEĞİLKEN no-op, sayaç henüz seed
    edilmediyse sessizce başarısız, ZATEN sahipken `claimIfEligible()`
    GEREKSİZ yere ÇAĞRILMIYOR (sayaç dolu olsa bile — erken çıkışın
    KANITI), VE en kritik senaryo: sayaç seed EDİLMEDEN ÖNCE bağlanmış bir
    hesap, sayaç SONRADAN seed edilip bu fonksiyon TEKRAR çağrılınca
    rozeti GERÇEKTEN kazanıyor (bu test DÜZELTMEDEN ÖNCEKİ mimaride hiç
    YAZILAMAZDI — o mimaride bu senaryoyu tetikleyecek hiçbir çağrı yolu
    yoktu). `flutter test` tam yeşil (538/539, yalnızca önceden belgelenmiş
    `audioplayers`/`home_widget` flake'i).
  - **Doğrulama — gerçek cihazda, canlı `adb logcat` ile İKİ AYRI bug için
    de kanıt toplanarak.** APK yeniden derlenip cihaza kuruldu (kullanıcı o
    an başka bir uygulamayla meşgulken sessizce, sonra kendi zamanlamasında
    kontrol edildi). **Kullanıcının kendi cihazında son adımı doğrulaması
    gereken:** uygulamayı bir sonraki açışta/öne getirişte (Google hesabı
    zaten bağlı olduğu için ekstra bir tıklama GEREKMİYOR — düzeltme
    otomatik/arka planda tetikleniyor) Profil ekranındaki fotoğrafın
    köşesinde küçük Kurucu Üye rozeti ikonunun GERÇEKTEN belirdiğini
    görmek.

## Google Play Billing (IAP) Entegrasyonu ([purchase_service.dart](lib/services/purchase_service.dart), [iap_purchase_service.dart](lib/services/iap_purchase_service.dart))

- **2026 — kullanıcı isteği: "gerçek pay billingle devam edelim."** Crashlytics'in HEMEN ardından
  ele alınan üçüncü Faz 1 maddesi — `MockPurchaseService` (600ms gecikmeyle her zaman başarı dönen
  sahte) yerine gerçek `in_app_purchase: ^3.3.0` paketi bağlandı. Uygulamada TEK bir satın alma
  türü var: 5 `coinPackages` (`coins_100`/`coins_250`/`coins_500`/`coins_1000`/`coins_10000`, bkz.
  `coin_packages.dart`) — hepsi Play Console'da **TÜKETİLEBİLİR (consumable)** ürün olarak
  tanımlanmalı, `CoinPackage.id` BİREBİR Play Console'daki ürün id'siyle eşleşiyor (id'ler zaten bu
  amaçla uygun bir adlandırmayla yazılmıştı — ek bir eşleme tablosu gerekmedi).
- **Mimari — basit istek/yanıt sözleşmesi ile `in_app_purchase`'ın stream-tabanlı API'si arasında
  köprü.** `PurchaseService.purchaseCoinPackage(package)` hâlâ `Future<bool>` döndüren tek bir
  metot (`AdService.showRewardedAd()` ile AYNI basitlik) — ama Play Billing'in gerçek API'si
  `buyConsumable()` (satın almayı BAŞLATIR, hemen dönmez) + ayrı bir `purchaseStream` (sonucun
  ASENKRON olarak geldiği yer) ikilisinden oluşuyor. `InAppPurchasePurchaseService`, constructor'da
  `purchaseStream`'i BİR KEZ dinlemeye başlıyor; `_pending` (`Map<String, Completer<bool>>`) o an
  AKTİF bir `purchaseCoinPackage()` çağrısının hangi ürün id'sini beklediğini tutuyor —
  `purchaseStream`'den gelen her olay bu haritada eşleşen bir `Completer`'ı bulup tamamlıyor.
  - **`buyConsumable(autoConsume: true)`** kullanılıyor — Android'de bu, satın alma başarılı
    olduğunda native tarafın `consumeAsync`'i OTOMATİK çağırmasını sağlıyor (elle
    `InAppPurchaseAndroidPlatformAddition.consumePurchase()` çağırmaya GEREK KALMADI) — coin
    paketleri gerçek anlamda tüketilebilir olduğu (aynı ürün SINIRSIZ kez satın alınabilmeli) için
    doğru seçim.
  - **`completePurchase(purchase)`** her `pendingCompletePurchase == true` olan olayda (yalnızca
    başarılı değil, HATA/iptal dahil TÜM sonlanmış durumlarda) çağrılıyor — resmi `in_app_purchase`
    örneğindeki AYNI desen; bu, Dart-taraflı plugin state'ini "işlem bitti" olarak işaretliyor.
- **Orphaned purchase (yetim satın alma) — gerçek bir "para alındı, ürün verilmedi" riskini kapatan
  ek bir katman.** `buyConsumable()` başlatıldıktan SONRA ama `purchaseStream`'in `purchased`
  olayı BU SERVİSE ulaşmadan ÖNCE uygulama çökerse/kapanırsa, ödeme Google'da GERÇEKLEŞMİŞ ama coin
  hiç teslim EDİLMEMİŞ olur. Google Play, tamamlanmamış (henüz `completePurchase` ile
  "acknowledge" edilmemiş) satın almaları BİR SONRAKİ `purchaseStream` dinlemesi başladığında
  (yani bir sonraki uygulama açılışında) OTOMATİK olarak tekrar oynatıyor — bu servis
  constructor'da hemen dinlemeye başladığı için bu "yetim" olayı yakalıyor.
  - **`PurchaseService.orphanedPurchaseProductIds` (YENİ, `Stream<String>`, varsayılan boş
    stream)** — `_onPurchaseUpdate`'te eşleşen bir `Completer` YOKSA (yani bu olay AKTİF bir
    `purchaseCoinPackage()` çağrısından değil, bir önceki oturumdan kalan bir replay'den geliyorsa)
    olay buraya yayınlanıyor.
  - **`CoinProvider`, constructor'da bu stream'i doğrudan dinliyor** (`_orphanedPurchaseSub`,
    `dispose()`'ta iptal ediliyor) — `_onOrphanedPurchase(productId)` `coinPackages`'ta (veri
    dosyası) eşleşen paketi bulup coin'i GEÇ de olsa teslim ediyor
    (`playRewardSound: false` + kendi `playCoinPurchase()` sesi, normal satın almayla AYNI
    ses/işlem-geçmişi deseni). **Bu katman `PurchaseService` arayüzüne eklendiği için** —
    `CoinProvider`'ın `create` callback'i `main.dart`'ta değişmeden kaldı, yalnızca servisin
    KENDİSİ (`InAppPurchasePurchaseService`) bu stream'i gerçek anlamda doldurur, `MockPurchaseService`
    varsayılan (boş) implementasyonu miras alır — testler etkilenmedi.
- **Canlı fiyat gösterimi — `CoinPackage.price` (sabit/görsel TRY fiyatı) artık YALNIZCA bir
  YEDEK.** `PurchaseService.queryLocalizedPrice(package)` (YENİ, varsayılan `null` döner) Play
  Store'dan ÜRÜNÜN GERÇEK, platformun kendi para birimi/bölge/vergi biçimlendirmesiyle
  hazırladığı fiyat metnini (`ProductDetails.price` — ASLA elle inşa EDİLMEMİŞ, Play politikası
  gereği fiyatlar her zaman mağazanın kendi biçimlendirmesiyle gösterilmeli) sorguluyor.
  `CoinProvider.queryLocalizedPrice()` bu servise ince bir passthrough. `_PackageCardState`
  (`store_screen.dart`) `initState`'te bunu sessizce (yükleniyor göstergesi YOK) sorgulayıp
  `_livePrice` state alanına yazıyor; buton metni `_livePrice ?? package.price?.formatted ??
  l10n.storeBuyButton` — mağaza henüz kullanılamıyorsa (emülatör, ürün Play Console'da henüz
  AKTİF değil, ağ yok, `MockPurchaseService` testte) sessizce sabit fiyata düşülüyor, HİÇBİR görsel
  fark YOK.
- **Satın alma başarısızlığında artık bir SnackBar gösteriliyor** (`storePurchaseFailedMessage`,
  TR/EN/ES) — `MockPurchaseService` HER ZAMAN başarılı döndüğü için eskiden bu dal hiç
  ÇALIŞMIYORDU/görünmüyordu; gerçek bir mağaza ile iptal/hata/"ürün henüz aktif değil" YAYGIN bir
  senaryo, kullanıcı butona basıp hiçbir şey olmadığını görmemeli.
- **Test gotcha'sı (gerçekten yaşandı) — `const DijitalKankaApp()` artık GERÇEK
  `InAppPurchasePurchaseService`'i kullanıyor, `AdMobAdService` geçişindeki AYNI riski taşıyor.**
  `main.dart`'a `purchaseService: purchaseService ?? InAppPurchasePurchaseService()` eklenince,
  bunu AÇIKÇA override ETMEYEN `const DijitalKankaApp()` çağrıları artık `CoinProvider`'ın KENDİ
  varsayılanı (`const MockPurchaseService()`) yerine GERÇEK servisi alıyor — "Mağazadan paket
  satın alınca bakiye artar" testi bu yüzden `pumpAndSettle timed out` ile BAŞARISIZ oldu
  (platform kanalına dokunan `_iap.isAvailable()` `flutter_test`/Windows ortamında hiçbir zaman
  tamamlanmıyor). **Çözüm — `AdMobAdService` geçişindeki AYNI desen:** satın alma akışının
  KENDİSİNİ doğrudan test eden bu TEK senaryo `DijitalKankaApp(purchaseService: const
  MockPurchaseService())` kullanacak şekilde güncellendi; diğer testler (yalnızca Mağaza'yı açıp
  kartları gören, satın almayan) etkilenmedi çünkü `queryLocalizedPrice` her yerde try/catch'li
  (mağaza kullanılamıyorsa sessizce `null`). **Ders (tekrar):** bir servisin `main.dart`'taki
  varsayılanı Mock'tan gerçek bir platform-kanalı implementasyonuna geçirilirken, o servisi
  DOĞRUDAN egzersiz eden HER mevcut widget testi gözden geçirilip gerekiyorsa Mock enjekte etmeye
  çevrilmeli.
- **`InAppPurchasePurchaseService.purchaseCoinPackage()`'ın TÜM gövdesi tek bir try/catch'e
  sarılı** (`AdMobAdService`'in `RewardedAd.load(...)` fire-and-forget gotcha'sıyla AYNI
  gerekçe — bkz. "AdMob Entegrasyonu" bölümü) — `isAvailable()`/`queryProductDetails()`/
  `buyConsumable()`'ın HERHANGİ biri beklenmedik şekilde fırlatırsa (desteklenmeyen platform,
  mağaza hesabı bağlı değil vb.) istisna DIŞARI SIZMADAN `false` dönüyor.
- **AndroidManifest.xml'e HİÇBİR yeni izin/queries GEREKMEDİ (elle) — ama `com.android.vending.
  BILLING` izni yine de nihai APK'da VAR, düzeltilmiş bir önceki not.** İlk yazımda
  `in_app_purchase_android`'in KENDİ manifest'i boş olduğu için ("modern Billing Library artık bu
  izni gerektirmiyor" diye) yanlış bir sonuca varılmıştı — **bu yanlıştı.** Gerçek release build'in
  BİRLEŞTİRİLMİŞ manifest'i (`build/app/intermediates/merged_manifest/release/
  processReleaseMainManifest/AndroidManifest.xml`) elle incelenince `<uses-permission android:name=
  "com.android.vending.BILLING" />` satırının GERÇEKTEN orada olduğu görüldü — yalnızca
  `in_app_purchase_android`'in İNCE sarmalayıcı manifest'inden DEĞİL, onun bağımlı olduğu Google'ın
  KENDİ `com.android.billingclient:billing` (Play Billing Library çekirdeği) AAR'ından Gradle
  manifest merge ile geliyor. **Sonuç DEĞİŞMEDİ** (elle bir şey eklemeye gerek YOK, izin zaten
  otomatik geliyor) ama GEREKÇE yanlış yazılmıştı — düzeltildi. **Ders:** bir plugin'in kendi ince
  sarmalayıcı paketinin (`in_app_purchase_android` gibi) manifest'ini incelemek yeterli değil,
  asıl kanıt her zaman GERÇEK BİRLEŞTİRİLMİŞ (merged) manifest — `build/<module>/intermediates/
  merged_manifest/<variant>/.../AndroidManifest.xml` — bir bağımlılığın transitif olarak neler
  eklediğini gösterir, tek bir paketin kendi manifest dosyasına bakmak yanıltıcı olabilir.
  - **Bu, Play Console'un "Uygulamanızda henüz tek seferlik ürün yok... APK'nıza FATURALANDIRMA
    izni eklemeniz gerekir" mesajının NEDEN yanıltıcı bir uyarı olduğunu da açıklıyor** —
    kullanıcı bu mesajı henüz HİÇ bir sürüm yüklemeden gördü; Play Console bu izni ARAMAK için
    kontrol edecek bir binary bulamadığı için genel bir "gerekiyor" mesajı gösteriyor, bizim
    build'imizde eksik olduğu için DEĞİL. İlk `.aab` bir test track'ine (Internal testing)
    yüklenince bu uyarı kaybolup "Uygulama içi ürün ekle" akışı açılmalı.
- **YAPILMASI GEREKENLER — bu KRİTİK bir açık güvenlik boşluğu, "Coin Ekonomisi Güvenliği"
  bölümündeki AYNI mimari kısıtlamaya bağlı:** `purchaseStream`'in `PurchaseStatus.purchased`
  olayı TEK BAŞINA yeterli güven kaynağı DEĞİL — bir mod APK bu durumu istemci tarafında sahte
  tetikleyebilir. Gerçek/tam çözüm: istemci satın almayı başlatır → Play Store makbuzu
  (`PurchaseDetails.verificationData`) döner → istemci bu makbuzu bir Cloud Function'a gönderir →
  Function, Google Play Developer API (`purchases.products.get`) ile makbuzun GERÇEKTEN GEÇERLİ ve
  BU UYGULAMAYA ait olduğunu doğrular → yalnızca DOĞRULANMIŞSA Function Admin SDK ile
  `coinState`'i (rules'u bypass ederek) günceller — İSTEMCİ ARTIK coin EKLEMEZ. Bu, kullanıcının
  henüz vermediği Blaze plan kararını gerektiriyor (bkz. "Coin Ekonomisi Güvenliği" bölümündeki
  aynı karar noktası) — şimdilik istemci-taraflı doğrulamayla devam ediliyor, launch ÖNCESİ (özellikle
  paket fiyatları yükseldikçe/gerçek kullanıcı trafiği başladıkça) ele alınmalı.
- **2026-08-21 güncellemesi — kullanıcının Play Console tarafındaki ön koşulların ÇOĞU
  TAMAMLANDI.** Bkz. "Release İmzalama" bölümündeki "Play Console'da uygulama oluşturma" notu —
  aynı oturumda hem uygulama hem ürünler hem ilk test sürümü kuruldu:
  1. **5 tüketilebilir ürün OLUŞTURULDU** — Play Console > Google Play ile para kazanın > Ürünler
     > **"Tek seferlik ürünler"** (Play Console'un YENİ arayüzde "Yönetilen ürünler"e verdiği isim)
     altında `coins_100`/`coins_250`/`coins_500`/`coins_1000`/`coins_10000` oluşturuldu, fiyatları
     `coin_packages.dart`'taki sabit değerlerle eşleşecek şekilde (100 ZC → 19,99 ₺, 250 ZC →
     44,99 ₺, 500 ZC → 84,99 ₺, 1000 ZC → 159,99 ₺, 10000 ZC → 1.499,99 ₺) girildi.
     - **Yeni öğrenilen bir Play Console gotcha'sı — her ürünün İKİ AYRI kimliği var, farklı
       karakter kısıtlamalarıyla.** "Ürün Kimliği" (Product ID, `coin_packages.dart`'taki
       `CoinPackage.id` ile BİREBİR eşleşmeli — `coins_100` gibi, alt çizgiye izin veriyor,
       oluşturulduktan sonra DEĞİŞTİRİLEMEZ) TAMAMEN AYRI bir alan; 2. adımda ("Kullanılabilirlik
       ve fiyatlandırma") ayrıca bir **"Satın alma seçeneği kimliği"** (Purchase option ID)
       istiyor — bu alan **alt çizgiye İZİN VERMİYOR, yalnızca tire (-)** kabul ediyor, bu yüzden
       `coins-100` gibi tire'li bir varyant kullanıldı. `in_app_purchase` paketinin
       `queryProductDetails()`/`buyConsumable()` çağrıları YALNIZCA "Ürün Kimliği"ni (alt çizgili
       olanı) kullanıyor — "Satın alma seçeneği kimliği" yalnızca Play Console'un kendi iç
       organizasyonu için, kodda hiçbir yerde referans EDİLMİYOR, bu yüzden hangi tire'li ismi
       seçtiğinin (`coins-100` vb.) fonksiyonel bir önemi YOK.
     - **Fiyat girişi — ülke bazlı dev bir tabloya düşüyor, ama TEK bir temel fiyat girip
       otomatik doldurmak yeterli.** Türkiye için girilen `19,99 ₺` temel fiyat, listede
       `TRY 23,99` olarak göründü — bu bir hata DEĞİL, Türkiye'nin %20 KDV'sini dahil eden
       vergi-dahil PERAKENDE fiyatı (`19,99 × 1,20 ≈ 23,99`), Play Console'un kendi standart
       davranışı.
  2. **Play Console'da "ZiboDk" hesabı altında uygulama OLUŞTURULDU** (Kişisel hesap, Hesap
     Kimliği `7407892887987832616`) — Uygulama adı "Zibo", Ücretsiz + IAP, Türkçe varsayılan dil.
     **Ödeme profili DOLDURULDU** (İşletme adı, adres, banka hesabı) — doğrulama BEKLENİYOR,
     kesinleşmesi biraz sürebilir.
  3. **İlk sürüm Internal testing'e YÜKLENDİ.** `pubspec.yaml`'daki sürüm `1.0.0+1` → `1.0.0+2`'ye
     artırıldı (ilk yüklemede "1 sürüm kodu daha önce kullanıldı" hatası alındı — muhtemelen daha
     önce başarısız/boş bırakılan bir taslak sürüm zaten `versionCode 1`'i "kullanılmış" olarak
     işaretlemişti, bkz. "Sürüm numarası stratejisi"ndeki genel kural) — `flutter build appbundle
     --release` ile yeniden derlenip `app-release.aab` (versionCode 2, versionName 1.0.0) Internal
     testing kanalına yüklendi, "Dahili test kullanıcıları tarafından kullanılabilir" durumuna
     geçti. **Test kullanıcısı ekleme adımı (kendi Google hesabını "Test kullanıcıları" sekmesine
     ekleme) bu oturumda TAMAMLANDIĞI DOĞRULANMADI** — bir sonraki oturumda kontrol edilmeli.
  - **HÂLÂ AÇIK — gerçek uçtan uca satın alma testi bu oturumda YAPILAMADI**, çünkü (a) test
    kullanıcısı eklemenin tamamlandığı teyit edilmedi, (b) ödeme profili doğrulaması bekleniyor —
    ikisi tamamlanmadan Play Store gerçek bir satın alma akışını göstermez. Bir sonraki oturumda
    önce bu ikisinin durumu kontrol edilmeli.
  - `flutter test` (279/279), `flutter build apk --release` VE `flutter build appbundle --release`
    sorunsuz derlendi, gerçek cihazda kurulup çöküş olmadan açıldığı doğrulandı.

## Release İmzalama / Play Store Yayın Hazırlığı ([android/app/build.gradle.kts](android/app/build.gradle.kts))

- **2026 — kullanıcının Play Console hesabı doğrulandı, "Teknik Yayın Hazırlığı" fazına
  başlandı.** İlk somut adım: uygulama o ana kadar (Flutter'ın kendi varsayılan şablonu) release
  build'lerini bile DEBUG anahtarıyla imzalıyordu (`signingConfig = signingConfigs.getByName
  ("debug")`, `build.gradle.kts`'teki `// TODO: Add your own signing config` yorumuyla açıkça
  işaretliydi) — **Play Store debug-imzalı bir paket kabul ETMEZ**, bu yüzden gerçek bir "upload
  keystore" oluşturup Gradle'a bağlamak, teknik yayın hazırlığının EN TEMEL/engelleyici adımıydı.
- **`android/upload-keystore.jks`** (YENİ) — `keytool -genkeypair` ile üretilen 2048-bit RSA
  anahtar çifti + kendinden imzalı sertifika, `-validity 10000` (~27 yıl, Google'ın Flutter/Android
  dokümantasyonunun ÖNERDİĞİ değer — sertifika süresi Play Console'un kendisini DEĞİL, yalnızca bu
  "upload" anahtarını etkiliyor ama yine de erken dolmasın diye uzun tutuldu). Alias `upload`
  (Google'ın Play App Signing dokümantasyonunda kullandığı KONVANSİYONEL isim). `-dname` alanları
  (`CN=Zibo, OU=Zibo, O=Zibo, L=Istanbul, ST=Istanbul, C=TR`) yalnızca sertifikaya gömülen
  KOZMETİK bilgiler — gerçek bir tescilli şirket kaydı GEREKTİRMİYOR, Play Console/Google bunları
  doğrulamıyor.
  - **KRİTİK — bu dosya + şifreleri KAYBOLURSA/SIZARSA gerçek sonuçlar doğurur.** Google'ın "Play
    App Signing" modeli (yeni uygulamalar için ARTIK ZORUNLU) bu "upload key"i yalnızca Play
    Console'a YÜKLEME kimlik doğrulaması için kullanıyor (Google, kullanıcıya asıl DAĞITILAN
    imzayı KENDİ sunucusunda AYRI bir "app signing key" ile yönetiyor) — yani bu anahtar
    kaybolursa uygulamanın KENDİSİ kaybolmuyor, ama Google Play Console üzerinden bir "upload key
    reset" talebi (destek süreci, günler sürebilir) GEREKİYOR. **Bu dosyayı (`android/upload-
    keystore.jks`) VE `android/key.properties`'teki şifreleri projenin DIŞINDA, güvenli bir yere
    (şifre yöneticisi + ayrı bir bulut yedeği) MUTLAKA yedekleyin** — ikisi de `.gitignore`'a
    eklendi (`*.jks`/`*.keystore`/`/android/key.properties`), yani git geçmişinde YOK ve bu
    makine dışında hiçbir kopyası YOK.
  - **Şifreler** (hem `storePassword` hem `keyPassword` — basitlik için AYNI, tek bir güçlü
    rastgele değer): `ae52084ddffaa01ca779f0ed703eca01` — bu, bu sohbette bir KEZ gösterildi,
    şimdi bir şifre yöneticisine kaydedin. `android/key.properties` dosyasında da (yerel, git'e
    girmeyen) duruyor.
  - **SHA-1/SHA-256 parmak izleri** (Firebase Console'a — Google Sign-In'in RELEASE build'lerde
    de çalışması için — VE varsa Play Console'un "App integrity" bölümüne eklenmesi gereken,
    debug'takinden TAMAMEN FARKLI bir çift, bkz. "Google Hesap Bağlama" bölümündeki DEBUG
    parmak izi notuyla KARIŞTIRMAYIN):
    - SHA-1: `CD:E6:95:44:D1:5A:5D:9E:2C:B6:F4:BC:2B:E5:CD:E6:12:53:44:A3`
    - SHA-256: `1E:5E:9C:F5:AC:00:43:5C:21:74:0E:9E:A8:2F:E3:A5:DB:B3:FD:00:B7:16:87:2C:FD:E0:2E:63:79:7F:00:56`
    **YAPILDI** — kullanıcı Firebase Console'a bu iki parmak izini AÇIKÇA (Console UI'daki "Add
    fingerprint" ile, buradan yalnızca talimat verildi, asistan Console'a erişemez) ekleyip
    `google-services.json`'ı yeniden indirdi; `android/app/google-services.json`'a yeni bir
    `oauth_client` girdisi (`certificate_hash: cde69544d15a5d9e2cb6f4bc2be5cde6125344a3` — yukarıdaki
    release SHA-1'in tire'siz/küçük harfli hâli) olarak yansıdığı diff'te doğrulandı. Release AAB
    bu güncel dosyayla yeniden derlenip imza doğrulaması tekrarlandı.
- **`android/key.properties`** (YENİ, git'e GİRMİYOR) — `storePassword`/`keyPassword`/`keyAlias`/
  `storeFile` (mutlak yol) taşıyor. `build.gradle.kts` bu dosyayı `rootProject.file("key.
  properties")` ile okuyup `signingConfigs.create("release")`'i dolduruyor.
  - **Güvenlik ağı — dosya YOKSA build KIRILMAZ, sessizce debug imzasına düşer.** Bu, CI/başka bir
    makine/klon bu sırrı henüz almadıysa `flutter build`'in en azından ÇALIŞMAYA devam etmesi için
    (gerçek yayın YANLIŞLIKLA bu dala düşmemeli — `flutter build appbundle --release` çalıştırmadan
    ÖNCE `android/key.properties`'in GERÇEKTEN var olduğunu kontrol edin).
- **Doğrulama:** `flutter build appbundle --release` çalıştırılıp imzalamanın GERÇEKTEN release
  keystore'unu kullandığı doğrulandı (bkz. build çıktısı/`bundletool`/`apksigner` ile sertifika
  kontrolü).
- **`android/app/proguard-rules.pro` (YENİ) + `buildTypes.release`'e `isMinifyEnabled = true`/
  `isShrinkResources = true`.** İlk yazımda release build'i (Flutter'ın kendi varsayılan şablonu
  gibi) küçültme AÇIK DEĞİLDİ — `isMinifyEnabled`/`isShrinkResources` hiç ayarlanmamıştı (Android
  Gradle Plugin'in varsayılanı `false`), bu yüzden ilk `app-release.aab` (130MB) hiç R8/kaynak
  küçültmesi görmemişti.
  - **Kritik bağlam (dosyanın kendi başındaki yorumla AYNI, tekrar altı çizilerek):** R8 YALNIZCA
    bu projenin Android/Kotlin/Java katmanını (plugin'lerin native platform-channel köprü kodu +
    Firebase/Google Play Services/AdMob) işliyor — uygulamanın GERÇEK iş mantığı (`CoinProvider`,
    `AuthLinkProvider` vb. TÜM Dart kodu) AOT derleyiciyle ayrı bir `libapp.so`'ya derleniyor ve
    R8'in hiç görmediği bir katman. Yani bu değişikliğin riski yalnızca "native plugin köprüsü"nde,
    uygulamanın kendi Dart mantığında DEĞİL.
  - **`proguard-rules.pro` içeriği bilinçli olarak MİNİMAL** — Flutter'ın kendi embedding
    sınıfları için `-keep`, Play Core için `-dontwarn` (Flutter'ın "deferred components" desteği
    kullanılmasa bile bu sınıflara derleme zamanında referans veriyor), Credential Manager
    (`androidx.credentials.**`) için `-keep`/`-dontwarn`, ve genel reflection/serialization
    meta-verisini koruyan `-keepattributes` satırları. Firebase/AdMob/google_sign_in gibi çoğu
    modern kütüphane KENDİ "consumer proguard rules"ını AAR'ının içinde taşıyor (AGP bunları
    `minifyEnabled` açıkken OTOMATİK birleştiriyor) — bu yüzden buraya HER olası sınıf için elle
    kural eklemek GEREKMEDİ, yalnızca bilinen/sık karşılaşılan boşluklar kapatıldı.
  - **GERÇEK doğrulama derleme BAŞARISI değil — gerçek cihazda test etmek GERÇEKTEN bir çökme
    yakaladı.** `flutter build apk --release` (AAB değil, doğrudan cihaza kurulabilir APK) ile
    derlenip telefona kurulunca uygulama `main()`'e HİÇ ulaşmadan, açılışta çöktü:
    ```
    Unable to get provider androidx.startup.InitializationProvider:
    Failed to create an instance of androidx.work.impl.WorkDatabase
    ```
    **Kök neden:** R8, AndroidX WorkManager'ın Room tabanlı `WorkDatabase`sinin ÜRETİLMİŞ
    (generated) `_Impl` sınıflarını (yalnızca reflection/SPI ile referans edildikleri için R8'in
    statik analizinin GÖREMEDİĞİ sınıflar) silmişti — WorkManager'ı DOĞRUDAN kullanan bir kod
    YAZILMADI, bu bir plugin'in (Firebase Messaging arka plan işleme veya benzeri) TRANSİTİF
    bağımlılığı. **Düzeltme:** `proguard-rules.pro`'ya `androidx.work.**`/`androidx.room.**` için
    kapsamlı `-keep` kuralları eklendi (hangi plugin'in tetiklediğini izole etmek yerine
    WorkManager/Room'un TAMAMI korundu — daha güvenli/kalıcı). Yeniden derlenip telefona kurulunca
    Onboarding ekranı (Zibo logosu, Türkçe metinler/fontlar) sorunsuz render edildi, `pidof` ile
    süreç canlı, logcat'te çökme izi yok. **Bu, bu bölümün başındaki "gerçek doğrulama derleme
    başarısı değil" uyarısının SOMUT kanıtı** — ilk derleme de hatasız TAMAMLANMIŞTI, çökme yalnızca
    cihazda uygulamayı GERÇEKTEN açınca ortaya çıktı.
- **Sürüm numarası stratejisi.** `pubspec.yaml`'daki `version: 1.0.0+1` (`X.Y.Z+N`) zaten
  `android/app/build.gradle.kts`'teki `flutter.versionCode`/`flutter.versionName`'e OTOMATİK
  eşleniyor — mekanizma DEĞİŞMEDİ/EK KOD GEREKMEDİ, yalnızca İZLENECEK POLİTİKA burada
  belgeleniyor:
  - **`+N` (versionCode, `1.0.0+1`'deki `1`) her Play Console'a YÜKLEME'de (internal testing dahil,
    yalnızca production DEĞİL) bir ÖNCEKİ yüklemeden STRIKTLY BÜYÜK olmak ZORUNDA** — Google Play
    bunu TÜM track'ler (internal/closed/open/production) genelinde, SONSUZA kadar takip ediyor;
    aynı `+N` ile İKİNCİ bir yükleme REDDEDİLİR. **Kural: `flutter build appbundle --release`
    çalıştırıp Play Console'a yüklemeden ÖNCE `pubspec.yaml`'daki `+N`'i HER SEFERİNDE artırın**
    (test amaçlı yerel bir derleme için artırmaya gerek YOK, yalnızca GERÇEKTEN Console'a
    yüklenecek bir derleme için).
  - **`X.Y.Z` (versionName, kullanıcıya GÖRÜNEN sürüm) için önerilen kural (standart semver):**
    yalnızca bug fix → `Z`'yi artır (`1.0.1`), yeni özellik → `Y`'yi artır ve `Z`'yi sıfırla
    (`1.1.0`), büyük/köklü bir değişiklik → `X`'i artır (`2.0.0`). İlk yayın için `1.0.0` zaten
    doğru/olduğu gibi kalabilir.
- **Sonraki adımlar (bu liste zamanla eskiyor, en güncel durum için "Google Play Billing (IAP)
  Entegrasyonu" bölümündeki 2026-08-21 notuna bakın):** **Çökme/hata izleme (Crashlytics) ARTIK
  KURULU**, **gerçek Google Play Billing ARTIK BAĞLI** (bkz. "Google Play Billing" bölümü — 5
  ürün Play Console'da oluşturuldu, ilk Internal testing sürümü yüklendi), **Play Console'da
  uygulama oluşturuldu + ödeme profili dolduruldu** (doğrulama bekleniyor). **HÂLÂ AÇIK:** Gizlilik
  Politikası/Kullanım Koşulları'nın yer tutucu metinden gerçek içeriğe geçmesi (bir URL'de
  yayınlanması gerekiyor), Play Console'daki mağaza listeleme/içerik derecelendirme/veri güvenliği
  formları, test kullanıcısı eklemenin tamamlandığının doğrulanması, farklı cihaz/Android
  sürümünde test, ve AYRICA **2026-08-21'de ortaya çıkan yeni bir engel: AdMob hesabı devre dışı
  bırakıldı, itiraz sonucu bekleniyor** (bkz. "AdMob Entegrasyonu" bölümündeki "AdMob/AdSense
  hesabı devre dışı bırakıldı" notu) — reklam geliri bu netleşene kadar askıda, ama Play Billing
  (coin satışları) bundan bağımsız çalışmaya devam ediyor.

## Crashlytics ([main.dart](lib/main.dart), [android/app/build.gradle.kts](android/app/build.gradle.kts), [android/settings.gradle.kts](android/settings.gradle.kts))

- **2026 — kullanıcı isteği: "crashlytics ile devam et."** Release imzalama tamamlandıktan hemen
  sonra ele alınan ikinci Faz 2 maddesi — canlıda bir kullanıcı çökme yaşarsa bunu Play Console'a
  değil doğrudan Firebase Console'a (zaten kurulu olan AYNI Firebase projesi) raporlayan bir
  çökme/hata izleme katmanı.
- **Paket:** `firebase_crashlytics: ^5.2.0` (`flutter pub get` ile `5.2.7`'ye çözüldü). Gradle
  tarafı: `android/settings.gradle.kts`'in `plugins {}` bloğuna `id("com.google.firebase.
  crashlytics") version "3.0.8" apply false` eklendi, `android/app/build.gradle.kts`'in
  `plugins {}` bloğuna (google-services'ten SONRA, `google-services.json`'ı okuyup gerekli
  kaynakları ürettikten sonra Crashlytics'in devreye girmesi için) sürüm belirtmeden
  `id("com.google.firebase.crashlytics")` eklendi.
  - **AGP 9.0 "yeni DSL" gotcha'sı — `firebaseCrashlytics { mappingFileUploadEnabled = true }`
    DSL uzantısı DERLENMİYOR.** İlk denemede bu blok `buildTypes.release`'e eklenince
    `Unresolved reference 'firebaseCrashlytics'`/`Unresolved reference
    'mappingFileUploadEnabled'` hatasıyla derleme BAŞARISIZ oldu. Kök neden: `android.newDsl=true`
    (AGP 9.0'ın varsayılanı, bkz. "Release İmzalama" bölümündeki `proguard-rules.pro`
    dokümantasyonuyla AYNI AGP sürümü) ile Crashlytics Gradle plugin'i (3.0.8) arasındaki bu
    extension-function kayıt biçimi UYUMSUZ. **Çözüm — blok TAMAMEN kaldırıldı**, yerine
    açıklayıcı bir yorum bırakıldı: bu explicit yapılandırmaya hiç gerek YOKTU, çünkü Crashlytics
    Gradle plugin'i `isMinifyEnabled = true` iken (bkz. "Release İmzalama" bölümündeki R8/ProGuard
    notu) mapping dosyasını (obfuscated → gerçek isim eşlemesi, R8 ile küçültülmüş release
    build'lerin stack trace'lerini Firebase Console'da OKUNABİLİR göstermek için) zaten
    VARSAYILAN olarak, her `assembleRelease`/`bundleRelease` SONRASI otomatik yüklüyor.
- **Dart tarafı bağlama — `main.dart`'ın MEVCUT Firebase try/catch bloğunun İÇİNE eklendi**
  (`Firebase.initializeApp()` + Anonymous Auth + `FirebaseAnalytics.instance.logAppOpen()`'dan
  HEMEN SONRA), YENİ bir try/catch AÇILMADI — bu bilinçli: Crashlytics GEREKTİREN global hata
  yakalayıcılar Firebase kullanılamayan bir ortamda (web önizlemesi, `flutter test`, config eksik)
  hiçbir zaman KURULMAMALI, projenin "Firebase'siz de sorunsuz çalışmaya devam et" ilkesiyle
  (bkz. "Şu an mock/placeholder olan şeyler" bölümündeki Firebase notu) tutarlı.
  ```dart
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  ```
  (1) Flutter FRAMEWORK'ünün kendi hata mekanizması (widget build/layout/paint hataları) —
  varsayılan davranış (konsola yazdırıp devam etmek) yerine ARTIK Crashlytics'e de FATAL olarak
  bildiriliyor. (2) Flutter'ın KENDİ hata bölgesinin (error zone) DIŞINDA kalan hatalar (ör.
  yakalanmamış bir `Future` hatası, bir platform kanalı callback'inde fırlatılan istisna) —
  `true` dönmek platformun varsayılan davranışını (uygulamayı sonlandırma) TETİKLEMİYOR,
  Crashlytics'e kaydettikten sonra uygulama MÜMKÜNSE çalışmaya devam ediyor.
- **Doğrulama — gerçek bir zorla-çökme testi, GEÇİCİ bir kod satırıyla yapıldı ve SONRA
  kaldırıldı.** `main()`'e geçici olarak `FirebaseCrashlytics.instance.crash();` eklendi (SDK'nın
  resmi test API'si — gerçek bir native/fatal çökme tetikliyor), release APK derlenip cihaza
  kuruldu:
  1. **İlk açılış → çökme.** `adb shell monkey` ile başlatılınca uygulama ANINDA çöktü
     (beklenen/istenen davranış — bu seferki tek test amacı, önceki oturumlardaki "çökme AVCILIĞI"
     senaryolarının TERSİ). `pidof` süreç bulamadı, doğrulandı.
  2. **İkinci açılış → rapor yükleme.** Uygulama tekrar açılınca (bu arada arka planda bir
     WorkManager/Firebase job'ı da kendiliğinden bir süreç başlatıp aynı yükleme adımını bir kez
     daha tetikledi) logcat'te ÖNCEKİ oturumun çökme kaydının işlendiği (`DigestGenerator`/MiSight
     olay akışında `"CrashType":"...FirebaseCrashlyticsTestCrash"`, `"Stacktrace":"...This is a
     test crash caused by calling .crash() in Dart."`) VE Crashlytics'in GERÇEKTEN bir ağ isteği
     attığı (`TRuntime.CctTransportBackend: Making request to: https://
     crashlyticsreports-pa.googleapis.com/v1/firelog/legacy/batchlog`) doğrulandı — bu, çökme
     raporunun Firebase'in sunucularına GERÇEKTEN ULAŞTIĞININ somut kanıtı.
  3. **Test satırı kaldırıldı.** `FirebaseCrashlytics.instance.crash();` + açıklayıcı yorumu
     `main.dart`'tan SİLİNDİ, `flutter test` (276/276) ile regresyon olmadığı doğrulandı, TEMİZ
     bir release APK yeniden derlenip cihaza kuruldu.
- **Kullanıcının Firebase Console'da doğrulaması gereken:** Console > Crashlytics sekmesinde
  yukarıdaki test çökmesinin (`FirebaseCrashlyticsTestCrash: This is a test crash caused by
  calling .crash() in Dart.`) birkaç dakika içinde bir rapor olarak BELİRMESİ gerekiyor — rapor
  işleme genelde ANINDA değil, kısa bir gecikmeyle Console'a yansıyor.
- **Mapping dosyası (deobfuscation) otomatik yükleniyor** (bkz. yukarıdaki AGP gotcha notu) —
  gerçek bir kullanıcı çökmesi geldiğinde Console'daki stack trace, R8'in obfuscate ettiği
  sınıf/metot adları yerine GERÇEK Dart/Kotlin isimlerini göstermeli; bu henüz gerçek (test
  DIŞI) bir çökmeyle doğrulanmadı, ilk gerçek rapor geldiğinde kontrol edilmeli.

