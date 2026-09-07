# ARŞİV — AdMob geçmişi, AdMob→Appodeal geçişi, Reklam tam ekran bug'ı, Art arda dokunma reklamı

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 5312–5943).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

## AdMob Entegrasyonu (TARİHSEL — bkz. altta "AdMob → Appodeal geçişi", `AdMobAdService`/`admob_ad_service.dart`/`admob_config.dart` artık kod tabanında YOK) ([ad_service.dart](lib/services/ad_service.dart))

> **Bu bölümün TAMAMI, AdMob'un `com.google.android.gms.ads.*` API'lerine dayanan ESKİ
> entegrasyonu anlatıyor — proje 2026'da bu SDK'dan TAMAMEN çıkıp Appodeal'e geçti (bkz. altta
> "AdMob → Appodeal geçişi" alt bölümü, bu H2'nin İÇİNDE). Aşağıdaki `AdMobAdService`/
> `admob_ad_service.dart`/`AdMobConfig`/`admob_config.dart`/`google_mobile_ads` referanslarının
> HİÇBİRİ artık koda karşılık GELMİYOR — bu bölüm, o zamanki kararların/bug düzeltmelerinin
> GEREKÇESİNİ (özellikle "reklam tam ekranı kaplamıyor" gibi genel Android/RemoteViews dersleri
> hâlâ geçerli) kaybetmemek için SİLİNMEDİ, projenin "geçmiş karar + neden değiştiği birlikte
> kalır" convansiyonuyla tutarlı.**

- **2026 yeni özellik — gerçek Google AdMob SDK'sı (`google_mobile_ads: ^9.1.0`) bağlandı.**
  Kullanıcı isteği: "gerçek admob entegrasyonuna geçmeye başlayalım." Uygulamada YALNIZCA TEK bir
  reklam formatı var — ödüllü reklam (rewarded video), `AdService.showRewardedAd()` arayüzünün
  ARKASINDA, iki ayrı akıştan çağrılıyor (`CoinProvider.watchAdAndEarn()` — Mağaza'nın "Ücretsiz"
  kartı, ve `CoinProvider.watchAdAndSpinWheel()` — Şans Çarkı). Banner/interstitial YOK, kapsam
  bilinçli olarak dar (uygulamanın gerçekte ihtiyaç duyduğu TEK format).
  - **YAPILMASI GEREKENLER — mod APK/hile koruması (bkz. "Coin Ekonomisi Güvenliği" bölümü):**
    Şu an `AdMobAdService.showRewardedAd()`'ın `onUserEarnedReward` callback'i TAMAMEN İSTEMCİ
    TARAFINDA değerlendiriliyor — `ServerSideVerificationOptions` (AdMob'un `setServerSideVerificationOptions`
    API'si, `RewardedAd`'a bir `customData` + kullanıcı kimliği geçirip Google'ın ödül olayını
    KENDİ sunucularınıza bir SSV callback URL'i ile doğrulayarak bildirmesini sağlıyor)
    KURULMADI. Gerçek para değeri taşıyan bir ödül miktarına geçilirse (şu anki 20 ZC/çevirme
    başına ödül düşükse risk düşük, ama miktar büyürse veya reklam sıklığı artarsa) AdMob'un
    server-side verification'ına geçilip `notification-scripts/`'teki AYNI Admin SDK + GitHub
    Actions altyapısı (veya bir Cloud Function) kullanılarak SSV callback'in coin'i EKLEMESİ,
    istemcinin `onUserEarnedReward`'unun YALNIZCA bir "UI geri bildirimi" (animasyon/mesaj)
    göstermesi, coin'i KENDİSİ EKLEMEMESİ gerekir.
- **İlk yazımda kullanıcının AdMob hesabı/uygulaması/reklam birimi YOKTU** — bu yüzden kod tarafı
  başlangıçta Google'ın HERKESE AÇIK, hesap gerektirmeyen resmi TEST App ID/Ad Unit ID'siyle
  yazıldı (onay bekleyen bir hesaba bağımlı kalmadan SDK'nın uçtan uca çalıştığını kanıtlamak
  için). **Kullanıcı AYNI oturumda AdMob Console'da hesap açıp "Zibo-Dijital Kankan" uygulamasını
  ve bir Ödüllü Reklam birimini oluşturdu — kod tarafı ANINDA o hesabın GERÇEK ID'lerine
  geçirildi** (App ID `ca-app-pub-7684383909235139~...`, Ad Unit ID `.../2423439155`) —
  **AMA bu hesap SONRADAN TERK EDİLDİ** (bkz. altta "2026 İKİNCİ güncelleme — hesap değişikliği").
- **Doğrulama — yeni oluşturulan bir reklam biriminin "no fill" (kod 3) dönmesi BEKLENEN bir
  durum, hata DEĞİL:** AdMob Console'un kendisi "New ad units may take up to an hour to start
  showing ads" uyarısını gösteriyor; gerçek cihazda APK kurulup açıldığında logcat'te
  `Ads: Ad failed to load : 3` (ERROR_CODE_NO_FILL) görülmesi, App ID/Ad Unit ID'nin DOĞRU
  okunduğunu (aksi halde farklı bir hata kodu — ör. `1`/ERROR_CODE_INVALID_REQUEST — dönerdi) ama
  Google'ın reklam envanterinin bu YENİ birim için henüz hazır olmadığını gösteriyor.
- **2026 İKİNCİ güncelleme — hesap değişikliği: `lib/config/admob_config.dart` config dosyası
  eklendi, gerçek ID'ler koddan ÇIKARILIP test ID'sine geri düşüldü.** Kullanıcı raporu: ilk
  "Zibo-Dijital Kankan" AdMob hesabı **Kuruluş (Organization)** türünde açılmıştı, ödeme profilini
  tamamlarken bir **VAT ID sorunu** çıktı — kullanıcı bu hesabı terk edip yeni bir **Bireysel
  (Individual)** AdMob hesabı açıyor. Kullanıcının isteği: (a) yeni hesaptan tam olarak hangi
  ID'lerin gerekeceği net olsun, (b) bu ID'lerin gireceği yer ÖNCEDEN hazırlansın (tek bir dosya
  doldurup kodun başka hiçbir yerine dokunmadan geçiş yapılabilsin), (c) gerçek bağlantı HENÜZ
  KURULMASIN — yalnızca yapı hazır olsun.
  - **Yeni hesaptan gereken ID'ler — YALNIZCA İKİ tane, uygulamanın kullandığı TEK reklam
    formatına (rewarded) göre:** (1) **App ID** (`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`
    biçiminde, AdMob Console > Uygulamalar > [uygulama] altında), (2) **Ödüllü Reklam birimi Ad
    Unit ID** (`ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` biçiminde, o uygulamanın Reklam Birimleri
    sekmesinde, tür "Rewarded"). Banner/interstitial ID'sine gerek YOK — uygulamada o formatlar
    hiç kullanılmıyor (bkz. yukarıdaki "TEK reklam formatı" notu); ileride eklenirse o zaman
    `admob_config.dart`'a yeni bir alan eklenir.
  - **`lib/config/admob_config.dart`** (YENİ) — `AdMobConfig.rewardedAdUnitId`, tek bir
    `static const`. **Aynı oturumda kullanıcı yeni Bireysel hesabı açıp ID'leri iletti — bu sabit
    ARTIK o hesabın GERÇEK Ad Unit ID'sini taşıyor**, bkz. altta "ÜÇÜNCÜ güncelleme".
  - **KRİTİK sınırlama — App ID bu dosyadan OKUNAMAZ, İKİNCİ bir dosya da gerekiyor:**
    `google_mobile_ads` SDK'sı App ID'yi native Android `Application.onCreate()` sırasında
    (Flutter/Dart kodu DAHA ÇALIŞMADAN) `AndroidManifest.xml`'deki
    `com.google.android.gms.ads.APPLICATION_ID` meta-data'sından okuyor — bu SDK'nın kendi
    KATI kısıtlaması, Dart tarafından hiçbir şekilde enjekte edilemiyor (build-time Gradle
    manifest placeholder'ları ile teorik olarak mümkün ama bu boyuttaki bir projede gereksiz bir
    dolaylılık eklerdi). **Bu yüzden "tek dosya" isteği tam anlamıyla karşılanamadı — gerçekte
    değiştirilecek İKİ nokta var, ama HER İKİSİ de tek satırlık, `TODO(admob)` ile açıkça
    işaretlenmiş, birbirine çapraz referans veren değerler:**
    1. `lib/config/admob_config.dart`'taki `rewardedAdUnitId` sabiti.
    2. `android/app/src/main/AndroidManifest.xml`'deki `APPLICATION_ID` meta-data'sının
       `android:value`'su (TODO yorumu `admob_config.dart`'a işaret ediyor).
  - **`main.dart`, `AdMobConfig.rewardedAdUnitId`'i kullanıyor** — eski (VAT ID sorunlu hesabın
    gerçek ID'sini taşıyan) top-level `_rewardedAdUnitId` sabiti TAMAMEN KALDIRILDI, yerine
    `AdMobAdService(rewardedAdUnitId: AdMobConfig.rewardedAdUnitId)` geçti.
  - Bu ara adımda AndroidManifest.xml'in App ID'si geçici olarak Google'ın test App ID'sine
    geri döndürülmüştü — bkz. altta "ÜÇÜNCÜ güncelleme", aynı oturumda gerçek yeni ID ile
    değiştirildi.
- **2026 ÜÇÜNCÜ güncelleme — yeni Bireysel hesabın GERÇEK ID'leri alındı, kod tarafına işlendi.**
  Kullanıcı AdMob Console'da yeni uygulamayı (`com.dijitalkanka.dijital_kanka`) kaydedip bir
  Ödüllü Reklam birimi oluşturdu, ekran görüntüsüyle iki ID'yi iletti:
  - **App ID (Android, GERÇEK, YENİ hesap):** `ca-app-pub-2881957853109429~2442148274` —
    `AndroidManifest.xml`'deki `APPLICATION_ID` meta-data'sına yazıldı.
  - **Rewarded Ad Unit ID (Android, GERÇEK, YENİ hesap):** `ca-app-pub-2881957853109429/1933318716`
    — `lib/config/admob_config.dart`'taki `AdMobConfig.rewardedAdUnitId`'e yazıldı (`TODO`
    yorumu kaldırıldı, artık kalıcı gerçek değer).
  - **Değiştirilen TAM OLARAK iki satır** — yukarıdaki "hesap değişikliği" bölümünde tarif edilen
    tam senaryo: kullanıcı iki ID'yi verdi, asistan yalnızca bu iki dosyadaki birer satırı
    güncelledi, başka HİÇBİR kod dosyasına dokunulmadı.
  - **Doğrulama:** `flutter test` (244/244 geçti) + APK yeniden derlenip telefona kurulup
    `adb shell monkey` ile başlatıldı — çöküş izi YOK, logcat'te AdMob SDK'sının yeni App ID'yi
    sorunsuz okuduğu (farklı bir hata koduna DÜŞMEDİĞİ) VE yeni Ad Unit ID'ye istek attığı
    doğrulandı (`Ads: Ad failed to load : 3` — ERROR_CODE_NO_FILL, bkz. yukarıdaki "no fill
    beklenen bir durum" notu — bu YENİ reklam biriminin henüz doldurulmamış olması + Ödemeler
    profilinin muhtemelen hâlâ tamamlanmamış olması nedeniyle bekleniyor, App ID/Ad Unit ID'nin
    KENDİSİNİN yanlış olduğu anlamına GELMİYOR).
  - **Kalan adım hâlâ Google'ın envanter/inceleme süreci** (bkz. önceki oturumdaki "Ödeme kurulumu
    tamamlanmadı" banner'ı notu) — kullanıcının AdMob Console'da Ödemeler > Ödeme bilgileri
    formunu tamamlaması gerekiyor, bu ASİSTANIN yapamayacağı (kimlik/vergi bilgisi girişi
    içeren) bir adım.
- **`AdMobAdService`** — `AdService`'i uygulayan gerçek implementasyon, `NotificationService`/
  `ShareService` ile AYNI "gerçek servis varsayılan, test'te sahte enjekte edilir" felsefesi (bkz.
  altta test/CoinProvider notu). Ön-yükleme (preload) deseni kullanıyor: ödüllü reklamlar AdMob'da
  ÖNCEDEN yüklenmesi gereken bir format, `showRewardedAd()` çağrıldığı anda sıfırdan yüklemeye
  başlamak kullanıcıyı saniyelerce bekletirdi — bu yüzden servis constructor'da VE her gösterimden
  hemen sonra arka planda bir sonraki reklamı önceden yüklemeye başlıyor; `showRewardedAd()`
  çağrıldığında genellikle zaten hazır bir reklam buluyor, yalnızca henüz yüklenmemişse 8sn'lik bir
  zaman aşımıyla bekliyor.
  - **Kritik gotcha — `RewardedAd.load(...)`'un döndürdüğü `Future`, `await`lenmeden ateşlenip
    unutulursa (fire-and-forget) platform kanalı hatası "unhandled Future rejection" olarak
    `flutter_test`'e SIZAR (senkron bir `try/catch` bunu YAKALAYAMAZ).** İlk yazımda bu Future
    hiç yakalanmıyordu — `flutter test` çalıştırılınca herhangi bir görünür hata/timeout OLMADAN
    (Flutter test framework'ü asenkron zone hatalarını bazen sessizce yutabiliyor) yalnızca iki
    testin (reklam izleme akışını doğrudan test eden) beklenmedik şekilde başarısız olduğu
    görüldü. **Çözüm:** `RewardedAd.load(...)`'un döndürdüğü `Future`'a `.catchError(...)`
    eklenip hata sessizce yutuluyor (`_rewardedAd = null` bırakılıp `showRewardedAd()`'ın `false`
    dönmesine izin veriliyor) — **bir platform-kanalı çağrısını `await`lemeden ateşlerken, hatasını
    HER ZAMAN `.catchError(...)` ile (senkron `try/catch` YETMEZ) yakalayın.**
- **`main.dart`'a bağlama:**
  - `main()`'e Firebase'den TAMAMEN BAĞIMSIZ (ayrı try/catch — biri başarısız olursa diğerini
    etkilemesin diye) `await MobileAds.instance.initialize();` eklendi, `runApp`'tan ÖNCE.
  - `DijitalKankaApp`, `CoinProvider(uid: uid, adService: adService ?? AdMobAdService(rewardedAdUnitId: AdMobConfig.rewardedAdUnitId))`
    kullanıyor (`AdMobConfig.rewardedAdUnitId` — bkz. yukarıdaki "hesap değişikliği" bölümü) —
    `RootScreen.pushNotificationService`/`HomeScreen.soundEffectsService` ile AYNI "test
    enjeksiyonu için opsiyonel constructor parametresi" deseni: `DijitalKankaApp`'in YENİ
    `adService` alanı `null` ise (üretimde HER ZAMAN) gerçek `AdMobAdService` kullanılır.
  - **`CoinProvider`'ın KENDİ varsayılan parametresi (`AdService adService = const
    MockAdService()`) BİLEREK DEĞİŞTİRİLMEDİ** — `CoinProvider()` çağıran ~10 test call site'ı
    (bkz. `coin_provider_test.dart`, `manifest_journal_screen_test.dart`,
    `profile_screen_test.dart`) hiçbirinin dokunulmasına GEREK KALMADI, hepsi sessizce Mock
    kullanmaya devam ediyor. Yalnızca `main.dart`'ın kompozisyon kökü (composition root) gerçek
    servisi override ediyor — `AdService` dokümantasyonundaki "gerçek AdMob geldiğinde
    CoinProvider'a VERİLECEK" ifadesi tam olarak bunu kastediyordu.
  - **`widget_test.dart`'ta `const DijitalKankaApp()` pump'layan İKİ senaryo** ("Mağazadan reklam
    izleyince 20 Zibo Coin kazanılır", "Şans Çarkı: reklam izleyip çevirince...") reklam izleme
    akışının KENDİSİNİ doğrudan test ettiği için (bakiyenin gerçekten arttığını doğruluyorlar) artık
    `DijitalKankaApp(adService: const MockAdService())` kullanıyor — gerçek `AdMobAdService`
    `flutter_test`'in platform kanalına dokunamadığı için reklam hiç "yüklenmez",
    `showRewardedAd()` sessizce `false` döner, bu da bu İKİ testin (yalnızca bunların, diğer 242
    test etkilenmedi) DEĞİŞMEDEN geçmesini engellerdi.
- **AndroidManifest.xml** — `<application>` içine `com.google.android.gms.ads.APPLICATION_ID`
  meta-data'sı eklendi (yukarıdaki test App ID ile) — `<queries>`/izin bloklarına DOKUNULMADI,
  `google_mobile_ads` ek bir izin/queries girdisi gerektirmiyor.
- **Gerçek cihazda doğrulama:** APK yeniden derlenip telefona kurulup `adb shell monkey` ile
  başlatıldı — çöküş izi olmadan açıldığı VE logcat'te AdMob SDK'sının gerçekten devreye girdiği
  doğrulandı (`Ads` etiketli loglar: `SDK version: afma-sdk-...`, GMS `ads.service.CACHE`/`START`
  servislerine bağlanma, `tag=addon/rewarded_video` ile bir ödüllü reklam kaynağının aktif olarak
  YÜKLENDİĞİ). **Kullanıcının kendi cihazında GÖRSEL olarak doğrulaması gereken kısım:** Mağaza'nın
  "Ücretsiz" kartındaki "İzle" butonuna VEYA Şans Çarkı'na basınca köşesinde "Test Ad" etiketli
  gerçek bir AdMob reklamının açılıp, izlenince/atlanınca doğru davrandığı (izlenirse coin/ödül
  verilir, erken kapatılırsa verilmez) — bu kod seviyesinde `flutter test`'teki 244 testle (reklam
  akışını Mock ile simüle ederek) kapsanıyor ama gerçek bir reklam GÖRÜNTÜSÜNÜN doğrulanması
  gerçek cihaz gerektiriyor.
- **GÜNCEL DURUM (bu bölümün en son hâli): kod tarafı GERÇEK ID'lerle bağlı, kalan tek adım
  Google'ın envanter/inceleme süreci.** Yeni Bireysel hesabın App ID + Rewarded Ad Unit ID'si
  (bkz. yukarıdaki "ÜÇÜNCÜ güncelleme") koda işlendi, `flutter test` (244/244) + gerçek cihaz
  derleme/kurulumla doğrulandı, çöküş YOK.
  - **Kullanıcının AdMob Console'da hâlâ tamamlaması gereken adım — Ödeme profili:**
    **Ödemeler > Ödeme bilgileri** formunu (ülke, hesap türü — Bireysel, ad/adres, vergi kimlik
    bilgisi) doldurması gerekiyor — bu tamamlanmadan Google uygulamayı incelemiyor ve reklamlar
    "no fill" dönmeye devam ediyor (bkz. önceki oturumdaki "Ödeme kurulumu tamamlanmadı"
    banner'ı notu). **Bu, kimlik/vergi bilgisi girişi olduğu için kullanıcının KENDİSİNİN
    yapması gereken bir adım** — asistan bunu hiçbir şekilde (form doldurma dahil) kullanıcı
    adına yapmıyor.
  - Ödeme profili tamamlanıp Google incelemeyi bitirdikten sonra (dakikalar-saatler) Mağaza'daki
    "İzle" butonuna veya Şans Çarkı'na basılınca gerçek (artık "Test Ad" etiketi OLMAYAN) bir
    reklam gösterilmeye başlamalı — bu noktada ayrıca bir kod değişikliği GEREKMİYOR, yalnızca
    Google tarafının hazır olmasını bekliyoruz.

### AdMob/AdSense hesabı devre dışı bırakıldı — itiraz süreci (2026-08-21)

- **Kullanıcının `cvntann@gmail.com` ile açtığı AdMob hesabı (Publisher ID `pub-2881957853109429`,
  App ID `ca-app-pub-2881957853109429~2442148274`) Google tarafından DEVRE DIŞI BIRAKILDI** —
  gelen resmi e-postadaki sebep AÇIKÇA **"Account related to a disabled account"** (daha önce
  politika ihlali nedeniyle devre dışı bırakılmış BAŞKA bir hesapla ilişkili bulunması), "geçersiz
  trafik" DEĞİL.
  - **Kök neden — mükerrer hesap kaydı:** Kullanıcı bu proje için önce KURUMSAL e-postasıyla
    (`contact@getzibo.com`) kayıt olmuştu — Google bunu işletme/kurum hesabı sayıp VAT (vergi)
    kimlik numarası istedi, kullanıcıda bu olmadığı için o hesabın kimlik doğrulamasını HİÇ
    tamamlamadı, hiç kullanmadı (sıfır reklam, sıfır gelir) ve yerine kişisel e-postasıyla
    (`cvntann@gmail.com`) SIFIRDAN yeni bir hesap açıp kimlik doğrulamasını ORADA tamamladı. Aynı
    kişinin aynı uygulama için iki ayrı hesap açması (ilkini hiç kapatmadan), Google'ın en yaygın
    "ilişkili/mükerrer hesap" tespit sebeplerinden biri — kimlik belgeleri/cihaz/muhtemelen ödeme
    bilgisi üzerinden iki hesabın AYNI kişiye ait olduğu tespit edilip ikincisi otomatik engellendi.
  - **Olası bileşen faktör:** Kullanıcı geliştirme sırasında GERÇEK (test etiketsiz) reklam
    birimiyle kendi cihazından birkaç kez reklam izleyip panelde ~3-4 TL "gelir" oluşturduğunu
    belirtti — bu, resmi bildirimde AÇIKÇA belirtilen birincil sebep DEĞİL ama Google'ın risk
    değerlendirmesine ek bir sinyal olarak katkıda bulunmuş olabilir. Bu rakam muhtemelen zaten
    ödenmeyecekti — hesapta "Ödeme kurulumu tamamlanmadı" uyarısı vardı, panelde görünen tutarlar
    bu aşamada yalnızca TAHMİNİ, kesinleşmiş/ödenebilir değil.
  - **İtiraz gönderildi (2026-08-21), sonuç BEKLENİYOR.** Resmi AdSense "policy disabled appeal"
    formu (`support.google.com/adsense/contact/policy_disabled_appeal`) üzerinden, kurumsal
    e-postayla başlayıp VAT ID sorunundan dolayı yarım bırakılan ilk kaydın, ardından kişisel
    e-postayla doğru şekilde açılan ikinci hesabın hikayesini dürüstçe anlatan bir metinle
    gönderildi. Google'ın onay e-postası: incelemenin bir hafta veya daha uzun sürebileceğini,
    yeniden etkinleştirmenin GARANTİ EDİLMEDİĞİNİ, ve bir itiraz sonuçlandıktan sonra yeni bir
    itiraz için 90 gün beklenmesi gerektiğini (ilk itiraz için geçerli değil) belirtiyor.
  - **Ders — bundan sonra geliştirme/test sırasında ASLA gerçek Ad Unit ID kullanılmamalı,
    HER ZAMAN Google'ın resmi test ID'lerine düşülmeli** (debug/test build'lerde otomatik
    geçiş — henüz UYGULANMADI, kullanıcıya teklif edildi ama başlanmadı) — bu tam olarak yukarıdaki
    "olası bileşen faktör"ün bir daha yaşanmaması için.
  - **Zibo'nun asıl gelir modeli AdMob'a bağımlı DEĞİL — bu olay Play Billing'i (coin satışları)
    HİÇ etkilemiyor.** İki gelir kanalı tamamen ayrı: coin satın almaları Google Play'in KENDİ
    ödeme altyapısını (bkz. "Google Play Billing" bölümü) kullanıyor, AdSense/AdMob kimlik
    sorunlarından bağımsız. AdMob kalıcı olarak geri gelmezse, reklam tarafı için **AppLovin
    (MAX)** — Google/AdSense ekosisteminden tamamen bağımsız, resmi Flutter paketi olan
    (`applovin_max`), rewarded+interstitial destekleyen bir alternatif olarak konuşuldu (henüz
    ENTEGRE EDİLMEDİ, yalnızca bir yedek plan olarak not düşüldü). `AdService` soyutlaması
    sayesinde geçiş (AdMob'a dönmek DAHİL) tek bir servis sınıfı yazıp `main.dart`'ta bağlamaktan
    ibaret olacak, `CoinProvider`/ekranlar hiç değişmeyecek.

### AdMob → Appodeal geçişi (2026) — `AdService` soyutlaması sayesinde tek bir servis değişikliği ([appodeal_config.dart](lib/config/appodeal_config.dart), [appodeal_ad_service.dart](lib/services/appodeal_ad_service.dart))

- **Kullanıcı isteği (verbatim özet): "uygulamayı admob entegrasyonundan çıkartıp appodeal ı
  entegre edeceğiz."** Yukarıdaki "AdMob/AdSense hesabı devre dışı bırakıldı" bölümünde konuşulan
  yedek planın (AppLovin MAX) YERİNE, kullanıcının kendisi Appodeal'i (bir mediation platformu —
  tek bir ağa bağımlı olmadığı için tek bir ağın hesap yasaklamasının reklam gelirini TAMAMEN
  durdurmasını önlüyor, tam da AdMob banının yarattığı riski hedefleyen bir seçim) araştırıp
  seçti; asistandan yalnızca kod-tarafı entegrasyonu istendi. Bu, `AdService` soyutlamasının
  tam olarak VAAT ETTİĞİ senaryo — `CoinProvider`/Mağaza/Şans Çarkı/Ana Sayfa'nın art arda dokunma
  reklamı/Günlük Giriş Ödülleri/Hedef Tamamlama kutlaması gibi TÜM çağıran kod HİÇ DEĞİŞMEDİ,
  yalnızca `AdService`'i uygulayan TEK bir sınıf (`AdMobAdService` → `AppodealAdService`) ve
  `main.dart`'taki TEK bir kompozisyon-kökü satırı değişti.
- **Paket seçimi — `appodeal_flutter` (community, pub.dev'de ARŞİVLENMİŞ, resmi paketi kullanmayı
  öneren bir notla) DEĞİL, `stack_appodeal_flutter: ^4.2.0` (Appodeal'in KENDİ, "verified
  publisher: appodeal.com" resmi paketi) seçildi.** WebFetch'in özetlenmiş dokümantasyonuna
  GÜVENMEK yerine (bu proje genelinde üçüncü parti paket entegrasyonlarında kurulu convansiyon,
  bkz. "Test kalıpları" ve diğer bölümlerdeki "gerçek kaynağı oku" pratiği), paketin pub-cache'teki
  GERÇEK kaynak dosyaları (`appodeal.dart`, 630 satır; `appodeal_ad_type.dart`, 57 satır) doğrudan
  okunup TAM API sözleşmesi (aşağıda) çıkarıldı.
- **API'nin AdMob'dan mimari FARKI — callback'ler SDK-seviyesinde GLOBAL, her `show()` çağrısına
  ÖZEL değil.** AdMob'da her `RewardedAd`/`InterstitialAd` örneği KENDİ
  `FullScreenContentCallback`'ini taşıyordu; Appodeal `Appodeal.setRewardedVideoCallbacks({...})`/
  `Appodeal.setInterstitialCallbacks({...})`'i BİR KEZ (bu servisin constructor'ında) kaydediyor —
  `AppodealAdService`'in `showRewardedAd()`/`showInterstitialAd()`'ı bu yüzden bir
  **Completer-tabanlı köprü** deseni kullanıyor: o anki isteği temsil eden bir `Completer<bool>`
  bir ALANDA (`_rewardedCompleter`/`_interstitialCompleter`) saklanıp, global callback'ler bu
  alanı görüp tamamlıyor.
  - `Appodeal.setTesting(bool)` — SENKRON (AdMob'un `await MobileAds.instance.initialize()`'ının
    AKSİNE).
  - `Appodeal.initialize({appKey, adTypes, onInitializationFinished})` — Dart API'sinin KENDİSİ
    HİÇBİR ŞEY DÖNDÜRMÜYOR (gövdesinde `return` YOK) — fire-and-forget, anlamlı şekilde
    `await`lenemez; `main()`'de bu yüzden `await` EDİLMEDEN çağrılıyor.
  - **Ön-yükleme (preload) YOK — AdMob'un AKSİNE elle bir `load()` TETİKLEMİYORUZ.** Appodeal
    `initialize()` çağrıldıktan sonra ilgili `adTypes` için arka planda SÜREKLİ kendi kendine
    reklam yüklüyor; `AppodealAdService._waitUntilLoaded(type)` yalnızca `Appodeal.isLoaded(type)`'i
    300ms aralıklarla 8 saniyelik (AdMob'daki AYNI zaman aşımı süresi) bir pencerede polling ile
    SORUYOR, bir yükleme TETİKLEMİYOR.
  - `Appodeal.show(adType, [placement])` → `Future<bool>` — reklamın GÖSTERİLEBİLDİĞİNİ (TAMAMLANDIĞINI
    DEĞİL) belirtiyor; gerçek sonuç (ödül kazanıldı mı/kapatıldı mı) yukarıdaki global callback'lerden
    geliyor.
  - `AppodealAdType` enum'u: `None, Banner, BannerBottom, BannerTop, BannerLeft, BannerRight,
    Interstitial, RewardedVideo, MREC, NativeAd, All` — uygulama yalnızca `RewardedVideo` +
    `Interstitial`'ı kullanıyor (AdMob entegrasyonundaki AYNI "TEK reklam formatı" kapsam
    sınırlaması, bkz. yukarıdaki bölüm — banner/MREC/native BİLEREK entegre EDİLMEDİ).
- **`AppodealConfig.appKey`** (`lib/config/appodeal_config.dart`, `AdMobConfig`'in AYNI "TEK Dart
  config noktası" deseni) — kullanıcının Appodeal Console'da oluşturduğu "Zibo" uygulamasının App
  Key'i (`6c5e7e6022e1a98028a71951d73681a9f587c7a1993d9114`, Bundle Id
  `com.dijitalkanka.dijital_kanka` ile eşleşiyor). **AdMob'un App ID'sinden KRİTİK bir farkla:**
  App Key native `AndroidManifest.xml`'den OKUNMUYOR — doğrudan Dart'tan `Appodeal.initialize(
  appKey: ...)`'e geçiriliyor, bu yüzden AdMob'un `com.google.android.gms.ads.APPLICATION_ID`
  meta-data'sının bir eşdeğerine HİÇ GEREK YOK (bkz. altta AndroidManifest.xml notu).
- **`AppodealAdService`** — `isAdShowing`/`AdBlurOverlay` (bkz. yukarıdaki "reklam tam ekranı
  kaplamıyor" bölümü) toggling'i, `.catchError`/try-catch güvenlik ağları, `unawaited` YOK ama
  reklam gösterildikten SONRA bir sonraki reklamı ELLE yeniden YÜKLEMEYE gerek yok (SDK zaten
  sürekli arka planda yüklüyor) — `AdMobAdService`'in bu iki deseninden (preload/`unawaited
  (_loadAd())`) BİLEREK VAZGEÇİLDİ, kalan tüm güvenlik davranışı (try/catch, `isAdShowing`
  toggling) BİREBİR korundu.
- **Android tarafı — `android/build.gradle` (proje düzeyi) VE `android/app/build.gradle`'a HİÇBİR
  elle ekleme GEREKMEDİ.** `stack_appodeal_flutter`'ın KENDİ `android/build.gradle`'ı
  `rootProject.allprojects { repositories { ... maven { url ".../appodeal" } } } }` ile Appodeal'in
  maven deposunu TÜM projeye (uygulamamız dahil) otomatik ekliyor VE kendi `dependencies {}`
  bloğunda `com.appodeal.ads.sdk:core:4.2.0` + `com.appodeal.ads.sdk.adapters:iab:1.8.1.0`'ı
  ZATEN bağımlılık olarak taşıyor — bu, TEK bir Appodeal-kendi ağı/bidding adaptörüyle (IAB/Bidon)
  reklam göstermeye yetecek MİNİMAL bir kurulum. **AdMob dahil BAŞKA hiçbir ağ adaptörü
  eklenmedi** (README'nin listelediği onlarca AppLovin/AdMob/Unity Ads/vb. adaptörü BİLİNÇLİ
  olarak dışarıda bırakıldı) — kullanıcı Appodeal Console'dan ek ağlar (ör. AdMob'u YENİDEN,
  ama bu sefer bir mediation ağı OLARAK) etkinleştirmek isterse, o ağın `build.gradle`
  bağımlılığını (Dependencies Wizard'ın ürettiği satırı) `android/app/build.gradle.kts`'e elle
  eklemesi gerekecek — bu turda kapsam dışı bırakıldı, "adım adım" ilerleyişin İLK/temel adımı.
- **`AndroidManifest.xml`/`styles.xml`'den AdMob'a özel üç şey TAMAMEN KALDIRILDI** (silinmedi
  bırakılmadı — projenin "genuine replacement, deprecation değil" convansiyonu): (1)
  `com.google.android.gms.ads.APPLICATION_ID` meta-data'sı (yukarıda açıklandığı gibi Appodeal'de
  karşılığı YOK), (2) `com.google.android.gms.ads.AdActivity`'ye `tools:replace="android:theme"`
  ile atanan tema override'ı (bkz. altta "Reklamlar tam ekranı kaplamıyor" bölümü — o bileşen artık
  manifest'te hiç YOK, `google_mobile_ads` paketi tamamen kaldırıldığı ve hiçbir Appodeal
  adaptörü AdMob'u getirmediği için), (3) `values/styles.xml`/`values-night/styles.xml`'deki
  `AdActivityTheme` stili (yalnızca #2'nin hedefiydi, artık kullanılmıyor). `AdBlurOverlay`/
  `isAdShowing` (Flutter-taraflı, native davranıştan bağımsız YEDEK katman) BİLEREK KORUNDU —
  hangi reklam SDK'sı kullanılırsa kullanılsın genel bir güvenlik ağı olarak faydalı.
- **`lib/services/admob_ad_service.dart`/`lib/config/admob_config.dart` TAMAMEN SİLİNDİ**
  (deprecate edilmedi) — `pubspec.yaml`'dan `google_mobile_ads: ^9.1.0` çıkarılıp
  `stack_appodeal_flutter: ^4.2.0` eklendi (`flutter pub get` "Changed 6 dependencies!" ile
  çözdü, `google_mobile_ads`'ın transitif `webview_flutter*` bağımlılıkları da birlikte gitti).
- **`kDebugMode` — CLAUDE.md'nin ÖNCEKİ bir notu YANLIŞTI, bu turda düzeltildi:** "kDebugMode
  (`flutter/foundation.dart`'tan, `material.dart` üzerinden transitif olarak erişilebilir)"
  diye belgelenmişti — gerçekte bu Flutter/paket sürüm kombinasyonunda DEĞİL, `flutter test`
  derleme hatasıyla (`Undefined name 'kDebugMode'`) YAKALANDI. **Düzeltme:** `main.dart`'a açık
  `import 'package:flutter/foundation.dart' show kDebugMode;` eklendi — `Appodeal.setTesting(
  kDebugMode)` DEBUG build'lerde HER ZAMAN test reklamı gösterilmesini garanti ediyor, kullanıcının
  önceki AdMob hesabının banlanmasına katkıda bulunduğu düşünülen hatayı (gerçek reklam
  birimleriyle kendi cihazından test etmek) BİR DAHA TEKRARLAMAMAK için.
- **Test + doğrulama:** `flutter test` — tam suite (bir istisnayla: "Zibo'ya dokununca söz
  değişir..." testi, ÖNCEDEN belgelenmiş `audioplayers`/`home_widget` platform kanalı
  `MissingPluginException` sızıntısı flake'i, bu turun değişiklikleriyle İLGİSİZ, bkz. "Test
  kalıpları" bölümü) yeşil. `flutter build apk --debug` sorunsuz derlendi (yalnızca
  `stack_appodeal_flutter`'ın da diğer plugin'ler gibi Kotlin Gradle Plugin uyguladığına dair
  zararsız/bilgilendirici bir uyarı — Firebase/`flutter_timezone`/`home_widget`'la AYNI kategori).
  **Gerçek cihazda kurulum/görsel doğrulama bu turda BİLEREK YAPILMADI** — bağlı cihaz
  kontrol edildiğinde (`adb shell dumpsys package`) `installerPackageName=com.android.vending`,
  `versionName=1.2.0` çıktı, yani bu kullanıcının GERÇEK, Play Store'dan kurulu canlı kurulumu
  (bir test cihazı DEĞİL) — bunu debug build'le ÜZERİNE YAZMAK (imza uyuşmazlığı yüzden önce
  `uninstall` gerektirirdi, bu da gerçek kullanıcı verisini SİLERDİ) bu projede DEFALARCA
  tekrarlanan "gerçek cihaz paylaşım riski" prensibiyle (bkz. "Hedef Tamamlama Kutlaması"/
  "Ana Ekran Widget'ları" bölümlerindeki AYNI temkinli durma kararları) tutarlı şekilde
  ATLANDI.
- **Kullanıcının Appodeal Console'da/kendi cihazında tamamlaması gereken adımlar** (asistan
  yapamaz — konsol/cihaz erişimi gerektiriyor):
  1. Yeni APK'yı (bir sonraki `flutter build`/Play Console yüklemesi) kurup EN AZ BİR KEZ
     çalıştırmak — Appodeal Console'daki uygulama girişinin SDK durumunun "No SDK" → gerçek bir
     SDK sürümüne (`4.2.0`) geçtiğini doğrulamak için (SDK ilk gerçek `initialize()` çağrısında
     Appodeal'in sunucularına "merhaba" sinyali gönderiyor).
  2. Appodeal Console'un Monetization Setup akışından (kullanıcının önceki turda paylaştığı
     ekran görüntüsündeki) en az bir gerçek reklam ağı (AdMob'u YENİDEN mediation ağı olarak
     eklemek DAHİL, veya farklı bir ağ) etkinleştirmek + o ağın kendi hesap/API anahtarlarını
     girmek — bu turda kod yalnızca Appodeal'in KENDİ (IAB/Bidon) minimal doldurma kapasitesine
     dayanıyor, gerçek/yüksek dolgu oranı için EN AZ bir ek ağ eklenmesi ÖNERİLİR.
  3. Debug build ile `Appodeal.setTesting(true)` (kod zaten `kDebugMode`'a bağlı) test reklamları
     gösterecek — kullanıcının kendi cihazında Mağaza'nın "İzle" butonuna/Şans Çarkı'na/art arda
     Zibo dokunmasına basıp GERÇEKTEN bir reklamın (test etiketli) göründüğünü doğrulaması
     gerekiyor.
  4. Ödeme/gelir kurulumu (Appodeal Console'un kendi ödeme profili formu) — kimlik/vergi bilgisi
     girişi içerdiği için asistan bunu YAPAMAZ, kullanıcının kendisi tamamlamalı.

### Appodeal Console onboarding'i + Unity Ads adaptörü — gerçek cihazda uçtan uca doğrulama (2026-08-31/09-01)

- **Kullanıcı Appodeal Console'un "Monetization Setup" onboarding sihirbazını adım adım geçti** —
  bkz. şu kararlar: (1) "Autoconnection" (varsayılan işaretli) bırakıldı — Appodeal kullanılabilir
  ağları otomatik bağlayıp uygulama yayında/yeterli trafikliyken devreye sokuyor; (2) "Connecting
  AdMob and Meta" bölümü BİLEREK atlandı (`Save and Continue Later`) — AdMob banlı, Meta
  kullanılmıyor; (3) "SDK Integration" adımında "Confirm SDK implemented"/"Confirm Ad Formats
  implemented" işaretlendi, "Confirm AdMob App ID added" BİLEREK boş bırakıldı (bu, "Finish SDK
  Integration" butonunu KİLİTLİ tuttu — çözüm: sol menüden doğrudan "Publish App" adımına
  tıklamak, sihirbazın adım linkleri serbestçe gezilebiliyor); (4) "Publish App" adımındaki üç
  uyum maddesi (Privacy Policy güncellemesi, app-ads.txt, AdMob üzerinden CMP/GDPR kurulumu)
  BİLEREK ERTELENDİ (`Save and Continue Later`) — hiçbiri reklam gösterimini ENGELLEMİYOR;
  app-ads.txt `getzibo.com`'a erişim gerektiriyor (bu oturumun erişemediği ayrı proje), CMP için
  Appodeal'in AdMob'suz kendi "Stack Consent Manager"ı (Google UMP tabanlı, SDK 3.0+'ta İLK
  başlatmada GDPR/CCPA bölgesindeki kullanıcılara OTOMATİK gösteriliyor) var — AdMob login
  GEREKMİYOR.
- **"Test Impressions" — gerçek cihazda GERÇEKTEN doğrulandı, kör tahmin YAPILMADI.** Release
  (Play Store) sürümünde reklam hiç gelmiyordu ("İzle"ye basınca hiçbir şey olmuyordu) — kullanıcı
  debug build'i (USB üzerinden, `adb install`) test etmeyi seçti. **MIUI'ye özgü ek bir engel
  bulundu:** `adb install` `INSTALL_FAILED_USER_RESTRICTED` ile başarısız oldu — Geliştirici
  Seçenekleri'nde "USB Hata Ayıklama"dan AYRI, **"USB üzerinden yükleme" (Install via USB)**
  anahtarının da açılması gerekiyordu (MIUI'nin ek güvenlik katmanı). Açılınca kurulum başarılı
  oldu; `adb logcat` ile canlı izlenince `com.explorestack.iab.vast.activity.VastActivity`'nin
  (Appodeal'in VAST/IAB reklam oynatma Activity'si) GERÇEKTEN başlayıp görüntülendiği (`ActivityTaskManager:
  Displayed`) doğrulandı — SDK uçtan uca çalışıyor. **Kök neden:** release build'de `Appodeal.
  setTesting(kDebugMode)` = `false` (doğru davranış — gerçek kullanıcıya test reklamı
  gösterilmemeli) + o ana kadar hiçbir gerçek ağ adaptörü bağlı değildi, bu yüzden production'da
  henüz gerçek doluluk (fill) yoktu; debug build'de test modu açık olduğu için Appodeal'in kendi
  backfill test kreatifi (`test_ads/video_720x1280.mp4`) yüklenip gösterildi. Test SONRASI cihaz
  `adb uninstall` + Play Store'dan yeniden kurulumla gerçek release sürümüne (imza/veri farkı —
  `installerPackageName=com.android.vending` ile doğrulandı) GERİ DÖNDÜRÜLDÜ.
- **Unity Ads adaptörü `android/app/build.gradle.kts`'e eklendi** —
  `implementation("com.appodeal.ads.sdk.adapters:unity_ads:4.17.0.0")` (Gradle cache'te hem bu
  adaptörün hem alttaki `com.unity3d.ads:unity-ads:4.17.0`'ın gerçekten indirildiği doğrulandı).
  **AMA Appodeal Console'un "Mediation Setup > Ad Units" sayfası UnityAds'i (VE VK Ads/Vungle/
  ironSource/Mintegral/BigoAds/DT Exchange gibi bir grubu) hâlâ "This network does not pass all
  restrictions" diyip KAPALI (OFF) gösteriyor — kod tarafında adaptörü eklemek TEK BAŞINA yeterli
  DEĞİL, Appodeal'in KENDİ tarafında da bu ağı "uygun" görmesi gerekiyor.** Kesin sebep (ⓘ tooltip'i
  okunarak, TAHMİN EDİLMEDEN doğrulandı): **"The store link is required."** — Apps > [uygulama] >
  General sayfasındaki **Store URL** alanı "This app is not in store yet" diyor, sağda **"The store
  link will update automatically in 24h"** notu var. Yani Appodeal, uygulamanın Play Store'da
  GERÇEKTEN yayında olduğunu KENDİ İÇ mekanizmasıyla (muhtemelen paket adı + App Key üzerinden
  Play Store'u periyodik sorgulayarak) 24 saat içinde otomatik doğruluyor — elle girilecek bir alan
  YOK, `Refresh` butonu da anlık bir API çağrısı yapmıyor gibi görünüyor (sonuç değişmedi). **Bu
  24 saatlik pencere dolana kadar UnityAds (ve aynı kısıtlamayı taşıyan diğer ağlar) Console'da
  AÇILAMAYACAK** — kod tarafında adaptör HAZIR bekliyor, Appodeal'in kendi tarafı devreye girince
  ekstra bir Dart/Kotlin değişikliği GEREKMEYECEK.
  - **İyi haber — bu bekleme sırasında bile TAMAMEN reklamsız DEĞİLİZ:** aynı Ad Units sayfasında
    **AppLovin** ve **BidMachine**'in ZATEN "ON" (Appodeal'in varsayılan hesabı üzerinden otomatik
    bağlı) olduğu görüldü — kullanıcının kendi AppLovin hesabının "uygulama yayında değil" diye
    reddedilmesinden TAMAMEN BAĞIMSIZ bir yol (Appodeal'in KENDİ AppLovin ilişkisi/hesabı
    üzerinden) — yani gerçek reklam talebi şu an SIFIR değil, yalnızca UnityAds gibi ek ağlar
    henüz devrede değil.
  - **General sayfasında AYRICA görülen, ileride değerlendirilecek iki alan:** (1) **COPPA**
    anahtarı BİLİNÇLİ olarak KAPALI bırakıldı (Zibo çocuklara özel bir uygulama değil, bu doğru);
    (2) **S2S Reward Callback URL / Encryption key** — BOŞ, Appodeal'in KENDİ sunucu-taraflı ödül
    doğrulama (server-side verification) mekanizması TAM OLARAK bu alanlar üzerinden kuruluyor —
    bkz. "Coin Ekonomisi Güvenliği" bölümündeki "AdMob SSV" notunun Appodeal karşılığı, aynı Cloud
    Functions/backend kararına bağlı, bu turda KURULMADI, yalnızca varlığı doğrulandı/not düşüldü.
- **Sürüm 1.3.1+17'ye yükseltildi**, Unity Ads adaptörünü içeren yeni bir release AAB derlenip
  kullanıcıya teslim edildi — Play Console'a yüklenmeyi bekliyor. Yüklenip 24 saatlik Store Link
  penceresi de dolunca, UnityAds'in Console'da otomatik AÇILIP AÇILMADIĞI + gerçek reklam
  doluluğunun artıp artmadığı kontrol edilmeli.

### Reklamlar tam ekranı kaplamıyor (bug düzeltmesi) — `AdActivity` tema override + blur yedek katmanı

> **TARİHSEL — `AdActivity` tema override'ının KENDİSİ (native/manifest seviyesindeki asıl
> düzeltme) AdMob → Appodeal geçişiyle KALDIRILDI** (bkz. yukarıdaki "AdMob → Appodeal geçişi"
> alt bölümü — `google_mobile_ads` paketi projeden tamamen çıkarıldığı için o bileşen artık
> manifest'te YOK). Bu bölümdeki KÖK NEDEN analizi (Android 15 edge-to-edge + üçüncü parti bir
> reklam Activity'sinin yarı saydam teması) genel bir Android dersi olarak halen geçerli;
> `AdBlurOverlay`/`isAdShowing` (Flutter-taraflı yedek katman, altta anlatılıyor) SDK'dan bağımsız
> olduğu için KORUNDU ve hâlâ aktif.

- **2026 bug raporu (İLK TUR — YETERSİZ KALDI).** Kullanıcı bildirdi: AdMob reklamları
  (özellikle geçiş/interstitial) gösterilirken ekranın üst kısmında hâlâ Zibo'nun kendi arayüzü
  (AppBar/status bar alanı) görünüyor, reklam tam ekranı kaplamıyor. İlk turda `styles.xml`'deki
  `LaunchTheme`/`NormalTheme`'e (yalnızca `MainActivity`'nin KENDİ teması)
  `windowOptOutEdgeToEdgeEnforcement` eklenmişti — kullanıcı bir ekran görüntüsüyle (Mağaza'nın
  reklam-karşılığı coin kartından açılan bir reklam, üstte hâlâ Zibo'nun coin sayacı/+/ayarlar
  ikonlarının göründüğü) bunun İŞE YARAMADIĞINI bildirdi.
- **Gerçek kök neden bulundu — ilk turda ATLANAN parça: AdMob'un KENDİ `AdActivity`
  bileşeninin ayrı bir teması var, biz hiç dokunmamıştık.** `google_mobile_ads`/Play Services
  Ads SDK'sı kendi `AndroidManifest.xml`'inde `com.google.android.gms.ads.AdActivity`
  bileşenini KENDİ teması ile deklare ediyor (bu, bizim uygulama manifest'imize bir AAR
  üzerinden OTOMATİK BİRLEŞİYOR) — ilk turdaki düzeltme yalnızca `MainActivity`'nin (bizim
  kendi Activity'miz) temasına `windowOptOutEdgeToEdgeEnforcement` eklemişti, AdActivity'nin
  KENDİ (SDK'nın deklare ettiği, muhtemelen yarı saydam) temasını hiç ETKİLEMİYORDU — bu yüzden
  Android 15'in ZORUNLU edge-to-edge davranışı AdActivity için hâlâ aktifti, reklam gösterilirken
  altındaki `MainActivity`'nin içeriği (Zibo'nun AppBar'ı) durum çubuğu şeridinde görünür
  kalmaya devam ediyordu. WebSearch ile bu, Google AdMob destek forumlarında YAYGIN olarak
  raporlanan, "Interstitial Ads issue on Android 15" başlığıyla tartışılan, Google mühendislik
  ekibinin KABUL ETTİĞİ bilinen bir bug olduğu doğrulandı — ve resmi çözüm TAM OLARAK
  AdActivity'nin kendi temasını override etmek.
  - **Asıl düzeltme (SDK/native seviyesinde) — `AdActivity`'nin teması
    `tools:replace="android:theme"` ile AÇIKÇA değiştirildi.**
    `android/app/src/main/AndroidManifest.xml`'e (kök öğeye `xmlns:tools` namespace'i eklenip)
    şu deklarasyon eklendi:
    ```xml
    <activity
        android:name="com.google.android.gms.ads.AdActivity"
        android:theme="@style/AdActivityTheme"
        tools:replace="android:theme"/>
    ```
    `tools:replace="android:theme"` ZORUNLU — hem bizim manifest'imiz hem SDK'nın kendi
    manifest'i AYNI bileşen için bir `android:theme` deklare ettiği için, birleştirici (manifest
    merger) bu çakışmayı hangi tarafın KAZANACAĞI açıkça belirtilmeden bir HATA sayıyor. Yeni
    `AdActivityTheme` (hem `values/styles.xml` hem `values-night/styles.xml`'de, Google AdMob
    destek ekibinin kendi önerdiği örnekle BİREBİR aynı ebeveynle) tanımlandı:
    ```xml
    <style name="AdActivityTheme" parent="@android:style/Theme.Translucent.NoTitleBar">
        <item name="android:windowOptOutEdgeToEdgeEnforcement" tools:targetApi="35">true</item>
    </style>
    ```
    **Doğrulama — Gradle'ın ÜRETTİĞİ birleştirilmiş manifest incelendi**
    (`build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`)
    ve `AdActivity` bileşeninin gerçekten `android:theme="@style/AdActivityTheme"` ile
    render edildiği (SDK'nın kendi `android:configChanges`/`android:enableOnBackInvokedCallback`
    özniteliklerini KORUYARAK — yani tam bir birleşme, elemanın tamamının silinip yeniden
    yazılması DEĞİL) doğrulandı — bu, `tools:replace`'in gerçekten beklenen şekilde çalıştığının
    somut kanıtı.
  - **İkinci, savunmacı bir katman — `MainActivity.kt`'ye açık bir `onCreate()` override'ı
    eklendi.** Flutter'ın kendi motoru, Android 15+ hedefleyen uygulamalarda `Activity`
    oluştururken `decorFitsSystemWindows`'u KENDİSİ çalışma zamanında `false`'a ayarlayabiliyor
    (edge-to-edge desteği) — bu, `styles.xml`'deki manifest-tema düzeyindeki
    `windowOptOutEdgeToEdgeEnforcement` bayrağının etkisini potansiyel olarak GEÇERSİZ
    kılabiliyordu (kesin kanıtlanmadı ama olası bir ek faktör). `super.onCreate()`'ten HEMEN
    SONRA `WindowCompat.setDecorFitsSystemWindows(window, true)` çağrılarak `MainActivity`'nin
    KESİN olarak geleneksel (edge-to-edge OLMAYAN) davranışta kaldığı KOD SEVİYESİNDE garanti
    edildi — manifest temasının tek başına yeterli olup olmadığından bağımsız.
  - **GEÇİCİ bir çözüm olduğu AÇIKÇA belgelendi (kod içi yorumlarda da):** Google, bu bayrağın
    `targetSdk` Android 16'ya yükseltilen uygulamalarda DEVRE DIŞI/kullanılamaz hale geleceğini
    duyurdu — o noktada AdMob SDK'sının kendisinin inset'leri doğru işlemesi (kendi güncellemesiyle)
    beklenir; ama `targetSdk` Android 16'ya yükseltildiğinde bu bug'ın geri gelip gelmediği
    TEKRAR kontrol edilmeli.
- **YEDEK (fallback) çözüm — Flutter tarafında, native davranıştan TAMAMEN BAĞIMSIZ bir blur
  katmanı da EKLENDİ.** Kullanıcının açık isteği: native/SDK düzeltmesi %100 garanti değilse
  (cihaz/OEM/Android sürümüne göre davranış değişebilir), reklam gösterilirken altındaki arayüzü
  bulanıklaştırıp en azından net bir karışıklık görünmesin. Bu YEDEK olarak, native düzeltmenin
  YANINDA (onun YERİNE değil) eklendi:
  - **`lib/utils/ad_overlay_state.dart`** (YENİ) — `isAdShowing` adında global bir
    `ValueNotifier<bool>` (`homeTabRequest`/`isHomeTabActive` ile AYNI "basit paylaşılan sinyal"
    deseni, bkz. `tab_navigation.dart`) — `AdMobAdService` bir widget OLMADIĞI için
    `Provider`/`context`'e erişemiyor, bu yüzden widget ağacının dışından da yazılabilen bu
    global değişken kullanıldı.
  - **`lib/widgets/ad_blur_overlay.dart`** (YENİ) — `AdBlurOverlay`, `isAdShowing`'i dinleyip
    `true` iken `BackdropFilter(ImageFilter.blur(sigmaX: 24, sigmaY: 24))` + yarı saydam bir
    `scrim` (`colorScheme.scrim`, `alpha: 0.55`) katmanını `Positioned.fill` + `AbsorbPointer`
    ile TÜM uygulamanın üzerine bindiriyor. `main.dart`'ın `MaterialApp.builder`'ında EN DIŞTA
    (`ThemeFadeOverlay`/`AnimatedThemeOverlay`'in DIŞINDA) sarılıyor — altındaki HER ŞEYİ (AppBar
    dahil) kapsasın diye.
  - **`AdMobAdService.showRewardedAd()`/`showInterstitialAd()`** artık `ad.show(...)`
    çağrılmadan HEMEN ÖNCE `isAdShowing.value = true` yapıyor; `FullScreenContentCallback`'in
    HER İKİ dalında (`onAdDismissedFullScreenContent`/`onAdFailedToShowFullScreenContent`) VE
    `ad.show()` çevresindeki `catch` bloğunda `false`'a geri döndürülüyor, ayrıca metodun
    SONUNDA bir güvenlik ağı olarak bir kez daha `false`'a ayarlanıyor (üç ayrı çıkış yolundan
    biri kaçırılırsa diye). **Reklam kendisi tam ekranı düzgün kapladığında bu blur ZARARSIZ**
    (native Activity'nin ARKASINDA/ALTINDA kalır, hiç GÖRÜNMEZ) — yalnızca bug tekrarlarsa devreye
    giriyor.
- **Doğrulama:** `flutter test` (256/256) + `flutter build apk --debug` sorunsuz derlendi,
  birleştirilmiş manifest elle incelenip `AdActivity`'nin doğru temayı aldığı doğrulandı, APK
  telefona kurulup uygulama çöküş olmadan açıldı (`adb shell monkey` + `pidof`). **Gerçek bir
  reklam gösterilirken canlı GÖRSEL doğrulama bu turda YAPILMADI** (rapid-tap interstitial
  akışını TEKRAR cihazda tetiklemek, önceki oturumda gerçek kullanıcının cihazını yanlışlıkla
  etkileyen olaylar yüzünden BİLEREK denenmedi) — güven, (a) resmi Google/AdMob kaynağından
  doğrulanmış, hedefe TAM isabet eden bir kök neden + düzeltme, VE (b) native düzeltme yetersiz
  kalsa bile devreye girecek, native davranıştan bağımsız/garantili bir Flutter-taraflı yedek
  katmana dayanıyor. **Kullanıcının kendi cihazında doğrulaması gereken:** Mağaza/Şans
  Çarkı'ndan bir reklam tetiklendiğinde reklamın artık GERÇEKTEN tam ekranı kapladığı, üst
  kısımda Zibo'nun AppBar'ının ARTIK görünmediği — eğer hâlâ (nadiren) görünürse, bu sefer net
  bir arayüz karışıklığı yerine bulanıklaştırılmış bir arka plan görünmeli (yedek katmanın devreye
  girdiğinin kanıtı).
- **Özet — hangi çözüm uygulandı:** İKİSİ BİRDEN. (1) **Asıl/native düzeltme**:
  `AdActivity`'nin manifest temasının `tools:replace` ile override edilmesi (+ `MainActivity`'ye
  savunmacı bir kod satırı) — bu, kök nedeni doğrudan hedefleyen, resmi Google kaynağından
  doğrulanmış düzeltme. (2) **Flutter-taraflı blur yedek katmanı** — native düzeltme herhangi bir
  sebeple (cihaz/OEM/sürüm farkı) tam işe yaramazsa, kullanıcının en azından net bir arayüz
  karışıklığı GÖRMEMESİNİ garanti eden, tamamen bizim kontrolümüzdeki ikinci bir savunma hattı.

### Zibo'ya Art Arda Dokunma → Geçiş (Interstitial) Reklamı / Reklamsız Zibo Teklifi ([home_screen.dart](lib/screens/home_screen.dart), [ad_service.dart](lib/services/ad_service.dart), [appodeal_ad_service.dart](lib/services/appodeal_ad_service.dart))

- **2026 yeni özellik.** Kullanıcı isteği (verbatim özet): Ana Sayfa'da Zibo'ya art arda 5-6 kez
  (birkaç saniye içinde) dokunulursa bir AdMob geçiş (interstitial) reklamı gösterilsin;
  gösterimlerin bir kısmında (%20-30 ihtimalle) reklam YERİNE Reklamsız Zibo (Zibo ADS) satın alma
  teklifi gösterilsin — İKİSİ ASLA aynı tetiklemede birlikte olmasın, dengeli bir sıklıkla dönüşümlü
  çalışsın.
- **`AdService` genişletildi — `showInterstitialAd()` (YENİ soyut metot).** `showRewardedAd()`'dan
  farkı: bir "ödül" kavramı yok, reklam GÖSTERİLEBİLDİYSE (kullanıcı erken kapatsa bile) `true`
  döner. `MockAdService` kısa bir gecikmeyle `true` simüle ediyor; `AdMobAdService`
  `showRewardedAd()`/`_loadAd()` ile BİREBİR AYNI ön-yükleme deseninin `InterstitialAd`
  karşılığını (`_loadInterstitialAd()`) kullanıyor — SDK'da `RewardedAd`/`InterstitialAd` farklı
  sınıflar/yükleme API'leri olduğu için ayrı bir alan seti gerekiyor ama mantık birebir aynı
  (preload + 8sn zaman aşımı + gösterimden hemen sonra bir sonrakini arka planda yükleme).
  - **`AdMobConfig.interstitialAdUnitId`** (YENİ, `null`) — kullanıcı henüz AdMob Console'dan gerçek
    bir Geçiş reklam birimi OLUŞTURMADI; `null` olduğu sürece `AdMobAdService`, Google'ın herkese
    açık test Geçiş reklam birimini (`AdMobAdService.testInterstitialAdUnitId`) kullanır —
    `rewardedAdUnitId`'nin ilk sürümündeki AYNI geçici durum. Kullanıcı gerçek bir ID sağladığında
    yalnızca bu TEK satır güncellenecek.
  - **`CoinProvider.showInterstitialAd()`** (YENİ, `_adService.showInterstitialAd()`'a doğrudan
    passthrough) — coin bakiyesini/işlem geçmişini HİÇ etkilemiyor, yalnızca `main.dart`'ta zaten
    gerçek AdMob ile kurulan `_adService` örneğini `HomeScreen`'den erişilebilir kılmak için buraya
    eklendi (ikinci bir `AdService` örneği/kablolaması gerekmesin diye — `HomeScreen`'in kendi ayrı
    bir `AdMobAdService` kurması yerine `context.read<CoinProvider>().showInterstitialAd()`
    çağrılıyor).
- **`HomeScreen`'de art arda dokunma algılama:** `_recentZiboTaps` (`List<DateTime>`) her
  `_onZiboTap()`'te güncellenip son 3 saniye dışına düşenler atılıyor
  (`_rapidTapWindow = Duration(seconds: 3)`); listede `_rapidTapThreshold` (5) veya fazlası
  birikince liste sıfırlanıp `_showRapidTapPromoOrAd()` tetikleniyor. `AdFreePromoTrigger`/
  `WheelTriggerButton` ile AYNI `DateTime.now().difference(...)` gerçek-zaman deseni — bu ekranda
  başka yerde kalıcılık gerektirmeyen saf/geçici bir pencere olduğu için ayrı bir enjekte edilebilir
  saate gerek YOK.
  - **`_showRapidTapPromoOrAd()`** — `_adPromoRandom.nextDouble() < 0.25` (kullanıcının "%20-30"
    ifadesinin ortası) iken `showAdFreePromoSheet(context)` (Mağaza'daki kalıcı karttan da
    kullanılan AYNI fonksiyon — bkz. "Zibo ADS" bölümü), aksi halde (yaklaşık %75)
    `context.read<CoinProvider>().showInterstitialAd()` çağrılıyor — İKİSİ aynı `if/else` dalında,
    ASLA birlikte tetiklenmiyor. `_showingRapidTapPromo` bool bayrağı bir gösterim sürerken YENİ
    bir tetiklemeyi engelliyor (üst üste binme olmasın diye).
  - **KRİTİK bug + düzeltme — `adPromoRandom` BİLEREK `_random`'dan (mesaj seçimi) AYRI bir alan.**
    İlk yazımda TEK bir `_random` alanı hem mesaj seçimi (`_pickNewMessageIndex()`'in "farklı bir
    sonuç gelene kadar tekrar dene" `do-while` döngüsü) HEM DE art arda dokunma kararı için
    kullanılıyordu. Teste SABİT bir `Random` (`_FixedRandom`, her zaman aynı `nextDouble()`
    değerini döndüren) enjekte edilince `_pickNewMessageIndex()`'in `do-while` döngüsü SONSUZA
    kadar dönüp testi (ve potansiyel olarak üretimde de aynı senaryoyu) kilitledi — çünkü
    `nextInt(...)` hep AYNI sabit değeri döndürüyor, `next == _messageIndex` hiç `false`
    olamıyordu. **Çözüm:** `HomeScreen`'in `random` parametresi `adPromoRandom` olarak yeniden
    adlandırılıp YALNIZCA `_showRapidTapPromoOrAd()`'a bağlandı; mesaj seçiminin kendi `_random`'ı
    HİÇBİR ZAMAN test parametresiyle override edilemez hale getirildi (her zaman gerçek
    `Random()`). **Ders:** bir `Random` alanını birden fazla, birbirinden bağımsız amaç için
    paylaşmak, SABİT/deterministik bir `Random` test double'ı enjekte edildiğinde (`nextInt`'in HER
    ZAMAN aynı değeri döndürdüğü senaryo) "farklı sonuç gelene kadar tekrar dene" tarzı herhangi bir
    döngüyü sessizce sonsuz döngüye çevirebilir — ayrı amaçlar İÇİN ayrı `Random` alanları kullanın.
- **Test:** YENİ `test/home_screen_rapid_tap_test.dart` (`_FixedRandom` + `_RecordingAdService` ile:
  5 dokunuşta yüksek random değeriyle interstitial çağrılır/promo AÇILMAZ; düşük random değeriyle
  promo açılır/interstitial ÇAĞRILMAZ; 4 dokunuşta — eşik dolmadan — HİÇBİRİ tetiklenmez).
- **Gerçek cihazda doğrulama — organik/kazara.** Cihaz doğrulaması sırasında (bkz. "Hedef Tamamlama
  Kutlaması" bölümündeki "gerçek cihaz paylaşım riski" notu) birkaç ıskalayan dokunma denemesi
  YANLIŞLIKLA Ana Sayfa'da 5+ hızlı Zibo dokunuşuna denk geldi ve gerçek bir AdMob test interstitial
  reklamı ("This is an interstitial test ad", Google AdMob logosu) cihazda GERÇEKTEN görüntülendi —
  bu, uçtan uca entegrasyonun (gerçek `AdMobAdService.showInterstitialAd()` → gerçek SDK → gerçek
  test reklamı) çalıştığının BEKLENMEDİK ama net bir kanıtı oldu. Reklamsız Zibo dalı (düşük
  ihtimalli yol) cihazda AYRICA doğrulanmadı — yalnızca yukarıdaki otomatik testle kanıtlanmış
  durumda.
- **2026 güncellemesi — `showInterstitialAd()`'ın İKİNCİ kullanım yeri: Günlük Giriş Ödülleri.**
  Kullanıcı isteği "birkaç aksiyondan sonra geçilebilir reklam daha ekleyelim" ile bkz. "Günlük
  Giriş Ödülleri" bölümündeki yeni bullet — ödül alınınca (`_DailyRewardsScreenState._claimDay`)
  AYNI `CoinProvider.showInterstitialAd()` çağrılıyor, %100 (probabilistik DEĞİL — art arda
  dokunma akışının aksine burada bir "ihtimal" kavramı YOK, ödül zaten günde bir kez alınabildiği
  için ek bir sıklık sınırlamasına gerek duyulmadı).
- **2026 İKİNCİ güncelleme — kullanıcı `AskUserQuestion` ile "Şans Çarkı sonucu" ve "Hedef
  tamamlama (7 gün)"nü seçti; İKİSİ de denendi, Şans Çarkı'nınki SONRADAN (bkz. altta ÜÇÜNCÜ
  güncelleme) GERİ ALINDI, Hedef Tamamlama'nınki KALICI.** İlk turda "birkaç aksiyondan sonra...
  daha ekleyelim" derken kullanıcı HANGİ diğer aksiyonları kastettiğini belirtmemişti — TAHMİN
  etmek yerine soruldu.
  - **Hedef Tamamlama (`goal_tracking_screen.dart`/`goal_card.dart`) — ÜÇÜNCÜ kullanım yeri,
    KALICI.** **BİLEREK `onMarkedToday`'e (HER gün işaretlemede tetiklenen titreşim+konfeti+ses
    kutlamasına) DEĞİL, YENİ ayrı bir `GoalCard.onCycleCompleted` callback'ine bağlandı** — bu,
    YALNIZCA 7/7 tamamlanan (`cycleCompleted == true`) dokunuşta çağrılıyor
    (`GoalCard._onTodayTap`'in zaten hesapladığı, `earnStreak7Bonus()`'u tetikleyen AYNI koşul).
    İki sinyalin AYRI tutulmasının nedeni: 7. gün dokunuşu HEM `onMarkedToday` (kutlama) HEM
    `onCycleCompleted` (reklam bayrağı) aynı anda tetikliyor — reklamı ANINDA göstermek, tam ekran
    native reklam Activity'sinin kullanıcının az önce tetiklediği titreşim/konfeti/ses
    kutlamasının ÜSTÜNE binip onu KESMESİNE yol açardı (bu kutlama CLAUDE.md'de belgeli onca ince
    ayardan sonra kullanıcının en çok önem verdiği detaylardan biri — bir reklamla yarıda kesmek
    büyük bir gerileme olurdu).
    - **`_GoalTrackingScreenState._pendingCycleCompletionAd`** (bool) — `_onCycleCompleted()`
      tarafından `true` yapılır; `_confettiController`'ın VAR OLAN `addStatusListener`'ı
      (`AnimationStatus.completed` — konfeti patlaması TAM bittiğinde, dokunuştan ~4 saniye
      sonra: 2sn titreşim + 2sn konfeti) bu bayrağı görürse `false`'a döndürüp
      `unawaited(context.read<CoinProvider>().showInterstitialAd())` çağırıyor. Reklam TAM
      kutlamanın gerçek bitiş anına (mevcut bir animasyon status listener'ına, YENİ bir
      Timer/gecikme EKLEMEDEN) bağlandığı için zamanlama otomatik doğru kalıyor.
    - **Test:** `goal_completion_celebration_test.dart`'a YENİ bir test eklendi
      (`_RecordingAdService` + enjekte edilebilir saatle: gün 1-6'da reklam HİÇ tetiklenmez; gün
      7'de dokunma ANINDA VE titreşimin ortasında VE konfeti sürerken reklam HÂLÂ `0` çağrı —
      konfeti TAM bitince `1` çağrı).
  - **Şans Çarkı sonucu (`wheel_screen.dart`) — DENENDİ, KULLANICI İSTEMEDİ, TAMAMEN GERİ
    ALINDI (bkz. hemen altta ÜÇÜNCÜ güncelleme).**
- **2026 ÜÇÜNCÜ güncelleme — Şans Çarkı sonrası reklam kaldırıldı.** İlk yazımda `_spin()`,
  `_showResultDialog(prize)` KAPANDIKTAN SONRA `showInterstitialAd()` çağırıyordu (kullanıcı
  zaten çevirmek için BİR ödüllü reklam izlemişti — `watchAdAndSpinWheel` — bu, sonuç mesajının
  ÜSTÜNE binmesin diye diyalog kapanana kadar bekletilen, coin ekonomisinden bağımsız İKİNCİ bir
  reklamdı). **Kullanıcı gerçek cihazda deneyip "hoşuma gitmedi, kaldıralım" dedi** — muhtemel
  gerekçe: çevirmek için zaten bir ödüllü reklam izlemiş kullanıcıya sonuç ekranının HEMEN
  ardından ikinci bir tam ekran reklam daha göstermek, arka arkaya iki reklam gibi hissettirip
  rahatsız edici geldi (Günlük Giriş Ödülü/Hedef Tamamlama'nın aksine, Şans Çarkı akışının
  KENDİSİ zaten BİR reklam içeriyor — "reklam üstüne reklam" hissi yalnızca bu akışa özgüydü).
  **Geri alma tamamen temiz** — `wheel_screen.dart`'taki çağrı + kullanılmayan `dart:async`
  import'u kaldırıldı, `test/wheel_screen_test.dart` (bu davranışı doğrulayan tek dosya) SİLİNDİ.
  `CoinProvider.showInterstitialAd()`'ın KENDİSİ dokunulmadı (Günlük Giriş Ödülü/Hedef Tamamlama
  hâlâ kullanıyor). **Ders:** yeni bir reklam yerleşimi eklerken, aynı akışın KENDİSİ zaten bir
  reklam içeriyorsa (Şans Çarkı'nın ödüllü çevirme reklamı gibi) ikinci bir reklam eklemek diğer
  (reklamsız) akışlardan (Günlük Giriş Ödülü, Hedef Tamamlama) FARKLI bir kullanıcı algısı
  yaratabilir — "birkaç yer daha ekleyelim" gibi genel bir istekte her yer eşit derecede uygun
  olmayabilir, kullanıcı geri bildirimiyle teker teker doğrulanmalı.
- **Doğrulama (Hedef Tamamlama, KALICI özellik):** `flutter build apk --debug` + cihaza kurulum +
  `adb shell monkey`/`pidof` ile çöküş olmadan açıldığı doğrulandı — reklamın gerçek cihazda
  GÖRSEL olarak (özellikle kutlama animasyonunun gerçekten KESİLMEDİĞİ, reklamın tam ~4 saniye
  SONRA geldiği) doğrulanması kullanıcının kendi cihazında yapılmalı.

