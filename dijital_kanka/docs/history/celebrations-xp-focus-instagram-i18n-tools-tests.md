# ARŞİV — Hedef Tamamlama Kutlaması, Level/XP, Odak Sayacı, Instagram, i18n, Görsel işleme, Test kalıpları, Mock durumu

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 4665–5311).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

## Hedef Tamamlama Kutlaması — titreşim + konfeti + ses ([goal_tracking_screen.dart](lib/screens/goal_tracking_screen.dart), [goal_card.dart](lib/widgets/goal_card.dart), [goal_confetti_burst.dart](lib/widgets/goal_confetti_burst.dart))

- **2026 yeni özellik.** Kullanıcı isteği (verbatim özet, ilk sürüm): kullanıcı Hedef Takibi'nde bir
  günün kutucuğuna dokunduğunda ÖNCE ekranın kısa bir titreşim (shake) efekti yapması, 2 saniye
  SONRA ekranda konfeti patlaması başlaması ve bu konfeti anıyla TAM EŞ ZAMANLI `zibo_target.wav`'ın
  çalması.
- **`GoalCard.onMarkedToday` (opsiyonel `VoidCallback?`)** — `_onTodayTap`, `toggleToday()`
  çağrılmadan ÖNCE `goal.completedDates.contains(today)`'i kontrol edip bu dokunuşun bir "YENİ
  işaretleme" mi (`onMarkedToday?.call()`) yoksa "işaret KALDIRMA" mı olduğunu ayırt ediyor.
  **Neden gerekli:** `GoalsProvider.toggleToday()`'in dönüş değeri (`cycleCompleted`) YALNIZCA 7/7
  tamamlanma anını ayırt ediyor, işaretleme/kaldırma YÖNÜNÜ değil (hem mark hem unmark `false`
  dönebiliyor) — bu yüzden yön, `toggleToday()` çağrılmadan ÖNCEki durumdan ayrıca hesaplanıyor.
  **Not:** Mevcut UI'da bir kez işaretlenmiş bir kutucuk `GoalDayStatus.done`'a geçtiği için ARTIK
  TIKLANAMIYOR (`_DayBox.isTappable = status == GoalDayStatus.today`) — yani gerçek arayüzden
  "unmark" senaryosuna ERİŞİLEMİYOR, bu kontrol yalnızca `toggleToday()`'in kendi API'sinin (ileride
  başka bir yerden çağrılırsa) doğru davranmasını garanti eden savunmacı bir kod.
- **2026 GÜNCELLEMESİ — zamanlama YENİDEN TASARLANDI: ses artık dokunma ANINDA, konfeti şekli
  "patlama" oldu.** Kullanıcının netleştirdiği kesin zamanlama: **0sn** dokunma ANINDA titreşim
  (shake) VE `zibo_target.wav` AYNI ANDA başlar; **titreşim TAM 2 saniye** sürer; ses dosyası
  kendi başına **toplam 4 saniye** (3. saniyede "Zibo!" kelimesi geçiyor — bu içeriğe
  DOKUNULMADI, yalnızca başlangıç anı senkronize edildi); **2sn'de** (titreşim bitince) konfeti
  patlaması başlar; konfeti (2sn sürüyor) ile ses (4sn sürüyor) KASITLI OLARAK AYRI zamanlanmış —
  ikisinin çakışması (2-4sn arası hem ses hem konfeti aynı anda) sorun değil (kullanıcının kendi
  ifadesi). Bu, İLK sürümdeki "titreşim(400ms)+2sn bekle+konfeti VE ses AYNI ANDA" tasarımından
  farklı — ses artık konfetiyle değil, titreşimin BAŞLANGICIYLA senkron.
  - **Titreşim (shake) — 400ms'ten TAM 2 saniyeye çıkarıldı, mekanizma da değişti.** Eski tasarım
    sabit bir 5-adımlı `TweenSequence`'i (400ms) kullanıyordu — bunu doğrudan 2 saniyeye UZATMAK
    (`duration` değiştirip aynı 5 adımı olduğu gibi bırakmak) tek, yavaş/tembel bir sallanma gibi
    hissettirirdi, gerçek bir "titreşim" değil. Bunun yerine `_shakeController` (artık 2000ms) ile
    `AnimatedBuilder`'ın `builder`'ında DOĞRUDAN `controller.value`'dan hesaplanan bir `_shakeOffset`
    getter'ı kullanılıyor: `sin(t · 2π · 10) · 9.0 · decay` — 2 saniye boyunca ~5Hz'lik (10 tam
    salınım) gerçek bir titreşim hissi sürüyor, yalnızca SON %15'lik dilimde (son 300ms) `decay`
    genliği yumuşakça sıfıra indiriyor (ani bir "kesilme" yerine akıcı bir bitiş — tam da konfetinin
    başladığı ana denk geliyor). `HapticFeedback.mediumImpact()` (cihaz titreşimi) DEĞİŞMEDİ, hâlâ
    dokunma anında bir kez tetikleniyor.
  - **Konfeti — artık AMBİANS "yağmur" DEĞİL, GERÇEK bir "patlama" görseli.** Kullanıcı isteği:
    "konfetiler yukarıdan aşağıya doğru patlayan bir hareketle gelsin (üstten başlayıp ekrana
    yağıyormuş gibi), rastgele yönlere infilak etsin." Eski sürüm Mağaza > Temalar'ın
    `ThemeParticleEffect(type: confetti)` çizim kodunu (sürekli tekrarlanan, yukarıdan aşağı
    SARILAN bir "yağmur" — `y = (startY + t·speed) % 1.0`) yeniden kullanıyordu — bu görsel bir
    "patlama" hissi vermiyordu, her zaman aynı yoğunlukta düzgün bir yağmurdu. **Yeni
    [goal_confetti_burst.dart](lib/widgets/goal_confetti_burst.dart) (YENİ dosya,
    `GoalConfettiBurst` widget'ı) kendi ayrı, tek seferlik bir fizik modeli** kullanıyor: her
    parçacığın ekranın üst kenarına yakın (birkaç ayrı "kaynak" noktasından, TEK bir merkez değil)
    bir başlangıç konumu + üst yarım daire (0..π) içinde RASTGELE bir açıyla seçilen bir patlama
    hız vektörü (`vx`/`vy`, `vy` çoğunlukla yukarı/negatif — gerçek bir patlama gibi) var;
    `y(t) = originY + vy·t + 0.5·g·t²` (sabit yerçekimi `g=2.4`) ile parçacık zamanla yukarı
    fırlayıp SONRA aşağı düşmeye başlıyor — "üstten patlayıp ekrana yağma" hissi TAM olarak bu
    yerçekimi eğrisinden geliyor. Parçacıklar TAM aynı anda değil, ilk %15'lik dilimde kısa bir
    "dalga" halinde art arda ateşleniyor (`_BurstPiece.delay`) — gerçek bir patlamanın anlık ama
    biraz dağınık başlangıcını taklit ediyor. Ekranın alt kısmında (`y > 0.85`) yumuşak bir solma
    var, sert bir "kesilme" yok.
    - **Parçacık sayısı belirgin şekilde artırıldı: 60 → 150** (varsayılan `particleCount`) —
      kullanıcı isteği "daha yoğun/kalabalık bir kutlama hissi versin."
    - **Konfeti süresi (2000ms) DEĞİŞMEDİ** — yalnızca ŞEKLİ (ambians yağmur → tek seferlik
      patlama) ve parçacık sayısı değişti, `_confettiController`'ın kendisi/BİR KEZ
      `forward(from: 0)` + `AnimationStatus.completed` olunca `setState(() => _showConfetti =
      false)` ile kaldırılma mantığı AYNI kaldı.
  - **`_triggerCompletionCelebration()` artık İKİ ayrı anı tetikliyor, TEK bir "2sn sonra" bloğu
    DEĞİL:** `_shakeController.forward(from: 0)` + `HapticFeedback.mediumImpact()` + (ses açıksa)
    `_soundEffectsService.playGoalComplete()` ÜÇÜ de FONKSİYONUN BAŞINDA, senkron/ANINDA
    çağrılıyor; `_confettiDelayTimer` (2 saniye, `Timer` olarak — bare `Future.delayed` DEĞİL, bkz.
    altta) yalnızca `_showConfetti = true` + `_confettiController.forward(from: 0)`'ı tetikliyor,
    SES ARTIK BU BLOKTA DEĞİL.
  - **2 saniyelik gecikme — `Timer` olarak tutuluyor, bare `Future.delayed` DEĞİL.** İlk denemede
    `Future.delayed` kullanıldı ve widget test dosyasında "A Timer is still pending even after the
    widget tree was disposed" hatasıyla BAŞARISIZ oldu (gerçekten yaşandı) — `_confettiDelayTimer`
    alanına taşınıp `dispose()`'ta `cancel()` edildi. Bu aynı zamanda üretimde de doğru: kullanıcı
    2 saniye içinde ekrandan ayrılırsa askıda bir zamanlayıcı kalmıyor.
  - **`GoalTrackingScreen({this.soundEffectsService})`** — `HomeScreen` ile AYNI test-injection
    deseni (varsayılan gerçek `AudioPlayersSoundEffectsService()`), DEĞİŞMEDİ.
- **Test:** `test/goal_completion_celebration_test.dart` bu güncellemeyle YENİDEN yazıldı —
  `playGoalComplete()`'in dokunma ANINDA (bir `pump()` sonrası, gecikme OLMADAN) çağrıldığını,
  `GoalConfettiBurst` widget'ının 2 saniyeden ÖNCE ağaçta OLMADIĞINI, TAM 2 saniye dolunca
  belirdiğini, ve konfeti animasyonu (2000ms) tamamlanınca ağaçtan kaldırıldığını doğruluyor
  (`find.byType(GoalConfettiBurst)` — eski testin `sound.goalCompleteCallCount` yalnızca konfeti
  anında kontrolünün YERİNE geçti, çünkü ses artık konfetiyle değil dokunmayla senkron).
- **Gerçek cihazda doğrulama — kullanıcının GERÇEK "Yeme düzeni" hedefi (2/7 gün) bozulmadı.**
  Doğrulama için AYRI, geçici bir "GECICI_TEST_SIL" hedefi eklendi; cihaz eşzamanlı olarak kullanıcının
  kendisi tarafından da kullanılıyordu (bkz. CLAUDE.md genelindeki "gerçek cihaz paylaşım riski"
  notu) — koordinat tahminleri birkaç kez ıskaladı (bir tıklama yanlışlıkla bildirim panelini açtı,
  bir diğeri "Yeni Hedef" diyaloğunu tekrar açtı) ve bu YANLIŞLIKLA Ana Sayfa'da 5+ hızlı Zibo
  dokunuşuna denk gelip **Feature 5'i (art arda dokunma reklamı) organik olarak tetikledi** — gerçek
  bir AdMob test interstitial reklamı cihazda GÖRÜNTÜLENEREK doğrulandı (bkz. altta). Risk fark
  edilince (kullanıcının gerçek telefonu, kişisel duvar kağıdı/uygulamaları görüldü) TÜM etkileşimli
  dokunma otomasyonu HEMEN durduruldu; konfeti/titreşim/ses efektinin kendisi görsel olarak cihazda
  TEYİT EDİLEMEDİ (yalnızca otomatik testle kanıtlanmış durumda). **Kullanıcının kendisinin
  silmesi gereken bir kalıntı var: Hedef Takibi'nde "GECICI_TEST_SIL" adlı geçici test hedefi —
  kartın sağ üstündeki çöp kutusu ikonuyla tek dokunuşla silinebilir.**
- **Yukarıdaki zamanlama/konfeti-şekli güncellemesi bu turda GERÇEK CİHAZDA GÖRSEL olarak
  doğrulanmadı** — yalnızca `flutter test` (256/256, yeniden yazılan `goal_completion_celebration_
  test.dart` dahil) + başarılı `flutter build apk --debug` ile doğrulandı. Kullanıcının kendi
  cihazında kontrol etmesi gereken: sesin dokunma ANINDA (titreşimle aynı anda) başladığı, titreşimin
  tam 2 saniye sürüp konfetinin TAM o an başladığı, ve konfetinin artık düzgün bir "yağmur" değil
  gerçek bir "patlama" (üstten fışkırıp aşağı düşen, kalabalık) gibi göründüğü.

## Level/XP Sistemi ([xp_level.dart](lib/models/xp_level.dart), [xp_provider.dart](lib/providers/xp_provider.dart), [level_up_signal.dart](lib/utils/level_up_signal.dart), [level_celebration_overlay.dart](lib/widgets/level_celebration_overlay.dart))

- **2026 yeni özellik.** Kullanıcı isteği: uygulamanın yaptığı HER anlamlı aksiyon genel bir
  seviye/XP puanı kazandırsın, belirli eşiklerde seviye atlansın, seviye atladığında kutlama
  animasyonu + otomatik paylaşılabilir bir kart gösterilsin, Profil'de mevcut seviye + ilerleme
  çubuğu görünsün.
- **İlerleme eğrisi — [xp_level.dart](lib/models/xp_level.dart), saf/test edilebilir matematik.**
  Level L'den L+1'e geçmek için gereken XP = `50*L` (doğrusal ARTAN maliyet — 1→2: 50, 2→3: 100,
  9→10: 450) — kullanıcının "düşük seviyeler hızlı, yüksek seviyeler daha yavaş kazanılsın"
  isteğini basit/öngörülebilir bir şekilde karşılıyor. `cumulativeXpForLevel(level)` bu doğrusal
  serinin kapalı biçimi (`25*level*(level-1)`); `levelForTotalXp`/`levelProgressForTotalXp` bir
  toplam XP'den seviye + seviye-içi ilerlemeyi (`LevelProgress{level, xpIntoLevel, xpForNextLevel,
  fraction}`) hesaplıyor.
- **`XpProvider`** — diğer basit provider'larla (`ReferralProvider`/`FavoriteQuotesProvider`) AYNI
  `CloudStateStore` Varyant A (`{'totalXp': ...}`) deseni. `addXp(amount)` toplamı artırıp, bir veya
  daha fazla seviye eşiği aşılırsa `pendingLevelUp` sinyaline ULAŞILAN YENİ seviyeyi yazıyor.
- **XP kaynağı — İKİ yol:**
  1. **`CoinProvider._earn()`'ün merkezi kancası (`onXpEarned`, `_isSoundEnabled` ile AYNI enjekte
     edilebilir callback deseni — `CoinProvider` bir widget OLMADIĞI için `context.read<
     XpProvider>()`'ı doğrudan çağıramıyor).** Kazanılan HER ZC kadar XP veriliyor (1:1) —
     `_earn()`'ü çağıran TÜM mekanikler (günlük check-in, Şükran/Su/Manifest günlüğü, 7 günlük
     hedef bonusu, günlük giriş ödülleri, rozet ödülleri, Şans Çarkı, referans, Instagram takip
     ödülü) OTOMATİK olarak XP veriyor — hiçbir çağıran site'ye elle dokunmaya gerek KALMADI.
     **İSTİSNA — `purchaseCoinPackage()`/yetim satın alma teslimi `awardXp: false` geçiyor:**
     gerçek parayla coin SATIN ALMAK bir "başarı" değil, XP verilmesi yanıltıcı olurdu
     (`playRewardSound: false` ile AYNI ayrım felsefesi).
  2. **Coin VERMEYEN üç aksiyon için doğrudan `context.read<XpProvider>().addXp(...)` çağrıları:**
     Ruh Hali Takibi'nin günün İLK check-in'i (+5, bkz. "Günlük Ruh Hali Takibi" bölümü), bir
     paylaşımın başarıyla tamamlanması (+10, bkz. "Zibonu Paylaş" bölümü), bir Odak Sayacı
     seansının kaydedilmesi (odaklanılan dakika kadar, en fazla 60 — bkz. "Odak Sayacı" bölümü).
- **Kutlama — `LevelCelebrationOverlay`, `BadgeCelebrationOverlay` ile BİREBİR AYNI mimari.**
  `MaterialApp.builder` zincirinde `BadgeCelebrationOverlay`'in İÇİNE sarılı (`main.dart`) —
  `home:` içindeki içerik başka bir rota push edilince boyanmadığı için "HER YERDE" görünürlük bu
  seviyede garanti ediliyor. `pendingLevelUp`'ı dinleyip değiştiğinde `GoalConfettiBurst` (Hedef
  Tamamlama'daki AYNI widget, yeniden kullanıldı) + `ModalBarrier(dismissible: false)` + ortalanmış
  bir kutlama kartı (Zibo görseli + "Seviye X'e Ulaştın!" + "Paylaş"/"Kapat") gösteriyor. `late
  final AnimationController` `initState()`'te KOŞULSUZ oluşturuluyor — `BadgeCelebrationOverlay`'
  deki AYNI dokümante edilmiş gotcha (hiç seviye atlanmadan dispose edilirse "Looking up a
  deactivated widget's ancestor is unsafe" hatası).
  - **"Paylaş" butonu DOĞRUDAN `showModalBottomSheet` ÇAĞIRAMIYOR** — bu overlay seviyesinin
    `context`'i Navigator'ın ATASI DEĞİL (`BadgeCelebrationOverlay`'deki AYNI kısıtlama, bkz. o
    widget'ın dokümantasyonu). `rootNavigatorKey` hack'i YERİNE (daha basit, `dailyRewardsPopupRequest`
    ile AYNI "iste, Navigator'ın İÇİNDEKİ bir widget karşılasın" deseni tercih edildi) YENİ bir
    sinyal — `pendingLevelShareMessage` (`ValueNotifier<String?>`) — ayarlanıyor;
    `RootScreen._onLevelShareRequested()` bunu dinleyip KENDİ (Navigator'ın altındaki) context'iyle
    mevcut `ZiboShareSheet`i açıyor. Yeni bir paylaşım kartı tasarımı YAZILMADI — kullanıcının
    "mevcut paylaşım kartı sistemine benzer tasarımda" isteği `ZiboShareSheet`in DOĞRUDAN yeniden
    kullanılmasıyla karşılandı (Profil Kartı Paylaşımı'ndaki AYNI "yeni widget yazma, mevcut genel
    `message: String` parametresini doldur" yaklaşımı).
- **Profil ekranına ilerleme çubuğu** — isim alanının HEMEN ALTINA (İstatistiklerim'den ÖNCE) YENİ
  `_LevelProgressCard` (`profile_screen.dart` içinde private): "Seviyen" başlığı + `Lv. N` rozeti +
  `LinearProgressIndicator` + "{xpIntoLevel}/{xpForNextLevel} XP" metni.
- **`main.dart`'a kablolama — `XpProvider`, `SoundEffectsProvider` ile AYNI gerekçeyle
  `CoinProvider`'DAN ÖNCE olmalı** (`CoinProvider`'ın `create` callback'i `context.read<
  XpProvider>()` kullanıyor).
- **Test:** YENİ `test/xp_level_test.dart` (8 test — saf matematik fonksiyonları), YENİ
  `test/xp_provider_test.dart` (7 test — toplam XP birikimi, seviye eşiği aşımı + `pendingLevelUp`
  sinyali, eşik ALTINDA sinyal DEĞİŞMEZ, negatif/sıfır no-op, çoklu-eşik tek seferde aşılabilir,
  kalıcılık) + `coin_provider_test.dart`'a yeni bir grup (3 test — `onXpEarned` kancasının HER
  kazanma mekaniğinde tetiklendiği, satın almanın XP VERMEDİĞİ, callback verilmezse çökmediği) +
  `zibo_share_sheet.dart`/`mood_tracking_screen.dart` değişikliklerini kapsayan mevcut testler.
  **Gerçek bir test-pollution bug'ı bulunup düzeltildi:** `widget_test.dart`'taki birkaç test,
  yalnızca hızlıca test bakiyesi biriktirmek için `CoinProvider.earnReferral()`'ı 3-11 kez art arda
  çağırıyordu — bu artık YENİ XP kancası yüzünden gerçek bir seviye atlamayı tetikleyip
  `LevelCelebrationOverlay`'in TAM EKRAN, `dismissible: false` popup'ını gösteriyor, bu da
  SONRAKİ `tester.tap(...)` çağrılarının yanlış hedefe isabet etmesine yol açıyordu. **Düzeltme —
  yalnızca `pendingLevelUp.value = null` YETERLİ DEĞİLDİ** (overlay'in KENDİ `_level` state'i
  sinyal DEĞİŞTİĞİ anda zaten senkron olarak ayarlanmış oluyordu) — YENİ `_dismissLevelUpIfShown
  (tester)` yardımcı fonksiyonu, gösterilmişse popup'ı GERÇEKTEN `levelUpCloseButton` (yeni eklenen
  `Key`) ile kapatıp testin normal akışına devam etmesini sağlıyor; `setUp()`'a da (`isHomeTabActive`
  ile AYNI "paylaşılan global sinyali testler arası izole et" gerekçesiyle) `pendingLevelUp.value =
  null`/`pendingLevelShareMessage.value = null` sıfırlaması eklendi. **Toplam: 588 test** (587
  geçti + 1 önceden belgelenmiş `audioplayers` flake'i).
- **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca `flutter test` ile doğrulandı.
  **Kullanıcının kendi cihazında doğrulaması gereken:** herhangi bir aksiyonla (ör. Şükran
  Günlüğü'nü tamamlamak) bir seviye eşiği aşılınca konfeti + kutlama kartının UYGULAMANIN HER
  YERİNDE göründüğü, "Paylaş"a basınca native paylaşım sayfasının açıldığı, Profil'deki ilerleme
  çubuğunun doğru seviye/XP'yi yansıttığı.

## Odak Sayacı (Kronometre/Pomodoro) Modülü ([focus_session.dart](lib/models/focus_session.dart), [focus_provider.dart](lib/providers/focus_provider.dart), [focus_timer_screen.dart](lib/screens/focus_timer_screen.dart))

- **2026 yeni özellik.** Kullanıcı isteği: bir süre belirleyip (veya serbest kronometre olarak)
  odaklanma/çalışma sürelerini takip edebileceği basit bir zamanlayıcı modülü; Profil'deki
  İstatistiklerim'e toplam odak süresini gösteren yeni bir satır.
- **`FocusProvider`** — `DreamJournalProvider`/`ManifestProvider` ile AYNI "id ile ayrı ayrı
  biriken kayıt" `CloudStateStore` deseni (`{nextId, sessions: [...]}`). `addSession(seconds)` her
  tamamlanan/durdurulan oturumu BİRİKTİRİR (üzerine yazmaz); `durationSeconds < 60` ise (kaza
  eseri anlık başlat/durdur) sessizce reddedilip `false` döner — `WaterProvider`'daki "bariz-
  anlamsız girdiyi reddet" deseni. `totalFocusSeconds` tüm oturumların toplamı.
- **`FocusTimerScreen`** — dört mod (`Serbest`/`15 dk`/`25 dk`/`45 dk`, `ChoiceChip` seçici) + bir
  "Başlat" butonu (kurulum/setup ekranı, normal tema renkleriyle). Belirli süreli modda hedefe
  ulaşınca OTOMATİK kaydediliyor (`_finish()`); Serbest modda kullanıcı "Bitir"e basmalı.
  Kaydedilince kazanılan dakika kadar XP veriliyor (`(duration/60).floor().clamp(1, 60)` — tek bir
  oturumun aşırı büyük bir seviye atlamasına yol açmaması için üst sınır) + bir SnackBar.
  - **2026 GÜNCELLEMESİ — çalışırken ekran TAMAMEN KARANLIK/immersive, kullanıcının açık
    isteğiyle.** "Başladığında ekran kapkaranlık olsun, sadece sayaç gözüksün, dikkat dağıtıcı
    hiçbir şey olmasın" — `build()` artık `_isRunning`'e göre TAMAMEN FARKLI iki görünüme
    dallanıyor: `_buildSetupView` (yukarıdaki, mod seçici + "Başlat") ve `_buildImmersiveView`
    (`Scaffold(backgroundColor: Colors.black)`, AppBar YOK, mod seçici/toplam süre kartı gibi
    HİÇBİR ŞEY görünmüyor — yalnızca ortada parlayan bir halka içinde büyük bir `MM:SS` sayaç,
    altında soluk (`Opacity(0.4)`) bir "Bitir ve Kaydet" metni, dokununca `_finish()`'i çağırıyor).
    **"Duraklat" BİLEREK TAMAMEN KALDIRILDI** — oturum ya çalışıyor ya bitmiş, ara (duraklatılmış)
    durum yok; kullanıcının minimalist isteğiyle tutarlı bir basitleştirme. `SystemUiOverlayStyle.
    light` ile durum çubuğu ikonları da (saat/pil vb.) açık renge dönüp siyah zeminle bütünleşiyor
    — sistem çubuklarını TAMAMEN gizleyen bir "immersive mode" BİLEREK kullanılmadı (çıkış akışını
    karmaşıklaştırma riski, düşük fayda).
    - **`_GlowRing`** (YENİ, private) — dairesel ilerleme göstergesinin ETRAFINA, kullanıcının
      "yuvarlak sayacın içinde dolan renkli şey biraz parlama efekti" isteğiyle, rengin kendisiyle
      bulanık bir `BoxShadow` halesi ekliyor (gerçek bir shader/blur efekti YERİNE — bu ölçekte
      gereksiz maliyetli — ucuz ve yeterince inandırıcı bir teknik). Renk (`_immersiveAccentColor`,
      sabit bir Zibo altın tonu `0xFFE8B44A`) aktif temadan BİLEREK BAĞIMSIZ — zemin HER ZAMAN düz
      siyah olduğu için rengin temaya göre değişmesi (ör. bir Premium temanın parçacık rengiyle
      çarpışması) tutarsız görünürdü, `Zibo ADS` banner'ının "aktif temadan bağımsız sabit marka
      rengi" felsefesiyle AYNI karar.
    - **`_FadingTimerText`** (YENİ, private) — kullanıcının "sayaç saniyesi dakikası geçişinde
      fade efekti" isteği: `AnimatedSwitcher(duration: 280ms)` + `ValueKey(text)`, HER saniye
      değişiminde metni "yeni" saydırıp varsayılan `FadeTransition` geçişini tetikliyor — ekstra
      bir `transitionBuilder` YAZILMADI, `AnimatedSwitcher`'ın varsayılanı zaten tam istenen efekt.
    - **"Hareketli temalara dikkat et" — gerçek bir bilinen sınırlamayı hedefleyen bilinçli bir
      düzeltme.** Bu ekranın ömrü boyunca `isHomeTabActive` (bkz. `tab_navigation.dart`) BİLEREK
      `false`'a sabitlenip (`initState`) çıkışta ESKİ değerine geri döndürülüyor (`dispose`).
      **Neden gerekli:** Ana Sayfa'da aktif bir Premium/Animasyonlu tema varsa (bkz.
      `AnimatedThemeOverlay`), o parçacık katmanı yalnızca sekme GEÇİŞLERİNDE
      (`RootScreen._setSelectedIndex`) güncellenen bu bayrağa bakıyor — bir ekran PUSH etmek
      bayrağı DEĞİŞTİRMEZ (CLAUDE.md "Premium/Animasyonlu temalar" bölümündeki ÖNCEDEN dokümante
      edilmiş bilinen sınırlama), yani Ana Sayfa'dan açılan bu ekranın ÜSTÜNE kar/galaksi/konfeti
      gibi bir efekt çizilmeye devam edebilirdi — tam da bu ekranın önlemeye çalıştığı türden bir
      dikkat dağınıklığı, "kapkaranlık" hissini bozardı.
- **Modül menüsü girişi** — Z butonu modül menüsüne (`modules_menu_sheet.dart`) YEDİNCİ bir
  `_ModuleCard` olarak eklendi (`Icons.timer_outlined`), Para ve Birikim kartının hemen ardına.
- **Profil'deki "Odak Süresi" satırı — BİLİNÇLİ bir kapsam kararı: mevcut 4 kategorili
  `ProfileStats` sistemine DAHİL EDİLMEDİ.** Bu sistem (Para/Şükür-Manifest/İstikrar/Öz Saygı-
  Sağlık) tam sayıda kategoriyle sıkı sıkıya bağlı (home-widget carousel'i tam 4 öğe varsayıyor,
  aylık arşiv snapshot formatı vb.) — beşinci bir kategori eklemek riskli/invaziv olurdu. Bunun
  yerine `_ProfileStatRow` (YENİ, `profile_screen.dart` içinde private) — `_ProfileLinkRow`'un
  AKSİNE bir sayfaya NAVİGE ETMEYEN salt bilgi satırı (ok/onTap yok, Odak Sayacı zaten Z-menüsünden
  erişiliyor) — "Zibo ile Bağın" bölümüne, "En Uzun Seri Rekoru"nun hemen ardına eklendi. Süre
  `_formatFocusDuration(seconds)` ile "{saat} sa {dakika} dk" / "{dakika} dk" biçiminde
  gösteriliyor. **Bu kapsam kararı kullanıcıya AÇIKÇA FLAGLENMELİ** — istenirse ileride gerçek
  5. kategori olarak `ProfileStats`'a taşınabilir, ama bu daha büyük/riskli bir refactor gerektirir.
- **Test:** `test/focus_provider_test.dart` (6 test — boş başlangıç, 60sn altı reddi, geçerli
  oturum kaydı, birden fazla oturumun BİRİKTİĞİ + en-yeni-önce sıralandığı, toplam süre hesaplaması,
  kalıcılık) + YENİ `test/focus_timer_screen_test.dart` (4 test — kurulum ekranının mod seçici/
  "Başlat" gösterdiği, "Başlat"a basınca ekranın karanlık moda geçip mod seçici/toplam süre
  kartının GİZLENDİĞİ + `Scaffold.backgroundColor == Colors.black` olduğu, `isHomeTabActive`'in
  ekran açıkken `false`'a sabitlenip kapanınca eski değerine döndüğü, sayacın ilerleyip "Bitir ve
  Kaydet" ile kaydedildiği).
- **Gerçek cihazda GÖRSEL doğrulama bu turda debug APK ile YAPILDI** (kullanıcı isteğiyle) —
  kullanıcının kendi cihazında kontrol ettiği: karanlık modun gerçekten tam siyah olduğu, halkanın
  parlama efektinin görünür olduğu, sayaç geçişlerinin fade ile yumuşak olduğu, ve (varsa) aktif
  bir Premium/Animasyonlu temanın parçacık efektinin bu ekranın ÜSTÜNE SIZMADIĞI.

## Instagram Takip Kartı ve Ödülü ([instagram_follow_provider.dart](lib/providers/instagram_follow_provider.dart), [instagram_follow_card.dart](lib/widgets/instagram_follow_card.dart))

- **2026 yeni özellik.** Kullanıcı isteği: Profil'de "Bizi Instagram'da Takip Edin" kartı — bir
  buton @zibo.app hesabını açsın, "Takip Ettim" butonuna basınca (gerçek takip doğrulaması teknik
  olarak MÜMKÜN OLMADIĞI için kullanıcı BEYANINA dayalı) 100 ZC + 1 standart tema + düşük fiyatlı
  bir kostüm versin, SADECE BİR KEZ.
- **`InstagramFollowProvider`** — `ThemeProvider`/`OnboardingProvider` ile AYNI "tek bir kalıcı
  bool bayrak" (Varyant C) `CloudStateStore` deseni. `markClaimed()` idempotent — `_claimed` bir
  kez `true` olduktan sonra HER ZAMAN `false` döner, çağıran taraf bu durumda ödünlerin HİÇBİRİNİ
  vermez. Kart ayrıca `claimed == true` iken kendini TAMAMEN GİZLER — bu yüzden gerçek kullanımda
  bu yola hiç girilmiyor, ama API seviyesinde çift bir güvenlik katmanı.
- **`CoinProvider.earnInstagramFollowReward()`** — sabit 100 ZC (`CoinEconomy.
  instagramFollowReward`), `_earn()`'ün merkezi kancasından geçtiği için otomatik XP + ses de
  veriyor.
- **Kostüm/tema hediyesi — `badge_special_reward.dart`'taki (Rozet Sistemi'nin "Kostüm/Tema
  Hediye Sistemi") AYNI saf/enjekte edilebilir-`Random` desenleri yeniden kullanıldı:**
  `pickRandomUnownedStandardTheme` (mevcut, değişmedi) + YENİ `pickRandomUnownedLowPricedCostume`
  — `costumes.dart`'ın fiyata göre sıralı listesinin (ucuzdan pahalıya) İLK ÜÇTE BİRİNDEN
  ("düşük fiyatlı kostümler"), henüz sahip olunmamış birini rastgele seçer. Uygun kostüm/tema
  kalmadıysa (teorik olarak nadir) `null` döner, o ödül sessizce atlanır — Rozet Sistemi'nin gift
  reward mantığındaki AYNI "hiçbir şey kalmadıysa sessizce ver-me" davranışı.
- **`InstagramFollowCard`** — Profil ekranında, isim alanının hemen altında (Level/XP ilerleme
  kartının HEMEN ALTINDA) gösteriliyor; `claimed == true` iken `SizedBox.shrink()`. "Instagram'ı
  Aç" (`url_launcher`, `https://www.instagram.com/zibo.app`, `LaunchMode.externalApplication`) +
  "Takip Ettim" (yükleniyor göstergeli) iki buton. **"Ara sıra gösterilsin" isteği, gerçek bir
  olasılıksal zamanlama YERİNE basitçe "henüz alınmadığı sürece HER ZAMAN görünür" olarak
  yorumlandı** — bu kapsam kararı kullanıcıya AÇIKÇA FLAGLENMELİ, istenirse Ana Sayfa'da/rastgele
  aralıklarla gösterilecek şekilde genişletilebilir.
- **Test:** YENİ `test/instagram_follow_provider_test.dart` (4 test — başlangıç durumu, İLK
  `markClaimed()` başarılı, İKİNCİ çağrı reddedilir, kalıcılık) + YENİ `test/badge_special_reward_test.dart`
  (4 test — `pickRandomUnownedLowPricedCostume`'un yalnızca ucuz/sahip-olunmayan kostümlerden
  seçtiği, sahiplenilmiş adayların listeden çıktığı, hepsine sahipken `null` döndüğü, pahalı
  kostümlerin ASLA seçilmediği). Widget testi (kartın kendisi) YAZILMADI — `url_launcher`'ın
  platform kanalına dokunduğu için (`ad_free_promo_sheet.dart`'taki benzer harici link butonlarıyla
  AYNI gerekçe) kapsam dışı bırakıldı, provider/saf-fonksiyon testleriyle yetinildi.
- **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI.** **Kullanıcının kendi cihazında
  doğrulaması gereken:** "Instagram'ı Aç"ın gerçekten Instagram uygulamasını/tarayıcıyı açtığı,
  "Takip Ettim"e basınca coin bakiyesinin +100 arttığı VE Mağaza'da yeni bir tema/kostümün "Sahip
  Olunan" göründüğü, kartın SONRASINDA bir daha HİÇ görünmediği (uygulama yeniden başlatılsa bile).

## Yerelleştirme (i18n) — Türkçe / İngilizce / İspanyolca

- Resmi Flutter `gen-l10n` pipeline'ı kullanılıyor (`easy_localization` gibi üçüncü parti paket
  değil). Config: [l10n.yaml](l10n.yaml) — `arb-dir: lib/l10n`, template `app_tr.arb`, çıktı sınıfı
  `AppLocalizations`.
- **Üç dil, üç ARB dosyası:** Türkçe (`app_tr.arb`) template/kaynak dil, İngilizce (`app_en.arb`) ve
  İspanyolca (`app_es.arb`) tam ayna — 85 UI metni anahtarının üçü de senkron (`AppLocalizations.
  supportedLocales` derlendiğinde otomatik olarak `[en, es, tr]` listeler, `flutter gen-l10n`
  ARB dosyalarını tarayarak üretir, elle bir yerde "desteklenen diller" listesi tutulmuyor).
- **Gotcha:** ARB'ye yeni anahtar eklendikten sonra `AppLocalizations`'ın güncellenmesi otomatik
  değil — `flutter test` bunu kendiliğinden tetiklemiyor (denendi: ARB güncellenip doğrudan
  `flutter test` çalıştırılınca "getter isn't defined" derleme hatası alındı). Yeni anahtarları
  kullanan kodu test etmeden/derlemeden önce elle **`flutter gen-l10n`** çalıştırılmalı.
- **`LocaleProvider`** ([locale_provider.dart](lib/providers/locale_provider.dart)) — `ThemeProvider`
  ile birebir aynı desen (`SharedPreferences` kalıcı, `languageCode` anahtarı, varsayılan Türkçe).
  `main.dart`'taki eski sabit `locale: const Locale('tr')` kaldırılıp `Consumer2<ThemeProvider,
  LocaleProvider>` ile `MaterialApp.locale: localeProvider.locale`'e bağlandı — kullanıcı dil
  değiştirdiğinde TÜM ağaç (ARB metinleri + söz havuzları, bkz. aşağı) anında yeniden build olup
  yeni dile geçiyor, ayrı bir "yeniden başlat" adımına gerek yok.
- **Ayarlar > Dil satırı** ([settings_screen.dart](lib/screens/settings_screen.dart)): artık no-op
  değil — seçili dilin küçük YUVARLAK bayrak rozetini (`_LanguageFlagCircle`) ve adını (`Türkçe`/
  `English`/`Español`, autonym — UI dilinden bağımsız, bu yüzden ARB'de DEĞİL) gösteriyor, dokununca
  üç dili de listeleyen bir `showModalBottomSheet` açılıyor (her satırda yuvarlak bayrak + dil adı +
  seçili olana onay ikonu).
  - **Gotcha — bayrak emoji'sini yuvarlak yapmak:** Bayrak emoji glifleri (🇹🇷/🇬🇧/🇪🇸) doğası gereği
    dikdörtgen çiziliyor; glif konteynerden KÜÇÜKSE `ClipOval` hiçbir şeyi kırpmıyor (üst üste
    binen bir daire arka planla birlikte düz bayrak gibi görünüyor — cihazda ilk denemede tam
    böyle oldu). **Çözüm:** glif bilerek konteynerden BÜYÜK çizilip (`fontSize: size * 1.05`,
    `OverflowBox` ile taşmasına izin verilip) `ClipOval` içine alınıyor — böylece köşeler gerçekten
    kırpılıp belirgin bir daire oluşuyor; ayrıca ince bir `Border` halkası eklendi (koyu temada arka
    planla karışmasın diye).
- **Coin Test Paneli tamamen kaldırıldı** (kullanıcı isteğiyle) — `_CoinTestPanel` widget'ı ve
  kullanımı silindi, `coin_provider.dart`/`coin_feedback.dart` import'ları settings_screen.dart'tan
  temizlendi. Panelin tetiklediği coin kazanma/harcama akışlarını doğrulayan testler artık
  `CoinProvider`'a `Provider.of<CoinProvider>(element, listen: false).earnX()` ile DOĞRUDAN
  erişiyor (bkz. `widget_test.dart`'taki "Günlük check-in..." ve "Kostüm satın alınıp giyilebilir"
  testleri) — panel yalnızca test/debug amaçlı geçici bir UI'ydi, gerçek bir kullanıcı akışı değildi.
- **Bilinçli ayrım korunuyor, ama artık ÜÇ dilli:** UI "chrome" metinleri (buton, başlık, tooltip
  vb.) ARB üzerinden gider; büyük "içerik havuzları" (`zibo_messages.dart`'taki ~100 mesaj,
  `goal_quotes.dart`'taki 100, `money_quotes.dart`'taki 50, `water_quotes.dart`'taki 30,
  `dream_quotes.dart`/`gratitude_quotes.dart`/`mood_quotes.dart`'taki 10'ar) hâlâ ARB'ye TAŞINMADI
  (uzun serbest metinler için ARB placeholder mekanizması gereksiz dolaylılık eklerdi) — ama artık
  yalnızca Türkçe değil, her biri üç dilde de (`xTr`/`xEn`/`xEs` sabit listeleri + `xForLocale
  (Locale)` yardımcı fonksiyonu) tutuluyor. **Çeviriler birebir değil** — Zibo'nun samimi/esprili
  "kanka" tonu İngilizce'de "buddy", İspanyolca'da "amigo" gibi o dilde doğal duracak şekilde
  uyarlandı (kullanıcının açık isteği). Üç liste de her dosyada BİREBİR AYNI SAYIDA öğe içeriyor
  (elle doğrulandı, bkz. aşağıdaki test notu) — index tabanlı seçim mantığının (bkz. altta) güvenle
  çalışması buna bağlı.
  - **Söz döndürme mantığı STRING değil INDEX tabanlı:** Eskiden her ekran `late String _quote =
    xQuotes.first;` + seçilen METNİ saklıyordu; dil değişince bu string artık YANLIŞ dildeki bir
    söz olarak kalırdı. Şimdi her ekran `int _quoteIndex = 0;` saklıyor, `build()` içinde
    `xForLocale(Localizations.localeOf(context))[_quoteIndex % quotes.length]` ile o anki dildeki
    karşılığı okuyor — kullanıcı bir modül ekranı AÇIKKEN dil değiştirirse (teorik olarak mümkün,
    Ayarlar geri gidilip modül tekrar açılmasa bile) konuşma balonu doğru dile anında geçer, "aynı
    konum" korunur. Bu desen `home_screen.dart` (dokununca), `money_screen.dart`/
    `goal_tracking_screen.dart` (`Timer.periodic` + `isActive`), `dream_journal_screen.dart`/
    `gratitude_journal_screen.dart`/`mood_tracking_screen.dart`/`water_tracking_screen.dart`
    (`Timer.periodic`, plain `initState`/`dispose`) — YEDİ ekranın hepsinde birebir tekrarlanıyor.
  - **`notification_provider.dart` İSTİSNA — bilerek locale-aware YAPILMADI:** Bildirim özelliği
    zaten GEÇİCİ OLARAK DEVRE DIŞI (`notificationsFeatureEnabled = false`, bkz. "Bildirimler"
    bölümü), bu yüzden `ziboMessagesTr`/`goalQuotesTr`'yi (yeniden adlandırılmış Türkçe sabit
    listeler) doğrudan kullanmaya devam ediyor — özellik yeniden açılırsa burası da
    `ziboMessagesForLocale`/`goalQuotesForLocale`'e geçirilmeli.
- **Test:** `flutter test` içinde her söz havuzu dosyası için üç dildeki liste UZUNLUĞUNUN birebir
  eşit olduğu elle (awk ile) doğrulandı (100/100/100, 50/50/50, vb. — 7 dosya × 3 dil). Ayrıca
  `widget_test.dart`'a yeni bir uçtan uca senaryo eklendi ("Dil seçici: İngilizce seçilince arayüz
  her yerde İngilizce'ye döner") — Ayarlar'dan İngilizce seçilip hem Ayarlar sayfasının (`Language`/
  `Settings`) hem alt gezinme çubuğunun (`Home`/`Goals`/`Savings`) hem de Ana Sayfa'daki söz
  havuzunun (`ziboMessagesEn.first`) AYNI ANDA İngilizce'ye döndüğünü doğruluyor — "seçilen dil
  uygulamanın her yerinde tutarlı uygulansın" gereksinimi bu testle somut olarak garanti altına
  alındı. Gerçek cihazda hem İngilizce'ye geçiş (Ayarlar, Ana Sayfa, Hedef Takibi — söz havuzu
  metinleri BİREBİR `ziboMessagesEn`/`goalQuotesEn` ile eşleşti) hem üç dilin de seçici sheet'inde
  doğru yuvarlak bayraklarla listelendiği doğrulandı; İspanyolca'ya geçiş ve Türkçe'ye geri dönüş
  doğrulaması cihaz bağlantısı koptuğu için TAMAMLANAMADI — kod yolu İngilizce ile birebir aynı
  olduğu için risk düşük, ama bir sonraki oturumda tamamlanmalı.
- **2026 güncellemesi — Gizlilik Politikası/Kullanım Koşulları de dil sistemine bağlandı, bilerek
  ALINMIŞ önceki "yalnızca Türkçe" kararı GERİ ÇEVRİLDİ.** Kullanıcı raporu: "uygulama dili
  İngilizce/İspanyolca'ya değiştirilse bile bu sayfalar hep Türkçe kalıyor." `lib/data/
  legal_texts.dart`'ın (bkz. "Ayarlar" bölümündeki orijinal açıklama) o zamanki gerekçesi —
  "hukuki bir belgenin çeviri belirsizliği GERÇEK sonuç doğurabilir, bu yüzden TEK yetkili Türkçe
  sürüm tutulsun" — kullanıcının bu turdaki AÇIK isteğiyle bilinçli olarak bir kenara bırakıldı.
  - **`privacyPolicyEn`/`privacyPolicyEs`/`termsOfServiceEn`/`termsOfServiceEs`** eklendi —
    `zibo_messages.dart` gibi diğer içerik havuzlarının "ton uyarlaması" YAKLAŞIMINI İZLEMİYOR
    (kelimesi kelimesine değil ama madde madde ANLAMCA birebir çeviri, çünkü bu bir hukuki/
    bilgilendirici belge). KVKK referansı gibi Türkiye'ye özgü unsurlar EN/ES sürümlerinde de
    KORUNDU (genel bir ifadeyle silinip gizlenmedi) — "Uygulanacak Hukuk" maddesi zaten dilden
    bağımsız olarak Türk hukukunun geçerli olduğunu söylüyor.
  - **`privacyPolicyForLocale(Locale)`/`termsOfServiceForLocale(Locale)`** — `moneyQuotesForLocale`/
    `ziboMessagesForLocale` ile BİREBİR AYNI kalıp (`switch (locale.languageCode) { 'en' => ...,
    'es' => ..., _ => trSürümü }`). `lib/screens/settings_screen.dart`'taki iki `LegalPlaceholder
    Screen` çağrısı `body: privacyPolicyTr`/`termsOfServiceTr` yerine
    `body: privacyPolicyForLocale(Localizations.localeOf(context))`/AYNI kalıpla `termsOfService
    ForLocale(...)` kullanıyor.
  - **Gotcha (gerçekten yaşandı) — `library;` direktifi dosyanın EN BAŞINDA olmalı, bir `import`'tan
    SONRA GELEMEZ.** İlk yazımda `import 'package:flutter/widgets.dart';` (yeni `Locale` parametresi
    için gerekli) dosyanın dokümantasyon yorumu+`library;` direktifinden ÖNCE eklenmişti —
    `flutter test` "The library directive must appear before all other directives" derleme
    hatasıyla ÇÖKTÜ. **Düzeltme:** `import`, `library;` direktifinden SONRAYA taşındı (Dart'ın
    zorunlu direktif sırası: `library` → `import`/`export` → geri kalan kod).
  - **Test:** `widget_test.dart`'a YENİ bir senaryo — dil İngilizce'ye çevrilip Gizlilik Politikası/
    Kullanım Koşulları'na girilince İngilizce sürümden ayırt edici bir ibarenin ("Data Controller"/
    "Virtual Currency") göründüğü VE Türkçe ibarenin ("Veri Sorumlusu"/"Sanal Para Birimi")
    GÖRÜNMEDİĞİ doğrulanıyor — mevcut TR-varsayılan test (aynı iki ibarenin Türkçe karşılıklarını
    doğrulayan) DOKUNULMADAN kalıyor. `flutter test` tam yeşil: **356/356.**
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — kullanıcının kendi cihazında dil
    değiştirip her iki sayfanın da doğru dilde, taşmadan render olduğunu kontrol etmesi gerekiyor
    (özellikle İspanyolca — bu dilin metni EN'den biraz daha uzun, `SingleChildScrollView`
    zaten uzun metinler için kurulmuştu ama İspanyolca ile ayrıca doğrulanmadı).

## Görsel işleme ([tool/](tool/))

- `zibo_yeni.png`, `zibo_coin.png`, `zibo_logo_new.png` gibi assetler orijinalde düz beyaz stüdyo
  arka planıyla geldi; iki tek seferlik betikle işlendi:
  - `remove_bg.dart`: kenarlardan başlayan flood-fill ile arka planı şeffaflaştırır + kenarlarda
    feather (kademeli saydamlık) uygular. Karakterin üstündeki beyaz alanlar (kenara bağlı
    olmadığı için) etkilenmez.
  - `crop_transparent.dart`: şeffaflaştırılmış görseli, içeriğin gerçek sınır kutusuna göre kırpar.
- `image` paketi yalnızca bu araçlar için `dev_dependency` — uygulamanın çalışma zamanına dahil değil.
- Kullanım: `dart run tool/remove_bg.dart <dosya_yolu>` ardından
  `dart run tool/crop_transparent.dart <dosya_yolu>`.
- 11 kostüm görseli (`zibo_hippi.png` vb.) tedarikçiden **zaten şeffaf** (düz siyah değil — görsel
  önizleyicilerde şeffaflık bazen siyah render edilebiliyor, köşe pikselinin alfa değeriyle
  doğrulanmalı) geldi; yalnızca `crop_transparent.dart` ile kırpıldı, `remove_bg.dart`'a gerek
  kalmadı.
- **Uygulama ikonu (`zibo_app_icon.png`, 1024×1024) — `clean_app_icon.dart`:** kullanıcının verdiği
  ikon, yuvarlatılmış köşeli mavi kare tasarımın DIŞINDA kalan dört köşede OPAK BEYAZ bir kare tuval
  içinde geldi. `remove_bg.dart`'taki AYNI "kenardan flood-fill" fikri kullanıldı ama basitleştirilmiş
  bir varyantla (`clean_app_icon.dart`, YENİ) — dört köşeden başlayan bir BFS, yalnızca köşelerle
  BAĞLANTILI beyaz piksel bölgesini şeffaflaştırıyor; ikonun İÇİNDEKİ izole beyaz tonlara (Zibo'nun
  atleti gibi) dokunulmuyor, `remove_bg.dart`'ın feather adımına gerek kalmadı (kenarlar zaten keskin
  tasarım kenarları, fotoğrafik değil). Orijinalin yedeği `tool/pose_originals_backup/
  zibo_app_icon.png` altında.
  - **`flutter_launcher_icons` paketiyle (dev_dependency, `pubspec.yaml`'daki
    `flutter_launcher_icons:` bloğu) tüm Android mipmap boyutları (`mipmap-mdpi` … `mipmap-xxxhdpi`)
    temizlenmiş bu tek kaynaktan üretildi** (`dart run flutter_launcher_icons`) — adaptive icon
    (foreground/background katmanları) BİLEREK kurulmadı, proje zaten eski/basit tek-PNG mipmap
    yapısını kullanıyordu (`mipmap-anydpi-v26` yok), bu yüzden ek katman karmaşasına gerek yoktu.
    Yeni bir ikon değişikliğinde tek yapılması gereken: kaynak PNG'yi güncelleyip (gerekirse
    `clean_app_icon.dart` ile arka planını temizleyip) `dart run flutter_launcher_icons`'ı tekrar
    çalıştırmak.

## Test kalıpları ve bilinen tuzaklar

- Test dosyaları: `widget_test.dart` (asıl entegrasyon testleri), `goals_provider_test.dart`,
  `coin_provider_test.dart`, `theme_provider_test.dart`, `money_provider_test.dart`,
  `zibo_share_sheet_test.dart`, `costume_provider_test.dart`, `app_theme_provider_test.dart`,
  `daily_rewards_provider_test.dart`, `wheel_prizes_test.dart`, `dream_journal_provider_test.dart`,
  `gratitude_provider_test.dart`, `mood_provider_test.dart`, `notification_provider_test.dart`,
  `profile_provider_test.dart`, `profile_stats_test.dart`, `profile_screen_test.dart`,
  `manifest_journal_screen_test.dart`, `address_term_test.dart`, `bond_level_test.dart`,
  `favorite_quotes_provider_test.dart`, `onboarding_provider_test.dart`,
  `zibo_animated_image_test.dart`, `sound_effects_provider_test.dart` (2026 — bkz. "Zibo
  Dokunma Sesi" bölümü), `home_screen_sound_test.dart` (aynı bölüm),
  `water_tracking_sound_test.dart` (2026 — kostüm/tema/su damlası sesleri, "Zibo Dokunma Sesi"
  bölümü), `auth_link_provider_test.dart` (2026 — bkz. "Google Hesap Bağlama" bölümü),
  `settings_screen_test.dart` (aynı bölüm), `custom_messages_provider_test.dart` (2026 — Ana Sayfa
  özel mesajlar özelliği), `currency_provider_test.dart` (2026 — Para ve Birikim çoklu para birimi
  özelliği), `profile_stats_archive_provider_test.dart` (2026 — bkz. "Profil" bölümündeki "Geçmiş
  Ay İstatistikleri" notu), `trusted_time_provider_test.dart` (2026 — bkz. "Push
  Bildirimleri" bölümündeki "günlük ödül 1. günde takılı kalıyor" bug düzeltmesi — cross-session
  staleness'ı doğrudan hedefleyen 5 test), YENİ `widget_status_test.dart`/
  `home_widget_sync_coordinator_test.dart`/`widgets_screen_test.dart` (2026 — bkz. "Ana Ekran
  Widget'ları" bölümü), YENİ `motivation_quote_selector_test.dart` (2026 — bkz. "Motivasyon Sözü
  Sistemi" bölümü, 11 test — `timeBucketFor`/`moodPoolTagFor`/`recentLowMoodRatio`/
  `resolveMotivationQuoteText`/`pickMotivationQuote`'un saf fonksiyon testleri), YENİ
  `founder_badge_provider_test.dart` (2026 — bkz. "Kurucu Üye Rozeti" bölümündeki "2026 İKİNCİ
  güncelleme", canlı sayaç + `claimIfEligible()` transaction mantığının `fake_cloud_firestore`
  ile 8 testi), YENİ `home_screen_event_message_test.dart` (2026 — bkz. "Olay Tetiklemeli Özel
  Mesajlar" bölümü, `pendingZiboEvent` tüketimi/gösterimini doğrulayan 3 test). **`test/
  wheel_screen_test.dart` KISA SÜRE var oldu, SONRA SİLİNDİ** — Şans Çarkı sonrası reklam
  denemesiyle birlikte geldi, kullanıcı o özelliği istemeyince (bkz. "Zibo'ya Art Arda Dokunma →
  Geçiş Reklamı" bölümündeki geri alma notu) testi de anlamsızlaştığı için kaldırıldı.
  **Toplam: 425 test** (424 geçti + 1 önceden belgelenmiş `audioplayers` flake'i — 2026, Olay
  Tetiklemeli Özel Mesajlar + Ruh Hali Notu Anahtar Kelime Çıkarımı turunda `motivation_quote_
  selector_test.dart`'a 14 YENİ test (`zibo_event_messages.dart` havuz bütünlüğü, `resolveMotivationQuoteText`'in
  `'event'` kaynağı, `moodNoteKeywordBias`, `pickMotivationQuote`'un anahtar kelime çıkarımı) +
  YENİ `home_screen_event_message_test.dart` [3 test] eklendi, bkz. "Olay Tetiklemeli Özel
  Mesajlar"/"Ruh Hali Notundan Anahtar Kelime Çıkarımı" bölümleri. Bu turdan BİR ÖNCEKİ, Kurucu
  Üye rozetinin Google-bağlama-tabanlı canlı sayaca geçişi turunda `founder_badge_provider_test.
  dart` [8 YENİ test] eklendi, bkz. "Kurucu Üye Rozeti" bölümü. Ondan BİR ÖNCEKİ, EN/ES
  söz havuzu çevirisi turunda `motivation_quote_selector_test.dart`'a 21 YENİ "havuz bütünlüğü"
  testi [`pool.toSet().length == 51`, 7 Tr + 7 En + 7 Es] eklendi, bkz. `motivation_pools.dart`
  bülteni. Bu turdan BİR ÖNCEKİ (Türkçe-yalnızca) turda `motivation_quote_selector_test.dart`'a
  [11 YENİ test] + `mood_provider_test.dart`'a not (note) alanı grubu [6 YENİ test] +
  `widget_test.dart`'a bir uçtan uca senaryo [1 YENİ test] eklenmişti, bkz. "Motivasyon Sözü
  Sistemi"/"Günlük Ruh Hali Takibi" bölümleri — bu testlerin ÖNCESİNDEKİ birikimli tarihçe için:
  `costume_provider_test.dart`'a
  `reconcileGoalUnlocks` grubu +
  `water_provider_test.dart`'a `completedDaysCount` testi [bkz. "Kostümler" bölümü] +
  `dream_sentiment_test.dart` [bkz. "Rüya Günlüğü" bölümündeki korelasyon notu] +
  `referral_provider_test.dart` [bkz. "Davet Et (Referral) Sistemi" bölümü] +
  `profile_screen_test.dart`'a "Kurucu Üye" rozeti senaryosu [bkz. "Kurucu Üye Rozeti" bölümü] +
  `trusted_time_provider_test.dart` [5 test, bkz. "Push Bildirimleri" bölümündeki günlük ödül
  bug düzeltmesi] + YENİ `widget_status_test.dart`/`home_widget_sync_coordinator_test.dart`/
  `widgets_screen_test.dart` [26 test, bkz. "Ana Ekran Widget'ları" bölümü] + "Zibo'nun Sözü"
  widget'ı için bu üç dosyaya eklenen 2 ek test [bkz. "Ana Ekran Widget'ları" bölümündeki 2026
  görsel yeniden tasarım notu] eklendi).
- `widget_test.dart` içindeki `_buildAppWithClock()` yardımcı fonksiyonu enjekte edilebilir saatli
  testler için — **`RootScreen`'in ihtiyaç duyduğu HER provider'ı içermeli** (`AppStreakProvider`
  (2026 — Rozet Sistemi, bkz. "Rozet Sistemi" bölümü), `AppThemeProvider`,
  `AuthLinkProvider`, `BadgeProvider` (aynı bölüm), `CoinProvider`, `CostumeProvider`, `CurrencyProvider`,
  `CustomMessagesProvider`, `DailyRewardsProvider`, `DreamJournalProvider`,
  `FavoriteQuotesProvider`, `FocusProvider` (2026 — Odak Sayacı, bkz. o bölüm),
  `FounderBadgeProvider` (2026 — `ProfileScreen`/`SettingsScreen`'in
  `FounderBadgePromoCard` üzerinden izlediği, bkz. "Kurucu Üye Rozeti" bölümü), `GoalsProvider`,
  `GratitudeProvider`, `HiddenBadgeProvider` (2026 — Gizli/Eğlenceli Rozetler'in
  `BadgeCoordinator`'ı artık bunu da izlediği için, bkz. "Rozet Sistemi" bölümündeki "Altıncı ve
  SON kategori"), `InstagramFollowProvider` (2026 — Instagram Takip Kartı, bkz. o bölüm),
  `LocaleProvider`,
  `ManifestProvider`, `MoneyProvider`, `MoodProvider`, `NotificationProvider`, `ProfileProvider`,
  `ProfileStatsArchiveProvider`, `ReferralProvider` (2026 — Sosyal/Paylaşım Rozetleri'nin
  `BadgeCoordinator`'ı artık bunu da izlediği için, bkz. "Rozet Sistemi" bölümündeki "Beşinci
  kategori"), `SoundEffectsProvider`,
  `ThemeProvider`, `TrustedTimeProvider`, `WaterProvider`, `XpProvider` (2026 — Level/XP Sistemi,
  `ProfileScreen`'in ilerleme çubuğu üzerinden izlediği, bkz. o bölüm), `ZiboPoseProvider`) —
  bunun sebebi
  `RootScreen`'in tüm sekmeleri hemen kurması (artık `ProfileScreen` de bir sekme olduğu için onun
  transitif olarak izlediği TÜM provider'lar da burada olmalı — bkz. "Alt Gezinme Çubuğu"
  bölümündeki Profil↔Birikim yer değiştirme notu). **ARTIK GEÇERSİZ NOT (tarihsel bağlam için
  tutuluyor):** `CurrencyProvider` bir süre bilerek bu listeye EKLENMEMİŞTİ, çünkü onu izleyen TEK
  ekran (`MoneyScreen`) `RootScreen`'in sabit sekmelerinden biri değildi. **2026 güncellemesi — Ana
  Ekran Widget'ları özelliğiyle bu artık geçerli DEĞİL:** `RootScreen`'in KENDİSİ artık
  `HomeWidgetSyncCoordinator` üzerinden `CurrencyProvider`'ı (Para ve Birikim widget'ının para
  birimi formatı için) DOĞRUDAN `context.read` ediyor — `MoneyScreen`'den TAMAMEN BAĞIMSIZ, YENİ
  bir gerekçeyle — bu yüzden `CurrencyProvider` (ve AYNI koordinatörün ihtiyaç duyduğu
  `DreamJournalProvider`/`LocaleProvider`/`MoodProvider`) artık listeye EKLENDİ, bkz. "Ana Ekran
  Widget'ları" bölümü. **Gotcha (gerçekten yaşandı, İKİ AYRI kez):** `AppThemeProvider` `main.dart`'a
  eklenirken bu yardımcıya eklenmesi UNUTULMUŞTU — sonuç, o yardımcıyı kullanan İLK testte değil,
  `ProviderNotFoundException`'ın `widget_test.dart`'ın KENDİSİNDEN SONRA gelen HER testi (aynı test
  ikili dosyasında art arda koştukları için) etkilemesi, tek dosyada 20 test başarısızlığına yol
  açması oldu (bkz. "Temalar" bölümü) — Ana Ekran Widget'ları eklenirken de AYNI hata TEKRAR
  yaşandı (bu sefer 4 eksik provider'la, `test/widget_test.dart: Method not found` derleme hatası
  olarak — bir öncekinden FARKLI belirti ama AYNI kök neden). **`main.dart`'a (VEYA `RootScreen`'in
  KENDİSİNİN okuduğu provider kümesine) yeni bir bağımlılık eklerken bu yardımcıyı GÜNCELLEMEYİ
  unutmayın** — unutulursa hata yalnızca doğrudan ilgili testte değil, ondan sonraki TÜM testlerde
  görünür, kökeni bulmak zorlaşır.
- **`widget_test.dart`'ta İKİ AYRI "uygulamayı ayağa kaldır" yardımcısı var, birbirine
  KARIŞTIRILMAMALI (2026, Onboarding eklenince ortaya çıktı):** `const DijitalKankaApp()`'i
  pump'layan HER test artık `_pumpPastOnboarding(tester, app)` kullanmalı (`DijitalKankaApp`
  gerçek `_AppStartupGate`'den geçtiği için önce isim girip Onboarding'i atlaması gerekiyor —
  bkz. "Onboarding" bölümü); `_buildAppWithClock(() => clock)` ile kurulan enjekte-saatli testler
  ise bare `MaterialApp(home: RootScreen())` kurduğu için (Onboarding'i/`_AppStartupGate`'i hiç
  içermez) DÜZ `tester.pumpWidget(...)` + `tester.pumpAndSettle()` kullanmaya devam ediyor.
  Bunları karıştırmak (`_pumpPastOnboarding`'i `_buildAppWithClock`'un çıktısına uygulamak)
  `enterText`/`tap('Devam Et')`'in bulacağı bir `TextField`/buton OLMADIĞI için `Bad state: No
  element` hatasıyla çöker.
- `widget_test.dart`'ın `setUp()`'ı `disableAnimations: true` sabitliyor (bkz. "Şans Çarkı"
  bölümündeki gotcha) — `RootScreen`'i pump'layan başka bir test dosyası açılırsa aynı satırlar oraya
  da taşınmalı. Aynı `setUp()` ayrıca gerçekçi bir telefon viewport'u da sabitliyor
  (`TestPlatformDispatcher.views` üzerinde `physicalSize: Size(412, 915)`, `devicePixelRatio: 1.0`,
  `addTearDown` içinde reset) — genel olarak faydalı bir pratik (varsayılan 800×600 masaüstü-oranlı
  test yüzeyi telefon tasarımlarını bozabiliyor), artık herhangi bir tek widget'a özgü bir gerekçesi
  yok ama kaldırılmadı.
- **Alt gezinme çubuğuna dokunan testler `find.text(...)` DEĞİL, `find.bySemanticsLabel(...)`
  kullanıyor** — `MainBottomBar` artık gerçek `Text` widget'ları içerse de (bkz. "Alt Gezinme
  Çubuğu"), testler bilerek semantics üzerinden gidiyor: `_NavItem`'ın `excludeSemantics: true`
  ile tanımladığı TEK, temiz `Semantics(label: ...)` etiketi, görünen kısa metinden (`Text`)
  bağımsız ve daha kararlı. Z butonu menüsünü açmak için de aynı şekilde
  `find.bySemanticsLabel('Ek modülleri aç')` kullanılıyor.
- `ThemeProvider`'a dokunan her testin `setUp`'ında `SharedPreferences.setMockInitialValues({})`
  gerekli.
- Keşfedilen `flutter_test` tuzakları:
  - `GridView.count`, `shrinkWrap: true` ile bir `ListView` içine gömülüyse (Mağaza ekranındaki
    gibi) ve bu `IndexedStack` içindeyse, `tester.tap()` koordinat hit-test uyuşmazlığı yaşayabilir
    — bunun yerine `tester.widget<FilledButton>(finder).onPressed!()` ile doğrudan çağırmak daha
    güvenilir.
  - Düz `ListView(children: ...)` viewport dışındaki öğeleri erken (eager) inşa etmez (Sliver lazy
    realize eder) — uzun bir listede aşağıda kalan bir öğeye erişmek için
    `tester.scrollUntilVisible()` kullanılmalı.
  - **`tester.scrollUntilVisible()` YALNIZCA TEK YÖNDE kaydırabilir — `delta`nın işareti +
    `Scrollable.axisDirection`'a göre SABİT bir `moveStep` hesaplanır, önceki bir kaydırmayı asla
    "geri alamaz".** (`flutter_test`'in kendi `controller.dart` kaynağı: pozitif `delta`, dikey-aşağı
    bir listede İÇERİĞİ YUKARI sürükleyip listenin SONUNA doğru ilerler — asla başa dönmez.) Bir
    `find.text(...)` hedefi hâlâ ağaçta (offstage de olsa) MEVCUTSA ve daha önce o hedefin
    GERİSİNDEKİ bir noktaya kadar kaydırılmışsa, `dragUntilVisible` 50 deneme boyunca YANLIŞ yöne
    kaydırıp sonunda `Bad state: No element` ile çöker (gerçekten yaşandı — `profile_screen.dart`'a
    listenin SONUNA yeni bir satır eklenip toplam içerik artık tek ekrana sığmayınca, testin ÖNCEDEN
    karışık sırada [alttaki bir satır → üstteki bir satır] ziyaret ettiği satırlar bu yüzden
    kırıldı, bkz. "Google Hesap Bağlama" bölümü). **Bir dikey `ListView`/`Column` içindeki birden
    fazla satırı `scrollUntilVisible` ile ziyaret eden bir testte, satırları HER ZAMAN ekrandaki
    GERÇEK sırayla (yukarıdan aşağıya) ziyaret edin — geriye dönük bir sıralama önceden çalışıyor
    olsa bile (içerik henüz tek ekrana sığdığı için tesadüfen geçiyor olabilir), yeni içerik
    eklenince sessizce kırılabilir.**
  - `Timer.periodic` içeren widget'lar (örn. `MoneyScreen`) `isActive`-tarzı korumaya sahip
    olmalı, yoksa `IndexedStack` sekmeleri hiç dispose etmediği için testler "pending timer"
    hatasıyla başarısız olur.
  - `WidgetTester.pageBack()` bu Flutter sürümünde güvenilir değil — `find.byTooltip('Geri')`
    kullanmak daha tutarlı.
  - `RenderRepaintBoundary.toImage()` (bkz. Zibonu Paylaş) gerçek raster işine bağlı — Flutter'ın
    normal `pump`/`pumpAndSettle` mekanizması bunu Flutter frame'i olarak görmediği için beklemez.
    Bu yüzden onu tetikleyen bir buton testi `tester.runAsync(() async {...})` içinde çalıştırılmalı.
    Ayrıca `onPressed`'in statik dönüş tipi `void` olduğundan (gerçek tip `Future<void>`), butonun
    `onPressed!()`'ini doğrudan çağırıp sonucu `await` edemiyoruz — `pumpAndSettle()` da (yeni bir
    frame planlanmadığı için) işin bitmesini beklemeden erken dönebiliyor; tamamlanmayı gerçek
    zamanlı olarak (ör. sahte servisin çağrıldığını yoklayarak) beklemek gerekiyor
    (bkz. `zibo_share_sheet_test.dart`).
  - `showModalBottomSheet` içeriği (özellikle `SingleChildScrollView`'a sarılıysa) `tester.tap`'te
    koordinat hit-test uyuşmazlığı yaşayabilir — hem `find.text(...)` ile bir butonda (`FilledButton`
    → `onPressed!()` doğrudan çağır) hem de daha aşağıdaki bir `InkWell`'de (`find.ancestor(of:
    find.byType(AnimatedContainer).at(i), matching: find.byType(InkWell))` ile bulup `onTap!()`
    doğrudan çağır) görüldü (bkz. `zibo_share_sheet_test.dart`).
  - **`Image.asset()` bazen `pumpAndSettle()`'dan sonra bile yükseklik=0 raporlayabilir**, bu da
    `tester.tap(find.byKey(...))`'in hesapladığı merkezin görselin DIŞINA düşüp başka bir widget'ı
    vurmasına yol açar (`Ana Sayfa'daki Zibo görseline dokununca` testi böyle kırıldı — üç provider'a
    (Goals/Money/Coin) birden `SharedPreferences` tabanlı asenkron yükleme eklendikten sonra ortaya
    çıktı, muhtemelen açılışta artan eşzamanlı asenkron iş, görsel codec'inin decode'unu
    `pumpAndSettle()`'ın taradığı sahte-zaman çerçeve penceresinin dışına itiyor). Kanıtlanan sebep:
    `RenderImage`, görsel gerçekten decode OLMADAN doğal en-boy oranını bilemiyor ve o ana kadar
    yükseklik 0 kalıyor — `pumpAndSettle()` yalnızca Flutter FRAME'lerini bekler, gerçek codec/isolate
    işini beklemez (bkz. yukarıdaki `RenderRepaintBoundary.toImage()` gotcha'sıyla aynı kök neden).
    **Çözüm:** `pumpAndSettle()`'dan sonra `await tester.runAsync(() => Future.delayed(Duration(
    milliseconds: 100)))` ile kısa bir GERÇEK zaman beklemesi + bir `pumpAndSettle()` daha —
    ardından `tester.getRect(finder)` doğru boyutları raporluyor ve `tap()` doğru yeri buluyor. Bir
    görsele `tester.tap()` ile dokunan (özellikle o görsel yeni eklenmiş/az önce providers boot
    olmuşsa) her testte bu deseni göz önünde bulundurun.

## Şu an mock/placeholder olan şeyler (gerçek entegrasyon bekliyor)

- **`MockPurchaseService` ARTIK gerçek Play Billing'e bağlandı** (bkz. altta "Google Play Billing
  (IAP) Entegrasyonu" bölümü) — `MockPurchaseService` yalnızca testlerde enjekte edilen bir sahte
  olarak kaldı, `AdMob`/`MockAdService` ile AYNI geçiş.
  - **AÇIK KALAN GÜVENLİK BOŞLUĞU (henüz YAPILMADI — bkz. "Coin Ekonomisi Güvenliği" VE "Google
    Play Billing" bölümlerindeki AYNI not):** `InAppPurchasePurchaseService.purchaseCoinPackage()`
    hâlâ Google'ın SDK'sının "satın alma başarılı" (`PurchaseStatus.purchased`) durumuna GÜVENİYOR
    — makbuz Google Play Developer API'ye karşı SUNUCU TARAFINDA (Cloud Function/eşdeğer bir
    backend) doğrulanmıyor. Bu, "Coin Ekonomisi Güvenliği" bölümündeki `coinState` rules'unun
    KISMİ (şekil/monotonluk/delta) doğrulamasıyla AYNI mimari kısıtlamaya bağlı — TAM çözüm
    (Cloud Functions) kullanıcının henüz vermediği bir Blaze plan kararını gerektiriyor.
- Ayarlar'daki "Hakkında" satırı — `onTap` hâlâ no-op. **Dil satırı ARTIK no-op DEĞİL** (bkz.
  Yerelleştirme bölümü) — Coin Test Paneli de kullanıcı isteğiyle tamamen kaldırıldı, bu listede
  DEĞİL artık.
- İçerik havuzları (`zibo_messages.dart` vb., bkz. Yerelleştirme bölümü) artık TR/EN/ES üç dilde de
  var — ama hâlâ ARB'ye taşınmadı (bilinçli, uzun serbest metin havuzları için placeholder
  mekanizması gereksiz dolaylılık eklerdi).
- "Zibonu Paylaş" — `SharePlusService` gerçek (mock değil), ama yalnızca genel `share_plus`
  paylaşım menüsünü kullanıyor; Instagram/TikTok'un platforma özel "doğrudan Hikayeye gönder"
  API'leri (Instagram Share to Story, TikTok Share Kit) bilerek eklenmedi, ayrı bir aşamaya
  bırakıldı. Gerçek WhatsApp/Instagram/TikTok'a "el değiştirme" yalnızca gerçek bir mobil
  cihazda/emülatörde doğrulanabilir — web preview'da Chrome'un Web Share API dosya desteği
  tarayıcıya göre değişir.
- "Manifest Günlüğü" — `ImagePickerPhotoService` gerçek (mock değil), fotoğraflar kullanıcının
  isteğiyle BİLEREK yalnızca cihazda yerel olarak saklanıyor (bkz. "Manifest Günlüğü" bölümü);
  bir bulut/sunucu senkronizasyonu (yedekleme, cihazlar arası paylaşım) şimdilik kapsam dışı.
- **Firebase — Analytics + Auth (Anonymous) + Firestore, hepsi aktif.**
  `android/app/google-services.json` (kullanıcının Firebase konsolundan indirdiği, gerçek proje
  bilgisi) + `android/settings.gradle.kts`/`android/app/build.gradle.kts`'a eklenen
  `com.google.gms.google-services` Gradle plugin'i (v4.5.0) + `pubspec.yaml`'a eklenen
  `firebase_core`/`firebase_analytics`/`firebase_auth`/`cloud_firestore` paketleri (+ dev:
  `fake_cloud_firestore`, testler için). Kullanıcı verisi kalıcılığı ve güvenilir zaman artık
  Firestore'a da bağlı — bkz. "Firestore veri kalıcılığı, Anonymous Auth ve güvenilir zaman" bölümü.
  - **Yalnızca Android** için yapılandırıldı (`FirebaseOptions` elle verilmedi, Android'de
    `google-services` plugin'i bunu derleme zamanında JSON'dan otomatik üretiyor) — bu yüzden
    `Firebase.initializeApp()` ve sonrasındaki tüm Firebase çağrıları `main()`'de TEK bir
    try/catch'e sarılı: web önizlemesinde (ayrı bir `FirebaseOptions` yapılandırması YOK) veya
    ilerideki bir sorunda sessizce başarısız olup uygulamanın Firebase'siz (tamamen yerel modda)
    açılmaya devam etmesine izin veriyor.
  - `flutter test` bu koddan hiç etkilenmiyor çünkü testler `main()`'i hiç çalıştırmıyor
    (`DijitalKankaApp`'i doğrudan `pumpWidget` ediyorlar, `uid` varsayılan `null`).

