# ARŞİV — Ana Sayfa, söz sistemleri, Konuşma Balonu, Hedef Takibi, Zibo Coin, Mağaza

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 121–734).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

### Ana Sayfa ([home_screen.dart](lib/screens/home_screen.dart))
- Zibo görseline (varsayılan `assets/images/zibo_yeni.png`, veya `CostumeProvider.equippedId`
  giyiliyse ilgili kostüm görseli) dokununca zıplama+sallanma animasyonu (`TweenSequence`,
  `AnimationController`) oynar ve konuşma balonunda rastgele yeni bir mesaj gösterilir
  (`lib/data/zibo_messages.dart` içindeki ~100 mesajlık havuzdan, art arda aynı mesaj gelmeyecek
  şekilde).
- Sol kenarda, yalnızca bu sekmedeyken görünen `WheelTriggerButton` (bkz. "Şans Çarkı" bölümü) var —
  `RootScreen`'de `_selectedIndex == 0` koşuluyla gösteriliyor.
- **Kaldırıldı:** Üstteki "X gün üst üste" etiketi (`streakLabel` ARB anahtarı) tamamen silindi —
  sabit `1` değeriyle gösterildiği ve gerçek bir "günlük seri" kaynağına bağlı olmadığı için kafa
  karıştırıyordu. Gerçek genel bir günlük seri kavramı eklenmek istenirse Hedef Takibi'ndeki per-goal
  7 günlük döngüden ayrı, `GoalsProvider`'daki verilerden türetilebilir bir şey olarak yeniden ele
  alınmalı.
- **2026 bug düzeltmesi — uygulama HER açılışta havuzdaki AYNI (ilk) sözle başlıyordu.** Kullanıcı
  raporu: "hep aynı söz ile başlıyor". Kök neden: `_HomeScreenState._messageIndex`'in başlangıç
  değeri sabit `0`'dı — `_pickNewMessageIndex()`'in "art arda aynı mesaj gelmesin" garantisi yalnızca
  Zibo'ya DOKUNULDUĞUNDA devreye giriyordu, İLK gösterim hiç rastgele değildi. **Düzeltme:**
  `_messageIndex` artık `Random().nextInt(1 << 16)` ile rastgele bir başlangıç değeri alıyor —
  `build()`'deki `_messageIndex % messagePool.length` zaten her büyüklükteki değeri geçerli bir
  indekse indirgediği için üst sınırın kesin değeri önemsiz. **Test etkisi:** `widget_test.dart`'taki
  başlangıç sözünü `ziboMessagesTr.first`'e sabit varsayan üç test (+ favorileme testindeki bir
  değişken ataması) artık `_currentHomeMessage(tester)` (YENİ yardımcı — `SpeechBubble`'ın İÇİNDEKİ
  `Text`'i doğrudan okuyor) ile o anki GERÇEK mesajı okuyup üyelik/eşitlik kontrolü yapıyor, belirli
  bir sabit metne güvenmiyor.
  > **TARİHSEL — bu bug düzeltmesindeki `_messageIndex`/`_pickNewMessageIndex()` artık kod
  > tabanında YOK, altta belgelenen "Motivasyon Sözü Sistemi"nin `_currentQuote`/`_pickAndSetQuote`
  > çiftiyle DEĞİŞTİRİLDİ** — kök neden analizi (ilk sözün rastgele başlaması gerektiği) hâlâ
  > geçerli, yeni sistem de AYNI garantiyi (rastgele başlangıç + art arda tekrarsızlık) koruyor.

#### Motivasyon Sözü Sistemi — zaman dilimi + ruh hali ağırlıklı seçim ([motivation_pools.dart](lib/data/motivation_pools.dart), [motivation_quote_selector.dart](lib/utils/motivation_quote_selector.dart))

- **2026 yeni özellik.** Kullanıcı isteği (verbatim özet): Zibo'nun sözü artık cihazın YEREL
  saatine göre zaman dilimine (sabah/öğle/akşam/gece) duyarlı olsun, kullanıcının EN SON kaydettiği
  ruh haline göre de tavrı değişsin (düşük ruh halinde teselli edici, yüksekte enerjiyi
  pekiştirici), ama TEK DÜZE olmasın — ağırlıklı bir karışım (zaman %50-60, ruh hali %20-30, kalan
  genel havuzdan) + kısa süreli tekrar-önleme. Kullanıcı masaüstünde yedi TXT dosyası hazırladı
  (`sozler_sabah/ogle/aksam/gece.txt` + `sozler_dusuk/notr/yuksek_ruhhali.txt`, 51'er satır) —
  bunlar `lib/data/motivation_pools.dart`'a elle aktarıldı.
  - **Kapsam BİLEREK dar tutuldu — yalnızca Ana Sayfa'nın Zibo konuşma balonu.**
    `zibo_messages.dart`'ın 279 sözü ATILMADI — "genel/rastgele" dilimin kaynağı olarak KALDI
    (kullanıcının "kalan yüzde genel havuzdan gelsin" isteğiyle birebir). Ruh Hali Takibi
    ekranının KENDİ küçük, ilgisiz `mood_quotes.dart` havuzu (10 söz, Timer'lı rotasyon)
    DEĞİŞMEDİ — o ekrana yalnızca aşağıdaki not alanı eklendi.
  - **Zaman dilimi — DÜZ `DateTime.now()`, `TrustedTimeProvider` DEĞİL.**
    `TrustedTimeProvider.now()` cihaz saati manipülasyonuna karşı (günlük ödül/streak gibi
    GÜVENLİK-kritik özellikler için) `Stopwatch`+doğrulanmış-UTC-çıpa tabanlı — kullanıcı FARKLI
    bir saat dilimine seyahat ederse bu çıpa yeni yerel saate otomatik uymayabilir. Bu özellik
    kozmetik/UX amaçlı (güvenlik DEĞİL) ve kullanıcı AÇIKÇA "cihazın kendi saatine göre... hangi
    ülkede olursa olsun" dediği için BİLEREK düz `DateTime.now()` kullanıldı —
    `timeBucketFor(DateTime)` saat sınırları: Sabah 05:00-11:59, Öğle 12:00-17:59, Akşam
    18:00-21:59, Gece 22:00-04:59 (elle seçilen makul varsayılanlar).
  - **`motivation_pools.dart`** — `zibo_messages.dart`'ın AYNI `xTr/En/Es` + `xForLocale` deseni,
    yedi havuz için. **2026 güncellemesi — İngilizce/İspanyolca havuzlar da dolduruldu** (kullanıcı
    isteği: "İngilizce İspanyolcaya sen çevir otomatik söz havuzlarını") — `zibo_messages.dart`'taki
    AYNI felsefeyle (kelimesi kelimesine ÇEVİRİ değil, Zibo'nun sıcak/samimi tonunu o dilde doğal
    duracak şekilde koruyan bir UYARLAMA) TR'den EN/ES'e asistan tarafından uyarlandı — kaynak TR
    havuzlarında "Kanka" hiç geçmediği için (grep ile doğrulandı) EN/ES uyarlamalarında da BİLEREK
    bir hitap kelimesi (Buddy vb.) zorlanmadı. `timeBucketQuotes`/`moodPoolQuotes`'un HER POOL'U
    AYRI AYRI kontrol edip boşsa Türkçe'ye düşen mekanizması KOD TARAFINDA hâlâ duruyor (ileride
    tek bir dil/havuz eksik kalırsa yine devreye girer) ama şu an fiilen TÜM 21 havuz (7×3 dil)
    dolu.
    - **Gerçek bug, testte yakalandı — çeviri sırasında İKİ ayrı kopyala-yapıştır tekrarı
      oluşmuştu.** `motivationNeutralMoodTr`'deki İKİ FARKLI Türkçe cümle ("...hedef koymaya ne
      dersin?" / "...hedef belirlemeye ne dersin?") hem İngilizce'ye hem İspanyolca'ya YANLIŞLIKLA
      AYNI tek cümleye uyarlanmıştı — `test/motivation_quote_selector_test.dart`'a eklenen
      "havuz bütünlüğü" testi (`pool.toSet().length == pool.length`, `zibo_messages.dart`'a yeni
      söz eklenirken kurulan AYNI convansiyon) bunu GERÇEK Dart string eşitliğiyle yakaladı —
      düzeltildi (`"How about setting yourself a goal today?"` → ikinci geçiş `"How about deciding
      on a goal for yourself today?"`e, İspanyolca karşılığı da benzer şekilde ayrıştırıldı). **Bu
      turdan itibaren TÜM 21 havuz (357×3=1071 satır) `pool.toSet().length == 51` testiyle
      KAPSANIYOR** — ileride yeni bir çeviri/uyarlama turu yapılırsa aynı testi çalıştırmak
      benzer kopyala-yapıştır hatalarını anında yakalar.
  - **`MoodEnergy.isHighEnergy`** (`models/mood.dart`, YENİ) — mevcut `MoodLowness.isLow`'un
    (index<=1) simetriği (index>=3). `moodPoolTagFor(Mood?)` bu ikisiyle üç havuza eşliyor:
    low={veryUnhappy,unhappy}, neutral={neutral, VEYA hiç kayıt yoksa}, high={happy,veryHappy}.
    Kullanılan ruh hali `MoodProvider.entries.first.mood` (liste zaten en-yeni-önce sıralı) —
    kullanıcının "SON ruh hali kaydına göre" isteğiyle birebir, `todayMood` gibi yalnızca bugünle
    SINIRLI DEĞİL (bugün kayıt yoksa en son GEÇMİŞ kayda düşer).
  - **`pickMotivationQuote(...)`** (`motivation_quote_selector.dart`) — saf, test edilebilir bir
    fonksiyon (enjekte edilebilir `DateTime`/`Random`, `wheel_prizes.dart`'taki `pickWeightedPrize`
    ile AYNI felsefe). Ağırlıklar: %55 zaman dilimi, %25 ruh hali, %20 genel (kullanıcının "%50-60/
    %20-30" aralığının ortası). **`recentLowMoodRatio(entries, now)`** — son 14 günün ne kadarının
    "düşük" olduğunu 0.0-1.0 oranla hesaplayan SAF bir fonksiyon (AI/network YOK, kullanıcının
    "gerçek bir yapay zeka değil, biriken veriye dayalı basit bir ağırlıklandırma" isteğiyle
    birebir) — oran 0.5'i geçerse ruh hali payına "hafifçe" (+10 puan) bir kişiselleşme nüansı
    ekleniyor (zaman diliminden yarısı + genelden yarısı düşülerek).
  - **Tekrar-önleme — `MotivationQuotePick.id` (`"time:morning:12"` gibi) tabanlı, sonsuz döngüye
    KARŞI KORUMALI.** `_pickFrom` bir havuzdan `recentIds`'te olmayan bir index'i EN FAZLA 20
    denemede arıyor; bulunamazsa (havuz küçük + neredeyse tamamı hariç) hariç tutmayı YOK SAYIP
    yine de bir sonuç dönüyor — `HomeScreen`'in eski `_pickNewMessageIndex()`'indeki
    `do-while` deseninin (sabit bir test `Random`'ı ile SONSUZ DÖNGÜYE girebildiği, bkz. yukarıdaki
    "Zibo'ya Art Arda Dokunma" bölümündeki `adPromoRandom` notu) AYNI dersinin bir daha
    tekrarlanmaması için BİLEREK sınırlı deneme sayısıyla tasarlandı.
  - **KRİTİK tasarım kararı — `_currentQuote` sözün METNİNİ DEĞİL, KİMLİĞİNİ tutuyor.**
    `MotivationQuotePick{source, tag, index}` — `resolveMotivationQuoteText(pick, locale,
    generalPool)` her `build()`'de o anki `locale`'e göre metni YENİDEN çözüyor. **Neden:**
    projedeki TÜM diğer locale-portable söz sistemleri (`_quoteIndex` deseni, bkz. "Yerelleştirme"
    bölümü) bir sözü "hangi havuzun kaçıncı elemanı" olarak saklayıp gösterim anında o anki dile
    göre metni tazeliyor — TEXT'i sabitlemiş olsaydık, kullanıcı bir söz ekrandayken dili
    değiştirirse (Ayarlar > Dil) konuşma balonu ESKİ dildeki metinde DONUP kalırdı. `pick.index`
    havuz boyutundan büyükse (dil değişince farklı uzunlukta bir havuza düşülürse) `%` ile güvenle
    sarılıyor — projenin diğer TÜM locale-portable indekslerindeki AYNI güvenlik deseni.
  - **`HomeScreen._pickAndSetQuote()`** hem `initState()`'te DEĞİL ilk `build()`'de (`_currentQuote
    == null` koşuluyla, `context`'e — locale/ruh hali/özel mesajlar — ihtiyaç duyduğu için) HEM
    `_onZiboTap()`'te (dokunuşta, `setState` içinde) çağrılıyor — `initState()`'in `context`
    kullanmaması gereken erken zamanlama kısıtlamasını bu şekilde aştı, `setState` OLMADAN (build()
    zaten AYNI çağrıda taze değeri kullanacağı için) doğrudan alan mutasyonu yapıyor.
  - **Test:** YENİ `test/motivation_quote_selector_test.dart` — `timeBucketFor` sınır saatleri
    (04:59/05:00/11:59/12:00/17:59/18:00/21:59/22:00), `moodPoolTagFor` beş `Mood` + `null`,
    `resolveMotivationQuoteText`'in üç kaynağı da doğru çözdüğü + havuz taşmasında `%` güvenliği +
    boş EN havuzunda TR'ye düştüğü, `pickMotivationQuote`'un sabit `Random` ile deterministik
    kaynak seçtiği, tekrar-önlemenin gerçekten hariç tuttuğu, TÜM havuz hariç tutulunca sonsuz
    döngüye GİRMEDEN (testin kendisi TAMAMLANMASI zaten bunun kanıtı) bir sonuç döndüğü,
    `recentLowMoodRatio > 0.5` iken ruh hali payının GERÇEKTEN büyüdüğü. **Gotcha (gerçekten
    yaşandı) — `home_screen_rapid_tap_test.dart`/`home_screen_sound_test.dart` (HomeScreen'i
    minimal bir `MultiProvider` ağacında izole test eden iki dosya) `MoodProvider`'ı hiç
    sağlamıyordu** — `HomeScreen` artık `_pickAndSetQuote()` içinde `context.read<MoodProvider>()`
    çağırdığı için bu iki dosyadaki TÜM testler `ProviderNotFoundException` ile (ağaç hiç
    render OLMADAN, `find.byKey('ziboCharacterImage')` "0 widget bulundu" diye çöktü) başarısız
    oldu — düzeltme her ikisine de `ChangeNotifierProvider(create: (_) => MoodProvider())`
    eklemekti. **Ders (proje genelinde tekrarlayan bir kalıp):** `HomeScreen`'e yeni bir
    `context.read<X>()`/`context.watch<X>()` bağımlılığı eklerken, `HomeScreen`'i MİNİMAL bir
    provider ağacında (TAM `DijitalKankaApp` DEĞİL) kuran TÜM test dosyalarını (`grep -rl
    "HomeScreen(" test/`) kontrol edin — `widget_test.dart`'ın `_buildAppWithClock`/`RootScreen`
    kuralından FARKLI, AYRI bir "minimal ağaç" kategorisi bu.
  - **Gerçek cihazda doğrulama bu turda YAPILMADI** — bu özellik saf Dart/UI (native tarafa hiç
    dokunmuyor), `flutter test` (tam suite, yalnızca ÖNCEDEN belgelenmiş `audioplayers` flake'i
    hariç) + `flutter build apk --debug` (sorunsuz) ile doğrulandı, düşük risk kabul edildi.
    **Kullanıcının kendi cihazında doğrulaması gereken:** farklı saatlerde (özellikle gece/sabah
    sınırında) Ana Sayfa'yı açıp sözün beklenen zaman dilimine uygun geldiği, bir ruh hali kaydı
    girdikten sonra Zibo'nun tavrının (düşükte teselli edici, yüksekte enerjik) gerçekten
    hissedilir şekilde değiştiği, VE — EN/ES havuzları artık dolu olduğu için ARTIK GERÇEKTEN test
    edilebilir — dil İngilizce/İspanyolca'ya çevrilince ekrandaki sözün ANINDA (bir sonraki
    dokunuşta) o dildeki karşılığına geçtiği.

#### Olay Tetiklemeli Özel Mesajlar ([zibo_event_signal.dart](lib/utils/zibo_event_signal.dart), [zibo_event_messages.dart](lib/data/zibo_event_messages.dart))

- **2026 yeni özellik.** Kullanıcı isteği: zaman/ruh hali havuzlarına ek olarak, belirli ANLARA
  özel, ayrı bir mesaj seti — bu mesajlar rastgele havuzdan DEĞİL, doğrudan olay gerçekleştiğinde
  tetiklensin ve normal ağırlıklı seçimin ÖNÜNE geçsin: (1) hedef/döngü tamamlandığında (7/7),
  (2) streak kırıldığında (kaçırılan gün), (3) yeni bir kostüm/tema açıldığında, (4) 7/30 günlük
  streak bonusuna ulaşıldığında.
- **Mimari — dört olayın DÖRDÜ de Ana Sayfa'nın KENDİSİNDE DEĞİL, BAŞKA ekranlarda
  gerçekleşiyor** (Hedef Takibi, Mağaza, Günlük Giriş Ödülleri) — bu yüzden `motivation_quote_
  selector.dart`'ın ağırlıklı seçimine YENİ bir "olay" kaynağı eklemek yerine (o fonksiyon hâlâ
  yalnızca zaman/ruh hali/genel arasında seçim yapıyor, HİÇ değişmedi), TAMAMEN AYRI, basit bir
  sinyal mekanizması kuruldu:
  - **`pendingZiboEvent`** (`utils/zibo_event_signal.dart`) — `tab_navigation.dart`'taki
    `homeTabRequest`/`isHomeTabActive` ile AYNI "basit, kalıcılık gerektirmeyen, widget ağacının
    dışından da yazılabilen global `ValueNotifier`" deseni. `ZiboEventType` enum'u dört değeri
    taşıyor. **Kalıcı DEĞİL** (uygulama kapanırsa kaybolur) — `_recentZiboTaps` gibi diğer
    oturum-içi durumlarla AYNI bilinçli basitleştirme, bu kozmetik bir özellik. **Tek bir slot,
    kuyruk DEĞİL** — aynı anda birden fazla olay gerçekleşirse yalnızca EN SON olay gösterilir.
  - **`zibo_event_messages.dart`** — `motivation_pools.dart`'ın AYNI `xTr/En/Es` + per-pool
    Türkçe geri düşüş deseni (şimdilik yalnızca Türkçe dolu, EN/ES BİLEREK BOŞ — `motivation_
    pools.dart`'ın İLK sürümüyle AYNI, ileride ayrı bir çeviri turunda doldurulabilir). Dört
    havuz: `goalCycleCompleted`/`streakBroken` (10-15'er söz, kullanıcının istediği aralık),
    `costumeOrThemeUnlocked`/`loginStreakBonus` (5-10'ar söz).
  - **`MotivationQuotePick.source`'a DÖRDÜNCÜ bir değer eklendi: `'event'`** —
    `resolveMotivationQuoteText`'in switch'ine `'event' => eventMessagesForLocale(...)` bir
    `case` daha eklendi, mevcut `'time'`/`'mood'`/`'general'` dallarına HİÇ dokunulmadı.
  - **`HomeScreen._pickAndSetQuote()`** artık İLK İŞ olarak `pendingZiboEvent.value`'u kontrol
    ediyor — `null` DEĞİLSE, normal `pickMotivationQuote` ağırlıklı seçimi TAMAMEN ATLANIP
    doğrudan o olayın özel havuzundan rastgele bir söz seçiliyor, VE olay ANINDA TÜKETİLİYOR
    (`pendingZiboEvent.value = null`) — bir SONRAKİ seçimde (dokunuş) normal akışa dönülüyor.
  - **`HomeScreen`'e YENİ bir `initState()`/`dispose()` çifti eklendi** — `pendingZiboEvent.
    addListener(_onPendingZiboEventChanged)`: olay BAŞKA bir ekranda tetiklendiğinde, Ana Sayfa
    `IndexedStack` içinde GÖRÜNMÜYOR bile olsa konuşma balonu ANINDA (kullanıcı sekmeyi
    değiştirmeden ÖNCE) güncelleniyor — aksi halde olay yalnızca kullanıcı Zibo'ya GERÇEKTEN
    dokunursa görünürdü, bu da "hedefimi tamamladım, Ana Sayfa'ya döndüğümde Zibo beni kutlasın"
    beklentisini karşılamazdı.
- **Altı tetikleme noktası, hepsi tek satırlık bir `pendingZiboEvent.value = ZiboEventType.X;`
  eklemesi:**
  1. `GoalCard._onTodayTap` — `cycleCompleted == true` iken (`earnStreak7Bonus()`'un HEMEN
     yanına) → `goalCycleCompleted`.
  2. `GoalTrackingScreen._reconcileForToday` — `resetNames.isNotEmpty` iken (mevcut "döngü
     sıfırlandı" SnackBar'ından HEMEN ÖNCE) → `streakBroken`.
  3. `CostumeCard._buy` — `markOwned` çağrısından HEMEN SONRA → `costumeOrThemeUnlocked`.
  4. `ThemeOptionCard._buy` — AYNI desen → `costumeOrThemeUnlocked`.
  5. `StoreScreen._maybeReconcileCostumeUnlocks` — `unlockedIds.isNotEmpty` iken (hedefle ÜCRETSİZ
     kostüm açma yolu, satın almadan AYRI) → `costumeOrThemeUnlocked`.
  6. `DailyRewardsScreen._claimDay` — `index == 6` (Gün 7, döngünün EN BÜYÜK tek günlük ödülü)
     iken → `loginStreakBonus`.
  - **7. — `CoinProvider.earnStreak30Bonus()` — GELECEĞE HAZIRLIK, BUGÜN HİÇBİR YERDEN
    ÇAĞRILMIYOR.** `CoinEconomy.streak30Bonus` (250 ZC) tanımlı ama bu metot kod tabanında
    HİÇBİR YERDEN tetiklenmiyordu (gerçek bir "30 günlük" mekanik hiç İCAT EDİLMEMİŞTİ) —
    kullanıcının "7 günlük VEYA 30 günlük streak bonusu" isteğini TAM karşılamak için YENİ bir
    30-günlük takip mekaniği İCAT ETMEK yerine (bu, mesaj eklemenin çok ötesinde bir oyun-
    ekonomisi tasarım kararı olurdu), BİLİNÇLİ bir kapsam kararı: `earnStreak30Bonus()`'un
    GÖVDESİNE `pendingZiboEvent.value = ZiboEventType.loginStreakBonus;` eklendi — böylece
    ileride biri bu metodu GERÇEKTEN bir yere bağlarsa (ör. `GoalsProvider.completions.length`
    30'a ulaşınca), mesaj sistemi otomatik olarak doğru çalışacak, ayrı bir kablolama
    GEREKMEYECEK. **"7 günlük" kısmı** `loginStreakBonus`'un GERÇEK tetikleyicisi olan Günlük
    Giriş Ödülleri'nin Gün 7'si üzerinden ZATEN karşılanıyor (yukarıdaki 6. madde) — Hedef
    Takibi'nin KENDİ 7/7 döngüsü (`goalCycleCompleted`, 1. madde) BİLEREK AYRI tutuldu, ikisi
    farklı ekranlar/farklı kavramlar (bir alışkanlığı bir hafta sürdürmek vs. uygulamayı bir
    hafta art arda açmak).
- **Mesaj metinleri Zibo'nun mevcut sesinden (motivation_pools.dart) türetildi** — sıcak,
  samimi, ikinci tekil şahıs ("sen"), abartısız. `streakBroken` havuzu ÖZELLİKLE suçlamayan bir
  dille yazıldı (kullanıcının açık isteği) — "neden yapamadın" tarzı hiçbir ifade YOK, yalnızca
  "bu normal, devam edelim" çerçevesi.
- **Test:** `motivation_quote_selector_test.dart`'a YENİ gruplar — `zibo_event_messages.dart`
  havuz bütünlüğü (her havuz kullanıcının istediği aralıkta [10-15/5-10] VE tekrarsız, EN/ES
  şimdilik TR'ye düştüğü), `resolveMotivationQuoteText`'in `'event'` kaynağını doğru çözdüğü.
  YENİ `test/home_screen_event_message_test.dart` (`home_screen_sound_test.dart`'taki
  "bağımsız test uygulaması" deseniyle, 3 test): Ana Sayfa açılmadan ÖNCE kuyruğa alınan bir
  olay İLK karede kendi özel havuzundan bir mesaj gösterip ANINDA tükeniyor; Ana Sayfa ZATEN
  AÇIKKEN kuyruğa alınan bir olay dokunmaya GEREK KALMADAN otomatik görünüyor (`initState`
  listener'ının kanıtı); olay tüketildikten SONRA Zibo'ya dokunmak normal (olay havuzu
  DIŞINDAKİ) bir söze dönüyor. **Gotcha (test) — `find.descendant(..., matching: find.byType
  (Text))` `AnimatedSwitcher`'ın fade GEÇİŞİ SÜRERKEN İKİ `Text` bulup "Too many elements"
  hatası verdi** (`speech_bubble.dart`'ın 320ms'lik fade animasyonu — bkz. "Konuşma Balonu"
  bölümü) — `pendingZiboEvent.value` DEĞİŞTİRİLDİKTEN sonra tek bir `pump()` yerine
  `pumpAndSettle()` kullanmak (geçişin TAMAMLANMASINI beklemek) düzeltti.
- **Gerçek cihazda doğrulama bu turda YAPILMADI** — `flutter test` (tam suite, yalnızca önceden
  belgelenmiş `audioplayers` flake'i hariç) + `flutter build apk --debug` ile doğrulandı. Altı
  tetikleme noktasının kendisi (tek satırlık ekler, çağıran kodun geri kalanı hiç değişmedi)
  ayrı ayrı test EDİLMEDİ — bunun yerine `pendingZiboEvent`'in TÜKETİLME/GÖSTERİLME mekanizması
  (asıl karmaşıklığın olduğu yer) kapsamlı test edildi, tetikleme noktaları kod incelemesiyle
  doğrulandı.

#### Ruh Hali Notundan Anahtar Kelime Çıkarımı ([mood_note_keywords.dart](lib/utils/mood_note_keywords.dart))

- **2026 yeni özellik.** Kullanıcı isteği: ruh hali notundaki serbest metinde basit bir anahtar
  kelime taraması yap (TR/EN/ES temel kelime listeleri), tespit edilince havuzdaki ilgili alt
  temaya sahip sözlerin çıkma olasılığını hafifçe artır — **gerçek AI/NLP KULLANILMADI**,
  `dream_sentiment.dart`'taki (Rüya Günlüğü ↔ Ruh Hali Takibi korelasyonu) BİREBİR AYNI desen:
  kısa gövdeler (kökler), TR+EN+ES BİRLİKTE taranıyor (kullanıcı notu hangi dilde yazdığını
  bilemeyiz), büyük/küçük harf duyarsız `contains` taraması.
- **`moodNoteKeywordBias(String? note)`** — İKİ kategori (`MoodPoolTag.low`/`high`, `neutral`
  için kelime listesi YOK çünkü zaten hiçbir sinyal bulunamadığında dönülen varsayılan): not
  hem düşük hem yüksek kelime içeriyorsa (çelişkili) VEYA boşsa/`null`sa `null` döner.
- **`pickMotivationQuote`'a YENİ, opsiyonel bir `latestMoodNote` parametresi eklendi**
  (varsayılan `null`, geriye dönük TAM uyumlu — mevcut TÜM testler DEĞİŞMEDEN geçmeye devam
  ediyor). Kararın kalbi — **not, SEÇİLEN emoji'den TÜRETİLEN etiketle ÇELİŞİYORSA** (ör. emoji
  "nötr" ama not "sınavdan çok yorgun geldim" diyorsa) İKİ şey oluyor:
  1. Mood havuzu artık emoji'nin DEĞİL, notun işaret ettiği (`effectiveMoodTag`) etiketten
     besleniyor — notun GÜNCELLİĞİ/özgüllüğü, birkaç saat/gün önce seçilmiş tek bir emoji'den
     daha güvenilir bir "şu an nasıl hissediyor" sinyali sayıldı.
  2. Ruh hali payına [recentLowMoodRatio] ile AYNI büyüklükte (+8 puan, kullanıcının "hafifçe"
     ifadesiyle tutarlı) EK bir nüans daha ekleniyor — notun GERÇEKTEN bir sonuç doğurduğunu
     garantiliyor, yalnızca "kaydedilip görmezden gelinen" bir alan olmuyor.
  - **Not YOKSA/boşsa VEYA emoji'yle ZATEN AYNI yöndeyse VEYA kendi içinde çelişkiliyse**
    (`moodNoteKeywordBias` `null` döner) davranış TAMAMEN DEĞİŞMİYOR — bu üç durumda
    `effectiveMoodTag == moodTag` ve `moodBoost` sıfır, mevcut testlerin HİÇBİRİ etkilenmedi.
- **Test:** `motivation_quote_selector_test.dart`'a YENİ gruplar — `moodNoteKeywordBias` (null/
  boş not, düşük/yüksek kelime eşleşmesi TR+EN+ES, bilinmeyen metin, çelişkili not), 
  `pickMotivationQuote — anahtar kelime çıkarımı` (not emoji ile AYNI yöndeyse davranış
  DEĞİŞMEZ, ÇELİŞİYORSA mood havuzu notun etiketine göre çözülür, çelişkili not hiçbir şeyi
  DEĞİŞTİRMEZ) — üçü de `_ScriptedRandom` ile elle hesaplanmış ağırlık matematiğine göre
  DETERMİNİSTİK doğrulandı (roll'ün hangi dala düştüğü + hangi etiketin kullanıldığı).

#### Söz Havuzlarının Genişletilmesi — 175 yeni söz EKLENDİ (51 → 76/havuz, ÜÇ dilde de)

- **2026 — kullanıcı isteği: "her havuz için 25'er yeni söz öner, ayrı bir dosyada topla, ben
  önce onaylayayım."** Yedi havuzun (sabah/öğle/akşam/gece/düşük/nötr/yüksek) mevcut 51 sözünün
  tonu/üslubu (Zibo'nun sıcak, samimi, motive edici ama abartısız kişiliği) analiz edilip HER
  HAVUZ İÇİN 25 yeni söz (toplam 175) yazılıp [yeni_sozler_onerileri.txt](yeni_sozler_onerileri.txt)
  dosyasında (hangi havuza ait olduğu belirtilerek) kullanıcıya sunuldu.
- **Mekanik doğrulama — geçici bir betikle (kontrolden sonra silindi):** her havuzun 25 yeni
  sözünün (a) KENDİ İÇİNDE tekrarsız olduğu, (b) mevcut 51 sözle TAM olarak ÇAKIŞMADIĞI, gerçek
  Dart string eşitliğiyle (regex ile her iki dosyadan ayrıştırılıp `Set` karşılaştırması)
  doğrulandı — `pool.toSet().length` testlerindeki AYNI "yalnızca metin `grep`'ine güvenme"
  dersi. **Yakın-benzerlik/anlamsal tekrar** (ör. aynı fikrin farklı kelimelerle ifadesi) bu
  mekanik kontrolün YAKALAYAMADIĞI bir şey — yalnızca insan gözden geçirmesiyle elenebilir,
  kullanıcının onay adımı tam olarak bunun içindi.
- **Kullanıcı TÜMÜNÜ onayladı ("sözleri ekle hoşuma gitti") — 175 sözün HEPSİ, HİÇBİR düzenleme
  YAPILMADAN, `motivation_pools.dart`'taki ilgili yedi `motivationXTr` listesinin SONUNA
  eklendi** (her havuz 51 → 76 söz, `// --- 2026 güncellemesi: kullanıcı onayıyla eklenen 25
  yeni söz ---` yorumuyla ayrılmış bloklar halinde — hangi sözlerin bu turda eklendiği kod
  içinde de görünür kalsın diye). `yeni_sozler_onerileri.txt` SİLİNMEDİ, yalnızca başına
  "DURUM: eklendi" notu eklenip tarihsel bir kayıt olarak bırakıldı.
- **2026 İKİNCİ güncelleme — 175 sözün TAMAMI aynı oturumda İngilizce/İspanyolca'ya da
  çevrildi ("evet çevir" isteği).** `motivation_pools.dart`'ın önceki EN/ES çevirisinde
  kurulan AYNI felsefe (kelimesi kelimesine ÇEVİRİ değil, Zibo'nun tonunu koruyan bir
  UYARLAMA; kaynakta "Kanka" geçmediği için EN/ES'te de bir hitap kelimesi zorlanmadı — bu
  175 sözün TR halinde de "Kanka" hiç geçmediği `grep` ile doğrulandı) BİREBİR tekrarlandı.
  21 EN/ES havuzunun HER BİRİNE kendi 25 çevirisi eklendi — artık TÜM 21 havuz (7×3 dil)
  yeniden AYNI uzunlukta (76).
- **`motivation_quote_selector_test.dart`'taki "havuz bütünlüğü" testleri güncellendi** —
  `checkPool` yardımcısındaki `expectedLength` parametresi TÜM 21 havuz için `76`'ya
  çıkarıldı. `resolveMotivationQuoteText`/`pickMotivationQuote` testleri (`motivationMorningTr
  [0]` gibi DİNAMİK referanslar kullanıyorlar, sabit "51"/"76" HİÇ geçmiyor) hiçbir değişiklik
  GEREKTİRMEDİ.
- **Bu turda GERÇEK bir duplicate-çeviri hatası YAKALANMADI** — `pool.toSet().length ==
  hasLength(76)` testinin HER 21 havuzda da (7 TR + 7 EN + 7 ES) sorunsuz geçmesi, 351
  yeni satırın (175 EN + 175 ES) hiçbirinin kendi havuzu İÇİNDE birebir tekrar ETMEDİĞİNİN
  somut kanıtı — önceki EN/ES çeviri turunda (`motivation_pools.dart`'ın İLK 51'lik
  çevirisinde) İKİ tane böyle hata bulunup düzeltilmişti, bu sefer TEMİZ çıktı.
- **Doğrulama:** `flutter test` — tam suite, yalnızca önceden belgelenmiş `audioplayers`
  flake'i hariç yeşil (425 test, sayı DEĞİŞMEDİ — yeni test EKLENMEDİ, yalnızca mevcut 21
  "havuz bütünlüğü" testinin BEKLENEN UZUNLUĞU güncellendi). `flutter build apk --debug`
  sorunsuz. **Gerçek cihazda GÖRSEL doğrulama YAPILMADI** — dil değiştirip 175 yeni sözün
  İngilizce/İspanyolca karşılıklarının Ana Sayfa'da GERÇEKTEN göründüğünü kullanıcı zaman
  içinde (havuz 76 söz olduğu için tek bir oturumda hepsini görmek beklenmiyor) kendi
  cihazında gözlemleyebilir.

### Konuşma Balonu ([speech_bubble.dart](lib/widgets/speech_bubble.dart))
- **2026 bug düzeltmesi — kısa sözlerde favori/paylaş/söz-ekle butonları metnin ÜSTÜNE biniyordu.**
  Kullanıcı raporu: "cümle kısa ise çok küçülüyor... butonlar cümleyle iç içe giriyor." Kök neden:
  `SpeechBubble` (8 ekranda paylaşılan tek widget — Ana Sayfa, Hedef Takibi, Para ve Birikim, Su
  Takibi, Rüya/Şükran/Ruh Hali/Manifest günlükleri) `CustomPaint`'in çocuğuna (`Text`) göre
  boyutlanıyordu — kısa bir söz geldiğinde balon küçülürken, köşelerine bindirilmiş 36×36 butonlar
  (`Positioned(top/bottom: -6, ...)`, bkz. `home_screen.dart`'taki `Stack`) sabit boyutlarını
  koruyup metnin üstüne taşıyordu. **Düzeltme:** `ConstrainedBox(minWidth: 240, minHeight: 100)`
  eklendi — balon bu köşe butonlarının rahat durabileceği bir ALT sınırın altına asla düşmüyor, ÜST
  sınır YOK (uzun sözler eskisi gibi serbestçe büyümeye devam ediyor). **Aynı turda eklenen ikinci
  iyileştirme** (kullanıcı isteği: "değişen cümlelere bir animasyon ekleyebiliriz... sen seç") —
  söz değiştiğinde ani bir "flaş" yerine yumuşak bir FADE (`AnimatedSwitcher`, 320ms,
  `ValueKey(message)`); shake yerine fade seçildi çünkü rutin bir söz rotasyonu için daha sakin/şık
  duruyor, shake daha çok hata/dikkat-çekme çağrışımı yapardı.
  - **Test etkisi — minimum boyut bazı ekranlarda içeriği viewport'un altına itti:**
    `manifest_journal_screen_test.dart`'ta büyüyen balon "Kaydet" `FilledButton`'ını gerçekçi telefon
    viewport'unda `ListView`'ın lazy-realize penceresinin dışına itti — `find.byType(FilledButton)`
    (varsayılan `skipOffstage: true`) onu bulamıyordu. Çözüm KAYDIRMAK değil (`onPressed`'i yalnızca
    OKUYUP/doğrudan ÇAĞIRDIĞIMIZ için gerçek bir hit-test'e hiç gerek yok)
    `find.byType(FilledButton, skipOffstage: false)` kullanmaktı.
  - **Test etkisi — fade animasyonu, bazı testlerin `Timer.periodic(5sn)` + BÜYÜK-adımlı
    `pump`/`pumpAndSettle` varsayımlarını bozdu:** `widget_test.dart`'taki "...5 saniyede bir
    otomatik değişir" testleri `pump(Duration(seconds:5))`'ten HEMEN SONRA eski sözün kaybolduğunu
    varsayıyordu — artık Timer'ın tetiklediği `setState` bu pump'ın SONUNDA gerçekleşip fade animasyonu
    o an YENİ BAŞLADIĞI için tamamlanması ayrıca bir `pumpAndSettle()` gerektiriyor. **Daha ciddi bir
    tuzak — `goal_completion_celebration_test.dart`'ta GERÇEK bir `pumpAndSettle` sonsuz döngüsü:**
    bu testin "kutlama animasyonunu (~4sn) tek seferde geç" tekniği `pumpAndSettle(Duration(seconds:
    5))` kullanıyordu — bu 5 SANİYELİK adım, `GoalTrackingScreen`'in KENDİ konuşma balonu sözünü
    döndüren AYNI 5 saniyelik `Timer.periodic`'iyle TAM ÇAKIŞIP HER adımda timer'ı yeniden
    tetikliyor, yeni eklenen fade animasyonunu her seferinde baştan başlatıp `pumpAndSettle`'ın ASLA
    "settle" olamamasına (`pumpAndSettle timed out`) yol açıyordu. **Çözüm:** o tek satırı, kendi
    başına asla yeniden tetiklenmeyen, 5000ms'e TAM denk gelmeyen üç ayrı `pump()` çağrısına
    (`2sn + 2sn + 500ms`) bölmek. **Ders — genelleştirilebilir bir tuzak:** bir ekranın KENDİ periyodik
    `Timer`'ı varsa, o ekranı pump'layan bir testte `pumpAndSettle(Duration(saniye))`'i o timer'ın
    periyoduna TAM EŞİT (veya tam katı) bir değerle ASLA kullanmayın — `pump()`'ın kendi TEK SEFERLİK,
    tekrarlamayan doğası bu resonance riskini taşımaz.

### Hedef Takibi ([goal_tracking_screen.dart](lib/screens/goal_tracking_screen.dart), [goals_provider.dart](lib/providers/goals_provider.dart), [goal.dart](lib/models/goal.dart), [goal_card.dart](lib/widgets/goal_card.dart), [goal_quotes.dart](lib/data/goal_quotes.dart))
- **`SharedPreferences` ile kalıcı** (`ThemeProvider`/`CostumeProvider` ile aynı desen) — hedefler
  listesi + her hedefin `cycleStartDate`/`completedDates`'i tek bir `'goals'` anahtarı altında JSON
  olarak saklanır (`_nextId` sayacı da aynı JSON'da, id çakışması olmasın diye). **Bu kalıcılık
  başlangıçta EKSİKTİ** — Hedef Takibi ve Para ve Birikim ekranlarındaki veriler uygulama yeniden
  başlatıldığında sıfırlanıyordu (yalnızca bellekte tutuluyordu); kullanıcı bildirince eklendi.
- **2026 güncellemesi — otomatik örnek hedef KALDIRILDI.** İlk sürümde ilk kurulumda (kayıtlı veri
  yoksa) kullanıcıya boş bir listeyle değil örnek bir hedefle ("Günde 30 dakika kitap oku")
  başlangıç noktası gösteriliyordu; kullanıcı bunun kafa karıştırıcı olduğunu bildirdi ("kullanıcı
  sıfırdan başlasın, hedef ekleneye"). `GoalsProvider._loadFromPrefs()`'teki `addGoal(...)` çağrısı
  kaldırıldı — ilk kurulumda liste artık gerçekten BOŞ, `GoalTrackingScreen` zaten "Yeni Hedef Ekle"
  butonunu koşulsuz gösterdiği için (bkz. altta) ekranda ayrı bir "boş durum" mesajına gerek kalmadı.
  **Yan etki — `ProfileStats._consistencyStat`'ın "veri yok" davranışı DÜZELDİ:** bu kategori
  `goals.goals.isNotEmpty`'e bakıyor; önceden seed sayesinde HER ZAMAN (0 puanla da olsa) "veri var"
  dönüyordu, artık gerçekten hiç hedef eklenmemişse diğer üç kategori (Para/Şükür-Manifest/Öz Saygı)
  gibi tutarlı şekilde "veri yok" dönüyor (bkz. `profile_stats_test.dart`).
- **Test gotcha'sı:** `_loadFromPrefs()` asenkron olduğu için (constructor'da fire-and-forget
  çağrılır), `GoalsProvider`'ı doğrudan (widget pump'lamadan) test eden `goals_provider_test.dart`
  `setUp`'ında `SharedPreferences.setMockInitialValues({})` + provider oluşturulduktan sonra
  `await Future<void>.delayed(Duration.zero)` GEREKTİRMEYE devam ediyor (ilk — artık boş — yüklemenin
  bitmesini beklemek için) — **artık ek olarak** bu bekleyişten SONRA `provider.addGoal(...)` ile
  testin ihtiyaç duyduğu hedefi AÇIKÇA eklemesi gerekiyor (eskiden bunu otomatik seed yapıyordu).
  Aynı desen `widget_test.dart`'taki `_buildAppWithClock` tabanlı iki testte de (gün-kutucuğu
  tıklama senaryoları) tekrarlanıyor.
- **Zibo başlığı, `MoneyScreen` ile birebir aynı desen:** `isActive` parametresi (RootScreen'in
  `IndexedStack`'i tüm sekmeleri baştan monte ettiği için, yalnızca sekme gerçekten görünürken
  çalışan bir `Timer.periodic(5sn)`), `goal_quotes.dart`'taki 100 istikrar/hedef temalı sözden
  rastgele (art arda tekrarsız) birini gösteren konuşma balonu, ve balonun yanında `ShareZiboButton`.
  Eski sabit `l10n.goalTrackingSpeechBubble` ARB anahtarı bu yüzden tamamen kaldırıldı — içerik
  havuzu artık `money_quotes.dart`/`zibo_messages.dart` ile aynı gerekçeyle (CLAUDE.md'de belgeli
  "içerik havuzu vs UI chrome" ayrımı) sabit Türkçe veri dosyası olarak tutuluyor.
- **Gotcha — Zibo görseli konuşma balonunun kuyruğuyla hizalı olmalı:** `SpeechBubble`'ın kuyruğu
  her zaman balonun **kendi genişliğinin ortasında** çizilir (bkz. `speech_bubble.dart`), balonun
  ekrandaki konumundan bağımsız. İlk sürümde bu başlık `Align(alignment: Alignment.topLeft)` +
  `Column(crossAxisAlignment: CrossAxisAlignment.start)` ile sarılıydı — bu, Align'ın çocuğuna gevşek
  (loose) kısıtlar vermesi yüzünden Column'un kendi içeriğine göre daralıp sola yaslanmasına, oysa
  balonun (metin uzunluğuna göre) çok daha geniş olup kuyruğunun Zibo'nun çok sağında kalmasına yol
  açtı (kullanıcı ekran görüntüsüyle bildirdi: "Zibo yanda kalmış"). **Çözüm:** `Align`/`start`
  sarmalayıcısını tamamen kaldırıp düz bir `Column` (varsayılan `crossAxisAlignment.center`)
  kullanmak — `ListView` öğesi olarak tam genişliğe gerdiği için Zibo ve balon aynı yatay merkez
  çizgisinde ortalanıyor, bu da balonun kendi ortasındaki kuyrukla otomatik hizalanıyor demek
  (`HomeScreen`'in zaten kullandığı `Center > Column` deseniyle aynı sonuç). **Bir Zibo görseli +
  `SpeechBubble` ikilisini yeni bir ekrana eklerken bu deseni kullanın, `Align(topLeft)` +
  `crossAxisAlignment.start` KULLANMAYIN.**
- **Kritik tasarım kararı:** Döngü bir sayaç değil, gerçek takvim tarihlerine bağlı.
  `Goal.cycleStartDate` döngünün Gün 1'inin tarihi; `completedDates` o döngüde işaretlenmiş
  tarihlerin kümesi. Gün numaraları hep `cycleStartDate + gün_indexi` ile hesaplanır.
- `GoalDayStatus`: `done` (işaretli) / `missed` (tarihi geçmiş, işaretsiz) / `today` (tek
  tıklanabilir kutu) / `upcoming` (henüz gelmemiş, kilitli).
- **Reconciliation (`GoalsProvider.reconcileForToday`):** Uygulama her açıldığında/öne geldiğinde
  (`WidgetsBindingObserver` + `AppLifecycleState.resumed`) çağrılır. Döngüde bugünden önce
  işaretlenmemiş bir gün varsa (kullanıcı o gün uygulamayı hiç açmamış demektir), döngü sıfırlanır
  ve bugünden yeniden Gün 1 başlar. Sıfırlanan hedeflerin isimleri döndürülür, ekran bunun için bir
  `SnackBar` gösterir.
- 7/7 tamamlanınca (`toggleToday` → `cycleCompleted == true`) `GoalCard` bilerek `CoinProvider`'ı
  çağırıp +50 Zibo Coin veriyor — **`GoalsProvider`'ın kendisi coin sistemine bağımlı değil**, ödülü
  vermek çağıran widget'ın sorumluluğunda (iki state parçası kasıtlı olarak ayrık tutuluyor).
- `GoalsProvider(now: ...)` enjekte edilebilir saat parametresi alıyor — testlerde sahte tarihler
  vermek için (`DateTime Function()`), üretimde varsayılan `DateTime.now`.
- Birden fazla hedef desteklenir; ekleme (dialog) ve silme (kart üstü çöp kutusu ikonu) var.
- **2026 güncellemesi — tamamlanan döngülerin kalıcı geçmişi + "Tamamlanan Hedefler" ekranı:**
  Kullanıcı isteği: "7 günlük hedef tamamlanınca '1 haftalık tamamlama' ibaresi/rozeti gösterilsin,
  yeni bir 'Tamamlanan Hedefler' sekmesi/ekranı oluştur, bu sekmede her hedefin kendine ait ayrı bir
  geçmiş listesi olsun." Eski mimaride bir döngü tamamlanınca `toggleToday`, `completedDates`'i ve
  `cycleStartDate`'i ANINDA sıfırlayıp yeni döngüye hazırlıyordu — tamamlanmış döngülerin HİÇBİR
  İZİ kalmıyordu (yalnızca o anki SnackBar + coin, kalıcı bir kayıt YOK).
  - **Yeni `GoalCompletion` modeli** ([goal_completion.dart](lib/models/goal_completion.dart)):
    `goalId`, `goalName` (tamamlanma ANINDAKİ ismin anlık görüntüsü — hedef sonradan yeniden
    adlandırılsa/silinse bile geçmiş bozulmasın diye), `cycleStartDate`, `completionDate`.
  - **`GoalsProvider._completions`** — `toggleToday`'de `cycleCompleted` true olduğunda,
    `completedDates`/`cycleStartDate` SIFIRLANMADAN HEMEN ÖNCE bir `GoalCompletion` ekleniyor. Aynı
    JSON'un yeni bir `'completions'` alanı altında `'goals'` ile birlikte kalıcı. `completions`
    getter'ı en yeni en üstte sıralı döner.
  - **Yeni [completed_goals_screen.dart](lib/screens/completed_goals_screen.dart)** — sekme DEĞİL
    (`RootScreen`'in 4 sabit sekmesi zaten yerleşik; yeni bir sekme eklemek `MainBottomBar`'ı
    yeniden tasarlamayı gerektirirdi), Ayarlar/Manifest/Su Takibi gibi `Navigator.push` ile açılan
    bir ekran. `completions`'ı `goalName`'e göre gruplar (`Map` ekleme sırasını koruduğu için ayrı
    bir sıralamaya gerek yok — zaten en-yeni-önce gelen listeyi gruplamak hem grup içi hem gruplar
    ARASI sırayı otomatik doğru veriyor). Her tamamlanma satırı altın/hardal renkli "1 haftalık
    tamamlama" rozeti (`Icons.emoji_events` + `colorScheme.primaryContainer`) + tarih aralığı
    gösterir.
  - **Erişim: `RootScreen`'in AppBar'ına KOŞULLU bir kupa ikonu eklendi** — yalnızca Hedefler
    sekmesi aktifken görünür (`if (_selectedIndex == _goalTrackingTabIndex)`), `WheelTriggerButton`'ın
    yalnızca Ana Sayfa'da görünmesiyle AYNI koşullu-görünürlük deseni. AppBar tüm sekmeler arasında
    PAYLAŞILDIĞI için (her sekmenin kendi Scaffold'u yok) bu, sekmeye özel bir eylemi eklemenin tek
    yolu.
  - **Test:** `goals_provider_test.dart`'a üç yeni senaryo (7. gün tamamlanınca kalıcı bir
    `GoalCompletion` kaydı düşüyor; aynı hedef ikinci bir döngüyü tamamlayınca İKİNCİ bir kayıt
    ekleniyor, birincisi kaybolmuyor; kalıcılık round-trip) + `widget_test.dart`'taki mevcut 7 gün
    tamamlama senaryosu, kupa ikonuna basıp "Tamamlanan Hedefler" ekranında hedef adı + rozeti
    doğrulayacak şekilde genişletildi.

### Zibo Coin ekonomisi ([coin_provider.dart](lib/providers/coin_provider.dart), [coin_economy.dart](lib/models/coin_economy.dart))
- Tüm tutarlar tek yerde: `CoinEconomy` (kazanma: check-in 5, reklam 20, mini görev 15, 7-gün
  bonusu 50, 30-gün bonusu 250, referans 100, günlük-modül ödülleri [Şükran/Su/Manifest] 5 — bkz.
  altta "2026 güncellemesi" — harcama: streak freeze 80, kişilik modu 500, replik paketi 150,
  kozmetik parametrik 100-300 aralığı).
- **2026 güncellemesi — Şükran Günlüğü/Su Takibi/Manifest Günlüğü'nün günlük ödülü 2 → 5 ZC'ye
  yükseltildi.** Kullanıcı isteği: "modüllerde 2 Zibo Coin veriyor, onu 5 yapalım" — üçü de AYNI
  değeri (`gratitudeJournal`/`waterGoalCompleted`/`manifestJournal`, `coin_economy.dart`) paylaştığı
  için TEK yerden, BİRLİKTE değiştirildi (kullanıcı belirli bir modülü ayırmadı, "modüllerde" genel
  ifadesi kullanıldı — üçü de aynı "günde bir kez, küçük bir günlük görev" kategorisinde). İlgili
  ARB metinleri (`gratitudeCoinRewardMessage`/`waterGoalCompletedMessage`/`manifestCoinRewardMessage`/
  `gratitudeTodayDoneBody`, TR/EN/ES) hardcoded "2" yerine "5" gösterecek şekilde güncellendi —
  bunlar `CoinEconomy`'den DİNAMİK OKUMUYOR, düz metin, bu yüzden kod DEĞİŞİNCE ARB'nin de elle
  senkron tutulması gerekiyor (`flutter gen-l10n` çalıştırıldı). `flutter test`'teki balance/metin
  assertion'ları (`widget_test.dart`, `manifest_journal_screen_test.dart`) güncellendi — 330/330 yeşil.
- **`SharedPreferences` ile kalıcı** — bakiye + işlem geçmişi tek bir `'coinState'` anahtarı altında
  JSON. **Bu da başlangıçta EKSİKTİ** (Hedef Takibi/Para ve Birikim ile aynı kullanıcı raporuyla
  ortaya çıktı) — `CoinProvider` daha önce hiç `SharedPreferences` kullanmıyordu, bakiye her yeniden
  başlatmada sıfırlanıyordu. İşlem geçmişi sınırsız büyümesin diye yalnızca en yeni
  `_maxStoredTransactions` (200) işlem saklanıyor — eski kayıtlar kalıcı depodan (yalnızca oradan;
  `transactions` getter'ı bellekteki listeyi olduğu gibi döner, kesme yalnızca `_save()`'de olur)
  budanıyor. `CostumeProvider` zaten en baştan `SharedPreferences` kullanıyordu, o yüzden kostüm
  sahipliği/giyili durumu bu sorundan hiç etkilenmedi.
- `CoinProvider._spend` bakiye yetersizse `false` döner ve hiçbir şey değişmez;
  `showInsufficientCoinsWarning` ([coin_feedback.dart](lib/utils/coin_feedback.dart)) ortak uyarı
  snackbar'ını gösterir.
- `CoinBalanceWidget` ([coin_balance_widget.dart](lib/widgets/coin_balance_widget.dart)): AppBar'da
  her zaman görünen rozet. Bakiye değişince `TweenAnimationBuilder<int>` ile eski değerden yeniye
  sayarak animasyonlanır, üstünde de yükselip kaybolan bir "+N"/"-N" metni belirir
  (`CoinProvider.lastDelta` üzerinden).
- **Ayarlar sayfasındaki "Coin Test Paneli" geçicidir** (`_CoinTestPanel` in
  [settings_screen.dart](lib/screens/settings_screen.dart), açıkça "GEÇİCİ" yorumuyla işaretli).
  Her kazanma/harcama mekaniğini denemek için var; gerçek check-in/görev akışları geldiğinde
  tamamen kaldırılacak.
- **2026 güncellemesi — reklam karşılığı günlük hak sınırı eklendi (Şans Çarkı + Mağaza'nın
  Ücretsiz kartı).** Kullanıcı isteği: gerçek AdMob entegrasyonu tamamlandıktan sonra (bkz. "AdMob
  Entegrasyonu" bölümü) reklam gösterimlerinin sınırsız tekrarlanmasını önlemek için — kullanıcı
  günde en fazla **3 kez** reklam izleyerek Şans Çarkı'nı çevirebilir, en fazla **2 kez** Mağaza'nın
  "Ücretsiz" kartından ekstra coin kazanabilir. Hak tükendiğinde ilgili buton/kart, `TrustedTimeProvider`
  günü ilerleyene kadar `dailyAdLimitReachedMessage` ("Bugünkü hakların bitti, yarın tekrar gel!")
  mesajıyla pasif görünür.
  - **`CoinProvider.maxDailyWheelSpins`/`maxDailyAdWatches`** — sabitler tek yerde. Günlük sayaçlar
    (`_dailyLimitsDate`, `_wheelSpinsUsedToday`, `_adWatchesUsedToday`) `WaterProvider._today`
    getter'ıyla AYNI "her erişimde `_now()`'a göre yeniden hesapla" deseninde: kayıtlı sayacın ait
    olduğu gün bugünden FARKLIYSA `wheelSpinsUsedToday`/`adWatchesUsedToday` getter'ları otomatik
    `0` döner — `GoalsProvider`/`WaterProvider` gibi ayrı bir "reconcile" adımına GEREK YOK.
    `remainingWheelSpinsToday`/`remainingAdWatchesToday`/`canSpinWheelToday`/
    `canWatchAdForCoinsToday` bu getter'ların üzerine kurulu, arayüz bunları `context.watch` ile
    izliyor.
  - **`CoinProvider` artık `GoalsProvider`/`WaterProvider` ile AYNI `DateTime Function() now`
    constructor parametresine sahip** (varsayılan `DateTime.now`, `main.dart`'ta
    `context.read<TrustedTimeProvider>().now()` ile enjekte ediliyor — CoinProvider,
    `MultiProvider` listesinde `TrustedTimeProvider`'dan HEMEN SONRA geldiği için bu `context.read`
    güvenli). **Kullanıcının açık isteği** "gerçek takvim tarihine bağlı, cihaz saatine değil"
    idi — bu, projenin diğer TÜM "güne bağlı" mekanizmalarıyla (Günlük Giriş Ödülleri/Hedefler/Su
    Takibi vb.) aynı güvenlik garantisini veriyor: kullanıcı telefonun tarihini ileri alarak günlük
    hakları erken sıfırlayamaz.
  - **Hak, YALNIZCA reklam GERÇEKTEN ödül verdiğinde (kullanıcı sonuna kadar izlediğinde)
    tüketilir — reklam yüklenemez/erken kapatılırsa hak HİÇ düşmez.** `earnAdWatch()`/
    `watchAdAndSpinWheel()`'in ikisi de ÖNCE `_adService.showRewardedAd()`'ı `await`liyor, `_consumeDailyLimit(...)`
    yalnızca `rewarded == true` iken çağrılıyor. Bu, kullanıcının "günde 3/2 hakkı" beklentisinin
    gerçek başarılı izlemeler için olduğu, ağ/envanter sorunuyla başarısız olan denemelerin
    cezalandırılmaması gerektiği yönündeki doğal beklentiyle örtüşüyor.
  - **İki metot da hakkı KENDİSİ de kontrol ediyor** (`if (!canSpinWheelToday) return null;` /
    `if (!canWatchAdForCoinsToday) return false;`, reklamı hiç GÖSTERMEDEN) — arayüz zaten butonu
    devre dışı bıraktığı için normalde bu yola hiç girilmiyor, ama çift bir güvenlik katmanı
    (ör. hızlı art arda iki dokunuş arasındaki yarış durumu) için provider seviyesinde de var.
  - **Günlük sayaçlar `_earn(...)`'ün ZATEN tetiklediği `_save()`'e (aynı `CloudStateStore`
    belgesine, `coinState`) eklendi** — ayrı bir kalıcılık çağrısı GEREKMEDİ, `_consumeDailyLimit(...)`
    `_earn(...)`'den HEMEN ÖNCE çağrılıp aynı bildirim/kayıt turunda birlikte gidiyor. **Yan
    not (bu turda kullanılmadı ama gelecekte faydalı olabilir):** bu sayaçlar artık `uid` varsa
    Firestore'a da (`users/{uid}/state/coinState`) senkronize oluyor — `notification-scripts/src/
    dailyRewardReminder.js`'teki "Şans Çarkı'nın Firestore'da kalıcı bir 'bugün çevrildi mi' alanı
    YOK" sınırlaması (bkz. "Push Bildirimleri" bölümü) artık TEKNİK olarak çözülebilir (`coinState.
    wheelSpinsUsedToday`/`dailyLimitsDate` okunarak), ama script bu turda GÜNCELLENMEDİ — kapsam
    dışı bırakıldı.
  - **UI — pasif görünüm:**
    - `StoreScreen._WatchAdCard`: `context.watch<CoinProvider>().canWatchAdForCoinsToday` `false`
      iken alt metin `dailyAdLimitReachedMessage`'a döner, `FilledButton.onPressed` `null` olur
      (Material'ın kendi disabled stilini otomatik alır — ekstra bir "sönük" stil kodu YAZILMADI).
    - `WheelScreen`: `canSpinWheelToday` `false` iken hub'ın dokunma alanı (`InkWell.onTap`) `null`
      olur VE başlığın altında AYNI mesaj metni belirir (yeni bir `if (!canSpin) ...` bloğu).
    - `WheelTriggerButton`: `AnimatedOpacity` ile (250ms) `0.45` opaklığa söner, tooltip/semantics
      etiketi mesaja döner, VE `didChangeDependencies()`'teki animasyon başlatma/durdurma mantığı
      (önceden yalnızca `MediaQuery.disableAnimations`'a bakıyordu) artık `canSpinWheelToday`'i de
      kontrol ediyor — hak tükendiğinde buton "dinlenir" (sürekli dönme/nabız animasyonu durur),
      dikkat çekmeye devam etmek yanıltıcı olurdu. **Tıklama BİLEREK devre dışı bırakılmadı** — sönük
      durumda bile basılabilir, `WheelScreen`'i açıp orada net mesajı görebilsin diye (dokunulunca
      hiçbir şey olmayan "ölü" bir buton kafa karıştırırdı).
  - **ARB — `dailyAdLimitReachedMessage` (TEK anahtar, ÜÇ konumda paylaşılıyor):** Mağaza kartı,
    Şans Çarkı ekranı ve Şans Çarkı tetikleyici tooltip'i AYNI metni gösteriyor (kullanıcının
    verdiği örnek mesaj birebir aynıydı) — üç ayrı namespaced anahtar yerine TEK paylaşılan anahtar
    (proje genelinde bazı yerlerde zaten kullanılan desen, ör. `tabMoney`), gereksiz çeviri
    tekrarını önlüyor.
  - **Test:** `coin_provider_test.dart`'a yeni bir grup (5 test) — Şans Çarkı tam
    `maxDailyWheelSpins` kez çevrilebilir + fazlası reddedilir, reklam karşılığı coin
    `maxDailyAdWatches` kez kazanılabilir + fazlası reddedilir, reklam BAŞARISIZ olursa
    (`_RejectingAdService`, yeni test-only sınıf) hak HİÇ tüketilmez, gün değişince (enjekte
    edilen `now` ile) her iki hak da sıfırlanır, günlük sayaçlar kalıcı depoya yazılıp AYNI gün
    içinde yeniden başlatmada hatırlanır. `widget_test.dart`'ın `_buildAppWithClock()` yardımcısına
    da (diğer TÜM güne bağlı provider'larla tutarlılık için) `CoinProvider(now: now)` eklendi —
    daha önce parametresizdi. **Toplam: 249 test.**
  - **Gerçek cihazda doğrulama:** APK yeniden derlenip telefona kurulup `adb shell monkey` ile
    başlatıldı, çöküş izi yok. Görsel doğrulama (3 kez çevirip/2 kez izleyip butonların gerçekten
    sönük göründüğü VE ertesi gün otomatik sıfırlandığı) kullanıcının kendi cihazında zaman
    geçtikçe doğrulanmalı — bu, `flutter test`'teki 5 testte enjekte edilen sahte saatle KAPSANIYOR
    ama gerçek zamanın geçmesini gerektiren bir senaryo olduğu için ek olarak gerçek cihazda uzun
    süreli doğrulama YAPILMADI.

### Mağaza ([store_screen.dart](lib/screens/store_screen.dart), [coin_package.dart](lib/models/coin_package.dart), [coin_packages.dart](lib/data/coin_packages.dart))
- Bir sekme (push edilen ayrı sayfa değil), RootScreen'in ortak AppBar'ını paylaşır.
- İki segment tek sayfada `SegmentedButton` ile birleşik: "Coin Al" (`_BuyCoinsSection`) ve
  "Kostümler" (`_CostumesSection`, bkz. aşağıdaki Kostümler bölümü) — coin kazanma/harcama akışları
  aynı girişten ulaşılabilir kalsın, alt gezinme çubuğu da 4 öğede sabit kalsın diye ayrı bir sekme/
  sayfa yerine böyle tasarlandı (`_StoreScreenState._section`, `StatefulWidget`).
- Coin Al: ücretsiz reklam izleme kartı (üstte) + 5 coin paketi grid'i (100/250/500/1000/10000 ZC).
- `CoinPackage.imageAsset` veri modelinin bir parçası — ileride pakete özel görsel eklemek yalnızca
  `coin_packages.dart`'taki ilgili satırı değiştirmek kadar kolay olsun diye böyle tasarlandı.
  **2026 güncellemesi — 5 pakete özel gerçek görsel.** Kullanıcı `assets/images/` klasörüne
  `zibo_coin_100.png`/`zibo_coin_250.png`/`zibo_coin_500.png`/`zibo_coin_1000.png`/
  `zibo_coin_10000.png` dosyalarını ekledi (dosya adı ↔ paket miktarı eşlemesi kasıtlı — 100 ZC
  tek bozuk para, 10000 ZC ise taşan bir hazine sandığı gibi miktar arttıkça daha "zengin" bir
  sahne). `coin_packages.dart`'taki eski tek `_defaultCoinImage` (`zibo_coin.png`, tüm paketler
  aynı ikonu kullanıyordu) sabiti kaldırıldı, her `CoinPackage.imageAsset` kendi dosyasına
  eşlendi — veri modelinin kendisi zaten bu değişikliği tek satırlık bir güncellemeyle
  destekleyecek şekilde tasarlanmıştı, `CoinPackage`/UI kodunda bir değişiklik GEREKMEDİ.
  - **Tutarlı çerçeve — `_PackageCard`'ta (`store_screen.dart`)** görsel sabit bir `SizedBox`
    içinde `Image.asset(..., fit: BoxFit.contain)` ile render ediliyor. Yeni 5 görsel piksel
    boyutu olarak zaten hemen hemen kare (1053×1024) ama içerdikleri "sahne" (tek madeni para vs.
    dolu bir sandık) görsel olarak farklı yoğunlukta — `BoxFit.contain` her görseli
    kırpmadan/gerilmeden AYNI çerçeveye sığdırıyor, kartlar arasında ani boyut sıçraması olmuyor.
    **2026 güncellemesi — görseller belirgin şekilde büyütüldü: 48×48 → 76×76.** Kullanıcı
    isteği: kartlarda daha "baskın/net" görünsünler. Doğrudan 48'den 64'e (+16px) çıkarmak daha
    ÖNCE `_PackageCard`'ın `Column`'ında bir `RenderFlex overflow`'a yol açmıştı
    (`childAspectRatio: 0.95`'lik 2 sütunlu grid'in dar dikey alanı yüzünden) — bu SEFER hem
    görsel gerçekten büyütüldü (76×76) HEM DE `GridView.count`'un `childAspectRatio`'su `0.95`'ten
    `0.8`'e düşürüldü (kartlara daha fazla dikey alan tanıyarak overflow'u kökten önledi, metin/
    buton boşlukları da hafifçe daraltıldı: görsel↔metin `SizedBox(height: 8)`→`4`, metin↔buton
    `10`→`6`). Sonuç: hiçbir overflow olmadan, belirgin şekilde büyümüş, net görünen görseller.
  - **Test + doğrulama:** tam `flutter test` (256/256 geçti — overflow olmadığı doğrulandı).
    `flutter build apk --debug` + cihaza kurulum + Mağaza > "Coin Al" ekran görüntüsüyle beş
    kartın da kendi görseliyle, belirgin şekilde büyümüş, kırpılmadan/gerilmeden,
    fiyat ve ZC miktarı hâlâ net okunur şekilde render olduğu doğrulandı.
  - **2026 güncellemesi — `CoinPackage.imageScale` (yeni alan, varsayılan `1.0`) ile 10000 ZC
    görseli TEK BAŞINA büyütüldü.** Kullanıcı isteği: en yüksek paket olduğu için 10000 ZC görseli
    diğerlerine oranla biraz daha "baskın" dursun, ama kart düzeni (grid, `childAspectRatio`)
    bozulmasın. **Grid/kart genişliğini değiştirmek yerine yalnızca O TEK paketin görsel
    çerçevesini büyütmek gerektiği için** `childAspectRatio`/ortak `SizedBox` sabitine
    dokunulmadı — `CoinPackage`'a genel bir `double imageScale` alanı eklendi (veri modelinin
    "data-driven, ileride pakete özel özelleştirme kolay olsun" felsefesiyle AYNI, bkz. yukarıdaki
    `imageAsset` notu), `coin_packages.dart`'taki `coins_10000` girdisi `imageScale: 1.2` aldı,
    diğer dört paket varsayılan `1.0`'da kaldı. `_PackageCard`'ın görsel `SizedBox`'ı artık
    `width/height: 76 * widget.package.imageScale` — yalnızca 10000 ZC kartında görsel çerçevesi
    ~%20 büyüyor (91.2×91.2), metin/fiyat/buton alanı VE kartın kendi dış boyutu (grid hücresi)
    DEĞİŞMİYOR, `BoxFit.contain` sayesinde büyüyen görsel kartın içinde taşmadan ortalanıyor.
  - **Test + doğrulama:** `flutter test` (256/256, mevcut testler etkilenmedi — `imageScale`
    yalnızca görsel boyutunu değiştiriyor, layout/metin assertion'larını bozmadı).
    `flutter build apk --debug` + cihaza kurulum + Mağaza ekran görüntüsüyle 10000 ZC kartının
    görselinin diğer dört karta göre gözle görülür biçimde daha büyük, ama kartın kendisinin
    (kenarlık/hizalama) diğerleriyle aynı boyutta kaldığı doğrulandı.
- **2026 güncellemesi — paket kartlarında "Satın Al" yerine gerçek TL fiyatları.** Kullanıcı isteği:
  butonda genel "Satın Al" metni yerine gerçek (şimdilik sabit/görsel — gerçek bir IAP işlemi
  TETİKLEMİYOR, `MockPurchaseService` hâlâ kullanılıyor) fiyatlar gösterilsin: 100 ZC → 19,99 ₺,
  250 ZC → 44,99 ₺, 500 ZC → 84,99 ₺, 1000 ZC → 159,99 ₺, 10000 ZC → 1.499,99 ₺.
  - **`CoinPackage.priceLabel` (düz `String?`) kaldırılıp yerine `CoinPackage.price`
    (`PackagePrice?`) getirildi** — kullanıcının açık isteği "ileride ülkeye göre farklı para
    birimi/fiyat gösterebilecek şekilde esnek tut" doğrultusunda: `PackagePrice`, ham bir metin
    yerine `{amount: double, currencyCode: String}` taşıyor (`currencyCode` varsayılanı `'TRY'`,
    ISO 4217). İleride ülkeye göre farklı bir fiyat/para birimi göstermek istenirse yalnızca VERİ
    katmanında (`coin_packages.dart`'taki `PackagePrice` değerleri, ör. bir ülke → fiyat eşlemesi)
    bir değişiklik gerekecek — `CoinPackage`/`_PackageCardState` UI kodu HİÇ değişmeyecek.
  - **[currency_format.dart](lib/utils/currency_format.dart)** (YENİ) — `formatCurrencyAmount
    (double amount, String currencyCode)`, `currencyCode`'a göre dallanan saf bir biçimlendirici
    (`intl` paketine BİLEREK gerek duyulmadı — yalnızca iki ondalık basamaklı, Türkçe stilinde
    [ondalık virgül, binlik nokta] bir fiyat metni üretmek için gereken kadar basit). Şu an yalnızca
    `'TRY'` bir `case` olarak tanımlı (`"19,99 ₺"` gibi), tanınmayan bir kod için genel bir geri
    düşüş var (`"9,99 USD"` gibi) — yeni bir para birimi eklemek yalnızca burada bir `case`
    eklemek kadar kolay. `PackagePrice.formatted` getter'ı bu fonksiyonu çağırıyor.
  - **`_PackageCardState`'in buton metni** (`store_screen.dart`) `widget.package.priceLabel ??
    l10n.storeBuyButton` yerine `widget.package.price?.formatted ?? l10n.storeBuyButton` kullanıyor
    — mantık DEĞİŞMEDİ (fiyat yoksa genel "Satın Al" metnine düşülüyor), yalnızca kaynak alan.
  - **Test:** YENİ `test/currency_format_test.dart` (`formatCurrencyAmount`'ın iki/üç haneli tam
    sayı kısımları, binlik ayracı, bilinmeyen para birimi geri düşüşü) + `widget_test.dart`'taki
    Mağaza testine beş fiyat metninin (`'19,99 ₺'`/`'44,99 ₺'`/`'84,99 ₺'`/`'159,99 ₺'`/
    `'1.499,99 ₺'`) göründüğünü doğrulayan assertion'lar eklendi. Gerçek cihazda beş kartın da
    doğru TL fiyatlarıyla (binlik ayracı dahil, "1.499,99 ₺") render olduğu görsel olarak
    doğrulandı.

