# ARŞİV — Şans Çarkı, Günlük Giriş Ödülleri, Para ve Birikim

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 1393–1812).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

### Şans Çarkı ([wheel_prize.dart](lib/models/wheel_prize.dart), [wheel_prizes.dart](lib/data/wheel_prizes.dart), [prize_wheel.dart](lib/widgets/prize_wheel.dart), [wheel_trigger_button.dart](lib/widgets/wheel_trigger_button.dart), [wheel_screen.dart](lib/screens/wheel_screen.dart), [tool/split_wheel_layers.dart](tool/split_wheel_layers.dart))
- `WheelTriggerButton._size` 72px (60'tan büyütüldü, kullanıcı isteğiyle daha dikkat çekici olsun
  diye) — coin'lerin boyutu (22/18) da aynı oranda büyütüldü ki orantı bozulmasın.
- Ekranın sol kenarında, **yalnızca Ana Sayfa sekmesinde** (bkz. yukarıdaki `RootScreen`/Ana Sayfa
  notları — `RootScreen`'de `if (_selectedIndex == 0)` koşullu, dikey konumu `Alignment(-1, -0.5)`
  ile üst tarafa yakın) sürekli görünen dikkat çekici bir `WheelTriggerButton`; basılınca
  `showDialog` ile tam ekran `WheelScreen` (`Dialog.fullscreen`) açılır. **Günlük çevirme sınırı
  ARTIK VAR** (2026 güncellemesi, bkz. altta "Günlük reklam hakları" bölümü) — eski "bilinçli
  olarak yok" kararı kullanıcı isteğiyle tersine çevrildi.
- **Ağırlıklı ödül seçimi tek yerde, kolayca ayarlanabilir:** `wheel_prizes.dart`'taki `wheelPrizes`
  listesi 8 `WheelPrize(amount, weight)` içeriyor (2/5/10 ZC ~%27-28, 20 ZC ~%9, 50-250 ZC ~%1.5-3 —
  en büyük ödül 250 ZC en düşük ağırlıklı). Ağırlıkların 100'e tamamlanması zorunlu değil, yalnızca
  okunabilirlik için öyle seçildi; `pickWeightedPrize(prizes, random)` yalnızca göreceli ağırlığa
  bakar (kümülatif aralık + `random.nextDouble() * toplamAğırlık`).
- **Görseller tek parça `zibo_cark.png`'den bölünerek üretildi:** `tool/split_wheel_layers.dart`
  (tek seferlik yardımcı betik, `dart run tool/split_wheel_layers.dart <dosya>` ile çalıştırılır),
  bir çark görselini merkeze olan uzaklığa (yarıçap) göre iki PNG'ye ayırıyor:
  `zibo_cark_disk.png` (yalnızca ödül dilimlerinin olduğu iç halka — döner) ve
  `zibo_cark_frame.png` (dış süslü çerçeve + ok işaretçi + merkez hub — sabit kalır). Bölme
  sınırları (`_diskInnerFraction`/`_diskOuterFraction`/`_frameHubFraction`/`_frameRingFraction`,
  hepsi 0-1 arası yarıçap kesri) görsele özel ölçülüp betiğe sabit yazıldı; yeni bir çark görseli
  gelirse bu sabitlerin yeniden ölçülmesi gerekir. Frame'in iç/dış kenarları disk'in görünür
  alanının biraz içine taşacak şekilde kesiliyor (`_featherFrac` ile yumuşak geçiş) — bu örtüşme
  güvenli çünkü **bir dairenin kendi merkezi etrafında dönüşü kendi siluetini değiştirmez**, yani
  disk hangi açıya dönerse dönsün kenar/merkezde asla boşluk (seam) görünmez.
  - **Birim hatası dersi:** `_featherFrac` ilk yazımda piksel birimiyle (`2.0`) tanımlanıp doğrudan
    0-1 aralığındaki yarıçap kesriyle (`rFrac`) karşılaştırılmıştı — bu, yumuşak geçiş bandının
    neredeyse TÜM 0-1 aralığını yutmasına ve her iki katmanın da (disk/frame) birbirinden ayırt
    edilemez şekilde yarı saydam görünmesine yol açtı. Görsel `Read` önizlemesi bile bu hatayı ilk
    bakışta gizledi (önbelleklenmiş/stale bir önizleme gösterdi) — kesin doğrulama için köşe/orta
    noktalarda alfa değerini sayısal olarak ölçen küçük bir problama betiği yazmak gerekti. **Bu
    tür radyal maskeleme işlerinde her zaman sayısal doğrulama yapın, yalnızca görsel önizlemeye
    güvenmeyin.**
- **`PrizeWheel`** artık saf görsel bir `Stack`: `Transform.rotate` ile döndürülen
  `zibo_cark_disk.png` + üstüne sabit `zibo_cark_frame.png`. Eski `CustomPainter`/`showLabels`
  kodu tamamen kaldırıldı — ok işaretçisi ve "Reklam İzle ve Çevir" hub metni artık
  `zibo_cark_frame.png`'nin içinde hazır geliyor, ayrıca çizilmiyor. `WheelScreen`, hub'ın üzerine
  yalnızca görünmez/dokunulabilir bir `InkWell` (`Key('wheelSpinButton')` ile işaretli, boyutu
  `_hubSizeFraction = 0.74` — `_frameHubFraction*2` ile eşleşecek şekilde) ve çevirme sırasında bir
  `CircularProgressIndicator` yerleştiriyor.
- **`WheelTriggerButton`** iki bağımsız katman: arka planda sürekli ve hızlı dönen
  `zibo_cark_katman1.png` (`_spinController`, 3sn'de bir tam tur, `Transform.rotate`) + önde
  dönmeyen ama sürekli hafifçe büyüyüp küçülen (`sin` dalgalı ölçek, faz kaydırmalı) iki adet
  `zibo_coin.png` kopyası (`_pulseController` + `_PulsingCoin`).
  - **`zibo_cark_katman2.png` planlanandan farklı kullanıldı:** İstenen tasarımda bu dosyanın
    dönmeyen ön katman (coin'lerin bulunduğu katman) olması gerekiyordu, ancak dosyanın gerçek
    içeriği 2326×1297 boyutunda, coin'lerin dağınık biçimde bir boşluk etrafına serpiştirildiği VE
    altına "Şans Çarkı" başlık yazısının gömülü olduğu geniş bir banner — küçük kare bir butona
    (60px) kırpılabilecek temiz bir coin halkası içermiyor. Birkaç kırpma denemesi (farklı merkez
    tahminleriyle) hep ya metne kesiyor ya da çoğu coin'i dışarıda bırakıyordu. Kullanıcıyla
    (`AskUserQuestion`, "Bu görsellerle devam et, elimden geleni yap" seçildi) pragmatik çözüm:
    `zibo_cark_katman2.png` **kullanılmadı**, yerine zaten temiz/şeffaf olan `zibo_coin.png`'nin
    (bkz. coin bakiyesi/fiyat gösterimlerinde de kullanılan asset) iki küçük kopyası nabız
    animasyonuyla eklendi. `zibo_cark_katman1.png` de benzer şekilde aslında farklı ödül
    etiketleriyle ("100x ZIBO", "BÜYÜK İKRAMİYE" vb.) tam bir alternatif çark görseli — ama 60px'lik
    küçük boyutta soyut, renkli, hızlı dönen bir bulanıklık olarak okunduğundan olduğu gibi
    kullanıldı. Dosya diskte duruyor ama kodda referans edilmiyor.
- **Çevirme akışı:** `CoinProvider.watchAdAndSpinWheel()` — `AdService.showRewardedAd()` (bkz.
  `MockAdService`) tamamlanırsa `pickWeightedPrize` ile ödülü seçip ekler ve `WheelPrize?` döner
  (reddedilirse `null`, hiçbir şey eklenmez). `WheelScreen`, dönen ödülün `wheelPrizes` içindeki
  index'ini bulup çarkı **gerçekten o dilimde** durduracak hedef açıyı hesaplıyor (`targetIndex`'in
  saat 12 hizasına gelmesi + en az 5 tam tur, hep ileri yönde — asla geri dönmüyor). Sonuç, bir
  `AlertDialog` ile net gösteriliyor ("Tebrikler! {amount} Zibo Coin kazandın!") — tarayıcıda
  doğrulandı: duran dilim ile diyalogdaki ödül miktarı birebir eşleşiyor.
- **`CoinProvider`'a enjekte edilebilir `Random`** eklendi (constructor'dan, `AdService`/
  `PurchaseService` ile aynı desen) — testte ağırlıklı seçimi kontrol edebilmek için.
- **Kritik gotcha — sürekli tekrar eden animasyon `pumpAndSettle()`'ı sonsuza kadar bekletir:**
  `WheelTriggerButton`'ın (artık iki: `_spinController` + `_pulseController`) `AnimationController
  ..repeat()`'i asla "settle" olmadığından (ticker hiç durmuyor), `RootScreen`'i (dolayısıyla her
  yerde) pump'layan HER TEST `pumpAndSettle()`'da timeout yemeye başladı. Çözüm: widget artık
  `MediaQuery.of(context).disableAnimations` bayrağına saygı duyuyor (true iken `repeat()` hiç
  başlamıyor) — bu hem gerçek kullanıcıların OS düzeyindeki "hareketi azalt" erişilebilirlik
  tercihini onurlandırıyor hem de testte `widget_test.dart`'ın `setUp()`'ında
  `(TestWidgetsFlutterBinding.instance.platformDispatcher as
  TestPlatformDispatcher).accessibilityFeaturesTestValue = const
  FakeAccessibilityFeatures(disableAnimations: true)` ile bayrağı sabitleyerek çözülüyor. **Sürekli
  dönen/tekrar eden yeni bir animasyon eklerken bu deseni tekrarlayın** — aksi halde
  `widget_test.dart`'taki (ve `RootScreen`'i pump'layan başka her) test kırılır.
- **Gotcha — `late final AnimationController`, yalnızca koşullu erişilen bir alanla birlikte
  kullanılırsa `dispose()` içinde çökebilir:** `WheelScreen._controller`, yalnızca `_spin()`
  çağrıldığında (kullanıcı gerçekten çevirdiğinde) okunuyordu; `build()` doğrudan `_controller`'a
  değil `_rotationAnimation`'a bağlıydı. Kullanıcı çarkı hiç çevirmeden kapatırsa `late final`'in
  TEMBEL başlatıcısı ilk kez `dispose()` içinde tetikleniyor, bu da `vsync: this` için gereken
  ancestor look-up'ı widget zaten deactivate edilmişken yapmaya çalışıp "Looking up a deactivated
  widget's ancestor is unsafe" hatasıyla çöküyordu (testte bir önceki test'in yarım kalan
  temizliğiyle ortaya çıktı, ama gerçek kullanımda da olurdu). **Çözüm:** controller'ı `late final`
  bırakıp değerini `initState()` içinde ata (field initializer'da değil) — böylece widget mount
  olurken, henüz aktifken oluşturuluyor ve `dispose()` her zaman zaten-var-olan bir controller'ı
  kapatıyor. **Kural: bir `AnimationController` `build()`'de koşulsuz kullanılmıyorsa (yalnızca bir
  event handler'da referans alınıyorsa), `late final = AnimationController(...)` yerine
  `initState()`'te açıkça ata.**

### Günlük Giriş Ödülleri ([daily_rewards_provider.dart](lib/providers/daily_rewards_provider.dart), [daily_rewards_trigger_button.dart](lib/widgets/daily_rewards_trigger_button.dart), [daily_rewards_screen.dart](lib/screens/daily_rewards_screen.dart))
- Ekranın **sağ** kenarında, Şans Çarkı'nın (sol kenar) **simetriği** olarak duran, sürekli görünen
  bir tetikleyici — yalnızca Ana Sayfa sekmesinde (`RootScreen`'de `WheelTriggerButton`'la AYNI
  koşullu-görünürlük deseni: `Align(alignment: Alignment(1, -0.8), child: ...)`). Tıklanınca ortada
  (Şans Çarkı'nın aksine TAM EKRAN DEĞİL) küçük, yuvarlak köşeli bir `Dialog` açılır: 7 gün
  kutucuğu, her biri o günün ZC miktarını gösterir (5/10/15/20/30/40/100 — `CoinEconomy.
  dailyLoginRewards` dizisinde tek yerde tanımlı, kullanıcı isteğiyle sabit).
- **Görsel: hiçbir yeni asset gerektirmiyor** — `Icons.card_giftcard_rounded` ikonlu, aktif temanın
  `colorScheme.primary`'sinden türeyen bir `RadialGradient` rozet (bkz. "Temalar" bölümü — kullanıcı
  bir tema seçtiğinde bu buton da otomatik olarak o temanın rengini alır, tıpkı bottom bar/butonlar
  gibi). Bugünün ödülü henüz alınmadıysa hafif bir "nabız" (ölçek + `boxShadow` parlaması)
  animasyonuyla dikkat çeker; alınmışsa animasyon durur ve köşede küçük bir tik rozeti belirir —
  `WheelTriggerButton`'daki `disableAnimations`'a saygı gösterme deseniyle AYNI (bkz. "Şans Çarkı"
  bölümündeki gotcha), yalnızca ek bir koşul (`!isTodayClaimed`) daha var.
- **Mimari, `GoalsProvider`'daki TEK bir hedefin döngüsüyle BİREBİR AYNI desen** (gerçek takvim
  tarihine bağlı `cycleStartDate` + o döngüde alınmış tarihlerin kümesi) — ama kullanıcının
  oluşturduğu birden çok hedef yerine uygulama genelinde TEK bir global döngü olduğu için ayrı bir
  `Goal`-benzeri model sınıfına gerek kalmadı, hepsi `DailyRewardsProvider` içinde. Coin ödülü vermek
  bu provider'ın işi değil — `GoalsProvider`/`WaterProvider` ile aynı gerekçeyle coin sistemine
  bağımlı değil; `claimToday()` o günün miktarını (veya `null`) döner, gerçekten eklemek
  (`CoinProvider.earnDailyLoginReward(amount)`) çağıran ekranın sorumluluğunda.
- **2026 bug düzeltmesi — döngü "her gün 1. gün olarak açılıyor, önceki günün ödülü
  kaydedilmemiş gibi görünüyor" (gerçek kullanıcı raporu).** Kök neden `reconcileForToday()`'deki
  `idx < 0` dalıydı: `TrustedTimeProvider` ağdan HENÜZ doğrulama yapmadan ÖNCE (uygulamanın ilk
  açılışının ilk anları, bkz. "Firestore veri kalıcılığı... güvenilir zaman" bölümü) cihazın kendi
  (yanlış/ileri ayarlı olabilen) saatine geçici olarak düşüyor — eğer `DailyRewardsProvider`'ın
  İLK KURULUMU tam bu pencereye denk gelirse, `_cycleStartDate` yanlışlıkla GELECEKTEKİ bir tarihle
  başlıyordu. Ağ saati düzelip gerçek "bugün" daha ERKEN bir tarihe dönünce `today < cycleStartDate`
  (`idx` negatif) oluyor — eski kod bunu da "sıfırlanması gereken" sayıp `_claimedDates`'i
  SİLİYORDU, bu da poisoned tarihe ulaşana kadar HER `reconcileForToday()` çağrısında (yani her gün)
  tekrarlanıyordu. **Düzeltme:** `idx < 0` artık HİÇBİR ŞEYİ SİLMEDEN no-op dönüyor (`GoalsProvider.
  _reconcileGoal`'ın `while (cursor.isBefore(today))` deseni bu anomaliye zaten doğal olarak bağışık
  — bu yüzden Hedef Takibi'nde AYNI raporun hiç gelmediği fark edildi, sorun `DailyRewardsProvider`'a
  ÖZGÜYDÜ) — gerçek zaman poisoned tarihe doğal olarak ulaşınca veri kaybı olmadan kendiliğinden
  düzeliyor. Gerçek release-imzalı bir build'de doğrulandı (yeni test:
  `daily_rewards_provider_test.dart`'taki "cycleStartDate cihaz saati anomalisiyle bugünün
  İLERİSİNDE kalırsa..." senaryosu).
- **2026 İKİNCİ bug düzeltmesi — bir tester raporu: "günlük giriş ödülleri bu seferde 2. günde
  takılı kalıyor."** Kullanıcıyla birlikte İKİ soruyla netleştirildi: (a) sorun uygulama İÇİ
  popup'ta mı yoksa ana ekran WIDGET'ında mı gözlemlendi — cevap: uygulama içi popup; (b) gün
  gerçek zamanla mı ilerledi yoksa cihaz saati elle mi değiştirildi — cevap: gerçek zaman geçti.
  Bu, hem "cihaz saatini kandırmaya çalışma" (bilerek engellenen, bug OLMAYAN bir senaryo) hem de
  "ana ekran widget'ının, uygulama açılmadan güncellenmemesi" (ayrı, muhtemel bir sınırlama)
  ihtimallerini elemek için soruldu — asıl kök nedene bu netleştirmeden SONRA ulaşıldı.
  - **Kapsamlı ama SONUÇSUZ kalan statik analiz:** `TrustedTimeProvider`/`DailyRewardsProvider`/
    `CloudStateStore` tekrar tekrar elle izlendi (cross-session staleness, Firestore-öncelik-
    sırası, tarih serileştirme/round-trip, `_resyncCooldown` etkileşimi) — hiçbir mantık hatası
    BULUNAMADI. Ardından "her gün uygulamayı zorla kapatıp aç" gerçek test kalıbını simüle eden
    geçici (sonradan silinen) testler yazıldı: Gün 1 claim → provider'ı YENİDEN OLUŞTUR (force-
    close simülasyonu) → Gün 2 claim → provider'ı YENİDEN OLUŞTUR → Gün 3'e bak — bu senaryo DA
    HER SEFERİNDE doğru sonuç verdi (`todayIndex` doğru ilerliyordu). **Kök neden koddan OKUYARAK
    değil, bu ampirik testlerin SONUÇSUZ kalmasından SONRA farklı bir açıdan (hangi widget'lar
    provider'ı İZLİYOR VE sürekli monte mi kalıyor) bakılınca bulundu.**
  - **Gerçek kök neden — `reconcileForToday()`, bir SIFIRLAMA olmadığı sürece
    `notifyListeners()`'ı HİÇ ÇAĞIRMIYORDU.** `todayIndex`/`isTodayClaimed`/`statusForIndex()`
    saf GETTER'lar olduğu için (her erişimde `_now()`'a göre YENİDEN hesaplanıyorlar) TAZE açılan
    bir widget (`DailyRewardsScreen` popup'ının KENDİSİ — `showDialog` her seferinde YENİ bir
    örnek kurduğu için) HER ZAMAN doğru günü gösteriyordu; bu yüzden ne kullanıcı ne asistan
    popup'ı doğrudan test ederken sorunu YAKALAYAMADI. Ama `DailyRewardsTriggerButton`
    (`RootScreen`'in `IndexedStack`'i yüzünden sekmeler arası geçişte ASLA dispose OLMUYOR, bkz.
    "Mimari özet" bölümündeki `IndexedStack` gotcha'sı) `context.watch<DailyRewardsProvider>()
    .isTodayClaimed`'e göre bir ✓ rozeti gösteriyor — Gün 1 alınınca bu rozet DOĞRU şekilde
    beliriyordu, ama Gün 2 SESSİZCE (sıfırlama gerekmeden, `_cycleStartDate`/`_claimedDates`
    hiç değişmeden) geldiğinde `reconcileForToday()` `notifyListeners()` ÇAĞIRMADIĞI için bu
    SÜREKLİ MONTE widget hiç YENİDEN BUILD OLMUYORDU — dünün ✓ rozetini GÜN DEĞİŞTİKTEN GÜNLER
    SONRA BİLE göstermeye devam ediyordu. Tester bu rozeti görüp "2. günde takılı kaldı" diye
    bildirdi — popup'ı GERÇEKTEN açsalardı muhtemelen doğru günü/kutucuğu görürlerdi, ama sürekli
    yanlış "zaten alındı" izlenimi veren rozet onları popup'ı hiç açmadan "bozuk" sonucuna
    götürmüş olabilir.
  - **Ampirik doğrulama — hedefe yönelik bir provider testiyle KANITLANDI:** `provider.
    addListener(...)` ile bir sayaç eklenip Gün 1 claim edildikten SONRA Gün 2'ye geçilip
    (sıfırlama GEREKMEYEN bir geçiş) `reconcileForToday()` çağrıldı — düzeltmeden ÖNCE
    `notifyCount == 0` (kanıtlanmış çökme/durgunluk kaynağı), düzeltmeden SONRA `notifyCount > 0`.
    Bu test kalıcı olarak `daily_rewards_provider_test.dart`'a eklendi.
  - **Düzeltme:** `reconcileForToday()`'in "sıfırlama gerekmiyor" dalı artık `return false`'tan
    HEMEN ÖNCE koşulsuz `notifyListeners()` çağırıyor (sıfırlama dalı zaten çağırıyordu, DEĞİŞMEDİ)
    — sürekli monte kalan HER widget artık her `reconcileForToday()` çağrısında (uygulama öne
    gelince, popup her açılışında) taze günü yansıtacak şekilde yeniden build oluyor.
  - **Genelleştirilebilir ders — bu proje genelinde tekrarlayan bir kalıp:** bir `ChangeNotifier`
    metodunun "bir şey DEĞİŞTİ mi?" diye SORUP yalnızca DEĞİŞİKLİK olduğunda `notifyListeners()`
    çağırması, TAZE açılan/yeniden oluşturulan widget'lar için ZARARSIZ görünse de (onlar zaten
    canlı state'i doğrudan okuyor), SÜREKLİ MONTE kalan widget'lar (özellikle bu projenin
    `IndexedStack` sekme mimarisinde YAYGIN olan bir desen) için SESSİZ bir durgunluk riski taşır
    — özellikle "durum" zaman GEÇTİKÇE (bir alan MUTASYONU olmadan) kendiliğinden değişebiliyorsa
    (buradaki "hangi gün bugün" gibi). **Böyle bir provider'da, dışarıdan çağrılan bir
    "reconcile/senkronize et" metodunun, SONUCU DEĞİŞTİRMESE bile `notifyListeners()`'ı ÇAĞIRMASI
    daha güvenli bir varsayılandır** — maliyeti (gereksiz bir rebuild) neredeyse sıfırdır, ama
    atlanması gerçek, kullanıcı tarafından fark edilen bir "takılı kalma" hissi yaratabilir.
- **2026 güncellemesi — ödül alınınca bir geçiş (interstitial) reklamı da gösteriliyor.** Kullanıcı
  isteği: "kişi günlük giriş ödülünü alınca da geçilebilir reklam olsun" — BİLEREK ÖDÜLLÜ
  (rewarded) DEĞİL, "Zibo'ya Art Arda Dokunma" bölümündeki AYNI `CoinProvider.
  showInterstitialAd()` çağrısı (bkz. o bölüm). `_DailyRewardsScreenState._claimDay()`,
  `earnDailyLoginReward(amount)`'tan HEMEN SONRA `unawaited(coin.showInterstitialAd())`
  çağırıyor — coin bakiyesini/işlem geçmişini HİÇ etkilemiyor, günde en fazla BİR kez tetiklenir
  (ödül zaten günde bir kez alınabildiği için ayrı bir sınırlama koduna gerek YOK). Reklam
  yüklenemezse (ağ yok, envanter boş) `showInterstitialAd()` sessizce `false` döner, ödülün
  kendisi HİÇ etkilenmez — coin zaten reklamdan ÖNCE eklenmiş durumda.
  - **Test gotcha'sı — gerçek reklam servisi kullanan bir teste YENİ bir reklam çağrısı
    eklemek "A Timer is still pending" hatasına yol açtı (o zamanki gerçek servis `AdMobAdService`
    idi, bkz. "AdMob → Appodeal geçişi" bölümü — `AppodealAdService` de AYNI 8sn'lik zaman aşımı
    desenini taşıdığı için bu gotcha güncelliğini koruyor):** `widget_test.dart`'taki "Günlük Giriş
    Ödülleri: bugünün kutucuğuna dokununca ödül alınır..." testi `const DijitalKankaApp()`
    (varsayılan, gerçek reklam servisi) kullanıyordu — `showInterstitialAd()`'ın `flutter_test`
    ortamında hiç tamamlanmayan 8sn'lik yükleme zaman aşımı Timer'ı, test biterken hâlâ askıda
    kalıp assertion'ı tetikledi (`showRewardedAd()`'ın Mağaza'daki reklam testinde ZATEN bilinen
    AYNI sorun). **Çözüm:** Mağaza'nın reklam testindeki AYNI desen — bu test de artık
    `DijitalKankaApp(adService: const MockAdService())` kullanıyor. **Ders (tekrar):** bir ekrana
    `CoinProvider.showRewardedAd()`/`showInterstitialAd()` çağrısı eklerken, o ekranı `const
    DijitalKankaApp()` (varsayılan gerçek AdMob) ile test eden HERHANGİ bir mevcut widget testi
    varsa, `MockAdService` enjekte etmeye çevrilmesi GEREKEBİLİR.
- **`reconcileForToday()` — TEK bir metotta İKİ gereksinimi birleştiriyor:** (1) "bir gün kaçırılırsa
  döngü Gün 1'den yeniden başlasın" VE (2) "Gün 7 alındıktan sonra ertesi gün otomatik yeni döngü
  başlasın". `GoalsProvider._reconcileGoal`'da bu ikisi AYRI ele alınıyordu (2. durum `toggleToday`
  içinde 7/7 anında `cycleStartDate`'i hemen ileri alıyordu) — burada daha basit tek bir kontrolle
  birleştirildi: `todayIndex` (bugün - cycleStartDate) 0-6 aralığının DIŞINDaysa (7 günlük pencere
  tamamen geride kaldıysa, tamamlanmış olsun ya da olmasın) YA DA aralık içinde ama bugünden önceki
  bir gün işaretlenmemişse, döngü bugünden sıfırlanır. Bu birleşim, `GoalCompletion` gibi kalıcı bir
  "tamamlanma geçmişi" özelliği bu modül için İSTENMEDİĞİ için mümkün oldu (Goal'da geçmiş kaydı
  tutmak için sıfırlamadan HEMEN ÖNCE bir snapshot almak gerekiyordu, burada gerekmiyor).
  - **Kasıtlı sonuç — Gün 7 alındıktan sonra AYNI gün içinde tüm kutucuklar "claimed" görünmeye
    devam eder** (döngü o an SIFIRLANMAZ, yalnızca `todayIndex` bir sonraki güne geçince — yani
    kullanıcı popup'ı ertesi gün tekrar açtığında — sıfırlanır). Bu, kullanıcının 7. günü aldığı anda
    kutucukların aniden boşalıp kafa karıştırmasını önlüyor; "Bugün zaten aldın, yarın tekrar gel"
    mesajı zaten net bir durum bildiriyor.
- **`reconcileForToday()` üç yerden çağrılıyor** (hepsi ucuz, no-op'sa hiçbir şey değişmiyor):
  provider `_loadFromPrefs()` içinde (uygulama kapalıyken kaçırılmış günleri anında yakalamak için),
  `DailyRewardsTriggerButton`'ın `initState`/`AppLifecycleState.resumed`'inde (`GoalTrackingScreen.
  _reconcileForToday` ile AYNI desen — rozetin doğru durumu popup açılmadan ÖNCE bile yansıtması
  için), ve `DailyRewardsScreen`'in kendi `initState`'inde (uygulama arka plana hiç alınmadan gün
  değiştiyse diye ekstra bir güvenlik).
- **Popup, `WheelScreen`'in `AlertDialog` sonuç popup'ından FARKLI bir UX kararı kullanıyor:**
  coin kazanıldığında ayrı bir SnackBar/kutlama diyaloğu YOK — bunun yerine `context.watch<
  DailyRewardsProvider>()` popup'ın TÜM içeriğini (durum metni + 7 kutucuk) doğrudan izliyor, bir
  gün kutusuna dokunulunca içerik ANINDA güncelleniyor (kutu "claimed" durumuna geçiyor, üstteki
  durum metni "Bugün zaten aldın..." mesajına dönüyor). **Gerekçe:** dialoglar `Navigator`'ın ayrı
  bir overlay dalında render edildiği için `ScaffoldMessenger.of(context)` (SnackBar göstermek için)
  RootScreen'in Scaffold'unu bulamayabilir — bu potansiyel soruna hiç girmeden, popup'ın kendi
  içeriğini güncellemek hem daha basit hem daha güvenilir.
- **Gotcha (aynı "Alt Gezinme Çubuğu" semantics birleşme dersi tekrarlandı):** `_DayRewardBox`'ın
  `Semantics(label: ...)` sarmalayıcısı `excludeSemantics: true` OLMADAN yazılsaydı, içerideki "Gün
  N"/"N ZC" `Text` widget'larının kendi otomatik semantics'i dıştaki `label`la birleşip testte
  `find.bySemanticsLabel(...)`'in tam eşleşmeyi bulamamasına yol açıyordu (`GoalCard`'ın `_DayBox`'ı
  da bu düzeltmeye sahip DEĞİL, ama oradaki testler zaten `find.text('1')` gibi görünen metne göre
  tıklıyor — buradaki testin AYNI yola (`find.text('Gün 1')`) geçmesi + widget'a `excludeSemantics:
  true` eklenmesi, hem testi hem gerçek ekran okuyucu deneyimini düzeltti).
- **Test:** `daily_rewards_provider_test.dart` (`GoalsProvider`'daki enjekte edilebilir saat
  deseniyle: Gün 1 ile başlama, claim akışı, aynı gün ikinci claim reddi, ertesi gün Gün 2'nin
  açılması, gün kaçırılınca sıfırlanma, 7 gün art arda alınıp 8. günde otomatik yeni döngü, Gün 7
  alındıktan sonra AYNI gün içinde tüm kutucukların claimed görünmeye devam etmesi, kalıcılık
  round-trip) + `widget_test.dart`'a iki uçtan uca senaryo (bugünün kutucuğuna dokununca ödül
  alınır + bakiyeye eklenir; tetikleyici yalnızca Ana Sayfa sekmesinde görünür — `WheelTriggerButton`
  testleriyle BİREBİR AYNI kalıp). `_buildAppWithClock()`'a `DailyRewardsProvider` eklenmeyi
  UNUTMAMAK için özellikle dikkat edildi (bkz. "Temalar" bölümündeki `_buildAppWithClock` gotcha'sı —
  bu oturumda daha önce tam olarak bu hatayı yapıp 20 test başarısızlığına yol açmıştı).
  Gerçek cihazda (koyu tema, aktif "Gece Gökyüzü" teması altında) tam akış doğrulandı: tetikleyici
  butonun aktif temanın rengini yansıttığı, popup'ın ortada (tam ekran değil) açıldığı, Gün 1'e
  dokununca bakiyenin +5 arttığı, popup'ı yeniden açınca "Bugün 5 Zibo Coin aldın! Yarın tekrar
  gel." mesajının ve Gün 1'in tik'li/vurgulu göründüğü, X ikonuyla temiz kapandığı gözlemlendi.

### Para ve Birikim ([money_screen.dart](lib/screens/money_screen.dart), [money_provider.dart](lib/providers/money_provider.dart), [money_entry.dart](lib/models/money_entry.dart), [money_category_card.dart](lib/widgets/money_category_card.dart), [money_trend_chart.dart](lib/widgets/money_trend_chart.dart))
- **Yerleşim (2026 güncellemesi) — artık bir alt sekme DEĞİL, Z butonunun açtığı modül menüsünden
  push edilen bir ekran** (bkz. "Alt Gezinme Çubuğu" bölümü — kullanıcı isteğiyle Profil'le yer
  değiştirdi: Profil bottom bar'ın 3. sekmesi oldu, Para ve Birikim modül menüsünün 6. kartına
  taşındı). Bu yüzden artık diğer pushed modüller (Rüya/Şükran/Su Takibi vb.) gibi **kendi
  `Scaffold`/`AppBar`'ı VAR** (`Text(l10n.moneyScreenTitle)` başlıklı) — eskiden `RootScreen`'in
  ortak AppBar'ını paylaşan bir sekme olduğu için bu sarmalayıcı yoktu, `MoneyScreen.build()`'e
  eklendi (bkz. aşağıdaki `isActive` notu — MoneyScreen artık pushed bir rota olduğu için `isActive`
  varsayılanı `true`'ya çevrildi, sekme-geçişi mantığına ihtiyaç kalmadı).
- **`SharedPreferences` ile kalıcı** — kategorilerin tüm kayıtları tek bir `'moneyEntries'`
  anahtarı altında JSON (bkz. `GoalsProvider`/`CoinProvider`'daki aynı "başlangıçta eksikti,
  kullanıcı raporuyla eklendi" notu — üçü de aynı kullanıcı geri bildirimiyle aynı anda düzeltildi).
- Zibo başlığı altında 5 saniyede bir otomatik değişen bir söz (`lib/data/money_quotes.dart`,
  50 sözlük havuz, art arda tekrar yok). **Söz, kullanıcının Profil'den seçtiği hitap tercihine göre
  de değişebilir** — bkz. "Profil" bölümündeki "Hitap Tercihi" alt bölümü, `applyAddressTerm()` bu
  ekranda da (diğer 7 söz-gösteren ekranla birlikte) çağrılıyor.
- Zibo görseli + `SpeechBubble` başlığı, "Hedef Takibi" bölümünde belgeli aynı `Column`
  (`crossAxisAlignment.center`, `Align(topLeft)` DEĞİL) desenini kullanıyor — kuyruk balonun kendi
  ortasında olduğu için Zibo'nun da aynı yatay merkezde olması gerekiyor. Aynı bölümde giyili kostüme
  göre Zibo görselinin değişmesi de belgeli.
- **`isActive` parametresi artık opsiyonel, varsayılanı `true`:** MoneyScreen bir sekmeyken
  (`IndexedStack` içinde HEP monte, bkz. eski davranış) zamanlayıcının yalnızca gerçekten görünürken
  çalışması için `isActive: _selectedIndex == 2` + `didUpdateWidget` start/stop deseni gerekiyordu.
  Artık pushed bir rota olduğu için (ya TAM monte ya HİÇ monte değil) buna gerek kalmadı — widget
  `dispose()` edildiğinde `Timer` zaten iptal ediliyor, `isActive` parametresi yalnızca geriye dönük
  uyumluluk için opsiyonel bırakıldı.
- Kayıt ekleme dialogu virgül veya nokta ondalık ayracını kabul ediyor
  (`amountController.text.replaceAll(',', '.')`).
- **2026 güncellemesi — "Harcamalar ve Birikimler"e yeniden düzenleme + trend grafiği:** Kullanıcı
  isteği: "Harcamalar ve Ödemeler aynı şeyi ifade ediyor, birleştir; ayrı bir Gelen Para kategorisi
  ekle; en altta harcama/birikim trendini gösteren küçük bir çizgi grafik olsun (fl_chart)."
  - **Kategoriler artık `MoneyCategory { expense, saving, income }`** — eski `payment` (Ödemeler)
    TAMAMEN kaldırıldı, `Harcamalar` ile birleştirildi. `MoneyProvider._loadFromPrefs`, eski kayıtlı
    verideki ayrı `'payment'` listesini okuyup `expense` listesine EKLİYOR (kullanıcının geçmiş
    ödeme kayıtları kaybolmuyor) — bu geri uyumluluk göçü kalıcı, sürüm kontrolü yok.
  - **`MoneyEntry`'ye `date` alanı eklendi** (`addEntry` çağrıldığı anki `_now()`) — trend
    grafiğinin zaman eksenini oluşturmak için gerekli, önceden hiçbir kayıt tarih taşımıyordu. Eski
    (tarihsiz) kayıtlar göç anında `_now()` ile dolduruluyor (gerçek eklenme tarihleri
    kaydedilmediği için bilinemez, en makul varsayılan).
  - **`MoneyCategoryCard`** artık `accentColor`/`amountSign` parametreleri alıyor — Harcamalar
    kırmızı/`-`, Birikimler yeşil/`+`, Gelen Para mavi/`+` (kullanıcı isteği: "Harcamalar kırmızı
    '-', Birikimler yeşil '+'"; Gelen Para için renk/işaret açıkça istenmedi, tutarlılık için
    aynı +/renk deseni uygulandı, yalnızca ayırt edici bir renk seçildi).
  - **Ekranın kendi başlığı artık `moneyScreenTitle` ("Harcamalar ve Birikimler") — `tabMoney`
    ("Para ve Birikim") DEĞİL.** Bilerek İKİ AYRI ARB anahtarı: `tabMoney` hâlâ
    `MainBottomBar`'daki sekme erişilebilirlik etiketi (testler `find.bySemanticsLabel('Para ve
    Birikim')` ile sekmeye dokunuyor, bunu bozmamak için DOKUNULMADI), `moneyScreenTitle` yalnızca
    ekranın kendi içindeki büyük başlık metni. Kullanıcı yalnızca modülün GÖRÜNEN adının
    değişmesini istedi, alt gezinme çubuğunun erişilebilirlik/otomasyon davranışının değişmesini
    değil.
  - **Yeni `MoneyTrendChart` widget'ı** (`fl_chart`'ın `LineChart`'ı) — Harcamalar VE Birikimler
    kayıtlarını (Gelen Para HARİÇ — kullanıcı isteği yalnızca bu ikisinin trendini istiyordu) güne
    göre gruplayıp KÜMÜLATİF (biriken) toplam olarak çiziyor; iki kategori de aynı gün eksenini
    (iki listenin birleşimi) paylaşıyor ki çizgiler karşılaştırılabilir kalsın.
    - **Gotcha — tek günlük veriyle grafik TAMAMEN BOŞ görünüyordu:** İlk yazımda seri doğrudan
      günlük kümülatif değerlerle başlıyordu — kullanıcı bugün İLK kaydını girdiğinde (en yaygın
      senaryo: yeni kullanıcı) yalnızca TEK bir nokta oluşuyordu, ve `fl_chart` tek noktadan çizgi
      ÇİZEMEZ (`dotData: show: false` olduğu için nokta işareti de görünmüyordu) — sonuç: kayıt
      eklensin eklenmesin grafik alanı boş kalıyordu, web preview'da ekran görüntüsüyle
      doğrulanarak yakalandı. **Çözüm:** her iki seri de sıfırdan (`[0]`) başlıyor, gerçek gün
      verileri bu taban noktanın ÜZERİNE ekleniyor — böylece tek günlük veri bile (0 → bugünkü
      toplam) görünür bir çizgi çiziyor, ayrıca "sıfırdan başlayan büyüme" çerçevesi kullanıcı
      için daha anlamlı.
    - Boş durumda (`expenses` VE `savings` ikisi de boş) grafik yerine `moneyTrendEmpty` metni
      gösteriliyor.
  - **Test:** `money_provider_test.dart` yeniden yazıldı (üç kategori, `date` alanı, eski `payment`
    göçü) + `widget_test.dart`'taki Para ve Birikim senaryoları yeni emoji/renk/işaretlere göre
    güncellendi (`-₺150.50` gibi işaretli tutar metni dahil). Web preview'da (`flutter run -d
    web-server`) hem boş hem dolu (harcama+birikim girilmiş) durumda grafik görsel olarak
    doğrulandı — yukarıdaki tek-günlük-veri bug'ı bu doğrulama sırasında bulunup düzeltildi.
  - **2026 ikinci güncelleme — Gelen Para grafiğe eklendi + interaktif + günlük/haftalık:**
    Kullanıcı gerçek cihazda test edip şunu bildirdi: "gelen para grafikte yok, grafiği biraz
    daha interaktif hale getir... grafiğin sağ üstünde bir seçenek olsun günlük haftalık olarak
    göstersin."
    - `MoneyTrendChart` artık `expenses`/`savings`'e ek olarak `incomes`'ı da alıp ÜÇÜNCÜ bir
      çizgi (mavi, kart rengiyle aynı `0xFF1E88E5`) olarak çiziyor — ilk sürümde bilerek dışarıda
      bırakılmıştı ("kullanıcı yalnızca harcama/birikim trendini istiyor" varsayımıyla), kullanıcı
      geri bildirimiyle bu varsayım yanlış çıktı.
    - Widget artık `StatefulWidget` — sağ üstte bir `SegmentedButton<_Granularity>` (Günlük/
      Haftalık) periyodu değiştiriyor. Haftalık modda `_bucketStart` tarihi o haftanın Pazartesi'sine
      indirgiyor (ISO haftası, istikrarlı gruplama anahtarı) — aynı zaman aralığı daha AZ noktaya
      sıkışıyor, bu da kullanıcının istediği "gün geçtikçe grafiğin daralıp genişlemesi" davranışını
      otomatik veriyor (X ekseni her zaman `buckets.length`'e göre ölçekleniyor, ayrı bir kod
      gerekmedi).
    - **Interaktiflik:** `titlesData` artık `show: true` — sol eksende `₺`/`k` kısaltmalı tutar
      etiketleri, alt eksende kısa tarih etiketleri (`5 Oca` gibi, `_shortMonths` — diğer
      ekranlardaki hardcoded Türkçe ay adı deseniyle AYNI, bkz. Yerelleştirme bölümündeki "içerik
      havuzu vs UI chrome" ayrımı). `lineTouchData: enabled: true` ile dokunulan noktanın tam
      değerini gösteren bir tooltip eklendi. Hafif yatay `gridData` çizgileri okunabilirliği
      artırıyor.
    - **Test:** Mevcut test suite'i (122 test) bu değişikliklerle birlikte hâlâ geçiyor — grafik
      widget'ı için ayrı bir widget testi YOK (fl_chart'ın kendi `CustomPainter` çizimini test
      etmek yerine, `money_provider_test.dart` + `widget_test.dart`'taki kategori/tutar senaryoları
      besleme verisinin doğruluğunu zaten kapsıyor).
  - **2026 ÜÇÜNCÜ güncelleme — her kayıt KENDİ para birimini taşıyabilir (tek bir global ayara
    bağımlı kalmadan).** Kullanıcı isteği (verbatim özet): "aynı listede hem TL hem Dolar hem Euro
    gibi farklı para birimleriyle girişler ekleyebilmeli, her kayıt kendi para birimini korusun,
    birbirine otomatik çevrilmesin." Eskiden `CurrencyProvider.currencyCode` TEK global bir ayardı
    ve TÜM kayıtlar/görüntülemeler onu paylaşıyordu — artık yalnızca YENİ kayıt eklerken bir
    BAŞLANGIÇ varsayılanı olarak kullanılıyor, GÖRÜNTÜLEME artık her kaydın KENDİ
    `currencyCode`'undan geliyor.
    - **`MoneyEntry.currencyCode`** (YENİ, `required`, ISO 4217) — kaydın eklendiği ANDAKİ para
      birimi, `GoalCompletion`/favori sözlerdeki AYNI "anlık görüntü" felsefesiyle sonradan global
      ayar değişse bile GERİYE DÖNÜK değişmiyor. `MoneyProvider._entryFromJson`'daki eski
      (`currencyCode`'suz) kayıtlar 'TRY'ye düşüyor (kullanıcının kendi önerdiği varsayılan) — ayrı
      bir migrasyon betiği/Cloud Function GEREKMEDİ, bu satır `CloudStateStore.load()`'un
      döndürdüğü HER kayıt için (yerelden VEYA Firestore'dan fark etmeksizin) çalışıp bir SONRAKİ
      `_save()`'de kalıcı hale geliyor — `date` alanının eklenmesindeki AYNI "oku-zamanı-göç-et"
      deseni. `addEntry`/`updateEntry` artık `required String currencyCode` alıyor (mevcut
      `required String name`/`amount` ile AYNI stilde — gizli bir varsayılana DÜŞÜLMÜYOR, çağıran
      HER ZAMAN açık bir seçim geçirmeli).
    - **`MoneyProvider.totalFor(category)` DOKUNULMADI** (ham/para-birimi-kör toplam, testleri hâlâ
      geçerli) — YENİ `Map<String, double> totalsByCurrencyFor(category)` eklendi (para birimi
      koduna göre gruplanmış toplamlar), UI artık BUNU kullanıyor.
    - **`MoneyCategoryCard._showEntryDialog`'a bir `DropdownButtonFormField<String>` eklendi**
      (`currencies` listesinden, her öğe `'${code} ${symbol}'` — dil-bağımsız, ARB gerekmiyor).
      Varsayılan: yeni kayıt için `defaultCurrencyCode` (kartın YENİ parametresi, eskiden
      `currencySymbol` idi — artık GÖRÜNTÜLEME için değil, yalnızca bu varsayılan için), düzenlemede
      `existing.currencyCode`. Dialog `StatefulBuilder`'a sarıldı (yalnızca TEK bir dropdown
      state'i olduğu için Şükran Günlüğü'nün "3 controller'lı, editable" `_GratitudeEditDialog
      Content`'i kadar ayrı bir StatefulWidget'a GEREK duyulmadı). Yeni `moneyEntryCurrencyLabel`
      ARB anahtarı (TR/EN/ES) alanın etiketi için eklendi.
    - **Liste satırları** artık `currencyByCode(entry.currencyCode).symbol` kullanıyor (kartın
      paylaşılan sembolü DEĞİL). **Kategori toplamı** `totalsByCurrencyFor`'u para birimi koduna
      göre ALFABETİK sıralayıp `'${symbol}${tutar}'` parçalarını `' + '` ile birleştirip mevcut
      `l10n.moneyCategoryTotal({amount})` anahtarına (TEK `{amount}` placeholder'ı, ARB'de zaten
      vardı) geçiriyor (ör. "Toplam: €3.00 + $5.00") — **otomatik kur çevirisi YOK**, kullanıcının
      açık isteği.
    - **`MoneyTrendChart` — "en basit çözüm": otomatik çevirme yok, tek seferde TEK para birimi
      çiziliyor.** Widget artık KENDİ `_selectedCurrency` state'ini taşıyor (granularity'yi zaten
      kendi yönettiği gibi); `expenses`/`savings`/`incomes` HÂLÂ TAM (filtrelenmemiş) listeler
      olarak geçiriliyor, filtreleme `build()` içinde yapılıyor — bu sayede widget kayıtlardaki
      BENZERSİZ para birimi kümesini kendi hesaplayıp seçiciyi (`_CurrencySelector`, YENİ, kompakt
      bir `DropdownButton`) doldurabiliyor. Seçici `SegmentedButton`ın SOLUNA (`Align(centerRight)`
      bir `Row(spaceBetween)`e çevrildi) eklendi — **yalnızca BİRDEN FAZLA para birimi varsa**
      gösteriliyor, tek para birimli (yaygın) durumda hiçbir ekstra UI eklenmiyor.
      - **Gerçek bug, testte yakalandı — `_selectedCurrency` (widget'ın İLK build'inde ayarlanan
        başlangıç değeri) kayıtlar EKLENMEDEN ÖNCE seçilmiş olabilir ve dropdown'ın `items`
        listesinde (yalnızca GERÇEKTEN var olan para birimi kodlarından oluşan) HİÇ
        BULUNMAYABİLİR** — bu, "there should be exactly one item with [DropdownButton]'s value"
        assertion hatasına yol açtı (widget testinde canlı yakalandı, iki farklı para biriminde
        art arda kayıt eklenen bir senaryoda). **Düzeltme:** `effectiveCurrency` adında TÜRETİLMİŞ
        bir değer — `_selectedCurrency` hâlâ `availableCurrencies` içinde GEÇERLİYSE onu korur,
        değilse mevcut ilk para birimine düşer; KALICI state (`_selectedCurrency`) yalnızca
        kullanıcı GERÇEKTEN seçim yapınca değişir. **Ders:** bir dropdown'ın `value`'sunu widget
        ömrü boyunca DEĞİŞEBİLEN bir `items` listesine karşı doğrulamadan doğrudan state'ten
        besleyen HER yerde bu risk var — `value`'nun HER ZAMAN `items`'ın bir üyesi olduğunu build
        anında garanti eden türetilmiş bir değer kullanın, ham state'i DOĞRUDAN vermeyin.
    - **`HomeWidgetSyncCoordinator._syncMoney()`** — "bu ayki net tutar" hesaplaması artık YALNIZCA
      `entry.currencyCode == currency.currencyCode` (o an SEÇİLİ global para birimi) olan kayıtları
      topluyor — widget'ın kompakt tek-satırlık özeti hâlâ TEK bir sayı olmak ZORUNDA (RemoteViews'ın
      basit metin alanı), bu yüzden diğer para birimlerindeki kayıtlar bu ÖZEL metrikte sessizce
      dışarıda bırakılıyor — kartlardaki/grafikteki asıl çoklu-para-birimi deneyimini ETKİLEMİYOR.
    - **Test:** `money_provider_test.dart`'taki TÜM `addEntry`/`updateEntry` çağrılarına
      `currencyCode: 'TRY'` eklendi (mevcut 10 test aynı davranışı doğrulamaya devam ediyor) + YENİ
      bir grup (4 test — `totalsByCurrencyFor` gruplama, boş kategori, `updateEntry` para birimi
      değiştirme, eski/para-birimsiz kayıt TRY'ye göç). `widget_test.dart`'taki 3. Para ve Birikim
      senaryosuna (USD'ye geçilip kayıt eklenen) AYNI kategoriye EUR'da İKİNCİ bir kayıt ekleyip her
      iki sembolün ayrı ayrı VE toplamın birleşik (`'€3.00 + $5.00'`) göründüğünü doğrulayan bir
      adım eklendi. `profile_stats_test.dart`/`home_widget_sync_coordinator_test.dart`'taki mevcut
      `MoneyProvider.addEntry` çağrılarına da `currencyCode: 'TRY'` eklendi (yeni required parametre
      yüzünden derleme kırılmasın diye). `flutter test` tam yeşil: **355/355.**
    - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca `flutter test`'teki
      kapsamlı senaryolarla doğrulandı. Kullanıcının kendi cihazında kontrol etmesi gereken: yeni
      kayıt eklerken para birimi seçicisinin doğru göründüğü, farklı para birimindeki kayıtların
      listede kendi sembolleriyle ayrı ayrı göründüğü, kategori toplamının birleşik metni doğru
      biçimlendirdiği, ve "Mevcut Durum" grafiğindeki yeni para birimi seçicisinin (birden fazla
      para birimi kullanılınca) doğru çalıştığı.

