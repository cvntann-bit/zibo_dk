# ARŞİV — Ayarlar, yerel Bildirimler (rafta), Zibonu Paylaş, Alt Gezinme Çubuğu

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 1813–2485).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

### Ayarlar ([settings_screen.dart](lib/screens/settings_screen.dart), [legal_placeholder_screen.dart](lib/screens/legal_placeholder_screen.dart))
- **2026 güncellemesi — üç bölüm başlığı altında gruplandı: Genel/Destek/Uygulama Hakkında**
  (kullanıcı isteği: "mevcut ayar kategorilerini mantıklı gruplar halinde başlıklarla ayır, dağınık
  görünüyor"). Başlıklar sade `Text` widget'ları (`Theme.of(context).textTheme.labelLarge`,
  `colorScheme.primary` renginde) — Mağaza'daki `_BuyCoinsSection`'ın "Ücretsiz"/"Coin Paketleri"
  başlıklarıyla AYNI desen, ayrı bir `_SectionHeader` widget'ına gerek duyulmadı.
  - **Genel:** Koyu tema switch'i (`ThemeProvider.setDarkMode`) + Dil satırı (fonksiyonel — bkz.
    Yerelleştirme bölümü) TEK bir Card'da birleştirildi; hemen altında (varsa) Bildirimler kartı
    (bkz. aşağıdaki bölüm).
  - **Destek:** "Bize Ulaşın" — `contact@getzibo.com`'u alt metin olarak gösterip dokununca
    `url_launcher` ile `mailto:` linkini açan tek satırlık bir Card.
  - **Uygulama Hakkında** (eski "Hakkında" no-op satırının YERİNE geçti — `settingsAbout` ARB
    anahtarı "Hakkında"dan "Uygulama Hakkında"ya güncellendi, artık bölüm başlığı olarak kullanılıyor):
    - **Sürüm** — `_AppVersionRow` (YENİ, `StatefulWidget`): `package_info_plus`'ın
      `PackageInfo.fromPlatform()`'uyla `pubspec.yaml`'daki `version:`'ı derleme zamanında okur, elle
      senkronize tutulan bir sabit YOK. `NotificationService`'teki AYNI gerekçeyle try/catch'e
      sarılı (`.catchError((_) {})`) — `flutter_test` ortamında platform channel'ı olmadığı için,
      aksi halde widget testleri çökerdi; hata durumunda sessizce "—" gösterip devam eder.
    - **Web Sitesi** (`getzibo.com`, `Uri.https()` ile açılır) + **Gizlilik Politikası**/
      **Kullanım Koşulları** — ikisi de `LegalPlaceholderScreen`'e (tek parametreli `title`/`body`
      alan paylaşımlı bir widget — iki AYRI ekran dosyası yerine, ikisi de yapısal olarak birebir
      aynı olduğu için) push ediliyor. **2026 güncellemesi — artık GERÇEK içerik gösteriyor**
      (bkz. altta "Gizlilik Politikası / Kullanım Koşulları içeriği" notu) — eski ortak
      `settingsLegalPlaceholderBody` ARB metni ("Bu içerik yakında burada olacak.") KULLANILMIYOR
      artık (silinmedi, proje geneli convansiyon), her ekran KENDİ gerçek metnini alıyor.
  - **`url_launcher` ile açma başarısız olursa** (ör. cihazda hiç mail istemcisi kurulu değilse)
    `_launchOrShowError` sessizce yutmak yerine `settingsCouldNotOpenLink` metniyle bir SnackBar
    gösterir. **`AndroidManifest.xml`'in `<queries>` bloğuna `mailto:`/`https:` intent'leri
    eklendi** — Android 11+ paket görünürlüğü kısıtlaması bunlar açıkça listelenmeden
    `launchUrl()`'ün sessizce başarısız olmasına yol açardı (OEM otomatik-başlatma ayarlarını
    sorgulayan `<package>` girdileriyle AYNI gerekçe, bkz. "Bildirimler" bölümü).
  - **Test:** Telefonda doğrulandı — "Bize Ulaşın" gerçek mail uygulamasını `contact@getzibo.com`
    alıcısıyla açtı, Gizlilik Politikası/Kullanım Koşulları yer tutucu ekranları doğru başlık/gövdeyle
    push edildi. `widget_test.dart`'taki mevcut Ayarlar testi yeni bölüm başlıklarını/satırlarını
    doğrulayacak şekilde güncellendi, yer tutucu sayfalar için yeni bir uçtan uca senaryo eklendi.
  - **2026 — Gizlilik Politikası / Kullanım Koşulları içeriği yazıldı (Play Console "Teknik Yayın
    Hazırlığı" fazının Faz 3 maddesi — roadmap'te "Beraber" etiketli).** `lib/data/legal_texts.dart`
    (YENİ) — `privacyPolicyTr`/`termsOfServiceTr`, `zibo_messages.dart` gibi diğer büyük içerik
    havuzlarıyla AYNI gerekçeyle (bkz. "Yerelleştirme" bölümü) ARB'YE DEĞİL ayrı bir Dart veri
    dosyasına konuldu.
    - **Bilinçli sınırlama — YALNIZCA Türkçe, uygulama diline göre DEĞİŞMİYOR** (diğer içerik
      havuzlarından FARKLI bir karar): bir hukuki belgeyi üç dile çevirmek, çeviri
      belirsizliğinin/hatasının GERÇEK hukuki sonuç doğurabileceği bir alan — şimdilik TEK, yetkili
      bir Türkçe sürüm var (uygulamanın asıl pazarı/dili). EN/ES çevirisi istenirse profesyonel bir
      çeviri turu olarak AYRICA ele alınmalı, otomatik/hızlı çeviri YAPILMADI.
    - **`LegalPlaceholderScreen`'in `body`'si artık `SingleChildScrollView` içinde** — eski kısa
      yer tutucu metin (`Padding` + düz `Text`, kaydırma YOK) taşmıyordu, ama gerçek hukuki
      metinler çok daha uzun olduğu için kaydırma eklenmedi taşardı (bu proje genelindeki tekrarlayan
      "yeni içerik eski dar container'ı taşırıyor" ders sınıfının bir örneği daha).
    - **KRİTİK — bu bir hukuk danışmanlığı DEĞİL, uygulamanın GERÇEKTEN ne yaptığına (Firebase
      Auth/Firestore/Analytics/Messaging, AdMob, Google Sign-In, yerel fotoğraf depolama, Zibo
      Coin'in gerçek parasal değeri olmadığı) dayanan bir TASLAK.** Veri Sorumlusu + Fikri Mülkiyet
      maddelerindeki kimlik bilgisi (**Mehmet Can Tan**) kullanıcının KENDİSİ tarafından AÇIKÇA
      verildi — başlangıçta `[AD SOYAD / ŞİRKET UNVANI]` köşeli parantezli yer tutucuydu, asistan
      UYDURMADI.
    - **YAPILMASI GEREKEN — Play Console'un Data Safety formu barındırılan bir URL istiyor,
      uygulama İÇİ metin TEK BAŞINA yeterli DEĞİL.** Bu metnin `getzibo.com` (kullanıcının AYRI bir
      Claude Code oturumunda çalıştığı `zibo-website` projesi — bu oturumun ERİŞEMEDİĞİ bir proje)
      üzerinde gerçek bir sayfa olarak (ör. `getzibo.com/privacy`, `getzibo.com/terms`)
      yayınlanması gerekiyor — asistan bunu buradan YAPAMADI, yalnızca içeriği üretti.
    - **Test:** `widget_test.dart`'taki Ayarlar testi artık yer tutucu metni DEĞİL, her iki
      belgeden ayırt edici birer ibareyi (`find.textContaining('Veri Sorumlusu')`/
      `find.textContaining('Sanal Para Birimi')`) doğruluyor.
- **Coin Test Paneli kullanıcı isteğiyle tamamen kaldırıldı** (bkz. Yerelleştirme bölümü — bu, dil
  desteğiyle AYNI değişiklik setinde yapıldı). **Su Takibi'nin günlük hedef ayarı BURADA DEĞİL** —
  Su Takibi'nin kendi ekranındaki AppBar ayar ikonunda yaşıyor (bkz. "Su Takibi" bölümündeki
  Tarihçe notu; başlangıçta burada bir kart olarak yaşıyordu, modülün TEK ayarı olduğu için
  kullanıcı isteğiyle modülün kendi ekranına taşındı).
- **2026 — dış test ekibinin geri bildirim raporu incelendi, iki somut madde uygulandı.** Kullanıcı
  `Zibo_Test_Geri_Bildirim_Raporu.docx` adlı bir tester geri bildirim raporu paylaştı (Test
  Topluluğu'ndan, 5 numaralı öneri + genel öneriler). Rapor önce brainstorm edildi — beş numaralı
  önerinin İKİSİ (2. "Dinamik tanıtım turu" ve genel önerilerdeki "günlük hatırlatıcı"/"çok dilli
  destek") ZATEN uygulanmış özelliklere karşılık geliyordu (muhtemelen raporun eski bir sürümü test
  ettiği anlaşıldı — onboarding akışı ve FCM push bildirimleri raporun yazıldığı tarihte henüz yoktu
  ya da tester onlara rastlamadı), ikisi (1. ASO, 3. ekran görüntüleri) kod dışı/pazarlama işiydi.
  Kullanıcı yalnızca **4. "Uygulama İçi Puanlama İstemi"** ve **5. "Sistem Teması Desteği"**
  maddelerini seçti — ikisi de altta belgeli.
  - **4) "Bizi Puanlayın" — `rate_us_sheet.dart` (YENİ).** Raporun önerdiği düz "Uygulamanızı
    Puanlayın" metin/buton YERİNE kullanıcının kendi tasarım isteği: Zibo görseli + altta 5
    yıldızlık dokunmatik bir seçim, hangi yıldıza (1-5) dokunulursa dokunulsun AYNI sonuç —
    doğrudan Google Play Store'a yönlendirme. Gerçek bir puanlama backend'i/API'si (Google'ın
    "In-App Review API"si dahil, raporun önerdiği bir alternatifti) BİLEREK kullanılmadı — bu,
    kullanıcının ne kadar yıldız seçtiğini biz KAYDETMİYORUZ, yalnızca Play Store'un KENDİ
    puanlama arayüzüne kapı aralıyoruz; gerçek puanı toplama işi TAMAMEN Play Store'da oluyor.
    - **`showModalBottomSheet`** — `AdFreePromoSheet`/`showModulesMenuSheet` ile AYNI desen
      (`showDragHandle: true`). İçerik: `assets/images/zibo_yeni.png` (kostüm-farkındalığı
      BİLEREK yok — `AdFreePromoSheet` gibi promosyon sheet'leri bu projede hep sade tutuluyor,
      8 "modül ekranı"nın aksine) + başlık/açıklama + 5 `IconButton` (`Icons.star_rounded`/
      `star_border_rounded`, Zibo'nun altın tonu `0xFFF0C868` — `ZiboShareCard`'daki AYNI marka
      rengi).
    - **`_selectStars(count)`** — `setState` ile N yıldızı ANINDA doldurup kısa bir gecikme
      (350ms, Hedef Tamamlama Kutlaması'ndaki "seçim önce görünsün, sonra devam et" felsefesiyle
      AYNI) sonrası sheet'i kapatıyor; Play Store yönlendirmesi (`_openPlayStoreListing`) BİLEREK
      `unawaited` — **gerçek bir bug'dan kaçınmak için:** `await` edilseydi, `launchUrl`
      `flutter_test` ortamında (bu codebase'in `settingsWebsite`/`settingsContactUs` satırlarının
      ZATEN hiç TIKLANMADAN test edilmesinin asıl nedeni) kalıcı olarak ASILI kalabiliyor —
      canlı `print` ile izlenerek doğrulandı (`await`'in `_openPlayStoreListing()`'den SONRAKİ
      hiçbir satıra asla ULAŞMADIĞI görüldü). `unawaited` yalnızca test'i mümkün kılmakla
      kalmıyor, GERÇEK KULLANICI için de daha iyi bir UX — sheet Play Store'un GERÇEKTEN açılmasını
      beklemeden hemen kapanıyor, yönlendirme arka planda devam ediyor.
    - **`_openPlayStoreListing()`** — ÖNCE `market://details?id=<paket>` (Play Store uygulamasını
      DOĞRUDAN açar, tarayıcıya hiç uğramadan) dener, başarısız olursa (Play Store kurulu değil,
      emülatör vb.) `https://play.google.com/store/apps/details?id=<paket>` web adresine geri
      düşer — ikisi de `.catchError((_) => false)` ile sarılı, `_launchOrShowError`'daki AYNI
      desen. `market:` şeması `AndroidManifest.xml`'in `<queries>` bloğuna YENİ eklendi (`https:`
      zaten sorgulanabilir durumdaydı) — Android 11+ paket görünürlüğü kısıtlaması bu olmadan
      `canLaunchUrl`/`launchUrl`'ün hep başarısız olmasına yol açardı (mailto/https ile AYNI, bu
      projede önceden belgelenmiş gerekçe).
    - **Ayarlar > Destek bölümüne "Bize Ulaşın"ın hemen altına yeni bir satır** eklendi
      (`Icons.star_outline_rounded`).
    - **Test:** `widget_test.dart`'a satırın varlığını doğrulayan bir assertion + AYRI, dedike
      bir senaryo (sheet'in başlığı + Zibo görseli + 5 BOŞ yıldız gösterdiği, bir yıldıza
      dokununca — gerçek `launchUrl`'ü hiç TETİKLEMEDEN, `unawaited` sayesinde — sheet'in
      KAPANDIĞI). **`flutter test` — 361/361** (bu turda eklenen testler dahil, ayrıca ÖNCEDEN
      var olan/bu turla İLGİSİZ bir flake — bkz. "Test kalıpları" bölümündeki not — ayrı bir
      göreve bölündü).
  - **5) Sistem Teması Desteği — `ThemeProvider` iki-durumlu `bool`'dan Flutter'ın KENDİ
    `ThemeMode` enum'una (`light`/`dark`/`system`) geçti.** Yeni bir özel enum İCAT EDİLMEDİ —
    `MaterialApp.themeMode` zaten TAM OLARAK bu üç değeri bekliyor ve `system` iken `theme`/
    `darkTheme` arasında cihazın kendi parlaklığına göre OTOMATİK seçim yapıyor;
    `main.dart`'taki `themeMode: themeProvider.themeMode` satırı HİÇ DEĞİŞMEDİ, artık üçüncü
    değeri de doğru taşıyor.
    - **`ThemeProvider.isDarkMode`** (halihazırda `AnimatedThemeOverlay`/`home_screen.dart`/
      `theme_option_card.dart` tarafından "hangi renk varyantı gösterilecek" kararı için
      kullanılıyordu) artık `system` iken `PlatformDispatcher.instance.platformBrightness`'a göre
      ÇÖZÜMLENİYOR — bu ÜÇ tüketici HİÇ DEĞİŞMEDEN doğru davranmaya devam ediyor.
    - **Gerçek bir tasarım hatası YAPILIP DÜZELTİLDİ — `WidgetsBindingObserver` denendi, TÜM
      `ThemeProvider` testlerini kırdığı görülüp GERİ ALINDI.** İlk tasarım, cihaz parlaklığı
      DEĞİŞTİĞİNDE `isDarkMode`'u izleyen widget'ların ANINDA (bir sonraki rebuild'i beklemeden)
      güncellenmesi için `ThemeProvider`'a `WidgetsBindingObserver` mixin'i + `WidgetsBinding.
      instance.addObserver(this)` ekliyordu — ama `theme_provider_test.dart` (`RootScreen`
      gibi bir `State` İÇİNDE DEĞİL, `test()` ile DOĞRUDAN `ThemeProvider()` örnekleyen bir dosya)
      bu yüzden "Binding has not yet been initialized" hatasıyla TAMAMEN kırıldı — `WidgetsBinding.
      instance`, `TestWidgetsFlutterBinding.ensureInitialized()`/`runApp()` hiç çağrılmadan
      erişilemiyor. **Çözüm — basitleştirildi:** `WidgetsBindingObserver` TAMAMEN kaldırıldı,
      `isDarkMode` yalnızca `PlatformDispatcher.instance.platformBrightness`'ı ANLIK okuyor (canlı
      REAKTİF değil) — kabul edilen ödünleşim: `MaterialApp`'in KENDİSİ zaten `themeMode: system`
      iken sistem parlaklığını canlı takip edip DOĞRU `theme`/`darkTheme`'i seçiyor (asıl görünen
      renk şeması HER ZAMAN doğru); yalnızca üç İKİNCİL/dekoratif tüketici, kullanıcı uygulama
      AÇIKKEN elle OS temasını değiştirirse BİR SONRAKİ rebuild'e (ekran geçişi, dil/tema
      değişimi, uygulama öne gelmesi — pratikte çok kısa bir gecikme) kadar eski değeri
      gösterebilir. **Ders — genelleştirilebilir:** bir `ChangeNotifier`'ın (State DEĞİL, düz bir
      sınıf) `WidgetsBinding.instance`'a bağımlı hale gelmesi, o sınıfı DÜZ `test()` bloklarında
      (yalnızca `testWidgets()`'te DEĞİL) doğrudan örnekleyen HER test dosyasını riske atar —
      `RootScreen` gibi bir `State` içindeki AYNI mixin güvenlidir çünkü `State`'ler yalnızca
      `testWidgets()`/`pumpWidget()` üzerinden, bir binding ZATEN kurulu haldeyken kullanılır.
    - **Kalıcılık göçü — eski format (`{'value': true/false}`, `system` hiç yoktu) → yeni format
      (`{'value': 'light'/'dark'/'system'}`).** `_loadFromPrefs()` `saved is bool` ise (2026
      ÖNCESİ kayıt) `true→dark`/`false→light`'a eşleyip yeni string formata göç ediyor — `date`/
      `currencyCode` alanlarının eklenmesindeki AYNI "oku-zamanı-göç-et" deseni, ayrı bir
      migrasyon betiği GEREKMEDİ.
    - **Ayarlar UI — eski `SwitchListTile` (Koyu Tema anahtarı) kaldırıldı, YERİNE Dil satırıyla
      BİREBİR AYNI "satır → alt metin + `showModalBottomSheet` seçici → onay ikonu" deseninde bir
      "Görünüm" satırı geldi** (`_showThemeModePicker`, `_showLanguagePicker`'ın kopyası) — üç
      seçenek: Açık/Koyu/Sistemi Takip Et.
    - **Test:** `theme_provider_test.dart` tamamen `ThemeMode`-tabanlı API'ye (`setThemeMode`)
      geçirildi + eski düz-bool kayıtlı veri göç testi eklendi; `widget_test.dart`'taki "Koyu Tema
      anahtarı..." testi yeni "Görünüm satırından Koyu seçilince..." sheet akışına güncellendi.
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** (cihazda kullanıcının GERÇEK, Play
    Store'dan kurulu canlı sürümü olduğu için — bkz. "Sürüm kontrolü" tartışması, debug build ile
    ÜZERİNE yazmak bilerek yapılmadı) — yalnızca `flutter build apk --debug` (hatasız) +
    `flutter test` (361/361, önceden var olan 1 ilgisiz flake ayrı bir göreve bölündü) ile
    doğrulandı. **Kullanıcının kendi cihazında (yeni bir sürüm kurulduğunda) doğrulaması
    gereken:** "Bizi Puanlayın"a dokununca gerçekten bir yıldıza basıp Play Store'un (uygulama
    veya tarayıcı) GERÇEKTEN açıldığını, "Görünüm"den "Sistemi Takip Et" seçilince cihazın kendi
    açık/koyu ayarını değiştirince uygulamanın da buna uyduğunu.

### Bildirimler ([notification_service.dart](lib/services/notification_service.dart), [notification_provider.dart](lib/providers/notification_provider.dart), [tab_navigation.dart](lib/utils/tab_navigation.dart))
- **GEÇİCİ OLARAK RAFA KALDIRILDI** — `notification_provider.dart`'taki `notificationsFeatureEnabled`
  (şu an `false`) bunu tek noktadan kontrol ediyor: `root_screen.dart`'taki başlangıç
  `initializeAndSchedule()` çağrısı VE `settings_screen.dart`'taki hem `_NotificationSettingsCard`
  hem `_NotificationDebugPanel` bu flag'le gate'lenmiş durumda. Sebep: aşağıdaki "Gerçek cihazda
  tanı" bölümünde anlatılan üç katmanlı azaltma (pil optimizasyonu istisnası + MIUI otomatik
  başlatma + Android'in "kullanılmıyorsa duraklat" ayarı) TAMAMEN uygulanmış ve gerçek cihazda
  doğrulanmış olsa bile zamanlanmış bildirimler hâlâ gelmiyor — canlı `adb` tanısı `AlarmManager`'ın
  alarmı tam 5. saniyede sorunsuz tetiklediğini ama `flutter_local_notifications` alıcısının
  hiçbir log/hata/çökme izi bırakmadan bildirimi hiç göstermediğini kanıtladı (ne `dumpsys
  notification`'da kayıt, ne logcat'te `ScheduledNotificationReceiver`/`dexterous` geçen tek satır).
  Bu, kod içinden ne sorgulanabilen ne de güvenilir şekilde atlatılabilen, MIUI'ye özel/belgelenmemiş
  bir arka plan kısıtlaması olduğuna işaret ediyor — kullanıcı isteğiyle özellik kapatıldı, diğer
  işler tamamlandıktan sonra tekrar ele alınacak. **Provider/servis kodunun kendisi HİÇ
  değiştirilmedi** — yeniden açmak için tek yapılması gereken `notificationsFeatureEnabled`'ı
  `true` yapıp yeniden derlemek. `test/notification_provider_test.dart` ve
  `test/notification_service_test.dart` (varsa) gibi provider'ı doğrudan test eden dosyalar bu
  flag'den etkilenmez (yalnızca UI/başlangıç kablolamasını gate'liyor); `test/widget_test.dart`'taki
  "Ayarlar dişli ikonuyla açılır..." testi artık `find.text('Bildirimler')` için `findsNothing`
  bekliyor.
- **GEÇİCİ: Ayarlar'da `_NotificationDebugPanel`** (`_CoinTestPanel` ile aynı "geçici" deseni) —
  bildirim sistemi kararlı çalıştığı gerçek cihazlarda doğrulandıktan sonra tamamen kaldırılacak.
  Üç şey sağlıyor: (1) **izin durumu göstergesi** (`NotificationService.hasPermission` →
  `AndroidFlutterLocalNotificationsPlugin.areNotificationsEnabled()` — izin İSTEMEZ, yalnızca mevcut
  durumu okur, yenile butonuyla tazelenir), (2) **"Hemen Test Bildirimi Göster"**
  (`showTestNotificationNow` → `_plugin.show()`, zamanlamaya hiç dokunmaz, temel gösterim + izin
  gerçekten çalışıyor mu diye ANINDA bir sinyal), (3) **"5sn Sonra Planlanmış Bildirim"**
  (`scheduleTestNotificationIn` → üretimdeki `scheduleDaily` ile TAMAMEN AYNI mekanizma —
  `zonedSchedule` + `AndroidScheduleMode.inexactAllowWhileIdle` — ama 5 saniye sonrası için tek
  seferlik). Bu ikisinin AYRI olması kasıtlı: (2) başarılı ama (3) başarısız/çok geç geliyorsa, bu
  sorunun izin/kanal değil AlarmManager/arka plan teslimatı (ör. MIUI'nin engellemesi, bkz. aşağıdaki
  tanı notu) olduğunu KESİN olarak ayırt ettiriyor.
- **Tamamen yerel (cihaz üzerinde), sunucu/backend gerektirmez** — `flutter_local_notifications` +
  `timezone` paketleriyle işletim sisteminin kendi bildirim zamanlayıcısına planlanan, uygulama
  kapalıyken/arka plandayken de tetiklenen günlük hatırlatmalar.
- **`NotificationService`** soyutlaması `AdService`/`ShareService` ile aynı desen: `LocalNotificationService`
  gerçek implementasyon, `FakeNotificationService` testte enjekte edilen sahte. Farkı: `AdService`'in
  aksine gerçek implementasyon **varsayılan** olarak da kullanılıyor (mock değil) — bu yüzden
  `LocalNotificationService`'in platform channel'a dokunan HER metodu (`initialize`, `requestPermission`,
  `cancelAll`, `scheduleDaily`) try/catch ile sarılı: eklenti kullanılamıyorsa (`flutter_test` ortamı,
  desteklenmeyen platform, vb.) özellik sessizce devre dışı kalır, `RootScreen`'i pump'layan HER TEST
  çökmeden çalışmaya devam eder. `DijitalKankaApp`'in kendisi bu yüzden `NotificationProvider` için
  fake enjekte etmiyor — `ShareZiboButton`'ın gerçek `SharePlusService`'i varsayılan kullanıp yalnızca
  platform channel'a GERÇEKTEN dokunan testlerin (ör. `zibo_share_sheet_test.dart`) sahte enjekte
  etmesiyle aynı mantık. `widget_test.dart`'ın `_buildAppWithClock` yardımcı fonksiyonu yine de
  netlik/hız için `FakeNotificationService` enjekte ediyor.
- **Saat dilimi bilerek `Europe/Istanbul` olarak sabitlendi** (`tz.setLocalLocation`), cihazın gerçek
  saat dilimini okuyan ayrı bir pakete (ör. `flutter_timezone`) gerek duyulmadan — tıpkı
  `locale: const Locale('tr')`'nin sabit olması gibi, uygulama şu an yalnızca Türkiye'yi hedeflediği
  için bilinçli bir basitleştirme (bkz. "Yerelleştirme" bölümü). Çoklu saat dilimi desteği eklenirse
  burası da yeniden ele alınmalı.
- **`NotificationProvider`**: sıklık (`NotificationFrequency`: `off`/`once`/`thrice` — Ayarlar'da
  "Kapalı"/"Günde 1"/"Günde 3") + üç sabit zaman dilimi (Sabah 09:00/Öğlen 13:00/Akşam 19:00,
  kullanıcı her birini `showTimePicker` ile değiştirebilir) tutar, `SharedPreferences` ile kalıcı
  (`ThemeProvider`'la aynı desen). "Günde 1" yalnızca Öğlen dilimini (`onceSlotIndex`) kullanır. Her
  değişiklik `_reschedule()`'ı tetikler: önce `cancelAll()`, sonra aktif her dilim için AYRI bir
  bildirim planlanır.
- **İçerik:** `zibo_messages.dart` (Ana Sayfa) + `goal_quotes.dart` (Hedef Takibi) havuzlarının
  birleşiminden rastgele seçilir. Aktif her zaman dilimi PLANLAMA ANINDA birbirinden farklı bir söz
  alır (aynı gün üç bildirim asla aynı şeyi söylemez). **Bilinçli basitleştirme:** işletim sistemi
  bildirimi `DateTimeComponents.time` ile her gün aynı saatte KENDİ BAŞINA tekrarladığı için (uygulama
  açık olmasa da çalışır), içerik kullanıcı uygulamayı tekrar açıp yeniden planlanana kadar gün gün
  DEĞİŞMEZ — günlük içerik rotasyonu için bir arka plan görevi (WorkManager vb.) gerekirdi, bu bilerek
  kapsam dışı bırakıldı.
- **İzin isteme + ilk planlama:** `RootScreen.initState`'te bir `addPostFrameCallback` ile bir kez
  `NotificationProvider.initializeAndSchedule()` çağrılır (eklentiyi kurar, `POST_NOTIFICATIONS`
  iznini ister — Android 13+, ve mevcut tercihe göre planlar). Bu, pratikte "ilk açılışta izin iste"
  isteğini karşılıyor çünkü Android'in kendisi zaten yalnızca İLK istekte gerçek bir dialog gösterir;
  sonraki çağrılar (her soğuk başlangıçta tekrar tetiklenir) sessizce mevcut durumu döner.
- **Bildirime dokununca Ana Sayfa'ya geçiş:** `tab_navigation.dart`'taki global `homeTabRequest`
  (`ValueNotifier<int>`) — `RootScreen` bunu dinleyip her artışta `_selectedIndex = 0` yapıyor.
  Uygulama SOĞUK başlangıçta zaten Ana Sayfa'da açıldığı için (`_selectedIndex` varsayılanı `0`) bu
  sinyal yalnızca uygulama ZATEN AÇIKKEN (ön/arka planda) gelen bir dokunuş için gerekli;
  `getNotificationAppLaunchDetails()` ile soğuk-başlangıç senaryosunu ayrıca ele almaya bilerek
  gerek duyulmadı.
- **Android manifest:** `POST_NOTIFICATIONS` izni eklendi (eklentinin kendi bundled manifest'i de
  zaten aynısını + `VIBRATE`'i deklare ediyor — Gradle manifest merge ile birleşiyor, çakışma yok).
  `AndroidScheduleMode.inexactAllowWhileIdle` kullanıldı (tam saatinde değil, birkaç dakika sapmayla —
  Android'in pil optimizasyonuna daha uyumlu) — bu, çok daha ağır bir kullanıcı izni gerektiren
  `SCHEDULE_EXACT_ALARM`'a hiç ihtiyaç duyulmamasını sağlıyor; "günde birkaç kez hatırlatma" gibi
  hassas olmayan bir kullanım için gereksiz kesinlik.
- **Bilinen sınırlamalar (gerçek cihazda ileride ele alınabilir):**
  - Cihaz yeniden başlatılırsa planlanmış bildirimler kaybolur (bir `BOOT_COMPLETED` receiver +
    yeniden planlama gerekirdi) — pratikte kullanıcı uygulamayı her açtığında zaten yeniden
    planlandığı için etkisi sınırlı (yalnızca "reboot sonrası uygulama hiç açılmadan" geçen ilk
    bildirim kaçırılabilir).
  - Bildirim ikonu şu an uygulamanın renkli `@mipmap/ic_launcher`'ı — Android status bar'da
    genellikle tek renkli/şeffaf bir `drawable` ikonu beklenir (renkli ikon bazı Android sürümlerinde
    düz beyaz bir daire/kare olarak render edilebilir). Kozmetik, ayrı bir görsel iş.
  - **Web'de anlamlı şekilde test edilemez** — `flutter_local_notifications_web` var ama tarayıcı
    bildirim izni/zamanlama modeli tamamen farklı; gerçek doğrulama yalnızca Android cihazda/APK'da
    yapılabilir (bkz. bu özelliğin tarayıcı önizlemesinde YALNIZCA statik görsel + otomatik testlerle
    doğrulandığı, gerçek izin isteme/bildirim tetiklenmesi/dokununca Ana Sayfa'ya geçişin gerçek
    cihazda elle doğrulanması gerektiği).

#### Gerçek cihazda tanı: bildirimler neden gelmeyebilir (ve güvenilirlik katmanı)
- **Gerçek bir Redmi/Xiaomi (MIUI) cihazda adb ile canlı tanı konuldu:** izin verilmişti
  (`POST_NOTIFICATIONS: granted=true`), kanal doğru yapılandırılmıştı, `dumpsys alarm` alarmın
  gerçekten PLANLANDIĞINI ve TETİKLENDİĞİNİ gösteriyordu — ama `dumpsys notification` hiçbir zaman
  gösterilmiş bir bildirim kaydı bulamadı ve logcat'te `ScheduledNotificationReceiver`'la ilgili
  TEK BİR SATIR bile yoktu (300 binden fazla satırlık tam dump'ta). Sonuç: Android'in kendi
  `AlarmManager`'ı doğru çalışıyor, ama MIUI'nin kendi arka plan/pil kısıtlama katmanı yayını
  uygulamanın bildirim koduna ulaşmadan sessizce engelliyor — bu, `AlarmManager` tabanlı TÜM yerel
  bildirim sistemlerinde (yalnızca bu uygulamada değil) Xiaomi/Huawei/Oppo/Vivo gibi üreticilerde
  son derece yaygın, iyi belgeli bir sorun (bkz. dontkillmyapp.com).
- **Bunu kod içinden %100 garantiyle "yenmenin" bir yolu yok** (araya giren bir arka plan
  servisiyle zorla atlatmaya çalışmak hem pil tüketimini patlatır hem Google Play politikasına
  aykırı olurdu) — ama sektörün kullandığı standart azaltma stratejisi var, bu da eklendi:
  [permission_handler](https://pub.dev/packages/permission_handler) ile standart Android pil
  optimizasyonu istisnası isteği (`Permission.ignoreBatteryOptimizations` — TÜM cihazlarda çalışır,
  yalnızca MIUI'ye özel değil) + [device_info_plus](https://pub.dev/packages/device_info_plus) ile
  üretici tespiti + [android_intent_plus](https://pub.dev/packages/android_intent_plus) ile bilinen
  agresif üreticilerin (Xiaomi/MIUI, Huawei, Oppo, Vivo, OnePlus) kendi "otomatik başlatma" ayar
  ekranını doğrudan açma. `NotificationService`'e üç yeni metot eklendi:
  `isIgnoringBatteryOptimizations`, `requestIgnoreBatteryOptimizations`,
  `openAutostartOrAppSettings` (hepsi diğerleri gibi try/catch'li, `FakeNotificationService`'te
  zararsız sahteleri var).
- **`_autostartIntentCandidates`** ([notification_service.dart](lib/services/notification_service.dart))
  — üretici adı → bilinen component adı/adları eşlemesi. Bu component adları **belgelenmemiş,
  üreticiye özel ve sürümler arası değişebilir** — bu yüzden her zaman önce
  `AndroidIntent.canResolveActivity()` ile kontrol edilir, çözülemezse
  `permission_handler.openAppSettings()` (genel uygulama ayarları — TÜM cihazlarda çalışır) ile
  güvenli bir şekilde geri düşülür. **Asla sessizce hiçbir şey yapmadan dönmez.**
- **Android 11+ paket görünürlüğü:** `AndroidIntent.canResolveActivity()`'nin bu üretici
  paketlerini "görebilmesi" için `AndroidManifest.xml`'e `<queries>` altında her üreticinin paket
  adı açıkça eklenmesi gerekti (`com.miui.securitycenter` vb.) — eklenmeseydi
  `canResolveActivity()` bilinen component'ler cihazda gerçekten var olsa bile hep `false`/`null`
  dönerdi.
- **`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` izni** manifestte statik olarak deklare edilmesi
  yeterli (çalışma zamanında ayrıca istenmez) — Google Play, bu iznin yalnızca gerçek bir kullanıcı
  etkileşimiyle (buton/anahtar) tetiklenmesini şart koşuyor; burada da Ayarlar'daki "Kapat" butonuna
  kullanıcı basmadan otomatik/gizli tetiklenmiyor.
- **UI:** Ayarlar > Bildirimler kartının altında "Bildirimlerin güvenilir gelmesi için" bölümü —
  pil optimizasyonu durumu CANLI gösterilir (`NotificationProvider.isBatteryOptimizationIgnored`,
  `refreshBatteryOptimizationStatus()` ile tazelenir: hem `initializeAndSchedule()`'da hem de
  `_NotificationSettingsCardState`'in `WidgetsBindingObserver` ile `AppLifecycleState.resumed`'da —
  kullanıcı sistem ayarlarına gidip dönmüş olabilir). Otomatik başlatma satırının bilerek DURUM
  göstergesi yok — bunu üreticiden bağımsız sorgulayan genel bir Android API'si yok, yalnızca
  "Ayarları Aç" eylem butonu var.
- **ÜÇÜNCÜ, ayrı bir engel bulundu: Android'in "kullanılmıyorsa uygulama etkinliğini duraklat"
  (unused app hibernation / auto-revoke permissions) özelliği.** Pil optimizasyonu istisnası VE
  MIUI otomatik başlatma İKİSİ DE doğru şekilde açık olsa bile (gerçek cihazda `adb shell dumpsys
  deviceidle whitelist` ve otomatik başlatma ekranı ile doğrulandı), planlanmış bildirimler hâlâ
  gelmeyebiliyordu. Kök neden: telefonun Ayarlar > Uygulamalar > (uygulama) > "Uygulama bilgisi"
  sayfasındaki bu anahtar AÇIKTI ve açıklaması net şekilde "İzinleri kaldırın, geçici dosyaları
  silin ve **bildirimleri durdurun**" diyor. Bu, pil optimizasyonundan ve otomatik başlatmadan
  TAMAMEN AYRI bir Android alt sistemi (Android 11+'ta standart, MIUI/HyperOS'ta yalnızca daha
  agresif uygulanıyor olabilir) ve üçüncü parti bir uygulamanın kendi durumunu sorgulayabileceği
  hiçbir genel API yok — bu yüzden `hasPermission()`/`isIgnoringBatteryOptimizations()` ikisi de
  "sorun yok" derken bu sessizce bildirimleri engelleyebiliyordu. **Düzeltme:** standart, belgelenmiş
  (yalnızca MIUI'ye özel DEĞİL, Android 11+ AOSP) `android.intent.action.AUTO_REVOKE_PERMISSIONS`
  intent'i (`data: package:<applicationId>`) kullanıcıyı doğrudan bu ekrana götürüyor —
  `NotificationService.openUnusedAppsSettings()`, çözülemezse `openAppSettings()`'e düşer (aynı
  autostart deseni). Üçüncü bir "güvenilirlik" satırı olarak eklendi (durum göstergesi yok, aynı
  gerekçeyle — sorgulanamaz).
- **Gotcha (test):** Bu bölüm `_NotificationSettingsCard`'ı belirgin şekilde uzattığı için, Ayarlar
  sayfasının ALTINDAKİ kartlar (Dil/Hakkında, Coin Test Paneli) artık `ListView`'ın ilk lazy-build
  aralığının dışında kalabiliyor — yalnızca `tester.tap()`'in hit-test'i değil,
  `tester.widget<X>(finder)`/`tester.ensureVisible(finder)` gibi salt "eleman var mı" kontrolleri
  bile `Bad state: No element` ile başarısız olabiliyor (`ensureVisible`, elemanın ÖNCEDEN ağaçta
  olmasını varsayıyor). Çözüm: her ikisi yerine `tester.scrollUntilVisible(finder, delta)`
  kullanmak — hem bulur hem kaydırır. **Ayarlar sayfasına yeni içerik eklerken altındaki
  testlerin bu deseni kullandığından emin olun.**

### Zibonu Paylaş ([zibo_share_card.dart](lib/widgets/zibo_share_card.dart), [zibo_share_sheet.dart](lib/widgets/zibo_share_sheet.dart), [share_zibo_button.dart](lib/widgets/share_zibo_button.dart), [share_service.dart](lib/services/share_service.dart), [share_card_backgrounds.dart](lib/data/share_card_backgrounds.dart), [share_card_text_styles.dart](lib/data/share_card_text_styles.dart))
- Ana Sayfa'daki ve Para ve Birikim'deki konuşma balonlarının sağ üst köşesinde (bir `Stack` ile
  bindirilmiş, `SpeechBubble`'ın kendisi değişmedi) küçük bir paylaş ikonu (`ShareZiboButton`) var.
  Basılınca `ZiboShareSheet` bottom sheet olarak açılır.
> **DÜZELTME/TARİHSEL NOT — bu alt bölümdeki hipotez YANLIŞ ÇIKTI, ama düzeltme YİNE DE
> ZARARSIZ/MAKUL bir iyileştirme olduğu için GERİ ALINMADI.** Firebase Console'a (kullanıcının
> gerçek Google oturumuyla, "Claude in Chrome" üzerinden) erişilip GERÇEK stack trace görülünce
> asıl kök nedenin `share_plus`/`cross_file` DEĞİL, **Manifest Günlüğü/Profil fotoğrafları**
> (`FileImage._loadAsync`) olduğu ortaya çıktı — bkz. altta "Manifest Günlüğü ↔ Profil fotoğrafı:
> Crashlytics'teki asıl kök neden" notu, GERÇEK/doğrulanmış düzeltme orada.
- **2026 bug düzeltmesi (YANLIŞ HİPOTEZ, bkz. yukarıdaki düzeltme notu) — Crashlytics'teki EN
  BÜYÜK tekrarlayan hata: `_File.length` →
  `PathNotFoundException: Cannot retrieve length of file` (58 olay/6 kullanıcı, TÜM sürümlerde,
  "Repetitive crashes" etiketli).** Kullanıcı Firebase Console ekran görüntüsü paylaşınca
  `cross_file`/`share_plus` pub cache kaynak kodu incelenerek bulundu (Google Console'a bu
  ortamdan doğrudan erişilemedi — `accounts.google.com` sandbox'ta engelli — bu yüzden TAM stack
  trace değil, plugin kaynak kodu + gerçek GitHub issue'larıyla çapraz doğrulanmış bir kanıt
  zinciri kullanıldı). **Kök neden:** `SharePlusService.shareImageBytes()` eskiden `XFile.
  fromData(bytes, ...)` (path'SİZ) veriyordu — `share_plus`'ın Android tarafı
  (`MethodChannelShare._getFile`, `share_plus_platform_interface` paketi) path'i boş bulunca
  bytes'ı KENDİ SEÇTİĞİ bir geçici (cache) dosyaya yazıp o path'ten YENİ bir `XFile` üretiyor —
  plugin'in kendi kod yorumu AÇIKÇA "the system will automatically delete files in this
  TemporaryDirectory as disk space is needed elsewhere on the device" diyor. Bu dosya paylaşım
  TAMAMLANMADAN Android tarafından temizlenirse sonraki bir okuma/uzunluk kontrolü
  `PathNotFoundException` fırlatıyor — VE bu, `ZiboShareSheet._share()`'in KENDİ try/catch'inin
  DIŞINDA (plugin'in kendi iç async akışında) gerçekleştiği için doğrudan Crashlytics'e sızıyordu.
  **Önemli nüans:** `main.dart`'taki `PlatformDispatcher.instance.onError`/`FlutterError.onError`
  (bkz. "Crashlytics" bölümü) `return true` diyor — yani bu hata uygulamayı GERÇEKTEN
  ÇÖKERTMİYOR (süreç hayatta kalıyor, yalnızca `fatal: true` olarak Crashlytics'e raporlanıyor) —
  kullanıcı muhtemelen "Paylaş"a bastı, sheet donuk kaldı/kapanmadı, hiçbir hata mesajı görmeden
  tekrar denedi. **Düzeltme:** `SharePlusService.shareImageBytes()` artık bytes'ı `share_plus`'ın
  belirsiz iç mekanizmasına BIRAKMIYOR — `path_provider`'ın geçici dizinine BİZ önceden bilinen
  bir path'e yazıp GERÇEK path'li bir `XFile(path, ...)` veriyor. Bu, `_getFile()`'ın riskli
  path'siz fallback dalını (dolayısıyla o dalın kendi AYRI temp-dosya yazma/okuma zamanlamasını)
  TAMAMEN atlıyor. **Dosya BİLEREK SİLİNMİYOR** — share_plus'ın kendi ürettiği temp dosyaları da
  hiç silmediği gibi, erken silmek paylaşım hedef uygulamaya (WhatsApp vb.) devrederken dosyayı
  hâlâ okuyor olabileceği için AYNI türden yeni bir yarış koşulu yaratırdı; OS zaten cache
  dizinini kendi zamanlamasında temizliyor. `flutter test` (541/542, yalnızca önceden belgelenmiş
  flake hariç) — `zibo_share_sheet_test.dart` testte SAHTE bir `ShareService` enjekte ettiği için
  bu değişiklikten etkilenmedi. **Doğrulanamadı** — bu, Android'in KENDİ cache-eviction
  zamanlamasına bağlı, kontrollü şekilde tetiklenmesi zor bir yarış koşulu; kesin kanıt için
  kullanıcının Firebase Console'da bu issue'ya tıklayıp TAM stack trace'i (hangi Dart çağrı
  zincirinden geçtiği) paylaşması, VEYA birkaç hafta sonra bu crash bucket'ının olay sayısının
  artık artmadığını gözlemlemesi gerekiyor.

#### Manifest Günlüğü ↔ Profil fotoğrafı: Crashlytics'teki asıl kök neden ([manifest_journal_screen.dart](lib/screens/manifest_journal_screen.dart), [profile_screen.dart](lib/screens/profile_screen.dart))

- **2026 — GERÇEK stack trace'e "Claude in Chrome" ile (kullanıcının GERÇEK Chrome'unda zaten
  oturum açık olan Google hesabıyla, hiçbir şifre girilmeden) Firebase Console'a girilip
  bakılınca bulundu.** Yukarıdaki `share_plus`/`cross_file` hipotezi (bu sandbox'ın kendi
  tarayıcısında `accounts.google.com` engelli olduğu için TAM stack trace görülemeden, yalnızca
  plugin kaynak kodu okunarak kurulmuştu) **YANLIŞ ÇIKTI** — GERÇEK stack trace TAMAMEN FARKLI
  bir çağrı zinciri gösteriyordu:
  ```
  Fatal Exception: io.flutter.plugins.firebase.crashlytics.FlutterError
  PathNotFoundException: Cannot retrieve length of file, path =
    '/data/user/0/com.dijitalkanka.dijital_kanka/app_flutter/app_photos/1788378812503803.jpg'
    (OS Error: No such file or directory, errno = 2). Error thrown resolving an image codec.

  _File.length.<fn> (dart:io)
  FileImage._loadAsync (image_provider.dart:1631)
  MultiFrameImageStreamCompleter._handleCodecReady (image_stream.dart:1021)
  ```
  Path `app_flutter/app_photos/` — `share_plus`'ın GEÇİCİ cache'i DEĞİL, `PhotoPickerService.
  saveToPermanentStorage()`'ın yazdığı KALICI belge dizini (bkz. "Manifest Günlüğü"/"Profil"
  bölümleri). Cihaz bilgisi: %100 Xiaomi, %100 Android 14 — tek bir kullanım paterni.
  - **Kök neden — CLAUDE.md'nin KENDİSİNDE ZATEN belgelenmiş bir sınırlamanın SOMUT/gerçek
    sonucu:** "Manifest Günlüğü" bölümü şunu AÇIKÇA söylüyor: "Fotoğraflar SUNUCUYA
    YÜKLENMİYOR — yalnızca cihazın kendi belge dizininde saklanıyor, kayıtta yalnızca yerel
    dosya yolu tutuluyor... **cihazlar arası fotoğraf taşınmaz**." `ManifestEntry.photoPath`/
    `ProfileProvider.photoPath` (yalnızca birer STRING) Firestore'a senkronize ediliyor ama
    GERÇEK dosya baytları HİÇBİR ZAMAN senkronize edilmiyor. Kullanıcı AYNI cihazda "Çıkış
    Yap"/"Hesap Değiştir" yapıp (bu proje boyunca ÇOK test edilen bir akış, bkz. "Google Hesap
    Bağlama" bölümü) SONRA farklı bir hesaba/oturuma dönünce, o hesabın Firestore'dan geri gelen
    `photoPath`'i BAŞKA bir oturuma/cihaza ait bir path olabilir — bu path BU cihazda hiç var
    OLMAMIŞ olabilir.
  - **Neden mevcut `errorBuilder` (Manifest ekranının 3 kullanım noktasında ZATEN vardı) bunu
    YAKALAMIYORDU — Flutter SDK'nın bilinen bir davranışı.** `Image.file`'ın `errorBuilder`'ı,
    `FileImage._loadAsync`'in async codec çözümleme sürecinde (özellikle dosya SİSTEMİ
    seviyesinde, decode BAŞLAMADAN önce) oluşan istisnaları GÜVENİLİR şekilde yakalamıyor —
    hata widget ağacına hiç ULAŞMADAN doğrudan global `PlatformDispatcher.instance.onError`'a
    (bkz. "Crashlytics" bölümü) sızıyordu. Profil ekranındaki `CircleAvatar.backgroundImage`'ta
    (`Image.file` widget'ı DEĞİL, bir `ImageProvider`) ise `errorBuilder` GİBİ bir savunma
    mekanizması HİÇ YOKTU.
  - **Önemli nüans (yine geçerli):** `main.dart`'taki `PlatformDispatcher.instance.onError`
    `return true` diyor — bu hata uygulamayı GERÇEKTEN ÇÖKERTMİYOR, süreç hayatta kalıyor,
    yalnızca `fatal: true` olarak Crashlytics'e raporlanıyor.
  - **Düzeltme — `errorBuilder`'a GÜVENMEK yerine dosyayı ÖNCEDEN kontrol etmek:** YENİ
    `manifest_journal_screen.dart`'taki `_SafeFileImage` (private `StatelessWidget`,
    `File(path).existsSync()` ile SENKRON bir varlık kontrolü — küçük/yerel bir dosya sisteminde
    `build()` içinde kullanmak bu ölçekte zararsız) dosya YOKSA `Image.file`'ı HİÇ İNŞA ETMEDEN
    doğrudan `_BrokenImagePlaceholder`'a düşüyor; VARSA `errorBuilder`'lı `Image.file`'ı
    (bozuk/corrupt bir JPEG gibi BAŞKA hatalar için hâlâ faydalı ikinci bir savunma katmanı
    olarak) döndürüyor. Ekranın ÜÇ `Image.file` kullanım noktası (fotoğraf seçici önizlemesi,
    detay diyaloğu, geçmiş galerisi kartı) bu TEK widget'a çevrildi. `profile_screen.dart`'a
    benzer bir `_hasReadablePhoto(String? photoPath)` top-level yardımcı fonksiyonu eklendi —
    `CircleAvatar.backgroundImage`/`.child` artık dosya GERÇEKTEN okunabilir DEĞİLSE (yok VEYA
    `existsSync()` istisna fırlatırsa) `person_rounded` ikonuna düşüyor.
  - **Test:** `flutter test` — tam suite yeşil (541/542, yalnızca önceden belgelenmiş flake
    hariç); `manifest_journal_screen_test.dart`/`profile_screen_test.dart` sahte
    `PhotoPickerService`'in GERÇEKTEN var olan bir dosyaya yazdığı test ortamında sorunsuz
    geçti (yeni `existsSync()` kontrolü test akışını BOZMADI). **Gerçek cihazda GÖRSEL doğrulama
    bu turda YAPILMADI** — kesin doğrulama, bir SONRAKİ Play Store sürümünden sonra bu crash
    bucket'ının (Firebase Console'daki `_File.length.<fn>`/`FileImage._loadAsync` issue'su) yeni
    olay ALMAMASIYLA gelecek zamanla.
  - **2026 GÜNCELLEMESİ — "bilinçli olarak yapılmayan" düzeltme SONRADAN, kullanıcının kendi
    talebiyle GERÇEKTEN uygulandı: kırık `photoPath` kaydı artık kalıcı olarak TEMİZLENİYOR.**
    Kullanıcı kendi cihazında GERÇEKTEN yaşadığını bildirdi ("profil fotoğrafı yüklüyordum,
    manifest günlüğüne fotoğraf ekliyordum, Google hesabımdan çıkıp geri girdiğimde fotoğraflar
    kayboluyordu") — bu, teşhisi kanıtlayan somut bir kullanıcı raporu. Gerçek fotoğraf kalıcılığı
    için Firebase Storage entegrasyonu (upload/download, cihazlar arası GERÇEKTEN taşınan
    fotoğraflar) TEKLİF EDİLDİ, ama **Şubat 2026'dan itibaren Cloud Storage for Firebase artık
    Spark (ücretsiz) planda HİÇ kullanılamıyor** — proje daha önce hiç bucket oluşturmadığı için
    Blaze'e (faturalandırma hesabı bağlı) geçmeden bucket bile OLUŞTURULAMIYOR
    ([firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)
    — gerçek kullanım "Always Free" sınırları içinde [5GB-ay depolama, ayda 100GB North America
    egress] kalırsa faturaya yansımıyor, ama Blaze'e geçmenin KENDİSİ hâlâ bir ön koşul). Kullanıcı
    bu projede daha önce Blaze'den BİLEREK kaçınmıştı (bkz. "Push Bildirimleri" bölümündeki
    GitHub Actions kararı) — `AskUserQuestion` ile netleştirilince kullanıcı Blaze'e GEÇMEMEYİ,
    bunun yerine yalnızca "kırık kaydı temizle" seçeneğini tercih etti.
    - **`ManifestEntry.photoPath`: `String` → `String?`'e çevrildi** (`ManifestProvider.
      addEntry()`'de kayıt OLUŞTURULURKEN hâlâ ZORUNLU/dolu — bu davranış DEĞİŞMEDİ, yalnızca
      SONRADAN, dosya kaybolursa `null` olabiliyor). **YENİ `ManifestProvider.
      reconcileMissingPhotos()`** — `DailyRewardsProvider.reconcileForToday()`/`AppStreakProvider.
      recordOpenForToday()` ile AYNI "reconcile-on-resume" felsefesi: TÜM `_entries`'i dolaşıp
      `File(photoPath).existsSync()` (senkron, `dart:io`) ile kontrol eder, dosyası artık diskte
      OLMAYAN her kaydın `photoPath`'ini kalıcı olarak `null`'a çevirir (niyet METNİ SİLİNMEZ,
      yalnızca kırık dosya referansı temizlenir) — değişiklik varsa `notifyListeners()` + `_save()`.
    - **YENİ `ProfileProvider.reconcileMissingPhoto()`** — `photoPath` ZATEN nullable olduğu için
      model değişikliği gerekmedi, AYNI mantıkla (`existsSync()` kontrolü, dosya yoksa `null`'a
      set edip kalıcı hale getir) TEK bir alanı temizliyor.
    - **`RootScreen`'e kablolama — `AppStreakProvider.recordOpenForToday()` ile BİREBİR AYNI İKİ
      tetikleme noktası:** `initState`'in postFrameCallback'i (soğuk başlangıç) + `didChangeAppLifecycleState`'in
      `resumed` dalı (uygulama HER öne gelişte — hesap değiştirip/çıkış yapıp geri dönmek
      uygulamayı KAPATMADAN da olabiliyor, bu yüzden yalnızca soğuk başlangıç YETMEZ).
    - **`_SafeFileImage`'ın `path` parametresi `String?`'e çevrildi** — `path == null` iken dosya
      sistemine HİÇ dokunmadan doğrudan `_BrokenImagePlaceholder`'a düşer (`path` dolu ama dosya
      YOKSA ile AYNI görsel sonuç). Manifest ekranının üç kullanım noktası (`entry.photoPath` artık
      nullable) buna göre otomatik uyumlu.
    - **Katmanlı savunma BİLEREK korundu — `reconcileMissingPhotos()`/`reconcileMissingPhoto()`
      TEK BAŞINA yeterli DEĞİL:** bu reconcile bir `postFrameCallback`'te (BİR FRAME SONRA) çalışıyor
      — İLK karede `photoPath` HÂLÂ eski/geçersiz path'i taşıyor olabilir. `_SafeFileImage`'ın
      KENDİ `existsSync()` kontrolü (build() içinde SENKRON) bu ilk karede bile crash'i önlüyor —
      reconcile "kalıcı temizlik", `_SafeFileImage`/`_hasReadablePhoto` "anlık/senkron güvenlik ağı"
      sağlıyor, ikisi BİRLİKTE tutuluyor.
    - **Test:** `manifest_provider_test.dart`/`profile_provider_test.dart`'a YENİ birer grup
      (`Directory.systemTemp.createTempSync(...)` ile GERÇEK geçici dosyalar oluşturup/silen,
      `existsSync()` kontrolünün GERÇEK dosya sistemi davranışına karşı doğrulandığı testler —
      diskte var olmayan path `null`'a çevrilir + kayıt/niyet metni SİLİNMEZ, GERÇEKTEN var olan
      path'e DOKUNULMAZ, değişiklik yoksa `notifyListeners` GEREKSİZ çağrılmaz, kalıcı depoya
      yazılıp yeniden başlatmada `null` olarak hatırlanır). `flutter test` tam yeşil (549/550,
      yalnızca önceden belgelenmiş flake hariç).
    - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — kullanıcının kendi cihazında (bir
      SONRAKİ Play Store sürümünden sonra) kendi bildirdiği senaryoyu (Google hesabından çıkıp
      geri girme) tekrarlayıp fotoğrafların artık ÇÖKME OLMADAN "kişi"/"kırık resim" ikonuna
      (fotoğraf hiç eklenmemiş gibi TEMİZ bir görünüme) döndüğünü doğrulaması gerekiyor — fotoğraf
      GERİ GELMEZ (bu, Firebase Storage entegrasyonu OLMADAN mimari olarak mümkün değil), yalnızca
      arayüz artık kırık/tutarsız görünmüyor.
- `ZiboShareCard`: 9:16 (Instagram/TikTok Hikaye) oranında, **sabit mantıksal boyutlu (450×800,
  2026 güncellemesi — eskiden 360×640, bkz. altta)** kart — logo sol üstte, söz kartın **tam
  ortasında**, yarı saydam koyu yuvarlak köşeli bir panelin üzerinde (arka plan gradyanı/rengi ne
  olursa olsun kontrast garantisi — panel bottom-anchored bir gradyan değil, metni her yönden saran
  sabit bir "kart içinde kart"). Otomatik boyutlanma ek paket olmadan, iç içe `SizedBox(width:
  sabit) → FittedBox(scaleDown) → SizedBox(width: aynı) → Text` kalıbıyla: metin önce sabit
  genişlikte doğal olarak satırlara bölünür, ancak taştığında (bloğun tamamı, satır kırılmaları
  bozulmadan) orantılı küçültülür.
  - Kart boyutu sabit olduğu için ekranda küçük gösterilmesi gerektiğinde çağıran taraf onu bir
    `FittedBox` içine alır — bu, `RenderRepaintBoundary.toImage()` ile yakalanan gerçek çözünürlüğü
    etkilemez (boundary kendi mantıksal boyutunda render eder, ata `FittedBox`'ın görsel ölçeklemesi
    yalnızca ekrandaki görünüme uygulanır).
  - **2026 güncellemesi — metin dizilimi bozuk görünüyordu, kart büyütüldü + içerik uzunluğuna göre
    font boyutu:** Kullanıcı bildirdi: özellikle Profil kartı paylaşımının (bkz. "Profil" bölümü —
    bağ seviyesi + 4 kategori puanı içeren çok satırlı, uzun bir mesaj) satırları üst üste
    yığılmış/okunaksız görünüyordu. **Kök neden:** kart baştan yalnızca KISA, tek satırlık sözler
    (`zibo_messages.dart` vb.) için tasarlanmıştı — sabit 220px'lik metin paneli + sabit 36pt font,
    uzun/çok satırlı bir mesaj geldiğinde `FittedBox(scaleDown)` metni agresifçe küçültüp satır
    aralığını da orantısız sıkıştırıyordu. **Çözüm:** kart 360×640'tan 450×800'e (yine tam 9:16)
    büyütüldü, metin paneli 220px'ten 480px'e çıkarıldı, logo/panel dolgusu/köşe yarıçapı orantılı
    büyütüldü; ayrıca yeni bir `ZiboShareCard._baseFontSize(message)` — mesaj `\n` içeriyorsa
    (çok satırlı) 26pt, tek satırlıysa (kısa söz) 36pt döner — `FittedBox`'ın küçültmeye
    başlamadan ÖNCEki taban font boyutunu içerik uzunluğuna göre ayarlıyor.
  - **Kartın en altına küçük, yarı saydam bir `#ziboapp` etiketi eklendi** (`Positioned(bottom: 28,
    ...)`, `textStyle`in rengiyle aynı ama `alpha: 0.75`, `fontSize: 15`) — kullanıcının açık
    isteği.
  - `ZiboShareSheet`'teki çözünürlük doküman yorumu da güncellendi: "360×640 × 3 = 1080×1920"
    yerine "450×800 × 3 = 1350×2400 (9:16 oranını koruyarak yeterli çözünürlük)" — `AspectRatio
    (aspectRatio: ZiboShareCard.width / ZiboShareCard.height)` sabitlere referans verdiği için
    KENDİLİĞİNDEN uyum sağladı, ayrıca bir değişiklik gerekmedi.
- Arka plan, kullanıcının serbestçe renk seçmesi yerine `share_card_backgrounds.dart`'taki 8
  küratörlü `LinearGradient` ön ayarından biri (varsayılan: koyu "Gece Kahvesi") — rastgele renk
  kombinasyonlarının logo/metin kontrastını bozmasını bilerek engelliyor.
- **Yazı stili** aynı mantıkla `share_card_text_styles.dart`'taki 5 küratörlü ön ayardan biri
  (`google_fonts` ile: Poppins/Fredoka/Caveat/Special Elite/Playfair Display, her biri kendi
  renkleriyle — beyaz veya Zibo'nun altın tonu `0xFFF0C868`). Sheet'te iki ayrı seçici satırı var
  ("Arka plan" / "Yazı Stili"), birbirinden bağımsız state (`_selectedBackgroundIndex`,
  `_selectedTextStyleIndex`). Yazı stili önizleme kartçıklarının arka planı **uygulama temasından
  bağımsız sabit koyu bir renk** (`_textStylePreviewBackground`) — hem beyaz hem altın önizleme
  metninin açık temada da okunabilir kalması için.
  - `google_fonts` varsayılan olarak fontları ağdan indirir (ilk kullanımda, sonra cihazda
    önbelleğe alınır) — gerçek cihazda sorun değil, ama `flutter test`'te hem yavaşlatmasın hem de
    ağsız ortamda kararsızlık yaratmasın diye testte `GoogleFonts.config.allowRuntimeFetching =
    false;` ile kapatılıp yerel yedek fonta düşülüyor.
- **`ShareService` soyutlaması** (`AdService`/`PurchaseService` ile aynı desen): `ZiboShareSheet`
  gerçek `share_plus` çağrısını doğrudan yapmaz, constructor'dan aldığı `ShareService`'i çağırır
  (varsayılan: gerçek `SharePlusService`). "Paylaş"a basınca: `RenderRepaintBoundary.toImage
  (pixelRatio: 3.0)` (450×800 × 3 = 1350×2400, bkz. yukarıdaki 2026 boyut güncellemesi) → PNG baytları →
  `ShareService.shareImageBytes(...)`. Başarılı olursa sheet kapanır; hata olursa (ör. web'de
  paylaşım desteklenmiyorsa) `try/catch` ile yakalanıp bir `SnackBar` gösterilir, sheet açık kalır.
- `share_plus`'ın modern (deprecated olmayan) API'si kullanılıyor: `SharePlus.instance.share
  (ShareParams(files: [XFile.fromData(...)], fileNameOverrides: [...], text: ...))` —
  eski `Share.shareXFiles` statik metodu artık `@Deprecated`.
- **2026 yeni özellik — Level/XP Sistemi entegrasyonu: her BAŞARILI paylaşım +10 XP verir.**
  `_share()`'in başarı dalında, Sosyal/Paylaşım Rozetleri'nin `reconcileSocialBadges` çağrısının
  HEMEN ardından, `Navigator.pop()`'tan ÖNCE `context.read<XpProvider>().addXp(10)` çağrılıyor —
  paylaşım coin VERMEYEN bir aksiyon olduğu için (`CoinProvider._earn()`'ün merkezi kancasından
  GEÇMİYOR) doğrudan burada. Bkz. "Level/XP Sistemi" bölümü.

### Alt Gezinme Çubuğu ([main_bottom_bar.dart](lib/widgets/main_bottom_bar.dart), [z_floating_button.dart](lib/widgets/z_floating_button.dart), [modules_menu_sheet.dart](lib/widgets/modules_menu_sheet.dart))
- **Tamamen kod-tabanlı — hiçbir özel görsele bağımlı DEĞİL.** Standart Flutter'ın
  `BottomAppBar(shape: CircularNotchedRectangle())` + `Scaffold.floatingActionButton` +
  `FloatingActionButtonLocation.centerDocked` deseni kullanılıyor: `RootScreen`'in `Scaffold`'ı
  `floatingActionButton: ZFloatingButton(...)` ve `bottomNavigationBar: MainBottomBar(...)`
  tanımlıyor, Flutter'ın kendi Scaffold geometrisi ikisini otomatik hizalayıp bar'ın üst kenarına
  dairesel bir "çentik" (notch) açıyor — elle piksel/oran hesabı yok.
  - **Tarihçe:** İlk sürüm, kullanıcının verdiği `alt_bar.png` tasarımından piksel-piksel kırpılan
    özel PNG katmanlarına (açık/koyu tema için ayrı görseller, Z coin için ayrı bir görsel, koyu
    görselin şeffaflaştırılması, aktif-sekme pilinin görselden silinip programatik olarak yeniden
    çizilmesi — onlarca elle ölçülen oran sabiti) dayanıyordu. Kullanıcı ileride bu alanı
    değiştirirken bu görsel-işleme/piksel-eşleştirme karmaşasıyla tekrar uğraşmak istemediğini
    belirtip **alt barın TAMAMEN kaldırılıp** yerine kod-tabanlı bir alternatif konmasını istedi
    (Z coin butonu ve modül menüsü işlevi korunarak). `assets/images/bottom_bar_bg*.png` ve onları
    üreten `tool/` betikleri (crop/split/process/strip) bu geçişte silindi;
    `assets/images/bottom_bar_z_coin.png` ve `alt_bar.png` (orijinal referans) duruyor.
- **`MainBottomBar`**: `BottomAppBar` içinde `Row` — 4 `_NavItem` (Ana Sayfa/Hedefler/**Profil**/
  Mağaza — bkz. aşağıdaki "2026 güncellemesi — Profil↔Birikim yer değiştirme" notu) + ortada Z
  butonu için boşluk bırakan bir `Expanded(child: SizedBox.shrink())`, 5 eşit sütun (eski
  görsel-tabanlı tasarımla aynı 0.10/0.30/0.50/0.70/0.90 hizası, ama artık yalnızca `Expanded`
  oranlarıyla). Bar rengi `colorScheme.surfaceContainer` — açık/koyu tema arasında HİÇBİR
  özel kod dallanması yok, tema hangi rengi tanımlıyorsa o kullanılıyor.
- **`_NavItem`**: `Icon` (Material — `home_rounded`/`flag_rounded`/`account_circle_rounded`/
  `storefront_rounded`) + kısa etiket (`Text`). Seçiliyken ikonun arkasında `colorScheme.primary`
  renginde bir "hap" (`AnimatedContainer`, 220ms) belirir — bu, eski görsele gömülü "Ana Sayfa
  aktif" piline kıyasla HERHANGİ bir sekmenin altına sorunsuzca taşınabiliyor (eski sürümde bu
  dinamik değildi, sonra programatik bir onarımla dinamikleştirilmişti — şimdi baştan dinamik).
  - **Semantics gotcha'sı:** `Semantics(label: semanticLabel, child: InkWell(...Text(visibleLabel)))`
    yazıldığında, içerideki `Text`'in KENDİ otomatik ürettiği semantics etiketi dıştaki `label`la
    BİRLEŞİP `"Hedef Takibi\nHedefler"` gibi birleşik bir etikete dönüşüyordu —
    `find.bySemanticsLabel('Hedef Takibi')` (tam eşleşme) bu yüzden hiçbir şey bulamıyordu. Çözüm:
    `Semantics(..., excludeSemantics: true, ...)` — alt ağacın kendi semantics düğümlerini bastırıp
    yalnızca dıştaki `label`i kullanır. **Bir `Semantics(label:)` widget'ı, içinde görünür metin/ikon
    barındıran bir çocuğu sarıyorsa bu deseni tekrarlayın.**
  - Görünen etiket (`visibleLabel`) ile erişilebilirlik etiketi (`semanticLabel`) KASITLI olarak
    farklı: görünen etiketler kısa (`bottomBarGoalsLabel`="Hedefler" için), semantics etiketleri ise
    `l10n.tabGoalTracking` ("Hedef Takibi") gibi daha açıklayıcı, başka yerlerde (ör. sayfa
    başlıkları) de kullanılan DEĞERLER — testler (`find.bySemanticsLabel(...)`) bu uzun değerleri
    arıyor, bar'daki kısa görünür metinleri DEĞİL. **Profil sekmesi istisna:** hem görünen hem
    semantics etiketi `l10n.profileScreenTitle` ("Profil") — ayrı kısa/uzun bir çift gerekmedi,
    "Profil" zaten kısa.
- **2026 güncellemesi — Profil↔Birikim yer değiştirme:** Kullanıcı isteği: "Bottom bardaki birikimi
  Z butonunun [menüsüne] alalım, birikimle profili yer değiştirelim." Gerekçe belirtilmedi (kullanıcı
  tercihi) — sonuç: Profil (`ProfileScreen`) alt gezinme çubuğunun 3. sekmesi oldu (eskiden Para ve
  Birikim'in yeriydi), Para ve Birikim (`MoneyScreen`) Z butonu modül menüsünün 6. kartına taşındı
  (eskiden Profil'in yeriydi). Bu, iki ekranın "sekme" ↔ "pushed modül" statülerini TAM TERSİNE
  çevirdiği için her ikisinde de Scaffold/AppBar sahipliği DEĞİŞTİ:
  - `MoneyScreen` kendi `Scaffold(appBar: AppBar(...))`'unu KAZANDI (bkz. "Para ve Birikim"
    bölümü) — artık RootScreen'in ortak AppBar'ını paylaşmıyor.
  - `ProfileScreen` kendi `Scaffold`/`AppBar`'ını KAYBETTİ (bkz. "Profil" bölümü) — artık
    RootScreen'in ortak AppBar'ını paylaşıyor, diğer sekmeler gibi.
  - `StoreScreen`'deki özel `_StoreSection` enum'u **public** `StoreSection`'a çevrildi + `StoreScreen`
    yeni bir `initialSection` parametresi kazandı — Profil'in "Kostüm Dolabı Önizlemesi" satırının
    doğrudan "Kostümler" segmentine deep-link atabilmesi için (bkz. "Profil" bölümü).
  - **Test gotcha'sı (tekrar yaşandı):** `widget_test.dart`'ın `_buildAppWithClock()` yardımcısına
    yeni eklenen `ProfileScreen`'in ihtiyaç duyduğu TÜM provider'lar (`TrustedTimeProvider`,
    `GratitudeProvider`, `ManifestProvider`, `ProfileProvider`, `WaterProvider`) eklenmesi
    gerekti — `IndexedStack` artık `ProfileScreen`'i de hep monte ettiği için (bkz. "Test kalıpları"
    bölümündeki genel gotcha). Ayrıca nav swap'ından SONRA, `Para ve Birikim`'e eskiden bottom-tab
    tap'iyle ulaşan 3-4 test senaryosu Z-menü push desenine, `Profil`'e eskiden Z-menü'yle ulaşan
    senaryo ise doğrudan bottom-tab tap'ine çevrildi.
- **`ZFloatingButton`** ([z_floating_button.dart](lib/widgets/z_floating_button.dart)): eski
  `_ShakingZButton`'ın ta kendisi, `MainBottomBar`'dan ayrı bir dosyaya taşındı (artık
  `Scaffold.floatingActionButton` olarak bağlandığı için kendi `AnimationController`'ını kendi
  taşıyor). Z Coin görselini `AnimatedBuilder` + `Transform.rotate(angle: sin(...)  *
  0.06)` ile sürekli hafifçe sallıyor (2.4sn'de bir tam sinüs turu, `disableAnimations`'a saygılı —
  bkz. "Şans Çarkı" bölümündeki aynı desen), dokununca `showModulesMenuSheet` açıyor. Görsel
  boyutu artık bar genişliğine ORANLI değil, sabit bir mantıksal boyut (`_coinSize = 64`) — normal
  bir `FloatingActionButton` boyutuna yakın.
  - **2026 güncellemesi — kostüme göre değişen Z Coin teması.** Kullanıcı Altın Zibo veya Elmas
    Kaplama Zibo kostümünü giyerken alt bardaki Z Coin görselinin de o kostümün temasına uysun istedi.
    `_coinAssetFor(String? equippedCostumeId)` — `context.watch<CostumeProvider>().equippedId`'ye
    göre üç görselden birini seçen basit bir `switch`: `zibo_altin` →
    `bottom_bar_z_coin_altintema.png`, `zibo_elmas` → `bottom_bar_z_coin_elmastema.png`, HER TÜRLÜ
    diğer durum (başka bir kostüm VEYA kostümsüz) → standart `bottom_bar_z_coin.png`.
  - **Buton boyutu SABİT kalıyor — üç PNG de AYNI 374x374 kare tuvale kırpıldı.** Yeni iki tema
    dosyası kullanıcıdan 1408×768'lik geniş/dolgulu bir kanvasla geldi (poz PNG'leriyle AYNI
    "kullanıcı-kaynaklı geniş kanvas" durumu) — `tool/measure_coin_bounds.dart` ile ölçülüp,
    `tool/process_coin_theme.dart` (YENİ, tek seferlik görsel işleme betiği) ile MEVCUT
    `bottom_bar_z_coin.png`'nin kendi doluluk oranına (içerik/kanvas ≈ 360/374 ≈ %96.3) göre
    kırpılıp ölçeklenip 374x374'lük şeffaf bir kare tuvalin TAM ORTASINA yapıştırıldı. Üç PNG'nin
    kanvas boyutu artık BİREBİR aynı olduğu için, `Image.asset(...)` widget'ının iç ölçekleme
    davranışından (fit vb.) BAĞIMSIZ olarak `SizedBox(width: _coinSize, height: _coinSize)` içinde
    hep AYNI görünür boyutta render ediliyor — yalnızca görsel/tema değişiyor, boyut asla
    kaymıyor. Orijinal (kırpılmamış) tema dosyalarının yedeği `tool/pose_originals_backup/` altında.
  - **Test:** yeni `test/z_floating_button_test.dart` — `ZFloatingButton`'ı minimal bir
    `ChangeNotifierProvider.value(value: costumeProvider)` ağacında izole test ediyor (tam
    `DijitalKankaApp`'i kurmaya gerek yok): kostümsüzken/poz seti olmayan bir kostümde standart
    görsel; Altın giyiliyken altıntema; Elmas giyiliyken elmastema; kostüm çıkarılınca standart
    görsele dönüş. `CostumeProvider.markOwned()` + `toggleEquipped()` doğrudan çağrılıyor —
    satın alma akışının UI'ından geçmeye gerek yok (`CostumeProvider`'ın coin'den bağımsız olması
    sayesinde, bkz. yukarıdaki mimari notu).
- **`showModulesMenuSheet`** ([modules_menu_sheet.dart](lib/widgets/modules_menu_sheet.dart)):
  `showDragHandle: true` ile bir bottom sheet, ALTI `_ModuleCard` (Rüya Günlüğü, Şükran Günlüğü,
  Günlük Ruh Hali Takibi, Su Takibi, Manifest Günlüğü, **Para ve Birikim**) — ilk üçü daha önce
  dağınık yerlerdeydi (bkz. ilgili bölümlerdeki "Tarihçe" notları) ve buraya taşındı; Su Takibi ve
  Manifest Günlüğü baştan beri bu menüde tanıtıldı; Para ve Birikim ise (2026 güncellemesi) eskiden
  Profil'in bulunduğu ALTINCI kart konumuna taşındı (bkz. yukarıdaki "Profil↔Birikim yer değiştirme"
  notu — Profil artık burada DEĞİL, bottom bar'ın 3. sekmesinde). Ayarlar artık yalnızca uygulama
  geneli ayarlarını içeriyor — Su Takibi'nin günlük hedef ayarı da modülün kendi ekranındadır,
  Ayarlar'da DEĞİL (bkz. "Su Takibi" bölümü).
- **2026 güncellemesi — "Ek Modüller" başlığı kaldırıldı.** Kullanıcı isteği: liste doğrudan modül
  kartlarıyla başlasın, ayrı bir başlık yazısına gerek yok. `showModulesMenuSheet`'in `Column`'unun
  en başındaki `Text(l10n.modulesMenuTitle)` + altındaki `SizedBox(height: 16)` satırları
  kaldırıldı — sheet artık sürükleme tutamacının hemen altında ilk `_ModuleCard`'la başlıyor.
  `modulesMenuTitle` ARB anahtarı kod tabanında artık kullanılmıyor ama ARB dosyalarından
  SİLİNMEDİ (kullanımda olmayan bir çeviri anahtarını silmek başka bir yerde yeniden kullanılma
  ihtimalini gereksiz karmaşıklaştırır, zararsız).
- **Bilinen sınırlama YOK artık:** eski görsel-tabanlı sürümün "dinamik aktif-sekme vurgusu yok"
  ve "her iki temada ayrı görsel + piksel eşleştirme gerektirir" sınırlamalarının ikisi de bu
  yeniden yazımla ortadan kalktı — renkler/ikonlar/vurgu tamamen tema ve kod üzerinden geliyor.
- **Test:** `_openModulesMenu()` hâlâ `find.bySemanticsLabel('Ek modülleri aç')` kullanıyor (Z
  butonunun semantics etiketi değişmedi). Sekme geçişleri de hâlâ
  `find.bySemanticsLabel('Ana Sayfa'/'Hedef Takibi'/'Profil')` — artık gerçek `Text`
  widget'ları da var ama testler bilerek semantics üzerinden gidiyor (daha kararlı, `excludeSemantics`
  sayesinde tek/temiz bir etiket). **Para ve Birikim ARTIK bir bottom-tab semantics etiketiyle
  erişilmiyor** — `_openModulesMenu()` + `find.text('Harcamalar ve Birikimler')` (modül kartının
  başlığı, `l10n.moneyScreenTitle`) deseniyle push ediliyor, dönüşte `find.byTooltip('Geri')`
  kullanılıyor (bkz. "Para ve Birikim" bölümündeki yeni Scaffold/AppBar notu). "Mağaza + ikonuyla açılır..." testi `find.text('Mağaza')` için
  `findsNWidgets(2)` bekliyor (biri sayfa başlığı, biri artık gerçek olan bar etiketi) —
  görsel-tabanlı sürümde bu `findsOneWidget`'tı, kod-tabanlı sürüme dönünce eski davranışa
  geri döndü. `setUp()`'ın gerçekçi telefon viewport'u (412×915) sabitlemesi hâlâ duruyor (genel
  olarak faydalı, artık bu spesifik widget'a bağlı değil). Gerçek cihazda hem açık hem koyu temada
  4 sekme + Z butonu (otomatik test paketiyle) doğrulandı.

