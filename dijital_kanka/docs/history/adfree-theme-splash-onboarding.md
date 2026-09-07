# ARŞİV — Zibo ADS mockup, Tema (fade), Açılış ekranı, Onboarding

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 3413–3746).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

### Zibo ADS (reklamsız deneyim mockup'ı) ([ad_free_promo_trigger.dart](lib/utils/ad_free_promo_trigger.dart), [ad_free_promo_sheet.dart](lib/widgets/ad_free_promo_sheet.dart))
- **2026 yeni özellik — TAMAMEN GÖRSEL BİR MOCKUP, gerçek bir satın alma akışı YOK.** Kullanıcı
  isteği (verbatim özet): Mağaza ziyaretlerinde ara sıra gösterilen, üstte kırmızı bir "Zibo ADS"
  şeridi olan, reklamsız olmanın faydalarını listeleyen, "Satın Al" butonu ŞİMDİLİK yalnızca bir
  "Yakında!" mesajı gösteren, kullanıcının kapatabildiği (zorunlu olmayan) bir tanıtım ekranı.
  Gerçek Google Play Billing ARTIK BAĞLI (bkz. "Google Play Billing" bölümü) ama bu spesifik
  "Satın Al" butonu HENÜZ ona BAĞLANMADI — `_maybeShowAdFreePromo`/`showAdFreePromoSheet`'in
  `onPressed`'i gerçek bir satın alma akışına (muhtemelen `PurchaseService` soyutlamasına,
  `CoinProvider`'ın kullandığı desenle aynı) bağlanacak — bu ARAYÜZ/TETİKLEME kablolaması o zaman
  DEĞİŞMEYECEK, yalnızca buton içindeki eylem.
- **`AdFreePromoTrigger`** — Mağaza ziyaretine göre tetiklenen bir kural.
  **2026 güncellemesi — kullanıcı raporu: "çok sık/rahatsız edici çıkıyor".** İlk sürüm YALNIZCA
  oturum bazlı bir sayaçtı (her 3. Mağaza ziyaretinde, kalıcılık YOK — uygulama yeniden açılınca
  sıfırlanıyordu) — kullanıcı Mağaza'yı sık ziyaret ettikçe (ör. kostüm/tema satın alırken) bu HER
  OTURUMDA yeniden tetiklenip rahatsız edici bir sıklığa yol açtı. Artık İKİ kısıtlama BİRLİKTE
  uygulanıyor:
  1. En az `_visitsPerAttempt` (eskiden 3, şimdi **5**) Mağaza ziyareti.
  2. En son gösterimden bu yana en az `_cooldown` (**3 gün**) geçmiş olması — bu artık
     `SharedPreferences` ile KALICI (uygulama kapatılıp yeniden açılsa bile hatırlanıyor), çünkü
     kullanıcı deneyimini asıl bozan OTURUMLAR ARASI tekrardı.
  - **`initialize()`** — `main()`'de, `runApp`'tan ÖNCE `await AdFreePromoTrigger.initialize()` ile
    çağrılır; en son gösterim zamanını kalıcı depodan belleğe yükler. **Yüklenene kadar
    `shouldShowOnStoreVisit()` HİÇBİR ZAMAN `true` DÖNMEZ** — bu, kalıcı veriyi henüz görmeden
    (teorik olarak `initialize()` tamamlanmadan bir Mağaza ziyareti gerçekleşirse) yanlışlıkla
    erken/sık göstermeyi engelleyen güvenli bir varsayılan. Kalıcı depo okunamazsa (ör.
    `flutter_test` ortamı) try/catch ile yutulur, `_lastShownAt` `null` kalır — yalnızca ziyaret
    sayacına göre karar verilir.
  - `shouldShowOnStoreVisit()` her çağrıldığında sayacı artırır; eşik dolmadıysa VEYA cooldown
    henüz geçmediyse `false` döner. `true` dönerken `_lastShownAt`'ı günceller VE
    `unawaited(_persistLastShown())` ile arka planda (`SharedPreferences`) kalıcı hale getirir —
    yazma başarısız olursa (test ortamı) yalnızca kalıcılık kaybolur, davranış bozulmaz.
  - `resetForTest({bool loaded, DateTime? lastShownAt})` — hem sayacı SIFIRLAR hem
    `initialize()`'ın yüklediği durumu (`loaded`/`lastShownAt`) simüle eder. `widget_test.dart`'ın
    global `setUp()`'ında parametresiz çağrılıyor (`loaded: true, lastShownAt: null` — "hiç
    gösterilmemiş, kalıcı veri yüklü" varsayılan durumu), aksi halde bir testteki Mağaza
    ziyaretleri SONRAKİ testlerin sayacını kirletirdi (aynı test ikili dosyasında art arda
    koştukları için).
  - **Test:** YENİ `test/ad_free_promo_trigger_test.dart` (yüklenmeden önce hiç `true` dönmez, tam
    5. ziyarette `true` döner, hemen ardından — cooldown dolmadığı için — tekrar `true` DÖNMEZ,
    cooldown içindeyken eşik dolsa bile `false`, cooldown dışındayken eşik dolunca `true`).
- **`showAdFreePromoSheet`** — `showModulesMenuSheet` ile AYNI `showModalBottomSheet` deseni
  (`showDragHandle: true`). Üstte sabit kırmızı (`0xFFD32F2F`, aktif temadan/açık-koyu moddan
  BİLEREK BAĞIMSIZ — gerçek dünya promosyon banner'ları genelde kendi marka rengini korur)
  `_RedBanner` + üç fayda satırı (`Icons.block`/`bolt_outlined`/`favorite_outline`) + "Satın Al"
  (`FilledButton`, `key: Key('adFreePromoBuyButton')`) + "Belki Sonra" (`TextButton`,
  `key: Key('adFreePromoDismissButton')`). **"Satın Al"a basınca:** sheet kapanır +
  `l10n.adFreePromoComingSoon` ("Yakında! Reklamsız deneyim çok yakında sunulacak.") metniyle bir
  `SnackBar` gösterilir — gerçek bir satın alma/coin harcaması YOK. "Belki Sonra" veya sürükleme
  tutamacı/dışarı dokunma ile sheet hiçbir yan etki olmadan kapanır (zorunlu değil).
  - **2026 güncellemesi — buton YAZISI yerine gerçek fiyat gösteriliyor (159,90 ₺).** Kullanıcı
    isteği: "Satın Al" metni yerine `adFreePromoPrice` (YENİ, `ad_free_promo_sheet.dart`'ta
    top-level `const` — `CoinPackage`'ın zaten var olan `PackagePrice` modeli YENİDEN
    KULLANILDI, ayrı bir fiyat tipi icat edilmedi) gösterilsin, arayüz diline göre sayı formatı
    uyarlanabilsin (gerçek çoklu para birimi DEĞİL, "şimdilik format olarak" — kullanıcının kendi
    ifadesi). `PackagePrice`'a `formattedForLocale(String languageCode)` metodu eklendi
    (`formatted` getter'ı DOKUNULMADAN kaldı — Mağaza'daki mevcut coin paketi kartları hâlâ onu
    kullanıyor, geriye dönük uyumluluk). `formatCurrencyAmount`'a (`utils/currency_format.dart`)
    opsiyonel bir `languageCode` parametresi eklendi: `'en'` iken nokta-ondalık/virgül-binlik
    (`"159.90 ₺"`), aksi halde (varsayılan, `'tr'`/`'es'`) virgül-ondalık/nokta-binlik
    (`"159,90 ₺"`) — **para birimi sembolü (`₺`) HİÇBİR dilde değişmiyor**, yalnızca sayının
    yazım biçimi. `showAdFreePromoSheet`, `Localizations.localeOf(context).languageCode`'u
    okuyup `adFreePromoPrice.formattedForLocale(...)`'i butonun `child`'ı olarak kullanıyor —
    `l10n.adFreePromoBuyButton` ARB anahtarı artık KULLANILMIYOR (silinmedi, proje geneli
    convansiyon). **İleride gerçek çoklu para birimi eklenmek istenirse** yalnızca
    `PackagePrice.currencyCode`'u (ör. `'USD'`) locale'e göre seçip `formatCurrencyAmount`'a yeni
    bir `case` eklemek yeterli olacak — `showAdFreePromoSheet`/UI kodu değişmeyecek.
  - **Test:** `currency_format_test.dart`'a `languageCode` parametresini kapsayan 3 yeni test
    eklendi (`'en'` iken nokta-ondalık, varsayılan/`'es'` iken virgül-ondalık). Mevcut Zibo ADS
    uçtan uca senaryoları (aşağıda) bu değişiklikten etkilenmedi — hâlâ `Key`'e göre buton buluyor,
    metne göre DEĞİL.
  - **Butonlara `Key` eklenmesi kasıtlı:** "Satın Al" metni Mağaza'daki kostüm/tema kartlarının
    "Satın Al" butonlarıyla AYNI (bkz. "Kostümler" bölümü) — `find.text('Satın Al')` testte
    BİRDEN FAZLA widget bulup `tap()`'i belirsiz hale getiriyordu (gerçekten yaşandı, ilk test
    yazımında yakalandı). **Çözüm:** her iki butona sabit bir `Key` eklendi, testler `find.text`
    yerine `find.byKey(...)` kullanıyor — Mağaza'daki metin çakışan başka bir butonla birlikte
    kullanılan her yeni sheet/dialog butonunda bu deseni tekrarlayın.
- **Tetikleme — `StoreScreen`'e YENİ bir `isActive` parametresi eklendi** (`GoalTrackingScreen` ile
  BİREBİR AYNI desen — bkz. "Mimari özet" bölümündeki `IndexedStack` gotcha'sı): varsayılan `true`
  (Mağaza'yı push edilen ayrı bir sayfa olarak açan `costume_closet_preview.dart` gibi yerler
  etkilenmesin diye), `RootScreen` kendi `IndexedStack`'inde `StoreScreen(isActive: _selectedIndex
  == _storeTabIndex)` geçiriyor. `_StoreScreenState.initState`/`didUpdateWidget`
  (`widget.isActive && !oldWidget.isActive` — "az önce görünür oldu" anı) `_maybeShowAdFreePromo()`'yu
  çağırıyor, bu da `AdFreePromoTrigger.shouldShowOnStoreVisit()`'e bakıp `true` ise
  `WidgetsBinding.instance.addPostFrameCallback` ile (build tamamlanmadan `showModalBottomSheet`
  çağırmak güvenli değil, `RootScreen`'in pil optimizasyonu promptuyla AYNI gerekçe)
  `showAdFreePromoSheet`'i açıyor.
  - **Hem alt gezinme çubuğunun "Mağaza" sekmesi HEM AppBar'ın "Coin satın al" ('+') ikonu AYNI
    `_selectedIndex = _storeTabIndex` state değişimini tetikliyor** (bkz. `root_screen.dart`) —
    ikisi de eşit şekilde bir "Mağaza ziyareti" sayılır, tetikleyici mantığında özel bir ayrım
    gerekmedi.
- **Test:** `widget_test.dart`'a ÜÇ uçtan uca senaryo — (1) art arda BEŞ Mağaza ziyareti (aralarda
  başka bir sekmeye geçilerek `isActive` geçişi tetiklenir) → 1-4. ziyaretlerde sheet
  GÖRÜNMEZ, 5. ziyarette görünür + banner/fayda metinleri doğru + "Satın Al"a basınca sheet
  kapanır ve "Yakında!" SnackBar'ı görünür; (2) aynı beş-ziyaret deseni + "Belki Sonra"ya basınca
  sheet hiçbir SnackBar göstermeden kapanır; (3) YENİ — `AdFreePromoTrigger.resetForTest
  (lastShownAt: DateTime.now())` ile "az önce gösterildi" durumu simüle edilip, eşik (5) dolsa
  bile 3 günlük cooldown henüz geçmediği için sheet'in HİÇ AÇILMADIĞI doğrulanıyor.
  `widget_test.dart`'ın global `setUp()`'ında `AdFreePromoTrigger.resetForTest()`
  parametresiz çağrılıyor (diğer testlerin store ziyaretlerinin/cooldown durumunun bu testlerin
  sayacını kirletmemesi için).
- **`main.dart`'a bağlama:** `main()`'e `await AdFreePromoTrigger.initialize();` eklendi
  (`WidgetsFlutterBinding.ensureInitialized()`'dan hemen sonra, `runApp`'tan ÖNCE) — bkz. yukarıdaki
  `initialize()` notu.
- **Gerçek cihazda doğrulama:** APK derlenip telefona kurulup Mağaza'ya art arda 3 kez girilerek
  kırmızı "Zibo ADS" banner'ı + üç fayda satırı + "Satın Al"/"Belki Sonra" butonlarının doğru
  render olduğu, "Satın Al"a basınca sheet'in kapanıp herhangi bir gerçek işlem yapmadan mockup
  akışın tamamlandığı ekran görüntüleriyle doğrulandı (koyu temada). **2026 sıklık güncellemesi**
  (5 ziyaret eşiği + 3 günlük cooldown) `flutter test`'teki unit/widget testleriyle kapsanıyor —
  cooldown'ın gerçek cihazda GÜNLER SÜREN bir bekleme gerektirmesi yüzünden bu spesifik davranış
  ayrıca elle telefonda doğrulanmadı (mantığı test edilen, saf/deterministik bir fonksiyon olduğu
  için risk düşük).
- **2026 üçüncü güncelleme — Mağaza'da KALICI bir "Reklamsız Zibo" kartı** ([store_screen.dart](lib/screens/store_screen.dart)).
  Kullanıcı isteği (verbatim özet): reklamsız paketin yalnızca ara sıra çıkan bildirimle değil,
  kullanıcı istediğinde Mağaza'dan da satın alınabilmesi — "no ads logosu kullanabilirsin eğer
  yapamıyorsan bana söyle ben tasarlarım" notuyla. `_BuyCoinsSection.build()` artık "Coin Al"
  sekmesinin EN ÜSTÜNE (mevcut "Ücretsiz" bölümünden ÖNCE) yeni bir "Reklamsız Zibo" başlığı + YENİ
  `_AdFreeCard` widget'ı render ediyor.
  - **İkon seçimi:** Bu ortamda özel görsel/logo üretme yeteneği YOK — kullanıcının kendi
    önerdiği yedek plana göre `Icons.workspace_premium` (Material ikon, `_RedBanner`'ın kendi
    ikonuyla AYNI marka rengi `0xFFD32F2F`) kullanıldı. Kullanıcı isterse kendi tasarladığı bir
    PNG/SVG logo verip bunun yerine koydurabilir — bu değişiklik yalnızca `_AdFreeCard`'ın ikon
    `Widget`'ını değiştirmeyi gerektirir, başka hiçbir yeri etkilemez.
  - **Buton davranışı:** `_AdFreeCard`'ın fiyat etiketli (`159,90 ₺`) `FilledButton`'ı doğrudan
    `showAdFreePromoSheet(context)`'i çağırıyor — `AdFreePromoTrigger`'ın periyodik
    ziyaret-sayacı/cooldown kısıtlaması BU YOLDAN GEÇMİYOR (o kısıtlama yalnızca
    `StoreScreen._maybeShowAdFreePromo()`'nun kendiliğinden/otomatik açılışına uygulanıyor) — bu,
    "kullanıcı istediğinde açabilsin" isteğiyle KASITLI olarak uyumlu, ayrı bir bypass mekanizması
    YAZILMADI, zaten mevcut olan `showAdFreePromoSheet` fonksiyonu başka bir yerden çağrıldı.
  - **YENİ ARB anahtarları — mevcut sheet metniyle BİLEREK farklı:** `storeAdFreeSectionTitle`
    ("Reklamsız Zibo"), `storeAdFreeCardTitle` ("Reklamları Kaldır"), `storeAdFreeCardSubtitle`
    ("Tüm reklamları kalıcı olarak kapat") — sheet'in kendi `adFreePromoTitle`/`adFreePromoSubtitle`
    ("Zibo ADS"/"Reklamsız Deneyim") metinleri YENİDEN KULLANILMADI. **Neden:**
    `widget_test.dart`, periyodik promo sheet'in görünürlüğünü `find.text('Zibo ADS')` ile
    (`findsNothing`/`findsOneWidget`) doğruluyor — kalıcı kart AYNI metni kullansaydı bu metin
    Mağaza'da HER ZAMAN mevcut olurdu ve o testler yanlış geçer/kırılırdı. Farklı metin kullanmak
    bu çakışmayı kökten önledi.
  - **Test + doğrulama:** `flutter gen-l10n` çalıştırıldı, tam `flutter test` (249/249 geçti — yeni
    kartın metniyle mevcut testler arasında çakışma YOK). `flutter build apk --debug` + cihaza kurulum
    + ekran görüntüsüyle kartın "Coin Al" sekmesinde "Ücretsiz" bölümünden ÖNCE, doğru ikon/başlık/alt
    metin/fiyatla render olduğu görsel olarak doğrulandı. Butona basınca sheet'in gerçekten açıldığını
    dokunarak doğrulama, test cihazının o sırada kullanıcı tarafından eş zamanlı kullanılıyor olması
    (Manifest Günlüğü'ne canlı metin girişi) nedeniyle YARIDA kesildi — veri kaybı riskini önlemek
    için ek `adb input tap` gönderilmedi; kod yolu (`onPressed: () => showAdFreePromoSheet(context)`)
    zaten aynı, kanıtlanmış fonksiyonu çağırdığından ek riski düşük kabul edildi.
- **2026 DÖRDÜNCÜ güncelleme — `showAdFreePromoSheet`'in ÜÇÜNCÜ tetikleme yolu.** Artık sheet üç
  yerden açılabiliyor: (1) periyodik otomatik promo (`AdFreePromoTrigger`, sayaç+cooldown'lu), (2)
  Mağaza'daki kalıcı "Reklamsız Zibo" kartı (yukarıda, sınırsız/anında), (3) Ana Sayfa'da Zibo'ya
  art arda hızlı dokunulunca — bkz. "Zibo'ya Art Arda Dokunma → Geçiş Reklamı" bölümü — %20-30
  ihtimalle interstitial reklam YERİNE. Fonksiyonun kendisi HİÇ değişmedi, yalnızca üçüncü bir
  çağıran eklendi — bu da tasarımın "tek bir mockup fonksiyonu, birden fazla tetikleyici" ilkesinin
  ne kadar iyi ölçeklendiğinin bir göstergesi.

## Tema ([main.dart](lib/main.dart), [theme_provider.dart](lib/providers/theme_provider.dart), [theme_fade_overlay.dart](lib/widgets/theme_fade_overlay.dart))

- Sıcak bal/hardal/krem palet — renkler `ColorScheme.fromSeed`'in otomatik türetmesine bırakılmadı,
  çünkü bu soluk/pembemsi ya da aşırı parlak sarıya kayıyordu; anahtar tonlar `main.dart`'ın başında
  elle sabit (`_mustard`, `_honey`, `_cream`, vb.).
- Koyu tema ayrı bir palet (`_darkBackground` vb.) — neredeyse siyah antrasit zemin + göz yormayan
  sarımtrak/krem metin. Görseller (Zibo, coin ikonu) değişmez, yalnızca `ColorScheme` değişir.
- Kart/buton/input ortak stilleri `_buildTheme(ColorScheme)` fonksiyonunda **tek yerde** tanımlı; açık
  ve koyu tema aynı fonksiyonu farklı `ColorScheme` ile çağırıyor (kopyala-yapıştır yok).
- Tercih `SharedPreferences` ile kalıcı (`ThemeProvider`, key: `isDarkMode`).
- **`AnimatedTheme` bilerek kullanılmıyor** — tüm `ThemeData` ağacını her karede interpolasyona
  çalışmak pahalıydı (IndexedStack'teki görünmeyen sekmeler dahil ~60fps yeniden çizim) ve
  buton/kart gibi alt temalar düzgün interpolasyon desteklemediği için görsel takılmaya yol
  açıyordu. Bunun yerine `ThemeFadeOverlay`: tema anında değişir, üstüne yeni arka plan renginde
  kısa bir opaklık "perdesi" konup hemen açılır — ucuz ve pürüzsüz.

### Açılış yükleme ekranı ([app_loading_screen.dart](lib/widgets/app_loading_screen.dart))

- **Kullanıcı raporu:** Firestore migrasyonundan sonra uygulama açılışında 2-3 saniye native
  splash (artık markalı — bkz. altta) + ardından 1-2 saniye "sıfırlanmış gibi duran" bir ekran
  görünüyordu — `RootScreen` hemen kuruluyor ama provider'lar (artık Firestore'dan da okuyan
  `CloudStateStore.load()`'lar yüzünden daha uzun süren) asenkron yüklenirken kullanıcı önce
  varsayılan/boş durumu (açık tema, sıfır bakiye, giyisisiz Zibo) görüp SONRA gerçek veriye
  "zıplayan" bir geçiş yaşıyordu.
- **Native splash markalandı:** `android/app/src/main/res/drawable*/launch_background.xml`
  (light/dark × pre-v21/v21+, 4 varyant) artık Flutter'ın varsayılan boş beyaz/siyah şablonu
  değil, `main.dart`'taki `_cream`/`_darkBackground` renkleriyle aynı zemin üzerinde ortalanmış
  `zibo_splash_logo.png` (bkz. `drawable-nodpi/`, `zibo_logo_new.png`'den 600px genişliğe
  küçültülmüş kopya) gösteriyor. Ham hex renk (`#FFF8E8` gibi) doğrudan bir `layer-list`
  `<item android:drawable="...">` içine yazılınca AAPT2 "incompatible with attribute drawable
  reference" hatası veriyor — bu yüzden renkler `values/colors.xml`'de `@color/zibo_splash_light`/
  `@color/zibo_splash_dark` olarak tanımlanıp öyle referans edildi. `styles.xml`'deki
  `NormalTheme.windowBackground` de aynı renklere sabitlendi (native splash'ten Flutter'ın ilk
  frame'ine geçişte HİÇBİR renk uyuşmazlığı olmasın diye).
- **Flutter tarafı — `AppLoadingScreen` + `_AppStartupGate`:** `main.dart`'taki
  `DijitalKankaApp`'in `MaterialApp.home`'u artık doğrudan `RootScreen` değil, `_AppStartupGate`
  adında küçük bir `StatelessWidget` — YEDİ provider'ın (`ThemeProvider`, `AppThemeProvider`,
  `LocaleProvider`, `CoinProvider`, `CostumeProvider`, `OnboardingProvider`, `ProfileProvider`)
  her biri kendi `isReady` bool'unu (`_loadFromPrefs()`'in HER çıkış yolunda — veri bulunsun/
  bulunmasın/hata olsun — unconditionally `true` yapılıp `notifyListeners()` çağrılıyor) `true`
  yapana kadar `RootScreen`/`OnboardingScreen` yerine `AppLoadingScreen` (markalı logo + nabız
  animasyonu) gösteriyor; hepsi hazır olunca `AnimatedSwitcher` (350ms) ile yumuşak çapraz-solmayla
  ya `OnboardingScreen`'e (ilk açılış) ya doğrudan `RootScreen`'e geçiyor — bkz. altta "Onboarding
  (İlk Açılış Akışı)" bölümü.
  - **2026 güncellemesi — `Consumer5` → `Consumer7` YOK, doğrudan `context.watch` zinciri:**
    Onboarding eklenirken kapıya `OnboardingProvider` VE (aşağıdaki kritik yarış koşulu düzeltmesi
    için) `ProfileProvider` eklenmesi gerekti (5 → 7 provider). `provider` paketinde `ConsumerN`
    sınıfları yalnızca `Consumer6`'ya kadar tanımlı (`grep -n "class Consumer7"` paket kaynağında
    HİÇBİR SONUÇ vermedi) — 7. provider için `ConsumerN` sugar'ı tamamen terk edilip
    `_AppStartupGate.build()` içinde ardışık YEDİ ayrı `context.watch<X>()` çağrısına geçildi
    (aynı rebuild semantiği, arity tavanı yok). **Bir 8. provider'ın bu kapıya eklenmesi
    gerekirse** aynı doğrudan-`watch` desenine bir satır daha eklemek yeterli, `ConsumerN`'e geri
    dönmeye gerek yok.
  - **Kritik yarış koşulu bulundu ve düzeltildi — `ProfileProvider`'ın kapıya EKLENMESİNİN asıl
    sebebi:** `ChangeNotifierProvider(create:)` TEMBEL olduğu için `ProfileProvider` normalde İLK
    KEZ Onboarding'in isim adımında `setName()`/`setAddressTerm()` çağrıldığı ANDA oluşturuluyordu
    — bu senkron çağrı `_name`'i hemen yazıyordu, ama AYNI constructor'ın fire-and-forget başlattığı
    `_loadFromPrefs()` o an henüz TAMAMLANMAMIŞ olabiliyordu; SONRADAN tamamlanınca (taze bir
    kurulumda kalıcı depoda henüz hiçbir şey yokken) `_name`'i boş dizeye GERİ YAZIP kullanıcının
    az önce yazdığı ismi SESSİZCE SİLİYORDU. Bu **gerçek bir üretim hatasıydı, yalnızca bir test
    artefaktı değil** — gerçek bir taze kurulumda aynı yarış aynı şekilde kullanıcının yazdığı
    ismi silebilirdi. `ProfileProvider.isReady` eklenip `_AppStartupGate`'in bu alan `true` olana
    kadar Onboarding'i HİÇ göstermemesi, Onboarding başladığında `ProfileProvider`'ın ZATEN tam
    yüklenmiş olmasını garanti ederek yarışı kökünden ortadan kaldırdı (Onboarding artık asla
    `ProfileProvider`'ın "ilk erişim" anı OLMUYOR).
  - **Diğer 9 provider (Goals/DailyRewards/Water/Gratitude/Mood/Manifest/Money/Dream/Notification)
  BİLEREK bu kapıya dahil edilmedi** — bunlar `RootScreen`'in İLK karesinde görünmüyor (ayrı
  sekmelerde/modül menüsünde), arka planda yüklenmeye devam edip kendi ekranları açıldığında
  zaten doğru veriyle görünüyorlar; hepsini beklemek başlangıcı gereksiz uzatırdı.
- **`AppLoadingScreen`'in zemin rengi bilerek `ThemeProvider.isDarkMode`'a DEĞİL, `MediaQuery.
  platformBrightnessOf(context)`'e (sistem düzeyinde açık/koyu mod) bağlı** — bu ekran
  gösterildiği anda `ThemeProvider` henüz `isReady` olmadığı için uygulama içi tercih zaten
  bilinmiyor; sistem parlaklığı hem elde her zaman hazır hem de native splash'in hangi
  varyantının (`drawable-night*` mi, `drawable` mi) gösterildiğiyle birebir aynı kaynağa dayanıyor
  — bu da native splash → Flutter loading screen geçişini görsel olarak kesintisiz kılıyor.
- **Gotcha (aynı `WheelTriggerButton` dersi tekrarlandı):** `AppLoadingScreen`'in nabız
  animasyonu `disableAnimations`'a saygı duymazsa (bkz. "Şans Çarkı" bölümündeki gotcha)
  `widget_test.dart`'taki `pumpAndSettle()` çağrıları sonsuza kadar beklerdi — aynı
  `didChangeDependencies()` + `MediaQuery.of(context).disableAnimations` deseni burada da
  baştan uygulandı, test suite hiç kırılmadı.
- Gerçek cihazda (koyu tema, MIUI) `adb`ile soğuk başlatma anında ekran görüntüsü alınarak
  doğrulandı: native splash'ten hemen sonra koyu zeminde Zibo logosu görünüyor, ~1-2 saniye sonra
  hiçbir "zıplama" olmadan doğrudan (mevcut kod-tabanlı temanın rengiyle) Ana Sayfa'ya geçiyor.

### Onboarding — İlk Açılış Akışı ([onboarding_provider.dart](lib/providers/onboarding_provider.dart), [onboarding_screen.dart](lib/screens/onboarding/onboarding_screen.dart))

- **2026 yeni özellik.** Kullanıcı isteği: uygulama İLK açıldığında (a) isim sorulsun, (b) isim
  otomatik olarak Profil'e VE hitap tercihine (varsayılan olarak) yazılsın, (c) ana modülleri
  1-2 cümleyle tanıtan adım adım bir tur olsun, (d) Zibo'nun ağzından motive edici bir kapanış
  mesajı gösterilsin, (e) bu akış YALNIZCA ilk açılışta görünsün, sonraki açılışlar direkt Ana
  Sayfa'ya gitsin.
- **`OnboardingProvider`** — diğer tüm provider'larla AYNI `CloudStateStore` deseni (Varyant A,
  TEK bir `bool` alan: `{'completed': ...}`, `onboardingState` anahtarı). `completeOnboarding()`
  yalnızca `false → true` yönünde tek seferlik bir geçiş (`_isCompleted` zaten `true` ise no-op).
  `isReady` bool'u diğer provider'larla aynı gerekçeyle var — bkz. yukarıdaki `_AppStartupGate`
  bölümü.
- **`_AppStartupGate`, `isReady` sonrası ÜÇ yönlü dallanıyor** (2 yönlü loading/root'tan
  genişletildi): `!ready` → `AppLoadingScreen`; `ready && !onboarding.isCompleted` →
  `OnboardingScreen`; `ready && onboarding.isCompleted` → `RootScreen`. Hepsi `AnimatedSwitcher`
  (350ms) ile birbirine yumuşak geçiyor — aynı çapraz-solma deseni, yalnızca üç dal.
- **`OnboardingScreen`** — `PageView` (`NeverScrollableScrollPhysics`, yalnızca "Devam Et"/"İleri"
  butonuyla ilerlenir, kullanıcı kaydırarak atlayamaz) + 9 sayfa: 1 isim adımı + 7 modül tanıtımı
  (Hedef Takibi, Su Takibi, Şükran Günlüğü, Ruh Hali, Manifest Günlüğü, Mağaza, Profil — her biri
  ilgili modülün SEKME/ekran BAŞLIĞI ARB anahtarını + YENİ bir `onboarding<X>Description` ARB
  anahtarını kullanıyor) + 1 kapanış sayfası. Üstte "Geç" butonu (isim sayfasında GİZLİ — isim
  girilmeden akış atlanamaz), altta nokta göstergesi + `ValueListenableBuilder<TextEditingValue>`
  ile isim `TextEditingController`'ını izleyen, isim boşken devre dışı kalan bir `FilledButton`.
  - **İsim ANINDA hem Profil'e hem hitap tercihine yazılır:** `_goNext()` isim sayfasından
    ayrılırken (`trim()` boş değilse) `context.read<ProfileProvider>().setName(name)` VE
    `.setAddressTerm(name)`'i AYNI ANDA çağırıyor — kullanıcının "isim otomatik olarak hem Profil
    hem hitap tercihine varsayılan olarak yazılsın" isteği tam olarak bu iki çağrı. (Kullanıcı
    Profil'den sonra hitap tercihini ayrıca değiştirebilir, bu yalnızca bir başlangıç değeri.)
  - **Kapanış sayfası** `context.watch<ProfileProvider>().name`'i okuyup `onboardingClosingMessage
    (name)` ARB placeholder'ıyla ismi mesaja gömüyor — "Hadi Başlayalım!" butonuna basınca
    `OnboardingProvider.completeOnboarding()` çağrılıp `_AppStartupGate` otomatik olarak
    `RootScreen`'e geçiyor (ayrı bir `Navigator.push`/`pop` YOK, tamamen gate'in kendi state'i
    üzerinden).
  - **`static const _totalPages` elle sabitlenmiş bir tamsayı, `_moduleIntros.length`'ten
    TÜRETİLMEDİ** — Dart'ta `List.length`, `const` bir liste üzerinde bile bir `static const`
    ifadesinde kullanılamıyor (derleme hatası: "The property 'length' can't be accessed... in a
    constant expression"). **`_moduleIntros` listesi değişirse bu sabit ELLE güncellenmeli**
    (1 dil + 1 isim + modül sayısı + 1 kapanış — 2026 güncellemesiyle 11'e çıktı, bkz. altta
    "modül tanıtım tonu ve Rüya Günlüğü eklendi" notu).
- **Gerçek bir üretim bug'ı bu özellik eklenirken bulundu ve düzeltildi** — bkz. yukarıdaki
  `_AppStartupGate` bölümündeki "Kritik yarış koşulu" notu: `ProfileProvider`'ın tembel
  oluşturulması, Onboarding'in `setName()` çağrısıyla `_loadFromPrefs()`'in asenkron tamamlanması
  arasında bir yarışa yol açıp kullanıcının yazdığı ismi sessizce silebiliyordu; `ProfileProvider.
  isReady` + `_AppStartupGate`'e eklenmesiyle kalıcı olarak çözüldü.
- **Test:** `onboarding_provider_test.dart` (yeni provider tamamlanmamış başlar, `completeOnboarding`
  kalıcı olur). `widget_test.dart`'a tam bir uçtan uca senaryo (isim boşken "Devam Et" devre dışı →
  isim girilince aktifleşir → 7 modül sayfasında "İleri" → kapanışta isim geçer → "Hadi
  Başlayalım!" → Ana Sayfa açılır → Profil'de isim doğru görünür).
  - **Yeni test helper'ı `_pumpPastOnboarding(tester, app)`** — `widget_test.dart`'taki
    MEVCUT ~30 `pumpWidget`+`pumpAndSettle()` çağrı ÇİFTİNİN tamamının yerini aldı (Onboarding
    eklenmeden önce tüm testler doğrudan `RootScreen`'e düşüyordu; artık `DijitalKankaApp`
    ÖNCE Onboarding'i gösteriyor, bu yüzden HER testin önce ismi girip "Devam Et"e basıp "Geç"e
    basarak Onboarding'i atlaması gerekiyor). **`_buildAppWithClock()` kullanan 2 test SİTESİ
    BİLEREK bu helper'a çevrilMEDİ** — o yardımcı bare `MaterialApp(home: RootScreen())` kurup
    `OnboardingProvider`/`_AppStartupGate`'i hiç kullanmıyor, doğrudan `RootScreen`'e düşmeye
    devam ediyor.
  - **Gotcha — `enterText()` kendi başına bir frame pump'lamaz:** `_pumpPastOnboarding` içinde
    `tester.enterText(...)` ile `tester.tap(find.text('Devam Et'))` arasına `await tester.pump();`
    EKLENMESİ gerekti — yoksa `ValueListenableBuilder` ile izlenen butonun `onPressed`'i henüz
    `null` (devre dışı) halde kalıyor, tap fiziksel olarak "başarılı" ama işlevsel olarak no-op
    oluyordu (sayfa ilerlemiyordu). **Bir `TextEditingController`'ın değerine bağlı, `enterText()`
    hemen ardından etkileşime girilecek bir widget varsa (buton enabled/disabled durumu gibi) araya
    açık bir `pump()` koyun.**
- **Gerçek cihazda doğrulama (2026 Arc E):** `flutter build apk --debug` + `flutter install
  --debug` ile TAZE bir kurulum yapıldı (eski sürüm önce kaldırıldığı için `SharedPreferences`
  boş — bu da gerçek "ilk açılış" senaryosunu tetikliyor). Uygulama `adb shell monkey` ile
  başlatılıp logcat'te `FATAL EXCEPTION`/`AndroidRuntime`/uygulamaya özgü `Exception` aranarak
  ÇÖKMEDEN açıldığı doğrulandı, `adb shell pidof` ile sürecin canlı kaldığı teyit edildi. **Ekran
  görüntüsü BİLEREK ALINMADI** — cihazın o an kilit ekranında olma ihtimaline karşı (bkz. bu
  oturumda daha önce yaşanan bir gizlilik olayı — kilit ekranı yanlışlıkla yakalanıp hemen
  silinmişti), yalnızca metin tabanlı (logcat/pidof) doğrulama tercih edildi. **Kullanıcının kendi
  cihazında GÖRSEL olarak doğrulaması gereken kısımlar:** Onboarding akışının uçtan uca görsel
  akıcılığı/animasyonları, büyütülmüş paylaşım kartının (özellikle Profil kartı gibi çok satırlı
  mesajlarda) artık düzgün dizildiği, Hitap Tercihi'nin serbest metin kutusunun ekranda doğru
  göründüğü, ve galeri fotoğrafı seçerken HİÇBİR izin diyaloğu göstermeden doğrudan sistem Photo
  Picker'ının açıldığı — kod tarafı `flutter test`'teki 187 testle kapsanıyor ama bunların hiçbiri
  gerçek bir görsel/izin diyaloğu doğrulaması yerine geçmez.
- **2026 güncellemesi — her modülün "neden var olduğu" tek cümlede netleştirildi + Rüya Günlüğü
  eklendi.** Kullanıcı isteği: her modül için tek cümlelik, net bir "bu ne işe yarıyor" tanımı
  yaz ve onboarding'de göster (kendi örnekleri: "Hedef Takibi: Büyük hayallerini küçük adımlara
  böl", "Rüya Günlüğü: Bilinçaltının sana ne anlattığını keşfet").
  - **7 mevcut `onboarding<X>Description` ARB metni YENİDEN YAZILDI** — eski ton "ne yap + ne
    kazanırsın" idi (iki tümce, em-dash'li, ör. eski Hedef Takibi: "Kendi hedeflerini belirle,
    her gün işaretle — 7 günlük bir seriyi tamamladığında Zibo Coin kazanırsın"), yeni ton
    kullanıcının istediği kısa/punchy/amaç-odaklı tek cümle (ör. yeni Hedef Takibi: "Büyük
    hayallerini küçük adımlara böl"). `onboarding_screen.dart`'ta HİÇBİR kod değişikliği
    gerekmedi — `_moduleIntros`'un `description` alanları zaten ARB anahtarlarına işaret
    ediyordu, yalnızca ARB metinleri değişti.
  - **Rüya Günlüğü onboarding'de HİÇ YOKTU** — kullanıcı onu ikinci örnek olarak verdiği için
    8. bir `_ModuleIntro` olarak EKLENDİ (`Icons.nights_stay_outlined`, Ruh Hali Takibi'nin
    HEMEN ardına, Manifest'ten ÖNCE — ikisi de "iç dünya" temalı, Rüya↔Ruh Hali korelasyon
    özelliğiyle [bkz. "Rüya Günlüğü" bölümü] de tematik olarak örtüşüyor). Yeni
    `onboardingDreamJournalDescription` ARB anahtarı + `_totalPages` elle 10'dan 11'e çıkarıldı.
  - **Test:** `widget_test.dart`'ın onboarding e2e senaryosu 7→8 modül sayfasına (dolayısıyla
    7→8 "İleri" döngüsüne) göre güncellendi — CLAUDE.md'de defalarca belgelenen "sayfa eklenince
    sabit sayaç kırılır" dersinin bir tekrarı. **Toplam: 317 test** (sayı DEĞİŞMEDİ — mevcut bir
    test güncellendi, yeni bir test EKLENMEDİ).

