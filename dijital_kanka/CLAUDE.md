# Dijital Kanka (Zibo)

Flutter uygulaması: kullanıcının günlük hedeflerini takip etmesine, harcama/ödeme/birikimlerini
kaydetmesine yardımcı olan, "Zibo" adlı maskot karakterin eşlik ettiği bir "dijital kanka" uygulaması.
İçinde bir sanal para birimi (Zibo Coin) ekonomisi var.

Bu dosya, projeye sıfırdan bakan bir Claude Code oturumunun hızlıca bağlam kazanması için yazıldı.
Kod zaten kendini büyük ölçüde açıklıyor (Türkçe kod-içi yorumlar WHY'a odaklanır); burada asıl amaç
mimariyi, kasıtlı tasarım kararlarını ve ortam kaynaklı tuzakları tek yerde toplamak.

**2026 güncellemesi — kullanıcıya görünen uygulama adı artık "Zibo"** (`android:label`,
`android/app/src/main/AndroidManifest.xml`; `appTitle` ARB anahtarı, üç dilde de "Zibo" — recents/
görev değiştirici ekranındaki başlık için). **Dart paket/dizin adı (`dijital_kanka`, `pubspec.yaml`
`name:` alanı, TÜM `package:dijital_kanka/...` importları) BİLEREK DEĞİŞTİRİLMEDİ** — yalnızca
kullanıcı-görünür isim istendi, dahili paket adını değiştirmek proje genelinde onlarca dosyada
import yeniden yazımı gerektirir ve hiçbir kullanıcı-görünür faydası yoktur. Uygulama ikonu da
kullanıcının verdiği `assets/images/zibo_app_icon.png`'ye güncellendi (bkz. "Görsel işleme"
bölümündeki `clean_app_icon.dart` notu).

## Ortam ve komutlar (Windows'a özgü tuzaklar)

- Flutter SDK `C:\flutter` altında, PATH'te değil — her oturumda PATH'e eklenmesi gerekir.
- **`flutter analyze` bu makinede çöküyor** (yol içindeki boşluk/Türkçe karakterler yüzünden LSP'de
  JSON parse hatası). Kullanma; bunun yerine `flutter test`'e güven.
- Windows native plugin derlemesi için symlink desteği eksik (`flutter run -d windows` etkilenir; web
  ve test etkilenmez). Bu yüzden görsel doğrulama **`flutter run -d web-server`** + Claude_Browser
  araçlarıyla yapılıyor, gerçek Chrome/Windows penceresiyle değil.
- Tarayıcı önizlemesi için `../.claude/launch.json` (workspace kökü `Zibo DK/`, proje kökü değil)
  içinde `dijital_kanka_web` adlı bir konfigürasyon var. **`runtimeExecutable` doğrudan
  `flutter.bat` değil, `cmd.exe /c cd /d <8.3 kısa yol> && flutter.bat run -d web-server ...`** —
  çünkü `preview_start` komutu workspace kökünden çalıştırıyor (proje alt klasörde) ve yoldaki
  Türkçe karakterler (`Masaüstü`) cmd.exe'nin varsayılan codepage'inde bozulup
  "sözdizimi hatalı" hatası veriyordu; bu yüzden `cd` hedefi olarak 8.3 kısa yol
  (`MASAST~1\ZIBODK~1\DIJITA~1`) kullanılıyor. Kısa yolu değişirse (proje taşınırsa) yeniden almak
  için: PowerShell'de
  `(New-Object -ComObject Scripting.FileSystemObject).GetFolder("<tam yol>").ShortPath`.
- Test komutu: `flutter test` (proje kökünde, `dijital_kanka/` içinde).
- Görsel işleme betikleri: `dart run tool/remove_bg.dart <dosya>` ve
  `dart run tool/crop_transparent.dart <dosya>` (bkz. aşağıdaki "Görsel işleme" bölümü).
- **Gotcha: yeni asset dosyası eklendikten sonra hot reload yetmez.** `pubspec.yaml`'da zaten
  dahil olan `assets/images/` klasörüne yeni bir dosya eklendiğinde (ör. yeni bir kostüm görseli),
  çalışan bir `flutter run` oturumunda hot reload bunu YANSITMAZ — asset manifest yalnızca build
  zamanında üretiliyor. Kullanıcı "Unable to load asset... does not exist or has empty data" hatası
  aldıysa (dosya diskte gerçekten var ve boş değilse) çözüm kod değil, **tam bir yeniden başlatma**:
  `flutter run` oturumunu tamamen durdurup yeniden başlatmak (yalnızca hot restart "R" bile
  yetmeyebilir, bazı durumlarda gerçekten durdurup tekrar çalıştırmak gerekir); web'de ayrıca
  tarayıcıyı sert yenilemek (hard refresh) faydalı olabilir.

## Mimari özet

- **State management:** `provider` paketi. Yirmi üç adet `ChangeNotifier`, `main.dart`'ta
  `MultiProvider` ile uygulama köküne bağlanıyor: `TrustedTimeProvider`, `AuthLinkProvider`
  (2026 yeni özellik — bkz. "Google Hesap Bağlama" bölümü), `AppThemeProvider`,
  `CoinProvider`, `CostumeProvider`, `CurrencyProvider` (2026 — Para ve Birikim çoklu para birimi),
  `CustomMessagesProvider` (2026 — Ana Sayfa özel mesajlar), `DailyRewardsProvider`,
  `DreamJournalProvider`, `FavoriteQuotesProvider`, `GoalsProvider`, `GratitudeProvider`,
  `LocaleProvider`, `ManifestProvider`, `MoneyProvider`, `MoodProvider`, `NotificationProvider`,
  `OnboardingProvider`, `ProfileProvider`, `ProfileStatsArchiveProvider` (2026 — "Geçmiş Ay
  İstatistikleri" arşivi, bkz. "Profil" bölümü), `ThemeProvider`, `WaterProvider`,
  `ZiboPoseProvider`. Kullanıcı verisi taşıyanların tamamı (`TrustedTimeProvider` VE
  `ZiboPoseProvider` HARİÇ — ikisi de kalıcı değil, saf UI/görsel durum, bkz. o sınıfların kendi
  dokümantasyonu) `CloudStateStore` üzerinden Firestore'a da senkronize oluyor — bkz. "Firestore
  veri kalıcılığı, Anonymous Auth ve güvenilir zaman" bölümü. `AuthLinkProvider` kendi `hasSeenLinkPrompt`
  alanı için AYNI `CloudStateStore`'u kullanıyor ama `isLinked`/`linkedEmail` Firebase Auth'un
  KENDİSİNDEN canlı okunuyor (ayrı bir kopya tutulmuyor) — bkz. "Google Hesap Bağlama" bölümü.
  **`_AppStartupGate`'in yedi provider'ı (`ThemeProvider`/`AppThemeProvider`/`LocaleProvider`/
  `CoinProvider`/`CostumeProvider`/`OnboardingProvider`/`ProfileProvider`) `isReady` olana kadar
  `RootScreen`/`OnboardingScreen` hiç GÖSTERİLMEZ** — bkz. "Açılış yükleme ekranı" ve "Onboarding
  (İlk Açılış Akışı)" bölümleri, özellikle `ProfileProvider`'ın bu kapıya SONRADAN (bir yarış
  koşulu bulunduğu için) eklendiği gotcha.
- **Navigasyon:** [`RootScreen`](lib/screens/root_screen.dart) sabit bir `AppBar` + kod-tabanlı
  bir alt gezinme çubuğu (`MainBottomBar`, bkz. "Alt Gezinme Çubuğu" bölümü — `Material`'ın
  `NavigationBar`'ı DEĞİL, `BottomAppBar` + ortada "dock" edilmiş bir `ZFloatingButton` deseni)
  barındırıyor, sekmeler arasında `IndexedStack` ile geçiliyor (4 sekme: Ana Sayfa, Hedef Takibi,
  **Profil**, Mağaza — **Para ve Birikim ARTIK BURADA DEĞİL**, kullanıcı isteğiyle Profil'le yer
  değiştirdi, bkz. "Alt Gezinme Çubuğu" bölümündeki güncelleme notu). **Ayarlar sekme değil** —
  AppBar'daki dişli ikonundan `Navigator.push` ile açılan ayrı bir sayfa (kendi
  `Scaffold`/`AppBar`/geri butonu var). Rüya Günlüğü/Şükran Günlüğü/Günlük Ruh Hali Takibi/**Para ve
  Birikim** de sekme DEĞİL, `Scaffold.floatingActionButton` olarak bağlı Z butonunun açtığı modül
  menüsünden erişiliyor (bkz. "Alt Gezinme Çubuğu"). AppBar'daki "+" ikonu Mağaza sekmesine
  geçiş yapıyor (aynı coin bakiyesinin yanında). Body, `IndexedStack`'i bir `Stack` içine alıp sol
  kenara sabit bir `WheelTriggerButton` (Şans Çarkı) overlay'i ekliyor — sekme dışında olduğu için
  sekme geçişlerinden etkilenmeden her zaman görünür.
- **Önemli gotcha — `IndexedStack` tüm sekmeleri hemen kurar:** Hangi sekme gösteriliyor olursa
  olsun, dört `Widget` da `build()` her çalıştığında inşa edilir (sadece görünürlük gizlenir).
  Sonuç olarak: (a) bir sekmenin ihtiyaç duyduğu her `Provider` uygulama genelinde mevcut olmalı,
  (b) `Timer`-tabanlı bir sekme (örn. `MoneyScreen`) görünür değilken de arka planda çalışmaya devam
  etmesin diye `isActive`-farkındalığı taşımalı (aşağıya bakın).
- **Servis soyutlamaları:** `AdService` ve `PurchaseService` soyut arayüzler. Üretimde varsayılan
  olarak gerçek implementasyonlar kullanılıyor — `AppodealAdService` (bkz. "AdMob → Appodeal
  geçişi" bölümü, önceden `AdMobAdService`) ve `InAppPurchasePurchaseService` (bkz. "Google Play
  Billing" bölümü); `MockAdService`/`MockPurchaseService` (600ms gecikmeyle her zaman başarı dönen
  sahteler) artık yalnızca `flutter_test`'te enjekte ediliyor — gerçek platform kanalına
  dokunamayan test ortamında reklam/satın alma akışlarını simüle etmek için. Bir reklam/ödeme
  SDK'sından başka birine geçilirken (AdMob → Appodeal'de olduğu gibi) yalnızca bu arayüzü
  uygulayan YENİ bir sınıf yazılıp `CoinProvider`'a constructor'dan verilecek — `CoinProvider` ve
  onu çağıran ekranların hiçbir satırı değişmeyecek. `ShareService`/`NotificationService`/`ManifestPhotoService`
  de aynı desende ama farkla: gerçek implementasyonları (`SharePlusService`/
  `LocalNotificationService`/`ImagePickerPhotoService`) baştan gerçek — mock/fake, yalnızca
  `flutter test`'in gerçek platform channel'lara dokunamaması için testte enjekte ediliyor (bkz.
  "Zibonu Paylaş"/"Bildirimler"/"Manifest Günlüğü").

## Klasör yapısı

```
lib/
  data/            # Sabit veri listeleri (mesaj havuzları, coin paketleri)
  l10n/            # ARB kaynak dosyaları + üretilen AppLocalizations
  models/          # Saf veri sınıfları (ChangeNotifier değil)
  providers/       # ChangeNotifier state sınıfları
  screens/         # Sayfa seviyesi widget'lar
  services/        # Soyut servis arayüzleri + mock implementasyonlar
  utils/           # Küçük paylaşılan yardımcılar (örn. coin_feedback)
  widgets/         # Yeniden kullanılabilir UI parçaları
tool/              # Uygulamaya dahil olmayan, elle çalıştırılan tek seferlik betikler
test/              # flutter_test testleri (provider'lar için birim, widget_test.dart için entegrasyon)
```

## Özellik bazlı döküm

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

### Kostümler ([costume.dart](lib/models/costume.dart), [costumes.dart](lib/data/costumes.dart), [costume_provider.dart](lib/providers/costume_provider.dart), [costume_card.dart](lib/widgets/costume_card.dart))
- Zibo Coin ile satın alınıp Ana Sayfa'daki Zibo'ya "giydirilebilen" 16 kostüm, 440-33000 ZC arası
  (bkz. altta "2026 fiyat güncellemesi"). Mağaza'nın "Kostümler" segmentinde 2 sütunlu bir
  `GridView.count` içinde `CostumeCard` olarak listelenir.
- **2026 fiyat güncellemesi — TOPLU %10 zam + fiyata göre sıralama.** Kullanıcı isteği:
  erişilebilirliği biraz zorlaştırmak için TÜM kostümlerin fiyatı %10 artırıldı (ör. 400 ZC →
  440 ZC — tüm eski fiyatlar zaten 50'nin katları olduğu için yuvarlamaya gerek kalmadan tam sayı
  çıktı). `costumes.dart`'taki `costumes` listesi ARTIK ucuzdan pahalıya SIRALI tanımlanıyor —
  Mağaza ızgarası listeyi olduğu gibi (`for (final costume in costumes) ...`) dolaştığı için, sıra
  BURADA tanımlanınca ayrı bir widget-seviyesi sıralama koduna gerek kalmadı (tek kaynak, tek yerde
  düzenleniyor). Güncel liste (ucuzdan pahalıya): Hippi/Sporcu 440, Asker/Hoca 550, Punk/Rapçi 715,
  Centilmen/Samuray 770, Gladyatör/Korsan 880, Siborg 935, Astronot 990, Kral 1045, Zombi 1100,
  **Altın 22000, Elmas Kaplama 33000** (en pahalı iki kostüm olarak kaldı — oranları zaten TAM
  %50 olduğu için, %10'luk toplu zam AYNI katsayıyla ikisine de uygulanınca "Elmas, Altın'ın ~%50
  üstünde" ilişkisi ayrıca elle ayarlamaya gerek kalmadan korundu).
- **2026 kostüm paketi — Centilmen/Samuray/Siborg/Astronot/Kral (`zibo_gentleman`/`zibo_samurai`/
  `zibo_cyborg`/`zibo_astronot`/`zibo_king`).** Kullanıcı her biri için bir vitrin görseli ("pose"
  ibaresi olmayan dosya, ör. `zibo_king.png`) + kendi poz seti (`zibo_king_pose1-3.png` vb.) ekledi.
  - **Fiyatlandırma** (ilk belirlenen değerler — o an kullanıcı isteğiyle 400-1000 ZC aralığında,
    "özel/prestijli" olanlar daha yüksek: Centilmen/Samuray 700, Siborg 850, Astronot 900, Kral 950;
    **sonradan yukarıdaki "2026 fiyat güncellemesi" ile TÜM kostümlerle birlikte %10 zamlandı** —
    güncel değerler için yukarıdaki listeye bakın). Altın/Elmas'ın 20000-30000 ZC'lik (şimdi
    22000-33000) ayrı mega-prestij kademesine BİLEREK dahil edilmedi.
  - **Kapak/vitrin görselleri de kırpıldı** (`tool/crop_new_costume_covers.dart`, YENİ) — kullanıcının
    eklediği 1024×1024 kaynak PNG'lerde karakterin etrafında geniş boşluk vardı (içerik kanvasın
    yalnızca ~%66-75'ini dolduruyordu); mevcut kostüm vitrin görselleri (`zibo_hippi.png` vb.) ÖNCEDEN
    ölçülüp ~%95.6-96.1 doluluk oranında sıkı kırpılmış olduğu tespit edildi (`CostumeCard`'ın sabit
    `height: 92` kutusunda tutarlı görünmesi için) — betik AYNI ~%96 hedefine (içerik sınır kutusu +
    %2 pay) kırpıp doğruladı. Poz PNG'lerinden FARKLI olarak vitrin görselleri TEK bir mutlak piksel
    hedefine ölçeklenmiyor (her kostümün kendi vitrin kartı bağımsız, kartlar arası kıyas gerekmiyor).
  - **Poz PNG'leri, `tool/process_new_costume_poses.dart` (YENİ) ile MEVCUT global hedefe (763px,
    `tool/process_all_poses.dart`'taki sabit) göre kırpılıp ölçeklendi** — kullanıcı isteği ("tüm
    görsellerin boyut/ölçek tutarlılığını koru") tam olarak bu: yeni 5 kostümün pozları eskilerle
    BİREBİR aynı nihai yükseklikte, kostümler arası geçişte boyut sıçraması yok.
  - **Kullanıcı-kaynaklı dosya adı yazım hatası düzeltildi:** `gentleman_zibo_pose2.png` (kelime
    sırası ters, diğer iki poz `zibo_gentleman_pose1/3.png` desenine uymuyordu) →
    `zibo_gentleman_pose2.png` olarak yeniden adlandırıldı — `zibo_korsan`/`zibo_hippi` arc'larındaki
    AYNI ders (kullanıcının belirttiği poz sayısı ile gerçek dosya sayısı arasındaki fark, dosya
    yeniden adlandırılarak çözüldü, poz atlanmadı).
  - **Orijinal (işlenmemiş) dosyaların yedeği `tool/pose_originals_backup/` altında duruyor.**
  - **Test:** `widget_test.dart`'a Kral Zibo'yu satın alıp giyen, `950 ZC` fiyat etiketini VE giyilince
    Ana Sayfa'nın `zibo_king_pose1.png`'ye geçtiğini doğrulayan yeni bir uçtan uca senaryo eklendi.
- **`CostumeProvider`** yalnızca "hangi kostümler sahiplenildi (`ownedIds`) / hangisi giyili
  (`equippedId`)" durumunu tutar — `GoalsProvider`'ın `CoinProvider`'a bağımlı olmaması gibi, coin
  harcamasından bilerek bağımsız. Satın alma akışını yürütmek (`CoinProvider.spendOnCostume` + bakiye
  kontrolü) `CostumeCard`'ın sorumluluğunda. `SharedPreferences` ile kalıcı (`ownedCostumeIds` bir
  `StringList`, `equippedCostumeId` nullable bir `String`) — tıpkı `ThemeProvider` gibi.
- `CostumeCard` üç görsel/etkileşim durumu var:
  - **Kilitli** (sahip olunmamış): görsel `Opacity(0.45)` ile soluk + köşede kilit rozeti, fiyat
    (`storeCoinAmount` ARB anahtarı yeniden kullanılıyor) net görünür, "Satın Al" butonu
    (`storeBuyButton` yeniden kullanılıyor). Bakiye yetmiyorsa buton pasifleştirilmez — basılınca
    `showInsufficientCoinsWarning` ([coin_feedback.dart](lib/utils/coin_feedback.dart)) çağrılır
    (mevcut coin harcama butonlarıyla aynı UX kalıbı).
  - **Sahip olunan, giyili değil**: "Sahip olunan" rozeti; kart bir bütün olarak `InkWell` ile
    sarılı — dokununca giyilir (`CostumeProvider.toggleEquipped`).
  - **Giyili**: `colorScheme.primary` kenarlıklı vurgulu kart + "Giyili" rozeti; tekrar dokununca
    çıkarılır (varsayılan Zibo görünümüne döner) — toggle semantiği, ayrı bir "çıkar" kontrolü yok.
- **Zibo görseli gösteren SEKİZ ekranın HEPSİ** — `HomeScreen`, `GoalTrackingScreen`, `MoneyScreen`,
  `WaterTrackingScreen`, `DreamJournalScreen`, `GratitudeJournalScreen`, `MoodTrackingScreen`,
  `ManifestJournalScreen` — **her biri ayrı ayrı** `CostumeProvider.equippedId`'yi izleyip
  `findCostumeById` ile görsel yoluna çevirir; `null` ise (veya id listeden kaldırılmışsa)
  `assets/images/zibo_yeni.png`'ye düşer. Bu, sekiz yerde neredeyse birebir aynı 3 satırlık koddur —
  kasıtlı: ortak bir provider/servis soyutlaması gerektirmeyecek kadar küçük bir mantık, ayrı bir
  yardımcı fonksiyon/widget'a çıkarmak gereksiz dolaylılık eklerdi. **`equippedId`/
  `equippedImageAsset` artık ekranda DOĞRUDAN `Image.asset`e verilmiyor** — ikisi de
  `ZiboAnimatedImage`e (`costumeId`/`fallbackImage` parametreleri) geçiriliyor; bkz. aşağıdaki
  "Zibo Poz/Animasyon Sistemi" bölümü.
  - **2026 güncellemesi — bug: yalnızca Ana Sayfa güncelleniyordu:** Kullanıcı bildirdi: bir kostüm
    giyildiğinde diğer 7 modül ekranındaki Zibo görseli DEĞİŞMİYORDU (sabit `zibo_yeni.png`'de
    kalıyordu) — kod incelendiğinde bu ekranların HİÇBİRİNİN `CostumeProvider`'ı hiç izlemediği
    görüldü (Ana Sayfa/Hedef Takibi/Para ve Birikim ÜÇÜ zaten izliyordu, kalan 5 modül — Su Takibi,
    Rüya/Şükran/Ruh Hali/Manifest Günlüğü — hiç izlemiyordu). **Merkezi bir state zaten vardı**
    (`CostumeProvider` — kullanıcının istediği "seçili kostümü merkezi bir state'te tut" tam
    olarak buydu), eksik olan yalnızca kalan 5 ekranın da onu `context.watch` etmesiydi; her birine
    yukarıdaki üç yerdeki AYNI 3 satırlık desen kopyalandı, `Image.asset` çağrılarındaki sabit
    `_defaultZiboImage` yerine hesaplanan `equippedImageAsset` kullanıldı.
- **Coin Test Paneli'ndeki eski "Kozmetik (-150)" test butonu kaldırıldı** — bu gerçek kostüm
  sistemi tarafından tamamen kapsandığı için artık gerek yok. Bununla birlikte `CoinProvider`'daki
  `spendCosmetic` (100-300 ZC dar aralığıyla sınırlı, gerçek kostüm fiyatlarına — 400-30000 —
  uymuyordu) kaldırılıp yerine sınırsız `spendOnCostume({costumeName, cost})` eklendi.
- **Bulunan gerçek bug — kostüm/tema isimleri dil değişince Türkçe kalıyordu:** `Costume.name`/
  `AppThemeOption.name` (ve aynı adı taşıyan `AppThemeOption`'daki alan) `const` veri listelerinde
  (`costumes.dart`/`app_themes.dart`) SABİT Türkçe string olarak tanımlı — `zibo_messages.dart`
  gibi "içerik havuzu" değil, kısa UI etiketleri (buton/kart metni gibi) olduğu için aslında ARB'ye
  ait olmaları gerekiyordu, ama ilk yazımda gözden kaçtı. Kullanıcı üç dilde de (TR/EN/ES) aynı
  sorunu bildirdi. **Çözüm:** ARB'ye `costumeName<Id>`/`themeName<Id>` anahtarları (11+5, TR/EN/ES)
  eklendi; `Costume`/`AppThemeOption` modellerine `String localizedName(AppLocalizations l10n)`
  metodu eklendi (id → doğru ARB getter'ı eşleyen bir `switch`) — `name` alanı YALNIZCA dahili/
  geliştirme referansı olarak kaldı, dokümantasyonda "EKRANDA GÖSTERMEYİN" diye açıkça işaretlendi.
  `CostumeCard`/`ThemeOptionCard`'daki HER görüntüleme noktası (kart başlığı, satın alma SnackBar'ı,
  semantics etiketleri, `CoinProvider.spendOnCostume`/`spendOnTheme`'e geçirilen işlem geçmişi
  etiketi) `costume.name`/`theme.name` yerine `costume.localizedName(l10n)`/
  `theme.localizedName(l10n)` kullanacak şekilde güncellendi. Gerçek cihazda üç dilde de
  (İngilizce: "Hippie Zibo"/"Sunset", İspanyolca: "Zibo Hippie"/"Atardecer") doğrulandı.
  **Bu kategori bir daha tekrarlanmasın diye kural:** `const` bir veri listesindeki (dosya adı,
  gradyan rengi gibi) SABİT bir alan kullanıcıya GÖRÜNÜYORSA (kart başlığı, buton metni, snackbar,
  semantics etiketi), o alan `BuildContext`'siz oluşturulduğu için doğrudan ARB'ye taşınamaz —
  bunun yerine modele bir `id`→ARB-getter eşleyen `localizedX(AppLocalizations l10n)` metodu ekleyin
  ve TÜM görüntüleme noktalarını ona geçirin, ham alanı asla `Text(...)`/`SnackBar(...)`/
  `Semantics(label:...)` içinde kullanmayın.
- **Gotcha (görsel doğrulamada yakalandı):** İlk `childAspectRatio` değeri (0.78) kilitli kartlarda
  ("Satın Al" butonu dahil en uzun durum) ~5px `RenderFlex overflow`'a yol açtı — bu yalnızca
  `flutter test`'te DEĞİL, gerçek tarayıcıda da görülen gerçek bir taşma hatasıydı (widget testleri
  overflow'u varsayılan olarak assertion'a çevirmiyor, sessizce geçebilir). `0.66`'ya düşürülünce
  düzeldi. Bir kart tasarımını değiştirirken en UZUN durumu (burada: kilitli, buton dahil) göz önünde
  bulundurun.
- **2026 güncellemesi — TÜM kostümler hedef tamamlayarak da (ücretsiz) açılabilir, zorluk fiyata
  göre ölçeklenir.** Kullanıcı isteği: kostümler yalnızca parayla değil, ilgili bir hedefi
  tamamlayınca da açılabilsin; ucuz kostümler kolay/kısa vadeli hedeflerle, pahalı kostümler zor/
  uzun vadeli hedeflerle. İKİ yol da geçerli — hangisi ÖNCE gerçekleşirse kostüm o yoldan açılıyor.
  - **Yeni `CostumeUnlockType` enum + `CostumeUnlockRequirement`**
    ([costume_unlock_requirement.dart](lib/models/costume_unlock_requirement.dart)) — üç tür:
    `goalStreak` (`GoalsProvider.longestStreak`), `goalCompletions`
    (`GoalsProvider.completions.length`, tamamlanan 7-günlük hedef döngüsü sayısı, SINIRSIZ büyür),
    `waterDaysCompleted` (YENİ `WaterProvider.completedDaysCount` getter'ı — su hedefinin
    tamamlandığı toplam gün sayısı, o da sınırsız büyür). `Costume`'a nullable bir
    `unlockRequirement` alanı eklendi.
  - **`goalStreak` BİLEREK yalnızca EN ucuz kostümde (zibo_hippi, hedef 3) kullanıldı** —
    `longestStreak` mimari gereği ASLA 7'yi aşamaz (bir 7 günlük döngü tamamlanınca/bozulunca
    sıfırlanıyor, bkz. `GoalsProvider` dokümantasyonu) — kullanıcının "30-60 gün streak" gibi üst-
    tier örnekleri bu yüzden `goalCompletions`/`waterDaysCompleted`'e (ikisi de sınırsız büyüyen
    metrikler) eşlendi, kullanıcının kendi "örn." ifadesiyle bunların katı bir gereksinim olmadığı
    yorumlanarak. `costumes.dart`'taki 16 kostümün TAMAMI artık bir gereksinim taşıyor, fiyatla
    monoton artan zorlukta (tam tablo o dosyanın dokümantasyonunda) — `zibo_hippi` = kullanıcının
    kendi "3 gün streak" örneği, `zibo_elmas` (en pahalı) = kullanıcının kendi "100 gün su takibi"
    örneği.
  - **`CostumeProvider.reconcileGoalUnlocks(goals, water)`** (YENİ) — `GoalsProvider`/
    `WaterProvider`'ı CONSTRUCTOR'dan değil PARAMETRE olarak alıyor (`CostumeProvider`'ın coin/
    sound'dan bağımsız olma felsefesiyle AYNI gerekçe — bu provider diğerlerine KALICI bağımlı
    değil, yalnızca çağıranın o anki verisini geçici okuyor). Her kostümü dolaşıp henüz sahip
    olunmamış + gereksinimi karşılananlar için `markOwned(id)`'yi (satın almadan TAMAMEN bağımsız,
    `CostumeCard._buy`'ın çağırdığı AYNI metot) çağırıp yeni açılanların id listesini döner.
    `StoreScreen`'in Mağaza'ya her girişte tetiklenen `isActive`/`didUpdateWidget` kancasından
    (`_maybeShowAdFreePromo` ile AYNI desen) çağrılıyor — yeni açılan varsa
    `costumeUnlockedViaGoalMessage` SnackBar'ı gösteriliyor. Genel bir listener/arka plan servisi
    GEREKMEDİ — `DailyRewardsProvider.reconcileForToday()` gibi "ilgili ekrana her girişte kontrol
    et" deseninin bir tekrarı.
  - **`CostumeCard` — dördüncü görsel alt-durum:** kilitli VE `unlockRequirement != null` iken,
    mevcut fiyat+"Satın Al" satırının ALTINA (kullanıcının açık isteği "hem fiyatı hem de X bilgisini
    BİRLİKTE göster") kompakt bir ilerleme satırı ekleniyor (ör. "🎯 3/5 gün su takibiyle ücretsiz
    aç") — `_unlockProgressText` (dosyanın sonunda, private) `CostumeProvider.reconcileGoalUnlocks`'
    taki AYNI küçük `switch`'in SALT GÖSTERİM amaçlı bir kopyası (bilerek paylaşılan bir yardımcıya
    çıkarılmadı — üç satırlık bir eşleme için ayrı bir soyutlama gereksiz dolaylılık eklerdi).
    `current`, `target`'ı AŞMAYACAK şekilde kırpılıyor (reconcile henüz çalışmadan önceki tek bir
    karede "6/5" gibi mantıksız bir görünüm olmasın diye).
  - **Bu projede DÖRDÜNCÜ kez tekrarlanan `childAspectRatio` overflow dersi:** yeni ilerleme satırı
    kilitli kartı bir satır daha uzattığı için `_CostumesSection`'daki oran `0.66`'dan `0.56`'ya
    düşürüldü (`flutter test` ile mevcut kostüm satın alma/giyme senaryolarının hâlâ overflow'suz
    geçtiği doğrulandı).
  - **Test:** `costume_provider_test.dart`'a yeni bir grup (5 test — eşik altı no-op, `goalStreak`/
    `goalCompletions`/`waterDaysCompleted` her biri için gerçek provider API'leriyle [enjekte
    edilebilir saatle] sürülen bir eşik-aşımı senaryosu, zaten sahip olunan bir kostümün tekrar
    "yeni açıldı" sayılmadığı) + `water_provider_test.dart`'a `completedDaysCount` testi. Gerçek
    cihazda/tarayıcıda görsel doğrulama bu turda YAPILMADI — yalnızca `flutter test`'teki 310
    testle kapsandı.

### Zibo Poz/Animasyon Sistemi ([costume_poses.dart](lib/data/costume_poses.dart), [zibo_animated_image.dart](lib/widgets/zibo_animated_image.dart), [zibo_pose_provider.dart](lib/providers/zibo_pose_provider.dart))

- **2026 yeni özellik — "Akinatör tarzı" poz döngüsü.** Kullanıcı isteği: Zibo'nun her kostümü için
  tek bir statik görsel yerine, birkaç poz görseli arasında hafif bir fade (crossfade) ile geçiş
  yapan bir animasyon sistemi kurulsun; henüz poz seti eklenmemiş bir kostüm için hata vermeden
  mevcut TEK statik görsele düşülsün.
- **`costume_poses.dart` — kostüm id → poz listesi eşlemesi, tek yerde:**
  - `defaultZiboPoses` (5 görsel, `zibo_df_pose1-5.png`) — kostümSÜZ (varsayılan) Zibo için. Bu,
    kostümsüz durumun eski sabit tek görseli `zibo_yeni.png`'nin YERİNİ ALDI — kostümsüz Zibo ARTIK
    da bu 5 poz arasında döngü yapıyor (`zibo_yeni.png` yalnızca `defaultZiboImage` sabiti olarak,
    "poz seti YOKSA" durumundaki son çare düşüş noktası olarak kod tabanında kaldı, kullanıcıya
    normal akışta neredeyse hiç görünmüyor).
  - `costumePoses` (`Map<String, List<String>>`) — **2026 GÜNCELLEMESİ: artık 16 kostümün TÜMÜ
    burada** (`zibo_sporcu` 4 poz, `zibo_rapci` 4 poz, `zibo_punk` 2 poz, `zibo_asker` 3 poz,
    `zibo_gladyator` 4 poz, `zibo_hippi` 4 poz, `zibo_hoca` 3 poz, `zibo_korsan` 4 poz — kullanıcı
    "pose1-3" dedi ama eklenen dosyalarda 4. bir poz da vardı, `zibo_koran_pose4.png` dosya adındaki
    YAZIM HATASI (`korsan` yerine `koran`) düzeltilip yeniden adlandırıldı, dördü de kullanılıyor —,
    `zibo_zombi` 3 poz, `zibo_altin` 3 poz, `zibo_elmas` 3 poz; en son eklenen 5'i — `zibo_gentleman`
    3 poz [AYNI yazım hatası deseni, bkz. yukarıdaki "Kostümler" bölümü], `zibo_samurai` 2 poz,
    `zibo_cyborg` 2 poz, `zibo_astronot` 3 poz, `zibo_king` 3 poz). **Bu Map'te girdisi OLMAYAN bir
    kostüm id'si için** (gerçek bir kostümde artık YOK, ama hipotetik/gelecekte eklenecek bir
    kostüm için hâlâ geçerli) `posesForCostume()` `null` döner ve `ZiboAnimatedImage` otomatik olarak
    `Costume.imageAsset`'teki mevcut TEK statik görsele düşer — **hiçbir kod değişikliği gerekmeden,
    yalnızca bu Map'e yeni bir girdi eklemek yeterli** olacak şekilde tasarlandı (yeni poz setleri
    eklenirken `tool/process_all_poses.dart`'a bkz. — aşağıdaki "GLOBAL boyut normalizasyonu"
    bölümü). `zibo_animated_image_test.dart`'taki "poz seti yok" testi bu yüzden artık UYDURMA bir
    costume id (`'zibo_test_kostumu_poz_seti_yok'`) kullanıyor — gerçek bir kostüm örneği kalmadı.
  - `posesForCostume(String? costumeId)` — `null` (kostümsüz) ise `defaultZiboPoses`, bir kostüm
    id'si verilip Map'te karşılığı yoksa `null` (çağıran taraf statik görsele düşer) döner.
- **2026 GÜNCELLEMESİ — otomatik zamanlayıcı TAMAMEN kaldırıldı, poz artık DOKUNUŞLA ilerliyor:**
  İlk sürüm `Timer`-tabanlıydı (her ekran kendi başına 3.5 saniyede bir otomatik ilerliyordu).
  Kullanıcı geri bildirimi: "poz döngüsü çok hızlı, [Ana Sayfa'da] kullanıcı Zibo'nun üstüne
  tıkladığında söz değişiyor ya, 5-10 tıklamadan sonra değişsin pozlar... diğer sayfalarda ana
  sayfadaki poz ne ise o olsun, sürekli değişmesin." Bu, TEK bir değişiklik değil, mimarinin
  KENDİSİNİ değiştirdi:
  - **`ZiboPoseProvider`** (YENİ, `main.dart`'a `uid` VERİLMEDEN eklendi — kalıcı değil, saf
    görsel/UI durumu, `CloudStateStore` kullanmıyor) TEK, paylaşılan bir `poseStep` (int) sayacı
    tutuyor. `registerZiboTap()` yalnızca `HomeScreen._onZiboTap()`'ten (mesaj değiştiren AYNI
    dokunuş) çağrılıyor — HER dokunuşta değil, rastgele 5-10 dokunuşta bir (`Random.nextInt`,
    eşik her ilerlemeden sonra yeniden seçiliyor ki hep aynı sayıda dokunuş beklenmesin).
  - **`ZiboAnimatedImage` artık kendi İÇSEL zamanlayıcısına SAHİP DEĞİL** — hangi pozun
    gösterileceği tamamen DIŞARIDAN, yeni bir `poseStep` (int) parametresiyle kontrol ediliyor
    (`poses[poseStep % poses.length]`). Sekiz ekranın HEPSİ `context.watch<ZiboPoseProvider>()
    .poseStep`'i okuyup DOĞRUDAN bu parametreye geçiriyor — yalnızca Ana Sayfa bu sayacı
    İLERLETİYOR (`registerZiboTap`), diğer yedisi SALT-OKUNUR izliyor. Bu, "diğer sayfalarda ana
    sayfadaki poz ne ise o olsun" isteğini TAM OLARAK karşılıyor: hepsi AYNI paylaşılan sayacı
    okuduğu için, Ana Sayfa'da poz ilerleyince TÜM ekranlar (o anda görünür olsun ya da olmasın,
    bir sonraki `build()`'lerinde) otomatik olarak senkron kalıyor.
  - **Crossfade artık `poseStep`/`costumeId` prop DEĞİŞİKLİĞİNE tepki olarak tetikleniyor**
    (`didUpdateWidget`), sabit aralıklı bir `Timer`e değil. Gösterilen asset, `widget.poseStep`'ten
    DOĞRUDAN türetilmiyor — ayrı bir `_displayedAsset` state alanında tutuluyor: `didUpdateWidget`
    hedef asset'in DEĞİŞTİĞİNİ görürse, `_fadeController.reverse()` ile ÖNCE mevcut (`_displayedAsset`
    hâlâ ESKİ değerde) pozu 0'a soluyor, SONRA `setState` ile `_displayedAsset`'i hedefe güncelliyor,
    SONRA `forward()` ile 1'e geri soluyor. **Bu ayrım kritik:** `_displayedAsset`, `build()`'de
    `widget.poseStep`'ten DOĞRUDAN hesaplanmış olsaydı, Flutter `didUpdateWidget`'tan HEMEN SONRA
    yeni `widget`'la `build()`'i çalıştıracağı için görüntü ANINDA yeni poza atlar, "eski pozu
    gösterirken sol" adımı hiç gerçekleşmezdi.
  - **Kostüm değişince (`costumeId` farklıysa) fade ATLANIYOR — ANINDA geçiş.** `poseStep` TÜM
    kostümler arasında PAYLAŞILAN tek bir sayaç olduğu için (kostüme özel bir sayaç DEĞİL) "sıfırlama"
    kavramı yok — yeni kostümün `poses[poseStep % newPoses.length]`'i, fade beklenmeden bir sonraki
    frame'de gösteriliyor. Gerekçe: iki FARKLI kostümün sanatı arasında yavaşça çapraz-solmak (biri
    diğerine "dönüşüyormuş" gibi görünmek) görsel olarak yanlış/kafa karıştırıcı olurdu.
  - **`disableAnimations`'a saygı GEREKMİYOR ARTIK** — eski Timer-tabanlı tasarımda `WheelTriggerButton`
    deseniyle aynı "hareketi azalt" kontrolü gerekliydi (sürekli tekrar eden bir animasyon
    `pumpAndSettle()`'ı sonsuza dek bekletirdi); artık poz değişimi salt REAKTİF (bir prop değişimine
    tepki) olduğu için böyle bir risk YOK — `poseStep` değişmediği sürece hiçbir şey tetiklenmiyor.
  - **Test uyumluluğu — `imageKey`, SABİT bir `Image` örneğine uygulanıyor** (değişmedi): mevcut
    testler (`find.byKey(const Key('ziboCharacterImage'))` + `tester.widget<Image>(...)`) o key'in
    gerçekten bir `Image` widget'ına ait olmasını VE poz değişse bile AYNI elemanın bulunmaya devam
    etmesini varsayıyor — bu yüzden crossfade `AnimatedSwitcher`'ın örtük key-tabanlı çocuk
    değişimiyle DEĞİL, elle yönetilen `AnimationController` + `FadeTransition` ile yapılıyor.
  - **Test:** `zibo_animated_image_test.dart` (baştan yazıldı, artık widget'ı `poseStep` prop'unu
    doğrudan değiştirerek test ediyor, herhangi bir zaman/`Timer` simülasyonuna GEREK YOK): poz seti
    olmayan bir kostüm sabit statik görsele düşer (poseStep değişse de); kostümsüz Zibo `poseStep %
    5` ile doğru pozu gösterir; kostüm değişince yeni kostümün pozu ANINDA (fade beklemeden, tek bir
    `pump()` sonrası) gösterilir; AYNI kostümde `poseStep` değişince crossfade `pumpAndSettle()`
    sonunda hedef poza ulaşır. `main.dart`'ın `_buildAppWithClock()` yardımcısına (bkz. "Test
    kalıpları" bölümü) ve `manifest_journal_screen_test.dart`'ın kendi provider kurulumlarına
    `ZiboPoseProvider` eklenmesi gerekti — sekiz ekranın hepsi artık onu `watch` ediyor.
- **Poz görsellerinin boyut TUTARSIZLIĞI matematiksel olarak düzeltildi (`tool/normalize_pose_sizes.dart`):**
  Kullanıcı bildirdi: "poz değişince boyut değişmesin, pozdan kaynaklı bir görsel diğerinden büyük/
  küçük olabilir, matematiksel bir şekilde aynı ölçüde olsun." Tüm poz PNG'lerinin AYNI kanvas
  boyutunda (1408×768) olduğu doğrulandı (`tool/measure_pose_bounds.dart` ile) — ama karakterin
  şeffaf-olmayan İÇERİK sınır kutusu pozdan poza ÖNEMLİ ÖLÇÜDE farklıydı (ör. `zibo_rapci_pose1`
  içerik yüksekliği 533px iken `zibo_rapci_pose4` 752px — aynı genişlikte gösterilince karakterin
  gözle görülür şekilde küçük/büyük görünmesine yol açıyordu).
  - **`tool/normalize_pose_sizes.dart`** (YENİ, tek seferlik görsel işleme betiği — `remove_bg.dart`/
    `crop_transparent.dart` ile AYNI "dev-only, asset'lerin üzerine yazan" desende, bkz. "Görsel
    işleme" bölümü): her kostümün poz SETİ için (DF/Sporcu/Rapçi/Punk, birbirinden BAĞIMSIZ dörder
    grup) o setteki EN BÜYÜK içerik yüksekliğini hedef alıp, diğer pozları bu hedefe göre oranlı
    (`img.copyResize`, kübik interpolasyon) yeniden ölçekleyip orijinal 1408×768 kanvasın TAM
    ORTASINA (hem X hem Y) yerleştirerek geri yazıyor. Sonuç: her setin İÇİNDEKİ tüm pozlar artık
    BİREBİR aynı içerik yüksekliğine VE aynı merkez noktasına (`centerX=704, centerY=384`) sahip —
    `dart run tool/measure_pose_bounds.dart` ile doğrulandı.
  - **Orijinal (ölçeklenmemiş) dosyaların yedeği `tool/pose_originals_backup/` altında duruyor**
    (pubspec `assets:` kapsamının DIŞINDA, uygulamaya dahil edilmiyor) — bu proje bir git deposu
    DEĞİL (`Is a git repository: false`), yani otomatik bir versiyon geçmişi yok; betik hedef
    PNG'lerin ÜZERİNE YAZDIĞI için geri dönmek gerekirse kaynak buradan kopyalanabilir.
  - **Ölçekleme yalnızca YUKARI (küçük pozları büyütme) yönünde** — hedef her zaman setin
    kendi maksimumu olduğu için hiçbir pozun küçültülmesi (ve dolayısıyla orijinal çözünürlükten
    kayıp yaşaması) gerekmedi; en agresif ölçek (`zibo_rapci_pose1`, 1.41x) bile kübik
    interpolasyonla görünür bir bulanıklaşma yaratmadı (elle görsel kontrol edildi).
  - **Gelecekte yeni bir kostüme poz seti eklenirken bu betik YENİDEN KULLANILABİLİR** — `_poseSets`
    listesine yeni dosya yollarını eklemek yeterli; hedef otomatik olarak o setin kendi maksimumuna
    göre hesaplanıyor, elle ölçüm/oran girmeye gerek yok.
- **2026 İKİNCİ güncelleme — `width` yerine `height`: karakter hâlâ küçük görünüyordu, kök neden
  BAMBAŞKA bir şeydi.** İlk büyütme turundan (`width` artırma) SONRA bile kullanıcı "hâlâ çok
  küçük" diye bildirdi ve karşılaştırma için eski/referans bir ekran görüntüsü ekledi. Gerçek kök
  neden `width` değerinin küçüklüğü DEĞİLDİ — normalize edilmiş poz PNG'leri hâlâ 1408×768'lik GENİŞ
  kanvasın TAMAMIYDI, ama karakterin kendisi bu kanvasın yalnızca ~%30-40'lık bir GENİŞLİK dilimini
  kaplıyordu (bkz. yukarıdaki içerik ölçümleri — içerik genişliği 400-600px, kanvas 1408px).
  `Image.asset(width: X)` yalnızca `width` verildiğinde yüksekliği görselin TÜM kanvasına göre
  hesapladığı için, `width`'i ne kadar büyütürseniz büyütün, görünen KARAKTER kutunun yalnızca küçük
  bir kısmını dolduruyordu — büyütülen şey büyük ölçüde ŞEFFAF ALANDI, karakterin kendisi değil.
  - **`tool/crop_pose_content.dart`** (YENİ) — normalize edilmiş (bkz. yukarıda, her SETTEKİ tüm
    pozlar zaten birebir aynı içerik yüksekliğine sahip) poz PNG'lerini karakterin gerçek sınır
    kutusuna (+ yüksekliğin %3'ü kadar küçük bir pay) SIKI kırpar, geniş/boş 1408×768 kanvası
    tamamen atar. Sonuç: bir SETTEKİ tüm pozlar hâlâ BİREBİR AYNI YÜKSEKLİĞE sahip (ör. DF seti
    735px, Rapçi seti 768px) ama GENİŞLİK artık pozdan poza DOĞAL olarak farklı (ör. kollar açık
    bir poz, kollar yanda duran bir pozdan daha geniş) — bu FARK bilerek KORUNDU, karakterin
    kendi silüetinin bir parçası.
  - **`ZiboAnimatedImage`: `width` parametresi tamamen kaldırılıp `height` ile değiştirildi.**
    Yalnızca `height` vermek (genişliği görselin kendi en-boy oranına bırakmak) İKİ şeyi birden
    garantiliyor: (1) bir SETTEKİ tüm pozlar aynı yükseklikte olduğu için, pozlar arasında geçişte
    ekrandaki DİKEY yerleşim (Column'daki diğer öğelerin konumu) ASLA sıçramıyor — "poz değişince
    boyut değişmesin" isteğinin LAYOUT tarafı böyle sağlanıyor; (2) kırpma sayesinde artık verilen
    `height` kutusu neredeyse TAMAMEN karakterle doluyor, şeffaf israf YOK — bu da "karakter küçük
    görünüyor" şikâyetinin GERÇEK çözümü oldu (yalnızca `width`'i büyütmek bunu asla çözemezdi).
  - **Sekiz ekranın hepsi güncellendi:** Ana Sayfa'da `ziboWidth` (ekran GENİŞLİĞinin oranı) yerine
    `ziboHeight = (MediaQuery.height * 0.36).clamp(260, 400)` (ekran YÜKSEKLİĞinin oranı) kullanılıyor;
    kalan yedi ekranda sabit `width: 112` yerine sabit `height: 200` kullanılıyor.
  - **`profile_screen.dart`'taki `width: 112` KARIŞTIRILMAMALI** — o, kullanıcının PROFİL FOTOĞRAFI
    dairesinin (`SizedBox(width: 112, height: 112)`, `CircleAvatar`) boyutu, Zibo görseliyle hiç
    ilgisi yok; bu arc'ta BİLEREK dokunulmadı.
  - **Test gotcha'sı — büyütülmüş görsel bazı ekranların içeriğini test viewport'unun (412×915)
    altına itti:** `manifest_journal_screen_test.dart`'taki 3 test, artık daha uzun sayfada
    aşağıda kalan "Kaydet" `FilledButton`'ına ve geçmiş galerisindeki (lazy `GridView.builder`,
    `shrinkWrap: true` OLSA BİLE hâlâ viewport-dışını geç inşa ediyor — bkz. "Test kalıpları"
    bölümündeki aynı ders) yeni eklenen karta artık `tester.tap()`/`find.text()` ile doğrudan
    erişemiyordu. **İki AYRI düzeltme deseni gerekti:** (a) buton için `tester.ensureVisible()` +
    `tester.tap()` denendi ama kaydırma tam viewport'a girecek kadar yetmedi (offset hâlâ sınırın
    birkaç piksel dışındaydı) — bunun yerine mevcut CLAUDE.md gotcha'sındaki (`GridView`/hit-test
    uyuşmazlığı) `tester.widget<FilledButton>(finder).onPressed!()` DOĞRUDAN çağrı deseni kullanıldı
    (kaydırmaya hiç gerek kalmadan, hit-test'i tamamen atlıyor); (b) geçmiş galerisindeki metin
    için `tester.scrollUntilVisible(finder, delta, scrollable: ...)` kullanıldı. **Yeni bir gotcha
    da burada keşfedildi:** `scrollable:` parametresi için `find.byType(Scrollable).last` bazı
    testlerde YANLIŞ Scrollable'ı (aktif bir `TextField`'ın kendi İÇSEL `EditableText` kaydırma
    alanı — `TextField`'lar da birer `Scrollable` içerir) seçip testi BAŞKA bir hit-test hatasıyla
    kırdı; `.first` (sayfanın en DIŞTAKİ/ATA `ListView`'i, ağaçta her zaman iç içe TextField'lardan
    ÖNCE gelir) doğru ve güvenilir seçimdi. **Bir sonraki `scrollUntilVisible` kullanımında,
    sayfada bir `TextField` de varsa `.last` yerine `.first` ile başlayın.**
- **2026 ÜÇÜNCÜ güncelleme — poz sistemi TÜM kostümlere genişletildi + GLOBAL (kostümler-arası) boyut
  normalizasyonu (`tool/process_all_poses.dart`).** Kullanıcı 8 yeni kostüm için poz seti PNG'leri
  ekledi (asker/gladyator/hippi/hoca/korsan/zombi/altin/elmas) ve istek şuydu: "bir kostümden diğerine
  geçildiğinde veya aynı kostümün pozları arasında geçiş yaparken Zibo'nun ekrandaki boyutu ani şekilde
  büyüyüp küçülmesin, tüm poz görselleri aynı çerçeve/oran içinde gösterilsin." Yukarıdaki
  `tool/normalize_pose_sizes.dart` yalnızca AYNI kostümün KENDİ pozları arasında tutarlılık
  sağlıyordu (her set kendi yerel maksimumuna göre) — bu, kostümler ARASI tutarlılığı GARANTİ ETMİYORDU
  (ör. bir önceki turda Sporcu seti ~629px, Rapçi seti 768px içerik yüksekliğinde kalmıştı).
  - **Çözüm — TEK bir global hedef:** `tool/measure_pose_bounds.dart` TÜM 12 kostüm setinin (4 eski +
    8 yeni) içerik sınır kutularını ölçüp `--- GLOBAL MAX CONTENT HEIGHT: 763 ---` şeklinde global
    maksimumu raporlayacak şekilde genişletildi (`_sets` Map'i, hem bu betikte hem
    `process_all_poses.dart`'ta AYNI). `tool/process_all_poses.dart` (YENİ, `normalize_pose_sizes.dart`
    + `crop_pose_content.dart`'ın YERİNE geçen TEK-geçişli birleşik betik) sonra 41 poz PNG'sinin
    HEPSİNİ bu TEK sabit hedefe (763px) göre kırpıp ölçekliyor — artık yalnızca bir setin KENDİ pozları
    değil, 12 kostümün TAMAMI birbiriyle aynı nihai yükseklikte.
  - **Eski (df/sporcu/rapçi/punk) pozlar YENİDEN İŞLENMEDEN önce yedekten GERİ YÜKLENDİ:** bu 4
    kostümün pozları önceki turda ZATEN kırpılmış/ölçeklenmişti (orijinal 1408×768 kanvas referansı
    kayboldu) — doğrudan yeniden işlemek hataları katlardı. `tool/pose_originals_backup/`'taki
    dokunulmamış orijinaller `assets/images/`'e geri kopyalanıp SONRA global betik çalıştırıldı.
  - **Kullanıcı-kaynaklı dosya adı yazım hatası düzeltildi:** `zibo_koran_pose4.png` → `zibo_korsan_pose4.png`
    (bkz. yukarıdaki `costumePoses` notu).
  - **Doğrulama:** işlem sonrası `measure_pose_bounds.dart` TEKRAR çalıştırılıp tüm 41 çıktı dosyasının
    BİREBİR `763` yükseklikte olduğu (genişlik doğal en-boy oranına göre 490-736px arasında serbest)
    doğrulandı. Ölçek çarpanları 0.993x (zaten uzun boylu pozlar, ör. Rapçi/Punk) ile 1.4x (en agresif,
    `zibo_sporcu_pose4`) arasında değişti — kübik interpolasyonla görünür bulanıklaşma yok (elle
    kontrol edildi).
  - **`costume_poses.dart` içine 8 yeni kostümün girdisi eklendi** (bkz. yukarıdaki `costumePoses`
    notu) — `ZiboAnimatedImage`'ı kullanan 8 ekranın HİÇBİRİ değişmedi, otomatik olarak yeni
    kostümlerin poz döngüsüne geçti.
  - **Test etkisi:** `zibo_hippi` artık gerçek bir poz seti aldığı için, onu "poz seti YOK" örneği
    olarak kullanan iki eski test (`widget_test.dart`'taki kostüm satın alma testi, `zibo_animated_
    image_test.dart`'taki fallback testi) güncellendi — ilki artık `zibo_hippi_pose1.png` bekliyor,
    ikincisi artık gerçek olmayan uydurma bir costume id kullanıyor (bkz. yukarı).
- **Gerçek cihazda GÖRSEL doğrulama:** APK her iki turda da (width→height geçişi dahil) yeniden
  derlenip telefona kuruldu, `adb shell monkey` ile başlatılıp logcat'te çökme izi olmadığı VE
  sürecin canlı kaldığı doğrulandı. Web preview'daki CanvasKit tıklama etkileşimlerinin bu ortamda
  güvenilir çalışmaması (bkz. "Temalar" bölümündeki AYNI önceden belgelenmiş gotcha) nedeniyle poz
  döngüsünün/crossfade'in/büyütülmüş boyutun CANLI görsel doğrulaması kullanıcının kendi cihazında
  yapılmalı — özellikle: Ana Sayfa'da Zibo'ya birkaç kez dokunup (5-10 arası) pozun DEĞİŞTİĞİNİ,
  geçişin yumuşak olduğunu, karakterin artık gerçekten BÜYÜK (kutuyu dolduran, çevresinde geniş
  şeffaf boşluk OLMAYAN) göründüğünü, Sporcu/Rapçi/Punk kostümlerinde pozlar arasında boyutun sabit
  kaldığını, ve diğer 7 ekranın Ana Sayfa'yla AYNI pozu gösterdiğini kontrol etmek.

### Temalar ([app_theme_option.dart](lib/models/app_theme_option.dart), [app_themes.dart](lib/data/app_themes.dart), [app_theme_provider.dart](lib/providers/app_theme_provider.dart), [theme_option_card.dart](lib/widgets/theme_option_card.dart), [theme_particle_effect.dart](lib/widgets/theme_particle_effect.dart), [animated_theme_overlay.dart](lib/widgets/animated_theme_overlay.dart), [starry_gradient_background.dart](lib/widgets/starry_gradient_background.dart))
- Zibo Coin ile satın alınabilen **22 adet** **kod-tabanlı** (görsel asset gerektirmeyen, tamamen
  kodla üretilen) tema: 15'i statik gradyan (5 orijinal + 10 YENİ — bkz. altta "2026 güncellemesi",
  250-500 ZC), 7'si "Premium/Animasyonlu" (canlı parçacık animasyonlu, 650-900 ZC — bkz. altta).
  Mağaza'nın üçüncü segmenti ("Temalar", Coin Al/Kostümler'in yanında), `_ThemesSection` bu iki
  grubu [AppThemeOption.isPremiumAnimated]'a göre AYRI başlıklı iki `GridView`'de gösterir.
- **2026 güncellemesi — 10 yeni STANDART (statik gradyan, animasyonsuz) tema.** Kullanıcı isteği:
  mevcut kod-tabanlı statik tema sistemiyle AYNI mantıkla, ekstra asset gerektirmeden yalnızca renk
  paleti/gradyan; hepsi "manzara/atmosfer" temalı TEK bir listede (ayrı kategori YOK), mevcut
  standart temalarla (Gün Batımı/Okyanus/Orman/Gece Gökyüzü/Altın Çağ) tutarlı fiyat aralığında
  (250-500 ZC), her birinde küçük bir renk önizlemesi.
  - **Kod tarafında YENİ bir mekanizma GEREKMEDİ** — her biri `AppThemeOption`'ın var olan alanlarını
    (`lightColors`/`darkColors`/`lightPrimary`/vb.) dolduruyor, `animationType` hiç verilmiyor
    (varsayılan `ThemeAnimationType.none`) — bu da `isPremiumAnimated`'ı otomatik olarak `false`
    yapıp `_ThemesSection`'ın ZATEN var olan bölme mantığıyla (`.where((theme) =>
    !theme.isPremiumAnimated)`) diğer 5 standart temayla AYNI "Standart Temalar" `GridView`'inde,
    kod DEĞİŞİKLİĞİ olmadan listelenmesini sağlıyor. Küçük renk önizlemesi de zaten var olan
    `ThemeOptionCard` altyapısından (`theme.colorsFor(isDark)` ile beslenen `LinearGradient`)
    otomatik geliyor — o widget'a da dokunulmadı.
  - **10 yeni id:** `lavender_garden` (Lavanta Bahçesi, 300 ZC), `coral_reef` (Mercan Resifi,
    300 ZC), `cherry_orchard` (Vişne Bahçesi, 350 ZC), `mint_greens` (Nane Yeşillikleri, 250 ZC),
    `desert_dunes` (Çöl Kumulları, 250 ZC), `moonlight` (Ay Işığı, 400 ZC), `copper_hills` (Bakır
    Tepeler, 350 ZC), `emerald_valley` (Zümrüt Vadisi, 400 ZC), `amethyst_cave` (Ametist Mağarası,
    450 ZC), `dusty_rose_dream` (Gül Kurusu Rüyası, 300 ZC). Fiyatlar mevcut 5 orijinal standart
    temanın (250-500 ZC) aralığında kalacak şekilde, "sıradan pastel" (250-300) ile "daha zengin/
    doygun palet" (400-450) arasında kabaca kademelendirildi — Altın Çağ'ın (500 ZC, en pahalı
    orijinal) üzerine hiçbiri çıkmadı.
  - **`isStarryInDark` YENİ temalardan hiçbirine verilmedi** — bu alan dokümantasyonda "yalnızca
    Gece Gökyüzü teması için" diye açıkça sınırlanmış tek bir görsel efekt (bkz. `AppThemeOption`
    dokümantasyonu); "Ay Işığı" gibi kavramsal olarak uygun görünen bir isim olsa bile bu deseni
    tekrarlamak yerine sade bir gradyan tercih edildi — tekilliği koruyup gelecekte biri bu alanı
    "birden fazla temada kullanılabilir" sanıp yanlış varsayımda bulunmasın diye.
  - **`AppThemeOption.localizedName`'e 10 yeni `case` eklendi** (`Costume.localizedName`/`theme
    NameCherryBlossom` ile AYNI id→ARB-getter deseni) + TR/EN/ES üç ARB dosyasına 10'ar
    `themeName<Id>` anahtarı (TR'de `@`-açıklamalı, EN/ES düz — dosyaların mevcut kuralı) +
    `flutter gen-l10n`.
  - **Test:** YENİ `test/app_themes_data_test.dart` — `appThemes.length == 22`, 10 yeni id'nin
    hepsinin bulunabildiği VE `animationType == none`/`isPremiumAnimated == false` olduğu (yanlışlıkla
    Premium bölümüne düşmediklerinin kanıtı), fiyatların 250-500 aralığında kaldığı, her birinin
    açık/koyu modda en az 2 gradyan durağı olduğu.
  - **Gerçek cihazda doğrulama:** Mağaza > Temalar'da 10 yeni temanın hepsi orijinal 5 standart
    temanın HEMEN ARDINDAN, aynı "Standart Temalar" başlığı altında, kendi gradyan önizlemesi ve
    doğru fiyatıyla listelendiği; listenin "Premium/Animasyonlu" bölümünden ÖNCE (Gül Kurusu
    Rüyası'ndan hemen sonra) net bir şekilde bittiği ekran görüntüleriyle doğrulandı.
- **Premium/Animasyonlu temalar — hafif, kod-tabanlı parçacık animasyonu.** Kullanıcı isteği: "birkaç
  Animasyonlu Tema ekleyelim, arka planda hafif bir hareket efekti olsun, telefon donanımını
  zorlamasın." Mimari:
  - **`ThemeAnimationType`** (`app_theme_option.dart`) — `none` + 7 tür: `snow`/`galaxy`/`confetti`
    (ilk eklenen üçlü) ve `hearts`/`notes`/`tropical`/`petals` (sonradan eklenen dörtlü — bkz. altta).
    `AppThemeOption.animationType != none` olan temalar `isPremiumAnimated == true` olur.
  - **`ThemeParticleEffect`** (`theme_particle_effect.dart`) — `type`'a göre ilgili `CustomPainter`'ı
    seçen tek bir widget. Her tür için: SABİT tohumlu (`Random(seed)`) bir parçacık listesi (BİR KEZ
    üretilir, her `paint()`'te AYNI dizilim — `StarryGradientBackground`'daki desenin AYNISI),
    `Animation<double> progress` (canlı kaplamada gerçek bir `AnimationController`, Mağaza kartı
    ÖNİZLEMESİNDE `AlwaysStoppedAnimation(0.35)` — İKİSİ de `Animation` arayüzünü karşıladığı için
    AYNI painter kodu paylaşılıyor, statik önizleme SIFIR ekstra animasyon maliyeti getirmiyor) ve
    `CustomPainter(repaint: progress)` (widget ağacını hiç yeniden inşa etmeden yalnızca canvas'ı
    yeniden çizen, en ucuz sürekli-animasyon deseni).
  - **`AnimatedThemeOverlay`** (`animated_theme_overlay.dart`) — `main.dart`'ın `MaterialApp.
    builder:` zincirinde `ThemeFadeOverlay`'in İÇİNE sarılı; `IgnorePointer` ile dokunuşları
    engellemeden bindirir. `animationType == none` iken widget hiçbir Stack/CustomPaint eklemeden
    doğrudan `child`'ı döner — maliyetsiz "kapalı" durum.
    - **2026 GÜNCELLEMESİ — hareketli katman ARTIK YALNIZCA Ana Sayfa'da.** Kullanıcı raporu:
      "canlı efekt tüm sayfalarda görünüyor, dikkat dağıtıyor/performansı zorluyor — sadece Ana
      Sayfa'da olsun, diğer sayfalarda tema hâlâ aktif olsun (renk paleti/arka plan) ama hareketli
      parçacık olmasın." İlk sürümde `AnimatedThemeOverlay` gerçekten TÜM sayfalarda gösteriliyordu
      (`main.dart`'ın `builder:` zinciri tüm `Navigator`'ı sardığı için) — bu, "canlı hareket TÜM
      uygulamada tutarlı görünsün" şeklindeki ESKİ isteğin doğrudan sonucuydu, ama kullanıcı
      deneyimini bozduğu ortaya çıktı. **`ColorScheme` uygulaması (bkz. yukarıdaki "İKİ katmanlı"
      madde) BU değişiklikten TAMAMEN BAĞIMSIZ, hiç dokunulmadı** — yalnızca parçacık KATMANI
      kısıtlandı, renk paleti/arka plan hâlâ tüm sayfalarda aktif temaya göre değişiyor.
      - **`isHomeTabActive`** (YENİ, `tab_navigation.dart`) — `homeTabRequest` ile AYNI dosyada,
        global bir `ValueNotifier<bool>` (varsayılan `true`, uygulama Ana Sayfa'da açıldığı için).
        `RootScreen`'in TÜM sekme geçişleri (`MainBottomBar`'ın dört `onXTap` callback'i, AppBar'ın
        "+" ikonu, bildirime dokununca gelen `homeTabRequest`) artık tek bir `_setSelectedIndex(int)`
        yardımcı metodundan geçiyor — bu metot hem `setState`'i hem `isHomeTabActive.value =
        index == 0`'ı BİRLİKTE yapıyor, tek bir noktadan.
      - **`AnimatedThemeOverlay`, `isHomeTabActive`'i dinliyor** (`initState`'te `addListener`,
        `dispose`'ta `removeListener`) — `_syncRunningState()` artık üç koşulu BİRLİKTE
        değerlendiriyor (`animationType != none && !reduceMotion && isHomeTabActive.value`):
        Ana Sayfa'dan başka bir sekmeye geçilince YALNIZCA `build()`'de katman gizlenmiyor, AYRICA
        `AnimationController` da `stop()` ediliyor (performans — arka planda gereksiz yere
        `repeat()` etmeye devam etmiyor). `build()` de aynı şekilde `!isHomeTabActive.value` iken
        doğrudan `widget.child`'ı dönüyor (`animationType == none` ile AYNI "maliyetsiz kapalı"
        yol).
      - **Bilinen/kabul edilen sınırlama:** bu mekanizma yalnızca `RootScreen`'in `IndexedStack`
        SEKME indeksini izliyor, NAVIGATOR YIĞININI değil — Ana Sayfa'dayken Ayarlar/bir modül
        ekranı PUSH edilirse (`isHomeTabActive` hâlâ `true` kalır, çünkü sekme indeksi
        değişmedi) katman teknik olarak arkadaki Ana Sayfa'nın üstünde açık kalmaya devam eder
        (yeni ekran onu görsel olarak zaten kapatıyor). Kullanıcının asıl şikayeti sekmeler arası
        geçişti (Hedef Takibi/Su Takibi/Mağaza/Profil/Ayarlar) — bu senaryoların HEPSİ doğru
        şekilde katmansız; yalnızca "Ana Sayfa'dan bir ekran push etme" kombinasyonu kapsam dışı
        bırakıldı (nadiren fark edilir, ekstra bir `NavigatorObserver` karmaşasına değmeyecek kadar
        küçük bir kenar durum).
      - **Test:** `animated_theme_overlay_test.dart`'ın `setUp()`'ına `isHomeTabActive.value =
        true` sabitlemesi eklendi (bu dosya `RootScreen`'i hiç kurmadığı için sekme geçişleriyle
        senkron değil — başka bir test dosyasının bıraktığı `false` durumu buraya sızmasın diye).
        `widget_test.dart`'taki Kış Teması e2e senaryosu güncellendi: Ana Sayfa'da katman VAR,
        Hedefler sekmesinde YOK, Ana Sayfa'ya dönünce TEKRAR VAR.
    - **Gotcha — `late final` alan başlatıcısı `dispose()`'da patlıyordu:** `_controller`
      `late final ... = AnimationController(...)` şeklinde alan başlatıcısıyla yazıldığında,
      `animationType == none` olduğu SÜRECE hiçbir kod yolu `_controller`'a dokunmuyordu — Dart'ın
      "late" alanları İLK ERİŞİMDE başlatması yüzünden bu ilk erişim `dispose()`'a denk geliyor,
      `vsync: this` artık deaktif olan context'in `TickerMode`'unu aramaya çalışıp "Looking up a
      deactivated widget's ancestor is unsafe" hatası fırlatıyordu (testte yakalandı — widget
      testleri her testin sonunda ağacı söktüğü için `none` tipiyle kurulan HER test bunu tetikledi).
      Çözüm: `_controller`'ı `initState()`'te KOŞULSUZ, erkenden oluşturmak.
  - **`disableAnimations`'a saygı** — `WheelTriggerButton`/`ZFloatingButton` ile AYNI desen: OS'in
    "hareketi azalt" tercihi açıkken `_controller.repeat()` HİÇ çağrılmıyor, aksi halde
    `pumpAndSettle()` sürekli tekrar eden bir animasyonda sonsuza dek beklerdi.
  - **Mağaza kartı önizlemesi de canlı görünümle AYNI painter'ı kullanıyor** (`ThemeOptionCard.
    _previewOverlay`) — yalnızca daha az parçacıkla (`particleCount` yarı yarıya düşürülmüş),
    performans önemli olmadığı için (statik) değil, küçük kart kutusunda görsel olarak taşmasın diye.
  - **Test:** `animated_theme_overlay_test.dart` — `none` iken katman yok, her 7 tür için
    `disableAnimations` açıkken `pumpAndSettle()`'ın DONMADIĞINI (bu, kapatma mantığının doğru
    çalıştığının dolaylı ama kesin kanıtı), katmanın `IgnorePointer` sayesinde alttaki butona
    dokunmayı ENGELLEMEDİĞİNİ doğruluyor. `widget_test.dart`'a Kış Teması'nı satın alıp uygulayan,
    Ana Sayfa VE Hedef Takibi'nde `themeParticleEffect` key'inin göründüğünü doğrulayan bir uçtan
    uca senaryo eklendi (mekanizma `animationType`'tan bağımsız jenerik olduğu için TEK bir tema
    örneği tüm türler için yeterli kanıt — her tema için ayrı bir e2e testi GEREKMEDİ).
  - **İlk üçlü — Kış Teması (kar, aşağı düşen+sallanan daireler) / Galaksi (twinkle eden yıldızlar,
    opaklık salınımı) / Parti Konfeti (düşen+dönen renkli dikdörtgenler).**
  - **2026 güncellemesi — Galaksi'ye kayan yıldız eklendi.** Kullanıcı isteği: "galaksi premium
    temasında kayan yıldız animasyonu koyar mısın." Sürekli twinkle eden yıldızlardan FARKLI bir
    ikinci parçacık katmanı: `_ShootingStar` (YENİ, `theme_particle_effect.dart` içinde) — sabit
    (`Random(77)`) 3 adet, her biri KENDİ periyoduyla (döngünün ~%22-42'si) tekrarlanan, o
    periyodun yalnızca küçük bir diliminde (~%6-10'u, ~1.5-3 saniye) aşağı-sağa çapraz (20°-55°)
    "kayan" bir çizgi + parlak bir baş noktası. `cycleFraction = (t + phase) % period`,
    `activeWindow = period * activeFraction` dışına çıkınca hiç ÇİZİLMİYOR (sürekli görünen twinkle
    yıldızlarının aksine, gerçek bir kayan yıldız gözlemi gibi ARA SIRA beliriyor) — her yıldızın
    kendi `phase`'i farklı olduğu için üçü asla aynı anda kaymıyor.
    - **Çizim:** `dart:ui`'nin `Gradient.linear` shader'ı ile kuyruktan (şeffaf) başa (parlak) doğru
      solan bir çizgi (`canvas.drawLine`) + başında küçük dolu bir daire; hem başlangıçta hem
      bitişte ani bir "flaş" olmasın diye `sin(travel * pi)` ile YUMUŞAK belirip-kaybolma (fade
      in/out) uygulanıyor.
    - **Yalnızca `_GalaxyPainter`'a eklendi** (diğer 6 tema türünü etkilemedi) — kayan yıldız sayısı
      bilerek twinkle yıldız sayısından (`count`, `ThemeParticleEffect`'ten geliyor) BAĞIMSIZ,
      sabit ve küçük (3) tutuldu; bu bir "ana efekt" değil, ara sıra beliren tamamlayıcı bir detay.
      Mağaza kartı önizlemesinde de (statik `AlwaysStoppedAnimation`, bkz. yukarıdaki painter
      paylaşım mimarisi) AYNI kod kullanılıyor — önizleme sabit bir `t` değerinde durduğu için
      kayan yıldızlar önizlemede ya görünür ya görünmez (o anki `t`'ye bağlı), ekstra bir kod dalı
      GEREKMEDİ.
    - **Gerçek cihazda doğrulama:** Galaksi teması uygulanıp Ana Sayfa'da art arda alınan ekran
      görüntülerinde kayan yıldızın (soluk diyagonal bir çizgi + parlak baş) belirip birkaç saniye
      sonra kaybolduğu, twinkle yıldızlarının bundan etkilenmediği doğrulandı.
  - **2026 GÜNCELLEMESİ — dörtlü paket: Kalpli Tema/Nota Teması/Tropikal Tema/Çiçekli Tema.**
    Kullanıcı isteğiyle eklendi, hepsi 650-900 ZC aralığında (Kalpli 650, Çiçekli 700, Nota 750,
    Tropikal 800):
    - **Kalpli Tema** (`hearts_love`, `ThemeAnimationType.hearts`) — kar tanelerinin TERSİ yönde,
      YUKARI süzülüyor (`startY - t*speed`, negatif sarma `% 1.0` ile 0..1'e düzeltiliyor).
      **2026 güncellemesi — kalp şekli düzeltildi:** ilk sürümdeki elle-ayarlanmış 4 kübik
      Bezier'lik `_heartPath()` gerçek bir kalbe benzemiyordu (kullanıcı bildirdi: "düzgün
      görünmüyor"). Yerine, klasik parametrik kalp eğrisi (`x = 16·sin³t`, `y = 13·cos t − 5·cos 2t
      − 2·cos 3t − cos 4t`) 48 noktayla örneklenip [-1, 1]'e normalize edilen, modül yüklenirken
      BİR KEZ hesaplanan sabit bir `_unitHeartPath` ile değiştirildi — `_HeartsPainter` her
      parçacık için bu birim path'i `canvas.scale(size/2)` ile ölçekleyip çiziyor (28 parçacık ×
      her karede path yeniden inşa etmek yerine, performans). Sonuç: gerçek, tanınabilir bir ♥
      (iki yuvarlak üst lob + sivri alt uç).
    - **Nota Teması** (`music_notes`, `ThemeAnimationType.notes`) — sekizlik nota siluetleri (oval
      "kafa" + düz "sap" + küçük eğri "bayrak", `canvas.rotate(-0.35)` ile tipik eğik duruş),
      Kalpli Tema ile AYNI yukarı-süzülme hareketi paylaşılıyor (`_FloatingShape` ortak veri sınıfı).
    - **Tropikal Tema** (`tropical_paradise`, `ThemeAnimationType.tropical`) — konfetiyle AYNI
      düşme+dönme hareketi ama yaprak formunda (`drawOval` + ortadan geçen ince bir "damar" çizgisi),
      turuncu-yeşil sıcak gradyan (açık mod) / koyu orman gecesi (koyu mod).
    - **Çiçekli Tema** (`cherry_blossom`, `ThemeAnimationType.petals`) — konfetiyle AYNI düşme+dönme
      hareketi. **2026 güncellemesi — tek bir oval/dikdörtgen ("petal") yerine gerçek bir ÇİÇEK:**
      kullanıcı bildirdi eski `RRect` tabanlı tek-petal tasarımın çiçeğe benzemediğini ("düzgün bir
      çiçek şekli — birkaç yapraklı, simetrik" istendi). `_drawFlower()` (YENİ, saf bir çizim
      yardımcısı — Path DEĞİL, doğrudan `canvas` çağrıları) merkez etrafında eşit açıyla (360°/5)
      döndürülmüş BEŞ oval yaprak + ortada küçük, farklı renkte (sarımsı-altın "polen") bir daire
      çiziyor — pembe/beyaz kiraz çiçeği paleti korunuyor, yalnızca siluet değişti.
    - **Ortak tasarım kararı — dörtlü de `_FloatingShape` (yukarı süzülenler) / konfeti deseni
      (aşağı düşenler) ARASINDA paylaşılan aynı iki hareket formülünü kullanıyor** — her tema için
      SIFIRDAN bir hareket matematiği icat etmek yerine, mevcut iki desenden (kar'ın aşağı-düşme +
      sallanma, konfetinin düşme + dönme) birini seçip yalnızca ÇİZİM şeklini (Path/oval/RRect)
      değiştirmek yeterli oldu — parçacık sayıları (22-32 arası) telefon donanımını zorlamayacak
      şekilde düşük tutuldu, `StarryGradientBackground`'daki 28 sabit yıldızla aynı büyüklük mertebesi.
- **Mimari, `CostumeProvider`/`CostumeCard` çiftinin BİREBİR aynısı** — `AppThemeProvider` da
  yalnızca "hangi temalar sahiplenildi (`ownedIds`) / hangisi aktif (`equippedId`)" durumunu tutar
  (coin harcamasından bağımsız), `SharedPreferences` ile kalıcı, satın alma akışı (`CoinProvider.
  spendOnTheme` + bakiye kontrolü) `ThemeOptionCard`'ın sorumluluğunda. Aynı üç görsel/etkileşim
  durumu (kilitli/sahip olunan/aktif).
- **`AppThemeOption`, açık VE koyu mod için AYRI renk listesi taşır** (`lightColors`/`darkColors`,
  `colorsFor(isDark)` ile seçilir) — kullanıcının istediği "hangi tema seçili olursa olsun, o anki
  açık/koyu moda göre otomatik doğru varyant" gereksinimi, ekranın `ThemeProvider.isDarkMode`'u
  `watch` etmesiyle karşılanıyor: kullanıcı Ayarlar'dan modu değiştirdiğinde `build()` zaten yeniden
  çalışıp doğru gradyanı çiziyor, ayrı bir "temayı yeniden uygula" adımına gerek yok.
- **Uygulama yeri — İKİ katmanlı:** İlk sürümde tema yalnızca Ana Sayfa'nın arka planına
  uygulanıyordu; kullanıcı geri bildirimiyle ("butonlar konuşma balonları bottom bar rengi ek
  modüller ve tüm sayfalar aynı şekilde değişsin sadece ana sayfa değil") TÜM uygulamaya
  genişletildi:
  1. **Ana Sayfa'nın "hero" gradyan arka planı** (değişmedi) — `HomeScreen.build()`'in sonunda,
     `Center(child: SingleChildScrollView(...))` içeriği `content` yerel değişkenine atanıp, aktif
     bir tema varsa bunun üzerine `DecoratedBox(gradient: ...)` ile sarılıyor
     (`key: Key('homeThemeGradientBackground')` — testte varlığını/yokluğunu doğrulamak için).
     Aktif tema yoksa `content` DOĞRUDAN dönüyor.
  2. **`AppThemeOption.colorScheme(bool isDark)`** — uygulamanın GERÇEK `ColorScheme`'ini (butonlar,
     alt gezinme çubuğu, konuşma balonları, kartlar, ek modüller menüsü, TÜM sayfaların
     `scaffoldBackgroundColor`'ı) üreten yeni bir metot. `main.dart`'taki `DijitalKankaApp.build()`
     artık `Consumer3<ThemeProvider, LocaleProvider, AppThemeProvider>` — bir tema aktifse
     `MaterialApp.theme`/`darkTheme`, `_buildTheme(_lightColorScheme)`/`_buildTheme
     (_darkColorScheme)` sabitleri yerine `_buildTheme(equippedTheme.colorScheme(isDark))`
     kullanır (`_buildTheme` zaten önceden bir `ColorScheme` parametresi alan, tekrar kullanılabilir
     bir fonksiyondu — hiç değişmedi). Bu tek değişiklik yeterli oldu, çünkü SpeechBubble/
     MainBottomBar/ModulesMenuSheet/tüm ekranların kartları/butonları zaten `Theme.of(context).
     colorScheme` üzerinden renk alıyordu (proje genelinde tutarlı bir kural) — ayrı ayrı her
     widget'a dokunmaya gerek kalmadı.
  - **`lightPrimary`/`lightPrimaryContainer`/`darkPrimary`/`darkPrimaryContainer` BİLEREK
    `lightColors`/`darkColors`'tan (gradyan durakları) AYRI tutuluyor:** gradyanın en koyu/canlı
    durakları (özellikle "Okyanus"un koyu lacivert/petrol tonları gibi) buton/metin kontrastı için
    uygun değil — bunlar aynı renk ailesinin elle seçilmiş, okunabilir bir türevi.
    `ColorScheme.fromSeed(seedColor: primary, brightness: ...)` tohumun yalnızca tonunu/doygunluğunu
    alıp açık/koyu moda uygun parlaklık tonlarını KENDİSİ hesapladığı için (girdinin kendi
    parlaklığından bağımsız — Material 3'ün HCT tonal palet algoritması), karanlık modda bile
    okunabilir bir `primary`/`surface` seti garanti ediyor; yalnızca `primary`/`primaryContainer`
    (ve ikisinin `on*` karşılıkları, `computeLuminance()` ile beyaz/siyah metin seçilerek) elle
    `copyWith` ile sabitleniyor, geri kalan roller (`surface`, `surfaceContainer`, `outline` vb.)
    tohumdan tutarlı biçimde türüyor — `main.dart`'ın kendi varsayılan temasının
    `_lightColorScheme`/`_darkColorScheme`'i kurma deseniyle AYNI.
  - **`ThemeFadeOverlay`'e `equippedThemeId` parametresi eklendi** — önceden yalnızca
    `themeMode` (açık/koyu) değişince "perde" geçişi tetikleniyordu; artık aktif tema
    değiştiğinde/kaldırıldığında da aynı yumuşak geçiş çalışıyor, aksi halde renkler anında
    "flaşlardı".
- **"Gece Gökyüzü" teması koyu modda yıldızlı** (`AppThemeOption.isStarryInDark`) —
  `StarryGradientBackground` adında yeni, küçük bir `CustomPaint` sarmalayıcı; 28 sabit yıldızı
  `Random(42)` ile BİR KEZ (class-static alan başlatmasında) üretip her rebuild'de AYNI deseni
  çiziyor (yeniden hesaplama maliyeti + görsel "zıplama" olmasın diye).
  - **Gotcha — `CustomPaint(painter:)` vs `foregroundPainter:`:** `painter:` çocuğun ARKASINA
    çizer — ilk yazımda yıldızlar gradyan dolgulu `DecoratedBox`'ın (çocuk) ALTINDA kalıp hiç
    görünmüyordu. `foregroundPainter:` çocuğun ÖNÜNE çizer, doğru seçim buydu. **Bir dekoratif
    katmanı (yıldız, parçacık, doku vb.) rengi olan bir arka planın ÜSTÜNE çizerken her zaman
    `foregroundPainter` kullanın, `painter` DEĞİL.**
- **Gotcha (aynı `childAspectRatio` overflow dersi, ÜÇÜNCÜ kez tekrarlandı):** `ThemeOptionCard`
  Kostüm/Manifest kartlarıyla neredeyse aynı içerik yapısını (gradyan önizleme + isim + fiyat/rozet
  satırı + buton) taşıdığı için `_ThemesSection`'ın ilk `childAspectRatio` değeri (0.78, Kostümler
  segmentinden kopyalanırken önizlemenin 1.6 en-boy oranı farklı olduğu için elle yeniden tahmin
  edilmişti) kilitli kartlarda `flutter test`'te yakalanan bir `RenderFlex overflow`'a (21px) yol
  açtı — yeni eklenen uçtan uca `widget_test.dart` senaryosu tarafından bulundu. `0.62`'ye
  düşürülünce düzeldi. **Bu, oturumdaki AYNI kategorideki üçüncü overflow bug'ı (Manifest geçmiş
  kartı, Kostüm kartı, şimdi Tema kartı) — yeni bir kart tasarımı `GridView.count(childAspectRatio:
  ...)` içine konurken DEĞERİ TAHMİN ETMEK yerine önce bir widget testiyle en UZUN içerik durumunu
  (genelde: kilitli/unowned, buton dahil) doğrulamak daha güvenilir.**
- **Test:** `app_theme_provider_test.dart` (`CostumeProvider`'daki testlerin birebir aynısı, `sunset`/
  `ocean` id'leriyle) + `widget_test.dart`'a bir uçtan uca senaryo (Mağaza > Temalar'dan "Gün Batımı"
  satın al → aktif et → Ana Sayfa'da `homeThemeGradientBackground` key'i BULUNUR → temayı kaldır →
  key BULUNMAZ). **Gotcha:** `_buildAppWithClock()` yardımcı fonksiyonuna (bkz. "Test kalıpları"
  bölümü) `AppThemeProvider` eklenmeyi UNUTULMUŞTU — bu, o yardımcıyı kullanan `widget_test.dart`
  testlerinden BİRİNİ değil, ondan SONRA çalışan HER testi (`ProviderNotFoundException` → test dosyası
  genelinde kademeli 20 test başarısızlığı) etkiledi, çünkü hepsi aynı test ikili dosyasında art arda
  koşuyor. **Yeni bir provider `main.dart`'a eklendiğinde `_buildAppWithClock()`'a da eklenmeyi
  unutmayın** — aksi halde hata yalnızca o yardımcıyı kullanan testlerde değil, ondan sonra gelen
  TÜM testlerde görünür, kökeni bulmayı zorlaştırır.
  - **App-wide `ColorScheme` uygulaması (yukarıdaki "İKİ katmanlı" madde) hiçbir otomatik testle
    KAPSANMIYOR** — mevcut widget testi yalnızca `homeThemeGradientBackground` key'inin varlığını
    doğruluyor, buton/bottom bar/kart renklerinin gerçekten değiştiğini DEĞİL (Flutter widget
    testlerinde `ColorScheme` değerlerini `Theme.of(context)` üzerinden okuyup karşılaştırmak
    yazılabilir ama bu oturumda yazılmadı). Bunun yerine gerçek cihazda `adb shell input tap` +
    `adb shell screencap` ile Ana Sayfa/Hedefler/Birikim/Mağaza sekmelerinde VE hem açık hem koyu
    modda (Gece Gökyüzü'nün yıldızlı koyu varyantı dahil) görsel olarak doğrulandı — bottom bar
    aktif sekme rengi, kart kenarlıkları/butonlar, "Ekle"/"Satın Al" gibi outline butonlar hepsi
    aktif temanın `primary` rengine döndü. **Gotcha (bu doğrulama sırasında bulundu):** Bash
    tool'da Git Bash'in yol dönüştürmesi (`/sdcard/...` gibi Unix-stili mutlak yolları Windows
    yoluna çeviriyor) `adb shell screencap -p /sdcard/foo.png` gibi komutları "usage" hatasıyla
    sessizce bozuyordu — çözüm `MSYS_NO_PATHCONV=1` ortam değişkeniyle çalıştırmak
    (`MSYS_NO_PATHCONV=1 adb shell screencap -p /sdcard/foo.png`). Web preview'daki (Claude
    Browser) tıklamalar CanvasKit'te güvenilir şekilde timeout yediği için (bkz. önceki
    "Su Takibi" gotcha'sı) bu doğrulama TAMAMEN gerçek cihaz üzerinden yapıldı.
- **2026 güncellemesi — kullanıcı raporu incelendi, KOD BUG'I BULUNAMADI:** Kullanıcı "tema seçince
  sadece Ana Sayfa değişiyor, diğer tüm sayfalar değişmeli" diye bildirdi. `main.dart`/
  `ThemeProvider`/`AppThemeProvider` kodu incelendiğinde yukarıdaki "İKİ katmanlı" mimarinin
  (özellikle 2. katman — `MaterialApp.theme`/`darkTheme`'in `AppThemeProvider.equippedTheme?.
  colorScheme(isDark)`'e bağlı olması) ZATEN doğru şekilde uygulanmış olduğu görüldü —
  `Theme.of(context).colorScheme` proje genelinde tutarlı kullanıldığı için bu tek değişiklik
  zaten TÜM sayfalara (Hedef Takibi/Su Takibi/Mağaza/Profil/Ayarlar dahil) yayılıyordu. **Gerçek
  eksik olan otomatik TEST kapsamıydı** — mevcut widget testi yalnızca Ana Sayfa'nın gradyan arka
  planını doğruluyordu, başka hiçbir ekranın `ColorScheme.primary`'sinin gerçekten değiştiğini
  DEĞİL (bkz. yukarıdaki "hiçbir otomatik testle KAPSANMIYOR" notu — bu artık kısmen geçersiz).
  Bu yüzden `widget_test.dart`'taki tema testine Profil sekmesinin VE Z-menüden açılan Su Takibi
  ekranının `Theme.of(tester.element(...)).colorScheme.primary`'sini doğrudan okuyup satın alınan
  temanın rengiyle (`sunsetLightPrimary = Color(0xFFD9531D)`) karşılaştıran yeni bir assertion
  eklendi — böylece bu davranış artık somut bir regresyon testiyle garanti altında, yalnızca elle/
  görsel doğrulamaya bağlı değil. Kullanıcının gördüğü sorun büyük olasılıkla ESKİ bir APK
  sürümüydü — güncel kaynak koda göre hiçbir düzeltme GEREKMEDİ.
- **2026 güncellemesi — Standart/Premium ayrımı kaldırıldı, TEK fiyata-göre-sıralı liste.**
  Kullanıcı isteği: Mağaza/Temalar'da tüm temaları (statik + premium/animasyonlu, kategori
  ayrımı OLMADAN) tek bir listede ucuzdan pahalıya sırala. `store_screen.dart`'taki
  `_ThemesSection`, iki ayrı başlıklı `_ThemesGrid` (Standart Temalar + Premium/Animasyonlu)
  render eden ~40 satırlık kod yerine `[...appThemes]..sort((a, b) => a.price.compareTo(b.price))`
  ile TEK bir sıralı liste üretip TEK bir `_ThemesGrid`'e veriyor — `storeThemesStandardSectionTitle`/
  `storeThemesPremiumSectionTitle`/`storeThemesPremiumSectionSubtitle` ARB anahtarları artık
  KULLANILMIYOR (silinmedi, bkz. proje geneli "kullanılmayan ARB anahtarını silme" convansiyonu).
  **Hangi temaların premium/animasyonlu olduğu bilgisi KAYBOLMADI** — `ThemeOptionCard`'ın kendi
  üstündeki "Premium" rozeti (bkz. `theme.isPremiumAnimated`) KART SEVİYESİNDE göstermeye devam
  ediyor, yalnızca üst düzey grup başlığı/ayrımı kalktı. `widget_test.dart`'taki "Kış Teması"
  testindeki `find.text('Standart Temalar')`/`find.text('Premium / Animasyonlu')`
  assertion'ları kaldırıldı (artık bu başlıklar hiç render edilmiyor).

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

### Rüya Günlüğü ([dream_journal_screen.dart](lib/screens/dream_journal_screen.dart), [dream_entry_form_screen.dart](lib/screens/dream_entry_form_screen.dart), [dream_journal_provider.dart](lib/providers/dream_journal_provider.dart), [dream_entry.dart](lib/models/dream_entry.dart), [dream_quotes.dart](lib/data/dream_quotes.dart))
- **Yerleşim: sekme DEĞİL, alt çubuktaki Z butonunun açtığı modül menüsünden erişiliyor**
  (bkz. "Alt Gezinme Çubuğu" bölümü). **Tarihçe:** ilk sürümde `RootScreen`'in AppBar'ından push
  edilen ayrı bir sayfaydı (ay ikonu, `Icons.nights_stay_outlined`) — gerekçesi uygulamada zaten 4
  sekme olması ve Türkçe etiketlerin (özellikle "Para ve Birikim") alt gezinme çubuğunu zaten
  doldurmuş olmasıydı. Şükran Günlüğü ve Günlük Ruh Hali Takibi eklendiğinde AppBar'a/Ayarlar'a daha
  fazla dağınık giriş noktası eklemek yerine kullanıcı isteğiyle bu üç modül tek bir Z-butonu
  menüsünde toplandı; AppBar'daki ay ikonu kaldırıldı. Ekranın kendisi (tek sayfa, hem form hem
  liste) değişmedi — yalnızca giriş noktası taşındı.
- **`DreamJournalProvider`**: `GoalsProvider`/`MoneyProvider` ile birebir aynı `SharedPreferences`
  JSON-encode kalıcılık deseni (`_loadFromPrefs`/`_save`, `dreamEntries` anahtarı, artan `_nextId`).
  `addDream`/`updateDream`/`removeDream` hepsi `notifyListeners()` + `_save()` çağırır; boş
  başlık/metin `trim()` sonrası sessizce reddedilir (`MoneyProvider.addEntry`'nin boş ad/tutar
  reddiyle aynı mantık).
- **`dreams` getter'ı en yeni kayıt en üstte olacak şekilde sıralar** — yalnızca `date`'e göre değil,
  ikincil anahtar olarak `id`'ye (artan sırada atanır) göre de sıralar. Sebep: `DateTime.now()` art
  arda hızlı çağrılarda (ör. testte üç `addDream` aynı milisaniyede) aynı değeri dönebiliyor;
  `date`'e göre sıralamak tek başına belirsiz/kararsız sonuç veriyordu (Dart'ın `List.sort`'u kararlı
  değil). `id` tiebreaker'ı bunu kesin/deterministik hâle getiriyor.
- **Tek form ekranı hem ekleme hem düzenleme için kullanılıyor** (`DreamEntryFormScreen(existing:
  ...)`) — `existing == null` ise "ekle" modu (AppBar'da silme ikonu yok), verilirse alanlar önceden
  doldurulur ve AppBar'a bir silme ikonu eklenir. Bu, "kaydı görüntüle/düzenle/sil" gereksinimini TEK
  bir ekranla karşılıyor — ayrı bir salt-okunur "detay" ekranı YOK (metnin tamamı zaten düzenlenebilir
  alanda görünür durumda, bu da fazladan bir ekran/route eklemeden aynı işi görüyor). Kaydet butonu
  başlık VE metin alanlarının ikisi de doluyken aktifleşir (`TextEditingController` listener'larıyla
  canlı takip edilen `_canSave`).
- **Silme**, form ekranındaki çöp kutusu ikonundan `AlertDialog` onayıyla yapılır; onaylanınca
  `removeDream` + `Navigator.pop()` (listeye döner) — `MoneyCategoryCard`'ın anlık/onaysız silme
  butonundan farklı olarak burada onay isteniyor çünkü bir rüya kaydı çok daha fazla içerik/emek
  taşıyor (tek satırlık bir harcama kaydından farklı).
- **Tarih otomatik atanır** (`DreamEntry.date = DateTime.now()`, `addDream` içinde) ve düzenlemede
  DEĞİŞMEZ (`updateDream` orijinal `date`'i korur). Görüntüleme için `dream_journal_screen.dart`
  içinde küçük, bağımsız bir `_formatDate`/`_turkishMonths` yardımcı yazıldı — `intl`'in
  `DateFormat`'ı yerine bilinçli olarak tercih edildi çünkü proje genelinde tarih GÖSTERİMİ için
  hiç `intl` kullanılmıyordu (`goal_card.dart` bile gün NUMARASI gösteriyor, takvim tarihi değil) ve
  yeni bir örüntü eklemek yerine mevcut "küçük, sabit Türkçe veri listeleri" kalıbına (`zibo_messages.
  dart` vb.) uyulması tercih edildi.
- **İçerik:** `dream_quotes.dart`, Ana Sayfa/Para ve Birikim'deki söz havuzlarıyla AYNI desen
  (yalnızca Türkçe, ARB'ye taşınmadı — bkz. "Yerelleştirme" bölümü) — konuşma balonu her 5 saniyede
  bir `Timer.periodic` ile döner. Bu ekran `MoneyScreen`/`GoalTrackingScreen`'in aksine bir
  `IndexedStack` içinde saklı kalmıyor (push edilen ayrı bir rota, her zaman ya tam görünür ya da
  hiç monte değil) — bu yüzden zamanlayıcı basitçe `initState`/`dispose`'a bağlı, `MoneyScreen`'deki
  `isActive` parametresine/`didUpdateWidget` mantığına gerek yok.
- **Costume entegrasyonu bilerek YOK:** Ana Sayfa/Para ve Birikim'in aksine bu ekrandaki Zibo görseli
  giyili kostümü yansıtmıyor, sabit `zibo_yeni.png`. Kullanıcı isteği yalnızca "küçük bir Zibo görseli"
  belirtiyordu; kapsam gereksiz büyütülmedi.
- **Test:** `dream_journal_provider_test.dart` (ekleme/güncelleme/silme/sıralama/kalıcılık,
  `MoneyProvider`/`GoalsProvider` testleriyle aynı desen) + `widget_test.dart`'a tek bir uçtan uca
  senaryo (Z-butonu modül menüsünden aç → ekle → listede gör → dokun, alanlar dolu gelsin → düzenle →
  sil → boş duruma dön). `find.text(...)`'in hem `Text` hem `EditableText` (yani `TextField` içeriği)
  widget'larını eşleştirdiğine güveniliyor — bu, form alanlarının önceden doldurulmuş değerlerini
  ayrı bir controller okuması yazmadan doğrudan `find.text('Ucmak')` gibi doğrulayabilmeyi sağlıyor.
- Gerçek cihazda tam CRUD akışı (ekle → uygulamayı tamamen kapat/yeniden aç → kalıcılığı doğrula →
  düzenle → sil) `adb` ile uçtan uca doğrulandı; koyu temada da doğru render olduğu teyit edildi.
- **2026 yeni özellik — Rüya Günlüğü ↔ Ruh Hali Takibi hafif korelasyonu (AI YOK, yalnızca tarih
  eşleştirme + anahtar kelime taraması).** Kullanıcı isteği: "Rüya Günlüğü'nün mevcut konumu ve
  yapısı aynen kalsın... sadece rüya günlüğü girdilerini Ruh Hali Takibi ile hafifçe
  ilişkilendir... AI kullanmadan, sadece tarih karşılaştırmasına dayalı basit bir mantık." Ekranın
  formu/navigasyonu/yerleşimi HİÇ değişmedi — yalnızca liste öğesinin `ListTile.subtitle`'ına
  KOŞULLU bir ikinci satır eklendi.
  - **`DreamEntry`'de sentiment alanı YOK, BİLEREK eklenmedi** (kullanıcının "yapı aynen kalsın"
    isteği) — bunun yerine YENİ [dream_sentiment.dart](lib/utils/dream_sentiment.dart)'taki
    `isNegativeDream(DreamEntry)` saf fonksiyonu, `title`+`text`'i (kullanıcı zaten yazmış olduğu
    serbest metin) bilinen "kötü rüya" anahtar kelimeleriyle (kabus, korku, kaçtım, düştüm, öldüm,
    boğul, kaybol, karanlık, canavar, saldırı, ağla, panik, terk) tarıyor. **Kullanıcının rüyayı
    HANGİ dilde yazdığı bilinmediği için** (arayüz dilinden bağımsız) TR+EN+ES anahtar kelimeleri
    BİRLİKTE taranıyor — diğer üç-dilli içerik havuzlarından (`zibo_messages.dart` vb., "kullanıcının
    seçtiği dile göre TEK liste") FARKLI bir desen. Bu KESİN bir sentiment analizi DEĞİL (bilinçli
    basitleştirme, kullanıcının açık "basit bir mantık" isteğiyle tutarlı) — yanlış pozitif/
    negatifler olabilir, `dreamMoodCorrelationNote` yalnızca HAFİF bir gözlem sunuyor, kesin bir
    teşhis İDDİA ETMİYOR.
  - **`Mood`'a yeni bir `MoodLowness` extension'ı** (`lib/models/mood.dart`) — `bool get isLow =>
    index <= 1;` (enum kötüden iyiye sıralı olduğu için ilk iki değer: `veryUnhappy`/`unhappy`).
  - **`MoodProvider.entryForDate(DateTime)` ZATEN tam olarak istenen "bu tarihte kayıt var mı"
    sorgusunu yapıyordu** — yeni bir metot GEREKMEDİ, `dream_journal_screen.dart` yalnızca
    `context.watch<MoodProvider>()` eklendi.
  - **`_buildDreamSubtitle`** (dosyanın sonunda, private top-level fonksiyon) — normalde yalnızca
    tarih (`formatLongDate`, değişmedi); AYNI tarihte `isNegativeDream(dream) &&
    moodProvider.entryForDate(dream.date)?.mood.isLow == true` ise `Column`'a dönüp ikinci bir satır
    (`dreamMoodCorrelationNote`, ör. "O gün ruh halin de düşüktü 😔") ekliyor. Liste yapısı, form,
    navigasyon — HİÇBİRİ değişmedi, yalnızca bu TEK koşullu satır.
  - **Test:** YENİ `test/dream_sentiment_test.dart` (`isNegativeDream`'in TR/EN/ES anahtar kelime
    tespiti, büyük/küçük harf duyarsızlığı, nötr/olumlu rüyalarda `false` dönmesi) +
    `widget_test.dart`'a bir uçtan uca senaryo (olumsuz bir rüya eklenir → henüz ruh hali kaydı
    yokken not GÖRÜNMEZ → Günlük Ruh Hali Takibi'nden düşük bir emoji seçilir → Rüya Günlüğü'ne
    dönülünce not GÖRÜNÜR). **Toplam: 317 test.**

### Şükran Günlüğü ([gratitude_journal_screen.dart](lib/screens/gratitude_journal_screen.dart), [gratitude_provider.dart](lib/providers/gratitude_provider.dart), [gratitude_entry.dart](lib/models/gratitude_entry.dart), [gratitude_quotes.dart](lib/data/gratitude_quotes.dart))
- **Yerleşim: alt çubuktaki Z butonunun açtığı modül menüsünden erişiliyor** (bkz. "Alt Gezinme
  Çubuğu"). **Tarihçe:** kullanıcı ilk eklendiğinde açıkça "şimdilik Ayarlar sekmesi içine ekle"
  demişti, bu yüzden bir süre `SettingsScreen`'de kendi başına bir `ListTile` kartı
  (`_GratitudeJournalSettingsCard`, alt metni `context.watch<GratitudeProvider>().isTodayComplete`
  ile bugünün durumunu CANLI gösteriyordu — "Bugün tamamlandı ✓" / "Bugün henüz yazılmadı") olarak
  yaşadı. Alt Gezinme Çubuğu yeniden tasarlanınca bu geçici yerleşim kaldırıldı, modül Z-butonu
  menüsüne taşındı — Ayarlar artık yalnızca uygulama ayarlarını içeriyor, canlı durum alt metni de
  bu taşımayla birlikte kaldırıldı (menü kartı sabit bir açıklama metni gösteriyor, bkz. Alt
  Gezinme Çubuğu bölümü). Tıklanınca `GratitudeJournalScreen`'e push eder — tek ekran hem bugünün
  formunu hem geçmiş listesini barındırır (Rüya Günlüğü'yle aynı desen).
- **Günlük kilitleme mantığı `Goal.dateOnly()`'daki tarih karşılaştırma yaklaşımıyla aynı** ama çok
  daha basit: `Goal`'daki 7 günlük döngü/seri/`reconcile` kavramlarının HİÇBİRİ yok, yalnızca
  "bugüne ait bir kayıt var mı?" sorusu (`GratitudeProvider.isTodayComplete`). Bir güne en fazla BİR
  kayıt düşebilir; `saveToday()` bugün zaten tamamlanmışsa veya üç metinden biri boşsa (`trim()`
  sonrası) hiçbir şey yapmadan `false` döner. Gün değişince (`_now()`'ın döndürdüğü tarih ilerleyince)
  `isTodayComplete` otomatik olarak `false`'a döner ve form kendiliğinden yeniden açılır — `Goal`'daki
  gibi ayrı bir "reconcile" adımına gerek YOK, çünkü kilitlenecek bir "seri" durumu yok.
  `GoalsProvider`'la aynı gerekçeyle enjekte edilebilir bir saat (`now:` constructor parametresi)
  taşıyor — testte "gün değişince yeni giriş açılır" davranışını gerçek zamanın geçmesini beklemeden
  doğrulayabilmek için (bkz. `gratitude_provider_test.dart`).
- **Coin entegrasyonu `GoalCard._onTodayTap`'teki desenle BİREBİR AYNI** — provider'lar birbirine
  bağımlı değil (`GratitudeProvider` `CoinProvider`'ı hiç bilmiyor), koordinasyonu çağıran WIDGET
  yapıyor: `GratitudeProvider.saveToday()` bir `bool` döner (kayıt gerçekten oluşturulduysa `true`),
  `GratitudeJournalScreen._save()` bunu görüp yalnızca `true` ise `context.read<CoinProvider>()
  .earnGratitudeJournal()`'ı çağırır + bir `SnackBar` gösterir. Miktar (`CoinEconomy.gratitudeJournal
  = 2`) diğer tüm kazanma tutarlarıyla aynı yerde (`coin_economy.dart`) tanımlı;
  `CoinProvider.earnGratitudeJournal()` da diğer adlandırılmış `earnX()` metotlarıyla (`earnDailyCheckIn`
  vb.) aynı desende, tek satırlık `_earn(...)` çağrısı.
- **"Yeşil tik" görseli kullanıcının açık isteğiyle uygulamanın hardal/altın paletinden BİLEREK
  SAPIYOR** — `_gratitudeGreen = Color(0xFF4CAF50)` sabit rengi yalnızca tamamlanma göstergesinde
  (bugünün "tamamlandı" kartındaki ve geçmiş listesindeki `Icons.check_circle`) kullanılıyor, başka
  hiçbir yerde; butonlar/kenarlıklar hâlâ standart tema renklerini kullanıyor.
- **Veri modeli kullanıcının istediği gibi:** `GratitudeEntry(date, text1, text2, text3, isComplete)`
  — `isComplete` şu anki akışta pratikte hep `true` (yarım kayıt kaydedilemiyor), ama kullanıcı
  açıkça bu alanı istediği ve ileride taslak/kısmi kaydetme eklenebileceği için ayrı bir alan olarak
  tutuldu (bkz. model dosyasındaki yorum).
- **2026 güncellemesi — bugünün 3 şükranı artık GÖRÜNÜR + hem bugün hem geçmiş DÜZENLENEBİLİR:**
  Kullanıcı geri bildirimi: "bugün tamamlandı yazısı çıkınca kullanıcı yazdığı 3 şükranı bir daha
  göremiyor, tamamlanan günün 3 şükranı geçmiş kayıtlara eklensin, kullanıcı geçmiş kayıtlara girip
  o günün şükranlarını tekrar düzenleyebilsin." Eski mimaride `_TodayDoneCard` yalnızca sabit bir
  kutlama başlığı/metni gösteriyordu (yazılan metinler HİÇBİR YERDE görünmüyordu — geçmiş listesi
  de bilerek bugünü FİLTRELEYİP dışlıyordu) ve `_showEntryDetail` salt-okunur bir `AlertDialog`'du.
  - **`GratitudeProvider.updateEntry(date, {text1, text2, text3})` eklendi** — `saveToday()`'nin
    aksine `isTodayComplete` KİLİDİNİ kontrol ETMEZ (zaten var olan bir kaydın İÇERİĞİNİ değiştirir,
    yeni bir günü "tamamlamaz"); `date`'e ait kayıt yoksa veya metinlerden biri boşsa `false` döner.
    Hem bugünün hem geçmişteki herhangi bir günün kaydını hedefleyebilir.
  - **`_TodayDoneCard`** artık kutlama başlığının ALTINDA üç şükranın kendisini de gösteriyor
    (`entry.text1/2/3`, alan etiketleriyle) + sağ üstte bir `Icons.edit_outlined` ikonu
    (`gratitudeEditTooltip`) — bu, `_showEntryDetail`'i bugünün kaydıyla açar.
  - **Geçmiş listesi artık BUGÜNÜ DE İÇERİYOR** — eski `pastEntries` filtresi (bugünü dışlayan
    `.where(...)`) tamamen kaldırıldı, `provider.entries` doğrudan kullanılıyor.
  - **`_showEntryDetail` salt-okunurdan DÜZENLENEBİLİRE çevrildi** — üç `Text` yerine üç `TextField`
    (mevcut değerlerle önceden doldurulmuş), "Kaydet" `GratitudeProvider.updateEntry()`'yi çağırıp
    başarılıysa diyaloğu kapatıyor.
  - **Gotcha — dialog içeriği ayrı bir `StatefulWidget`'a taşındı:** İlk yazımda diyaloğun üç
    `TextEditingController`'ı `_showEntryDetail` metodunun kendi yerel değişkeni olarak oluşturulup
    `showDialog(...).then((_) => controller.dispose())` ile temizleniyordu — ama bu, Future
    dialog KAPANMAYA BAŞLAR BAŞLAMAZ (çıkış animasyonu bitmeden) çözüldüğü için "A
    TextEditingController was used after being disposed" hatasına yol açtı (widget testinde
    yakalandı: `pumpAndSettle()` çıkış animasyonunun son karelerinde hâlâ eski controller'a
    yazmaya çalışıyordu). **Çözüm:** diyalog içeriği kendi `State`'i olan
    `_GratitudeEditDialogContent`'e taşındı — controller'lar `initState`'te oluşturulup
    `dispose()`'ta serbest bırakılıyor, bu da widget'ın Element'i GERÇEKTEN unmount olana kadar
    (çıkış animasyonu dahil) dispose edilmemelerini garanti ediyor. `water_tracking_screen.dart`'taki
    `_showGoalDialog`nun `literController`'ı da benzer bir riske sahip ama orada yalnızca TEK
    controller var ve dialog `StatefulBuilder` içinde (ayrı bir widget değil) — bu ayrım burada,
    daha karmaşık (3 controller'lı, editable) bir diyalog için gerekliydi.
- **Test:** `gratitude_provider_test.dart` (`GoalsProvider`'daki enjekte edilebilir saat deseniyle:
  kaydetme/kilitleme/eksik-alan-reddi/ikinci-kayıt-reddi/gün-değişince-yeni-giriş-açılması/kalıcılık
  + `updateEntry`: bugünü düzenler ve yeni kayıt EKLEMEZ, geçmişteki bir günü de düzenleyebilir,
  var olmayan tarih/boş metinle `false` döner) + `widget_test.dart`'a bir uçtan uca senaryo
  (Z-butonu modül menüsünden aç → Kaydet başlangıçta devre dışı → üç alan doldurulunca aktifleşir →
  kaydet → "tamamlandı" kartı + coin SnackBar'ı + yazılan üç şükran KARTTA GÖRÜNÜR → Düzenle
  ikonuna basıp bir şükranı değiştir → değişiklik hem kartta hem geçmişte yansır → Ana Sayfa'ya
  dönünce AppBar'daki bakiye +2 artmış). Gerçek cihazda tam akış (3 alanı doldur → kaydet → yeşil
  tik + kutlama kartı + SnackBar → bakiyenin 70'ten 72'ye çıktığı) `adb` ile doğrulandı (2026
  güncellemesinin görüntüle/düzenle akışı henüz cihazda AYRICA doğrulanmadı, yalnızca testlerle).

### Günlük Ruh Hali Takibi ([mood_tracking_screen.dart](lib/screens/mood_tracking_screen.dart), [mood_provider.dart](lib/providers/mood_provider.dart), [mood.dart](lib/models/mood.dart), [mood_quotes.dart](lib/data/mood_quotes.dart))
- **Yerleşim: alt çubuktaki Z butonunun açtığı modül menüsünden erişiliyor** (bkz. "Alt Gezinme
  Çubuğu"). Tarihçesi Şükran Günlüğü ile AYNI — bir süre Ayarlar sayfasında kendi `ListTile` kartı
  (`_MoodTrackingSettingsCard`, bugünün seçimini canlı gösteren bir alt metinle) olarak yaşadı, Alt
  Gezinme Çubuğu eklenince Z-butonu menüsüne taşındı.
- **`Mood`, Dart'ın enhanced enum özelliğiyle her değerin kendi emoji'sini VE rengini taşıyor**
  (`Mood.veryHappy.emoji`, `Mood.veryHappy.color`) — `notification_provider.dart`'taki
  Sabah/Öğlen/Akşam gibi ayrı bir eşleme listesi yerine, doğrudan enum üzerinde tek yerde tanımlı.
  Renkler (`0xFFE53935` kırmızıdan `0xFF43A047` yeşile) kullanıcının açık isteğiyle uygulamanın
  hardal/altın temasından BİLEREK BAĞIMSIZ — Şükran Günlüğü'ndeki tek `_gratitudeGreen` sabitinin
  aksine burada 5 farklı sabit renk var, çünkü "trafik ışığı" skalasının kendisi özelliğin amacı.
- **Kilitleme YOK, Şükran Günlüğü'nün TAM TERSİ mantık** — `MoodProvider.setTodayMood()` bugün için
  zaten bir kayıt varsa onu SİLİP YENİSİNİ ekler (üzerine yazar), her çağrı başarılı olur (`bool`
  dönmez) — kullanıcının açık isteği "aynı gün tekrar değiştirilebilsin" buydu. Gün değişince
  (`_now()` ilerleyince) otomatik yeni seçim açılır; `Goal`/`GratitudeEntry`'deki gibi tarih
  karşılaştırması saat bileşeni atılarak yapılıyor.
- **Seçim = kayıt, ayrı "Kaydet" butonu YOK** — her emoji `InkWell`, dokununca doğrudan
  `context.read<MoodProvider>().setTodayMood(mood)` çağırıyor. Görsel geri bildirim
  `AnimatedScale` (seçili emoji 1.25x büyür) + `AnimatedContainer` (rengin %25 opaklıkla dolgusu +
  tam renkte kenarlık + hafif gölge) ile veriliyor — `GoalCard`'daki `_DayBox`'ın "emphasized" durum
  vurgusuyla (kenarlık + `boxShadow`) aynı görsel dil, ama duruma göre değil `Mood.color`'a göre.
- **"Trend görme" isteği tek ekranda İKİ farklı görünümle karşılanıyor:** (1) "Son 7 Gün" şeridi —
  bugün dahil son 7 günün her biri için küçük bir daire (`_WeekDayDot`), o günün varsa rengi dolu,
  yoksa `colorScheme.outlineVariant` kenarlıklı boş; üstünde Türkçe gün kısaltması (Pzt/Sal/.../Paz).
  (2) Altındaki `Geçmiş` bölümünde TÜM kayıtların tam listesi (tarih + emoji + Türkçe etiket),
  Rüya/Şükran Günlüğü'ndeki liste deseniyle aynı. Ayrı bir "takvim ekranı" YAPILMADI — kullanıcının
  "olursa iyi olur" diye bıraktığı, zorunlu olmayan bir istekti, bu yüzden en basit çözüm seçildi.
- **Coin ödülü YOK** — kullanıcı istemedi, `MoodProvider` `CoinProvider`'ı hiç bilmiyor/çağırmıyor
  (Şükran Günlüğü'ndeki `GoalCard._onTodayTap` deseninin aksine burada iki provider'ı birbirine
  bağlayan bir widget mantığı da yok, tek yönlü `setTodayMood` çağrısı yeterli).
- **Test:** `mood_provider_test.dart` (`GratitudeProvider`'daki enjekte edilebilir saat deseniyle:
  kaydetme/üzerine-yazma/gün-değişince-yeni-seçim-açılması/`entryForDate`/sıralama/kalıcılık) +
  `widget_test.dart`'a bir uçtan uca senaryo (Z-butonu modül menüsünden aç → emoji'ye dokun →
  geçmiş listesinde görünür). Gerçek cihazda hem seçim+otomatik kayıt hem ÜZERİNE YAZMA (aynı gün
  farklı bir emoji'ye tekrar dokunma — listede İKİNCİ bir kayıt oluşmadığı, tek kaydın güncellendiği)
  `adb` ile açık temada doğrulandı (koyu tema, diğer tüm ekranlarla aynı ortak `_buildTheme`
  altyapısını kullandığı için ayrıca test edilmedi, ama aynı garantiye sahip).
- **2026 yeni özellik — bugünün ruh haline eşlik eden serbest not/günlük alanı** (bkz. "Motivasyon
  Sözü Sistemi" bölümündeki aynı turun diğer yarısı). `MoodEntry.note` (`String?`, opsiyonel) +
  `MoodProvider.setTodayMood(mood, {String? note})` — **`note` HİÇ VERİLMEZSE bugünün MEVCUT notu
  KORUNUR** (yalnızca emoji'ye dokunmak notu SİLMEZ), **AÇIKÇA verilirse** (boş string DAHİL)
  trim'lenip boşsa notu SİLER doluysa günceller — tek parametreyle hem "sadece emoji" hem "notu
  güncelle/temizle" akışları karşılanıyor. Eski (bu alan eklenmeden ÖNCE) kayıtlı veride `note`
  alanı hiç yok — `map['note'] as String?` bunu sessizce `null`'a düşürüyor, ayrı bir göç adımı
  GEREKMEDİ (zaten nullable).
  - **UI — emoji satırının ALTINDA, `todayMood == null` iken GİZLİ bir `TextField`.** Bir ruh hali
    seçilmeden önce "hangi güne ait olacağı" belirsiz olduğu için önce emoji seçilmeli.
    `ProfileProvider`'ın isim alanındaki "onSubmitted/odak kaybında kaydet" deseniyle AYNI —
    HER tuş vuruşunda DEĞİL, yalnızca gönderilince/odak kaybedilince `setTodayMood(mood, note:
    ...)` çağrılıyor (`FocusNode` + `!hasFocus` listener'ı).
  - **Geçmiş listesinde de gösteriliyor** — `entry.note != null` iken `ListTile.subtitle`
    ruh hali etiketinin ALTINA notu (3 satırla sınırlı, `TextOverflow.ellipsis`) ekliyor,
    `isThreeLine: true` ile.
  - **Test:** `mood_provider_test.dart`'a yeni bir grup (`note` verilmeden korunur, verilirse
    kaydedilir, boş/boşluk AÇIKÇA verilirse siler, trim edilir, kalıcı depoya yazılıp yeniden
    başlatmada hatırlanır) + `widget_test.dart`'a bir uçtan uca senaryo (emoji seç → not alanı
    BELİRİR → not yaz → gönder → geçmişte hem etiket hem not görünür). **Gotcha (test) —
    `find.text(not)` HEM hâlâ odaktaki `TextField`'ın `EditableText`'ini HEM geçmişteki yeni
    `Text`'i eşleştirdiği için `findsOneWidget` DEĞİL `findsWidgets` kullanılmalı** (Flutter'ın
    `find.text` finder'ı hem `Text` hem `EditableText` widget'larını aynı literal string için
    eşleştiriyor — bir alan hem yazılıp hem SONUÇ olarak başka bir yerde göründüğünde bu ikisi
    çakışıyor).

### Su Takibi ([water_tracking_screen.dart](lib/screens/water_tracking_screen.dart), [water_provider.dart](lib/providers/water_provider.dart), [water_entry.dart](lib/models/water_entry.dart), [water_quotes.dart](lib/data/water_quotes.dart))
- **Yerleşim: alt çubuktaki Z butonunun açtığı modül menüsünden erişiliyor**, dördüncü `_ModuleCard`
  olarak (bkz. "Alt Gezinme Çubuğu"). Rüya/Şükran/Ruh Hali'nin aksine bu modül **baştan beri** bu
  menüde tanıtıldı — hiçbir zaman Ayarlar'da yaşamadı, bu yüzden diğer üçündeki "önce Ayarlar'a
  eklendi, sonra taşındı" tarihçesi burada yok.
- **Günlük hedef `WaterProvider._goalGlasses` içinde, varsayılan 8 bardak (2000 ml, `250 ml/bardak`
  sabit)** — kullanıcı Su Takibi ekranının AppBar'ındaki `Icons.tune_rounded` ikonundan
  (`_showGoalDialog`, `showDialog` + `StatefulBuilder` stepper) 4-16 bardak arasında
  değiştirebiliyor (`WaterProvider.setGoalGlasses`, `clamp(4, 16)`). Hedef değişince o günün kaydı
  varsa `glassCount`i koruyarak yeniden yazılıyor (`_upsertToday`) — hedefi düşürmek zaten içilmiş
  suyu silmiyor, yalnızca ilerleme oranını/tamamlanma eşiğini değiştiriyor.
  - **Tarihçe:** Bu ayar başlangıçta Ayarlar sayfasında kendi kartıydı (`_WaterGoalSettingsCard`,
    diğer üç modülün eski "Ayarlar'da yaşama" döneminin aksine bu bilerek Su Takibi'ne ait tek bir
    ayar olduğu için oraya konmuştu). Kullanıcı isteğiyle Ayarlar'dan tamamen kaldırılıp aynı
    diyalog kodu `WaterTrackingScreen`'in kendi State sınıfına taşındı — modülün TEK ayarı artık
    modülün kendi ekranında, Ayarlar sayfası yalnızca uygulama geneli ayarları içeriyor.
- **`WaterProvider`, `GoalsProvider`/`GratitudeProvider` ile aynı `SharedPreferences` JSON-encode
  kalıcılık deseni** (`'waterState'` anahtarı altında `{goalGlasses, entries: [...]}`), aynı
  enjekte edilebilir saat parametresi (`now:`) testler için. `WaterEntry` günün tarihine
  (saat bileşeni yok) bağlı `glassCount`/`goalGlasses`/`rewardClaimed` tutan saf bir veri sınıfı —
  `goalGlasses` entry'nin İÇİNDE de saklanıyor ki geçmiş günlerin ilerleme yüzdesi, hedef sonradan
  değişse bile o günkü GERÇEK hedefe göre doğru hesaplanabilsin.
- **Kilitleme YOK, Ruh Hali Takibi'yle aynı "üzerine yazılabilir" mantık — ama iki yönlü sayaç:**
  `incrementGlass()` bir sonraki bardağı doldurur (hedefte durur, üstüne çıkmaz),
  `decrementGlass()` bir öncekini geri alır (0'ın altına inmez). Ekrandaki her bardak ikonu tek bir
  `onTap`; dolu bir bardağa dokunmak "geri al" (`decrementGlass`), boş bir bardağa dokunmak
  "doldur" (`incrementGlass`) anlamına geliyor — Rüya/Şükran Günlüğü'ndeki gibi ayrı bir "Kaydet"
  butonu YOK, her dokunuş anında kaydediliyor.
- **Coin ödülü, Şükran Günlüğü'ndeki `GratitudeProvider.saveToday()` deseniyle BİREBİR AYNI, ama
  GÜNDE YALNIZCA BİR KEZ garantili:** `WaterProvider` `CoinProvider`'ı hiç bilmiyor;
  `incrementGlass()` bir `bool` döner — yalnızca TAM O DOKUNUŞ hedefi tamamlattıysa VE bugünün
  ödülü henüz alınmamışsa `true`. Çağıran widget (`_WaterTrackingScreenState._tapGlass`) bunu görüp
  `context.read<CoinProvider>().earnWaterGoal()` çağırır (+2 ZC, `CoinEconomy.waterGoalCompleted`)
  ve bir `SnackBar` gösterir.
  - **Gotcha/düzeltilen bug — coin farming:** İlk sürümde `incrementGlass()` yalnızca
    `next >= goalGlasses` kontrolü yapıyordu — bu, kullanıcının hedefi doldurup bir bardağı geri
    alıp (`decrementGlass`) tekrar doldurarak (ya da hedefi tamamladıktan SONRA
    `setGoalGlasses` ile hedefi yükseltip yeniden tamamlayarak) SINIRSIZ coin kazanmasına izin
    veriyordu — kullanıcı bunu bizzat cihazda deneyip bildirdi. **Çözüm:** `WaterEntry`'ye
    `rewardClaimed` (bool, varsayılan `false`) eklendi; `WaterProvider._upsertToday(glassCount,
    {rewardClaimed})` bu bayrağı — açıkça verilmedikçe — bugünün MEVCUT kaydından KORUYARAK yazıyor
    (bardak sayısı/hedef değişse bile sıfırlanmıyor). `incrementGlass()` artık
    `justCompleted = next >= goalGlasses && !alreadyClaimed` hesaplıyor ve `true` döndüğünde
    `rewardClaimed`'i kalıcı olarak `true`'ya çeviriyor — gün bitip `_today` ilerleyene kadar bir
    daha `false`'a dönmez, bu yüzden decrement/increment döngüsü ya da hedefi sonradan yükseltmek
    ikinci bir ödül TETİKLEMEZ. `WaterProvider.isTodayRewardClaimed` getter'ı bu durumu dışarı
    açıyor. Eski (bu alan eklenmeden ÖNCE) kaydedilmiş kayıtlar `rewardClaimed: false`'a düşer
    (`raw['rewardClaimed'] as bool? ?? false`) — yani geçiş anında en fazla bir kez "bedava" ödül
    verilebilir, ama sonrasında kural tam uygulanır.
- **Zibo başlığı + rotating quote, Rüya Günlüğü'yle aynı basit desen** (`Timer.periodic(5sn)`,
  `initState`/`dispose` — bu ekran da push edilen ayrı bir rota, `IndexedStack` içinde değil, bu
  yüzden `MoneyScreen`'deki `isActive` parametresine gerek yok). `water_quotes.dart`'taki 30 sözlük
  havuzdan art arda tekrarsız seçim.
- **Gotcha — dar viewport'ta `RenderFlex overflow`:** İlerleme özetindeki `Row(spaceBetween)` içinde
  `Text('8/8 bardak')` ile `Text('2000 ml / 2000 ml')` yan yana, gerçekçi 412px test viewport'unda
  sayılar 2-4 haneye çıkınca taşıyordu. **Çözüm:** ikinci (ml) `Text`'i `Flexible(textAlign: right,
  maxLines: 1, overflow: TextOverflow.ellipsis)` ile sarmak — `costume_card.dart`/`store_screen.dart`
  bölümlerindeki aynı taşma dersinin bir tekrarı.
- **Test:** `water_provider_test.dart` (`GratitudeProvider`/`GoalsProvider` testleriyle aynı desen:
  varsayılan durum, hedefe kadar `incrementGlass` hep `false` döner, tam hedefi tamamlatan dokunuş
  `true` döner ve sonrası no-op, `decrementGlass` 0'da durur, `setGoalGlasses` 4-16 aralığına
  sabitler, gün değişince sayaç VE `rewardClaimed` sıfırlanır ama dünkü kayıt `history`de kalır,
  kalıcılık round-trip, + coin farming koruması için üç ayrı senaryo: bardağı boşaltıp tekrar
  doldurmak ikinci ödül vermiyor, ödül alındıktan sonra hedef yükseltilip yeniden tamamlansa bile
  aynı gün tekrar ödül verilmiyor, yeni günde ödül tekrar kazanılabiliyor)
  + `widget_test.dart`'a bir uçtan uca senaryo (Z-butonu modül menüsünden aç → "Su Takibi"ne dokun →
  8 bardağı sırayla işaretle → hedef tamamlanma metni + coin SnackBar'ı görünür → bir bardağı
  boşaltıp tekrar doldurarak farming denemesi → SnackBar/bakiye tekrar ARTMAZ → Ana Sayfa'ya
  dönünce bakiye yalnızca +2 artmış). Gerçek cihazda hem açık hem koyu temada `adb` ile tam akış
  (modül menüsü kartı → ekran → 8 bardağı doldur → tamamlanma banner'ı + SnackBar + bakiye artışı
  → AppBar'daki ayar ikonundan hedefi 9'a yükselt → 9. bardağı doldur → SnackBar/bakiye YİNE
  artmıyor) doğrulandı — koyu temada özel bir kod dallanması olmadığı için (tamamen `colorScheme`
  token'larından geliyor) sorunsuz uyum sağladı.
- **2026 güncellemesi — birim (bardak/şişe) + yapılandırılabilir ml + litre hedefi + geçmiş listesi:**
  Yukarıdaki `_goalGlasses`/`glassCount`/`incrementGlass`/`setGoalGlasses` API'si **tamamen
  yeniden adlandırıldı** (`goalUnitCount`/`unitCount`/`incrementUnit`/`decrementUnit` — bu bölümdeki
  eski isimler artık kod tabanında yok, yalnızca tarihsel bağlam için burada duruyor). Kullanıcı
  isteği: "Ayarlar kısmına Şişe seçeneği ekle... her birinin ml değeri ayarlanabilir olsun... hedefi
  Litre cinsinden de girebilsin... hedef tamamlanınca geçmiş listesine 'X tarihinde hedef
  tamamlandı' kaydı eklensin."
  - **Hedef artık kanonik olarak ml cinsinden tutuluyor (`WaterProvider._goalMl`), adet DEĞİL** —
    `WaterEntry`/`WaterProvider`'daki `goalUnitCount` bundan TÜRETİLİYOR
    (`(goalMl / mlPerUnit).ceil()`). Bu tasarım kararı bilinçli: kullanıcı birimi (bardak↔şişe)
    veya birim başına ml'yi değiştirdiğinde "günlük hedefim 2 litre" sabit kalsın, yalnızca kaç
    adet gerektiği yeniden hesaplansın istendi — aksi halde "8 bardak" hedefini şişeye geçince "8
    şişe"ye (4 litreye) katlamak kullanıcıyı şaşırtırdı.
  - **`WaterUnit` enum (`glass`/`bottle`)** yeni `water_entry.dart`'ta. `WaterProvider._glassMl`
    (varsayılan 250) ve `._bottleMl` (varsayılan 500) AYRI AYRI saklanıyor ve 50-2000 ml aralığına
    sabitleniyor (`setGlassMl`/`setBottleMl`) — kullanıcı birimi değiştirdiğinde diğerinin ml
    ayarı kaybolmuyor. `WaterEntry` artık o günkü `unit`/`mlPerUnit`'in bir anlık görüntüsünü de
    taşıyor (`goalUnitCount` ile aynı "geçmiş bozulmasın" gerekçesi).
  - **Hedef girişi yalnızca "Adet" (+/- stepper, güncel birimle)** — bkz. aşağıdaki "Litre girişi
    kaldırıldı" notu, litre modu KISA SÜRE yaşayıp gerçek cihazda çözülemeyen bir çökme yüzünden
    tamamen kaldırıldı. Diyalog (`_showGoalDialog`) birim seçici (`SegmentedButton<WaterUnit>`) +
    ml stepper + adet stepper'ı tek bir `StatefulBuilder` içinde barındırıyor; kaydetme sırasında
    ml/birim/hedef üç ayrı provider çağrısıyla sırayla uygulanıyor.
  - **Geri uyumluluk / veri göçü:** `_loadFromPrefs` eski formatı (`goalGlasses` düz bardak sayısı,
    entry'lerde `glassCount`/`goalGlasses`) tanıyıp `250 ml/bardak` varsayımıyla yeni `goalMl`/
    `unitCount` alanlarına çeviriyor — kullanıcının önceden kaydedilmiş su geçmişi kaybolmadı
    (cihazda doğrulandı: göç sonrası "8/8 bardak, 2000 ml/2000 ml" ve geçmişteki tamamlanma kaydı
    doğru göründü).
  - **Yeni "Geçmiş" bölümü** ekranın altına eklendi — `provider.history` (bugün hariç, zaten var
    olan getter) üzerinden her günü listeler: `entry.isCompleted` ise yeşil tik + "{tarih} tarihinde
    hedef tamamlandı" (`waterHistoryCompletedEntry`), değilse nötr ikon + "{tarih}: {sayı}/{hedef}"
    (`waterHistoryPartialEntry`). Ayrı bir "tamamlanma kaydı" modeli EKLENMEDİ — mevcut günlük
    `WaterEntry`'den `isCompleted` türetilerek gösteriliyor, `ManifestEntry`/`GoalCompletion` gibi
    paralel bir geçmiş yapısına gerek kalmadı.
  - **`waterProgressLabel`/`waterGlassFilledLabel`/`waterGlassEmptyLabel` artık `{unit}` parametresi
    alıyor** (`l10n.waterUnitGlass`/`waterUnitBottle`, kasıtlı olarak KÜÇÜK harfle — "0/8 bardak"
    gibi mevcut cümle içi kullanımla birebir aynı kalsın diye, chip/segment etiketi olarak da
    kullanılıyor olsa da büyütülmedi).
  - **Test:** `water_provider_test.dart` API rename'e göre tamamen yeniden yazıldı + yeni senaryolar
    (birim değişince hedef ml sabit kalır, ml sınırları 50-2000'e sabitlenir, eski format verisi
    doğru göç ediyor, geçmişte `isCompleted` doğru). Litre girişiyle ilgili testler aşağıdaki
    kaldırma notunda açıklanan nedenle sonradan silindi.
  - **Gotcha/çözülemeyen bug — Litre girişi kaldırıldı:** Kullanıcı gerçek cihazda "Litre kısmını
    seçip değer giriyorum sonrasında kırmızı ekranla hata veriyor" diye bildirdi. İlk teşhis:
    `double.tryParse(literText)` sonucu `liters > 0` kontrolünden geçen ama `.isFinite` OLMAYAN bir
    değer (`double.infinity`) üretebiliyordu (Dart'ta `double.infinity > 0` `true`'dur), bu da
    `WaterProvider.setGoalLiters`'ın `(liters * 1000).round()` çağrısında `UnsupportedError`
    fırlatmasına yol açıyordu. Bu teşhise göre `setGoalLiters`'a bir `isFinite` güvenlik ağı +
    `_showGoalDialog`'a canlı doğrulama/önizleme eklendi, telefona kurulup tekrar test edildi —
    **ama kullanıcı AYNI çökmenin devam ettiğini bildirdi.** Kök neden ikinci denemede de kesin
    olarak izole edilemedi (web preview'da Z-butonu etkileşimi bu ortamda güvenilir çalışmadığı
    için orada da doğrulanamadı). Kullanıcının açık isteğiyle **litre girişi TÜMÜYLE kaldırıldı**
    — `WaterProvider.setGoalLiters`, `_showGoalDialog`'daki Adet/Litre `ChoiceChip` sekmeleri ve
    ilgili tüm ARB anahtarları (`waterGoalModeUnitTab`, `waterGoalModeLiterTab`,
    `waterGoalLiterFieldLabel`, `waterGoalLiterInvalid`, `waterGoalLiterPreview`) silindi. Hedef
    artık YALNIZCA adet (+/- stepper) ile giriliyor — bu, litre denemesinden ÖNCEki, sorunsuz
    çalışan orijinal tasarım. **Eğer ileride litre girişi tekrar istenirse:** bu çökmenin kök
    nedeni hâlâ belirsiz olduğu için sıfırdan, gerçek cihazda adım adım (ör. `runtimeType`/
    `toString()` ile ham hata mesajını yakalayan bir `runZonedGuarded`/`FlutterError.onError`
    ekleyerek) teşhis edilmesi gerekir — bir dahaki sefere kör tahminle "muhtemel neden" bulup
    düzeltmeye ÇALIŞMAK yerine önce gerçek stack trace/hata mesajını görmek şart.

### Manifest Günlüğü ([manifest_journal_screen.dart](lib/screens/manifest_journal_screen.dart), [manifest_provider.dart](lib/providers/manifest_provider.dart), [manifest_entry.dart](lib/models/manifest_entry.dart), [manifest_photo_service.dart](lib/services/manifest_photo_service.dart), [manifest_quotes.dart](lib/data/manifest_quotes.dart))
- **Yerleşim: alt çubuktaki Z butonunun açtığı modül menüsünden erişiliyor**, beşinci `_ModuleCard`
  olarak — Su Takibi gibi baştan beri bu menüde tanıtıldı, hiçbir zaman Ayarlar'da yaşamadı.
- **Amaç: bir "vizyon panosu"** — kullanıcı her gün bir fotoğraf (galeriden) + kısa bir niyet/
  manifestasyon metni girer, ikisi birlikte o günün kartı olarak kaydedilir; geçmiş günler 2
  sütunlu bir galeri grid'inde birikir.
- **`ManifestPhotoService` soyutlaması** (`AdService`/`ShareService`/`NotificationService` ile
  AYNI desen): hem `image_picker` (galeri seçimi) hem `path_provider` (kalıcı depolama) platform
  kanalı kullandığı için `flutter test` gerçek implementasyona erişemez. Gerçek implementasyon
  (`ImagePickerPhotoService`) üç şey yapar: (1) `pickFromGallery()` — `ImagePicker().pickImage
  (source: ImageSource.gallery)`, kullanıcı vazgeçerse `null`; (2) `saveToPermanentStorage
  (sourcePath)` — `image_picker`'ın GEÇİCİ önbellek yolundaki dosyayı `getApplicationDocuments
  Directory()/manifest_photos/` altına, zaman damgalı benzersiz bir adla kopyalar ve YENİ kalıcı
  yolu döner (geçici yolu doğrudan saklamak, işletim sistemi önbelleği temizlediğinde fotoğrafın
  kaybolmasına yol açardı); (3) `deletePhoto(path)` — best-effort silme (try/catch, dosya yoksa
  sessizce geçer). `ManifestJournalScreen` bu servisi constructor'dan alır (varsayılan: gerçek
  `ImagePickerPhotoService`), testte sahte bir implementasyon enjekte edilir.
  - **Fotoğraflar SUNUCUYA YÜKLENMİYOR** — yalnızca cihazın kendi belge dizininde saklanıyor,
    kayıtta (bkz. aşağı) yalnızca yerel dosya yolu tutuluyor. Kullanıcı isteğiyle bilinçli bir
    kapsam sınırlaması (bkz. "Şu an mock/placeholder olan şeyler" bölümü).
- **2026 güncellemesi — günde ÇOKLU giriş + kaydettikten sonra form BOŞ/AÇIK kalır:** Kullanıcı
  geri bildirimi: "Kaydet dendiğinde ekran olduğu gibi kalıyor... kaydedilen giriş geçmiş kayıtlar
  listesine eklensin, fotoğraf yükleme alanı ve yazı metni kutusu BOŞ ve AÇIK kalsın, kullanıcı
  isterse hemen yeni bir giriş daha ekleyebilsin." Eski mimaride bir güne YALNIZCA TEK bir kayıt
  düşebiliyordu (`saveToday()` her zaman bugünün tek slotunu ÜZERİNE YAZIYORDU) — bu yüzden aynı
  gün içindeki ikinci bir "Kaydet" hiçbir zaman yeni bir geçmiş kartı OLUŞTURMUYORDU, yalnızca aynı
  kartı güncelliyordu. Bu kökten değiştirildi:
  - **`ManifestEntry` artık `DreamEntry` ile AYNI "id ile ayrı ayrı biriken kayıt" desenini
    kullanıyor** — `rewardClaimed` alanı ENTRY'DEN kaldırıldı (artık günde birden fazla entry
    olabildiği için tek bir entry'ye "ödül alındı" damgası vurmak anlamsız). `ManifestProvider`
    bunun yerine `_rewardClaimedDates` (`Set<DateTime>`) ile GÜN düzeyinde takip ediyor —
    `WaterProvider`'daki `rewardClaimed` deseninin bir üst seviyeye taşınmış hali.
  - **`ManifestProvider.addEntry()`** (eski `saveToday()`'nin yerini aldı) HER ZAMAN yeni bir kayıt
    EKLER, hiçbirinin üzerine yazmaz. Dönen `bool`, `WaterProvider.incrementUnit()` ile AYNI
    mantıkla, bu girişin coin ödülünü İLK KEZ hak edip etmediğini belirtir — çağıran widget
    yalnızca `true` döndüğünde `CoinProvider.earnManifestJournal()` çağırır (+2 ZC, günde bir kez,
    kaç giriş eklenirse eklensin).
  - **`history` artık BUGÜNÜ DE İÇERİYOR** (eski `todayEntry`/prefill ayrımı tamamen kaldırıldı) —
    her `addEntry()` çağrısı anında galeri grid'inde yeni bir kart olarak görünür.
  - **Form artık PREFILL EDİLMİYOR** (`_prefillFromToday`/`_prefilled` kaldırıldı) — ekran her
    zaman boş açılır, `_save()` başarılı kayıttan SONRA `_photoPath`'i `null`'a, metin
    controller'ını boşa çevirir. Eski fotoğraf/üzerine-yazma temizliği (`deletePhoto`) mantığı da
    kaldırıldı — artık her girişin kendi fotoğrafı kalıcı ve bağımsız, hiçbiri "eskisinin yerine
    geçmiyor".
  - **Geri uyumluluk:** `_loadFromPrefs`, eski (düz liste, id'siz, entry-düzeyinde `rewardClaimed`)
    formatı tanıyıp yeni `{nextId, entries, rewardClaimedDates}` yapısına göçürüyor.
  - **Gotcha — bulunan gerçek bug:** Yeni-format dalında `_entries.addAll(...)` çağrısı ÖNCESİNDE
    `_entries.clear()` UNUTULMUŞTU — testte provider inşa edilip ASENKRON `_loadFromPrefs()` henüz
    tamamlanmadan `addEntry()` senkron çağrılınca (yaygın bir test deseni), sonradan tamamlanan
    `_loadFromPrefs()` diskte zaten yazılmış olan AYNI kayıtları listeye BİR KEZ DAHA ekliyor,
    galeri her kartı iki kez gösteriyordu. **Çözüm:** `try` bloğunun başında `_entries.clear();
    _rewardClaimedDates.clear();` eklendi (her iki dal için de tek noktadan) — `DreamJournalProvider`
    dahil diğer tüm provider'ların `_loadFromPrefs`'i zaten bunu yapıyordu, Manifest'in ilk
    yazımında bu adım atlanmıştı.
- **Zibo başlığı + rotating quote, Su Takibi'yle aynı desen**: `manifestQuotesTr/En/Es` (15'er söz,
  manifestasyon/vizyon temalı, "kanka"/"buddy"/"amigo" tonu) + `manifestQuotesForLocale(Locale)`,
  index tabanlı döngü (bkz. Yerelleştirme bölümündeki "STRING değil INDEX tabanlı" deseni — dil
  değişince konuşma balonu doğru dile anında geçer).
- **Fotoğraf seçici alan** (`_PhotoPickerArea`) büyük, kare, yuvarlatılmış köşeli bir kart —
  `AspectRatio(1)` + `ClipRRect` benzeri `Material(borderRadius:)`. Boşken ikon+ipucu metni,
  doluyken fotoğrafı kaplar + köşede küçük bir "düzenle" rozeti. `Semantics(excludeSemantics:
  true)` — Alt Gezinme Çubuğu'ndaki aynı gotcha'ya karşı önlem (içerideki ipucu Text'i dıştaki
  label ile birleşmesin diye).
  - **Gotcha — realistik test viewport'unda `AspectRatio(1)` hit-test'i off-screen'e taşırıyor:**
    `manifest_journal_screen_test.dart`'ın VARSAYILAN 800×600 (geniş-kısa) test viewport'unda,
    fotoğraf alanı genişliğe göre kare olduğu için (~760px genişlik → ~760px yükseklik) 600px'lik
    viewport yüksekliğinin tamamen dışına taşıp `tester.tap()`'in ulaşamayacağı hale geliyordu
    (`widget_test.dart`'ın kendi `setUp()`'ındaki `MainBottomBar` gotcha'sıyla AYNI kök neden).
    **Çözüm:** bu test dosyasının kendi `setUp()`'ında da `widget_test.dart`'taki gerçekçi telefon
    viewport'u (`physicalSize: Size(412, 915)`, `devicePixelRatio: 1.0`) tekrarlandı.
- **Geçmiş galeri** 2 sütunlu `GridView.builder` (`childAspectRatio: 0.6` — kare fotoğraf + 2
  satır kısaltılmış metin + tarih için hesaplanmış pay; `0.72` gerçekçi telefon viewport'unda 16px
  `RenderFlex` overflow'una yol açtığı için 2026 güncellemesinde düşürüldü — bkz. aşağıdaki gotcha),
  her kart (`_HistoryCard`, `key: ValueKey(entry.id)` ile — `GridView.builder`'da id-bazlı stabil
  anahtar, `DreamJournalProvider` listeleriyle aynı established kalıp) küçük fotoğraf + `maxLines: 2`
  niyet metni + tarih; dokununca `showDialog` ile büyük fotoğraf + tam metin detayı açılır (Şükran
  Günlüğü'ndeki `_showEntryDetail` deseniyle aynı). Bir fotoğraf dosyası beklenmedik şekilde
  okunamazsa (`Image.file` `errorBuilder`) `_BrokenImagePlaceholder` gösterilir.
- **Test:** `manifest_provider_test.dart` (ilk giriş `true` döner, boş fotoğraf/metinle
  kaydedilemez, aynı gün İKİNCİ bir giriş İLKİNİN üzerine yazmaz + coin tekrar vermez + her ikisi
  de geçmişte ayrı ayrı görünür, gün değişince ödül durumu sıfırlanır, kalıcılık round-trip, eski
  format verisi doğru göç ediyor) + `manifest_journal_screen_test.dart` —
  `zibo_share_sheet_test.dart`'taki "bağımsız test uygulaması + sahte servis enjeksiyonu"
  deseniyle AYNI (gerçek `image_picker`/`path_provider` platform kanallarına HİÇ dokunulmuyor):
  fotoğraf seç + niyet yaz + kaydet → coin kazanılır + form boş/açık kalır + giriş geçmişte
  görünür; aynı gün ikinci giriş eklemek coin tekrar vermez ve hiçbir fotoğrafı silmez, iki giriş
  de ayrı ayrı görünür; bugün için zaten kayıt olsa bile ekran açılışında form BOŞ olur (prefill
  YOK), mevcut kayıt geçmişte görünür. Gerçek cihazda modül menüsü kartı (5. kart, sparkle ikonu)
  doğrulandı.

### Profil ([profile_screen.dart](lib/screens/profile_screen.dart), [profile_provider.dart](lib/providers/profile_provider.dart), [profile_stats.dart](lib/utils/profile_stats.dart), [profile_stat_card.dart](lib/widgets/profile_stat_card.dart), [circular_score_gauge.dart](lib/widgets/circular_score_gauge.dart), [stat_trend_chart.dart](lib/widgets/stat_trend_chart.dart), [bond_level.dart](lib/models/bond_level.dart), [address_terms.dart](lib/data/address_terms.dart), [address_term.dart](lib/utils/address_term.dart), [favorite_quotes_provider.dart](lib/providers/favorite_quotes_provider.dart), [favorite_quote_button.dart](lib/widgets/favorite_quote_button.dart), [costume_closet_preview.dart](lib/widgets/costume_closet_preview.dart), [bond_level_screen.dart](lib/screens/bond_level_screen.dart), [longest_streak_screen.dart](lib/screens/longest_streak_screen.dart), [coin_summary_screen.dart](lib/screens/coin_summary_screen.dart), [address_term_screen.dart](lib/screens/address_term_screen.dart), [favorite_quotes_screen.dart](lib/screens/favorite_quotes_screen.dart))

- **Yerleşim (2026 güncellemesi): artık alt gezinme çubuğunun ÜÇÜNCÜ sekmesi** (kullanıcı isteğiyle
  Para ve Birikim'le yer değiştirdi — bkz. "Alt Gezinme Çubuğu" bölümündeki "Profil↔Birikim yer
  değiştirme" notu). Bu yüzden diğer sekmeler (Ana Sayfa/Hedefler/Mağaza) gibi kendi
  `Scaffold`/`AppBar`'ı YOK, `RootScreen`'in ortak AppBar'ını paylaşıyor. **Eski yerleşim (Z butonu
  modül menüsünün altıncı kartı) artık geçerli DEĞİL** — o konum şimdi Para ve Birikim'e ait.
- **Üst kısım — fotoğraf + isim, `CloudStateStore` ile kalıcı:** `ProfileProvider` (`name`+
  `photoPath`, Varyant A tek anahtarlı JSON blob, `profileState`) diğer tüm provider'larla AYNI
  desen. Fotoğraf seçimi/kalıcı depolama için Manifest Günlüğü'nün servisi jenerikleştirilip
  yeniden kullanıldı: `manifest_photo_service.dart`/`ManifestPhotoService` →
  `photo_picker_service.dart`/`PhotoPickerService` olarak yeniden adlandırıldı (davranış
  DEĞİŞMEDİ, yalnızca artık iki bağımsız özellik tarafından paylaşıldığı için ismi manifest'e özgü
  olmaktan çıkarıldı) — ikisi de aynı `app_photos/` klasörünü kullanıyor (zaman damgalı benzersiz
  dosya adları sayesinde çakışma riski yok).
  - **Profil fotoğrafı Manifest'ten farklı olarak TEK ve DEĞİŞTİRİLEBİLİR** (Manifest'in "hiçbiri
    bir öncekinin yerine geçmez, hepsi birikir" felsefesinin TAM TERSİ) — yeni fotoğraf seçilince
    eskisi `deletePhoto` ile best-effort silinir, öksüz dosya kalmaz.
  - **Fotoğrafın kendisi yine yalnızca cihazda yerel** (Manifest Günlüğü'ndeki AYNI bilinçli kapsam
    sınırlaması — bkz. o bölüm) — Firestore'a yalnızca dosya YOLU (string) senkronize edilir, foto
    baytları değil; cihazlar arası fotoğraf taşınmaz.
  - **2026 güncellemesi — galeri izni modeli doğrulandı/tamamlandı:** Kullanıcı isteği: fotoğraf
    seçmeden önce uygun sistem izni istensin, mümkünse Android'in modern "Photo Picker"ı kullanılıp
    tam galeri izni hiç istenmesin. İnceleme sonucu: `PhotoPickerService`'in `image_picker.
    pickImage(source: ImageSource.gallery)` çağrısı Android 13+ (API 33+) cihazlarda **zaten**
    OS'nin kendi Photo Picker arayüzünü otomatik kullanıyordu — bu, kullanıcının yalnızca seçtiği
    fotoğrafı uygulamaya açan bir sistem UI'sı olduğu için **hiçbir çalışma zamanı izni
    GEREKTİRMEZ** (`READ_EXTERNAL_STORAGE`/`READ_MEDIA_IMAGES` istemeden çalışır) — kod tarafında
    bir değişiklik GEREKMEDİ (`image_picker: ^1.2.3`/`compileSdk 37` zaten yeterliydi). **Gerçek
    eksik** Android 12L ve altı (API 32-) cihazlardı — bu eski sürümlerde Photo Picker
    YERLEŞİK OLARAK yok, `image_picker` geriye düşüp klasik depolama izni istemeye ihtiyaç
    duyabiliyor. `android/app/src/main/AndroidManifest.xml`'e Google'ın resmi Photo Picker geçiş
    rehberinin önerdiği fallback izni eklendi:
    ```xml
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    ```
    `maxSdkVersion="32"` sayesinde bu izin API 33+'ta HİÇBİR ETKİ YARATMAZ (asla istenmez) —
    yalnızca API 32 ve altı için sessiz bir geri düşüş yolu. **Bu deseni tekrarlayın:** ileride
    galeri/medya erişimi gerektiren yeni bir özellik eklenirse, önce `image_picker`'ın Photo
    Picker'ı zaten kapsayıp kapsamadığını kontrol edin — çoğu modern kullanım için EK bir çalışma
    zamanı izin isteği kodu YAZMAYA gerek yoktur, yalnızca eski OS sürümleri için manifest'te
    `maxSdkVersion`'lı bir fallback yeterlidir.
  - İsim alanı `onSubmitted`/odak kaybında kaydedilir (HER tuş vuruşunda DEĞİL — gereksiz
    Firestore yazımı olmasın diye), `TextEditingController`'ın metni `context.watch<
    ProfileProvider>()`'dan her build'de senkronize edilir ama YALNIZCA alan o an odaklı DEĞİLKEN
    (aksi halde kullanıcı yazarken imleç/metin üzerine yazılırdı).
- **Alt kısım — "İstatistiklerim": dört sabit kategori, her biri kendi kartında bir trend grafiği +
  0-10 dairesel puan.** Puanlar/trendler AYRI bir kalıcı state DEĞİL — `ProfileStats.compute(...)`
  (saf, yan etkisiz bir fonksiyon) kaynak provider'ların (Money/Gratitude/Manifest/Goals/Water)
  GÜNCEL durumundan HER `build()`'de canlı hesaplanıyor; `ProfileScreen` bu 5 provider'ı `context.
  watch` ile izlediği için biri değişince kartlar otomatik yeniden hesaplanıp güncelleniyor.
  - **Dört kategori ve formülleri** (kullanıcının "mantıklı ve tutarlı olsun, formülü sen
    belirle" isteğiyle tasarlandı — bkz. `profile_stats.dart` içindeki tam dokümantasyon):
    - **Para Yönetimi:** `%70` birikim oranı (`birikim/(birikim+harcama)`, %50 oran tam puan
      sayılır — "en az %20 biriktir" kişisel finans kuralının üzerinde cömert bir hedef) `+ %30`
      son 4 haftanın kaçında en az bir kayıt girildiği (tutarlılık).
    - **Şükür ve Manifest:** son 30 günün kaçında Şükran Günlüğü VE kaçında Manifest Günlüğü
      kullanıldığının (farklı GÜN sayısı — aynı gün birden fazla manifest girişi tek gün sayılır)
      ortalama oranı.
    - **İstikrar:** `%60` aktif hedeflerin güncel döngüdeki ortalama ilerlemesi (`completedCount/7`)
      `+ %40` son 8 haftada tamamlanan TAM 7-günlük döngü sayısı, **3** tamamlama = tam puan
      (`totalCompletions/3`, kırpılır).
    - **Öz Saygı ve Sağlık:** son 30 günün her birindeki Su Takibi KISMİ ilerleme oranının
      (`unitCount/goalUnitCount`, 1.0'da kırpılır) ortalaması (kayıt hiç girilmemiş günler 0 oranla
      sayılır, 30 sabit payda — birkaç gün kullanıp bırakmak yapay yüksek puana yol açmasın diye).
    - **2026 bug düzeltmesi — gerçek kullanıcı raporu: "İstikrar ve Öz Saygı-Sağlık çalışmıyor."**
      Kök neden formül DEĞİL, formülün AŞIRI KATI olmasıydı: İstikrar'ın eski ağırlıkları (`%40`
      güncel + `%60` geçmiş, geçmiş bileşeni 8 haftada 8 TAM 7-gün tamamlaması istiyordu) ve Öz
      Saygı-Sağlık'ın eski `isCompleted` (ikili, hepsi-ya-da-hiçbiri) ölçütü, GERÇEK ama KUSURSUZ
      OLMAYAN kullanımı (ör. günlük check-in yapan ama henüz hiç 7 günü kesintisiz tamamlamamış bir
      kullanıcı; günde 8 bardaktan 5-6'sını içen ama nadiren tam 8'e ulaşan bir kullanıcı) neredeyse
      HİÇ ödüllendirmiyordu — puan sürekli 0'a yakın kalıp kullanıcıya "çalışmıyor" gibi görünüyordu.
      Para Yönetimi/Şükür-Manifest zaten KISMİ katılımı ödüllendirdiği için (herhangi bir kullanım
      orantılı puan veriyor) bu ikisinden şikayet gelmedi — asimetri buradan kaynaklanıyordu.
      **Düzeltme:** İstikrar'ın ağırlıkları ters çevrildi (güncel andaki ilerlemeye daha fazla
      ağırlık) VE geçmiş eşiği gevşetildi (8→3); Öz Saygı-Sağlık ikili ölçütten KISMİ orana geçti
      (`unitCount/goalUnitCount`, ör. 6/8 bardak artık 0.75 kredi veriyor, 0 değil). Yeni testler
      (`profile_stats_test.dart`): "haftanın yarısından fazlasını check-in yapan ama hiç tam
      döngü tamamlamamış" ve "hedefin yarısını her gün düzenli içen ama asla %100'e ulaşmayan"
      senaryoları artık anlamlı (0'a yakın olmayan) puanlar üretiyor.
  - **ARTIK GEÇERSİZ NOT (tarihsel bağlam için tutuluyor):** Bu bölüm önceden "İstikrar kartı
    pratikte HİÇBİR ZAMAN 'veri yok' göstermez" diyordu — `GoalsProvider`'ın o zamanki otomatik
    örnek hedef eklemesi yüzünden. **O otomatik örnek hedef sonradan KALDIRILDI** (bkz. "Hedef
    Takibi" bölümündeki "2026 güncellemesi — otomatik örnek hedef KALDIRILDI" notu) — taze bir
    kurulumda `goals.goals` artık GERÇEKTEN boş, İstikrar kartı da diğer üç kategori gibi tutarlı
    şekilde "veri yok" gösteriyor (`profile_stats_test.dart`'taki ilk test bunu doğruluyor).
  - **Renk sistemleri kasıtlı olarak İKİ BAĞIMSIZ katman:** `CircularScoreGauge`'un halka rengi
    SADECE puana göre (0'da kırmızı → 5'te amber → 10'da yeşil, sürekli `Color.lerp` geçişi);
    `StatTrendChart`'ın çizgi rengi SADECE kategoriye göre sabit (Para=mavi, Şükür ve Manifest=
    mor, İstikrar=turuncu, Öz Saygı ve Sağlık=yeşil) — biri "ne kadar iyi gidiyor", diğeri "hangi
    kategori" bilgisini taşıdığı için bilerek karıştırılmadı.
  - **`StatTrendChart`** `fl_chart`'ın `LineChart`'ı ama `MoneyTrendChart`'ın aksine eksen
    etiketleri/dokunma tooltip'i YOK (kullanıcı isteği: "basit bir çizgi/bar grafik") — yalnızca
    genel eğilimi gösteren küçük bir sparkline.
  - **Veri yoksa** (`CategoryStat.hasData == false`) grafik+gösterge yerine teşvik edici bir
    mesaj gösteriliyor ("Henüz veri yok — {modül}'i kullanmaya başla!").
  - **2026 güncellemesi — `CircularScoreGauge` artık dolma + sayaç animasyonuyla açılıyor,
    Profil'e HER girişte tekrar oynuyor.** Kullanıcı isteği: halka sıfırdan gerçek puana doğru
    dolsun, içindeki sayı (0-10) da AYNI ANDA 0'dan gerçek değere sayarak artsın, kısa/akıcı
    (1-1.5sn) olsun, sayfaya her girişte TEKRAR oynasın.
    - **`CircularScoreGauge`** (`StatelessWidget`'tan `StatefulWidget`'a çevrildi) artık kendi
      `AnimationController`'ını (`initState`'te `forward()` çağrılan, 1200ms,
      `Curves.easeOutCubic`) taşıyor — `Tween<double>(begin: 0, end: score)`'un `AnimatedBuilder`
      ile beslediği TEK bir `value`, hem `CircularProgressIndicator.value`'yu (halka dolumu) hem
      ortadaki `Text` (`value.toStringAsFixed(1)`, sayaç) hem halka rengini (`_ringColorFor(value)`
      — kırmızı→amber→yeşil geçişi artık ANINDA değil, dolan değere göre CANLI hesaplanıyor)
      besliyor — üç görsel efekt (dolum/sayaç/renk) TEK bir animasyon değerinden türediği için
      birbirinden asla kopmuyor/senkronsuz kalmıyor.
    - **"Her girişte tekrar oynasın" isteği — `initState`'te BİR KEZ çalışan bir
      `AnimationController` kendi başına bunu SAĞLAMAZ** (`ProfileScreen` `IndexedStack` içinde
      hiç dispose olmuyor, bkz. "Mimari özet" bölümündeki `IndexedStack` gotcha'sı — sekmeler
      arası geçişte widget `initState`'i BİR DAHA çalıştırmaz). Çözüm, `GoalTrackingScreen`/
      `StoreScreen`'in ZATEN kullandığı `isActive` deseninin AYNISI: `ProfileScreen` yeni bir
      `isActive` parametresi kazandı (`root_screen.dart`'ta `_selectedIndex ==
      _profileTabIndex`), `_ProfileScreenState.didUpdateWidget` `widget.isActive &&
      !oldWidget.isActive` (sekme AZ ÖNCE aktif oldu) anında `_statsReplayKey++` ile
      `setState` yapıyor.
    - **Yeniden oynatma tekniği — "İstatistiklerim" kart listesi `KeyedSubtree(key:
      ValueKey(_statsReplayKey), ...)` ile sarıldı.** `_statsReplayKey` her sekme
      re-aktivasyonunda artınca Flutter bu `Key` değişikliğini "tamamen farklı bir widget" olarak
      yorumlayıp TÜM alt ağacı (dolayısıyla içindeki her `CircularScoreGauge`'un `State`'ini VE
      `AnimationController`'ını) söküp SIFIRDAN yeniden kuruyor — bu, `ProfileStatCard`/
      `CircularScoreGauge`'un public API'sine dokunmadan, "replay tetikleyicisini" ara
      widget'lardan geçirmeden animasyonu baştan başlatan en az invaziv yöntem (bir
      `GlobalKey`+`resetAnimation()` çağrı zinciri kurmaktan çok daha basit).
    - **Test + doğrulama:** `flutter test` (256/256) + Profil sekmesine ilk giriş VE
      sekmeler arası geçip geri dönme (Ana Sayfa→Profil) senaryolarının İKİSİNDE de dört
      `CircularScoreGauge`'un 0'dan gerçek puana dolarak/sayarak animasyonlandığı, ~1.2 saniye
      sonra durup doğru nihai değerde kaldığı gerçek cihazda doğrulandı.
- **"Zibo ile Bağın" bölümü (2026 güncellemesi) — istatistik kartlarının altında 7 satırlık bir
  liste.** Kullanıcı isteği (verbatim özet): bond seviyesi, en uzun seri, kostüm dolabı önizlemesi,
  coin özeti, hitap tercihi, favori sözler, profil kartı paylaşımı — "liste liste olsun basınca yeni
  sayfa açılsın" (kostüm dolabı ve paylaşım İSTİSNA, aşağıda açıklandı). Her satır `_ProfileLinkRow`
  (profile_screen.dart içinde private) — ikon + başlık + CANLI alt metin (ilgili provider'ı
  `context.watch` ile izleyen `ProfileScreen.build()`'den geliyor, ayrı bir state YOK) + sağ ok,
  `modules_menu_sheet.dart`'taki `_ModuleCard` ile aynı görsel dil (`Card` + `ListTile`).
  1. **Zibo ile Bağ Seviyesi** (`bond_level_screen.dart`) — `ProfileProvider.firstUsedAt`'ten
     hesaplanan `daysSinceFirstUsed()` gün sayısı + `BondLevel` kademesi (`bond_level.dart`, yeni
     model: `newBuddy`(<7g)/`gettingClose`(<30g)/`oldFriend`(<90g)/`soulBuddy`(<365g)/
     `lifetimeBuddy`(365g+) — eşikler kullanıcının "mantıklı gün aralıkları" isteğiyle serbestçe
     seçildi: hafta/ay/üç ay/yıl, alışkanlık uygulamalarında sık kullanılan dönüm noktaları). Satır
     alt metni VE sayfa "Zibo ile {gün} gündür kankasın" gösterir. **2026 güncellemesi — bu SATIR
     ARTIK `applyAddressTerm()`'DEN GEÇMİYOR, BİLEREK:** önceden madde 5'teki hitap tercihi
     mekanizmasıyla "kanka" kelimesi kullanıcının seçtiği terimle (ör. kendi adı "Mehmet Can")
     değiştiriliyordu — ama "-sın" eki bir sıfata değil bir ÖZEL İSME eklenince ("... Mehmet
     Cansın") anlamsızlaşıyordu (kullanıcı bildirdi: "o kısım mantıklı değil"). Diğer söz
     havuzlarındaki "kanka" kullanımları (goal_quotes.dart vb., madde 5'te açıklanan asıl
     mekanizma) bundan ETKİLENMEDİ — yalnızca bu ÜÇ konum (bond_level_screen.dart +
     profile_screen.dart'taki satır alt metni + paylaşım kartı metni) `applyAddressTerm` çağrısını
     kaybetti, `profileBondLevelRowSubtitle` ARB metni artık DOĞRUDAN kullanılıyor. Sayfa ayrıca bir
     sonraki kademeye kaç gün kaldığını (`nextBondLevelThreshold`) veya (en üst kademedeyse) bir
     tebrik mesajı gösterir.
  2. **En Uzun Seri Rekoru** (`longest_streak_screen.dart`) — `GoalsProvider.longestStreak`'i
     gösterir (yeni alan, bkz. altta). Basit: büyük rakam + açıklama + teşvik cümlesi.
  3. **Kostüm Dolabı Önizlemesi** (`costume_closet_preview.dart`) — **İSTİSNA: yeni bir sayfa
     AÇMAZ**, `CostumeProvider.ownedIds`'teki kostümlerin küçük görsellerini yatay bir
     `ListView.separated` şeridinde doğrudan Profil sayfasının İÇİNDE gösterir (kullanıcının açık
     isteği: "tıklanınca Store/Costumes sayfasına gider" — önizleme kartının KENDİSİ, satırın
     tamamı bir `InkWell`). Hiç kostüm yoksa teşvik mesajı gösterir. Dokununca (veya boş mesaja
     dokununca) `Navigator.push` ile YENİ bir `Scaffold(appBar: AppBar(title: storeTitle), body:
     StoreScreen(initialSection: StoreSection.costumes))` açılır — `StoreScreen`'in kendisi
     (normalde Mağaza sekmesinde kendi Scaffold'u OLMAYAN bir tab içeriği) burada elle bir
     `Scaffold` içine SARILIYOR, çünkü push edilen bir rota olarak kendi AppBar'ına/geri
     butonuna ihtiyacı var ama `StoreScreen`'in kendisi HİÇ değiştirilmedi (Mağaza sekmesindeki
     kullanımı etkilenmedi). Bunu mümkün kılmak için `store_screen.dart`'taki özel `_StoreSection`
     enum'u **public** `StoreSection`'a çevrildi + `StoreScreen` yeni bir `initialSection`
     parametresi kazandı (varsayılan `StoreSection.coins` — Mağaza sekmesinin/'+' ikonunun
     davranışı DEĞİŞMEDİ).
  4. **Zibo Coin Özeti** (`coin_summary_screen.dart`) — `CoinProvider.totalEarned`/`totalSpent`
     (yeni alanlar, bkz. altta) iki ayrı kartta gösterilir (yeşil "Toplam Kazanılan" / kırmızı
     "Toplam Harcanan").
  5. **Hitap Tercihi** (`address_term_screen.dart`) — kullanıcı kendi hitap şeklini **serbest bir
     metin kutusuna** yazar (`hintText`: "Zibo sana nasıl seslensin? Örn: Kanka, Reis, Aslanım...");
     odak kaybında (`FocusNode` dinleyicisi) VEYA klavyeden "Bitti"ye basılınca (`onSubmitted`)
     `ProfileProvider.setAddressTerm()` ile kaydedilir. **Varsayılan hâlâ `'Kanka'`**
     (`address_terms.dart`'taki `defaultAddressTerm`) ve **bilerek YALNIZCA Türkçe** — mekanizma
     yalnızca Türkçe söz havuzlarını etkiliyor (İngilizce/İspanyolca havuzlar zaten farklı sabit
     kelimeler kullanıyor: "buddy"/"amigo", bkz. "Yerelleştirme" bölümü).
     - **2026 güncellemesi — 4 sabit seçenekten (`Kanka`/`Abi-Abla`/`Patron`/`Reis`,
       `RadioListTile`) serbest metne geçildi:** Kullanıcı isteği: "hazır seçenekleri kaldır,
       kullanıcının kendi hitap şeklini serbestçe yazabileceği bir metin kutusu koy." `address_terms.
       dart`'taki `addressTermOptions` listesi TAMAMEN silindi, yalnızca `defaultAddressTerm` sabiti
       kaldı. `AddressTermScreen` `StatelessWidget`'tan `StatefulWidget`'a çevrildi (kendi
       `TextEditingController`/`FocusNode`'unu tutmak için).
     - **Boş girdi koruması (yeni bir çökme riskini önlemek için eklendi):**
       `applyAddressTerm`'in `term[0].toUpperCase()` çağrısı boş bir dizede `RangeError` fırlatır —
       kullanıcı metin kutusunu tamamen silip odağı kaybederse `ProfileProvider.setAddressTerm()`
       artık `value.trim().isEmpty` ise sessizce `defaultAddressTerm`'e döner (aynı guard
       `_loadFromPrefs()`'e de eklendi, kalıcı depoda boş bir string bulunursa diye). Bu guard
       olmadan boş metin kutusuyla uygulamanın konuşma balonu gösteren HERHANGİ bir ekranı
       çökertirdi — `profile_provider_test.dart`'a bunu doğrulayan bir test eklendi.
     - **`applyAddressTerm(text, term)`** (`lib/utils/address_term.dart`, saf fonksiyon, davranışı
       DEĞİŞMEDİ) —
       `term == 'Kanka'` (varsayılan) ise metni OLDUĞU GİBİ döner (hızlı yol); değilse cümle
       başındaki büyük harfli `"Kanka"`yı seçilen terimin BÜYÜK harfli hâliyle, cümle içindeki
       küçük harfli `"kanka"`yı KÜÇÜK harfli hâliyle değiştirir (iki ayrı `replaceAll` — söz
       havuzlarındaki tutarlı kullanım buna izin veriyor, hiçbir söz "kanka" kelimesini ek
       almış/bitişik biçimde barındırmıyor, grep ile doğrulandı).
     - **8 ekranın HEPSİNE uygulandı** — HomeScreen, GoalTrackingScreen, MoneyScreen,
       WaterTrackingScreen, DreamJournalScreen, GratitudeJournalScreen, MoodTrackingScreen,
       ManifestJournalScreen: her birinde konuşma balonuna gösterilecek söz hesaplandığı NOKTADA
       (`quotes[i % quotes.length]` sonrası) `applyAddressTerm(..., context.watch<
       ProfileProvider>().addressTerm)` ile sarmalanıyor. `notification_provider.dart` BİLİNÇLİ
       OLARAK bu kapsamın DIŞINDA — özellik zaten geçici olarak devre dışı (bkz. "Bildirimler"
       bölümü).
     - **2026 güncellemesi — Ana Sayfa söz havuzuna 179 yeni söz eklendi, "kanka" hâlâ dinamik
       yer tutucu.** Kullanıcı isteği (verbatim özet): "250 yeni sözü ekle, 'kanka' kelimesi
       sabit metin değil dinamik bir yer tutucu olmalı — Profil'deki hitap tercihi neyse
       gösterimde onunla değişmeli; mevcut havuzlarda geçen 'kanka'lar da aynı kurala tabi
       olsun." İnceleme sonucu bu mekanizma (`applyAddressTerm`, yukarıda) **zaten TAM olarak
       istenen şekilde çalışıyordu** — 8 ekranın hepsi zaten her gösterimde seçilen sözü
       `applyAddressTerm`'den geçiriyordu; bu yüzden istek, KOD tarafında hiçbir değişiklik
       gerektirmedi, YALNIZCA veri (yeni sözler) eklendi.
       - **179/250 eklendi, 71'i elendi:** kullanıcının verdiği 250 satırlık liste hem KENDİ
         İÇİNDE (aynı cümle birden fazla kez yapıştırılmış — 54 satır) hem de MEVCUT 100 sözlük
         havuzla (23 satır zaten pool'da vardı, ör. "Kanka bugün kendine bir teşekkür
         borçlusun.") ÇAKIŞAN tekrarlar içeriyordu. Eklemeden önce iki aşamalı bir dedupe
         uygulandı (`awk '!seen[$0]++'` ile batch-içi, `grep -Fxvf` ile mevcut pool'a karşı) —
         sonuç: `ziboMessagesTr` artık 100 → **279** söz. **Neden dedupe edildi:** kullanıcı
         "250 YENİ söz" dedi — birebir tekrar eden bir cümleyi ikinci kez eklemek "yeni" değil,
         yalnızca aynı sözün tekrar gösterilme olasılığını artırıp havuzun çeşitliliğini
         suni şekilde şişirirdi (`HomeScreen._pickNextIndex`'in "art arda aynı söz gelmesin"
         garantisi ayrı kayıtlar arasında ayrım yapmadığı için, iki AYNI metin art arda gelme
         riskini de artırırdı).
       - **İlk sürümde YALNIZCA `ziboMessagesTr`'ye eklenmişti** — kullanıcı o an yalnızca Türkçe
         metin vermişti, çeviri istenmemişti. **Bu asimetri SONRADAN (aşağıdaki 2026 güncellemesi)
         GİDERİLDİ** — bkz. hemen altındaki madde, artık üç dil de 279/279/279.
       - **Test:** `address_term_test.dart`'a iki yeni test eklendi — yeni pool'dan bir örneğin
         `applyAddressTerm` ile doğru dönüştüğü, VE `ziboMessagesTr`'de artık birebir tekrar
         KALMADIĞI (`.toSet().length == .length`).
       - **Gerçek cihazda doğrulama:** Profil'de daha önce ayarlanmış "Mehmet Can" hitap
         tercihiyle Ana Sayfa'da Zibo'ya art arda dokunulup yeni pool'dan bir söz
         ("Kanka dün de zorlanmıştın ama başardın.") ekranda **"Mehmet Can dün de zorlanmıştın
         ama başardın."** olarak doğru dönüştürülmüş hâliyle görüldü.
     - **2026 İKİNCİ güncelleme — 179 yeni söz EN/ES'e uyarlandı, hitap sistemi ÜÇ dilde de
       işlevsel hale getirildi.** Kullanıcı isteği: "179 sözü İngilizce/İspanyolca'ya çevir/uyarla
       (kelimesi kelimesine değil, Zibo'nun tonunu koruyarak), dinamik hitap sistemini EN/ES'te de
       koru." İnceleme sırasında **gerçek, önemli bir eksik bulundu:** `applyAddressTerm` o ana
       kadar YALNIZCA Türkçe metinlerdeki "Kanka"yı değiştiriyordu — İngilizce/İspanyolca söz
       havuzları "Buddy"/"Amigo" kullandığı için bu fonksiyon o iki dilde TAMAMEN ETKİSİZDİ
       (kullanıcı İngilizce/İspanyolca arayüzdeyken hitap tercihi HİÇBİR ZAMAN kişiselleşmiyordu —
       bu, dokümantasyonda "bilerek" diye işaretlenmiş bir kapsam sınırlamasıydı, ama kullanıcının
       bu turdaki isteğiyle artık geçerliliğini yitirdi).
       - **`applyAddressTerm` locale-aware yapıldı** (`utils/address_term.dart`) — üçüncü,
         opsiyonel bir `Locale` parametresi (varsayılan `Locale('tr')`, geriye dönük uyumluluk
         için) alıp `_placeholderFor(locale)` ile hangi kelimenin değiştirileceğini seçiyor: TR
         "Kanka", EN "Buddy", ES "Amigo". `defaultAddressTerm` karşılaştırması (`term ==
         'Kanka'`) HİÇ değişmedi — kullanıcı hitabı özelleştirmediyse (hangi arayüz dilinde
         olursa olsun) metin aynen kalıyor, tıpkı öncesinde olduğu gibi.
       - **8 ekranın HEPSİ güncellendi** (`home_screen.dart` + 7 modül ekranı) — her biri artık
         `Localizations.localeOf(context)`'i bir `locale` değişkenine alıp hem `xQuotesForLocale
         (locale)` hem `applyAddressTerm(..., addressTerm, locale)` çağrısında kullanıyor (önceden
         `Localizations.localeOf(context)` iki kez, ayrı ayrı çağrılıyordu — küçük bir temizlik).
         Bu, yalnızca `ziboMessagesEn/Es`'i DEĞİL, `goalQuotesEn/Es`/`moneyQuotesEn/Es`/
         `waterQuotesEn/Es`/vb. TÜM diğer 7 söz havuzunun İngilizce/İspanyolca sürümlerini de
         (hepsi zaten "Buddy"/"Amigo" kullanıyordu, bkz. `grep` doğrulaması) aynı anda düzeltti —
         kullanıcı yalnızca Ana Sayfa'nın 179 yeni sözünü kastetmiş olsa da, paylaşılan fonksiyonu
         düzeltmek TÜM ekranlara otomatik yayıldı.
       - **179 sözün İngilizce/İspanyolca uyarlaması** — kelimesi kelimesine ÇEVİRİ değil, Zibo'nun
         sıcak/samimi tonunu o dilde doğal duracak şekilde koruyan bir UYARLAMA (orijinal 100
         sözlük havuzla AYNI felsefe, bkz. dosyanın en üstündeki yorum). `ziboMessagesEn`/
         `ziboMessagesEs` artık TR ile AYNI uzunlukta: **279/279/279.**
       - **Kalite kontrolü — iki ayrı duplicate turu gerekti:** İlk taslakta hem YENİ 179 satırın
         KENDİ İÇİNDE (TR kaynağın kendisi de tekrar-yakın cümleler içeriyordu, bkz. yukarıdaki
         "71'i elendi" notu) hem de yeni çevirilerin ESKİ 100'lük havuzla ÇAKIŞTIĞI birkaç satır
         bulundu (toplam TR 279 + EN 279 + ES 279, hepsi elle bir Dart testiyle sıfır tekrara
         indirildi). **Gotcha — basit `grep`/`sort | uniq -d` YETERSİZ kaldı:** bazı satırlar aynı
         metni taşısa da biri çift tırnak (`"..."`, apostrof içerdiği için) biri tek tırnak
         (`'...'`) ile yazılmıştı — ham metin satırları FARKLI görünüyordu (tırnak karakteri
         farklı) ama Dart STRING DEĞERİ olarak birebir aynıydı. Bu yüzden nihai doğrulama
         `flutter test` içinde geçici bir betikle (`ziboMessagesEn[i] == ziboMessagesEn[j]`
         karşılaştırması, GERÇEK Dart string eşitliği) yapıldı — yalnızca metin tabanlı `grep`
         kontrolüne güvenmeyin, kaçırabilir.
       - **Test:** `address_term_test.dart`'a yeni bir `group` eklendi — İngilizce/İspanyolca
         locale ile `applyAddressTerm` çağrıları, varsayılan terimde hiçbir dilde değişmeme,
         `locale` verilmeden çağrılınca Türkçe'ye düşme (geriye dönük uyumluluk), yeni EN/ES
         sözlerin doğru dönüştüğü, VE üç havuzun da (TR/EN/ES) 279 uzunlukta + tekrarsız olduğu.
       - **Gerçek cihazda doğrulama:** APK yeniden derlenip telefona kurulup çöküş izi olmadan
         açıldığı doğrulandı (`adb shell monkey` + `pidof`) — İngilizce/İspanyolca arayüzde hitap
         tercihinin görsel olarak doğru kişiselleştiğinin TAM doğrulaması (dil değiştirip Zibo'ya
         dokunarak) kullanıcının kendi cihazında yapılması gerekiyor, bu arc'ta yalnızca kod
         seviyesinde (`flutter test`, 244 test) doğrulandı.
  6. **Favori Sözler** (`favorite_quotes_screen.dart` + `favorite_quotes_provider.dart` +
     `favorite_quote_button.dart`) — Ana Sayfa'nın konuşma balonunun sol üst köşesine (sağ üstteki
     `ShareZiboButton`'ın SİMETRİĞİ, `Positioned(top: -6, left: -6)`) `FavoriteQuoteButton` eklendi:
     `ShareZiboButton` ile BİREBİR aynı görsel stil (`IconButton.filled`, 36×36), ikon
     `Icons.favorite`/`Icons.favorite_border` arasında geçiş yapıyor. `FavoriteQuotesProvider`
     (`DreamJournalProvider` ile aynı `CloudStateStore` deseni, `favoriteQuotes` anahtarı, düz bir
     `List<String>`) — `toggleFavorite(quote)` yoksa BAŞA ekler (en son favorilenen en üstte),
     varsa çıkarır. **Söz metni, favorilendiği ANDAKİ (hitap tercihi UYGULANMIŞ) hâliyle saklanır**
     — `GoalCompletion`'daki "anlık görüntü" mantığıyla aynı gerekçe (bkz. "Hedef Takibi" bölümü):
     kullanıcı sonradan hitap tercihini değiştirirse geçmişte favorilediği söz olduğu gibi kalır,
     geriye dönük değişmez. **Yalnızca Ana Sayfa'nın konuşma balonuna eklendi** (kullanıcının açık
     isteği "Ana Sayfa'daki konuşma balonuna") — diğer 7 modül ekranının kendi sözleri
     favorilenemiyor, kapsam bilinçli olarak dar tutuldu.
  7. **Profil Kartı Paylaşımı** — **İSTİSNA: yeni bir sayfa AÇMAZ**, kullanıcının açık isteği
     "mevcut Zibonu Paylaş altyapısını aynı mantıkla kullan" doğrultusunda YENİ bir kart/sheet
     widget'ı YAZILMADI — bunun yerine `ProfileScreen._openShareCard()` bond seviyesi + 4 kategori
     puanını (`_statTitle()` ile `ProfileStatCard`'daki başlık eşlemesinin bir kopyası, private,
     dosyaya özel küçük bir duplikasyon — ayrı bir paylaşılan yardımcıya çıkarmaya değmeyecek kadar
     küçük) tek bir çok satırlı `String`'e biçimlendirip DOĞRUDAN mevcut `ZiboShareSheet(message:
     ...)`'e geçiriyor (`ShareZiboButton._openShareSheet`'teki AYNI `showModalBottomSheet` çağrı
     deseni). `ZiboShareCard`/`ZiboShareSheet`'in kendisinde HİÇBİR DEĞİŞİKLİK yapılmadı — zaten
     genel bir `message: String` parametresi aldıkları için görev tamamen bu formatlanmış metni
     üretmekten ibaretti. Kart, Zibo logosunu (ZiboShareCard'ın kendi şablonunun bir parçası, sabit
     sol üstte) + bağ seviyesi/gün sayısını + 4 kategori puanını gösterir.
- **Yeni provider alanları (Firestore'a `CloudStateStore` ile senkronize, diğerleriyle aynı desen):**
  - `ProfileProvider.firstUsedAt`/`daysSinceFirstUsed()`/`addressTerm` — `firstUsedAt` İLK açılışta
    (`TrustedTimeProvider.now()` ile, cihaz saatine değil) sabitlenir ve BİR DAHA DEĞİŞMEZ;
    `addressTerm` varsayılan `'Kanka'`.
  - `GoalsProvider.longestStreak` — **"canlı seri = aktif döngünün `completedDates.length`'i" içgörüsü
    üzerine kurulu:** `_reconcileGoal` bir gün kaçırılır kaçırılmaz döngüyü ANINDA sıfırladığı için
    (bkz. "Hedef Takibi" bölümü), sıfırlanmamış bir döngüde `Goal.completedDates.length` ZATEN
    gerçek zamanlı bir "kesintisiz seri" sayacı — `toggleToday`'de her gün işaretlemede
    `max(mevcut, yeniUzunluk)` ile güncelleniyor, tam geçmişi yeniden inşa etmeye GEREK KALMADAN
    doğru, monotonik-azalmayan bir "rekor" veriyor.
  - `CoinProvider.totalEarned`/`totalSpent` — `transactions` listesinden (yalnızca en yeni 200
    kaydı tutuyor, bkz. sınıf dokümantasyonu) AYRI, hiç budanmayan, ömür boyu kalıcı iki sayaç. Bu
    alanlar eklenmeden ÖNCEki kayıtlı veri için BİR KEZLİK bir geriye dönük hesaplama yapılıyor
    (o an önbellekte duran en fazla 200 işlemden) — **bilinen sınırlama:** 200 işlemi aşan çok eski
    geçmiş bu geriye dönük hesaplamada YOK, göç anından itibaren doğru tutuluyor.
- **Bulunan gerçek test hatası — iki `MoneyProvider` örneği AYNI mock `SharedPreferences`
  deposunu paylaşıp birbirinin verisini "sızdırdı":** `profile_stats_test.dart`'ta "yüksek
  birikim oranı > yüksek harcama oranı" yönünü doğrulayan test için iki ayrı `MoneyProvider`
  (`uid` varsayılan `null`, ikisi de AYNI yerel depoya yazıyor) oluşturulmuştu — ikinci
  provider'ın kurucusu birincinin AZ ÖNCE yazdığı veriyi yükleyip her iki skorun da aynı (7.75)
  çıkmasına yol açtı. **Çözüm:** ikinci provider'dan HEMEN ÖNCE `SharedPreferences.
  setMockInitialValues({})` ile mock depo sıfırlandı — gerçek uygulamada bu senaryo hiç
  oluşmaz (asla iki `MoneyProvider` aynı anda yaşamaz), yalnızca testin kendi izolasyon
  ihtiyacıydı.
- **Test:** `profile_provider_test.dart` (isim/fotoğraf kaydı + kalıcılık + YENİ:
  `firstUsedAt`/`daysSinceFirstUsed()`/`addressTerm` kalıcılığı), `profile_stats_test.dart` (dört
  formülün yönlü doğruluğu + uç durumlar), `profile_screen_test.dart` (fotoğraf seçme/kaydetme, isim
  kaydetme, kart başlıkları/boş durum mesajları — `manifest_journal_screen_test.dart`'taki "bağımsız
  test uygulaması + sahte servis enjeksiyonu" deseniyle AYNI, artık `CoinProvider`/`CostumeProvider`/
  `FavoriteQuotesProvider`'ı da sağlıyor çünkü `ProfileScreen` "Zibo ile Bağın" bölümünde bunları
  izliyor), YENİ `address_term_test.dart` (`applyAddressTerm` saf fonksiyon testleri — büyük/küçük
  harf, varsayılan terimde no-op), YENİ `bond_level_test.dart` (`bondLevelForDays`/
  `nextBondLevelThreshold` eşik testleri), YENİ `favorite_quotes_provider_test.dart`
  (favorileme/favoriden çıkarma/sıralama/kalıcılık), `goals_provider_test.dart`'a eklenen
  `longestStreak` testleri (döngü tamamlanınca rekor artar, daha kısa bir sonraki seri düşürmez,
  kalıcılık), `coin_provider_test.dart`'a eklenen `totalEarned`/`totalSpent` testleri +
  `widget_test.dart`'a iki uçtan uca senaryo: (1) mevcut "Profil: isim yazılıp kaydedilir..." testi
  Z-menü yerine DOĞRUDAN `find.bySemanticsLabel('Profil')` bottom-tab tap'ine çevrildi (bkz.
  "Alt Gezinme Çubuğu" bölümündeki nav-swap notu), (2) YENİ "Zibo ile Bağın satırları..." senaryosu
  — kalp ikonuyla favorile → Favori Sözler'de gör → Hitap Tercihi'nde "Reis" yaz (2026
  güncellemesiyle `find.text('Reis')` radio-seçimi yerine `tester.enterText(find.byType(TextField),
  'Reis')` + `TextInputAction.done`'a çevrildi, bkz. altta) → satır güncellenir
  → Bağ Seviyesi/En Uzun Seri/Coin Özeti sayfaları açılır → Kostüm Dolabı'na dokununca Mağaza'nın
  Kostümler segmentine gider. **Gotcha (aynı kalıp üçüncü kez):** `ProfileScreen`'in kendi içindeki
  `TextField` + iç içe `IndexedStack` yüzünden `tester.scrollUntilVisible(...)`'ın `scrollable:`
  parametresi HER ZAMAN `find.descendant(of: find.byType(ProfileScreen), ...).first` ile açıkça
  daraltılmalı; ayrıca "Zibo ile Bağın" satırlarına dokunurken KOORDİNAT tabanlı `tester.tap()`
  güvenilir hit-test yapmadığı için (aynı "GridView/InkWell" gotcha'sı, bkz. "Test kalıpları"
  bölümü) satırlar `tester.widget<ListTile>(find.ancestor(...)).onTap!()` ile DOĞRUDAN çağrılıyor.
- **Gerçek cihazda doğrulama bu arc'ta YAPILAMADI** (önceki arc'ların MIUI `adb shell input tap`
  sınırlamasından FARKLI bir sebeple — bkz. "Profil" bölümünün ilk sürümündeki aynı not — bu oturumda
  ortamda `adb`'ye hiç erişim yoktu, cihaz bağlı değildi/platform-tools bulunamadı). Bunun yerine
  **tarayıcı önizlemesinde (`flutter run -d web-server`) canlı doğrulama yapıldı:** alt gezinme
  çubuğunun yeni sırası (Ana Sayfa/Hedefler/**Profil**/Mağaza), Ana Sayfa'daki kalp ikonunun
  favorileyip dolu kalbe döndüğü, Profil'deki 7 satırlı "Zibo ile Bağın" bölümünün tüm CANLI alt
  metinlerle (gün sayısı, seri rekoru, coin toplamları, hitap tercihi, favori sayısı) doğru göründüğü
  ve Hitap Tercihi sayfasının (o zamanki) 4 seçeneği doğru render ettiği ekran görüntüleriyle teyit
  edildi. **Not: Hitap Tercihi ekranı SONRADAN (2026 güncellemesi, yukarıda belgeli) 4 sabit
  seçenekten serbest metin kutusuna çevrildi** — bu paragraf yalnızca o anki tarihsel doğrulamayı
  yansıtıyor.
  **Kullanıcının kendi cihazında TAMAMLAMASI gereken:** kostüm dolabı önizleme şeridinin gerçek
  kostüm görselleriyle göründüğü, profil kartı paylaşımının native paylaşım sayfasını açtığı ve
  koyu temada tüm yeni ekranların (Bağ Seviyesi/En Uzun Seri/Coin Özeti/Hitap Tercihi/Favori Sözler)
  doğru render olduğu — kod tarafı `flutter test`'teki 183 testle (bu arc'ta eklenen ~25'i dahil)
  kapsanıyor.
- **2026 güncellemesi — "Geçmiş Ay İstatistikleri" arşivi**
  ([monthly_stats_snapshot.dart](lib/models/monthly_stats_snapshot.dart),
  [profile_stats_archive_provider.dart](lib/providers/profile_stats_archive_provider.dart),
  [monthly_stats_history_screen.dart](lib/screens/monthly_stats_history_screen.dart)). Kullanıcı
  isteği: "İstatistiklerim" bölümü her ay sonunda sıfırlansın, o ayın istatistikleri arşive
  kaydedilsin; Profil'de küçük bir "Geçmiş Ay İstatistikleri" bağlantısı olsun, tıklanınca önceki
  ayların istatistikleri ay ay listelensin.
  - **Bilinçli mimari karar — `ProfileStats.compute()`'un rolling-window formülleri HİÇ
    DEĞİŞTİRİLMEDİ.** Bu fonksiyon zaten kapsamlı test kapsamına sahip (`profile_stats_test.dart`)
    ve "canlı, o ANKİ duruma göre" hesaplanan saf bir fonksiyon — "ay sonunda sıfırlanma" kavramı
    bu mimariye doğal olarak uymuyor (kalıcı bir sayaç değil, son N gün/haftanın kayan penceresi).
    Formülleri "aya özel" kalıcı sayaçlara çevirmek hem riskli (mevcut test kapsamını bozar) hem
    de gereksiz bir karmaşıklık olurdu. Bunun yerine YENİ, tamamen AYRI bir "arşiv" katmanı eklendi:
    `ProfileStatsArchiveProvider`, `ProfileScreen` her `build()`'de hesapladığı CANLI `stats`'ı bir
    `addPostFrameCallback` ile `archiveIfMonthChanged(stats, now)`'a geçiriyor — bu metot yalnızca
    takvim ayı SON kontrolden beri DEĞİŞTİYSE bir şey yapar (aksi halde ucuz bir string
    karşılaştırmasıyla no-op), değiştiyse ÖNCEKİ ayı o anki canlı `stats` değerleriyle
    (`MonthlyStatsSnapshot`) arşivleyip yeni ayı işaretler. **`build()` sırasında `notifyListeners()`
    tetiklenmesin diye** çağrı bir sonraki kareye (`addPostFrameCallback`) ertelendi.
  - **Bilinçli yaklaşıklık:** rolling-window hesaplamanın geçmiş bir anını kalıcı tutmadığımız için,
    arşivlenen değer "geçen ayın TAM son günündeki" değer değil, "kullanıcının yeni ayda uygulamayı
    İLK açtığı anda" görülen canlı değer — pratikte neredeyse her zaman aynı gün/çok yakın bir
    yaklaşıklık. Kullanıcı bir veya daha fazla ayı hiç açmadan atlarsa yalnızca EN SON görülen ay
    arşivlenir (atlanan ara ayların verisi rolling-window'dan zaten geri getirilemez) — bu, kod
    içinde ve dokümantasyonda açıkça belirtilmiş bilinen bir sınırlama.
  - **`ProfileStatsArchiveProvider`** diğer TÜM provider'larla AYNI `CloudStateStore` Varyant A
    deseni (`profileStatsArchive` anahtarı, `{lastSeenMonthKey, snapshots: [...]}`). `hasData ==
    false` olan bir kategori arşive HİÇ girmiyor (`MonthlyStatsSnapshot.scores` map'inde o
    kategorinin anahtarı yok) — `MonthlyStatsHistoryScreen` bunu `–` ile gösteriyor
    (`ProfileScreen._openShareCard`'daki AYNI "veri yoksa tire" convansiyonu).
  - **"Geçmiş Ay İstatistikleri" satırı** İstatistiklerim kartlarının HEMEN ALTINA, "Zibo ile
    Bağın" bölüm başlığından ÖNCE eklendi (bağ/streak/coin gibi diğer satırlardan ayrı bir kavramsal
    grup olduğu için) — `_ProfileLinkRow` ile AYNI görsel dil, canlı alt metin arşivlenen ay
    sayısını gösteriyor (`{count} ay arşivlendi`).
  - **`MonthlyStatsHistoryScreen`** — `CoinSummaryScreen` ile benzer basit bir kart-listesi ekranı;
    her kart bir ayı (`localized_calendar_names.dart`'taki `monthNamesForLocale` ile yerelleştirilmiş
    ay adı + yıl) ve dört kategorinin o aydaki puanını gösterir. Arşiv boşsa teşvik/bilgi mesajı.
  - **Test:** YENİ `profile_stats_archive_provider_test.dart` (ilk çağrı arşivlemez/yalnızca temel
    ayı işaretler, aynı ay içi tekrar çağrılar no-op, ay değişince önceki ay doğru puanlarla
    arşivlenir, `hasData == false` kategori arşive girmez, birden fazla ay en-yeni-önce sıralanır,
    kalıcılık round-trip, JSON şekli) + `profile_screen_test.dart`/`widget_test.dart`'ın
    `_buildAppWithClock()` yardımcılarına `ProfileStatsArchiveProvider` eklendi (`ProfileScreen`
    artık onu da `context.watch` ettiği için, bkz. "Test kalıpları" bölümündeki genel provider
    kuralı) + `widget_test.dart`'taki "Zibo ile Bağın" senaryosuna, satır sıralamasını (yukarıdaki
    tek-yönlü `scrollUntilVisible` gotcha'sı gereği) BOZMAYACAK şekilde en başa (Bağ Seviyesi'nden
    ÖNCE) bir kontrol eklendi: taze kurulumda satır "0 ay arşivlendi" gösterir, dokununca boş durum
    mesajı görünür.
  - **Gerçek cihazda GÖRSEL doğrulama bu arc'ta YAPILMADI** (ay değişimini gerçek zamanda tetiklemek
    günler/ay gerektirir, mantığı test edilen saf/deterministik bir fonksiyon olduğu için risk
    düşük) — yalnızca `flutter test` (299/299) ile doğrulandı. **Kullanıcının ileride doğrulayabileceği
    gerçek senaryo:** cihazın tarihini bir sonraki aya ileri alıp uygulamayı açmak (bkz. CLAUDE.md
    "Firestore veri kalıcılığı" bölümündeki güvenilir zaman notu — bu ARŞİV kontrolü `TrustedTimeProvider.
    now()`'u kullanıyor, cihaz saatini değil, bu yüzden yalnızca cihaz saatini ileri almak YETMEZ,
    gerçek zamanın geçmesi VEYA test ortamında `now` enjekte edilmesi gerekir).

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

## Push Bildirimleri — FCM + GitHub Actions ([push_notification_type.dart](lib/models/push_notification_type.dart), [push_notification_provider.dart](lib/providers/push_notification_provider.dart), [push_notification_service.dart](lib/services/push_notification_service.dart), workspace kökü [notification-scripts/](../notification-scripts/) + [.github/workflows/](../.github/workflows/))

- **2026 yeni özellik — eski yerel bildirim sisteminden (bkz. "Bildirimler" bölümü, hâlâ rafta,
  `notificationsFeatureEnabled = false`) TAMAMEN BAĞIMSIZ, sunucu taraflı bir push sistemi.**
  Kullanıcı isteği dört bildirim türü: Günlük Motivasyon, Streak Hatırlatması, Günlük Ödül
  Hatırlatması, Geri Kazanma — Cloud Functions + Cloud Scheduler ile (GitHub Actions DEĞİL, zaten
  Firebase ekosistemindeyiz).
- **İstemci tarafı (Flutter) — "alma" mantığı:**
  - `PushNotificationType` enum — 4 tür, her birinin `wireValue`'su (`daily_motivation`/
    `streak_reminder`/`daily_reward`/`re_engagement`) Cloud Functions'ın gönderdiği
    `RemoteMessage.data['type']` ile birebir eşleşiyor.
  - `PushNotificationProvider` — `CloudStateStore` Varyant A (`pushNotificationState` doküman,
    4 bool tercih). **2026 güncellemesi — Ayarlar'daki "Push Bildirimleri" kartı (4 `SwitchListTile`)
    KULLANICI İSTEĞİYLE TAMAMEN KALDIRILDI** ("bu gereksiz bir ayrım" — kullanıcının kendi ifadesi;
    `settings_screen.dart`'taki `_PushNotificationSettingsCard` sınıfı SİLİNDİ, `PushNotificationProvider`/
    `PushNotificationType` importları kullanılmadığı için kaldırıldı). **Provider'ın kendisi VE
    sunucu tarafı filtreleme mantığı DOKUNULMADAN kaldı** — yalnızca kullanıcının bunu Ayarlar'dan
    tek tek kapatabildiği arayüz gitti. Bunun PRATİK SONUCU: `PushNotificationProvider`'ın 4 alanı
    da varsayılan `true` olarak kalıcı depoda takılı kalır (hiçbir kullanıcı arayüzden değiştiremez),
    yani **tüm kullanıcılar artık fiilen dört bildirim türünün TAMAMINI alır, hiçbir opt-out yolu
    YOK** (sistem düzeyinde OS'un kendi bildirim izni HARİÇ). Bu, kullanıcının açık isteğiydi ("türlere
    göre ayrı seçenek gerekmiyor" gerekçesiyle) — provider/backend kodu SİLİNMEDİ ki ileride tekrar
    bir arayüz eklenmek istenirse (ör. tek bir genel "bildirimleri kapat" anahtarı) `isEnabled`/
    `setEnabled` API'si hâlâ hazır dursun.
    Eskiden kullanıcı bir türü kapatırsa Cloud Functions/betik tarafı bunu (aşağıdaki `isTypeEnabled`
    kontrolü ile) okuyup o türü GÖNDERMİYORDU — istemci tarafında bir "bastırma" mantığı YOK,
    filtreleme SUNUCUDA; bu mekanizma HÂLÂ ÇALIŞIR durumda, yalnızca artık hiçbir kullanıcı `false`
    değerine ERİŞEMEDİĞİ için pratikte hep `true` okunuyor.
  - `PushNotificationService` (`AdService`/`NotificationService` ile AYNI gerçek+fake desen) —
    `FirebaseMessagingPushNotificationService.initialize()`: izin ister, FCM token'ı alıp
    `users/{uid}.fcmToken`/`fcmTokenUpdatedAt`'e yazar (`onTokenRefresh` ile de senkron tutar),
    `FirebaseMessaging.onMessage`/`onMessageOpenedApp`/`getInitialMessage()`'ı bağlar.
    `touchLastActive(uid)` → `users/{uid}.lastActiveAt` — Geri Kazanma fonksiyonunun "kaç gündür
    açılmadı" kontrolü için TEK veri kaynağı, `RootScreen`'in `didChangeAppLifecycleState`'inde
    (`resumed`) her öne gelişte tazeleniyor.
  - **`FirebaseMessaging.onMessage` foreground'da OS bildirimini OTOMATİK GÖSTERMEZ** — bu yüzden
    `NotificationService.showNow({title, body})` (YENİ metot, `LocalNotificationService`/
    `FakeNotificationService`'e eklendi) `PushNotificationService` tarafından çağrılıp uygulama
    açıkken gelen mesajı elle bir yerel bildirim olarak gösteriyor.
  - **`firebaseMessagingBackgroundHandler`** (top-level, `@pragma('vm:entry-point')`) `main()`'de
    `Firebase.initializeApp()`'ten HEMEN SONRA, `runApp`'tan ÖNCE kaydediliyor — gövdesi no-op
    (`notification` alanlı mesajlar OS tarafından uygulama arka plandayken/kapalıyken otomatik
    gösteriliyor, handler'ın yalnızca KAYITLI OLMASI güvenilir Android teslimatı için yeterli).
  - **Bildirime dokununca yönlendirme:** `goalsTabRequest`/`dailyRewardsPopupRequest` (YENİ,
    `homeTabRequest` ile AYNI `ValueNotifier<int>` deseni, `tab_navigation.dart`) —
    `RootScreen._handlePushNotificationTap(type)` türe göre `homeTabRequest`/`goalsTabRequest`'i
    artırıyor veya `DailyRewardsScreen` dialogunu açıyor.
  - **`RootScreen`'in `uid`'e erişimi `context.read<String?>()` ile, constructor parametresi
    DEĞİL** — bkz. `main.dart`'taki kritik `MaterialApp.home` const-kimlik notu (altta).
- **Sunucu tarafı — 2026 GÜNCELLEMESİ: Cloud Functions/Cloud Scheduler DEĞİL, GitHub Actions.**
  İlk tasarım Cloud Functions v2 (`onSchedule`) kullanıyordu, ama bu **Blaze (ücretli) plana
  geçiş gerektiriyordu** — kullanıcı şimdilik Blaze'e geçmek istemediği için mimari tamamen
  GitHub Actions cron'larına taşındı. **Firestore okuma/yazma VE FCM gönderimi Spark (ücretsiz)
  planda da tam çalışır** — yalnızca Cloud Functions/Cloud Scheduler'ın KENDİSİ Blaze
  gerektiriyordu, bu ihtiyaç artık YOK. Eski `functions/` (Cloud Functions) projesi tamamen
  SİLİNDİ, yerine workspace kökünde (`Zibo DK/`, `dijital_kanka/`'ın DIŞINDA — Cloud Functions'la
  aynı "proje bazlı" konum kararı) **`notification-scripts/`** (bağımsız Node.js betikleri) ve
  **`.github/workflows/`** (4 ayrı cron workflow'u) geldi.
  - **`notification-scripts/src/common.js`** — paylaşılan yardımcılar: `firebase-admin`'i
    `FIREBASE_SERVICE_ACCOUNT_JSON` ortam değişkenindeki (GitHub Secret'tan gelen) JSON ile
    başlatan `initAdmin()`, `fetchAllUsers()` (`users` koleksiyonunun tamamı), `isTypeEnabled
    (uid, field)` (`users/{uid}/state/pushNotificationState`'i okuyup kullanıcının o türü AÇIK
    bıraktığını doğrular — doküman/alan yoksa varsayılan `true`, istemcideki
    `PushNotificationProvider` varsayılanıyla AYNI), `sendToUser(user, type, title, body)`
    (`isTypeEnabled` kontrolünden geçerse `messaging.send(...)`, token geçersizse/eskimişse
    hatayı yutup loglar — tek kullanıcının başarısızlığı `Promise.all` batch'ini durdurmasın diye),
    `istanbulDateKey`/`istanbulMinutesOfDay` (aşağıya bakın).
  - **5 betik** (`src/dailyMotivation.js`, `src/streakReminder.js`, `src/dailyRewardReminder.js`,
    `src/reEngagement.js`, `src/waterReminder.js`) — mantık Cloud Functions taslağıyla BİREBİR AYNI,
    yalnızca "ne zaman çalıştırıldıkları" artık `onSchedule` yerine GitHub Actions `schedule:` cron'u:
    - **Günlük Motivasyon** — **2026 GÜNCELLEMESİ — GERÇEK BİR OLAYLA BULUNAN, MİMARİYİ DEĞİŞTİREN
      bir GitHub Actions kısıtlaması:** İlk tasarım, GitHub Actions cron'unun (Cloud Scheduler
      gibi) "rastgele saat" desteklememesi yüzünden, "her kullanıcıya günde 1 kez, 09:00-11:00
      arası RASTGELE bir saatte" isteğini `pickSlot(uid, dateKey, 8)` hash'iyle karşılıyordu:
      workflow 09:00-10:45 (Europe/Istanbul) arası 15 dakikada bir (`cron: '0,15,30,45 6-7 * * *'`,
      8 tetikleme) çalışıp her seferinde yalnızca o anki dilime denk gelen kullanıcılara gönderim
      yapıyordu. **Kullanıcı gerçek bir çalıştırmadan sonra bildirim gelmediğini bildirdi — GitHub
      Actions'ın run geçmişi incelenince şu bulundu:** o gün planlanan 8 tetiklemeden GitHub
      yalnızca **1'ini** gerçekleştirdi, o da **22 dakika GECİKMEYLE** (`minutesOfDay=667` yani
      11:07 Istanbul, 09:00-10:45 penceresinin TAMAMEN DIŞINDA) — script'in kendi pencere
      koruması bu geç çalıştırmayı görüp `"Pencere dışı (minutesOfDay=667), gönderim yapılmadı."`
      diyerek HİÇBİR kullanıcıya gönderim yapmadan sessizce sonlandı (log, `GET /repos/{owner}/
      {repo}/actions/jobs/{job_id}/logs` API'siyle doğrulandı). **Kök neden — GitHub'ın kendi
      dokümantasyonu:** "The schedule event can be delayed during periods of high loads... High
      load times include the start of every hour" — cron'umuzun kullandığı `:00/:15/:30/:45`
      dakikaları TAM OLARAK GitHub'ın "yoğun" dediği anlar, ve saatte birden fazla (8 kez/2 saat)
      sık bir cron bu yoğunlukta GÜVENİLİR ÇALIŞMIYOR (7/8 tetikleme hiç gerçekleşmedi).
      **Düzeltme — mimari basitleştirildi:** `pickSlot` TAMAMEN kaldırıldı (`common.js`'den de
      silindi); GÜNDE TEK bir tetikleme kondu, `cron: '7 6 * * *'` (09:07 Europe/Istanbul) —
      dakika BİLEREK `:07` (GitHub'ın "yoğun" dediği dakikaların DIŞINDA). Betik TÜM
      kullanıcılara AYNI çalıştırmada, AYNI rastgele seçilmiş sözle gönderiyor (kullanıcıya göre
      FARKLI dakika nüansı feda edildi) — sıkı 15dk'lık pencere kontrolü de kaldırılıp yerine
      yalnızca GitHub'ın çalıştırmayı KATASTROFİK derecede geç tetiklemesine karşı geniş bir
      güvenlik ağı (`SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE`, `dailyMotivation.js`) kondu. **Ders
      — genel kural bu betiklerin HEPSİNE uygulandı:** GitHub Actions cron'larında dakika alanı
      olarak ASLA `:00/:15/:30/:45` kullanmayın, bunun yerine `:07` gibi sıra dışı bir dakika
      seçin — sıklık değil, DAKİKA SEÇİMİ asıl risk faktörü.
      - **2026 İKİNCİ güncelleme — kullanıcı isteğiyle günde 1 → 4 tetiklemeye çıkarıldı.**
        Kullanıcı raporu: sabah 11'de gelen tek motivasyon sözü yetersiz geldi, günde 3-4 kez
        istendi. Yukarıdaki dersten (SIKLIK değil DAKİKA SEÇİMİ asıl risk) hareketle, `pickSlot`
        tarzı "kullanıcıya göre farklı dakika" karmaşıklığına GERİ DÖNÜLMEDİ — bunun yerine DÖRT
        BAĞIMSIZ, birbirinden habersiz basit çalıştırma eklendi, HER BİRİ kendi sabit ve
        yoğun-olmayan dakikasında: `7 6 * * *` (09:07), `22 9 * * *` (12:22), `37 13 * * *`
        (16:37), `52 17 * * *` (20:52) — hepsi Europe/Istanbul. Her çalıştırma TÜM kullanıcılara
        kendi rastgele seçtiği sözle gönderiyor, yani bir kullanıcı günde 4 FARKLI söz alıyor.
        `SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE` de dört tetiklemenin hepsini kapsayacak şekilde
        07:00-23:00'e genişletildi (eskiden yalnızca 07:00-13:00'ü kapsıyordu, tek tetikleme
        olduğu için yeterliydi).
    - **Streak Hatırlatması** — `7 17 * * *` (UTC) ≈ 20:00 Istanbul. `users/{uid}/state/goals`'u
      okuyup en az bir hedefin bugün işaretlenmediğini kontrol ediyor; hiç hedef yoksa göndermiyor.
    - **Günlük Ödül Hatırlatması** — `7 12 * * *` (UTC) ≈ 15:00 Istanbul. **BİLİNEN SINIRLAMA
      (kullanıcıya açıkça belirtildi):** Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
      mi" alanı YOK (bkz. "Şans Çarkı" bölümü), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
      claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.
    - **Su Hatırlatması (2026 yeni özellik)** — `7 13 * * *` (UTC) ≈ 16:07 Istanbul.
      `users/{uid}/state/waterState`'i (bkz. `water_provider.dart`) okuyup bugüne ait bir `entries`
      kaydı YOKSA (hiç başlanmamış) veya varsa ama `unitCount < goalUnitCount`'sa (yarım kalmış)
      gönderiyor; `waterState` dokümanı hiç yoksa (kullanıcı su takibini hiç kullanmamışsa)
      `streakReminder.js`'in "hiç hedef yoksa gönderme" deseniyle AYNI gerekçeyle HİÇ göndermiyor
      (kullanılmayan bir özelliği push ile "reklamını yapmak" yerine yalnızca zaten kullanan
      kullanıcılara hatırlatma). Mesaj: "Suyunu içtin mi kanka? Hemen bir bardak iç, hedefine bir
      adım daha yaklaş! 💧" (TR/EN/ES, `content.js`).
    - **Geri Kazanma** — `7 8 * * *` (UTC) ≈ 11:00 Istanbul. `users/{uid}.lastActiveAt` 2 günden
      eski olan kullanıcılara gönderiyor.
    - GitHub Actions cron'ları HER ZAMAN UTC'dir — Europe/Istanbul (sabit UTC+3) karşılıkları her
      workflow dosyasının yorumunda AÇIKÇA yazılı, ileride saat değiştirmek isteyen biri yeniden
      hesaplamak zorunda kalmasın diye.
    - **GitHub Actions run/job loglarını sorgulama tarifi (bu bulguyu çıkarmak için kullanıldı,
      `gh` CLI bu ortamda YOK):** `git credential fill` ile (zaten `git push` için depolanmış)
      GitHub token'ını alıp `curl -H "Authorization: token $TOKEN"` ile REST API'ye istek atmak —
      `GET /repos/{owner}/{repo}/actions/workflows/{id}/runs` (run listesi + `created_at`) →
      `GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs` (job id) → `GET /repos/{owner}/{repo}/
      actions/jobs/{job_id}/logs` (ham log metni). Token asla ekrana yazdırılmadan tek bir
      alt-shell içinde `eval "$(... | sed -n 's/^password=/GH_TOKEN=/p')"` ile ortam değişkenine
      alınıp kullanıldı.
  - **`.github/workflows/*.yml`** (4 dosya) — her biri `schedule:` (cron) + `workflow_dispatch:`
    (elle manuel tetikleme, ilk kurulum testinde kullanılacak) tetikleyicisiyle: `actions/checkout`
    → `actions/setup-node@v4` (Node 20) → `npm install` (`notification-scripts/` içinde,
    `working-directory` ile) → ilgili `npm run <script>` komutu, `FIREBASE_SERVICE_ACCOUNT_JSON`
    GitHub Secret'ını ortam değişkeni olarak geçirerek.
  - **Bu ortamda Node.js/npm/GitHub CLI YOK** — betikler dikkatle elle yazıldı ama YEREL OLARAK
    ÇALIŞTIRILIP TEST EDİLEMEDİ. `workflow_dispatch` sayesinde kullanıcı ilk kurulumdan sonra her
    workflow'u GitHub Actions sekmesinden ELLE bir kez tetikleyip loglardan doğrulayabilir (bkz.
    altta "Kullanıcının tamamlaması gereken adımlar").
- **2026 GÜNCELLEMESİ — bildirimler artık kullanıcının arayüz diline göre gönderiliyor (TR/EN/ES),
  eskiden HER ZAMAN Türkçe gidiyordu.** Kullanıcı raporu (verbatim özet): "admoba geçmeden önce
  bildirimler sadece Türkçe gidiyor, yabancı biri (ör. İspanyolca) kullanıyorsa bildirimler de o
  dilde gitmeli." İnceleme sonucu kök neden doğrulandı: `dailyMotivation.js` TEK bir Türkçe
  `MOTIVATION_QUOTES` dizisinden TÜM kullanıcılara aynı sözü gönderiyordu, `streakReminder.js`/
  `dailyRewardReminder.js`/`reEngagement.js` üçü de `sendToUser(...)`'a doğrudan sabit bir Türkçe
  string literal geçiriyordu — DÖRDÜNDE de hiçbir dil-farkındalığı YOKTU.
  - **`common.js`'e YENİ `getLanguageCode(uid)` eklendi** — istemcideki `LocaleProvider`'ın AYNI
    şemasını okuyor (`users/{uid}/state/languageCode` dokümanı, `value` alanı,
    `['tr','en','es']` dışında/eksik/hatalıysa varsayılan `'tr'` — istemcinin kendi varsayılanıyla
    BİREBİR aynı). `db` çağrısı `isTypeEnabled`'daki AYNI desende try/catch'e sarılı — Firestore
    hatası/ağ sorunu olursa sessizce `'tr'`'ye düşer, tüm çalıştırmayı bozmaz.
  - **YENİ `notification-scripts/src/content.js`** — 4 türün TR/EN/ES içeriğini TEK yerde
    toplayan bir modül (Günlük Motivasyon: 8'er söz/dil; diğer üçü: tek body string/dil).
    Çeviriler `lib/data/zibo_messages.dart`'taki AYNI felsefeyle (birebir çeviri değil, Zibo'nun
    sıcak tonu o dilde doğal duracak şekilde uyarlama — TR "Kanka"/EN "Buddy"/ES "Amigo")
    yazıldı. Üç dil de Günlük Motivasyon'da BİREBİR aynı sayıda (8) söz içeriyor.
  - **4 betiğin HEPSİ** artık `sendToUser(...)`'ı çağırmadan ÖNCE ilgili kullanıcı(lar) için
    `getLanguageCode(uid)`'i çözüp `content.js`'teki doğru dildeki metni seçiyor —
    `dailyMotivation.js`'de bu, ESKİDEN "tüm kullanıcılara aynı çalıştırmada aynı rastgele söz"
    olan tasarımı "her kullanıcı KENDİ dilinde, kendi rastgele sözünü alır" hâline getirdi (hâlâ
    aynı çalıştırmada, `Promise.all` ile paralel); diğer üçünde zaten per-user bir döngü/filtre
    olduğu için yalnızca `sendToUser` çağrısından hemen önce bir `getLanguageCode` eklemek yeterli
    oldu.
  - **Bu ortamda Node.js YOK, betikler yalnızca dikkatli kod incelemesiyle doğrulandı** (aynı
    "yerel olarak çalıştırılamıyor" sınırlaması, bkz. yukarı) — kullanıcının GitHub Actions'tan
    `workflow_dispatch` ile elle tetikleyip (ideal olarak EN/ES `languageCode`'lu bir test
    kullanıcısıyla) doğrulaması gerekiyor.
- **2026 ÜÇÜNCÜ güncelleme — bildirimler artık kullanıcının KENDİ saat dilimine göre gönderiliyor,
  eskiden HEPSİ sabit Europe/Istanbul saatine göre gidiyordu.** Kullanıcı raporu: Kolombiya'da
  (testerscommunity.com üzerinden bulunan) bir test kullanıcısı, günlük motivasyon bildirimini
  yerel saatiyle sabah 4'te aldığını bildirdi — kök neden buydu, kullanıcının GERÇEK konumu/saat
  dilimi hiçbir zaman dikkate alınmıyordu.
  - **İstemci tarafı — `PushNotificationService.touchLastActive(uid)`** (zaten `RootScreen`'in her
    açılışında/`AppLifecycleState.resumed`'da çağırdığı, `lastActiveAt`'i güncelleyen metot) artık
    AYRICA cihazın GÜNCEL IANA saat dilimini (`flutter_timezone` paketi, `FlutterTimezone.
    getLocalTimezone().identifier` — ör. `America/Bogota`) okuyup `users/{uid}.timeZone` alanına
    yazıyor. Saat dilimi okuması AYRI bir try/catch'te — bu adım başarısız olsa bile (desteklenmeyen
    platform vb.) `lastActiveAt` güncellemesi ("Geri Kazanma" bildiriminin TEK veri kaynağı)
    ETKİLENMİYOR. Ayrı bir yazım turu/mekanizma GEREKMEDİ — mevcut "her resume'da tazele" çağrısına
    tek bir alan eklendi, bu da kullanıcı SEYAHAT ettiğinde bile saat diliminin makul bir sıklıkla
    güncel kalmasını sağlıyor.
  - **Sunucu tarafı — `notification-scripts/src/common.js`'e İKİ yeni yardımcı eklendi:**
    `userLocalHour(user, date)` (kullanıcının KENDİ yerel saatindeki saat değeri, 0-23) ve
    `userDateKey(user, date)` (kullanıcının KENDİ yerel takvim günü, `YYYY-MM-DD`) — ikisi de
    Node'un YERLEŞİK `Intl.DateTimeFormat` desteğiyle IANA saat dilimi isimlerini kullanıyor (ek bir
    npm paketi GEREKMEDİ), bu da yaz/kış saatini (DST) otomatik doğru hesaplıyor. `users/{uid}.
    timeZone` alanı YOKSA (eski uygulama sürümü, henüz güncellemeyen kullanıcı) VEYA geçersiz bir
    IANA ismiyse `Europe/Istanbul`'a düşülüyor — 2026 güncellemesinden ÖNCEki davranışla TUTARLI bir
    geri düşüş, kimse "kırılmıyor". Eski `istanbulDateKey`/`istanbulMinutesOfDay` (yalnızca sabit
    Istanbul saatine göre hesaplayan) fonksiyonları, tüm kullanım yerleri değiştirildikten sonra
    TAMAMEN kaldırıldı — artık hiçbir yerde kullanılmıyorlardı.
  - **Mimari değişiklik — 5 betiğin HEPSİ "sabit Istanbul saatinde bir kez çalış, herkese gönder"
    yerine "SAATTE BİR çalış, yalnızca KENDİ yerel saati hedefe denk gelen kullanıcılara gönder"
    modeline geçti:**
    - `dailyMotivation.js`: `TARGET_LOCAL_HOURS = [9, 12, 16, 20]` (eski dört sabit Istanbul
      saatiyle AYNI ruh, artık HERKESİN KENDİ 9/12/16/20'sinde). Eski `SAFETY_MIN_MINUTE`/
      `SAFETY_MAX_MINUTE` güvenlik penceresi TAMAMEN kaldırıldı — YENİ tasarım zaten yalnızca
      kullanıcının hesaplanan yerel saati hedefe denk geldiğinde gönderim yaptığı için o güvenlik
      ağına gerek kalmadı ("yanlış saatte gönderim" riski tasarım gereği yok).
    - `streakReminder.js` (`TARGET_LOCAL_HOURS = [20]`), `dailyRewardReminder.js`
      (`= [15]`), `waterReminder.js` (`= [16]`) — üçü de HEM saat filtresini HEM "bugün" tanımını
      (`istanbulDateKey` yerine `userDateKey`) kullanıcının yerel saat dilimine göre hesaplıyor;
      Firestore alt-doküman okuması (goals/dailyRewards/waterState) yalnızca saat filtresini
      GEÇEN kullanıcılar için yapılıyor (gereksiz okuma maliyetini önlemek için filtre ÖNCE).
    - `reEngagement.js` (`TARGET_LOCAL_HOURS = [11]`) — "2 gündür açılmadı mı" kontrolü zaten ham
      milisaniye farkına dayandığı için saat dilimi bağımsızdı, DEĞİŞMEDİ; yalnızca gönderim ANI
      artık kullanıcının yerel saatine göre.
  - **`.github/workflows/*.yml` (4 dosya, `cleanup-stale-anonymous-users.yml` HARİÇ) — cron'lar
    GÜNDE BİR/DÖRT sabit tetiklemeden SAATTE BİR'e çevrildi**, her biri KENDİ sabit, yoğun-olmayan
    dakikasında (GitHub'ın `:00/:15/:30/:45`'i "yoğun" işaretlediği, gerçek bir olayla doğrulanmış
    gecikme riski — bkz. `daily-motivation.yml`'deki tarihsel not — bu yüzden her workflow farklı
    ve yuvarlak olmayan bir dakika kullanıyor, hem GitHub'ın yoğun dakikalarından kaçınmak hem
    4 workflow'un aynı anda çakışmaması için): `daily-motivation` `:07`, `streak-reminder` `:14`,
    `daily-reward-reminder` `:21`, `re-engagement` `:42`, `water-reminder` `:49`.
  - **Bilinçli ölçek/maliyet notu (şimdilik sorun DEĞİL, ileride revize edilebilir):** saatlik
    çalıştırma, `fetchAllUsers()`'ın (tüm `users` koleksiyonunu okuyan) çağrı sıklığını ~9 kat
    artırdı (günde ~9 çalıştırmadan 5×24=120 çalıştırmaya). Küçük bir kapalı test kullanıcı
    tabanında (birkaç düzine kişi) bu, Firestore'un Spark (ücretsiz) plan kotasının (günde 50.000
    okuma) çok altında kalıyor — ama kullanıcı sayısı ileride binlere çıkarsa (ör. 1000+ kullanıcı)
    bu tasarım günde 100.000+ okumaya çıkıp ücretsiz kotayı aşabilir. O noktaya gelinirse çözüm:
    her kullanıcının "hedef saat kovası"nı (ör. `timeZone`'dan türetilen bir UTC-saat ofseti)
    Firestore'da AYRI bir alan olarak SAKLAYIP, sorguyu `where('targetHourBucket', '==', currentUtcHour)`
    gibi bir Firestore sorgusuna çevirmek (tüm koleksiyonu her seferinde ÇEKMEK yerine yalnızca o
    anki kovaya denk gelenleri sorgulamak) — şimdilik bu optimizasyon YAPILMADI, "bilinçli
    basitleştirme" (mevcut ölçekte gereksiz karmaşıklık).
  - **Bu ortamda Node.js YOK, betikler (aynı yukarıdaki sınırlama) yalnızca dikkatli kod
    incelemesiyle doğrulandı, `flutter test` (299/299) ile Flutter tarafının derlendiği/geçtiği
    doğrulandı.** Kullanıcının GitHub Actions'tan `workflow_dispatch` ile elle tetikleyip (ideal
    olarak farklı `timeZone` değerlerine sahip birkaç test kullanıcısıyla) doğrulaması gerekiyor —
    özellikle Kolombiya'daki test kullanıcısının bir sonraki bildirimi artık KENDİ yerel saatinde
    (gece yarısı/sabaha karşı DEĞİL) aldığını teyit etmek.
  - **Yeni versiyon gerektiren kısım YALNIZCA istemci tarafı** (`touchLastActive`'in `timeZone`
    yazması) — sunucu tarafı (`notification-scripts`/`.github/workflows`) değişiklikleri repoya
    push edilir edilmez, kullanıcı hiçbir şey yapmadan devreye girer. Eski uygulama sürümündeki
    (henüz güncellemeyen) kullanıcılar `timeZone` alanı yazmadığı için Europe/Istanbul'a düşer —
    yani KIRILMIYORLAR, yalnızca güncelleyene kadar eski (sabit Istanbul saatli) davranışı
    görmeye devam ediyorlar.
- **2026 DÖRDÜNCÜ güncelleme — saat-dilimi dağıtımından SONRA bildirimler 33+ saat boyunca
  TAMAMEN durdu, "catch-up" penceresine geçilerek düzeltildi.** Kullanıcı raporu: yukarıdaki
  saat-dilimi güncellemesinden beri hiçbir bildirim gelmiyordu, GitHub'dan manuel tetiklemek de
  hiçbir şey göndermiyordu. `gh run list`/`gh run view --log` ile canlı teşhis edildi:
  - **Kanıt — kesin bir ÖNCE/SONRA sınırı bulundu.** Son başarılı gönderim 2026-08-25 19:20 UTC'de
    (`daily_motivation`, 16 kullanıcıya) gerçekleşmişti; saat-dilimi commit'i (`9071c82`) TAM
    2026-08-25 21:54 UTC'de deploy edildi; o andan itibaren — kullanıcının manuel tetiklemesi DAHİL
    — TÜM betiklerin TÜM çalıştırmaları (5 betik × onlarca çalıştırma, 33+ saat) istisnasız
    `"N kullanıcıdan 0'i şu an hedef yerel saatte"` diye loglandı. Bu net zaman sınırı, saat-dilimi
    değişikliğinin kendisini kesin şüpheli yaptı.
  - **Kök neden — "TAM o saat mi?" kontrolü GitHub Actions'ın kendi cron güvenilirliğine karşı
    çok kırılgandı.** `.github/workflows/*.yml`'in cron'ları GERÇEKTEN saatlik (`'7 * * * *'` vb.)
    olsa da, GERÇEK çalıştırma zaman damgaları incelenince GitHub'ın bu tetiklemelerin ÇOĞUNU
    (bazen 2-4+ saatlik boşluklarla) GECİKTİRDİĞİ/hiç ateşlemediği görüldü — bu, projede DAHA
    ÖNCE de karşılaşılmış, GitHub'ın kendi dokümantasyonunda kabul edilen bir sınırlama (bkz.
    yukarıdaki "Günlük Motivasyon" bölümündeki ilk `pickSlot` deneyiminin dersi), ama SAATLİK + 5
    AYRI workflow'a geçişle (eskiden günde birkaç sabit tetikleme) yük ÇOK artıp gecikme/atlama
    çok daha SIK hale geldi. Eski tasarım `userLocalHour(u, now) === TARGET`'in TAM O DAKİKADA
    yakalanmasını gerektiriyordu — bir tetikleme gecikir/atlanırsa, o kullanıcının o günkü dilimi
    BİR DAHA HİÇ yakalanamıyordu (ertesi gün `now` ilerleyip hedef saat GERİDE kalana kadar) —
    GitHub'ın gecikme sıklığı göz önüne alınca bu, PRATİKTE neredeyse HİÇBİR gönderimin
    gerçekleşmemesine yol açtı.
  - **Düzeltme — `common.js`'e `pendingNotifyHours`/`markNotifyHoursSent` eklendi, TÜM 5 betik
    bunu kullanacak şekilde güncellendi.** Kontrol artık "şu an TAM hedef saat mi?" DEĞİL, "hedef
    saat(ler) GEÇTİ mi VE bugün bu tür için henüz `users/{uid}.notifyState[type]` = `{dateKey,
    sentHours}`'a işlenmedi mi?" — `fetchAllUsers()` zaten TÜM kullanıcı dokümanını çektiği için bu
    EK bir Firestore okuması GEREKTİRMİYOR. Gecikmiş/atlanmış bir tetikleme artık GÜN İÇİNDE
    SONRAKİ (gecikmeli de olsa) herhangi bir çalıştırmada hâlâ doğru şekilde yakalanıyor. Hem
    GERÇEKTEN gönderim yapıldığında HEM DE altta yatan koşul zaten karşılandığı için (hedef zaten
    işaretli, su hedefi zaten tamamlanmış vb.) gönderim BİLİNÇLİ olarak atlandığında
    `markNotifyHoursSent` çağrılıyor — ikisi de "bu dilim bugün için değerlendirildi" anlamına
    gelir, aksi halde aynı günün SONRAKİ bir çalıştırmasında (koşul o sırada değişmiş olabileceği
    için) aynı kullanıcıya birden fazla bildirim gitme riski doğardı. **Günlük Motivasyon'un DÖRT
    hedef saati** için: birden fazla dilim BİRDEN aynı çalıştırmada "geçmiş" bulunursa (uzun bir
    GitHub gecikmesi/atlaması sonucu) kullanıcıya TEK bir (spam olmayan) bildirim gidip TÜM geçmiş
    dilimler birlikte "işlendi" işaretleniyor — 4 ayrı bildirim yerine bir "yakalama" bildirimi.
  - **Doğrulanamadı (bu ortamda Node.js yok, bkz. bölümün genelindeki AYNI sınırlama)** — kod
    yalnızca dikkatli inceleme + yukarıdaki kanıt zinciriyle doğrulandı. **Kullanıcının doğrulaması
    gereken:** bir sonraki GitHub Actions çalıştırmasından (otomatik veya `workflow_dispatch` ile
    manuel) sonra loglarda `"Gönderildi: uid=..."` satırlarının tekrar görünmesi VE gerçek cihazda
    bir bildirimin gelmesi.
- **2026 BEŞİNCİ güncelleme — üç bağımsız gerçek kullanıcı raporu birlikte incelendi ve düzeltildi:
  "bildirimler 3 kez birden ve düzensiz geliyor", "bildirimlerde hep aynı motivasyon cümleleri
  tekrar ediyor", "günlük Zibo Coin ödülü 1. günde takılı kalıyor".** Üçü de kanıta dayalı ayrı ayrı
  araştırıldı (kör tahminle düzeltmeye başlanmadı) — kökleri BİRBİRİNDEN TAMAMEN BAĞIMSIZ çıktı:
  1. **"3 bildirim birden" — KÖK NEDEN: 5 bildirim türünün `TARGET_LOCAL_HOURS`'ları arasında
     ÇAKIŞMA, tekrarlayan/çift tetikleyici DEĞİL.** `gh run list`/`gh run view --log` ile
     onlarca çalıştırma incelendi — GitHub Actions'ın saatlik cron'ları GÜVENİLİR şekilde
     ateşleniyordu (önceki "33+ saat tamamen durdu" olayından farklı olarak) VE `pendingNotifyHours`/
     `markNotifyHoursSent` catch-up penceresi (bkz. yukarıdaki DÖRDÜNCÜ güncelleme) tek bir türün
     kendi içinde çift gönderim yapmasını zaten doğru şekilde engelliyordu — sorun tekilleştirme
     DEĞİL, ZAMANLAMA tasarımıydı: eski hedef saatler `dailyMotivation=[9,12,16,20]`,
     `waterReminder=[16]` (dailyMotivation'ın 16'sıyla TAM çakışıyordu),
     `dailyRewardReminder=[15]` (16'ya yalnızca 1 saat mesafede), `streakReminder=[20]`
     (dailyMotivation'ın 20'siyle TAM çakışıyordu) idi — bir kullanıcı 15:XX-16:XX arası ödül +
     motivasyon + su (ÜÇ bildirim, ~60-90 dakika içinde) ve 20:XX'te motivasyon + streak (İKİ
     bildirim, AYNI saatte) alabiliyordu. **Düzeltme — saatler yeniden dağıtıldı, hiçbir türün
     GÜNLÜK SIKLIĞI azaltılmadı** (dailyMotivation'ın 4x/gün'ü ÖNCEKİ bir kullanıcı isteğiydi,
     geri alınmadı — yalnızca ÇAKIŞMA giderildi): `waterReminder` `16→14` (dailyMotivation'ın 12 ve
     16 dilimlerinin tam ortası), `dailyRewardReminder` `15→18` (dailyMotivation'ın 16 ve 20
     dilimlerinin tam ortası), `streakReminder` `20→21` (dailyMotivation'ın son diliminden yalnızca
     1 saat sonra — TAM çakışmadan çok daha iyi, ayrıca "gün bitmeden son şans" anlamına da daha
     uygun düştü). `reEngagement=[11]` DEĞİŞTİRİLMEDİ (hiçbir türle TAM çakışmıyordu, kapsam dışı
     bırakıldı — gereksiz risk eklemeden minimal müdahale). **Yeni tam program (yerel saat):**
     `9, 11, 12, 14, 16, 18, 20, 21` — en dar boşluk artık 1 saat (11-12, 20-21), eskiden 0 saat
     (tam çakışma) olan İKİ nokta tamamen giderildi. `.github/workflows/{streak-reminder,
     daily-reward-reminder,water-reminder}.yml`'in dokümantasyon yorumları da yeni saatlere göre
     güncellendi (cron'un kendisi zaten saatlik, `TARGET_LOCAL_HOURS` filtrelemesi JS tarafında).
  2. **"Hep aynı sözler tekrar ediyor" — KÖK NEDEN DOĞRULANDI (bkz. "content.js" dosyasının kendi
     eski yorumu): `notification-scripts/src/content.js`'in `daily_motivation` havuzu YALNIZCA
     8 söz/dil içeriyordu, Ana Sayfa'nın KENDİSİNİN kullandığı `lib/data/zibo_messages.dart`'taki
     TAM 279'luk havuzla senkron DEĞİLDİ** ("küçük temsili bir alt küme kullanılıyor" diye dosyanın
     kendi yorumunda bilerek işaretlenmiş bir basitleştirmeydi). Günde 4 kez 8 sözlük bir havuzdan
     rastgele seçim yapınca birkaç gün içinde kaçınılmaz tekrar oluyordu. **Düzeltme — İKİ AYRI
     katman:**
     - **`tool/generate_content_js_daily_motivation.dart` (YENİ, tekrar çalıştırılabilir betik)**
       — `lib/data/zibo_messages.dart`'ı DOĞRUDAN import ETMEDEN (o dosya `package:flutter/
       material.dart` import ediyor, plain `dart run` Flutter framework'ünü çözemeyip çöküyordu —
       ilk denemede yakalandı) kaynağı düz metin olarak okuyup `const ziboMessagesXx =
       <String>[...]` bloklarını satır-satır ayrıştırıyor (tek/çift tırnaklı Dart string
       literallerini, aralardaki dokümantasyon yorumlarını atlayarak) ve `jsonEncode` ile
       (JSON string literalleri her zaman geçerli JS string literalleridir) hatasız bir JS çıktısı
       üretiyor — 837 satırı (279×3 dil) ELLE kopyalamak yerine. **Gotcha (yakalanıp düzeltildi):**
       ilk sürüm çift-tırnaklı satırlardaki `\"` iç-tırnak kaçışlarını unescape ETMİYORDU (`Say one
       \\\"no\\\" today...` gibi ÇİFT kaçışlı, geçersiz bir çıktı üretiyordu) — genel bir `\X → X`
       unescape'e (hem `\'` hem `\"` için) geçilerek düzeltildi, iki dedicated regex yerine.
       `content.js`'in `daily_motivation` bloğu artık bu betiğin ÜRETTİĞİ, `lib/data/
       zibo_messages.dart` ile BİREBİR senkron TR/EN/ES 279'ar sözden oluşuyor.
     - **"En azından son birkaç günde kullanılmamış" garantisi (kullanıcının AÇIKÇA istediği
       ikinci gereksinim)** — `dailyMotivation.js`'e `pickQuoteAvoidingRecent(quotes,
       recentIndices)` eklendi: `users/{uid}.notifyState.daily_motivation.recentQuoteIndices`
       (kalıcı, en fazla `RECENT_QUOTE_MEMORY=20` elemanlı bir dizi — günde 4 gönderimle ~5 günlük
       tekrarsızlık penceresi) son gönderilen söz INDEX'lerini tutuyor, yeni seçim bu indexleri
       HARİÇ TUTARAK yapılıyor (279'luk havuzda hepsi hariç tutulacak kadar dolması pratikte
       imkansız, yine de bir güvenlik ağı olarak havuz tükenirse TÜM havuza geri düşülüyor). Bu
       index dizisi DİLDEN BAĞIMSIZ — TR/EN/ES havuzları AYNI sırada/anlamda hizalı olduğu için
       (`content.js`'in kendi yorumu) kullanıcı dil değiştirse bile aynı kavramsal söz kısa sürede
       tekrar gelmiyor. `markNotifyHoursSent` (paylaşılan, 5 betiğin HEPSİNİN kullandığı) SÖZLEŞMESİ
       DEĞİŞTİRİLMEDİ — `recordQuoteIndex` AYRI, küçük bir `db.set(..., {merge:true})` çağrısı
       (Firestore'un nested map alanlarını `merge:true` ile REKÜRSİF birleştirdiği doğrulandı, bu
       yüzden iki ayrı `set` çağrısı `notifyState.daily_motivation` altında `dateKey`/`sentHours`/
       `recentQuoteIndices` üçünü de kaybetmeden bir araya geliyor).
     - **Doğrulandı (2026-08-29) — `content.js`'in söz dizimi ÖNCE elle + brace/parantez
       sayımıyla, SONRA GERÇEK bir GitHub Actions çalıştırmasıyla doğrulandı.**
       `daily-motivation.yml` `gh workflow run` ile elle tetiklendi, log şunu gösterdi:
       `"39 kullanıcıdan 1'i şu an hedef yerel saatte... — günlük motivasyon gönderiliyor."`
       ardından `"Gönderildi: uid=... type=daily_motivation"` — betik HİÇBİR JS söz dizimi/çalışma
       zamanı hatası fırlatmadan çalıştı (279 satırlık `content.js` bloğu VE `pickQuoteAvoidingRecent`
       ikisi de gerçekte hatasız çözüldü). **Hâlâ kullanıcının doğrulaması gereken:** birkaç gün
       gerçek kullanımda aynı sözün ardı ardına gelmediğini (yeni 279'luk havuz + tekrar-önleme
       penceresi sayesinde) gözlemlemek — bu, YALNIZCA zaman geçtikçe gözlemlenebilecek bir
       davranış, tek bir çalıştırmayla kanıtlanamaz.
  3. **"Günlük ödül 1. günde takılı kalıyor" — KÖK NEDEN: `TrustedTimeProvider`'da cross-session
     staleness, `DailyRewardsProvider`'ın KENDİSİNDE DEĞİL.** `daily_rewards_provider.dart`
     (`reconcileForToday`/`claimToday`/`todayIndex`) incelendi — bu dosyanın ÖNCEKİ bir oturumda
     tam olarak bu semptom için düzeltilmiş `idx < 0` mantığı hâlâ doğru duruyordu, provider
     KENDİ İÇİNDE bir bug barındırmıyordu. Şüphe `TrustedTimeProvider.now()`'a kaydı — sınıfın
     KENDİ dokümantasyonu "ilk doğrulama HİÇ TAMAMLANMADAN cihaz saatine GEÇİCİ olarak düşülür"
     diyordu, ama KOD bunu UYGULAMIYORDU: `_loadFromPrefs()` kalıcı depodan (ÖNCEKİ bir oturumdan,
     saatler/günler eski olabilecek) bir `_lastVerifiedUtc` yüklediği ANDA, `now()` bunu SANKİ BU
     OTURUMDA taze doğrulanmış gibi (`verified + _stopwatch.elapsed`, `_stopwatch` BU oturumun
     başında sıfırdan başlamış olsa BİLE) kullanmaya başlıyordu — "kalıcı depodan bir değer okundu"
     ile "BU oturumda gerçekten doğrulandı" birbirine KARIŞTIRILMIŞTI. Eğer bir cihazda/oturumda ağ
     senkronizasyonu TUTARLI şekilde başarısız olursa (ör. soğuk başlangıçta henüz bağlanmamış
     Wi-Fi/mobil veri — MIUI'nin agresif ağ kısıtlaması bu projede DAHA ÖNCE de karşılaşılan bilinen
     bir sorun, bkz. "Bildirimler" bölümündeki arka plan teslimat notu), `now()` GÜNLERCE
     dondurulmuş eski bir tarihte kalabiliyordu — her gün uygulama açıldığında "bugün" hep AYNI
     (eski) günü gösterip `todayIndex`'in ASLA ilerlememesine yol açıyordu; kullanıcının GERÇEKTEN
     force-close edip her gün soğuk başlangıç yaptığı bir kullanım deseninde bu GÜNLÜK olarak
     tekrarlanabilirdi. **Düzeltme:** `TrustedTimeProvider`'a `_verifiedThisSession` (bool) eklendi
     — `now()` artık yalnızca BU OTURUMDA gerçekten bir ağ doğrulaması TAMAMLANDIYSA `verified +
     _stopwatch.elapsed` kullanıyor; kalıcı depodan yüklenmiş ama BU oturumda henüz tazelenmemiş
     bir değer varken (`hasVerifiedTime` `true` dönse BİLE geçerli bir durum) `now()` güvenle cihaz
     saatine düşüyor — TAM OLARAK sınıfın zaten VAAT ETTİĞİ (ama kodun uygulamadığı) davranış.
     Güvenlik özelliği (bir doğrulama BU oturumda tamamlandıktan sonra cihaz saati bir daha ASLA
     danışılmaz — kullanıcı saati manuel ileri/geri alarak günlük ödülleri tekrar tetikleyemez)
     KORUNUYOR, yalnızca cross-session staleness kapatıldı.
     - **Test:** YENİ `test/trusted_time_provider_test.dart` (5 test) — özellikle "KRİTİK" testi bu
       TAM senaryoyu simüle ediyor (kalıcı depoda yıllar eski bir doğrulama + bu oturumda ağ
       senkronu BAŞARISIZ → `now()` eski/dondurulmuş tarihi DEĞİL, gerçek cihaz saatini döndürmeli)
       — bu test DÜZELTMEDEN ÖNCEKİ kodda BAŞARISIZ olurdu, düzeltmeden SONRA geçiyor; bu, fix'in
       gerçekten bu regresyonu yakaladığının somut kanıtı. `flutter test` tam yeşil: **330/330.**
     - **Gerçek cihazda doğrulanmadı** (ağın soğuk başlangıçta kasıtlı olarak kesilmesini gerektiren
       bir senaryo, kontrollü şekilde tekrarlaması zor) — mantığı test edilen, saf/deterministik bir
       provider metodudur, risk düşük kabul edildi. Kullanıcı isterse: uçak modunu aç → uygulamayı
       kapat → uçak modunu kapatmadan (veya ağı gerçekten yavaş bırakarak) uygulamayı yeniden aç →
       Günlük Giriş Ödülleri'nin ESKİ günü DEĞİL, `DateTime.now()`'a yakın bir günü göstermesi
       gerekir (kalıcı depoda önceden doğrulanmış bir zaman varsa bile).
  - **Genel doğrulama (2026-08-29, kullanıcı isteğiyle: "önce apkyı telefonuma kur sonra tetikle
    loglara bak onaylıyorum") — 1/2/3'ün HEPSİ tek bir turda birlikte doğrulandı:** `flutter build
    apk --debug` ile yeniden derlenip telefona kurulup çöküş olmadan açıldığı (`adb shell monkey` +
    `pidof`, logcat'te `FATAL EXCEPTION` YOK) doğrulandıktan SONRA, saat çakışması düzeltmesinden
    etkilenen DÖRT workflow (`daily-motivation`, `daily-reward-reminder`, `streak-reminder`,
    `water-reminder`) `gh workflow run` ile elle tetiklenip loglar okundu — DÖRDÜ de hatasız
    tamamlandı (`✓` durumu), tek "hata" sınıfı birkaç `NotRegistered` (eski/geçersiz FCM token,
    betiğin zaten beklediği/sessizce atladığı zararsız bir durum, KOD hatası DEĞİL). **Şeffaf bir
    not:** bu manuel tetikleme günün akşam saatine denk geldiği için, YENİ saatlere (`reward=18`,
    `water=14`) geçişten SONRAKİ İLK çalıştırma olduğundan catch-up mekanizması o an "bugün için
    henüz işlenmemiş" bulduğu birçok kullanıcıya ÖDÜL VE SU hatırlatmasını ARKA ARKAYA gönderdi —
    bu, YENİ saatlerin KENDİSİNİN bir çakışması DEĞİL, yalnızca bu BİR KEZLİK manuel/gündüz-dışı
    test tetiklemesinin yan etkisiydi; normal saatlik zamanlamada her tür kendi saatinde, günün
    farklı anlarında tetiklenmeye devam edecek. `streak-reminder` "0 kullanıcı hedef saatte" dedi
    (beklenen — tetikleme anında hiçbir kullanıcının yerel saati henüz 21 değildi), bu da mantığın
    YANLIŞ POZİTİF üretmediğinin kanıtı.
- **2026 ALTINCI güncelleme — kullanıcı raporu: "bildirimler şimdi de 2şer tane gelmeye başladı."**
  Kanıta dayalı araştırma, kör tahminle "muhtemelen sunucu tarafı" diye düzeltmeye BAŞLANMADI —
  önce `gh run view --log` ile 5 betiğin TAMAMININ son ~15'er çalıştırması tek tek incelendi:
  - **SUNUCU tarafında (`notification-scripts`) bir çift-gönderim bulunamadı.** Her çalıştırma
    log'u, uygunluk saati/dilim koşulunu karşılayan HER kullanıcı için TAM BİR `"Gönderildi:
    uid=... type=..."` satırı üretiyordu — iki kez değil. `daily_motivation`'ın AYNI 15 kullanıcıya
    ~3 saat arayla (06:10 VE 09:10 UTC) tekrar göndermesi İLK BAKIŞTA bir çift-gönderim gibi
    göründü, ama bu tamamen BEKLENEN bir davranıştı: bu kullanıcılar Türkiye saatinde (UTC+3),
    `TARGET_LOCAL_HOURS = [9, 12, 16, 20]`'nin İKİ AYRI değerine (yerel 09:10 → hedef 9, yerel
    12:10 → hedef 12) denk geliyorlardı — kullanıcının kendi önceki isteğiyle ZATEN "günde 3-4 kez"
    olacak şekilde tasarlanmış özelliğin doğru çalışması, bir hata DEĞİL. Diğer dört türün
    (`streak_reminder`/`water_reminder`/`daily_reward`/`re_engagement`, hepsi TEK bir hedef saate
    sahip) günlük tekrarları da (~24 saat arayla) aynı şekilde BEKLENEN, tek-günlük cadence'e uygun
    çıktı — hiçbir türde AYNI gün İÇİNDE, AYNI hedef saat için iki ayrı "Gönderildi" satırı
    bulunmadı.
  - **Kök neden İSTEMCİ tarafında bulundu — `NotificationService.showNow()`'ın rastgele bildirim
    id'si.** FCM'in kendi teslimat garantisi resmi olarak "en az bir kez" (at-least-once), "TAM
    OLARAK bir kez" DEĞİL (Firebase'in kendi dokümantasyonu) — ağ yeniden bağlanması gibi durumlarda
    AYNI mantıksal mesaj istemcinin `FirebaseMessaging.onMessage` akışına İKİNCİ kez düşebiliyor.
    `PushNotificationService`'in `onMessage` handler'ı bunu `NotificationService.showNow()`'a
    iletiyordu, ve `showNow()` HER çağrıda `DateTime.now().millisecondsSinceEpoch.remainder(100000)`
    ile YENİ/rastgele bir bildirim id'si üretiyordu — Android'de `_plugin.show(id: ...)`'ün AYNI
    id'yle çağrılması mevcut bildirimin ÜZERİNE YAZAR/günceller, FARKLI id'yle çağrılması ise
    TAMAMEN AYRI, İKİNCİ bir kart EKLER. Rastgele id, bu yeniden-teslimatı Android'in gözünde
    "alakasız yeni bir bildirim" gibi gösteriyordu — kullanıcı bu yüzden AYNI bildirimin "2 tane"
    geldiğini görüyordu.
  - **Düzeltme — iki katmanlı:**
    1. **Kök/asıl düzeltme — `messageId` tabanlı dedup.** `FirebaseMessagingPushNotificationService`'e
       `_recentMessageIds` (en fazla 20 elemanlı, FIFO) eklendi — `onMessage` handler'ı artık FCM'in
       HER mesaja verdiği benzersiz `message.messageId`'yi bu listede ARAYIP zaten işlenmişse
       `showNow()`'ı hiç ÇAĞIRMADAN sessizce çıkıyor.
    2. **İkinci savunma hattı — deterministik bildirim id'si.** `NotificationService.showNow()`'a
       opsiyonel bir `int? id` parametresi eklendi (verilmezse eski rastgele davranışa düşülür —
       geriye dönük uyumlu, TEK çağıran yeri `PushNotificationService` olduğu için risksiz bir
       değişiklik); `onMessage` artık `id: messageId?.hashCode` geçiriyor — (1)'i her nasılsa
       kaçıran bir yeniden teslimat (ör. `messageId` `null` gelirse) olsa bile, Android'in kendi
       "aynı id = güncelle, yeni kart EKLEME" davranışı ikinci bir güvenlik ağı oluyor.
  - **Doğrulanamadı — bu, gerçek bir FCM yeniden-teslimat senaryosunu (ağ kesintisi/yeniden bağlanma
    ANINDA bir bildirim gelmesi) KONTROLLÜ olarak tetiklemek pratik olmadığı için gerçek cihazda
    UÇTAN UCA doğrulanamadı** (yalnızca `flutter test`, 358/358 yeşil — `showNow()`'ın imza
    değişikliği hiçbir mevcut çağrı yerini bozmadı). `PushNotificationService`/
    `FirebaseMessagingPushNotificationService` zaten gerçek Firebase Messaging'e ihtiyaç duyduğu
    için (bkz. bu bölümün en başındaki "flutter_test'te DOĞRUDAN test EDİLEMİYOR" notu, diğer
    Firebase-bağımlı servislerle AYNI sınırlama) otomatik bir regresyon testi de YAZILAMADI. **Bu
    KESİN bir kanıtlanmış çözüm DEĞİL, ama Firebase'in KENDİ resmi "at-least-once, id'lerinizi
    deterministik tutun" tavsiyesine dayanan, doğru/standart bir düzeltme** — kullanıcının birkaç
    gün gerçek kullanımda "2 tane geliyor" örüntüsünün TEKRARLANIP tekrarlanmadığını gözlemlemesi
    gerekiyor.
- **`firestore.rules` — DEĞİŞİKLİK GEREKMEDİ (Cloud Functions taslağındaki gerekçeyle AYNI).**
  Mevcut kural zaten `match /users/{userId}/{document=**}` (bkz. "Firestore Veri Kalıcılığı"
  bölümü) ile `users/{uid}` dokümanının TÜM alanlarını (`fcmToken`/`lastActiveAt` dahil) sahibine
  açıyor — Admin SDK (GitHub Actions'taki `firebase-admin`) zaten TÜM güvenlik kurallarını atlıyor,
  bu yüzden bu betiklerin okuma/yazmaları hiçbir şekilde etkilenmiyor.
- **Blaze plan GEREKMİYOR.** Firestore (Spark/ücretsiz planda da tam işlevsel, cömert bir günlük
  ücretsiz kotayla) ve Firebase Cloud Messaging (plan bağımsız, HER ZAMAN ücretsiz) — GitHub
  Actions'ın kendi ücretsiz dakika kotası (public repo'larda sınırsız, private repo'larda ayda
  2000 dakika) bu 4 küçük, saniyeler süren workflow için fazlasıyla yeterli. **Blaze'e geçilmesi
  gereken TEK senaryo:** ileride Şans Çarkı'nın "bugün çevrildi" durumunu Firestore'a
  senkronize etmek için bir `Cloud Function` (ör. bir Firestore trigger) eklenmek istenirse —
  bu, şu anki mimarinin bir parçası DEĞİL.
- **Servis hesabı (GitHub Secrets) — kullanıcının Firebase Console'da yapması gereken adımlar:**
  1. Firebase Console → proje → dişli ikonu → **Project settings** → **Service accounts** sekmesi.
  2. **Generate new private key** butonuna bas → bir `.json` dosyası iner (bu dosyanın İÇİNDEKİ
     `private_key` alanı bir sır — asla kod deposuna commit etme, asla paylaşma).
  3. GitHub'da repo → **Settings** → **Secrets and variables** → **Actions** → **New repository
     secret**.
  4. İsim: `FIREBASE_SERVICE_ACCOUNT_JSON`. Değer: indirilen `.json` dosyasının TÜM içeriğini
     olduğu gibi (metin editöründe açıp kopyala-yapıştır) yapıştır.
  5. Kaydet — bu andan itibaren workflow'lar `${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}` ile
     bu değere erişebiliyor, GitHub bunu loglarda otomatik olarak maskeliyor.
- **Kritik gotcha — bu arc'ta bulunan ve düzeltilen bir `MaterialApp.home` const-kimlik bug'ı:**
  FCM için `RootScreen`'in anonim `uid`'e ihtiyacı olduğu için ilk yazımda `uid` bir constructor
  parametresi olarak `_AppStartupGate`/`RootScreen`'e eklenmiş, bu da ikisini de `const`
  OLMAKTAN çıkarmıştı. Sonuç: `MaterialApp.home`'un her rebuild'de (ör. Ayarlar'dan Koyu Tema
  değiştirilince, `ThemeProvider.notifyListeners()` → `Consumer3` → yeni `MaterialApp` widget'ı)
  YENİ (const OLMAYAN) bir widget kimliği alması — `flutter test`'te "Koyu Tema anahtarı açılınca
  uygulama koyu temaya geçer" testinin `RootScreen`'i ARTIK BULAMADIĞI (element ağacından tamamen
  kaybolduğu) şeklinde ortaya çıktı. **Düzeltme:** `_AppStartupGate`/`RootScreen` `const` kalmaya
  devam ediyor; `uid` bunun yerine `main.dart`'ın `MultiProvider.providers` listesine
  `Provider<String?>.value(value: uid)` olarak eklendi, `RootScreen` bunu `context.read<String?>()`
  ile okuyan bir `_uid` getter'ı üzerinden alıyor. **Kural: `MaterialApp.home`'a (veya ana
  `Navigator`'ın ilk route'una) verilen bir widget'ın kimliği rebuild'ler arası SABİT (`const` veya
  en azından aynı runtimeType+key) kalmalı — "app-session-constant ama compile-time-const olmayan"
  bir değeri (uid gibi) geçirmek gerekiyorsa, widget'a constructor parametresi olarak DEĞİL, bir
  `Provider<T>.value` ile `MultiProvider`'a ekleyip `context.read<T>()` ile okutun.**
  - **Ayrı ve daha küçük bir test gotcha'sı, AYNI test içinde:** Bu testte Ayarlar sayfası
    `RootScreen`'in ÜSTÜNE push edilmiş haldeyken (Koyu Tema anahtarı Ayarlar'da), `Theme.of
    (tester.element(find.byType(RootScreen)))` çağrısı — `RootScreen` teknik olarak hâlâ element
    ağacında (state korunuyor) ama Navigator onu artık BOYAMIYOR (yalnızca en üstteki route
    render ediliyor) — flutter_test'in VARSAYILAN `find.byType` finder'ı (`skipOffstage: true`)
    böyle "offstage" (boyanmayan ama hâlâ mount edilmiş) elemanları ATLAR. **Çözüm:**
    `find.byType(RootScreen, skipOffstage: false)` — bir widget'ın altında BAŞKA bir route
    push edilmişken o widget'ı `find.byType` ile ararken bu deseni kullanın.

### Firebase Anonymous Auth Temizliği — terkedilmiş test kullanıcılarını silme ([cleanupStaleAnonymousUsers.js](../notification-scripts/src/cleanupStaleAnonymousUsers.js), [.github/workflows/cleanup-stale-anonymous-users.yml](../.github/workflows/cleanup-stale-anonymous-users.yml))

- **2026 bakım işi — BİR KERELİK, cron'a BAĞLI DEĞİL.** Kullanıcı isteği: geliştirme boyunca
  yapılan onlarca test kurulumu/kaldırma (her taze kurulum, bkz. "Firestore veri kalıcılığı,
  Anonymous Auth ve güvenilir zaman" bölümü, `main()`'de `signInAnonymously()` ile YENİ bir
  anonim kimlik oluşturuyor) Firebase'de "boşuna" birikmiş, bir daha asla açılmayacak anonim
  kullanıcılar bıraktı — bunlar hem Authentication hem Firestore'da (`users/{uid}/...`) yer
  kaplıyor. Kullanıcı bunun **bir kerelik bir temizliğini** istedi, periyodik/otomatik bir
  mekanizma İSTEMEDİ (bkz. altta "neden `schedule:` yok" notu).
- **Bu ortamda Node.js/npm YOK** (diğer 4 bildirim betiğiyle AYNI sınırlama, bkz. "Push
  Bildirimleri" bölümü) — betik dikkatle elle yazıldı ama YEREL OLARAK ÇALIŞTIRILIP TEST
  EDİLEMEDİ. Kullanıcının GitHub Actions'tan `workflow_dispatch` ile elle tetikleyip
  doğrulaması gerekiyor.
- **`notification-scripts/src/common.js`'e `auth` (yalnızca bu betik için `app.auth()`)
  eklendi** — diğer 4 betik bunu hiç kullanmıyor, yalnızca `db`/`messaging` yeterli oluyordu.
- **`cleanupStaleAnonymousUsers.js` — "terkedilmiş" tanımı, İKİ sinyalden HANGİSİ daha
  YENİYSE onu kullanan, KASITLI OLARAK temkinli bir hesaplama:**
  1. Firestore `users/{uid}.lastActiveAt` (bkz. `PushNotificationService.touchLastActive` —
     `RootScreen`'in her öne gelişinde tazelenir) — yalnızca push bildirimi özelliği
     eklendikten SONRA en az bir kez açılmış kurulumlar için mevcut.
  2. Firebase Auth'un KENDİ `metadata.lastRefreshTime`/`lastSignInTime`/`creationTime`'ı —
     Firebase'in HER kullanıcı için OTOMATİK tuttuğu, bizim kodumuza bağımlı OLMAYAN bir
     sinyal; push bildirimi eklenmeden ÖNCEki eski test kullanıcıları için TEK kaynak bu.
  İki sinyalden İKİSİ de yoksa (teorik olarak imkansız — Auth her zaman `creationTime` taşır)
  güvenlik gereği o kullanıcıya DOKUNULMUYOR, atlanıyor. Eşik `MIN_INACTIVE_DAYS` (varsayılan
  **30 gün** — kullanıcının seçtiği değer, `AskUserQuestion` ile "3/7/30 gün" arasından
  seçildi) — bu SÜREDİR hiç aktivite izi olmayan kullanıcılar silinmeye aday.
- **GÜVENLİK — varsayılan DRY RUN.** Betik `DRY_RUN=false` AÇIKÇA verilmedikçe HİÇBİR ŞEY
  SİLMEZ, yalnızca "şu uid'ler silinecekti" diye Actions log'una yazar. Workflow'un
  `dry_run` girdisi VARSAYILAN `'true'` — kullanıcı ÖNCE dry-run ile listeyi gözden geçirip,
  sonra emin olunca `dry_run: false` ile TEKRAR tetiklemeli. **Bu iki aşamalı onay bilerek
  eklendi** — tersine çevrilemez bir silme işlemi (gerçek Auth kaydı + kullanıcı verisi) kör
  bir şekilde tek seferde çalıştırılmasın diye.
- **Silme işleminin kendisi — hem Auth HEM Firestore, TEK bir kullanıcı için birlikte:**
  `deleteFirestoreUserData(uid)` önce `users/{uid}/state/*` alt koleksiyonundaki TÜM
  dokümanları (`listDocuments()` ile enumere edilip) TEK bir `batch()` içinde `users/{uid}`
  dokümanının kendisiyle BİRLİKTE siliyor (proje ölçeğinde bir kullanıcının `state`
  koleksiyonu ~20 doküman, `WriteBatch`'in 500 yazma sınırına asla yaklaşmıyor) — SONRA
  `auth.deleteUser(uid)` ile Authentication kaydı siliniyor. Yalnızca Firestore verisini
  silip Auth kaydını BIRAKMAK (veya tersi) YARIM bir temizlik olurdu, ikisi BİRLİKTE
  siliniyor.
- **Neden `schedule:` (otomatik/periyodik tetikleyici) YOK — diğer 4 workflow'un AKSİNE:**
  Kullanıcı `AskUserQuestion` ile açıkça "bir kerelik temizlik" seçeneğini seçti
  ("bir kerelik + haftalık otomatik" veya "yalnızca otomatik" DEĞİL) — bu yüzden
  `.github/workflows/cleanup-stale-anonymous-users.yml`'de yalnızca `workflow_dispatch`
  var, `schedule:` YOK. İleride tekrar gerekirse (ör. birkaç ay sonra yeniden birikirse)
  kullanıcı Actions sekmesinden elle tekrar tetikleyebilir — betiğin/workflow'un kendisi
  KALICI olarak repoda duruyor, tek seferlik kullanılıp silinen bir şey DEĞİL.
- **Doğrulama YAPILAMADI (yerel Node.js yokluğu) — kullanıcının GitHub Actions'tan
  tamamlaması gereken adımlar:**
  1. Actions sekmesi → "Terkedilmiş Anonim Kullanıcıları Temizle" → **Run workflow** →
     `dry_run: true` (varsayılan) ile çalıştır.
  2. Log'u aç, "SİLİNECEK" satırlarını gözden geçir — özellikle KENDİ telefonundaki AKTİF
     kurulumun uid'sinin listede OLMADIĞINDAN emin ol (30 gündür açılmamış olması gerekirdi,
     aktif kullanımda olan bir kurulum bu listede görünmemeli).
  3. Liste doğru görünüyorsa, **Run workflow**'u bu sefer `dry_run: false` ile TEKRAR
     tetikle — bu sefer GERÇEKTEN silinir.

### Push Bildirimi Özel Sesi ([notification_service.dart](lib/services/notification_service.dart), `android/app/src/main/res/raw/zibo_notification.wav`)

- **2026 yeni özellik.** Kullanıcı `assets/sounds/` altına özel bir bildirim sesi (`Zibo
  notification new.wav`) ekledi, push bildirimlerinde (FCM) varsayılan sistem sesi yerine bu sesin
  çalması istendi.
- **Kritik: Android bildirim kanalı sesleri Flutter asset'inden DEĞİL, native `res/raw/`
  kaynağından atanır.** `assets/sounds/`'taki dosya bu özellik için hiç KULLANILMIYOR — Android'in
  kendi bildirim sistemi yalnızca `android.resource://<package>/raw/<isim>` gibi native
  kaynaklara veya `content://` URI'lerine erişebiliyor. Dosya
  `android/app/src/main/res/raw/zibo_notification.wav` olarak KOPYALANDI (orijinali
  `assets/sounds/`'ta da duruyor — **2026 İKİNCİ güncelleme**: `assets/sounds/` klasörü SONRADAN
  Zibo dokunma sesi özelliği için `pubspec.yaml`'ın `flutter: assets:` listesine eklendi, bkz.
  "Zibo Dokunma Sesi" bölümü — bu, o klasördeki `zibo_notification.wav`'ı da bir Flutter asset'i
  haline getirdi ama bu YİNE de bildirim kanalı sesi için KULLANILMIYOR, yalnızca zararsız bir
  yan etki).
  - **Dosya adı yeniden adlandırıldı — Android raw kaynak adlandırma kısıtlaması:** orijinal
    "Zibo notification new.wav" (boşluklu, büyük harfli) Android'in raw kaynak adı kurallarını
    (yalnızca küçük harf, rakam, alt çizgi — `^[a-z0-9_]+$`) İHLAL ediyordu; Gradle bu dosyayı
    `res/raw/` altında görünce derleme hatası verirdi. `zibo_notification.wav` olarak kopyalandı.
  - **Format dönüşümü GEREKMEDİ** — dosya standart PCM WAV (`RIFF ... WAVE audio`), Android
    bildirim sesleri için MP3/WAV/OGG'nin hepsi desteklenir, WAV'ı OGG'ye çevirmeye gerek yoktu.
- **`LocaleNotificationService`'e (bkz. "Bildirimler" bölümündeki mevcut `daily_reminders`
  kanalından AYRI) yeni bir `push_notifications` kanalı eklendi** —
  `AndroidNotificationChannel(sound: RawResourceAndroidNotificationSound('zibo_notification'))`.
  İki kanal BİLEREK ayrı: `daily_reminders` hâlâ rafta olan eski yerel hatırlatma sistemine ait
  (bkz. `notificationsFeatureEnabled`), `push_notifications` yalnızca FCM push bildirimleri için.
- **Kanal, uygulamanın HER başlangıcında erkenden ve koşulsuz oluşturuluyor** —
  `PushNotificationService.initialize()` (her açılışta `main()`'den çağrılıyor, `uid` varsa) artık
  `localNotificationService.initialize(onNotificationTap: () {})`'i FCM izni istemeden ÖNCE
  çağırıyor. **Gerekçe — Android O+'ın kritik bir davranışı:** bir FCM mesajı, henüz cihazda hiç
  oluşturulmamış bir kanala (`android.notification.channel_id`) işaret ederse, bildirim SESSİZCE
  DÜŞÜRÜLÜR (hata fırlatmaz, hiçbir yerde görünmez) — bu yüzden kanalın uygulama arka planda/
  kapalıyken gelen İLK bildirimden bile ÖNCE var olması şart, yalnızca bir bildirim gösterilirken
  "tembel" oluşturmak yetmiyor.
- **Bulunan ve düzeltilen gerçek bir bug — `showNow()` hiçbir zaman `initialize()`'ı
  ÇAĞIRMIYORDU:** `PushNotificationService`, ön plandaki FCM mesajlarını göstermek için
  `NotificationService.showNow()`'ı çağırıyordu, ama eski yerel hatırlatma sistemi kapalı olduğu
  için (`notificationsFeatureEnabled == false`) `RootScreen` hiçbir zaman `NotificationProvider.
  initializeAndSchedule()`'ı çağırmıyor, dolayısıyla `flutter_local_notifications` eklentisinin
  KENDİSİ (`_plugin.initialize()`) hiç başlatılmamış oluyordu — `showNow()` bu durumda `_plugin.
  show()`'u SESSİZCE (try/catch içinde) başarısız kılıyordu, yani **ön planda gelen HİÇBİR FCM
  mesajı hiçbir zaman gösterilmiyordu.** Düzeltme: `showNow()` artık kendi başına `initialize
  (onNotificationTap: () {})`'i (idempotent, `_initialized` bayrağıyla korunuyor) çağırıp emin
  oluyor.
- **`notification-scripts/src/common.js`'deki `sendToUser`'a `android.notification.channelId:
  'push_notifications'` ve `sound: 'zibo_notification'` eklendi** — bu, uygulama ARKA PLANDA/
  KAPALIYKEN OS'in doğrudan gösterdiği bildirimlerin (ön planda `showNow` üzerinden gösterilenlerin
  DIŞINDaki asıl senaryo) doğru kanala (dolayısıyla doğru sese) yönlenmesini sağlıyor —
  channel_id verilmezse Android varsayılan bir kanal kullanır, bu da varsayılan sistem sesi demek.
- **Test:** Ses/kanal atamasının kendisi platform kanalına dokunduğu için `flutter test`'te
  DOĞRULANAMIYOR (mevcut `LocalNotificationService`'in TÜM platform-kanalı metotları zaten try/
  catch'li ve testte sessizce no-op oluyor, bkz. "Bildirimler" bölümündeki genel gerekçe) — gerçek
  doğrulama yalnızca cihazda mümkün, bkz. altta.
- **Gerçek cihazda doğrulama adımları (kullanıcı için):**
  1. Yeni derlenen `app-debug.apk`'yı kur (aşağıdaki "Kurulum" talimatına bakın).
  2. Uygulamayı aç (bu, `PushNotificationService.initialize()`'ı tetikleyip kanalı + FCM token'ını
     kaydeder) — telefon Android 13+ ise bir bildirim izni isteği görmelisin, izin ver.
  3. GitHub Actions'tan (`Actions` sekmesi) herhangi bir bildirim workflow'unu `workflow_dispatch`
     ile elle çalıştır (bkz. "Push Bildirimleri" bölümündeki test talimatları).
  4. Telefonda bildirim gelince (uygulama AÇIK/ön plandayken VEYA kapalıyken/arka plandayken)
     **özel Zibo sesinin** çaldığını, varsayılan sistem "ping" sesinin ÇALMADIĞINI doğrula.
  5. **Eğer hâlâ varsayılan ses çalıyorsa:** Ayarlar > Uygulamalar > Zibo > Bildirimler > "Push
     Bildirimleri" kanalına gir, kanalın sesinin gerçekten "Zibo" (ya da benzer bir isim) olarak
     ayarlı olduğunu kontrol et. **Önemli Android davranışı:** bir bildirim kanalı BİR KEZ
     oluşturulduktan sonra, uygulama kodundaki sesi/ayarları DEĞİŞTİRMEK kanalı GÜNCELLEMEZ — eğer
     bu APK'dan ÖNCE zaten bir `push_notifications` kanalı oluşmuşsa (olası değil, bu kanal bu
     arc'ta YENİ eklendi, ama ihtimal dahilinde) uygulamayı TAMAMEN kaldırıp yeniden kurmak
     (yalnızca yeniden derlemek YETMEZ) gerekebilir — bu, Android'in kanal sistemine özgü, kod
     tarafından atlatılamayan bir kısıtlama.
- **2026 İKİNCİ güncelleme — 4 bildirim türünün TÜMÜ tek sese/kanala bağlı olduğu doğrulandı,
  KOD DEĞİŞİKLİĞİ GEREKMEDİ.** Kullanıcı isteği: "Günlük Motivasyon/Streak Hatırlatması/Günlük
  Ödül Hatırlatması/Geri Kazanma bildirimlerinin HEPSİ aynı `zibo_notification.wav` sesini
  çalsın." İnceleme sonucu: `notification-scripts/src/*.js`'teki 4 betiğin (`dailyMotivation.js`,
  `streakReminder.js`, `dailyRewardReminder.js`, `reEngagement.js`) HEPSİ ZATEN `common.js`'teki
  TEK bir paylaşılan `sendToUser(...)` fonksiyonunu çağırıyordu (bkz. "Push Bildirimleri"
  bölümü) — `channelId: 'push_notifications'`/`sound: 'zibo_notification'` bu TEK fonksiyonda
  bir önceki oturumda zaten ayarlanmıştı, dolayısıyla 4 türün hepsi otomatik olarak AYNI kanala/
  sese bağlıydı. Bu istek, bir önceki arc'ta zaten tam olarak tamamlanmış bir işin
  DOĞRULANMASIYDI — hiçbir dosya değişmedi.
- **2026 ÜÇÜNCÜ güncelleme — kullanıcı raporu: gerçek cihazda özel ses HİÇ çalmıyor, varsayılan
  sistem sesi geliyor.** Kod tekrar incelendi — `push_notifications` kanalının oluşturma kodu
  (`LocalNotificationService.initialize()`) VE `zibo_notification.wav` dosyası (`android/app/
  src/main/res/raw/`) ikisi de doğru/eksiksiz. **Teşhis — bu yukarıdaki "Önemli Android
  davranışı" notunda BAHSEDİLEN, o zaman "olası değil ama ihtimal dahilinde" diye işaretlenmiş
  senaryonun TAM OLARAK gerçekleştiği durum:** kullanıcının cihazında Ayarlar > Uygulamalar >
  Zibo > Bildirimler > "Push Bildirimleri" kanalı kontrol edildiğinde ses "Varsayılan" görünüyordu
  — yani bu kanal, ses doğru şekilde bağlanmadan ÖNCEki bir APK sürümünde (bu proje boyunca aynı
  cihaza onlarca kez kurulup kaldırılmıştı) zaten oluşmuş ve Android'e "yapışmış". **Kod
  tarafında YAPILACAK HİÇBİR ŞEY YOK** — çözüm KESİNLİKLE uygulamayı cihazdan TAMAMEN kaldırıp
  (yalnızca `adb install -r` ile üzerine kurmak YETMEZ) yeniden kurmak, bu Android'in kanal
  sistemine özgü, programatik olarak atlatılamayan bir kısıtlama. **Bu ders genelleştirilebilir:**
  bir bildirim kanalının sesi/adı/açıklaması ile ilgili "kod doğru ama cihazda çalışmıyor"
  raporu alındığında, İLK yapılacak şey kodu şüphelenmek DEĞİL, kullanıcıdan cihazın Ayarlar
  uygulamasında o kanalın GERÇEKTE ne gösterdiğini sormak — kanal zaten yanlış konfigürasyonla
  cihaza kaydolmuşsa hiçbir kod değişikliği bunu düzeltmez, yalnızca kaldır+yeniden kur düzeltir.
- **2026 DÖRDÜNCÜ güncelleme — kaldır+yeniden kurulumdan SONRA bulunan, AYRI bir kafa karıştırıcı
  durum: Android bildirim ayarlarında İKİ kanal görünüyordu.** Yeniden kurulum "Push Bildirimleri"
  kanalının sesini düzeltti (ÖNCEKİ madde), ama kullanıcı Ayarlar'da BİR DE **"Günlük
  Hatırlatmalar"** adında, "Varsayılan" ses gösteren İKİNCİ bir kanal olduğunu fark etti — bu,
  push bildirimleriyle İLGİSİZ, `notificationsFeatureEnabled = false` ile rafa kaldırılmış ESKİ
  yerel hatırlatma sisteminin kanalı (bkz. "Bildirimler" bölümü). **Kök neden:**
  `LocalNotificationService.initialize()` HER İKİ kanalı da (push + eski yerel) KOŞULSUZ
  oluşturuyordu — `PushNotificationService.initialize()` her uygulama açılışında bu metodu
  çağırdığı için, özellik devre dışı olsa bile `daily_reminders` kanalı yine de Android'e
  kaydoluyordu, yalnızca hiçbir zaman KULLANILMIYORDU (zararsız ama kafa karıştırıcı — kullanıcı
  hangisinin "gerçek" motivasyon kanalı olduğunu ayırt edemedi). **Düzeltme:** `notificationsFeatureEnabled`
  sabiti dairesel import olmadan hem `NotificationProvider` hem `NotificationService` tarafından
  okunabilsin diye YENİ [notification_config.dart](lib/config/notification_config.dart) dosyasına
  taşındı (`notification_provider.dart` geriye dönük uyumluluk için onu `export` ediyor, mevcut
  importlar DEĞİŞMEDİ); `daily_reminders` kanalının oluşturulması artık `if
  (notificationsFeatureEnabled)` ile SARILI — özellik kapalıyken bu kanal ARTIK HİÇ oluşmuyor,
  yeniden etkinleştirilirse bir sonraki `initialize()` çağrısında (her açılış) otomatik geri
  gelir. **Ders:** iki BAĞIMSIZ özelliğin (aktif push sistemi + rafa kaldırılmış eski yerel
  sistem) altyapı kurulumunu (`initialize()`) TEK bir metotta birleştirmek, birinin "kapalı"
  durumunun diğerinin yan etkilerini (burada: kullanılmayan bir Android kanalının kalıcı olarak
  cihaza kaydolması) engellemeyebilir — her alt kurulum adımı kendi özelliğinin açık/kapalı
  bayrağına göre AYRI AYRI kapılanmalı.
- **2026 BEŞİNCİ güncelleme — ASIL kök neden bulundu: `res/raw/zibo_notification.wav`
  RELEASE APK'DAN TAMAMEN SİLİNMİŞTİ (kaynak küçültücü tarafından).** Yukarıdaki İKİ düzeltmeden
  (kanal önbelleği + ölü ikinci kanal) SONRA bile kullanıcı sesin HÂLÂ çalmadığını bildirdi —
  kanal Ayarlar'da doğru isimle ("zibo_notification") görünmeye devam ediyordu ama gerçek çalma
  anında HİÇBİR ses çıkmıyordu. Sistemli bir şekilde elenen ihtimaller: (1) ses dosyasının
  kendisi sessiz/bozuk mu? — PowerShell ile `.wav`'ın PCM örneklerini elle okuyup tepe genliğini
  ölçtük (%100, sağlıklı), DEĞİL; (2) kullanıcının yeni eklediği `assets/sounds/
  zibo_notification_new.wav` farklı bir dosya mı? — `md5sum` ile karşılaştırıldı, mevcut
  `res/raw/zibo_notification.wav` ile BİREBİR AYNI, DEĞİL; (3) `adb uninstall`in SESSİZCE
  başarısız olup (`DELETE_FAILED_INTERNAL_ERROR`) eski/bozuk kanalın kalıntısını bırakmış olması
  mı? — telefonun KENDİ arayüzünden (adb değil) kaldırılıp `adb shell pm list packages` ile
  paketin GERÇEKTEN gittiği doğrulandıktan sonra tertemiz yeniden kurulum yapıldı, DEĞİL (sorun
  aynen devam etti). **Asıl kanıt — derlenen release APK'nın kendisi `aapt2 dump resources` ile
  incelendi:** `raw/zibo_notification` kaynağı APK'da HİÇ YOKTU (yalnızca AGP'nin kendi
  ürettiği, boş bir `raw/keep` girdisi vardı) — **kaynak küçültücü (`isShrinkResources = true`,
  bkz. "Release İmzalama" bölümü) dosyayı "kullanılmıyor" sanıp APK'dan SİLMİŞTİ.** Kök neden:
  `flutter_local_notifications`'ın `RawResourceAndroidNotificationSound('zibo_notification')`'ı
  bu kaynağa yalnızca ÇALIŞMA ZAMANINDA bir METİN İSMİYLE (platform kanalı üzerinden) referans
  veriyor — Java/Kotlin/XML'de statik bir `R.raw.zibo_notification` referansı YOK, bu yüzden
  kaynak küçültücünün statik kullanım analizi bu dosyayı hiç "görmüyor" ve güvenle silinebilir
  sanıyor. **Kanal OLUŞTURMA kodu bu yüzden hiç hata VERMİYORDU** (yalnızca bir Uri/isim
  kaydediyor, dosyanın var olup olmadığını kontrol etmiyor) — hata yalnızca gerçek ÇALMA anında,
  sessizce ortaya çıkıyordu. **Düzeltme — Android'in resmi/standart mekanizması:**
  [android/app/src/main/res/raw/keep.xml](android/app/src/main/res/raw/keep.xml) (YENİ) eklendi:
  ```xml
  <resources xmlns:tools="http://schemas.android.com/tools"
      tools:keep="@raw/zibo_notification" />
  ```
  Bu, küçültücüye bu KAYNAĞA DOKUNMAMASINI açıkça söylüyor. **Doğrulama İKİ aşamalı yapıldı:**
  önce statik olarak, `aapt2 dump resources` ile yeniden derlenen APK'da `raw/zibo_notification`'ın
  artık GERÇEKTEN var olduğu teyit edildi; sonra gerçek cihazda kurulup **kullanıcı bildirim
  sesinin GERÇEKTEN çaldığını doğruladı** — sorun KALICI olarak çözüldü. **Ders — genelleştirilebilir
  bir Android/R8 kalıbı:** bir
  native platform eklentisinin (herhangi bir Flutter eklentisi) bir Android kaynağına yalnızca
  bir STRING/isim üzerinden ÇALIŞMA ZAMANINDA referans verdiği HER durumda (raw ses/video
  dosyaları, drawable'lar vb. — `R.xxx.yyy` gibi statik bir Java/Kotlin/XML referansı yerine),
  release build'de kaynak küçültme AÇIKSA (`isShrinkResources = true`) bu kaynak SESSİZCE
  silinme riski taşır — kanıt/hata YOK, yalnızca çalışma zamanında sessiz bir eksiklik. Bu tür
  bir kaynak eklerken PROAKTİF olarak `res/raw/keep.xml`'e (veya ilgili kaynak türü için
  benzerine) eklemek, sorunu TESPİT ETMEK için saatler harcamaktan çok daha ucuz.

### Zibo Dokunma Sesi ([sound_effects_service.dart](lib/services/sound_effects_service.dart), [sound_effects_provider.dart](lib/providers/sound_effects_provider.dart), `assets/sounds/zibo_tap_new.wav`)

- **2026 yeni özellik.** Kullanıcı `assets/sounds/zibo_tap_sound.wav` ekledi, Ana Sayfa'da Zibo'ya
  her dokunuşta (mevcut poz/söz değişim animasyonuyla AYNI anda) bu sesin çalmasını istedi —
  art arda hızlı dokunuşlarda seslerin üst üste binmemesi ve Ayarlar'da bir "Ses Efektleri"
  anahtarına bağlı olması şartıyla.
- **2026 İKİNCİ güncelleme — ses dosyası değiştirildi.** Kullanıcı `zibo_tap_sound.wav`'ı iptal edip
  yerine `zibo_tap_new.wav`'ı ekledi — `AudioPlayersSoundEffectsService.playZiboTap()`'teki
  `AssetSource(...)` yolu güncellendi, eski dosya `assets/sounds/`'tan SİLİNDİ (artık hiçbir yerde
  referans edilmiyor). Mekanizmanın kendisi (stop+play, `SoundEffectsProvider`, `HomeScreen`
  enjeksiyonu) HİÇ değişmedi — yalnızca hangi ses dosyasının çalındığı değişti.
- **`audioplayers: ^6.0.0`** (pubspec.yaml, `flutter pub get` ile `6.8.1`'e çözüldü) — projede
  daha önce hiçbir ses ÇALMA paketi yoktu (yalnızca `flutter_local_notifications`'ın kendi dahili
  ses mekanizması vardı, bkz. yukarıdaki "Push Bildirimi Özel Sesi" bölümü — bu TAMAMEN AYRI bir
  ihtiyaç, native bildirim kanalı değil, uygulama İÇİNDE anlık bir ses efekti). `assets/sounds/`
  klasörü `pubspec.yaml`'ın `flutter: assets:` listesine eklendi (önceden yalnızca
  `assets/images/` vardı) — `AudioPlayer.play(AssetSource(...))` Flutter asset bundle'ından
  okuduğu için (native `res/raw/`'dan DEĞİL, bkz. yukarıdaki bildirim sesi bölümündeki AYNI ayrım
  ama TERSİ yönde) bu adım gerekliydi.
- **`SoundEffectsService`** (`AdService`/`NotificationService` ile AYNI "gerçek + fake, testte
  enjekte edilebilir" desen — `audioplayers` da bir platform kanalı kullandığı için
  `flutter_local_notifications` gibi `flutter_test`'te doğrudan kullanılamaz):
  - `AudioPlayersSoundEffectsService` — tek bir `AudioPlayer` örneği (`ReleaseMode.stop`).
    `playZiboTap()` her çağrıldığında ÖNCE `_player.stop()` SONRA `_player.play(AssetSource
    ('sounds/zibo_tap_new.wav'))` çağırıyor — kullanıcının "art arda hızlı tıklamalarda önceki
    sesi kesip yeniden başlat" isteği bu TEK `stop()`+`play()` çiftiyle karşılanıyor, ayrı bir
    debounce zamanlayıcısına gerek KALMADI (daha basit, daha az durum yönetimi).
  - `FakeSoundEffectsService` — `const`, no-op (diğer Fake* servislerle AYNI desen).
- **`SoundEffectsProvider`** — `ThemeProvider` ile BİREBİR AYNI Varyant C (`CloudStateStore`, tek
  bool, `{'value': ...}` sarmalı) deseni; `enabled` varsayılan `true`. Bilerek genel/soyut
  isimlendirildi ("Ses Efektleri", tekil "Zibo dokunma sesi" DEĞİL) — şu an tek bir ses efekti
  kontrol ediyor olsa da, ileride başka UI ses efektleri (ör. coin kazanma sesi) eklenirse AYNI
  anahtarı paylaşabilsin diye.
- **`HomeScreen`'e enjeksiyon** — `RootScreen.pushNotificationService` ile AYNI desen:
  `HomeScreen({this.soundEffectsService})` opsiyonel bir constructor parametresi (varsayılan
  gerçek `AudioPlayersSoundEffectsService()`), `_HomeScreenState` bunu `late final` bir alanda
  tutup `dispose()`'ta serbest bırakıyor. `_onZiboTap()` (poz/söz değişiminin olduğu AYNI metot)
  artık `context.read<SoundEffectsProvider>().enabled` kontrolünden geçerse
  `_soundEffectsService.playZiboTap()`'i de çağırıyor — poz/söz değişimiyle TAM OLARAK aynı anda
  tetikleniyor (kullanıcının açık isteği).
  - **Yalnızca Ana Sayfa'da — kapsam bilinçli olarak dar tutuldu.** Kullanıcı "Zibo'nun
    tıklanabilir olduğu diğer yerlerde de" dedi, ama incelemede diğer 7 modül ekranının HİÇBİRİNDE
    Zibo görseli tıklanabilir DEĞİL (`GestureDetector`/`onTap` yok, bkz. "Zibo Poz/Animasyon
    Sistemi" bölümü — yalnızca Ana Sayfa'nın `_onZiboTap`'i poz/söz ilerletiyor) — bu yüzden
    şu an fiilen yalnızca Ana Sayfa'da ses çalıyor, kapsam eksiksiz. **İleride başka bir ekranda
    Zibo tıklanabilir hale getirilirse, aynı `_soundEffectsService.playZiboTap()` deseni oraya da
    eklenmeli.**
- **Ayarlar'a yeni "Ses Efektleri" anahtarı** — `settings_screen.dart`'taki "Genel" kartında,
  "Koyu Tema" satırının HEMEN ALTINDA (`Icons.volume_up_outlined`, yeni `settingsSoundEffects`
  ARB anahtarı, TR/EN/ES üçünde de eklendi). Kart artık ÜÇ satır (Koyu Tema/Ses Efektleri/Dil) —
  bu, `settings_screen.dart`'ın "yeni içerik eklerken altındaki testler `scrollUntilVisible`
  gerektirebilir" gotcha'sını (bkz. "Test kalıpları" bölümü) TEKRAR tetikledi: "Gizlilik
  Politikası"/"Kullanım Koşulları" testindeki `tester.tap(find.text(...))` çağrıları artık
  hit-test uyuşmazlığı yaşıyordu (kaydırma sonrası satır AppBar'a çok yakın kalıyordu) —
  `tester.widget<ListTile>(...).onTap!()` ile DOĞRUDAN çağrıya çevrildi (GridView/hit-test
  uyuşmazlığı deseniyle AYNI çözüm, bkz. "Test kalıpları").
- **Test:** YENİ `test/sound_effects_provider_test.dart` (`ThemeProvider` testleriyle AYNI desen:
  varsayılan açık, `setEnabled` hem durumu hem kalıcı depoyu günceller, yeniden başlatmada
  hatırlanır) + YENİ `test/home_screen_sound_test.dart` (`manifest_journal_screen_test.dart`'taki
  "bağımsız test uygulaması + sahte servis enjeksiyonu" deseniyle: Ses Efektleri açıkken Zibo'ya
  dokununca `playZiboTap` çağrılır, kapalıyken ÇAĞRILMAZ). **Gotcha (tekrar yaşandı):**
  `Image.asset()` providers boot olduktan hemen sonra yükseklik=0 raporlayıp `tester.tap()`'in
  hit-test'ini şaşırtabiliyor (bkz. "Test kalıpları" bölümündeki aynı gotcha) — çözüm yine
  `pumpAndSettle()`'dan sonra `tester.runAsync(() => Future.delayed(Duration(milliseconds:
  100)))` + bir `pumpAndSettle()` daha. `widget_test.dart`'ın `_buildAppWithClock()`'una da
  `SoundEffectsProvider` eklendi (RootScreen'in ihtiyaç duyduğu HER provider kuralı, bkz. "Test
  kalıpları").
- **Gerçek cihazda doğrulama:** APK yeniden derlenip telefona kurulup çöküş izi olmadan açıldığı
  doğrulandı (`adb shell monkey`/`pidof`) — sesin GERÇEKTEN duyulup duyulmadığı (ve Ayarlar'daki
  anahtarın gerçekten sesi açıp kapattığı) kullanıcının kendi cihazında dinleyerek doğrulaması
  gerekiyor, bu arc'ta yalnızca kod seviyesinde (`flutter test`, 244 test) doğrulandı.
- **2026 ÜÇÜNCÜ güncelleme — üç YENİ ses efekti: coin kazanma, coin satın alma, hedef tamamlama.**
  Kullanıcı isteği (verbatim özet): `zc_reward.wav` coin kazanılan HER senaryoda (check-in, günlük
  görev, streak bonusu, çark, günlük giriş ödülü, reklam karşılığı coin, su/şükran/manifest
  hedefleri), `zc_buy.wav` Mağaza'dan gerçek para karşılığı coin paketi satın alınca, `zibo_target.
  wav` Hedef Takibi'nde bugünün kutucuğu işaretlenince (bkz. altta "Hedef Tamamlama Kutlaması"
  bölümü) çalsın. `SoundEffectsService`'in kapsamı yukarıdaki "yalnızca Zibo dokunma sesi"
  yorumundan TAM OLARAK öngörüldüğü gibi genişletildi (bkz. `SoundEffectsProvider`'ın "ileride
  başka ses efektleri eklenirse AYNI anahtarı paylaşsın" notu — GERÇEKTEN öyle oldu, tek "Ses
  Efektleri" anahtarı hepsini birden açıp kapatıyor, ayrı bir anahtar EKLENMEDİ).
  - **`SoundEffectsService`'e üç yeni soyut metot eklendi:** `playCoinReward()`, `playCoinPurchase()`,
    `playGoalComplete()` — `playZiboTap()` ile AYNI imza deseni. `AudioPlayersSoundEffectsService`
    içindeki tekrarlı stop+play mantığı ortak bir `_play(String assetPath)` yardımcı metoduna
    çıkarıldı (dört genel metot da bunu çağırıyor) — TEK bir `AudioPlayer` örneği hâlâ yeterli
    çünkü her tüketici (`HomeScreen`, `CoinProvider`, `GoalTrackingScreen`) KENDİ AYRI
    `SoundEffectsService` örneğini oluşturuyor (bkz. altta), farklı bağlamlardaki sesler
    birbirini KESMİYOR.
  - **`CoinProvider`'a `SoundEffectsService`/`bool Function() isSoundEnabled` enjeksiyonu** —
    `CoinProvider` bir widget OLMADIĞI için `HomeScreen`'in yaptığı gibi doğrudan
    `context.read<SoundEffectsProvider>()` çağıramıyor; `now: DateTime Function()` (`TrustedTimeProvider`
    için) ile AYNI enjekte edilebilir callback deseni `isSoundEnabled` için de kullanıldı.
    `main.dart`'ta `SoundEffectsProvider` artık `CoinProvider`'dan ÖNCE listelendi (`MultiProvider`
    listesinde ÖNCEKİ provider'lar SONRAKİlerin `context`'inden görünür olduğu için —
    `TrustedTimeProvider`'ın EN BAŞTA olma gerekçesiyle AYNI) — `CoinProvider`'ın `create` callback'i
    `() => context.read<SoundEffectsProvider>().enabled` geçiriyor.
  - **Merkezi tetikleme noktası — `_earn()`.** `CoinProvider._earn(int amount, String reason,
    {bool playRewardSound = true})` artık `playRewardSound && _isSoundEnabled()` iken
    `playCoinReward()` çalıyor — bu, `_earn()`'ün ZATEN TÜM kazanma mekaniklerinin (yukarıdaki
    kullanıcı listesinin tamamı) TEK geçiş noktası olması sayesinde HİÇBİR `earn*` metoduna elle
    ses çağrısı eklemeden otomatik olarak kapsandı. **TEK istisna — `purchaseCoinPackage()`:**
    `_earn(..., playRewardSound: false)` ile "kazanma" sesini BASTIRIP hemen ardından KENDİ ayrı
    `playCoinPurchase()`'ini çalıyor — "kazanma" ile "satın alma" arasında işitsel bir ayrım olsun
    diye kasıtlı.
  - **`CoinProvider.dispose()` eklendi** — `_soundEffectsService.dispose()` çağırıyor (önceden
    `CoinProvider`'ın hiç `dispose()` override'ı yoktu).
  - **Test:** `coin_provider_test.dart`'a YENİ `_RecordingSoundEffectsService` + "CoinProvider -
    kazanma/satın alma sesleri" grubu (3 test: kazanma mekanikleri `playCoinReward` çalar
    `playCoinPurchase` ÇALMAZ; satın alma tersi; `isSoundEnabled: () => false` iken HİÇBİRİ
    çalmaz).
- **2026 DÖRDÜNCÜ güncelleme — üç YENİ ses efekti: kostüm satın alma, tema satın alma, su damlası.**
  Kullanıcı `assets/sounds/` klasörüne üç yeni dosya ekledi: `zibo_costume_buy.wav` (Mağaza'da bir
  kostüm satın alınca), `theme_buy.wav` (bir tema satın alınca — kostümden BİLEREK AYRI bir ses,
  kullanıcının açık isteği), `water_drop.wav` (Su Takibi'nde bir bardak/şişe dolum kutucuğuna
  dokunup su içildiği işaretlenince, dolma animasyonuyla EŞ ZAMANLI). Hepsi mevcut "Ses Efektleri"
  anahtarına bağlı (`SoundEffectsProvider.enabled`) ve mevcut stop+play deseni sayesinde üst üste
  binmiyor — yeni bir mimari GEREKMEDİ, yalnızca mevcut `SoundEffectsService` sözleşmesine üç yeni
  metot eklendi.
  - **`SoundEffectsService`'e üç yeni soyut metot: `playCostumeBuy()`, `playThemeBuy()`,
    `playWaterDrop()`** — `playCoinReward()`/`playCoinPurchase()`/`playGoalComplete()` ile AYNI
    imza deseni, `AudioPlayersSoundEffectsService` içindeki ortak `_play(String assetPath)`
    yardımcısını çağırıyor (stop+play, üst üste binmeyi engelliyor). `FakeSoundEffectsService`'te
    üçü de no-op.
  - **`CoinProvider.spendOnCostume`/`spendOnTheme`** artık harcama BAŞARILI olduğunda (yetersiz
    bakiye durumunda `_spend` `false` döndüğü için ses HİÇ çalınmıyor) kendi sesini çalıyor —
    `playCoinReward`'ın aksine bunlar `_earn()`'ün merkezi ses yoluna GİRMİYOR (bunlar birer
    HARCAMA, kazanma değil), `spendOnCostume`/`spendOnTheme` gövdelerinde doğrudan
    `_soundEffectsService.playCostumeBuy()`/`playThemeBuy()` çağrılıyor (ikisi de
    `_isSoundEnabled()` kontrolünden geçtikten sonra).
  - **`WaterTrackingScreen`** yeni bir opsiyonel `soundEffectsService` constructor parametresi
    kazandı (`HomeScreen`/`GoalTrackingScreen` ile AYNI test-injection deseni, varsayılan gerçek
    `AudioPlayersSoundEffectsService()`). `_tapGlass` yalnızca ARTIŞ (bardağı/şişeyi DOLDURMA)
    dalında `playWaterDrop()` çağırıyor, azaltma (geri alma/undo) dalında ÇAĞIRMIYOR — kullanıcının
    "kullanıcı... su içtiğini işaretlediğinde çalsın" isteğiyle birebir örtüşüyor.
  - **Test:** `coin_provider_test.dart`'ın "kazanma/satın alma sesleri" grubuna 3 yeni test eklendi
    (kostüm satın alma sesi çalar, tema satın alma sesi çalar, yetersiz bakiyede İKİSİ de
    çalmaz) + mevcut "isSoundEnabled false" testi kostüm/tema seslerinin de susturulduğunu
    doğruyacak şekilde genişletildi. YENİ `test/water_tracking_sound_test.dart` (Ses Efektleri
    açıkken bir birim işaretlenince `playWaterDrop` çağrılır) — `find.byIcon(Icons.
    water_drop_outlined)`/`find.byIcon(Icons.water_drop)` ile bulunuyor (`_WaterGlass` yalnızca
    ikon render ediyor, görünür bir sayı metni YOK — `find.text('1')` gibi bir finder işe
    yaramaz). `goal_completion_celebration_test.dart`/`home_screen_sound_test.dart`'taki yerel
    `_RecordingSoundEffectsService` sınıflarına da (bu dosyalar kostüm/tema/su sesini test
    ETMİYOR ama Dart'ın soyut sınıf sözleşmesini karşılamak için) üç yeni metodun no-op override'ı
    eklendi.
  - **Test suite'i tam yeşil:** 262/262 geçti.

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
  `FavoriteQuotesProvider`, `FounderBadgeProvider` (2026 — `ProfileScreen`/`SettingsScreen`'in
  `FounderBadgePromoCard` üzerinden izlediği, bkz. "Kurucu Üye Rozeti" bölümü), `GoalsProvider`,
  `GratitudeProvider`, `HiddenBadgeProvider` (2026 — Gizli/Eğlenceli Rozetler'in
  `BadgeCoordinator`'ı artık bunu da izlediği için, bkz. "Rozet Sistemi" bölümündeki "Altıncı ve
  SON kategori"), `LocaleProvider`,
  `ManifestProvider`, `MoneyProvider`, `MoodProvider`, `NotificationProvider`, `ProfileProvider`,
  `ProfileStatsArchiveProvider`, `ReferralProvider` (2026 — Sosyal/Paylaşım Rozetleri'nin
  `BadgeCoordinator`'ı artık bunu da izlediği için, bkz. "Rozet Sistemi" bölümündeki "Beşinci
  kategori"), `SoundEffectsProvider`,
  `ThemeProvider`, `TrustedTimeProvider`, `WaterProvider`, `ZiboPoseProvider`) — bunun sebebi
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

## Ana Ekran Widget'ları ([home_widget_service.dart](lib/services/home_widget_service.dart), [home_widget_sync_coordinator.dart](lib/services/home_widget_sync_coordinator.dart), [widget_status.dart](lib/utils/widget_status.dart), [widget_module.dart](lib/utils/widget_module.dart), [widgets_screen.dart](lib/screens/widgets_screen.dart), [android/.../widgets/](android/app/src/main/kotlin/com/dijitalkanka/dijital_kanka/widgets/))

- **2026 yeni özellik.** Kullanıcı isteği: "her modül için kullanıcı anasayfasına widget
  ekleyebilsin, widget tasarımını yap" — SEKİZ modülün (Hedef Takibi, Su Takibi, Şükran Günlüğü,
  Günlük Ruh Hali Takibi, Manifest Günlüğü, Rüya Günlüğü, Para ve Birikim, Günlük Giriş Ödülleri)
  HER BİRİ için ayrı, kullanıcının Android ana ekranına ekleyebileceği bir "at a glance" widget.
- **Paket seçimi — `home_widget: ^0.9.0` (0.9.3'e çözüldü), KLASİK (RemoteViews/
  `AppWidgetProvider`-tabanlı) API ile, YENİ Jetpack Glance (Compose) API'si DEĞİL.** Paketin
  GitHub deposu (`gh api` ile incelendi, WebFetch'in Medium/docs.page sayfalarını çekemediği
  durumlarda) `HomeWidgetProvider` (klasik) sınıfının hem eski hem GÜNCEL (main branch, 0.9.3)
  sürümde hâlâ mevcut olduğunu doğruladı — paketin ÖRNEKLERİ Glance'a geçmiş olsa da, alttaki
  Android kütüphanesi ikisini de destekliyor. **Glance BİLEREK seçilmedi:** Glance, `androidx.
  glance:glance-appwidget` + Kotlin Compose derleyici Gradle plugin'i (`org.jetbrains.kotlin.
  plugin.compose`) + `buildFeatures.compose = true` gerektiriyor — bu projenin `app/build.gradle.
  kts`'sinde HİÇ kullanılmayan, bu spesifik AGP 9.0/Gradle 9.1.0 kombinasyonuyla önceden HİÇ test
  edilmemiş bir toolchain eklemek anlamına gelirdi (bir sürüm uyuşmazlığı TÜM UYGULAMANIN
  derlemesini kırabilirdi, yalnızca widget özelliğini değil). Klasik RemoteViews/XML-layout yolu,
  bu projenin YAZILI/görsel olarak DOĞRULANABİLEN, hiçbir yeni Gradle plugin'i gerektirmeyen,
  çok daha düşük riskli seçimdi — `home_widget` paketinin KENDİSİ zaten `androidx.glance:
  glance-appwidget`'ı transitif bir bağımlılık olarak taşıyor (klasik API kullanılsa bile), ama bu
  YALNIZCA paketin İÇİNDE bir AAR bağımlılığı — uygulamanın KENDİ modülünde hiçbir `@Composable`
  kod YAZILMADIĞI için `app/build.gradle.kts`'e Compose derleyicisi eklemeye HİÇ gerek kalmadı.
- **Mimari — SEKİZ widget, TEK paylaşılan native render mantığı.** `res/layout/widget_module.xml`
  (TEK RemoteViews layout — ikon rozeti + başlık + büyük "ana metin" + küçük "alt metin" +
  opsiyonel yatay ilerleme çubuğu) SEKİZ widget'ın HEPSİ tarafından paylaşılıyor.
  `ZiboBaseWidgetProvider.kt` (abstract, `HomeWidgetProvider`'ı extend ediyor) TEK render
  fonksiyonunu barındırıyor; sekiz somut alt sınıf (`ZiboGoalsWidgetProvider.kt` vb.) yalnızca
  `dataKeyPrefix`/`emoji`/`accentColor` değerlerini override ediyor — 4-6 satırlık dosyalar.
  Modül ikonu bir Material vector drawable DEĞİL, DÜZ BİR EMOJİ (🎯💧🙏😊✨🌙💰🎁) — yeni
  drawable asset'leri eklemeden/doğrulamadan, evrensel olarak desteklenen sistem fontu üzerinden
  düşük riskli bir çözüm. Rozet arka planı TEK bir düz beyaz oval drawable
  (`widget_badge_circle.xml`), her widget'ın kendi accent rengiyle ÇALIŞMA ZAMANINDA
  `RemoteViews.setInt(id, "setColorFilter", color)` ile tonlanıyor (RemoteViews'ın resmî olarak
  desteklediği bir "runtime tinting" yöntemi) — sekiz ayrı renkli drawable dosyası YAZILMADI.
  - **Renk paleti uygulamanın GERÇEK Material temasıyla piksel piksel eşleşiyor** — kart arka
    planı/metin renkleri `main.dart`'taki `_honeyCream`/`_espresso`/`_espressoSoft`/`_mustard`
    (açık) ve `_darkSurfaceContainer`/`_darkCream`/`_darkCreamSoft`/`_darkGold` (koyu) sabitlerinden
    ELLE kopyalandı (`android/app/src/main/res/values(-night)/colors.xml`) — bu dosyalar Dart
    tarafını okuyamıyor, senkron tutmak İLERİDE tema renkleri değişirse ELLE yapılmalı. Modül
    rozeti accent renkleri (`ZiboXWidgetProvider.kt`'deki `accentColor`) bazı modüllerde
    uygulamanın KENDİ kategori renkleriyle BİREBİR eşleşiyor (Şükran=`#4CAF50`
    `_gratitudeGreen` ile aynı, Para ve Birikim=`#1E88E5` money kategorisi mavisiyle aynı).
  - **AndroidManifest.xml'e sekiz `<receiver>` + MainActivity'ye bir `LAUNCH` intent-filter'ı
    eklendi** (`home_widget` paketinin resmi örneğindeki AYNI desen —
    `es.antonborri.home_widget.action.LAUNCH` — widget'a dokununca `HomeWidgetLaunchIntent`'in
    ürettiği `PendingIntent`'in AYNI `MainActivity` örneğine doğru yönlenmesi için).
  - **Tap davranışı BİLEREK BASİT tutuldu — widget'ın HERHANGİ bir yerine dokununca uygulama
    yalnızca AÇILIR, modüle özel bir derin bağlantı (deep link, ör. doğrudan Su Takibi ekranına
    gitme) YOK.** Bu, bildirime dokununca her zaman Ana Sayfa'ya giden mevcut push bildirimi
    deseniyle (bkz. "Push Bildirimleri" bölümü) AYNI kasıtlı basitlik tercihi — sekiz FARKLI
    modül ekranına derin bağlantı kurmak (her biri için ayrı bir `Uri`/route eşlemesi, `RootScreen`
    tarafında ayrıca ele alınması gereken sekiz yeni "widget'tan geldi" durumu) bu turun kapsamının
    ÖNEMLİ ölçüde ötesine geçen ayrı bir özellik olurdu; kullanıcı ileride isterse doğal bir sonraki
    adım olarak eklenebilir.
- **Veri akışı — Flutter'dan native'e TEK YÖNLÜ, `HomeWidgetSyncCoordinator` ile.** Sekiz
  provider'ın (GoalsProvider/WaterProvider/GratitudeProvider/MoodProvider/ManifestProvider/
  DreamJournalProvider/MoneyProvider/DailyRewardsProvider, + CurrencyProvider para birimi
  formatı için) HİÇBİRİNİN constructor'ı DEĞİŞTİRİLMEDİ — `HomeWidgetSyncCoordinator`
  (`RootScreen.initState()`'te BİR KEZ kurulan, hiçbir provider'a kalıcı bağımlı OLMAYAN bir
  koordinatör, `CostumeProvider.reconcileGoalUnlocks`'ın "constructor'dan değil parametre olarak
  al" felsefesiyle AYNI gerekçe) her provider'a DIŞARIDAN bir `addListener` ekleyip, İLGİLİ
  provider değiştiğinde YALNIZCA o modülün widget'ını `HomeWidgetService.pushStatus(...)` ile
  günceller — `HomeWidget.saveWidgetData` (native `SharedPreferences`'a `{prefix}_title`/
  `{prefix}_primary`/`{prefix}_secondary`/`{prefix}_progress` yazar) + `HomeWidget.updateWidget`
  (native `onUpdate`'i ANINDA tetikler) ikilisine ince bir sarmalayıcı. `LocaleProvider` de AYRICA
  dinleniyor (`syncAll()` çağırıyor) — kullanıcı dil değiştirirse widget metinleri de ANINDA yeni
  dile geçsin diye (widget başlıkları/alt metinleri `AppLocalizations`'tan geliyor, sabit Türkçe
  DEĞİL — üç dilin hepsinde çalışıyor).
  - **İçerik hesaplama mantığı (`widget_status.dart`) SEKİZ SAF fonksiyon** — provider nesnelerinin
    KENDİSİNİ değil yalnızca birkaç ilkel değeri alıyor (`goalsWidgetStatus(l10n, {doneToday,
    totalGoals})` gibi), bu sayede gerçek bir widget/provider kurmadan `flutter test`'te doğrudan
    test edilebiliyor. Her modülün "at a glance" özeti:
    - **Hedef Takibi:** bugün işaretlenen/toplam aktif hedef oranı (`3/5`) + ilerleme çubuğu.
    - **Su Takibi:** bugünkü bardak/şişe sayısı/hedef (`6/8`) + seçili birim etiketi + ilerleme.
    - **Şükran Günlüğü:** bugün tamamlandıysa `✓`, değilse `—` (ikili durum, ilerleme çubuğu YOK).
    - **Ruh Hali Takibi:** bugün seçilen `Mood.emoji`'si (`Mood` enum'unun ZATEN taşıdığı emoji,
      bkz. "Günlük Ruh Hali Takibi" bölümü) veya henüz seçilmediyse `—`.
    - **Manifest Günlüğü:** bugün eklenen giriş sayısı (0 dahil).
    - **Rüya Günlüğü:** TOPLAM (günlük değil — bu modülde günlük kilit yok) rüya sayısı.
    - **Para ve Birikim:** bu ayki NET tutar (gelir+birikim−harcama, `formatCurrencyAmount` ile
      kullanıcının seçtiği para birimi sembolüyle formatlı) — kapsam BİLEREK sadeleştirildi
      (`MoneyTrendChart`'ın tam grafiği/kategori kırılımı DEĞİL, tek bir özet sayı).
    - **Günlük Giriş Ödülleri:** `Gün X/7` + bugün alınıp alınmadığı + 7 günlük döngü ilerlemesi.
      `todayIndex` güvenilir-zaman anomalisiyle (bkz. "Firestore veri kalıcılığı" bölümündeki
      TrustedTimeProvider notları) döngü DIŞINA taşarsa `0..6` aralığına KIRPILIYOR — widget'ın
      asla "Gün 19/7" gibi anlamsız bir şey GÖSTERMEMESİ için ekstra bir güvenlik ağı.
- **`WidgetsScreen`** (YENİ, Ayarlar > Genel'deki "Ana Ekran Widget'ları" satırından push edilir)
  — sekiz modülü emoji/renk/başlıkla listeleyip her biri için bir "Ekle" butonu sunuyor;
  `HomeWidgetService.requestPin(module)` → `HomeWidget.requestPinWidget(androidName: ...)`
  (Android 8+, yalnızca bazı launcher'larda desteklenen `requestPinAppWidget` API'sinin sarmalayıcısı)
  — desteklenmiyorsa/reddedilirse SnackBar kullanıcıyı "ana ekranına uzun bas, Widget'lar
  listesinden Zibo'yu bul" akışına yönlendiriyor (bu HER ZAMAN çalışan, evrensel geri düşüş yolu).
- **Gerçek, çözülen İKİ hata (bu turda yakalanıp düzeltildi):**
  1. **`context.read<LocaleProvider>()`'ı `RootScreen.dispose()` İÇİNDE çağırmak** "Looking up a
     deactivated widget's ancestor is unsafe" hatasıyla ÇÖKÜYORDU (`flutter test`'te GERÇEKTEN
     yakalandı, ~40 test bu yüzden başarısız oldu) — `dispose()` çağrıldığında widget zaten
     deactivate ediliyor olabilir, bu anda YENİ bir `context.read`/`Provider.of` çağrısı GÜVENSİZ.
     **Düzeltme:** referans `initState`'te (güvenli bir zamanda) BİR KEZ okunup
     `_localeProviderForCleanup` alanında saklandı, `dispose()` yalnızca bu saklanan referansı
     kullanıyor. **Genelleştirilebilir kural: bir listener'ı `initState`'te `context.read<T>()` ile
     EKLEYEN bir State, o AYNI listener'ı `dispose()`'ta KALDIRIRKEN ASLA tekrar `context.read<T>()`
     ÇAĞIRMAMALI — ilk okumadaki referansı bir alanda saklayıp dispose'ta ONU kullanmalı.**
  2. **`flutter_test`'in `testWidgets` bloğu İÇİNDE çıplak `await Future<void>.delayed(Duration.
     zero)` çağırmak SONSUZA KADAR HANGLENIYOR** (gerçekten yakalandı — bir test dosyası dakikalarca
     "tamamlanmadı" durumunda kaldı, `timeout` ile zorla kesilip bisection'la kök nedene inildi).
     Kök neden: `testWidgets`'ın test gövdesi Flutter'ın kendi "fake async" test ortamında
     çalışıyor — gerçek bir `Future.delayed` (`Duration.zero` bile olsa) bu ortamda otomatik
     İLERLEMEZ, yalnızca `tester.pump()`/`pumpAndSettle()`/`tester.runAsync()` zamanı/microtask
     kuyruğunu güvenli şekilde ilerletebilir. **Bu, `goals_provider_test.dart` gibi DÜZ `test()`
     bloklarında (fake async SARMALAMASI YOK, gerçek async ortamı) YAYGIN VE GÜVENLİ olarak
     kullanılan `await Future<void>.delayed(Duration.zero)` desenini `testWidgets()` içine
     KÖRÜ KÖRÜNE taşımanın SESSİZCE (derleme hatası YOK, yalnızca çalışma zamanında sonsuz
     askıda kalma) kırıldığı somut bir örnek.** **Düzeltme:** o satır tamamen kaldırıldı — hemen
     ardından gelen `tester.pumpWidget(...)`/`await tester.pumpAndSettle()` zaten provider'ların
     `_loadFromPrefs()`'inin bekleyen microtask'larını güvenli şekilde flush ediyor, ayrı bir
     bekleyişe gerek YOKTU. **Genelleştirilebilir kural: `testWidgets()` içinde asenkron bir
     bekleyiş gerekiyorsa (bir provider'ın `_loadFromPrefs()`'i gibi), önce `tester.pump()`/
     `pumpAndSettle()`'ın YETİP yetmediğine bakın; GERÇEKTEN çıplak bir `Future.delayed` GEREKİYORSA
     bunu HER ZAMAN `tester.runAsync(() => Future.delayed(...))` içine sarın (bkz. "Test kalıpları"
     bölümündeki `RenderRepaintBoundary.toImage()` gotcha'sında ZATEN belgelenen AYNI desen) — asla
     `testWidgets` gövdesinde çıplak/sarmalanmamış bırakmayın.**
- **Test:** YENİ `test/widget_status_test.dart` (16 test — sekiz saf fonksiyonun HER biri, boş/dolu
  durumlar + `dailyRewardsWidgetStatus`'un güvenlik-ağı kırpma davranışı dahil), YENİ
  `test/home_widget_sync_coordinator_test.dart` (7 test — `syncAll` sekizini birden günceller,
  DÖRT temsili modülün [goals/water/dailyRewards/currency] KENDİ provider'ı değişince YALNIZCA
  kendi widget'ını güncellediği, `dispose()` sonrası hiçbir güncelleme tetiklenmediği — sekiz
  modülün TAMAMI değil, temsili bir alt küme + genel izolasyon garantisi; içerik hesaplamasının
  KENDİSİ zaten `widget_status_test.dart`'ta ayrı ve tam test ediliyor), YENİ
  `test/widgets_screen_test.dart` (3 test — sekiz modül kendi başlığıyla listeleniyor [gerçekçi
  test yüzeyine sığmadığı için `scrollUntilVisible` ile GERÇEK EKRAN sırasıyla doğrulanıyor, bkz.
  "Test kalıpları" bölümündeki tek-yönlü kaydırma gotcha'sı], "Ekle" doğru modülle `requestPin`
  çağırıyor, başarısızlıkta doğru mesaj). `widget_test.dart`'ın `_buildAppWithClock()` yardımcısına
  `CurrencyProvider`/`DreamJournalProvider`/`LocaleProvider`/`MoodProvider` eklendi — `RootScreen`
  artık bunları da `context.read` ettiği için (bkz. "Test kalıpları" bölümündeki genel provider
  kuralı), eklenmeseydi hata yalnızca ilgili testte değil ondan SONRAKİ TÜM testlerde görünürdü.
  **Toplam: 356 test.**
- **Native derleme + cihazda doğrulama:** `flutter build apk --debug` SORUNSUZ derlendi (yalnızca
  `home_widget`'ın da (Firebase/flutter_timezone gibi) Kotlin Gradle Plugin uyguladığına dair
  zararsız/bilgilendirici bir uyarı, hata DEĞİL). APK telefona kurulup `adb shell monkey` ile
  başlatıldı — çöküş izi yok, logcat'te FATAL EXCEPTION YOK. **`adb shell dumpsys package` ile
  SEKİZ widget receiver'ının da (`ZiboGoalsWidgetProvider`...`ZiboDailyRewardsWidgetProvider`)
  `APPWIDGET_UPDATE` intent-filter'ıyla doğru şekilde SİSTEME KAYITLI olduğu doğrulandı** — bu,
  sekizinin de telefonun widget seçicisinde (ana ekrana uzun basıp "Widget'lar") GERÇEKTEN
  görüneceğinin somut/otomatik bir kanıtı.
  - **Kullanıcının kendi cihazında GÖRSEL olarak doğrulaması gereken kısım** (native ana ekran
    chrome'u, Flutter'ın render ağacının TAMAMEN dışında — `flutter test`/web preview'un HİÇBİRİYLE
    doğrulanamaz, bu projenin native özelliklerindeki TÜM önceki "kullanıcı kendi cihazında
    doğrulamalı" notlarıyla AYNI kategori): Ayarlar > "Ana Ekran Widget'ları"ndan (veya doğrudan
    ana ekrana uzun basıp Widget'lar listesinden) sekiz widget'ın her birini eklemek, doğru
    emoji/renk/başlıkla göründüklerini, açık VE koyu sistem temasında kart renklerinin doğru
    çözüldüğünü (`values`/`values-night`), ilgili modülde bir işlem yapınca (ör. bir hedefi
    işaretlemek) widget'ın birkaç saniye içinde GÜNCELLENDİĞİNİ, ve widget'a dokununca uygulamanın
    açıldığını gözlemlemek.
- **2026 bug düzeltmesi — kullanıcı raporu: "uygulama içinde widget eklenmedi yazıyor, manuel
  olarak anasayfada ekleyince araç yüklenemiyor yazıyor."** İki AYRI, birbirinden BAĞIMSIZ gerçek
  bug — ikisi de gerçek cihazda (`adb logcat`) canlı teşhis edilip doğrulandı, kör tahmin
  YAPILMADI:
  1. **"Widget eklenmedi" (in-app "Ekle" butonu her zaman başarısız) — kök neden:
     `ZiboWidgetModule.androidProviderName` DEĞERLERİ `home_widget` paketinin native tarafının
     beklediği şekle uymuyordu.** `HomeWidgetPlugin.kt`'nin `updateWidget`/`requestPinWidget`
     handler'ları, `androidName`/`name` argümanı verildiğinde `Class.forName("${context.
     packageName}.${className}")` kuruyor — yani bu parametre YALNIZCA widget provider sınıfı
     uygulamanın KÖK paketinde (alt paket YOK) ise doğru çalışıyor. Bizim provider'larımız
     `com.dijitalkanka.dijital_kanka.widgets.*` ALT PAKETİNDE (bkz. yukarıdaki mimari notu) —
     `androidName: 'ZiboGoalsWidgetProvider'` vermek native tarafta `com.dijitalkanka.dijital_
     kanka.ZiboGoalsWidgetProvider`'ı (`.widgets.` OLMADAN, GERÇEKTE VAR OLMAYAN bir sınıf)
     aramaya çalışıp sessizce `ClassNotFoundException` fırlatıyordu — `HomeWidgetService`'in
     try/catch'i bunu yutup `requestPin()`'in her zaman `false` dönmesine yol açıyordu.
     **Düzeltme:** `ZiboWidgetModule`'e TAM NİTELİKLİ sınıf adını döndüren yeni bir
     `qualifiedAndroidName` getter'ı eklendi (`'com.dijitalkanka.dijital_kanka.widgets.
     $androidProviderName'`); `home_widget_service.dart`'taki HER İKİ çağrı (`HomeWidget.
     updateWidget`/`requestPinWidget`) `name:`/`androidName:` yerine `qualifiedAndroidName:`
     kullanacak şekilde değiştirildi (`Class.forName(qualifiedName ?: ...)` — verilen değeri
     OLDUĞU GİBİ kullanıyor, hiçbir birleştirme yapmıyor, bu yüzden paket yolu sorunu YOK).
  2. **"Araç yüklenemiyor" (manuel olarak ana ekrana eklenince) — kök neden: `widget_module.
     xml`'de boşluk için kullanılan ham bir `<View>` spacer, RemoteViews'ın inflate ETMEYE
     İZİN VERDİĞİ view sınıflarının whitelist'inde DEĞİL.** Gerçek cihazda `adb logcat` ile
     `com.miui.home` (launcher) sürecinin kendi `AppWidgetHostView` etiketi altında TAM stack
     trace'i yakalandı: `android.view.InflateException: ... Class not allowed to be inflated
     android.view.View` — bu, `Class not allowed`'ın kelimesi kelimesine söylediği gibi, MIUI'ye
     ÖZGÜ bir kısıtlama DEĞİL, `RemoteViews`'ın (bildirim VE widget'larda ortak) TÜM Android
     sürüm/launcher'larında geçerli, belgelenmiş bir mimari kısıtlaması — yalnızca sabit bir
     view sınıfı listesi (FrameLayout/LinearLayout/TextView/ImageView/ProgressBar vb.) inflate
     edilebiliyor, ham `android.view.View`/`Space` bu listede YOK. Bu hata bizim UYGULAMAMIZIN
     sürecinde DEĞİL, launcher'ın sürecinde (RemoteViews'ı ALICI taraf) oluştuğu için `com.
     dijitalkanka.dijital_kanka`'nın kendi logcat'inde HİÇBİR İZ bırakmıyordu — yalnızca
     `AppWidgetHostView`/`Launcher.Widget` etiketleriyle launcher'ın PID'inde görünüyordu, bu
     yüzden ilk aramalar (uygulamamızın kendi loglarına bakan) sonuçsuz kaldı. **Düzeltme:**
     ayrı spacer `<View>` KALDIRILDI, 8dp'lik boşluk bunun yerine hemen altındaki
     `widget_primary` `TextView`'ının `layout_marginTop`'una taşındı (TextView zaten
     RemoteViews'ın desteklediği bir sınıf, komşu elemanın margin'iyle AYNI görsel sonucu
     SIFIR ek view maliyetiyle veriyor). **Genelleştirilebilir kural: RemoteViews kullanan HER
     layout'ta (bildirimler DAHİL) boşluk için ASLA ham `<View>`/`<Space>` kullanmayın — komşu
     elemanın `layout_margin*`'ini kullanın; aksi halde hata yalnızca ALICI SÜREÇTE (launcher/
     sistem UI) oluşur ve GÖNDEREN uygulamanın kendi logcat'i TAMAMEN TEMİZ görünür, bu da teşhisi
     ciddi şekilde zorlaştırır.**
  - **Doğrulama — gerçek cihazda, İKİ AYRI derleme+kurulumla, canlı `adb logcat` ile:** İlk
    düzeltmeden (yalnızca `qualifiedAndroidName`) sonra `WidgetsScreen`'den "Ekle"ye basılınca
    widget artık GERÇEKTEN bağlanıyordu (`bindAppWidgetId`/`Bound widget` log satırları) AMA
    hemen ardından `AppWidgetHostView` üzerinde YUKARIDAKİ `InflateException` görüldü — bu, İKİ
    bug'ın BAĞIMSIZ olduğunu VE ilk düzeltmenin GERÇEKTEN işe yaradığını (aksi halde bind hiç
    gerçekleşmezdi) kanıtladı. İkinci düzeltmeden SONRA aynı akış (hem "Hedef Takibi" hem "Su
    Takibi" widget'ları için ayrı ayrı denendi) `logcat`'te HİÇBİR `AppWidgetHostView`/
    `InflateException` satırı ÜRETMEDEN tamamlandı, VE `WidgetsScreen`'in "Ekle" butonu artık
    gerçek `"Widget eklendi! Ana ekranını kontrol et."` başarı mesajını gösterdi (önceden HER
    ZAMAN "Widget eklenemedi" başarısızlık mesajı gösteriyordu). `flutter test` iki düzeltmeden
    sonra da tam yeşil (356/356) — hiçbir mevcut test bu iki dosyaya (`widget_module.dart`,
    `home_widget_service.dart`, `widget_module.xml`) doğrudan bağımlı olmadığı için regresyon
    riski taşımadı.
  - **Ders — bu proje genelinde tekrarlayan bir teşhis kalıbı:** native bir platform bileşeninin
    (widget/bildirim) render/uygulama HATASI, "gönderen" uygulamanın KENDİ sürecinde değil ALICI
    sistem sürecinde (launcher, sistem UI) oluşabilir — bu durumda `adb logcat`'i yalnızca kendi
    paket adınıza göre filtrelemek (`grep dijital_kanka`) hatayı TAMAMEN KAÇIRIR; ilgili sistem
    bileşeninin (`AppWidgetHostView`, `NotificationManagerService` vb.) kendi log etiketlerini de
    aramak GEREKİR — bu oturumda tam olarak bu genişletilmiş arama sayesinde bulundu.
- **2026 güncellemesi — görsel yeniden tasarım + DOKUZUNCU widget: "Zibo'nun Sözü".** Kullanıcı
  isteği (verbatim özet): "widget tasarımlarını Zibo görsellerini kullanarak daha güzel ve çeşitli
  yap... Zibo'nun motivasyon cümlelerinin olduğu widget de yapabilirsin, daha büyük widgetler
  yapabilirsin, Zibo'nun logosunu kullanabilirsin — sana bırakıyorum" (tasarım kararları bilerek
  asistana bırakıldı).
  - **Sekiz mevcut (kompakt) widget'ın paylaştığı `widget_module.xml` üç yönden zenginleştirildi:**
    1. **Rozetin arkasına soluk bir "halo"** — mevcut `widget_badge_circle.xml` drawable'ı DAHA
       BÜYÜK (36dp, eski 26dp'lik rozetin ETRAFINDA) VE modülün KENDİ `accentColor`'ının düşük
       opaklıklı (`alpha=40/255`) hâliyle tonlanıyor (`ZiboBaseWidgetProvider.withAlpha`, YENİ
       private yardımcı). Yeni bir renk sistemi İCAT EDİLMEDİ — sekiz modülün zaten farklı olan
       `accentColor`'ı burada İKİNCİ kez, daha GÖRÜNÜR bir şekilde kullanılıyor.
    2. **"Çeşitlilik" isteği — accent bar.** Önceki turda (bkz. yukarıdaki "Araç yüklenemiyor" bug
       düzeltmesi) ham `<View>` spacer'ın YERİNE geçen düz margin, şimdi modülün accent rengiyle
       DOLU ince (3dp) bir "accent bar"a (`R.id.widget_accent_bar`, bir `TextView`,
       `setInt(..., "setBackgroundColor", accentColor)` ile tonlanıyor) dönüştürüldü — sekiz
       widget artık yalnızca rozetin İÇİNDE değil, ETRAFINDA VE ALTINDA da kendi rengiyle ayırt
       ediliyor.
    3. **Zibo logosu — kartın sağ-alt köşesinde, ÇOK soluk (`alpha="0.18"`) bir marka imzası**
       (`@drawable/widget_zibo_logo`) — kullanıcının açık isteği. İçerikle YARIŞMASIN diye kasıtlı
       düşük opaklık ve küçük boyut (30×12dp) seçildi.
  - **DOKUZUNCU, DAHA BÜYÜK widget — "Zibo'nun Sözü" (`ZiboWidgetModule.motivation`).** Diğer
    sekizinin AKSİNE kendi ayrı native layout'u (`widget_motivation.xml`) VE provider sınıfı
    (`ZiboMotivationWidgetProvider.kt`, `ZiboBaseWidgetProvider`'ı EXTEND ETMİYOR — o sınıf
    `R.layout.widget_module`u sabit varsayıyor, bu widget'ın yapısı yeterince farklı) var:
    - **Varsayılan boyut 4×2 hücre** (`widget_info_motivation.xml`, `minWidth="250dp"`) — diğer
      sekizinin 2×2'sinden BİLEREK daha büyük, kullanıcının "daha büyük widgetler yapabilirsin"
      isteğinin doğrudan karşılığı.
    - **Gerçek bir Zibo karakter görseli** (`widget_zibo_character.png` — `assets/images/
      zibo_yeni.png`'nin `tool/prepare_widget_assets.dart` ile 420px yüksekliğe küçültülmüş hâli,
      widget belleği için makul bir boyutta tutuldu, orijinal 773×975'in tamamı DEĞİL) solda, sağda
      başlık + accent bar (diğer sekiziyle AYNI görsel dil) + çok satırlı (`maxLines="4"`) söz
      metni.
    - **İçerik — `HomeWidgetSyncCoordinator._syncMotivation()`** (YENİ metot): `syncAll()` her
      çağrıldığında (uygulama açılışı + dil değişimi — diğer sekiz widget'ın listener'ları
      `syncAll()`'ı TETİKLEMEDİĞİ için, bkz. sınıf dokümantasyonundaki güncellenmiş not, bu widget
      GÜRÜLTÜSÜZ bir sıklıkta tazeleniyor) `ziboMessagesForLocale(locale)` havuzundan (Ana Sayfa'nın
      KENDİ kullandığı AYNI 279 sözlük havuz — YENİ bir içerik havuzu YAZILMADI) rastgele bir söz
      seçip `applyAddressTerm(quote, profile.addressTerm, locale)` ile kullanıcının hitap tercihini
      UYGULUYOR (bkz. "Profil" bölümündeki "Hitap Tercihi" alt bölümü — 8 ekranın zaten kullandığı
      AYNI kişiselleştirme, widget'a da genişletildi). Bunun için koordinatör artık `ProfileProvider`
      (yeni required alan) VE test edilebilirlik için enjekte edilebilir bir `Random` (`CoinProvider`
      Şans Çarkı'ndaki AYNI desen) alıyor.
    - **`ZiboMotivationWidgetProvider`'ın accent rengi** yeni bir sabit renk İCAT ETMİYOR —
      `@color/widget_accent_default`i (uygulamanın zaten var olan "Zibo marka rengi" varsayılanı,
      açık/koyu temaya otomatik uyuyor) kullanıyor.
  - **Native asset hazırlığı — `tool/prepare_widget_assets.dart` (YENİ, tek seferlik görsel işleme
    betiği, `remove_bg.dart`/`clean_app_icon.dart` ile AYNI desen):** `zibo_splash_logo.png`'yi
    (zaten native/RemoteViews-uyumlu, splash ekranı için önceden hazırlanmış) `widget_zibo_logo.
    png` olarak kopyalıyor + `assets/images/zibo_yeni.png`'yi (773×975) 420px yüksekliğe küçültüp
    `widget_zibo_character.png` olarak kaydediyor — `dart run tool/prepare_widget_assets.dart`.
  - **`AndroidManifest.xml`'e dokuzuncu `<receiver>` eklendi** (`.widgets.
    ZiboMotivationWidgetProvider`, `widget_info_motivation` kaynağıyla) — diğer sekizle BİREBİR
    AYNI desen.
  - **Gerçek cihazda GÖRSEL doğrulama, canlı `adb logcat` ile — DÖRT farklı widget türü, SIFIR
    hata:** APK yeniden derlenip telefona kurulup (`adb install -r`, veri korunarak) test edildi.
    Uygulama açılışında Hedef Takibi/Su Takibi widget'larının (önceki turdan zaten ekliydi) YENİ
    tasarımla sorunsuz yeniden çizildiği (`AppWidgetHostView`/`InflateException` log'u SIFIR)
    doğrulandı. Ardından "Zibo'nun Sözü" widget'ı gerçekten eklenip **bir EKRAN GÖRÜNTÜSÜYLE**
    Zibo karakter görseli + "Zibo'nun Sözü" başlığı + accent bar + gerçek bir söz ("Emek boşa
    gitmez can, er ya da geç karşılığını bulur.") ile DOĞRU render olduğu somut olarak kanıtlandı.
    Test sırasındaki kazara dokunuşlar Su Takibi ve Şükran Günlüğü widget'larının da (farklı
    zamanlarda) eklenip tıklandığını tetikledi — `adb logcat`'te bu DÖRT widget türünün (Hedef
    Takibi/Su Takibi/Şükran Günlüğü/Zibo'nun Sözü) HİÇBİRİNDE `AppWidgetHostView` hata satırı VEYA
    `InflateException` YOKTU, yalnızca zararsız `onclick` bilgi logları — yeni tasarımın (halo/
    accent bar/logo/büyük karakter görseli) RemoteViews'ın kısıtlı view whitelist'iyle TAM uyumlu
    olduğunun somut kanıtı. **Kazara birkaç widget eklenip/kaldırılmış olabilir** (test sırasındaki
    dokunuş/kaydırma hareketleri MIUI'nin kendi widget kaldırma jestini tetiklemiş olabilir) —
    kullanıcının kendi ana ekranını kontrol edip istediği widget'ları elle düzenlemesi gerekebilir.
  - **Test:** `test/widget_status_test.dart`'a `motivationWidgetStatus` testi,
    `test/home_widget_sync_coordinator_test.dart`'a `ProfileProvider` + enjekte edilebilir
    `Random` (`_FixedRandom`, `CoinProvider` testlerindeki AYNI desen) ile "syncAll havuzdan
    deterministik bir söz seçip gönderir" testi, `test/widgets_screen_test.dart`'a dokuzuncu
    modülün satırı eklendi. **Gotcha (bu turda yakalandı) — dokuzuncu karta kadar kaydırmak
    `ListView`'ın Sliver tabanlı lazy-build/cache-eviction'ını tetikleyip ÖNCEKİ (artık ekrandan
    çok uzak) kartların `FilledButton`'larını inşa edilmiş ağaçtan ÇIKARDI:** eski test tüm
    kaydırma BİTTİKTEN SONRA TEK bir global `findsNWidgets(9)` sayımı yapıyordu — sekiz modülle
    çalışıyordu ama dokuzuncuya kaydırılınca yalnızca 8 buton bulundu (GERÇEK bir uygulama hatası
    DEĞİL, yalnızca o anki cache penceresi). **Çözüm:** her başlık için "Ekle" butonunu o ANDA
    (`scrollUntilVisible`'dan HEMEN sonra, `find.ancestor(of: find.text(title), matching: find.
    byType(Card))` ile o KARTA özel) doğrulamak — toplu/gecikmeli bir sayıma güvenmemek. `flutter
    test` tam yeşil: **358/358.**
- **2026 İKİNCİ güncelleme — büyük bir yeniden yapılanma: beş widget kaldırıldı, carousel'ler
  eklendi, görsel tasarım profesyonelleştirildi.** Kullanıcı isteği (verbatim özet): "widget
  kısmında Zibo motivasyon sözleri 3 dakikada bir değişsin, Zibo logosunu kullan, arka planı
  güzelleştir, widget'in modellemesini daha profesyonel yap; ana ekrana basılı tutup widget
  eklerken diğer uygulamaların widget'i görünüyor ama Zibo'da sadece app ikonu görünüyor onu
  düzelt; uygulama içinden otomatik widget eklenmiyor onu düzelt; bazı modüllerin widget'i
  gereksiz duruyor (Hedef Takibi gereksiz, Rüya/Şükran/vs.) bunları komple kaldırıp kullanıcının
  profil kısmındaki istatistiklerini sıra sıra animasyonla gösteren bir widget yapalım; Zibo
  logosu ve Zibo görselini kullanmayı unutma." `AskUserQuestion` ile netleştirilen kesin kaldır/
  tut listesi: **KALDIRILDI** Hedef Takibi, Rüya Günlüğü, Şükran Günlüğü, Ruh Hali Takibi,
  Manifest Günlüğü (5 widget) — **KALDI** Su Takibi ("güzel, o kalsın"), Zibo'nun Sözü, Para ve
  Birikim, Günlük Giriş Ödülleri — **YENİ EKLENDİ** "İstatistiklerim" (Profil ekranındaki 4
  kategoriyi döndüren carousel).
  - **`HomeWidgetService`'e YENİ, paylaşılan bir `pushCarousel(module, {title, items})` API'si
    eklendi** — `CarouselItem` (YENİ, `home_widget_service.dart`) `{value, label?, progress?,
    hasData}` taşıyan tek bir veri şekli, hem "Zibo'nun Sözü" (yalnızca `value` dolu) HEM
    "İstatistiklerim" (dördü de dolu) tarafından PAYLAŞILIYOR. Native tarafta TEK bir anahtar
    sözleşmesi (`{prefix}_itemCount` + `{prefix}_item{i}_value`/`_label`/`_progress`/`_hasData`)
    — önceki taslakta bu iki widget FARKLI anahtar isimleri (`quoteCount`/`quote{i}` vs.
    `categoryCount`/`cat{i}_label` vb.) kullanıyordu, `pushCarousel` yazılırken TEK, tutarlı bir
    şemaya birleştirildi (hem Dart hem her iki Kotlin provider'ı güncellendi) — ileride üçüncü bir
    carousel widget'ı eklenirse sıfırdan bir anahtar şeması icat etmeye gerek kalmayacak.
  - **`ZiboMotivationWidgetProvider`/`ZiboProfileStatsWidgetProvider` — `RemoteViews.addView(...)`
    ile ÇALIŞMA ZAMANINDA bir `ViewFlipper`'a N sayfa ekleyen desen.** `widget_motivation.xml`/
    `widget_profile_stats.xml`'deki `ViewFlipper` (`android:flipInterval` — motivasyon 180000ms/3dk,
    istatistikler 6000ms/6sn — `autoStart="true"`) TAMAMEN NATIVE (launcher sürecinin kendi
    `Handler`-tabanlı zamanlayıcısı) döndüğü için Dart/uygulama HİÇ AÇIK OLMASA BİLE, hatta
    `updatePeriodMillis`'in Android'in dayattığı 30 dakikalık ALT SINIRINDAN TAMAMEN BAĞIMSIZ
    olarak dönmeye devam ediyor — kullanıcının "3 dakikada bir değişsin" isteğini `WorkManager`/
    arka plan görevi gibi ağır bir mekanizma OLMADAN karşılıyor.
    - **Bu teknik gerçek cihazda doğrulandı — RemoteViews'ın kısıtlı inflate whitelist'ine karşı
      SIFIR risk taşıyor, çünkü `ViewFlipper` (LinearLayout/FrameLayout gibi) whitelist'te
      ZATEN VAR olan bir sınıf; bu projenin iki ÖNCEKİ gerçek RemoteViews çökmesi (ham `<View>`
      spacer, `ProgressBar.setProgressTintList` reflection'ı) HER İKİSİ de whitelist'te OLMAYAN
      bir sınıf/metot kullanmaktan kaynaklanmıştı — `ViewFlipper` bu kategoriye GİRMİYOR.**
      Uygulama içi "Ekle" akışı üç widget türü için (Su Takibi/kompakt, Zibo'nun Sözü/motivasyon
      carousel, İstatistiklerim/carousel) ayrı ayrı denenip HER SEFERİNDE `adb logcat`'te
      `AppWidgetHostView`/`InflateException`/`FATAL EXCEPTION` etiketleri SIFIR sonuç verdi —
      bu, projenin önceki iki gerçek çökmesinin AYNI teşhis yöntemiyle (bkz. yukarıdaki "Araç
      yüklenemiyor" bug düzeltmesi notu) doğrulandığı, negatif ama güvenilir bir kanıt.
  - **Kaldırılan beş widget'ın Kotlin provider'ları + `widget_info_*.xml`'leri SİLİNDİ**
    (`ZiboGoalsWidgetProvider.kt` vb.), `AndroidManifest.xml`'deki 5 `<receiver>` kaldırıldı.
    `ZiboBaseWidgetProvider`'ı KULLANAN modül sayısı sekizden ÜÇE düştü (Su Takibi/Para ve
    Birikim/Günlük Giriş Ödülleri — "Zibo'nun Sözü"/"İstatistiklerim" kendi AYRI carousel
    layout'larını kullanıyor, bu paylaşılan sınıfı hiç extend ETMİYOR).
  - **`lib/utils/widget_module.dart`** — `goals`/`gratitude`/`mood`/`manifest`/`dream` enum
    değerleri TAMAMEN KALDIRILDI, yerine `profileStats` geldi. **`lib/utils/widget_status.dart`**
    — beş modülün saf durum fonksiyonu (`goalsWidgetStatus` vb.) KOMPLE KALDIRILDI (kullanıcının
    "komple kaldır" isteği — bu proje genelinde "kullanılmayan ARB anahtarını SİLME" konvansiyonu
    ARB metinleri için geçerli, ama kod-seviyesi ölü fonksiyonlar için değil, bu yüzden
    `widget_status.dart`'taki fonksiyonlar silindi, ARB anahtarları [`widgetGoalsEmptyHint` vb.]
    İSE bilerek dosyalarda BIRAKILDI).
  - **`HomeWidgetSyncCoordinator`'ın büyük yeniden yazımı** — `mood`/`dream` alanları+parametreleri
    TAMAMEN kaldırıldı (`ProfileStats.compute()` bu ikisini hiç GEREKTİRMİYOR); `goals`/
    `gratitude`/`manifest` alanları KALDI ama artık kendi `addListener`'ları YOK — yalnızca
    [`_syncProfileStats()`]'ın (SADECE `syncAll()` içinde, uygulama açılışı + dil değişiminde
    tetiklenen) `ProfileStats.compute(...)` girdisi. **Pratik sonuç:** bir hedefi işaretlemek/bir
    şükran kaydı eklemek ARTIK anlık bir widget güncellemesi TETİKLEMİYOR — İstatistiklerim
    widget'ı yalnızca bir sonraki `syncAll()`'da (açılış/dil değişimi) güncel puanları görür. Bu,
    `ProfileStats.compute()`'un zaten "o anki canlı duruma göre HER SEFERİNDE yeniden hesaplanan"
    bir fonksiyon olması ve dört kaynak provider'ın HER BİRİNE ayrı ayrı `addListener` eklemenin
    (widget'ın kendisi zaten dakikalar mertebesinde güncellenen bir "at a glance" özet olduğu için)
    gereksiz karmaşıklık eklemesi nedeniyle BİLİNÇLİ bir basitleştirme — `_syncMotivation()`'ın
    ZATEN aynı "yalnızca syncAll'da tazelen" deseninde olması (bkz. sınıfın 2026 İLK güncelleme
    notu) bu kararla tutarlı.
  - **`_syncMotivation()` — TEK sözden `pushCarousel`'e geçti.** Havuzdan (`ziboMessagesForLocale`,
    279 söz) `_motivationQuoteCount` (8) FARKLI söz `shuffle(_random)` ile seçilip her biri
    `applyAddressTerm` (hitap tercihi) ile kişiselleştirilip TEK seferde gönderiliyor —
    `CoinProvider`'ın Şans Çarkı'nda kullandığı AYNI enjekte edilebilir `Random` deseni testte
    deterministik bir küme doğrulamayı sağlıyor (belirli bir Fisher-Yates SIRASI değil, kümenin
    KENDİSİ + tekrarsızlığı test ediliyor — `shuffle()`'ın iç algoritmasına bağımlı KIRILGAN bir
    beklenti kurulmadı).
  - **YENİ `_syncProfileStats()`** — `ProfileStats.compute(money:, gratitude:, manifest:, goals:,
    water:, now:)`'u ÇAĞIRIP dört `CategoryStat`'ı `CarouselItem`'a çeviriyor: `label` =
    `lib/widgets/profile_stat_card.dart`'taki AYNI id→ARB-getter eşlemesi (`_profileStatTitle`,
    KASITLI bir küçük duplikasyon — Profil ekranındaki `_title()` metoduyla BİREBİR aynı switch,
    ayrı bir paylaşılan yardımcıya çıkarmaya değmeyecek kadar küçük), `value` = `hasData` ise
    `"{score.toStringAsFixed(1)}/10"` değilse `"—"`, `progress` = `hasData` ise puanın 0-100
    yüzdesi değilse `null`.
  - **Görsel yeniden tasarım — `widget_module.xml` (kompakt üçlü) üç yönden zenginleştirildi:**
    (1) rozetin arkasına modülün KENDİ accent renginin düşük-opaklıklı ("halo") hâli — yeni bir
    renk sistemi İCAT EDİLMEDİ, mevcut `accentColor` altyapısı yeniden kullanıldı; (2) eski ham
    `<View>` spacer'ın (bkz. "Araç yüklenemiyor" bug düzeltmesi) YERİNE geçen düz margin, modülün
    rengiyle dolu ince bir "accent bar"a (bir `TextView`, RemoteViews-güvenli) dönüştürüldü; (3)
    kartın sağ-alt köşesine soluk (`alpha=0.18`) bir Zibo logosu eklendi. "Zibo'nun Sözü"/
    "İstatistiklerim" AYRICA gerçek bir Zibo karakter görseli (`widget_zibo_character.png`) + AYNI
    logo/accent-bar dilini paylaşıyor — kullanıcının "Zibo logosu ve Zibo görselini kullanmayı
    unutma" isteği hem kompakt hem büyük widget'larda karşılandı.
  - **Arka plan — düz renkten köşegen gradyana.** `widget_background.xml`'deki `<solid>` bir
    `<gradient android:angle="135">`'e çevrildi (`widget_card_gradient_start/end`, hem
    `values/colors.xml` hem `values-night/colors.xml`'de tanımlı) — "arka planı güzelleştir"
    isteğinin doğrudan karşılığı, TÜM widget'lar (5'i de) bu paylaşılan drawable'ı kullanıyor.
  - **`tool/prepare_widget_assets.dart`** (YENİ) — `zibo_splash_logo.png`'yi `widget_zibo_logo.png`
    olarak kopyalayıp `assets/images/zibo_yeni.png`'yi (773×975) 420px yüksekliğe küçültüp
    `widget_zibo_character.png` olarak kaydeden tek seferlik görsel betiği (`remove_bg.dart` ile
    AYNI desen).
  - **Widget picker önizleme sorunu ("her widget kendi nasılsa öyle görünsün") — İKİ AYRI
    doğrulama.** (a) `android:previewLayout` (API 31+) TÜM beş `widget_info_*.xml`'de tanımlı —
    her ikisi de gerçek layout'u (`tools:text` yer tutucularıyla) `initialLayout` ile AYNI
    dosyaya işaret ediyor, ek bir statik `previewImage` PNG'si GEREKMEDİ. (b) uygulama içi "Ekle"
    ekranı (`WidgetsScreen`) her modül için KENDİ emoji/renk kombinasyonunu (`_presentationFor`)
    doğru gösteriyor — statik/manuel olarak `flutter test`'te (`widgets_screen_test.dart`)
    doğrulandı. **Manuel "ana ekrana uzun bas → Widget'lar" akışının GÖRSEL doğrulaması** (gerçek
    launcher'ın previewLayout'u render edip etmediği) bu turda TAMAMLANAMADI — bkz. altta.
  - **KRİTİK bulgu — "uygulama içinden otomatik widget eklenmiyor" raporu YENİDEN İNCELENDİ,
    KOD SEVİYESİNDE zaten DÜZELTİLMİŞ olduğu doğrulandı, ama gerçek cihazda İKİNCİ, FARKLI bir
    sınırlama keşfedildi.** `WidgetsScreen`'in "Ekle" butonuna (Su Takibi/Zibo'nun Sözü/
    İstatistiklerim için ayrı ayrı) basılınca `HomeWidget.requestPinWidget(qualifiedAndroidName:
    ...)` HER SEFERİNDE `true` döndü ve `"Widget eklendi! Ana ekranını kontrol et."` başarı
    mesajı gösterildi (bkz. Phase 2'nin `qualifiedAndroidName` düzeltmesi — bu HÂLÂ doğru
    çalışıyor). **AMA `adb shell dumpsys appwidget`'in `Widgets:`/`Hosts:` bölümleri incelenince**
    hiçbir Zibo widget'ının GERÇEKTEN bağlanmadığı (`appWidgetId` atanmadığı) görüldü — sistemde
    yalnızca ÖNCEDEN var olan tek bir (Duolingo) widget kaydı vardı, üç ayrı "Ekle" denemesinden
    (isolate edilmiş, tek tek, aralarında `dumpsys` kontrolüyle) SONRA bile widget sayısı
    `1`'de sabit kaldı. `dumpsys window`'daki `mCurrentFocus` da her denemede uygulamanın KENDİ
    `MainActivity`'sinde kaldı — sistemin/launcher'ın bir onay diyaloğu (`PinAppWidgetActivity`
    gibi) HİÇ açılmadı. **Bu, `AppWidgetManager.requestPinAppWidget()`'ın bu MIUI launcher
    sürümünde `isRequestPinAppWidgetSupported()`'ı `true` döndürmesine RAĞMEN isteği SESSİZCE
    no-op bıraktığı, bilinen bir OEM launcher kısıtlaması sınıfı** — kodumuzun (Dart VEYA Kotlin
    tarafının) HİÇBİR şekilde tespit edemeyeceği/atlatamayacağı bir davranış, çünkü API'nin
    KENDİSİ hatasız `true` dönüyor (`isRequestPinWidgetSupported()` de `true`). **Bu, kullanıcının
    Phase 2'de bildirdiği "widget eklenmedi" hatasından TAMAMEN FARKLI bir sınıf** — o zamanki
    hata `ClassNotFoundException`'a bağlı bir gerçek KOD hatasıydı (düzeltildi, hâlâ düzeltilmiş
    durumda); bu seferki, kodun DOĞRU davrandığı ama OS/launcher'ın isteği tamamlamadığı bir
    durum. **Kullanıcının kendi cihazında kontrol etmesi gereken:** "Ekle" butonuna bastıktan
    SONRA gerçekten ana ekranına gidip widget'ın göründüğünü doğrulamak — görünmüyorsa, TEK
    güvenilir yol her zaman "ana ekrana uzun bas → Widget'lar → Zibo" manuel akışı (bu akışın
    KENDİSİ Phase 2'de ayrı bir bug'dan — ham `<View>` spacer inflate çökmesi — düzeltildi ve o
    düzeltme bu turda da geçerliliğini koruyor, yalnızca GÖRSEL olarak launcher üzerinden
    doğrulanamadı — bkz. altta "yapılamayan doğrulama" notu).
  - **YAPILAMAYAN doğrulama — gerçek launcher'da manuel pinleme + previewLayout'un GÖRSEL
    doğrulaması.** Bu MIUI launcher'ının "ana ekrana uzun bas → Widget'lar" akışı, `adb shell
    input tap`/`swipe` ile sentezlenen dokunuşlara TUTARSIZ tepki verdi (bazen düğmeye
    dokunmak yerine bir uygulama simgesini "seçili" duruma getirdi, bir kez yanlışlıkla bir
    uygulamayı açtı) — bu, kullanıcının GERÇEK, kişisel ana ekranı/uygulamaları üzerinde
    (rastgele bir uygulamanın yanlışlıkla kaldırılması RİSKİ dahil) güvenle devam ETTİRİLEMEYECEK
    kadar öngörülemez hale gelince, bu proje genelinde zaten belgelenmiş "gerçek cihaz paylaşım
    riski" prensibiyle (bkz. "Hedef Tamamlama Kutlaması" bölümündeki AYNI temkinli durma kararı)
    TUTARLI şekilde durduruldu — hiçbir uygulama/veri zarar GÖRMEDİ (her adımda `dumpsys window`
    ile odak kontrol edildi, hiçbir silme İŞLEMİ ONAYLANMADI), ama previewLayout'un GERÇEKTEN
    "her widget kendi nasılsa öyle görünüyor" sonucunu verip vermediği yalnızca STATİK XML
    incelemesiyle (doğru yapılandırıldığı doğrulandı) kapsandı, CANLI bir launcher ekran
    görüntüsüyle DEĞİL. **Kullanıcının kendi cihazında elle tamamlaması gereken tek adım:** ana
    ekrana uzun basıp Widget'lar listesinden Zibo'yu bulup her 5 widget'ın önizlemesinin
    (özellikle "Zibo'nun Sözü"/"İstatistiklerim" — gerçek karakter görseli + söz/istatistik
    metniyle) generic bir uygulama ikonu DEĞİL, kendi gerçek tasarımıyla göründüğünü, ve ekleyip
    3 dakika (motivasyon) / 6 saniye (istatistikler) bekleyip sözlerin/kategorilerin gerçekten
    OTOMATİK döndüğünü gözlemlemek.
  - **Test:** `widget_status_test.dart`'tan beş obsolete `group` SİLİNDİ (yalnızca `waterWidgetStatus`/
    `moneyWidgetStatus`/`dailyRewardsWidgetStatus`/`motivationWidgetStatus` kaldı).
    `home_widget_sync_coordinator_test.dart` TAMAMEN yeniden yazıldı — `_RecordingHomeWidgetService`
    artık hem `statusCalls` hem `carouselCalls` iki AYRI liste tutuyor; yeni testler: `syncAll`
    TÜM beş modülü günceller, motivasyon carousel'i havuzdan 8 FARKLI söz gönderir (kümenin
    KENDİSİ + üyeliği doğrulanıyor, sıra DEĞİL), istatistikler carousel'i veri yokken dört
    kategoriyi `hasData: false`/`"—"` ile gönderir, veri eklenip `syncAll` TEKRAR çağrılınca
    günceller, `GoalsProvider` değişimi ARTIK hiçbir ANLIK güncelleme TETİKLEMEZ (mimari
    değişikliğin doğrudan kanıtı). `widgets_screen_test.dart`'taki `titlesInOrder` 9 modülden
    5'e (`Su Takibi`/`Para ve Birikim`/`Günlük Giriş Ödülleri`/`Zibo'nun Sözü`/`İstatistiklerim`)
    güncellendi, ilk "Ekle" butonunun artık `ZiboWidgetModule.water`'a karşılık geldiği
    doğrulandı (eskiden `goals`'tı). ARB'ye `widgetTitleProfileStats` (TR: "İstatistiklerim",
    EN: "My Stats", ES: "Mis Estadísticas") eklenip `flutter gen-l10n` çalıştırıldı. `flutter
    test` tam yeşil: **350/350** (9 test net azaldı — 5 obsolete widget'ın 12 durumu SİLİNDİ, YENİ
    carousel/profileStats testleri EKLENDİ, net fark negatif çünkü kaldırılan testler eklenenden
    fazlaydı).
  - **Gerçek cihazda doğrulama — build+kurulum+üç bağımsız "Ekle" denemesi + geniş kapsamlı
    logcat taraması, SIFIR çökme/InflateException (uygulamanın KENDİSİNDEN VEYA launcher/
    AppWidgetHost sürecinden).** `flutter build apk --debug` + `adb install -r` (veri korunarak)
    + `adb shell am start` ile açılış → `AndroidManifest.xml`'in gerçekten 5 receiver'a
    (`ZiboWaterWidgetProvider`/`ZiboMoneyWidgetProvider`/`ZiboDailyRewardsWidgetProvider`/
    `ZiboMotivationWidgetProvider`/`ZiboProfileStatsWidgetProvider`) indiği doğrulandı; Ayarlar >
    "Ana Ekran Widget'ları" ekranı beş modülü doğru emoji/renk/sırayla listeledi; "Ekle"
    butonlarının HER BİRİ (su/motivasyon/istatistikler) başarı mesajı gösterdi, hiçbiri
    `AppWidgetHostView`/`InflateException` ÜRETMEDİ. Yukarıdaki iki "YAPILAMAYAN"/"KRİTİK bulgu"
    notunda açıklanan kısıtlamalar HARİÇ, bu turun teknik risklerinin (ViewFlipper güvenliği,
    kod-seviyesi Ekle akışı, layout/kaynak eksiksizliği) TAMAMI olumlu sonuçlandı.
- **2026 ÜÇÜNCÜ güncelleme — kullanıcı gerçek cihazda widget'ları test edip beş ayrı bulgu
  bildirdi: logo çok soluk, İstatistiklerim widget'ı çalışmıyor, widget'lar "durgun" (animasyon
  eksik), arka plan amatörce duruyor (Zibo'nun Z harfini kullanan bir doku önerildi), ve
  uygulama içindeki "Ekle" akışı çalışmıyor — EKRAN GÖRÜNTÜSÜYLE kanıtlandı ki widget seçici
  Zibo'nun BEŞ widget'ı için de yalnızca GENEL UYGULAMA İKONUNU gösteriyordu (diğer uygulamaların
  — Hedef Takibi/Telegram/İşCep — widget'ları KENDİ gerçek önizlemeleriyle listelenirken).**
  - **1) Logo opaklığı** — `widget_module.xml`/`widget_motivation.xml`/`widget_profile_stats.xml`
    üçünde de `alpha=0.18`/30-34dp'lik logo `alpha=0.5`/42-48dp'ye büyütüldü — hâlâ ana metnin
    ÜSTÜNE binmeyecek kadar geride ama artık net seçilebiliyor.
  - **2) "İstatistiklerim çalışmıyor" — KÖK NEDEN: carousel'ler YALNIZCA `syncAll()`'da
    (uygulama açılışı/dil değişimi) tazeleniyordu, widget'ı UYGULAMA ZATEN AÇIKKEN (ör. arka
    planda) manuel olarak ana ekrana eklemek bir SONRAKİ tam soğuk başlangıca kadar HİÇ taze veri
    GÖRMÜYORDU.** Düzeltme: `RootScreen.didChangeAppLifecycleState`'e, `touchLastActive`'in
    KULLANDIĞI AYNI `AppLifecycleState.resumed` tetikleyicisine `_homeWidgetSync?.syncAll()`
    eklendi — uygulama HER öne gelişte (yani "widget'ı ekleyip uygulamaya geri döndüğün an")
    carousel'ler de tazeleniyor, ek bir maliyeti yok (ikisi de ucuz, saf hesaplamalar).
  - **3) "Widgetler durgun" — ViewFlipper geçişleri düz `fade_in`/`fade_out`'tan hafif bir
    kayma+solma birleşimine (YENİ `res/anim/widget_page_in.xml`/`widget_page_out.xml`, `<set>`
    içinde `<translate>` + `<alpha>`, 420ms) çevrildi** — RemoteViews'ın inflate kısıtlamasıyla
    İLGİSİZ (bir VIEW SINIFI değil, standart bir animasyon KAYNAĞI). "İstatistiklerim"in
    `flipInterval`'i de 6000ms→4500ms'e düşürüldü (daha görünür hareket) — "Zibo'nun Sözü"nün
    180000ms'i (3 dakika) kullanıcının AÇIK isteği olduğu için BİLEREK DOKUNULMADI.
    **RemoteViews'ın gerçek animasyon kısıtı:** sürekli/nabız tarzı bir animasyon (ör. halo'nun
    yanıp sönmesi) `ViewFlipper` DIŞINDA teknik olarak MÜMKÜN DEĞİL (RemoteViews özel View'lara/
    per-frame güncellemeye izin vermiyor) — bu yüzden animasyon zenginliği yalnızca MEVCUT iki
    carousel'in geçiş kalitesine yatırıldı, kompakt üçlüye (Su Takibi/Para ve Birikim/Günlük Giriş
    Ödülleri) eklenebilecek RemoteViews-güvenli bir sürekli animasyon YOK.
  - **4) Arka plan — "Zibo'nun Z harfini kullanan, bolca+blurlanmış bir doku" isteği,
    `tool/generate_widget_z_pattern.dart` (YENİ) ile karşılandı.** "Z" harfleri font/BitmapFont'a
    GEREK KALMADAN saf geometriyle çiziliyor (bir Z zaten yalnızca üç doğru parçası — üst yatay,
    çapraz, alt yatay — `img.drawLine` ile, rastgele boyut/açı/konumda ~55 adet). **Alfa kontrolü
    İKİ AŞAMALI, kasıtlı dolaylı:** çizim TAM OPAK yapılıp `img.gaussianBlur` (radius 16) ile
    blurlanıyor, SONRA bütün görselin alfa kanalı TEK bir çarpanla (`_finalAlphaScale = 0.34`)
    aşağı çekiliyor — `drawLine`'ın `thickness`'le birleşince KISMİ alfa değerlerini güvenilir
    blend ETMEDİĞİ (ilk denemede metnin okunmasını zorlaştıracak kadar KOYU/net çıktığı) elle
    görsel karşılaştırmayla YAKALANIP bu iki-aşamalı yaklaşıma geçildi. AÇIK/KOYU tema için AYRI
    renkte (espresso/altın) İKİ PNG üretilip `drawable-nodpi`/`drawable-night-nodpi`'ye kaydedildi
    — Z-doku dosyasıyla AYNI ada sahip olduğu için gece/gündüz seçimi Android'in kendi resource
    qualifier mekanizmasıyla OTOMATİK. `widget_background.xml` düz gradyandan bir
    `<layer-list>`'e çevrildi (gradyan katmanı + `widget_zibo_z_pattern_tiled.xml`'in [YENİ,
    `<bitmap tileModeX/Y="repeat">`] TEKRARLAYAN doku katmanı) — TÜM beş widget bu paylaşılan
    drawable'ı kullandığı için tek bir değişiklik hepsine yayıldı.
    - **2026 DÖRDÜNCÜ güncelleme — DENENDİ, KULLANICI GERÇEK CİHAZDA GÖRÜP REDDETTİ, TAMAMEN GERİ
      ALINDI.** Kullanıcının net ifadesi: "widgetin arka planı çok kötü öyle olmasın kaldıralım o
      blurlu z şeklini." `widget_background.xml` düz gradyana GERİ DÖNDÜRÜLDÜ (`<layer-list>`
      kaldırıldı); `widget_zibo_z_pattern_tiled.xml`, iki `widget_zibo_z_pattern.png` (açık/koyu)
      ve onları üreten `tool/generate_widget_z_pattern.dart` TAMAMEN SİLİNDİ (geri getirmeye
      değecek bir asset değil — ihtiyaç olursa git geçmişinden kurtarılabilir). **Beş widget'ın
      `previewImage` PNG'lerinde de (bkz. altta "AYRI, kritik bir bulgu") Z-dokusu vardı** — bu
      PNG'ler `tool/compose_widget_previews.dart` ile üretimin İKİNCİ (masaüstü) aşamasında
      bindiriliyordu; dokuyu "çıkarmak" piksel-matematiksel olarak GERİ ALINAMAZ bir işlem olduğu
      için (kompozisyon geri döndürülemez), `lib/widget_preview_generator_main.dart`
      (değişmedi, hiç Z-doku İÇERMİYORDU zaten) cihazda TEKRAR çalıştırılıp on temiz temel PNG
      yeniden üretildi, `compose_widget_previews.dart`'IN KENDİSİ de Z-doku bindirme adımı
      TAMAMEN kaldırılacak şekilde güncellendi (artık YALNIZCA Zibo logosunu bindiriyor) — sonra
      bu güncellenmiş betikle previewImage'lar yeniden oluşturuldu. Her iki betik de (`lib/
      widget_preview_generator_main.dart`, `tool/compose_widget_previews.dart`) HÂLÂ KORUNUYOR
      (yalnızca logo bindirme adımı için hâlâ gerekli, widget tasarımı ileride tekrar değişirse
      yeniden çalıştırılabilir) — yalnızca Z-doku'ya ÖZGÜ üçlü (generator script + tiled drawable +
      PNG'ler) silindi.
  - **5) "Uygulama içindeki Ekle çalışmıyor" — BİLEREK "düzeltilmedi", YERİNE YÖNLENDİRME
    getirildi.** Önceki turda `adb dumpsys appwidget` ile KANITLANMIŞTI ki `requestPinWidget()`
    bu MIUI launcher'ında `true` DÖNSE BİLE widget'ı GERÇEKTEN bağlamıyor — bu API'nin
    KENDİSİ hatasız `true` döndüğü için Dart/Kotlin tarafından TESPİT EDİLEMEYEN bir OEM launcher
    kısıtlaması. Kullanıcının kendi isteği ("onun yerinde direkt widget ekleme yerine
    yönlendirebilirsin") doğrultusunda `WidgetsScreen`'in "Ekle" butonu ARTIK bir başarı/
    başarısızlık SnackBar'ı GÖSTERMİYOR — bunun yerine HER ZAMAN üç adımlı manuel ekleme
    talimatlarını (`_showAddInstructionsSheet`, YENİ) gösteren bir bottom sheet açıyor.
    `requestPin()` YİNE DE arka planda (`unawaited`, sonucu HİÇ beklenmeden/UI'a yansıtılmadan)
    çağrılmaya devam ediyor — bu API'yi GERÇEKTEN doğru uygulayan launcher'larda (ör. stok
    Android/Pixel) kullanıcı belki hiç uzun basmadan sistemin kendi onay diyaloğunu görüp tek
    adımda ekleyebilir, bu "bonus" yol tamamen zararsız.
    - **Gotcha (bu turda yakalandı) — sheet'in içeriği (başlık + satır + 3 adım + buton) sabit
      sheet yüksekliğine sığmayıp `RenderFlex overflow` verdi** — GERÇEK bir hata, yalnızca test
      viewport'una özgü DEĞİL (dar bir telefonda da olurdu). `ad_free_promo_sheet.dart`'taki AYNI
      desen (`isScrollControlled: true` + `SingleChildScrollView`) ile düzeltildi.
  - **AYRI, kritik bir bulgu — widget seçicinin generic app ikonu göstermesinin ASIL kök nedeni:
    `android:previewLayout` (API 31+) bu MIUI launcher'ında GÜVENİLİR RENDER EDİLMİYORDU/YOK
    SAYILIYORDU, `android:previewImage` (eski/evrensel, STATİK bir PNG kaynağı) HİÇ VERİLMEMİŞTİ,
    Android da son çare olarak uygulama ikonuna düşüyordu.** Önceki turdaki "previewLayout zaten
    doğru tanımlı, statik doğrulamayla yeterli" varsayımı BU ekran görüntüsüyle YANLIŞLANDI —
    launcher'ların previewLayout desteği TUTARSIZ, `previewImage` GERİ DÜŞÜŞÜ de eklenmesi
    gerekiyormuş.
    - **Beş widget'ın HER BİRİ için AÇIK+KOYU tema önizleme PNG'si üretildi (10 PNG toplam),
      `android:previewImage` tüm `widget_info_*.xml`'lere eklendi** (previewLayout DA kaldı —
      onu destekleyen launcher'larda hâlâ ÖNCELİKLİ, previewImage yalnızca bir geri düşüş).
    - **Üretim yöntemi — İKİ AŞAMALI, ciddi bir gotcha'dan sonra bulundu.** İlk deneme
      `flutter_test` + `RenderRepaintBoundary.toImage()` (ZiboShareCard'daki AYNI teknik) idi —
      ama `flutter_test`'in kendi render motoru GERÇEK bir font/emoji YÜKLENMEDİĞİ sürece TÜM
      karakterleri tofu/boş dikdörtgen olarak çiziyor; `google_fonts`'un ağdan gerçek font
      indirmesiyle bunu aşma denemesi de bu ortamın test-sandbox'ında ASILI KALDI (dakikalarca
      askıda kalan bir `flutter_tester.exe` süreci, elle `taskkill` ile sonlandırılmak zorunda
      kaldı). **Çözüm — GERÇEK CİHAZ:** YENİ `lib/widget_preview_generator_main.dart` (normal
      `main.dart`'ı hiç etkilemeyen, alternatif bir giriş noktası) `flutter build apk --debug -t
      lib/widget_preview_generator_main.dart` ile derlenip cihaza kurulup açıldı — açılışta
      OTOMATİK 10 PNG'yi (gerçek Roboto fontu + gerçek Zibo karakter görseliyle, ama `dart:io`
      cihazın PROJE KLASÖRÜNE erişemediği için Z-dokusu/logo OLMADAN, düz gradyanla) kendi belge
      dizinine yazdı — `adb exec-out run-as com.dijitalkanka.dijital_kanka cat <yol>` ile (debug
      build'ler `run-as` erişimine sahip, root GEREKMEDİ) çekilip masaüstünde YENİ
      `tool/compose_widget_previews.dart` ile Z-dokusu + Zibo logosu ÜZERİNE bindirildi (aynı
      "cihaz: gerçek render, masaüstü: doku/logo bindirme" iki-aşamalı iş bölümü). **Emoji
      rozetleri de Material Icons'a çevrildi** (`Icons.water_drop_rounded` vb.) — emoji glifleri
      de (renkli emoji fontu gerektirdiği için) `flutter_test`'te render OLMUYORDU; Material
      Icons Flutter SDK'sıyla birlikte geldiği için bu sorunu yaşamıyor, ama gerçek cihaz yoluna
      geçilince bu artık gerekli değildi — yine de PREVIEW'ların kendi iç tutarlılığı için
      korundu (gerçek widget'lar hâlâ RemoteViews'ta emoji kullanıyor, YALNIZCA statik önizleme
      PNG'lerinde Icon kullanılıyor).
    - **Her iki betik de (`lib/widget_preview_generator_main.dart`,
      `tool/compose_widget_previews.dart`) SİLİNMEDİ — widget tasarımı ileride tekrar değişirse
      yeniden çalıştırılabilecek, projenin `tool/` klasöründeki diğer tek-seferlik-ama-kalıcı
      görsel betikleriyle (remove_bg.dart vb.) AYNI konvansiyonda tutuldu**, ikisinin de tepesinde
      TAM yeniden-üretim adımlarını anlatan bir doküman var.
  - **Test:** `widgets_screen_test.dart` yeniden yazıldı — eski başarı/başarısızlık SnackBar
    testleri, artık `requestPin()`'in SONUCUNDAN BAĞIMSIZ olarak HER ZAMAN talimat sheet'inin
    açıldığını (VE "Anladım"ın kapattığını) doğrulayan testlere döndü. `flutter test` tam yeşil:
    **350/350.**
  - **Gerçek cihazda doğrulama — KISMİ.** Build başarılı, `flutter test` yeşil, önizleme PNG'leri
    GERÇEK cihazda üretilip masaüstünde bindirilerek doğrulandı (görsel olarak incelendi, net/
    okunabilir/marka tutarlı). **AMA bu turun GERİ KALAN düzeltmelerinin (logo opaklığı, animasyon
    geçişleri, arka plan dokusu gerçek widget üzerinde, İstatistiklerim'in resumed-sync
    düzeltmesi, yeni "Ekle" talimat sheet'i) CANLI cihaz doğrulaması YAPILAMADI** — cihaz bu
    turun sonunda bağlantıyı kaybetti (muhtemelen kullanıcı tarafından çıkarıldı/kilitlendi).
    **Kullanıcının bir sonraki fırsatta kontrol etmesi gereken:** yeni APK'yı kurup (a) beş
    widget'ın hepsinde logonun artık net göründüğünü, (b) "Zibo'nun Sözü"/"İstatistiklerim"
    carousel'lerinin geçişinin artık kayma+solma ile daha "canlı" hissettirdiğini, (c) arka
    planda artık soluk bir Z-deseni dokusu olduğunu, (d) İstatistiklerim widget'ını EKLEYİP
    uygulamayı AÇIP KAPATINCA (resumed tetikleyici) gerçek verilerle dolduğunu, (e) uygulama
    içindeki "Ekle" butonunun artık başarı iddia ETMEDEN doğrudan 3 adımlı bir talimat sheet'i
    gösterdiğini, (f) ana ekrana uzun basıp Widget'lar listesindeki Zibo önizlemelerinin ARTIK
    generic app ikonu DEĞİL, gerçek tasarımlarıyla (karakter görseli, gerçek metin, ilerleme
    çubuğu) göründüğünü.
  - **2026 BEŞİNCİ güncelleme — kullanıcının "durgun" geri bildirimine devam: HER widget'ın
    kendi TEMASINA uygun, sabit dört kareli bir "sahne" animasyonu.** Önceki turdaki ViewFlipper
    geçiş animasyonu (kayma+solma) sürekli hissettirmedi — kullanıcı önce "su takibine dalgalar,
    para/birikime yeşil banknot [Zibo logolu], günlük ödüllere hediye kutuları, Zibo'nun Sözü'ne
    ampul, İstatistiklerim'e bir şey" fikrini SADECE KONUŞMAK için sordu (`işleme koyma sadece
    yapabilirmisin yaparsan nasıl olur konuşalım`), bu KAPSAMLI teknik açıklamadan (bkz. altta
    "RemoteViews'ın gerçek sınırı") sonra `evet hepsine başla` ile onayladı.
    - **RemoteViews'ın gerçek animasyon sınırı, kullanıcıya önceden açıklandı:** Android home
      screen widget'ları hiçbir zaman gerçek/sürekli bir canvas animasyonu (özel View, çizim
      döngüsü) ÇALIŞTIRAMAZ — tek native "hareket" mekanizması `ViewFlipper`'ın ÖNCEDEN ÇİZİLMİŞ,
      STATİK sayfalar arasında dönmesi (bkz. yukarıdaki "Zibo'nun Sözü"/"İstatistiklerim"
      carousel'leri). Bu yüzden "animasyon" burada, her widget'ın KENDİ temasına göre üretilmiş
      4 statik PNG karesinin `ViewFlipper` ile yavaşça (5sn aralıklarla) döndürülmesi — gerçek bir
      akışkan hareket DEĞİL, "nefes alan" bir sahne illüzyonu. Kullanıcı bu açıklamayı KABUL EDİP
      onayladıktan sonra uygulanmaya başlandı.
    - **`tool/generate_widget_bg_animations.dart`** (YENİ) — saf geometri (`img.drawLine`/
      `fillPolygon`/`drawCircle`/`fillRect`, `remove_bg.dart` ailesinden hiçbir font/BitmapFont
      bağımlılığı olmayan AYNI teknik) ile 5 widget × 4 kare = 20 PNG üretiyor
      (`drawable-nodpi/widget_bg_<widget>_1..4.png`): **Su Takibi** — sinüs dalgalı su desenleri
      (mavi `#2F7FBF`); **Para ve Birikim** — kayan, dönük banknotlar (yeşil `#2E8B57`, her biri
      dikdörtgen çerçeve + mühür dairesi + küçük 3 çizgilik bir "Z" — kullanıcının "Zibo logolu
      yeşil banknot" isteğine sembolik bir karşılık, gerçek logo PNG'si DEĞİL, saf çizim); **Günlük
      Giriş Ödülleri** — bobbing hediye kutuları (altın `#C79A3D`, kare + çapraz kurdele + iki
      üçgenli fiyonk); **Zibo'nun Sözü** — bir ampul + beş ışın çizgisi (altın `#D9A94A`);
      **İstatistiklerim** — yükselen dört çubuklu bir mini bar grafik (mor `#8E24AA`). Her widget
      TEK, kendi SATÜRE accent rengini kullanıyor (Z-deseninin aksine — bkz. altta "neden AÇIK/
      KOYU ayrımı yok").
      - **Gerçek bug #1 — düşük alfa (30-50/255), sıcak krem arka plan üzerinde renk yerine
        gri/bej okunuyordu.** Z-desenindeki AYNI genel teknik (opak çiz → blurla) burada
        KULLANILMADI (motifler zaten kalın/net şekiller, blur GEREKMİYOR) ama İLK denemede alfa
        değerleri düşük tutulunca (Z-deseninin dokümante edilmiş gerekçesiyle AYNI perspektif
        karışım etkisi) mavi/yeşil/altın/mor tonlar tanınamaz hale geldi. **Düzeltme:** tüm 5
        fonksiyonda alfa 68-100/255 aralığına (sed ile toplu) yükseltildi — artık her renk hem
        açık hem koyu temada tanınabilir kalıyor.
      - **Gerçek bug #2 — İstatistiklerim'in EN UZUN (4.) çubuğu 400px'lik kanvasın DIŞINA
        taşıyordu.** `startX=0.72×400` + `barW=24,gap=18` toplamı sağ kenarı aşıyordu. Düzeltme:
        `barW` (0.06→0.045×boyut), `gap` (0.045→0.03×boyut), `startX` (0.72→0.68×boyut) küçültülüp
        4 çubuğun TAMAMI marjla kanvasa sığdırıldı.
      - **Neden AÇIK/KOYU tema ayrımı YOK (Z-deseninden farklı):** Z-deseni neredeyse nötr
        tonlarla arka plana KARIŞMAK üzere tasarlandığı için iki ayrı varyant gerekiyordu; bu yeni
        motifler her widget'ın KENDİ SATÜRE (doygun) accent rengini orta-düşük alfayla kullandığı
        için hem sıcak krem hem neredeyse-siyah arka planda AYIRT EDİLEBİLİR kalıyor — TEK asset
        seti yeterli (kompoze edilmiş önizlemelerle iki temada da doğrulandı).
    - **`res/layout/widget_bg_frame.xml`** (YENİ) — tek bir `ImageView` (`widget_bg_frame_image`)
      taşıyan PAYLAŞILAN bir tek-sayfa şablonu; 5 widget'ın HEPSİ `RemoteViews(pkg, R.layout.
      widget_bg_frame).setImageViewResource(...)` + `addView(...)` ile bunu bir ARKA PLAN
      `ViewFlipper`'ına (`R.id.widget_bg_flipper`) dolduruyor — 5 ayrı, neredeyse aynı layout
      dosyası YAZILMADI.
    - **İKİ BAĞIMSIZ `ViewFlipper` içeren widget'lar — bu projede İLK KEZ.** "Zibo'nun Sözü" ve
      "İstatistiklerim"in HER İKİSİ artık İKİ AYRI `ViewFlipper` taşıyor: mevcut İÇERİK
      carousel'i (`widget_quote_flipper`/`widget_stats_flipper`, gerçek veri) VE YENİ ARKA PLAN
      carousel'i (`widget_bg_flipper`, sabit 4 dekoratif kare) — ikisi TAMAMEN bağımsız, farklı
      `flipInterval`'lerle (arka plan 5sn, içerik sırasıyla 180000ms/4500ms) kendi başlarına
      dönüyor. Diğer üç widget (Su Takibi/Para ve Birikim/Günlük Giriş Ödülleri, hepsi
      `ZiboBaseWidgetProvider`'ı extend ediyor) yalnızca TEK (yeni) arka plan `ViewFlipper`'ı
      kazandı — `ZiboBaseWidgetProvider`'a eklenen `abstract val backgroundFrames: List<Int>` +
      `onUpdate()`'teki paylaşılan doldurma döngüsü sayesinde HER ALT SINIFA tek satırlık bir
      `backgroundFrames = listOf(...)` eklemek yeterli oldu.
    - **RemoteViews güvenli-view sınıfı riski YOK** — yeni `widget_bg_frame.xml` tek bir
      `ImageView`, yeni `ViewFlipper`'lar zaten whitelist'te olan bir sınıf (bkz. yukarıdaki
      "Araç yüklenemiyor" bug notundaki whitelist) — bu turda YENİ bir inflate riski
      İNCELENMESİ/İCAT EDİLMESİ gerekmedi.
    - **Gerçek cihazda doğrulama — build+kurulum ANINDA yapıldı, `adb logcat` ile canlı
      izlendi.** APK yeniden derlenip (`flutter build apk --debug`) telefona kurulup (`adb
      install -r`, mevcut veri/widget'lar korunarak) açıldı — `adb shell dumpsys appwidget` ile
      cihazda ZATEN bağlı bir `ZiboWaterWidgetProvider` (id=23) örneği olduğu görüldü (önceki bir
      manuel ekleme oturumundan kalma). Bu, YENİ dual-ViewFlipper kodunu RİSKLİ bir manuel
      ana-ekran etkileşimine hiç gerek kalmadan test etmek için gerçek bir fırsat sundu: uygulama
      açılışı zaten `HomeWidgetSyncCoordinator.syncAll()`'ı (dolayısıyla bu widget'ın `onUpdate()`
      'ini YENİ Kotlin koduyla) tetikledi. `adb logcat -T <açılış anı>` ile filtrelenmiş loglar
      `AppWidgetServiceImpl: updateAppWidgetInstanceLocked ... ZiboWaterWidgetProvider` +
      `Launcher:WidgetView: onWidgetUpdate id = 23`'ün İKİ KEZ, HİÇBİR `InflateException`/`FATAL
      EXCEPTION`/`Class not allowed` satırı OLMADAN gerçekleştiğini gösterdi — dual-ViewFlipper
      yaklaşımının en az BİR gerçek, canlı widget örneğinde ÇÖKMEDEN render edildiğinin somut
      kanıtı.
    - **`flutter test` tam yeşil: 350/350** (bu turda kod-seviyesi testte bir değişiklik
      GEREKMEDİ — arka plan `ViewFlipper`'ları saf Kotlin/XML/asset değişikliği, hiçbir Dart
      tarafı davranışına dokunmuyor).
    - **YAPILAMAYAN/EKSİK doğrulama:** yalnızca Su Takibi widget'ı GERÇEKTEN bağlı bir örnek
      üzerinden test edilebildi (crash-free doğrulandı) — diğer dört widget türünün (Para ve
      Birikim/Günlük Giriş Ödülleri/Zibo'nun Sözü/İstatistiklerim) HİÇBİRİ bu turda bağlı DEĞİLDİ,
      bu yüzden onlar için aynı canlı `dumpsys`/`logcat` kanıtı ELDE EDİLEMEDİ (yalnızca statik
      kod incelemesiyle güvenilir — Kotlin tarafındaki desen Su Takibi'yle BİREBİR aynı olduğu
      için risk düşük kabul edildi, ama KESİN değil). Görsel (renklerin/motiflerin gerçekten
      doğru/net göründüğü, geçişin "nefes alma" hissi verdiği) doğrulama da bu turda YAPILAMADI —
      kullanıcının kendi cihazında beş widget'ın hepsini (özellikle henüz hiç bağlanmamış
      dördünü) ekleyip birkaç dakika gözlemlemesi gerekiyor.
    - **DENENDİ, KULLANICI GERÇEK CİHAZDA GÖRÜP REDDETTİ, TAMAMEN GERİ ALINDI.** Kullanıcı geri
      bildirimi (verbatim): "hiç güzel durmadı komple silelim bu tasarımları olmadı bunlar" —
      Z-desenindeki AYNI kategori bir sonuç (bkz. yukarıdaki "ÜÇÜNCÜ güncelleme"deki Z-deseni
      reddi), bu sefer TÜM BEŞ widget'ın arka plan animasyonu için. Tam geri alma yapıldı: 20 PNG
      (`widget_bg_*_1..4.png`), `widget_bg_frame.xml`, `tool/generate_widget_bg_animations.dart`
      SİLİNDİ; `ZiboBaseWidgetProvider.kt`'deki `backgroundFrames` abstract alanı + doldurma
      döngüsü, üç alt sınıfın (`Water`/`Money`/`DailyRewards`) `backgroundFrames` override'ları,
      `ZiboMotivationWidgetProvider.kt`/`ZiboProfileStatsWidgetProvider.kt`'deki ikinci
      `ViewFlipper` doldurma bloğu, VE `widget_module.xml`/`widget_motivation.xml`/
      `widget_profile_stats.xml`'deki `widget_bg_flipper` `<ViewFlipper>` elemanları TAMAMEN
      kaldırılıp bu güncellemeden BİR ÖNCEKİ (Round 2/Z-deseni reddi sonrası) haline dönüldü —
      beş widget şu an yeniden yalnızca TEK içerik-taşıyan katmana (veya "Zibo'nun Sözü"/
      "İstatistiklerim" için TEK içerik `ViewFlipper`'ına) sahip, arka plan animasyonu YOK. Bu bir
      daha DENENMEDEN önce, "sahne illüzyonu"nun (4 statik kare + ViewFlipper) kavramsal olarak
      neden işe yaramadığı (renk/motif kalitesi mi, "durgunluk" hissi devam mı etti, yoksa arka
      plan katmanının kendisi mi rahatsız etti) kullanıcıyla AYRICA netleştirilmeli.
  - **2026 ALTINCI güncelleme — arka plan animasyonu tamamen reddedildikten HEMEN SONRA, kullanıcı
    aynı oturumda "bu sefer YALNIZCA logoyu belirginleştir + hareket ettir" isteğiyle DAHA DAR
    kapsamlı bir animasyon istedi, ardından ilk deneme "kasıyormuş gibi" bulunup düzeltildi.**
    - **İlk deneme — "duraksamalı shake":** kullanıcı isteği (verbatim): "logoyu biraz daha
      belirgin yap hafif duraksamalı shake efekti ver logo hareket etsin güzel durur." Köşedeki
      Zibo logosu (`alpha=0.5`) statik bir `ImageView`'DEN, kendi `ViewFlipper`'ına (`widget_logo_
      flipper`) çevrildi — `alpha=0.68`'e çıkarılıp SEKİZ kareye bölündü (`0/0/0/-8/8/-4/0/0°`,
      `flipInterval=600ms`) — HİÇ YENİ PNG ÜRETİLMEDEN: her kare AYNI `widget_zibo_logo` kaynağının
      yalnızca farklı bir `android:rotation` açısıyla STATİK XML örneği. **Bu tekniğin RemoteViews
      güvenliği ÖNEMLİ bir keşif:** `android:rotation` (`alpha`/`scaleType` gibi) View'in TEMEL bir
      inflate-zamanı XML özniteliği — `RemoteViews.setInt(id, "setRotation", ...)` gibi ÇALIŞMA
      ZAMANI bir "action" çağrısı DEĞİL (bu, geçmişte `ProgressBar.setProgressTintList` reflection
      hatasına yol açan TÜRDEN bir riskti) — bu yüzden RemoteViews'ın kısıtlı whitelist'inden HİÇ
      geçmiyor, host süreç layout'u NORMAL `LayoutInflater` ile inflate ederken diğer TÜM statik
      XML öznitelikleriyle (zaten güvenle kullanılan `alpha` gibi) AYNI şekilde uygulanıyor —
      whitelist riski YOK.
    - **Kullanıcı geri bildirimi (verbatim, HENÜZ cihazda görmeden, yalnızca kavram üzerinden):**
      "widgetdeki ziboyu duraksamalı shake yaptık ya onu akıcı bir şekilde shake efekti yap böyle
      kasıyormuş gibi durdu güzel olmadı daha akıcı animasyon ekle." Kök sorun: SEKİZ KABA kare +
      ARADA GEÇİŞ ANİMASYONU OLMADAN (kasıtlı — "gerçek bir sallanma ani/keskin geçişlerle daha
      inandırıcı" varsayımıyla) her komşu kare arasında BÜYÜK açı sıçramaları (0°→-8°→8°→-4°) VE
      600ms'lik YAVAŞ bir `flipInterval` — bu, göze akıcı bir salınım değil, "zıplayan"/"takılan"
      bir dizi ANLIK sıçrama olarak okunuyordu.
    - **Düzeltme — "flip-book" (film şeridi/sprite animasyon) tekniği: ÇOK sayıda, İNCE açı
      adımlı kare + KISA `flipInterval`.** Bu, klasik kare-tabanlı animasyonun (GIF/sprite sheet)
      TEMEL prensibi — RemoteViews gerçek bir property animator ÇALIŞTIRAMADIĞI için (bkz. bu
      bölümün genelindeki "RemoteViews'ın gerçek animasyon sınırı" notu), akıcılık YALNIZCA
      "yeterince küçük adım + yeterince kısa aralık" ile TAKLİT edilebiliyor. Yeni tasarım: 28
      kare — İLK 12'si bir sinüs eğrisinin örneklemi (`0°→4°→7°→8°→7°→4°→0°→-4°→-7°→-8°→-7°→-4°`,
      TAM BİR yumuşak sallanma jesti, komşu kareler arası fark yalnızca 3-4°), SONRAKİ 16'sı 0°'de
      DİNLENME (kullanıcının "hafif duraksamalı" isteğinin karşılığı) — `flipInterval=70ms` (12
      kare × 70ms ≈ 840ms'lik akıcı bir sallanma + 16 kare × 70ms ≈ 1.1sn'lik bir duraklama,
      döngü tekrarlıyor). Geçiş animasyonu (`in/outAnimation`) YİNE BİLEREK EKLENMEDİ — ince açı
      adımları ZATEN akıcı, üstüne bir solma/kayma binmesi (özellikle bu kadar küçük bir logoda)
      net rotasyon hissini bulanıklaştırırdı; akıcılığın kaynağı KARE SAYISI/HIZI, geçiş efekti
      DEĞİL.
    - **Üç widget layout dosyasının (`widget_module.xml` — 42×17dp, 8 modülden 3'ünün paylaştığı
      şablon; `widget_motivation.xml`/`widget_profile_stats.xml` — 48×20dp) ÜÇÜ de AYNI 28 kareyi,
      yalnızca kendi logo boyutuyla taşıyor** — elle 3×28=84 satır yazmak yerine tek bir Bash
      döngüsüyle (derece dizisi → `<ImageView .../>` satırları) üretilip her dosyaya yapıştırıldı,
      `tool/`'a kalıcı bir script EKLENMEDİ (tek seferlik, tekrar üretilmesi gerekirse aynı derece
      dizisi + boyut/alpha kalıbı yeterli).
    - **Gerçek cihazda doğrulama — İKİ AYRI build+kurulum turunda, `adb logcat` ile canlı
      izlendi, SIFIR hata.** İlk tur (kaba 8-kare tasarım): cihazda ZATEN bağlı bir
      `ZiboWaterWidgetProvider` (id=23) örneği bulunup uygulama açılışında `onWidgetUpdate`'in
      HİÇBİR `InflateException`/`FATAL EXCEPTION` OLMADAN İKİ KEZ tetiklendiği doğrulandı. İkinci
      tur (28-kareli akıcı tasarım, "kasıyor" düzeltmesinden SONRA): cihazda BU SEFER
      `ZiboMotivationWidgetProvider` (id=29, "Zibo'nun Sözü" — `widget_motivation.xml`'i kullanan,
      üç dosyadan biri) bağlı bulundu, `onWidgetUpdate id = 29` YİNE hatasız tetiklendi — İKİ
      FARKLI widget türünde, İKİ AYRI tasarım turunda, RemoteViews inflate güvenliği canlı
      kanıtlandı. **Görsel (gerçekten "akıcı" hissettirip hissettirmediği) doğrulama YAPILAMADI**
      (bkz. bu bölümün genelindeki tekrarlayan "kullanıcının kendi cihazında bakması gerekiyor"
      notu) — kullanıcının birkaç saniye izleyip önceki "kasıyor" hissinin geçtiğini onaylaması
      gerekiyor.
  - **2026 YEDİNCİ güncelleme — gerçek bug: widget'lar HER ZAMAN Türkçe kalıyordu, uygulama İÇİ
    dil (`LocaleProvider`) değiştirilse bile.** Kullanıcı raporu (verbatim): "bu widgetler aynı
    zamanda uygulama dili hangi dilse ona uygun olsun o hata var uygulama ispanyolca widget türkçe
    misal bunu düzelt." İnceleme, `HomeWidgetSyncCoordinator`'ın (ve onu çağıran `RootScreen`'in)
    DART tarafındaki kodunun YÜZEYSEL olarak zaten doğru göründüğünü ortaya çıkardı —
    `localeProvider.addListener(sync.syncAll)` dil değişince `syncAll()`'ı tetikliyordu ve
    `HomeWidgetSyncCoordinator._l10n` her çağrıda `AppLocalizations.of(context)`'i TAZE okuyordu.
    - **Gerçek kök neden — bir KARE-ZAMANLAMA YARIŞI (race condition).**
      `ChangeNotifier.notifyListeners()` KAYITLI TÜM listener'ları SENKRON (aynı çağrı yığınında)
      tetikler — ama `provider` paketinin `Consumer3<ThemeProvider, LocaleProvider,
      AppThemeProvider>`'ı bu bildirimi Flutter'ın standart `setState`-benzeri mekanizmasıyla ele
      alır, bu da `MaterialApp`'in (dolayısıyla `locale:` parametresinin, dolayısıyla
      `Localizations.of(context)`'in gördüğü AMBİYAN değerin) yalnızca BİR SONRAKİ ÇİZİM
      KARESİNDE gerçekten yeniden `build()` edilmesi anlamına gelir — SENKRON değil. `RootScreen.
      initState()`'teki `localeProvider.addListener(sync.syncAll)` DOĞRUDAN bağlıyken,
      `sync.syncAll()` bu SENKRON anda (yani `MaterialApp` HENÜZ yeni locale'le yeniden inşa
      EDİLMEDEN) çalışıp `_l10n` üzerinden HÂLÂ ESKİ (bir adım geride) dili okuyordu — widget'lar
      dil değiştirildikten SONRA bile eski dilde KALIYORDU (locale bir daha DEĞİŞMEDİĞİ sürece bu
      yeniden tetiklenmediği için KENDİLİĞİNDEN asla düzelmiyordu). **İlginç bir şekilde
      `initState()`'teki İLK `syncAll()` çağrısı ZATEN (BAMBAŞKA bir gerekçeyle — `AppLocalizations.
      of(context)`'in ilk karede `null` dönebileceği ihtimaline karşı) `addPostFrameCallback`'e
      ERTELENMİŞTİ — yalnızca dil DEĞİŞİMİ dinleyicisi bu erteleme deseninden YOKSUNDU, asimetri
      buradaydı.**
    - **Düzeltme — `root_screen.dart`'a YENİ `_onLocaleChangedForWidgetSync()` metodu.**
      `localeProvider.addListener(sync.syncAll)` yerine `localeProvider.addListener(_
      onLocaleChangedForWidgetSync)` — bu yeni metot `syncAll()`'ı DOĞRUDAN çağırmak yerine
      `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _homeWidgetSync?.
      syncAll(); })` ile bir SONRAKİ KAREYE erteliyor — TAM OLARAK initState'in İLK çağrısının
      ZATEN kullandığı deseni. `dispose()`'daki `removeListener` çağrısı da AYNI (artık isimli)
      metoda güncellendi.
    - **Test enjeksiyonu genişletildi — `DijitalKankaApp`/`_AppStartupGate`'e YENİ bir
      `homeWidgetService` parametresi eklendi** (`adService`/`purchaseService` ile AYNI desen) —
      önceden yalnızca `RootScreen`'in KENDİSİ bunu kabul ediyordu (`_AppStartupGate` her zaman
      `const RootScreen(key: ValueKey('root'))` kuruyordu, hiçbir enjeksiyon yolu YOKTU). Bu
      olmadan bu KARE-ZAMANLAMA hatasını GERÇEKTEN yakalayan bir test yazmak imkansızdı — hatayı
      `HomeWidgetSyncCoordinator`'ı izole test ederek (bkz. `home_widget_sync_coordinator_test.
      dart`) YAKALAYAMAZSINIZ, çünkü o test `syncAll()`'ı DOĞRUDAN çağırıyor, `Consumer3`'ün
      GERÇEK bir sonraki-kare rebuild mekanizmasından hiç GEÇMİYOR — hatayı yakalamak için `const
      DijitalKankaApp()`'in GERÇEK `MaterialApp`+`Consumer3` zincirinden geçen bir widget testi
      ŞARTTI.
    - **Test:** `widget_test.dart`'a YENİ `_RecordingHomeWidgetService` (yalnızca hangi modüle
      hangi başlık metninin gönderildiğini kaydeden minimal bir sahte) + YENİ bir test — Ayarlar'dan
      İngilizce'ye geçilip Su Takibi widget'ına gönderilen başlıkların ARTIK "Water Tracking"
      İÇERDİĞİNİ VE ASLA "Su Takibi" İÇERMEDİĞİNİ (dil değişiminden SONRAKİ gönderimler için)
      doğruluyor — bu test, DÜZELTMEDEN ÖNCEKİ kodda BAŞARISIZ OLURDU (senkron `syncAll()` hâlâ
      Türkçe title gönderirdi), düzeltmeden SONRA geçiyor.
    - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** (dil değiştirip widget'ın GERÇEKTEN
      İngilizce/İspanyolca'ya döndüğünü görmek kullanıcının kendi cihazında gerekiyor) — yalnızca
      yukarıdaki hedefe yönelik regresyon testiyle (`flutter test`, 351/351) VE mantığın kendisinin
      (bir sonraki frame'e erteleme) `initState`'teki İLK senkronizasyonla BİREBİR AYNI, zaten
      kanıtlanmış deseni tekrarladığıyla güven kazanıldı.
  - **2026 SEKİZİNCİ güncelleme — widget'lar artık tıklanınca yalnızca Ana Sayfa'yı DEĞİL, kendi
    modüllerini DOĞRUDAN açıyor.** Kullanıcı isteği (verbatim özet): "Su Takibi widget'ına basınca
    kullanıcı doğrudan Su Takibi ekranına düşmeli, önce Ana Sayfa'ya gidip sonra manuel gezinmesine
    gerek kalmamalı — bu davranışı SADECE Su Takibi'nde değil, mevcut TÜM widget'larda düzelt."
    Eskiden BEŞ widget'ın (Hedef Takibi/Şükran Günlüğü gibi örnekler kullanıcının verdiği ama
    ÖNCEKİ bir turda ZATEN kaldırılmış widget'lardı — kullanıcının NİYETİ güncel beş widget'a
    [Su Takibi/Para ve Birikim/Günlük Giriş Ödülleri/Zibo'nun Sözü/İstatistiklerim] uygulandı)
    HEPSİ `HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)`'ı URI'SİZ
    çağırıyordu — bu, "bildirime dokununca Ana Sayfa'ya gitme deseniyle AYNI basitlik tercihi"
    diye BİLEREK belgelenmiş bir kararı geri çeviriyor.
    - **Kotlin — üç dosyada `Uri.parse("zibowidget://open/$dataKeyPrefix")` üçüncü parametre
      olarak eklendi** (`android.net.Uri` importuyla): `ZiboBaseWidgetProvider.kt` (Su Takibi/Para
      ve Birikim/Günlük Giriş Ödülleri'nin PAYLAŞTIĞI TEK `onUpdate()` — üçü de kendi
      `dataKeyPrefix`'ini zaten taşıdığı için TEK bir değişiklik üçüne birden yayıldı),
      `ZiboMotivationWidgetProvider.kt`, `ZiboProfileStatsWidgetProvider.kt` (ikisi ayrı
      `onUpdate()` taşıyor, `HomeWidgetLaunchIntent.getActivity(...)` çağrısı HER birinde TEK bir
      yerde, `R.id.widget_root` hedefli — tam üç widget türünün üçünde de BAŞKA hiçbir tıklama
      hedefi olmadığı Explore turuyla doğrulandı).
    - **`home_widget` paketinin (v0.9.3) KENDİ resmi derin bağlantı API'si kullanıldı** —
      `HomeWidgetLaunchIntent.getActivity(context, activityClass, uri)`'nin ÜÇÜNCÜ, opsiyonel `uri`
      parametresi (paket kaynağından doğrulandı: `intent.data = uri`) + Flutter tarafındaki
      `HomeWidget.initiallyLaunchedFromHomeWidget()` (SOĞUK başlangıç) / `HomeWidget.widgetClicked`
      (uygulama ZATEN açıkken, bir `EventChannel` stream'i) — ikisi de URI'yi `Uri.parse(...)`
      olarak döndürüyor, hiç yeni bir platform kanalı YAZILMASI gerekmedi.
    - **`HomeWidgetService`'e iki yeni üye:** `Future<ZiboWidgetModule?> initialLaunchModule()` +
      `Stream<ZiboWidgetModule?> get moduleClicked` — `HomeWidgetPluginService` bunları yukarıdaki
      gerçek API'lere sarıp, ortak bir `_moduleFromWidgetUri(Uri?)` yardımcısıyla
      `zibowidget://open/<prefix>`'i (`uri.pathSegments.last`) `ZiboWidgetModule.values`'tan
      `dataKeyPrefix`'i eşleşen üyeyle `ZiboWidgetModule`e çeviriyor (eşleşme yoksa `null`, AdService/
      NotificationService'teki AYNI "platform kanalı hatası sessizce yutulur" savunması).
    - **`RootScreen._handleWidgetModuleTap(ZiboWidgetModule)`** — `_handlePushNotificationTap`'in
      BİREBİR AYNI switch-tabanlı deseni. `ZiboWidgetModule.dailyRewards` ZATEN VAR OLAN
      `dailyRewardsPopupRequest` sinyalini YENİDEN KULLANIYOR (push bildirimiyle AYNI hedef — Ana
      Sayfa'ya geçip `DailyRewardsScreen`'i dialog olarak açıyor); `ZiboWidgetModule.motivation`
      ("Zibo'nun Sözü") kendi ayrı bir EKRANI olmadığı için (içerik zaten Ana Sayfa'nın konuşma
      balonunda yaşıyor) `homeTabRequest`'e düşüyor — kullanıcının "her widget kendi modülünü
      DOĞRUDAN açsın" isteğinin bu widget için EN DOĞRU karşılığı Ana Sayfa'nın kendisi (zaten
      GERÇEK bir hedef ekranı YOK).
      - **`waterModuleRequest`/`moneyModuleRequest`** (YENİ, `tab_navigation.dart`,
        `goalsTabRequest` ile AYNI `ValueNotifier<int>` deseni) — Su Takibi/Para ve Birikim BİRER
        SEKME DEĞİL, `modules_menu_sheet.dart`'ın push ettiği ekranlar olduğu için (push
        bildiriminin `waterReminder`/`dailyMotivation` türlerinin daha önce "en basit düşüş"
        olarak Ana Sayfa'ya attığı AYNI sınırlama) bu ikisi `RootScreen`'de `Navigator.of(context).
        push(MaterialPageRoute(builder: (_) => const WaterTrackingScreen()))`/AYNI `MoneyScreen()`
        ile — `modules_menu_sheet.dart`'ın Su Takibi/Para ve Birikim'i açtığı BİREBİR AYNI çağrı
        kopyalandı — DOĞRUDAN karşılanıyor; artık push bildirimlerinin aksine GERÇEKTEN o ekrana
        düşülüyor.
      - **`profileTabRequest`** (YENİ) — "İstatistiklerim" widget'ı Profil sekmesine karşılık
        geliyor; push bildirimlerinin HİÇBİRİ Profil sekmesine ihtiyaç duymadığı için önceden HİÇ
        var olmayan yepyeni bir sinyal.
    - **Soğuk başlangıç kontrolü, `initState`'teki MEVCUT `sync.syncAll()` postFrameCallback'inin
      İÇİNE eklendi** (`final initialModule = await _homeWidgetService.initialLaunchModule(); if
      (mounted && initialModule != null) _handleWidgetModuleTap(initialModule);`) — AYNI karede,
      ayrı bir postFrameCallback'e gerek kalmadan. **Sıcak tıklama için `RootScreen`'de bu sınıfta
      İLK KEZ bir `StreamSubscription<ZiboWidgetModule?>`** (`_homeWidgetService.moduleClicked.
      listen(...)`, `_homeWidgetSync` alanıyla AYNI "nullable field, dispose'ta güvenli temizlik"
      üslubunda `dispose()`'ta `cancel()` ediliyor).
    - **Test enjeksiyonu — `DijitalKankaApp`'e YENİ bir `homeWidgetService` parametresi eklendi**
      (`adService`/`purchaseService` ile AYNI desen), `_AppStartupGate` üzerinden `RootScreen`'e
      iletiliyor — önceden yalnızca `RootScreen`'in KENDİSİ bunu kabul ediyordu (`_AppStartupGate`
      her zaman `const RootScreen(key: ValueKey('root'))` kuruyordu, hiçbir enjeksiyon yolu YOKTU)
      — bu enjeksiyon olmadan derin bağlantı davranışını `const DijitalKankaApp()`'in GERÇEK
      `MaterialApp`+`Consumer3` zincirinden geçen bir widget testiyle doğrulamak İMKANSIZDI.
    - **Mevcut sahte `HomeWidgetService`'ler güncellendi** (`widget_test.dart`/
      `home_widget_sync_coordinator_test.dart`/`widgets_screen_test.dart`'taki ÜÇ ayrı fake) — yeni
      soyut üyeleri implemente etmeden derleme kırılırdı. `widget_test.dart`'taki
      `_RecordingHomeWidgetService` AYRICA testte KONTROL EDİLEBİLİR bir `initialLaunchModuleValue`
      alanı + `simulateWidgetClick(module)` metodu (dahili `StreamController.broadcast()`'a `.add`
      eden TEK açık giriş noktası, private field'a dışarıdan erişilemediği için) kazandı.
    - **Test:** `widget_test.dart`'a ÜÇ YENİ senaryo — (a) soğuk başlangıç: `initialLaunchModule
      Value = ZiboWidgetModule.water` ile pump'lanan uygulamanın DOĞRUDAN (Ana Sayfa'dan geçmeden)
      Su Takibi ekranını açtığı; (b) sıcak tıklama: uygulama normal açıldıktan SONRA `simulateWidget
      Click(ZiboWidgetModule.money)` çağrılınca Para ve Birikim ekranının push edildiği; (c) kalan
      üç eşleme (`dailyRewards`/`motivation`/`profileStats`) için DAHA HAFİF doğrulamalar — ilgili
      `ValueNotifier`'ın (`dailyRewardsPopupRequest`/`homeTabRequest`/`profileTabRequest`) ÖNCEKİ
      değerinden BÜYÜK olduğu (mutlak değer değil, DELTA — global sinyaller test dosyası genelinde
      paylaşıldığı için robust) doğrulanıyor; bu üçü ZATEN kendi mekanizmalarıyla (push bildirimi
      yönlendirmesi, sekme geçişi) ayrı ayrı test edildiği için burada yalnızca `_handleWidgetModule
      Tap`'in DOĞRU sinyale eşlediği kanıtlanması yeterli. `flutter test` tam yeşil (bir istisnayla —
      bkz. altta): **357/358** (kalan bir başarısızlık — "Zibo'ya dokununca söz değişir..." testinin
      `audioplayers` platform kanalı `MissingPluginException`'ı — `git stash` ile son commit'e
      dönülüp DOĞRULANDI: bu turdan ÖNCE de aynı şekilde başarısız oluyordu, bu turun DEĞİŞİKLİKLERİYLE
      İLGİSİZ, önceden var olan bir kusur; ayrı bir arka plan görevi olarak flagelendi, bu turda
      DÜZELTİLMEDİ).
    - **Gerçek cihazda doğrulama bu turda YAPILAMADI — bilinçli bir karar.** Bağlı cihazda
      `adb install -r` **imza uyuşmazlığı** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) ile reddedildi;
      `adb shell dumpsys package` ile kontrol edilince cihazdaki kurulu sürümün
      `installerPackageName=com.android.vending` (Google Play Store) VE `versionName=1.1.1`
      (kullanıcının BİR ÖNCEKİ turda Play Console'a yüklediği GERÇEK release sürümü) olduğu
      görüldü — yani bu, bir test cihazı DEĞİL, kullanıcının kendi GERÇEK/CANLI kurulumu. Bunu
      SİLİP debug anahtarıyla YENİDEN kurmak (imza uyuşmazlığını aşmanın TEK yolu) kullanıcının
      gerçek uygulamasını bir debug build'le DEĞİŞTİRİRDİ — "geri dönüşü zor/dışa dönük eylem"
      ilkesi gereği bu YAPILMADI. Doğrulama yalnızca (a) `flutter build apk --debug`'ın SORUNSUZ
      derlenmesi (Kotlin `Uri.parse` çağrıları dahil) VE (b) yukarıdaki kapsamlı widget test
      senaryolarıyla sınırlı kaldı. **Kullanıcının kendi cihazında (Play Store güncellemesini
      aldıktan SONRA) doğrulaması gereken:** her beş widget'a dokununca uygulamanın GERÇEKTEN
      kendi modülüne (Su Takibi/Para ve Birikim ekranı DOĞRUDAN açılıyor, Günlük Giriş Ödülleri
      popup'ı açılıyor, Zibo'nun Sözü/İstatistiklerim widget'ları sırasıyla Ana Sayfa'yı/Profil
      sekmesini öne getiriyor) düştüğü, önce Ana Sayfa'ya gidip MANUEL gezinme GEREKMEDİĞİ.

## Coin Reward Miktarları — Şükran/Su/Manifest Günlüğü 2 → 5 ZC

- **2026 güncellemesi.** Kullanıcı isteği: "modüllerde 2 Zibo Coin veriyor, onu 5 yapalım" —
  bkz. "Zibo Coin ekonomisi" bölümündeki tam detay (bu, o bölümdeki notun bir tekrarı değil,
  çapraz referans içindir): `CoinEconomy.gratitudeJournal`/`waterGoalCompleted`/`manifestJournal`
  ÜÇÜ BİRLİKTE 2'den 5'e yükseltildi + ilgili 4 hardcoded ARB metni (TR/EN/ES) + test
  assertion'ları güncellendi. `flutter test` 330/330 (bu değişikliğin kendisi için) yeşil.

## Rozet Sistemi ([badge_definition.dart](lib/models/badge_definition.dart), [badge_record.dart](lib/models/badge_record.dart), [consistency_badges.dart](lib/data/consistency_badges.dart), [badge_provider.dart](lib/providers/badge_provider.dart), [app_streak_provider.dart](lib/providers/app_streak_provider.dart), [badge_coordinator.dart](lib/services/badge_coordinator.dart), [badges_trigger_button.dart](lib/widgets/badges_trigger_button.dart), [badge_celebration_overlay.dart](lib/widgets/badge_celebration_overlay.dart), [badges_gallery_screen.dart](lib/screens/badges_gallery_screen.dart))

- **2026 yeni özellik — adım adım ilerlenen bir plan, bu turda YALNIZCA İLK
  kategori (İstikrar Rozetleri, 5 rozet) tamamlandı.** Kullanıcının kalan
  kategorileri (Modül Ustalığı, Koleksiyon, Sadakat, Sosyal/Paylaşım, Gizli/
  Eğlenceli) AYRI turlarda istediği açıkça belirtildi — bu bölüm/altyapı
  BİLEREK yalnızca `consistencyBadges`'i barındırıyor, `BadgeCategory` enum'u
  şimdilik tek değerli (`consistency`).
- **Kullanıcının netleştirdiği tek kritik tasarım kararı — "streak" hangi
  veriye bağlı?** `GoalsProvider.longestStreak` mimari gereği ASLA 7'yi
  aşamaz (bir 7 günlük döngü tamamlanınca/bozulunca sıfırlanıyor, bkz. "Hedef
  Takibi" bölümü) — bu yüzden `AskUserQuestion` ile soruldu, kullanıcı
  **"Uygulamayı her gün açma serisi"**ni seçti: Hedef Takibi'nden TAMAMEN
  BAĞIMSIZ, YENİ bir `AppStreakProvider`.
- **`AppStreakProvider`** — `CoinProvider`/`GoalsProvider` ile AYNI
  `CloudStateStore` (Varyant A) deseni, `{lastOpenDate, currentStreak}`.
  **GÜVENLİK-KRİTİK:** cihaz saatine değil `TrustedTimeProvider.now()`'a
  bağlı (`main.dart`'ta `now: () => context.read<TrustedTimeProvider>().
  now()` ile enjekte ediliyor) — diğer TÜM "güne bağlı" mekanizmalarla AYNI
  garanti: kullanıcı cihaz saatini ileri alarak seriyi/rozetleri erken
  kazanamaz. `recordOpenForToday()` bugün ZATEN kaydedilmişse no-op; dün
  kaydedilmişse +1; aksi halde (gün ATLANMIŞSA) 1'e sıfırlar.
- **`BadgeProvider`** — kazanılan rozetleri (`Map<String, BadgeRecord>`,
  `earnedAt`/`claimed`) tutar, AYNI `CloudStateStore` deseni.
  `reconcileConsistencyBadges({hasCompletedFirstGoalCycle, appOpenStreak})`
  — beş rozetin HER BİRİNİN koşulunu (`first_step`=ilk 7 günlük hedef
  döngüsü tamamlandı mı, diğer dördü=`appOpenStreak >= 7/30/90/180`)
  kontrol edip YENİ kazanılanları kaydeder. **Tek slot kutlama sinyali —
  `pendingZiboEvent`/`pendingBadgePopup` ile AYNI desen** (bkz.
  `badge_celebration_signal.dart`): aynı reconcile çağrısında BİRDEN FAZLA
  rozet aynı anda kazanılırsa (ör. `appOpenStreak` bir sıçramada 30'u geçip
  hem `week_streak` hem `month_streak`'i tetiklerse) HEPSİ kalıcı olarak
  kazanılmış sayılır ama yalnızca EN SONuncusu kutlama popup'ına yazılır.
- **`BadgeCoordinator`** — `HomeWidgetSyncCoordinator`/`CostumeProvider.
  reconcileGoalUnlocks` ile AYNI "constructor'dan değil PARAMETRE olarak al,
  dışarıdan `addListener` ekle" felsefesi: `GoalsProvider`/`AppStreakProvider`'a
  KALICI bağımlı değil, yalnızca dinliyor. Constructor'ı EAGER bir ilk
  `reconcile()` de yapıyor (kuruluşta zaten karşılanmış bir koşul HEMEN
  ödüllendirilsin diye). `RootScreen.initState()`'te, `HomeWidgetSyncCoordinator`
  ile AYNI `addPostFrameCallback`'e (ilk frame TAMAMLANDIKTAN sonra)
  kuruluyor — **gerçek bir bug'dan öğrenildi:** `initState`'in GÖVDESİNDE
  senkron çağrılırsa (`AppStreakProvider.recordOpenForToday()`/
  `BadgeCoordinator`'ın eager reconcile'ı `notifyListeners()` tetikleyebildiği
  için) "setState() or markNeedsBuild() called during build" hatasıyla
  ÇÖKÜYORDU (`flutter test`'te GERÇEKTEN yakalandı) — postFrameCallback'e
  taşınarak düzeltildi. Uygulama her öne geldiğinde (`didChangeAppLifecycleState`'in
  `resumed` dalı, `touchLastActive`/`syncAll` ile AYNI tetikleyici)
  `recordOpenForToday()` tekrar çağrılıyor.
- **Ana Sayfa Tetikleyicisi (`BadgesTriggerButton`)** — mevcut Günlük Ödül
  tetikleyicisinin (`Alignment(1, -0.8)`) HEMEN ALTINDA (`Alignment(1,
  -0.55)`), aynı koşullu-görünürlük deseni (`_selectedIndex == 0`).
  **Kullanıcının açık isteği — `DailyRewardsTriggerButton`'ın sürekli
  `repeat(reverse: true)` nabzından FARKLI, "sakin ve SÜREKLİ OLMAYAN" bir
  animasyon** ("Şans Çarkı'nın titreşen coin animasyonu gibi dikkat dağıtıcı
  OLMASIN"): `_pulseScaleFor(t)` bir döngünün yalnızca İLK %30'unda kısa bir
  nabız (1.0→1.07→1.0) uygulayıp kalan %70'inde TAM DİNLENME (1.0, sabit)
  döndürüyor — göz sürekli hareket görmüyor, arada bir "nefes alıyor".
  Kullanıcının verdiği `popup_rozet_icon.png` görselini kullanıyor (kod-tabanlı
  bir rozet DEĞİL). Dokununca ARA bir pop-up/önizleme OLMADAN DOĞRUDAN
  `BadgesGalleryScreen` push ediliyor.
- **Rozetler Galerisi (`BadgesGalleryScreen`)** — `GridView.count(crossAxisCount:
  2, childAspectRatio: 0.6)`, bu projedeki tekrarlayan "yeni grid kartı ekleyince
  overflow" bug sınıfına karşı BİLEREK muhafazakar seçildi (bkz. "Test
  kalıpları" bölümü) ve `test/badges_gallery_screen_test.dart`'ta gerçekçi
  dar bir viewport'ta (412×915) `tester.takeException()` ile doğrulandı.
  Kazanılan rozetler net/renkli, kazanılmamışlar `ColorFiltered` (greyscale
  matrisi) + `Opacity(0.5)` ile gri tonlu/soluk — ama adı VE kazanma koşulu
  HER İKİ durumda da HER ZAMAN görünür (kullanıcının açık isteği; "gizli"
  rozetler kategorisi için bu kural GEÇERLİ OLMAYACAK, ayrıca ele alınacak).
- **Rozet Kazanma Anı (`BadgeCelebrationOverlay`)** — `AdBlurOverlay` ile
  AYNI konumda, `MaterialApp.builder`'ın EN DIŞINDA (`home:` içindeki
  içerik başka bir rota push edilince BOYANMADIĞI için "HER YERDE" görünürlük
  yalnızca bu seviyede garanti ediliyor) mount ediliyor.
  `pendingBadgePopup`'ı dinleyip değiştiğinde `GoalConfettiBurst` (Hedef
  Tamamlama Kutlaması'ndaki AYNI widget, yeniden kullanıldı) + bir
  `ModalBarrier(dismissible: false)` + ortalanmış bir kutlama kartı gösteriyor
  (görsel + ad + hedef + `l10n.storeCoinAmount(zcReward)` ile ZC ödülü).
  **`rootNavigatorKey` global anahtarı** (`utils/root_navigator_key.dart`,
  `MaterialApp.navigatorKey`'e bağlı) — bu seviyenin `context`'i Navigator'ın
  ATASI OLMADIĞI için "Ödülü Al"dan sonra Rozetler Galerisi'ni açmak
  `Navigator.of(context)` YERİNE bunu kullanıyor (push bildirimi/deep-link
  handler'larındaki standart Flutter çözümü). "Ödülü Al" butonu
  `BadgeProvider.markClaimed(id)` + `CoinProvider.earnBadgeReward(amount,
  badgeId)` + `pendingBadgePopup.value = null` + Rozetler Galerisi'ni açmayı
  TEK `onPressed`'te yapıyor.
  - **Gerçek bug, testte yakalandı — `late final AnimationController` field
    initializer'ı `dispose()`'da çöküyordu.** `AnimatedThemeOverlay`'deki
    (bkz. "Premium/Animasyonlu temalar" bölümü) BİREBİR AYNI gotcha: bir
    rozet HİÇ kazanılmadan (yani `_confettiController`'a hiç erişilmeden)
    bu widget dispose edilirse, `late final`'in tembel başlatıcısı İLK
    erişimi `dispose()`'a denk getirip "Looking up a deactivated widget's
    ancestor is unsafe" hatası fırlatıyordu — `flutter test`'te `widget_test.
    dart`'taki 45 testin NEREDEYSE HEPSİ bu yüzden başarısız oldu (rozet HİÇ
    tetiklenmeyen sıradan testler bile). **Düzeltme:** `_confettiController`
    `initState()`'te KOŞULSUZ, erkenden oluşturuluyor.
- **`CoinProvider.earnBadgeReward(int amount, String badgeId)`** — `earnDailyLoginReward`
  ile AYNI "dinamik miktar, tek satırlık `_earn` çağrısı" deseni; `_earn`'ün
  merkezi ses yolu sayesinde (bkz. "Zibo Dokunma Sesi" bölümü) coin kazanma
  sesi OTOMATİK çalıyor, ayrı bir ses çağrısı EKLENMEDİ.
- **İstikrar Rozetleri (5 rozet, `assets/images/*_rozet.png`):** İlk Adım
  (`first_step`, ilk 7 günlük hedef döngüsü, 10 ZC), 1 Haftalık Seri
  (`week_streak`, 7 gün, 30 ZC), 1 Aylık Seri (`month_streak`, 30 gün,
  100 ZC), Demir İrade (`iron_will`, 90 gün, 250 ZC), Yılmaz (`unyielding`,
  180 gün, 500 ZC). Görseller kullanıcının masaüstündeki `rozetler/istikrar
  rozetleri` klasöründen `tool/process_badge_images.dart` ile (dosya adları
  AYNEN korunarak, yalnızca 512px'e küçültülerek) `assets/images/`e
  kopyalandı — `pubspec.yaml`'ın zaten bütün olarak dahil ettiği
  `assets/images/` glob'u sayesinde ayrı bir pubspec değişikliği GEREKMEDİ.
- **`Costume`/`AppThemeOption` ile AYNI "id → ARB-getter" `localizedName`/
  `localizedRequirement` deseni** (`ZiboBadgeDefinition`, bkz. "Kostümler"
  bölümündeki "const veri listesindeki sabit alan kullanıcıya görünüyorsa
  ARB'ye taşınmalı" kuralı) — 10 yeni ARB anahtarı (`badgeName<X>`/
  `badgeRequirement<X>`, TR/EN/ES) + `badgesTriggerTooltip`/
  `badgesGalleryTitle`/`badgeCategoryConsistency`/`badgeClaimRewardButton`.
  ZC ödül metni YENİ bir anahtar GEREKTİRMEDİ — mevcut `storeCoinAmount`
  (`"{amount} ZC"`) yeniden kullanıldı.
- **Firestore rules — YENİ bir kural GEREKMEDİ.** Mevcut genel
  `users/{uid}/state/{stateDoc}` kuralı (`coinState` HARİÇ tam yetkili, bkz.
  "Coin Ekonomisi Güvenliği" bölümü) zaten `badgeState`/`appStreakState`'i
  kapsıyor.
- **Test: 25 YENİ test** — `app_streak_provider_test.dart` (8, gün-değişimi/
  atlama/kalıcılık), `badge_provider_test.dart` (9, eşik/eş-zamanlı-çoklu-
  kazanım/markClaimed/kalıcılık), `badge_coordinator_test.dart` (3, eager
  reconcile/dinleyici/dispose), `badges_gallery_screen_test.dart` (2,
  ColorFiltered sayımı + overflow), `badge_celebration_overlay_test.dart` (2,
  popup içeriği + tam claim akışı), `badges_trigger_button_test.dart` (1,
  doğrudan galeri açılışı). `widget_test.dart`'ın `_buildAppWithClock()`
  yardımcısına `AppStreakProvider`/`BadgeProvider` eklendi (`RootScreen`'in
  ihtiyaç duyduğu HER provider kuralı, bkz. "Test kalıpları" bölümü — 
  eklenmeseydi hata yalnızca ilgili testte değil ondan SONRAKİ TÜM testlerde
  görünürdü). **Toplam: 450 test** (449 geçti + 1 önceden belgelenmiş
  `audioplayers` flake'i).
- **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca `flutter
  test` (450 test) + `flutter build apk --debug` (sorunsuz) ile doğrulandı.
  **Kullanıcının kendi cihazında doğrulaması gereken:** Rozetler
  tetikleyicisinin göz yormayan nabız animasyonuyla doğru konumda göründüğü,
  dokununca ARA bir pop-up OLMADAN doğrudan galeri açıldığı, bir rozet
  kazanıldığında (ör. uygulamayı 7 gün art arda açarak) konfetinin
  UYGULAMANIN HER YERİNDE (hangi ekranda olunursa olsun) patladığı, kutlama
  kartındaki görsel/ad/koşul/ödülün doğru göründüğü, "Ödülü Al"a basınca
  ZC'nin bakiyeye eklenip galerinin açıldığı ve rozetin artık renkli/net
  göründüğü.
- **Sonraki adım (kullanıcı henüz İSTEMEDİ, proaktif başlanmayacak):** diğer
  beş kategori (Modül Ustalığı, Koleksiyon, Sadakat, Sosyal/Paylaşım, Gizli/
  Eğlenceli) — `BadgeCategory` enum'una yeni değerler + `allBadges`'e yeni
  listeler eklemek yeterli olacak, `BadgesGalleryScreen`/`BadgeCelebrationOverlay`
  hâlihazırda kategoriden bağımsız/genel yazıldı.
  > **TARİHSEL — bu not artık GEÇERSİZ, ALTI kategorinin HEPSİ tamamlandı**
  > (bkz. bu bölümün altındaki "İkinci" → "Altıncı ve SON kategori" alt
  > bölümleri) — yalnızca o anki planlama bağlamı için tutuluyor, projenin
  > "geçmiş karar + neden değiştiği birlikte kalır" convansiyonuyla.
- **2026 güncellemesi — USB üzerinden gerçek cihaz testinden sonra beş küçük
  UI/davranış düzeltmesi.** Kullanıcı isteği (verbatim özet): Çark/Günlük
  Giriş popup'ları biraz yukarı kaydırılsın; Rozet popup'ı DAHA FAZLA yukarı
  kaydırılsın + arkasındaki "siyah yuvarlak arkaplan" kaldırılsın (yalnızca
  PNG kullanılsın) + görsel biraz büyütülsün + konfeti animasyonu AYNEN
  kalsın; Rozetler Galerisi'ndeki rozet boyutları büyütülsün + ad/açıklama
  biraz aşağı kaydırılsın + en alta Zibo Coin ikonuyla ödül miktarı
  eklensin; Ayarlar'a GEÇİCİ bir "rastgele rozet kazan" test düğmesi
  eklensin.
  - **Popup konumları:** `WheelScreen`'in `Expanded(child: Center(...))`'ı
    `Expanded(child: Align(alignment: Alignment(0, -0.25), ...))`'a,
    `DailyRewardsScreen`'in `Dialog(...)`'ı `alignment: Alignment(0, -0.2)`
    almaya, `BadgeCelebrationOverlay`'in `Center(...)`'ı (diğerlerinden
    DAHA FAZLA yukarı) `Align(alignment: Alignment(0, -0.45), ...)`'e
    çevrildi — üçü de yalnızca DÜŞEY konum, hiçbir animasyon/mantık
    DEĞİŞMEDİ (`GoalConfettiBurst`/`_confettiController` hiç dokunulmadı).
  - **GERÇEK, önemli bir asset bug'ı bulunup düzeltildi — "siyah yuvarlak
    arkaplan" kullanıcının hayal ettiği bir widget dekorasyonu DEĞİL,
    `yilmaz_efsanevi_rozet.png`nin (Yılmaz/Efsanevi, en üst tier İstikrar
    rozeti) kaynak dosyasına GERÇEKTEN BAKILI, ŞEFFAF OLMAYAN düz siyah bir
    kare arka plandı.** Diğer 4 rozet PNG'si (+ `popup_rozet_icon.png`)
    incelenip TAMAMEN temiz/şeffaf olduğu doğrulandı — yalnızca bu TEK
    dosya farklıydı (muhtemelen üretici görsel aracın "transparent" yerine
    "black" arka planla dışa aktarması). Mevcut `tool/remove_bg.dart`
    yalnızca BEYAZ arka planları hedeflediği için (`r/g/b >= 245` eşiği) bu
    dosyada hiçbir şey YAPMADI — bu yüzden **YENİ, kalıcı bir araç**
    ([tool/remove_black_bg.dart](tool/remove_black_bg.dart)) yazıldı:
    `remove_bg.dart` ile BİREBİR AYNI kenar-flood-fill + feather deseni,
    yalnızca eşik SİYAHA çevrilmiş (`r/g/b <= 12` "arka plan", dekontaminasyon
    255'e değil 0'a doğru). **Doğrulama, Read/önizleme aracına GÜVENİLMEDEN
    pikselin GERÇEK alfa değeri ölçülerek yapıldı** — düzeltmeden sonra bile
    önizleme aracı köşeleri SİYAH göstermeye devam etti (bu aracın tam
    saydam pikselleri `(0,0,0,0)` RGB'siyle, beyaz değil SİYAH bir kanvasa
    kompozit ettiği anlaşıldı — bir görüntüleyici tuhaflığı, gerçek bir veri
    sorunu DEĞİL); geçici bir pixel-inceleme betiğiyle köşe bölgesinin
    `alpha=0` olduğu VE sanat eserinin merkezinin (`alpha≈252`) etkilenmediği
    KANITLANDI, sonra inceleme betiği silindi. **Ders — genelleştirilebilir:**
    bir PNG önizlemesinin transparanlığı YANLIŞ/tutarsız gösterebileceği
    unutulmamalı — kuşkulu bir asset için nihai kanıt her zaman pikselin
    HAM alfa değeri, önizleme aracının o pikseli hangi renkte "gösterdiği"
    DEĞİL.
    `badge_celebration_overlay.dart`'ın `_BadgeClaimCard`'ında zaten PNG'yi
    saran bir Container/dekorasyon YOKTU — "arkaplanı kaldırma" işi TAMAMEN
    asset düzeltmesinden ibaretti, widget kodunda kaldırılacak bir şey
    çıkmadı. Görsel boyutu da `Image.asset(..., width: 128, height: 128)`'den
    `width: 152, height: 152`'ye büyütüldü.
  - **Rozetler Galerisi kartı** (`_BadgeGalleryCard`) — görsel 88'den 108'e
    büyütüldü, görsel↔ad arası boşluk 8'den 14'e çıkarıldı (ad/açıklama
    "biraz aşağı" kaydı), kartın en altına yeni bir satır eklendi
    (`Image.asset('assets/images/zibo_coin.png', width: 16, height: 16)` +
    `Text(l10n.storeCoinAmount(badge.zcReward))`) — `CoinBalanceWidget`/
    `CostumeCard`'daki AYNI coin ikonu kullanımı. **`childAspectRatio`
    overflow dersi (bu projede TEKRARLAYAN bir kategori — bkz. Kostüm/Tema/
    Manifest kartları) yine devreye girdi:** eklenen içerik kartı
    uzattığı için `0.6`'dan `0.5`'e düşürüldü; `badges_gallery_screen_test.
    dart`'taki mevcut overflow testi (`tester.takeException()`) DEĞİŞİKLİKTEN
    SONRA da temiz geçti.
  - **`BadgeProvider.debugGrantRandomBadge()`** (YENİ, GEÇİCİ) —
    `allBadges`'ten henüz kazanılmamış rastgele bir rozeti GERÇEK
    `reconcileConsistencyBadges` akışıyla BİREBİR AYNI şekilde kazandırır
    (kazanılmış say + kalıcı hale getir + `pendingBadgePopup`'a yaz) — ZC
    ödülünü BURADA VERMİYOR, gerçek akışla TUTARLI şekilde yalnızca
    kullanıcı popup'taki "Ödülü Al"a bastığında `CoinProvider.
    earnBadgeReward` çağrılıyor. Tüm rozetler zaten kazanılmışsa `null`
    döner. Ayarlar'a `_BadgeTestPanel` (YENİ, `_CoinTestPanel`/
    `_NotificationDebugPanel` ile AYNI "açıkça GEÇİCİ işaretli, izole
    widget" deseni) eklendi — tek bir "Rastgele Rozet Kazan" butonu, rozet
    sistemi gerçek cihazda doğrulandıktan sonra TAMAMEN kaldırılacak.
  - **Doğrulama:** `flutter test` — tam suite yeşil (450/450, yalnızca
    önceden belgelenmiş `audioplayers`/`home_widget` flake'i hariç — bu
    turun değişiklikleriyle İLGİSİZ). `flutter build apk --debug` sorunsuz.
    **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — kullanıcı bu
    APK'yı kendi USB kablosuyla kurup test edecek. Kontrol edilmesi
    gerekenler: Çark/Günlük Giriş popup'larının hafifçe yukarı kaydığı,
    Rozet kazanma popup'ının DAHA FAZLA yukarıda ve arkasında hiçbir siyah
    arka plan OLMADAN (yalnızca PNG) büyümüş halde göründüğü (özellikle
    Yılmaz/Efsanevi rozeti kazanıldığında/test edildiğinde), Rozetler
    Galerisi'ndeki kartların büyümüş görsel + aşağı kaymış metin + alttaki
    ZC ödül satırıyla (coin ikonu dahil) taşmadan göründüğü, ve Ayarlar'ın
    en altındaki geçici "Rozet Test Paneli"nin rastgele bir rozeti gerçek
    konfeti+popup akışıyla kazandırdığı.
  - **2026 DÜZELTME — kullanıcı gerçek cihazda test edip bir ekran görüntüsüyle
    "siyah yuvarlak" yorumunu netleştirdi: yukarıdaki asset-fix DOĞRU bir
    bulguydu ama ASIL şikayet edilen yer FARKLIYDI.** Kullanıcı Ana Sayfa'nın
    bir ekran görüntüsünü paylaşıp "şu rozet popup'ının siyah yuvarlak diye
    bahsettiğim yer bu" diyerek doğrudan `BadgesTriggerButton`'ın (Ana
    Sayfa'daki tetikleyici DÜĞMESİ, kutlama popup'ı DEĞİL) arkasındaki
    `RadialGradient`/`boxShadow` DAİRESİNİ işaret etti — "popup" kelimesini
    kullanıcı kutlama modalı için DEĞİL, bu tetikleyici düğme için kullanmış.
    **Düzeltme:** `BadgesTriggerButton`'daki dairesel gradyan/gölge
    `Container` dekorasyonu TAMAMEN kaldırıldı — pulse animasyonu artık
    doğrudan çıplak `popup_rozet_icon.png`'ye uygulanıyor
    (`Transform.scale(scale: scale, child: child)`, `child` = `Image.asset`),
    hiçbir Container/gradyan/gölge YOK. `_size` de (64 → 80) büyütüldü.
    Ayrıca kullanıcı Günlük Ödül/Rozetler tetikleyicilerinin "çok iç içe"
    (üst üste biniyormuş gibi) durduğunu bildirdi — `root_screen.dart`'taki
    `Align` konumları güncellendi: Çark/Günlük Ödül `Alignment(±1, -0.8)` →
    `Alignment(±1, -0.88)` (biraz daha yukarı), Rozetler `Alignment(1,
    -0.55)` → `Alignment(1, -0.58)` (Günlük Ödül'le arası büyütüldü — artık
    arkasında dekorasyon/gölge OLMADIĞI için daha az gerekli olsa da fazladan
    nefes payı bırakıldı). **Bir önceki turdaki `badge_celebration_overlay.
    dart` değişiklikleri (kartın yukarı kayması, görselin büyütülmesi) GERİ
    ALINMADI** — yanlış varsayıma dayansa da zararsız/olumlu bir iyileştirme
    olduğu için korundu.
  - **Rozet Galerisi kartları BİR TUR DAHA ince ayar gördü** — kullanıcı
    isteği: görsel "biraz daha büyüsün, çok değil" (108→118), ad/açıklama
    yazı boyutu büyüsün (`titleSmall`/`bodySmall` → `titleMedium`/
    `bodyMedium`), "10 ZC/30 ZC" metni VE coin ikonu büyüsün (16px→20px ikon,
    `labelSmall`→`labelMedium` metin), VE genel kart çerçevesi ("dikdörtgen
    şeklinde uzun") biraz kısaltılsın — `childAspectRatio` `0.5`'ten `0.62`'ye
    çıkarıldı (kartın FİKSE yüksekliği kısa metinli rozetlerde altta boşluk
    bırakıyordu; oranı büyütmek hem kartı kısalttı hem büyümüş içerik için
    yeterli pay bıraktı — `badges_gallery_screen_test.dart`'taki overflow
    testi doğruluyor).
  - **Doğrulama:** `flutter test` tam suite yeşil (450/450, yalnızca
    önceden belgelenmiş flake hariç). Kullanıcı build'i kurdu ama telefonu
    o an başka bir uygulamayla (Play Store) meşgul olduğu için asistan
    ekranı açıp GÖRSEL doğrulama YAPMADI — kullanıcının kendi
    zamanlamasında kontrol etmesi bekleniyor.

#### İkinci kategori — Modül Ustalığı Rozetleri (6 rozet)

- **2026 yeni özellik.** Kullanıcı isteği: İstikrar Rozetleri'nin AYNI
  mimarisiyle (Firestore kaydı, otomatik tetikleme, kazanınca konfeti +
  detaylı pop-up + "Ödülü Al" + galeriye dönüş) altı yeni rozet — bu sefer
  ARDIŞIK bir seriye DEĞİL, ilgili modülün TOPLAM kayıt sayısına bağlı
  (kullanıcının kendi ifadesiyle: "bu kayıt sayıları ARDIŞIK olmak zorunda
  değil — streak gibi değil — toplam kayıt sayısı bazlı, kullanıcı istediği
  zaman aralığında bu sayıya ulaşabilir").
  - **Şükreden Kalp** (`grateful_heart`) — Şükran Günlüğü'nde toplam 30
    kayıt — 55 ZC. **Su Kahramanı** (`water_hero`) — Su Takibi'nde toplam 30
    GÜN kayıt (tamamlanmış olması ŞART DEĞİL, yalnızca o gün en az bir
    dokunuş) — 55 ZC. **Ruh Hali Kaydedicisi** (`mood_chronicler`) — Ruh
    Hali Takibi'nde toplam 30 kayıt — 55 ZC. **Birikim Ustası**
    (`savings_master`) — Para ve Birikim'de (HANGİ kategoriden geldiği
    önemsiz — Harcama/Birikim/Gelen Para) toplam 20 kayıt — 45 ZC.
    **Hayalperest** (`dreamer`) — Manifest Günlüğü'nde toplam 15 kayıt —
    40 ZC. **Rüya Yorumcusu** (`dream_interpreter`) — Rüya Günlüğü'nde
    toplam 15 kayıt — 40 ZC.
  - **`BadgeCategory` enum'una `moduleMastery` eklendi** (`consistency`'nin
    yanına). YENİ `lib/data/module_mastery_badges.dart` — `consistency_
    badges.dart`'taki `consistencyBadges` deseninin BİREBİR AYNISI, altı
    `ZiboBadgeDefinition`. `allBadges` (hâlâ `consistency_badges.dart`'ta
    tanımlı, dokümantasyonun ZATEN öngördüğü "yeni kategori eklendiğinde
    yalnızca allBadges'e eklenmesi yeterli" notuna TAM uyarak)
    `[...consistencyBadges, ...moduleMasteryBadges]`'e güncellendi.
  - **Sayaç getter'ları — üçü ZATEN vardı, ikisi YENİ eklendi.**
    `GratitudeProvider.entries.length`/`MoodProvider.entries.length`/
    `ManifestProvider.history.length`/`DreamJournalProvider.dreams.length`
    doğrudan kullanılabiliyordu. **YENİ `WaterProvider.totalDaysRecorded`**
    (`_entries.length` — `completedDaysCount`'un AKSİNE hedefe ULAŞILMASINI
    ŞART KOŞMUYOR, yalnızca o gün en az bir dokunuş olmuş mu diye bakıyor,
    "Su Kahramanı"nın "toplam 30 gün KAYIT yap" isteğiyle birebir). **YENİ
    `MoneyProvider.totalEntryCount`** (üç kategorinin [expense/saving/
    income] toplam eleman sayısı — "Birikim Ustası"nın "hangi kategoriden
    geldiği önemsiz" isteğiyle birebir).
  - **`BadgeProvider.reconcileModuleMasteryBadges(...)`** —
    `reconcileConsistencyBadges`'in BİREBİR AYNI "tek slot, en son yeni
    kazanılan `pendingBadgePopup`'a yazılır" deseni, yalnızca altı sayaç
    parametresi (`gratitudeCount`/`waterDaysCount`/`moodCount`/`moneyCount`/
    `manifestCount`/`dreamCount`) alıyor.
  - **`BadgeCoordinator` genişletildi — artık SEKİZ provider'ı dinliyor**
    (Badges HARİÇ: Goals/AppStreak/Gratitude/Water/Mood/Money/Manifest/Dream).
    `_reconcile()` HER İKİ kategoriyi de (`reconcileConsistencyBadges` +
    `reconcileModuleMasteryBadges`) art arda çağırıyor — sekiz provider'dan
    HERHANGİ biri değişince TÜM rozetler yeniden kontrol ediliyor (basit,
    "gereksiz bir rebuild'in maliyeti neredeyse sıfır" felsefesiyle tutarlı,
    bkz. "Günlük Giriş Ödülleri" bölümündeki AYNI genelleştirilebilir ders).
    `RootScreen.initState()`'teki kuruluş çağrısına altı yeni provider
    eklendi (`context.read<GratitudeProvider>()` vb.) — `MoodProvider`/
    `DreamJournalProvider` importları root_screen.dart'a YENİ eklendi
    (diğer dördü zaten import ediliyordu).
  - **`BadgesGalleryScreen` artık kategoriye göre GRUPLU render ediyor.**
    `allBadges` kategoriye göre bir `Map`'e toplanıp `BadgeCategory.values`
    SIRASIYLA (İstikrar → Modül Ustalığı) gösteriliyor; İLK HARİÇ her bölümün
    ÜSTÜNE `SizedBox(20) + Divider(height:1) + SizedBox(16)` ile ince bir
    ayraç ekleniyor (kullanıcının "kategoriler birbirinden görsel olarak
    ayrılsın, örn. ince bir ayraç çizgisiyle" isteği). Kartların kendisi
    (`_BadgeGalleryCard`, `childAspectRatio: 0.62`) DEĞİŞMEDİ.
  - **Görseller** kullanıcının masaüstündeki `rozetler/modul ustalıgı
    rozetleri` klasöründen `tool/process_module_mastery_badge_images.dart`
    (YENİ, `process_badge_images.dart`'ın AYNI "dosya adlarını koru, 512px'e
    küçült" deseni, yalnızca kaynak klasör farklı) ile kopyalandı. **Bu altı
    dosyanın HİÇBİRİNDE önceki `yilmaz_efsanevi_rozet.png` bug'ı (baked-in
    siyah arka plan) YOKTU** — kopyalamadan ÖNCE hem görsel olarak (`Read`)
    hem piksel-alfa ölçümüyle (`img.getPixel(...).a`) doğrulandı, hepsi
    temiz/şeffaf.
  - **ARB — 14 yeni anahtar (TR/EN/ES):** `badgeCategoryModuleMastery` +
    6× `badgeName<X>` + 6× `badgeRequirement<X>` — `ZiboBadgeDefinition.
    localizedName`/`localizedRequirement`'a altışar yeni `case` eklendi
    (`Costume`/`AppThemeOption` ile AYNI "id → ARB-getter" deseni).
  - **`BadgeProvider.debugGrantRandomBadge()` (Ayarlar'daki GEÇİCİ test
    paneli) HİÇBİR DEĞİŞİKLİK GEREKTİRMEDİ** — zaten `allBadges` üzerinden
    genel çalışıyordu, artık on bir rozetin (5+6) HERHANGİ birini rastgele
    kazandırabiliyor.
  - **Firestore rules — YENİ bir kural GEREKMEDİ** (mevcut genel
    `users/{uid}/state/{stateDoc}` kuralı `badgeState`'i zaten kapsıyor,
    bkz. "Coin Ekonomisi Güvenliği" bölümü).
  - **Test: 12 YENİ test.** `badge_provider_test.dart`'a `reconcileModuleMasteryBadges`
    grubu (9 test — eşik altı no-op, altı rozetin HER BİRİ için ayrı bir
    eşik-aşımı senaryosu, çoklu-eş-zamanlı-kazanımda EN SONuncunun kutlama
    sinyaline yazılması, tekrar-bildirmeme, kalıcılık). `badge_coordinator_
    test.dart`'a 3 yeni test (MoneyProvider TEMSİLCİ olarak seçildi —
    tarih kilidi olmayan EN BASİT modül provider'ı; EAGER ilk reconcile
    Modül Ustalığı'nı da kapsıyor, SONRADAN değişince otomatik reconcile,
    dispose sonrası tetiklenmiyor — altı provider'ın HEPSİ için ayrı
    senaryo YAZILMADI, modüle özel eşik mantığı zaten `badge_provider_
    test.dart`ta tam kapsandığı için koordinatörün yalnızca "GERÇEKTEN
    dinliyor mu" doğrulanması yeterli). `badges_gallery_screen_test.dart`'taki
    mevcut iki test `consistencyBadges.length` yerine `allBadges.length`
    kullanacak şekilde güncellendi (artık HİÇ rozet kazanılmamışken 11
    `ColorFiltered` render ediliyor, 5 değil). **Toplam: 462 test** (461
    geçti + 1 önceden belgelenmiş `audioplayers`/`home_widget` flake'i).
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca
    `flutter test` (462 test) + `flutter build apk --debug` (sorunsuz) ile
    doğrulandı; APK cihaza SESSİZCE kuruldu (kullanıcı o an başka bir
    uygulamayla meşgul olduğu için AÇILMADI). **Kullanıcının kendi
    cihazında doğrulaması gereken:** Rozetler Galerisi'nde İstikrar
    Rozetleri'nin ALTINDA, ince bir ayraçla ayrılmış "Modül Ustalığı
    Rozetleri" başlığı + altı yeni rozetin (Şükreden Kalp/Su Kahramanı/Ruh
    Hali Kaydedicisi/Birikim Ustası/Hayalperest/Rüya Yorumcusu) doğru
    görsel/ad/koşul/ödülle göründüğü; Ayarlar'daki geçici "Rastgele Rozet
    Kazan" butonuna birkaç kez basınca artık BU altı rozetin de rastgele
    çıkabildiği; VE (gerçek kullanım senaryosu, saatler/günler sürer)
    ilgili modüllerden birinde (ör. Şükran Günlüğü) 30 kayda ulaşınca
    rozetin GERÇEKTEN otomatik kazanıldığı.

#### Üçüncü kategori — Koleksiyon Rozetleri (4 rozet)

- **2026 yeni özellik.** Kullanıcı isteği: yine AYNI mimari, bu sefer sahip
  olunan kostüm/tema SAYISINA bağlı dört rozet. **Kritik netleştirme,
  kullanıcının kendi ifadesiyle:** "Kostüm/tema SAHİPLİĞİ nasıl kazanılmış
  olursa olsun (parayla satın alınmış veya hedefle/başarıyla ücretsiz
  açılmış fark etmeksizin) sayıma dahil edilsin — rozet, sadece sahip
  olunan toplam kostüm/tema sayısına bakar, kaynağına bakmaz."
  - **Koleksiyoncu** (`collector`) — 5 farklı kostüme sahip ol — 30 ZC.
    **Moda İkonu** (`fashion_icon`) — 10 farklı kostüme sahip ol — 75 ZC.
    **Tam Gardırop** (`full_wardrobe`) — mağazadaki TÜM kostümlere sahip
    ol — 200 ZC **+ özel bir ödül (bkz. altta)**. **Tema Avcısı**
    (`theme_hunter`) — 3 farklı temaya sahip ol — 25 ZC.
  - **`ZiboBadgeDefinition`'a YENİ `hasSpecialReward` alanı (bool,
    varsayılan `false`) eklendi — kullanıcının açık isteği doğrultusunda
    BİLEREK bir YER TUTUCU/bayrak, HENÜZ İŞLEVSEL DEĞİL.** Kullanıcı:
    "Tam Gardırop rozeti özel: kazanıldığında normal ZC ödülüne ek olarak,
    mağazada asla satılmayan, sadece bu rozetle kazanılabilen özel bir
    kostüm/rozet de kullanıcıya verilsin... bu özel ödülün görseli/
    detayları için ayrı konuşacağız, şimdilik sistemde bir 'özel ödül'
    alanı olarak yer tutucu bırak." Bu yüzden `full_wardrobe`
    `hasSpecialReward: true` alıyor ama **kod tarafında HİÇBİR ŞEY
    OTOMATİK VERİLMİYOR** (`CoinProvider`/`CostumeProvider`'a bağlı bir
    "özel ödül ver" çağrısı YOK, henüz gerçek bir kostüm/asset tanımlı
    DEĞİL — icat etmek yerine kullanıcının netleştirmesi bekleniyor) —
    yalnızca UI'da (galeri kartı + kutlama popup'ı) yeni bir
    `badgeSpecialRewardComingSoon` ("Özel Ödül (Yakında)") etiketi,
    `Icons.auto_awesome_rounded` ikonuyla küçük bir NOT olarak gösteriliyor.
  - **`CostumeProvider`'a İKİ yeni getter — `founder_badge` pseudo-kostüm
    id'sini (bkz. "Kurucu Üye Rozeti" bölümü) SAYMAYAN, YANLIŞ POZİTİF
    ÜRETMEYEN bir tasarım:**
    - `ownedRealCostumeCount` — yalnızca `costumes.dart`'taki GERÇEK/
      satılabilir kostümlerden kaçının sahiplenildiğini sayar
      (`costumes.where((c) => isOwned(c.id)).length`) — "Koleksiyoncu"/
      "Moda İkonu" için.
    - `ownsAllCostumes` — **BİLEREK bir SAYIM karşılaştırması
      (`ownedIds.length >= costumes.length`) DEĞİL**, `costumes.every((c)
      => isOwned(c.id))` — her kostümü TEK TEK doğruluyor. Gerekçe: bir
      kullanıcı `founder_badge`'e (satılabilir olmayan bir id) sahipse VE
      gerçek kostümlerin yalnızca N-1'ine sahipse, SAYI zaten
      `costumes.length`'e eşit olabilir — SAYIM tabanlı bir kontrol bunu
      YANLIŞLIKLA "hepsine sahip" sayardı; `every` bu riski taşımıyor. Bu
      ayrım `costume_provider_test.dart`'a eklenen özel bir testle (TAM
      OLARAK bu senaryoyu kuran) KANITLANDI.
  - **`BadgeProvider.reconcileCollectionBadges(...)`** —
    `reconcileModuleMasteryBadges` ile AYNI "tek slot, en son yeni kazanılan
    yazılır" deseni, üç parametre (`ownedCostumeCount`/`ownsAllCostumes`/
    `ownedThemeCount`).
  - **`BadgeCoordinator` genişletildi — artık ON provider'ı dinliyor**
    (önceki sekize `CostumeProvider`/`AppThemeProvider` eklendi). `_reconcile()`
    ARTIK ÜÇ kategoriyi de (`reconcileConsistencyBadges` +
    `reconcileModuleMasteryBadges` + `reconcileCollectionBadges`) art arda
    çağırıyor. `RootScreen.initState()`'teki kuruluş çağrısına iki yeni
    provider eklendi — `CostumeProvider`/`AppThemeProvider` importları
    root_screen.dart'a YENİ eklendi (`RootScreen` bunları daha önce hiç
    okumuyordu).
  - **`BadgesGalleryScreen`'in `_categoryTitle` switch'ine `BadgeCategory.
    collection` case'i eklendi** — mevcut gruplama/ayraç mantığı (bkz.
    "İkinci kategori" bölümü) HİÇBİR DEĞİŞİKLİK GEREKTİRMEDİ, zaten
    `BadgeCategory.values` sırasını genel olarak dolaşıyordu.
  - **Görseller** kullanıcının masaüstündeki `rozetler/Koleksiyon rozetleri`
    klasöründen `tool/process_collection_badge_images.dart` (YENİ, AYNI
    "dosya adlarını koru, 512px'e küçült" deseni) ile kopyalandı — dördü de
    kopyalamadan ÖNCE piksel-alfa ölçümüyle temiz/şeffaf olduğu doğrulandı
    (Yılmaz/Efsanevi rozetindeki bug'ın tekrarlanmadığı).
  - **ARB — 14 yeni anahtar (TR/EN/ES):** `badgeCategoryCollection` + 4×
    `badgeName<X>` + 4× `badgeRequirement<X>` + `badgeSpecialRewardComingSoon`.
  - **`BadgeProvider.debugGrantRandomBadge()` (Ayarlar'daki GEÇİCİ test
    paneli) YİNE HİÇBİR DEĞİŞİKLİK GEREKTİRMEDİ** — `allBadges` üzerinden
    genel çalıştığı için artık on beş rozetin (5+6+4) HERHANGİ birini
    rastgele kazandırabiliyor.
  - **Test: 13 YENİ test.** `badge_provider_test.dart`'a `reconcileCollectionBadges`
    grubu (7 test — eşik altı no-op, dört rozetin her biri için ayrı bir
    eşik-aşımı senaryosu [Koleksiyoncu+Moda İkonu'nun AYNI ANDA kazanılıp
    kutlama sinyalinin EN SONuncuya yazıldığı dahil], tekrar-bildirmeme,
    kalıcılık). `badge_coordinator_test.dart`'a 3 yeni test (CostumeProvider
    TEMSİLCİ — EAGER ilk reconcile Koleksiyon'u da kapsıyor, SONRADAN
    değişince otomatik reconcile, dispose sonrası tetiklenmiyor).
    `costume_provider_test.dart`'a YENİ bir grup (3 test — `ownedRealCostumeCount`/
    `ownsAllCostumes`'un `founder_badge`'i doğru DIŞLADIĞI, özellikle
    "sayı eşleşiyor ama gerçekte hepsi değil" YANLIŞ POZİTİF senaryosu
    AÇIKÇA test edildi). **Toplam: 475 test** (474 geçti + 1 önceden
    belgelenmiş `audioplayers`/`home_widget` flake'i).
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca
    `flutter test` (475 test) + `flutter build apk --debug` (sorunsuz) ile
    doğrulandı; APK cihaza SESSİZCE kuruldu (kullanıcı o an ana ekran
    launcher'ındaydı, aktif bir uygulama İÇİNDE değildi ama yine de
    temkinli davranılıp AÇILMADI). **Kullanıcının kendi cihazında
    doğrulaması gereken:** Rozetler Galerisi'nde Modül Ustalığı'nın
    ALTINDA "Koleksiyon Rozetleri" başlığı + dört rozetin doğru görsel/ad/
    koşul/ödülle göründüğü, "Tam Gardırop" kartının altında "Özel Ödül
    (Yakında)" notunun (ikonla birlikte) belirdiği, Ayarlar'daki test
    panelinin artık BU dört rozeti de rastgele kazandırabildiği, VE
    (gerçek kullanım senaryosu) 5/10 kostüme veya 3 temaya sahip olununca
    ilgili rozetlerin GERÇEKTEN otomatik kazanıldığı.

#### Dördüncü kategori — Sadakat Rozetleri (3 rozet)

- **2026 yeni özellik.** Kullanıcı isteği: yine AYNI mimari, ama İSTİKRAR
  Rozetleri'nden BİLEREK FARKLI — ARDIŞIKLIK (streak) GEREKTİRMİYOR,
  yalnızca TOPLAM kullanım gün SAYISINI veya geçen takvim SÜRESİNİ baz
  alıyor (kullanıcının kendi ifadesiyle: "kullanıcı ara sıra kullansa bile
  zamanla bu rozetleri kazanabilmeli").
  - **İlk Hafta** (`first_week`) — uygulamayı toplam 7 farklı günde aç
    (ardışık OLMASI ŞART DEĞİL) — 15 ZC. **Sadık Dost** (`loyal_friend`) —
    toplam 100 farklı gün — 100 ZC. **Yıl Dönümü** (`anniversary`) —
    Zibo ile tanışmanın (ilk kayıt/hesap oluşturma) üzerinden 1 yıl (365
    gün) geçsin — 300 ZC.
  - **YENİ bir sayaç — `AppStreakProvider.totalDaysOpened`.** Kullanıcının
    "Teknik detay" notu AÇIKÇA İKİ badge'in (İlk Hafta + Sadık Dost) AYNI
    "benzersiz gün sayacı"nı paylaşacağını belirtti — bu, mevcut
    `currentStreak`'ten (bir gün kaçırılınca SIFIRLANIR) BİLEREK FARKLI,
    YENİ bir alan: `totalDaysOpened`, `recordOpenForToday()` YENİ bir gün
    kaydettiği HER SEFERİNDE (streak devam etsin ya da sıfırlansın FARK
    ETMEZ) +1 artan, MONOTONİK bir sayaç. **Göç:** bu alan eklenmeden
    ÖNCEki kayıtlı veride yoksa `currentStreak`'e düşülüyor (en azından o
    kadar gün açıldığı KESİN biliniyor — gerçek toplam daha BÜYÜK olabilir
    ama bu göç ASLA fazla SAYMAZ, yalnızca olası bir az sayım — bilinçli
    bir sadeleştirme).
  - **`ProfileProvider.firstUsedAt`/`daysSinceFirstUsed()` ZATEN VARDI —
    "Yıl Dönümü" için YENİ HİÇBİR ŞEY EKLENMEDİ.** Bu alan "Zibo ile Bağ
    Seviyesi" özelliği için önceden eklenmişti (bkz. "Profil" bölümü) —
    Sadakat Rozetleri onu DOĞRUDAN yeniden kullanıyor.
  - **`BadgeProvider.reconcileLoyaltyBadges(...)`** —
    `reconcileCollectionBadges` ile AYNI "tek slot" deseni, iki parametre
    (`totalDaysOpened`/`daysSinceFirstUsed`).
  - **`BadgeCoordinator` genişletildi — artık ON BİR provider'ı dinliyor**
    (önceki ona `ProfileProvider` eklendi — `AppStreakProvider` zaten
    vardı, `totalDaysOpened` için AYRI bir provider GEREKMEDİ). `_reconcile()`
    ARTIK DÖRT kategoriyi de art arda çağırıyor. `RootScreen`'e YENİ bir
    import GEREKMEDİ (`ProfileProvider` zaten `HomeWidgetSyncCoordinator`
    kurulumu için import ediliyordu).
  - **`BadgesGalleryScreen`'in `_categoryTitle` switch'ine `BadgeCategory.
    loyalty` case'i eklendi** — mevcut gruplama/ayraç mantığı YİNE HİÇBİR
    DEĞİŞİKLİK GEREKTİRMEDİ.
  - **Görseller** kullanıcının masaüstündeki `rozetler/sadakat rozetleri`
    klasöründen `tool/process_loyalty_badge_images.dart` (YENİ, AYNI desen)
    ile kopyalandı — üçü de kopyalamadan ÖNCE piksel-alfa ölçümüyle temiz/
    şeffaf olduğu doğrulandı.
  - **ARB — 10 yeni anahtar (TR/EN/ES):** `badgeCategoryLoyalty` + 3×
    `badgeName<X>` + 3× `badgeRequirement<X>`.
  - **`BadgeProvider.debugGrantRandomBadge()` YİNE HİÇBİR DEĞİŞİKLİK
    GEREKTİRMEDİ** — artık on sekiz rozetin (5+6+4+3) HERHANGİ birini
    rastgele kazandırabiliyor.
  - **Test: 16 YENİ test.** `app_streak_provider_test.dart`'a 7 yeni test
    (`totalDaysOpened`'in sıfırdan başlaması, ilk çağrıda 1 olması, aynı
    gün tekrar ARTMAMASI, bir gün ATLANIP `currentStreak` sıfırlansa BİLE
    `totalDaysOpened`'in SIFIRLANMAMASI [en kritik test — Sadakat'in TÜM
    "ardışık değil" garantisinin kanıtı], 7 ARDIŞIK OLMAYAN günde 7 olması,
    kalıcılık, ve eski-format göç testi [`totalDaysOpened` alanı OLMAYAN
    kayıtlı veriden `currentStreak`'e düşme]). `badge_provider_test.dart`'a
    `reconcileLoyaltyBadges` grubu (6 test). `badge_coordinator_test.dart`'a
    3 yeni test (AppStreakProvider'ın KENDİSİ TEMSİLCİ — zaten kurulu
    olduğu için yeni bir provider setUp'ı gerekmedi; hepsi 7 ARDIŞIK
    OLMAYAN gün açılışıyla kuruluyor). **Toplam: 491 test** (490 geçti + 1
    önceden belgelenmiş `audioplayers`/`home_widget` flake'i).
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca
    `flutter test` (491 test) + `flutter build apk --debug` (sorunsuz) ile
    doğrulandı; APK cihaza SESSİZCE kuruldu (kullanıcı o an aktif olarak
    bir oyun oynuyordu, açılmadı). **Kullanıcının kendi cihazında
    doğrulaması gereken:** Rozetler Galerisi'nde Koleksiyon'un ALTINDA
    "Sadakat Rozetleri" başlığı + üç rozetin doğru görsel/ad/koşul/ödülle
    göründüğü, Ayarlar'daki test panelinin artık BU üç rozeti de rastgele
    kazandırabildiği, VE (gerçek kullanım senaryosu, GÜNLER/AYLAR sürer)
    uygulamayı ARA SIRA (ardışık olmadan) toplam 7/100 farklı günde açınca
    veya 1 yıl geçince ilgili rozetlerin GERÇEKTEN otomatik kazanıldığı.

#### Beşinci kategori — Sosyal/Paylaşım Rozetleri (3 rozet)

- **2026 yeni özellik.** Kullanıcı isteği: yine AYNI mimari, bu sefer YENİ
  bir mekanik İCAT ETMEDEN — mevcut "Zibonu Paylaş" özelliği VE "Arkadaşını
  Davet Et" (Referral) sistemiyle DOĞRUDAN bağlantılı üç rozet. Kullanıcının
  açık isteği: "paylaşım butonu tıklandığında veya referral sistemi başarılı
  bir davet kaydettiğinde, ilgili rozet kontrolü otomatik tetiklensin."
  - **İlk Paylaşım** (`first_share`) — kullanıcı bir başarı kartını
    ("Zibonu Paylaş" özelliğiyle) sosyal medyaya/WhatsApp'a İLK KEZ
    paylaştığında — 15 ZC. **Elçi** (`ambassador`) — Davet Et ile 1
    arkadaşını BAŞARIYLA davet ettiğinde — 30 ZC. **Topluluk Kurucusu**
    (`community_founder`) — Davet Et ile 5 arkadaşını BAŞARIYLA davet
    ettiğinde — 150 ZC.
  - **`BadgeCategory` enum'una `social` eklendi** (`loyalty`'nin yanına).
    YENİ `lib/data/social_badges.dart` — önceki dört kategori dosyasının
    BİREBİR AYNISI, üç `ZiboBadgeDefinition`. `allBadges`
    `[...consistencyBadges, ...moduleMasteryBadges, ...collectionBadges,
    ...loyaltyBadges, ...socialBadges]`'e güncellendi.
  - **İKİ FARKLI kaynak türü — OLAY-tabanlı vs. DURUM-tabanlı reconcile,
    bu kategoride İLK KEZ gerekli oldu.** Önceki dört kategorinin
    HEPSİ saf DURUM (bir sayaç/eşik) sorguluyordu; `first_share` ise
    GERÇEK bir OLAYA (bir paylaşımın BAŞARIYLA tamamlanması) bağlı —
    `BadgeProvider.reconcileSocialBadges({required bool
    hasSharedAtLeastOnce, required int successfulReferralCount})` bu
    ikisini TEK bir metotta birleştiriyor, ama İKİ AYRI çağrı sitesinden
    FARKLI değerlerle besleniyor:
    1. **`ZiboShareSheet._share()`'in BAŞARI dalı** — paylaşım
       `shareImageBytes(...)` GERÇEKTEN tamamlandıktan HEMEN SONRA (ama
       `Navigator.pop()`'tan ÖNCE, `if (!mounted) return;` guard'ıyla)
       `hasSharedAtLeastOnce: true` ile çağrılıyor — bu, `first_share`'in
       kazanılabileceği TEK yer. **Ayrı bir kalıcı "hiç paylaştı mı"
       bayrağı EKLENMEDİ** — `BadgeProvider._earned`'ın kendi idempotent
       bookkeeping'i (`if (_earned.containsKey(badge.id)) continue;`)
       zaten HER paylaşımda güvenle tekrar çağrılabilmesini sağlıyor.
    2. **`BadgeCoordinator._reconcile()`'ın rutin geçişi** —
       `hasSharedAtLeastOnce: false` (bu yoldan `first_share` ASLA
       kazanılmıyor) + `successfulReferralCount:
       referral.successfulReferralCount` ile, `ReferralProvider`
       DEĞİŞTİĞİNDE (bkz. altta) `ambassador`/`community_founder`'ı
       reaktif olarak kontrol ediyor.
  - **`BadgeCoordinator` genişletildi — artık ON İKİ provider'ı dinliyor**
    (önceki on bire `ReferralProvider` eklendi). `RootScreen.initState()`
    hem `BadgeCoordinator(..., referral: context.read<ReferralProvider>())`
    hem AYRICA (koordinatör kurulumundan BAĞIMSIZ, `postFrameCallback`'in
    DIŞINDA) `context.read<ReferralProvider>().refresh()` çağırıyor —
    `DailyRewardsProvider.reconcileForToday()` ile AYNI "reconcile-on-resume"
    felsefesi: `successfulReferralCount` sunucu tarafında (`processReferralRewards.
    js`'in bir SONRAKİ GitHub Actions çalıştırmasında) artırılıyor,
    istemci bunu ANINDA GÖRMÜYOR, yalnızca `refresh()` çağrılınca. Bu yüzden
    `RootScreen.didChangeAppLifecycleState`'in `resumed` dalına da (mevcut
    `touchLastActive`/`syncAll`/`recordOpenForToday` çağrılarının YANINA)
    `context.read<ReferralProvider>().refresh()` eklendi — uygulama HER
    öne geldiğinde tazeleniyor, yalnızca soğuk başlangıçta DEĞİL.
  - **`ZiboShareSheet`'e YENİ importlar (`provider`, `BadgeProvider`,
    `ReferralProvider`) eklendi** — bu widget'ın önceden HİÇ Provider
    bağımlılığı YOKTU (yalnızca constructor parametreleri + kendi state'i).
  - **`BadgesGalleryScreen`'in `_categoryTitle` switch'ine `BadgeCategory.
    social` case'i eklendi** — mevcut gruplama/ayraç mantığı YİNE HİÇBİR
    DEĞİŞİKLİK GEREKTİRMEDİ.
  - **Görseller** kullanıcının masaüstündeki `rozetler/sosyal paylaşım
    rozetleri` klasöründen `tool/process_social_badge_images.dart` (YENİ,
    AYNI "dosya adlarını koru, 512px'e küçült" deseni) ile kopyalandı —
    üçü de kopyalamadan ÖNCE piksel-alfa ölçümüyle temiz/şeffaf olduğu
    doğrulandı (Yılmaz/Efsanevi rozetindeki bug'ın tekrarlanmadığı).
  - **ARB — 10 yeni anahtar (TR/EN/ES):** `badgeCategorySocial` + 3×
    `badgeName<X>` + 3× `badgeRequirement<X>`.
  - **`BadgeProvider.debugGrantRandomBadge()` (Ayarlar'daki GEÇİCİ test
    paneli) YİNE HİÇBİR DEĞİŞİKLİK GEREKTİRMEDİ** — artık yirmi bir
    rozetin (5+6+4+3+3) HERHANGİ birini rastgele kazandırabiliyor.
  - **Test: 18 YENİ test.** `badge_provider_test.dart`'a
    `reconcileSocialBadges` grubu (7 test — eşik altı no-op,
    `hasSharedAtLeastOnce`/`ambassador`/`community_founder`'ın her biri
    için ayrı bir senaryo [İKİSİNİN BİRLİKTE kazanılıp kutlama sinyalinin
    EN SONuncuya yazıldığı dahil], tekrar-bildirmeme, kalıcılık).
    `badge_coordinator_test.dart`'a (`FakeFirebaseFirestore` ile) 3 yeni
    test — ReferralProvider TEMSİLCİ, sunucu tarafı sayaç artışı
    `firestore.collection('users').doc(uid).collection('state').
    doc('referralState').set({'successfulReferralCount': N})` ile DOĞRUDAN
    simüle edilip `referral.refresh()` çağrılarak `notifyListeners()`
    tetikleniyor (EAGER ilk reconcile Sosyal/Paylaşım'ı da kapsıyor,
    SONRADAN `refresh()` ile değişince otomatik reconcile, dispose sonrası
    tetiklenmiyor). **Gerçek bir test hatası bulunup düzeltildi —
    `zibo_share_sheet_test.dart`'ın bağımsız test uygulaması hem
    `BadgeProvider`/`ReferralProvider`'ı (yeni `context.read` çağrıları
    yüzünden) HEM `SharedPreferences.setMockInitialValues({})`'ı
    (`CloudStateStore`'un ikisi de kullandığı için) EKSİK bırakıyordu —
    "Paylaş'a basınca..." testi ProviderNotFoundException'ı sessizce
    yutup sheet'i HİÇ KAPATMIYORDU (`_share()`'in genel `catch (_)`
    bloğu); `MultiProvider` sarmalayıcısı + `setUp`'a
    `SharedPreferences.setMockInitialValues({})` eklenerek düzeltildi.**
    **Toplam: 500 test** (499 geçti + 1 önceden belgelenmiş
    `audioplayers`/`home_widget` flake'i).
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** — yalnızca
    `flutter test` (500 test) + `flutter build apk --debug` (sorunsuz) ile
    doğrulandı; APK cihaza SESSİZCE kuruldu (kullanıcı o an aktif olarak
    BitLife oynuyordu, açılmadı). **Kullanıcının kendi cihazında
    doğrulaması gereken:** Rozetler Galerisi'nde Sadakat'in ALTINDA
    "Sosyal Rozetler" başlığı + üç rozetin doğru görsel/ad/koşul/ödülle
    göründüğü, Ayarlar'daki test panelinin artık BU üç rozeti de rastgele
    kazandırabildiği, "Zibonu Paylaş"tan GERÇEKTEN bir paylaşım
    tamamlanınca İlk Paylaşım rozetinin ANINDA kazanıldığı, VE (gerçek
    kullanım senaryosu, sunucu tarafı cron'u gerektirir) Davet Et ile
    1/5 arkadaş başarıyla davet edilip uygulama bir SONRAKİ açılışta/
    öne gelişte Elçi/Topluluk Kurucusu rozetlerinin otomatik kazanıldığı.

#### Altıncı ve SON kategori — Gizli/Eğlenceli Rozetler (3 rozet)

- **2026 yeni özellik — bu kategori diğer beşinden İKİ yönden KÖKTEN
  FARKLI: bir GİZLİLİK mekaniği taşıyor VE zaman penceresi BİLEREK cihazın
  KENDİ saatine bağlı.** Kullanıcı isteği: **Gece Kuşu** (`night_owl`) —
  cihaz saatine göre gece yarısı (00:00) ile sabah 05:00 arası 30 kez
  uygulamayı aç — 777 ZC. **Erken Kuş** (`early_bird`) — cihaz saatine göre
  sabah 06:00-08:00 arası 30 kez uygulamayı aç — 777 ZC. **Denge Ustası**
  (`balance_master`) — AYNI takvim günü içinde uygulamadaki 7 modülün
  (Hedef Takibi, Şükran Günlüğü, Ruh Hali Takibi, Su Takibi, Manifest
  Günlüğü, Rüya Günlüğü, Para ve Birikim) HEPSİNE en az bir kayıt ekle —
  777 ZC. Kullanıcının açık notu: "Kurucu Üye" rozeti (bkz. o bölüm) BU
  kategoriye DAHİL EDİLMEDİ — görseli AYRI bir turda gelecek.
  - **Belirsizlik netleştirmesi (kod yazmadan ÖNCE çözüldü, kullanıcıya
    SORULMADAN):** kullanıcının "Gizlilik Mekaniği" paragrafı ORTADA
    kendiyle çelişen tek bir cümle içeriyordu ("AMA 777zC VİTRİNDE
    GÖRÜNSÜN SADECE") — ama paragrafın HEMEN ARDINDAN gelen, gramatik
    olarak TAM ve açık son cümlesi ("Diğer kategorilerdeki rozetlerde
    olduğu gibi kazanma koşulu ve ödül miktarı ÖNCEDEN gösterilmesin")
    belirsizliği kesin olarak çözüyordu — o ortadaki cümle muhtemelen bir
    yazım/otokorrekt kazası (belki de "sadece '???' etiketi görünsün"
    demek isterken yanlışlıkla "777zC" yazılmış). Bu ikinci, net cümleye
    göre hareket edildi: KAZANILMADAN ÖNCE isim/koşul/ÖDÜL MİKTARININ
    ÜÇÜ de galeri kartında GİZLİ.
  - **`ZiboBadgeDefinition`'a YENİ `bool isHidden` alanı eklendi**
    (varsayılan `false`, `hasSpecialReward` ile AYNI "opsiyonel bayrak"
    deseni). `BadgeCategory` enum'una `hidden` eklendi (artık ALTI değer).
    YENİ `lib/data/hidden_badges.dart` — üç `ZiboBadgeDefinition`, hepsi
    `isHidden: true` + `zcReward: 777`. Ayrıca `hiddenBadgeMysteryImageAsset`
    (`assets/images/gizli_rozet.png`) sabiti — üçünün de kazanılana kadar
    PAYLAŞTIĞI ortak "gizem" görseli (kullanıcının kendi tasarımı — bir
    şapkalı gölge figür + "?" — zaten "bilinmiyor" hissini taşıyan bir
    illüstrasyon).
  - **`BadgesGalleryScreen`'in `_BadgeGalleryCard`'ına `hiddenLocked =
    badge.isHidden && !earned` kontrolü eklendi.** `hiddenLocked` iken:
    (1) görsel `hiddenBadgeMysteryImageAsset` (badge'in KENDİ görseli
    DEĞİL) — ve normal kazanılmamış rozetlerin AKSİNE `ColorFiltered`/
    `Opacity` ile GRİLEŞTİRİLMİYOR de (gizem görseli zaten "bilinmiyor"
    hissini taşıyan bir tasarım, AYRICA soluklaştırmaya gerek YOK); (2)
    isim VE koşul metinlerinin İKİSİ de `l10n.badgeHiddenPlaceholder`
    ("???") — badge'in gerçek `localizedName`/`localizedRequirement`'ı HİÇ
    ÇAĞRILMIYOR bile; (3) alttaki ZC ödül satırı (VE varsa `hasSpecialReward`
    notu) TAMAMEN GİZLİ — `if (!hiddenLocked) ...` bloğuna alındı.
    **Kazanıldıktan SONRA `hiddenLocked` `false` olur ve kart TÜM diğer
    rozetlerle BİREBİR aynı kod yolundan render edilir** — `isHidden`
    bayrağının kazanma MANTIĞINA (`BadgeProvider.reconcileHiddenBadges`)
    hiçbir etkisi YOK, yalnızca bu GÖRÜNTÜLEME kararını etkiliyor.
  - **`BadgeCelebrationOverlay`'in kutlama popup'ı HİÇBİR DEĞİŞİKLİK
    GEREKTİRMEDİ** — zaten kayıtsız şartsız `badge.imageAsset`/
    `localizedName`/`localizedRequirement`/`zcReward`'ı gösteriyordu; bu
    popup'ın TETİKLENDİĞİ an ZATEN "rozet YENİ kazanıldı" anı olduğu için
    (`pendingBadgePopup`, `reconcileHiddenBadges` içinde YALNIZCA yeni
    kazanılan bir rozet için ayarlanıyor) hiçbir `isHidden` kontrolüne
    gerek YOK — kullanıcının "kazanıldığı anda normal akış devam etsin"
    isteği KOD DEĞİŞİKLİĞİ GEREKTİRMEDEN zaten karşılanıyordu.
  - **YENİ `HiddenBadgeProvider`** (`lib/providers/hidden_badge_provider.dart`)
    — `AppStreakProvider`'ın AYNI `CloudStateStore` (Varyant A) deseni,
    `{'nightOwlDays': [...], 'earlyBirdDays': [...]}` (ISO tarih dizileri).
    **BİLEREK `AppStreakProvider`'ın AKSİNE `TrustedTimeProvider` DEĞİL,
    cihazın KENDİ `DateTime.now()`'unu kullanıyor** — kullanıcının "cihaz
    saatine göre" ifadesini İKİ kez tekrarlaması, `motivation_quote_
    selector.dart`'taki `timeBucketFor`'un AYNI "kozmetik/eğlenceli
    özellik, kullanıcının O ANKİ GERÇEK yerel saatini yansıtmalı, doğrulanmış-
    UTC-çıpaya bağlı KALMAMALI" gerekçesiyle TUTARLI. **Kabul edilen
    ödünleşim, provider'ın kendi dokümantasyonunda AÇIKÇA belgelendi:** bu,
    `AppStreakProvider`'daki "cihaz saatini manipüle ederek erken
    kazanamaz" güvenlik garantisini TAŞIMIYOR — düşük-riskli/eğlence
    odaklı kabul edilen bir özellik olduğu ve kullanıcının AÇIKÇA bunu
    istediği için, `Coin Ekonomisi Güvenliği` bölümündeki genel
    "client-authoritative ekonomi" risk kabulüyle AYNI kategoride kabul
    edildi.
    - **Gün-bazlı DEDUP — kullanıcının metninde AÇIKÇA istenmemiş ama
      trivial-gaming'e karşı BİLİNÇLİ bir tasarım kararı.** "30 kez
      uygulamayı aç" talimatı KELİMESİ KELİMESİNE "30 açılış olayı" olarak
      okunabilirdi — ama bu, pencere içinde art arda hızlı aç/kapat ile
      SANİYELER içinde 777 ZC kazanmaya izin verirdi. Bunun yerine
      `recordOpenForCurrentTime()` `Set<DateTime>.add(today)` ile TEK bir
      takvim gününü EN FAZLA BİR KEZ sayıyor (`Set.add`'in kendi idempotent
      davranışı, ayrı bir "bugün zaten sayıldı mı" kontrolüne gerek
      BIRAKMADAN) — bu, projenin `AppStreakProvider.totalDaysOpened`'daki
      (Sadakat Rozetleri) AYNI "benzersiz GÜN sayacı" felsefesiyle tutarlı.
  - **`BadgeProvider.reconcileHiddenBadges({nightOwlDaysCount,
    earlyBirdDaysCount, hasAllModulesToday})`** — diğer beş `reconcileX`
    metoduyla BİREBİR AYNI "tek slot, en son yeni kazanılan yazılır" deseni.
  - **`BadgeCoordinator` genişletildi — artık ON ÜÇ provider'ı dinliyor**
    (önceki on ikiye `HiddenBadgeProvider` eklendi). **`hasAllModulesToday`
    ("Denge Ustası") koordinatörün KENDİ, BU turda YENİ bir hesaplaması** —
    YEDİ modül provider'ının ("Hedef Takibi, Şükran Günlüğü, Ruh Hali
    Takibi, Su Takibi, Manifest Günlüğü, Rüya Günlüğü, Para ve Birikim")
    HEPSİ ZATEN koordinatörün constructor parametreleriydi (Modül Ustalığı
    Rozetleri'nden beri) — YENİ bir provider bağımlılığı GEREKMEDİ, yalnızca
    mevcut yedisinin "bugün bir kaydı var mı" getter'ları `&&` ile
    birleştirildi (`goals.hasAnyRecordToday && gratitude.isTodayComplete &&
    mood.todayMood != null && water.todayEntry != null && manifest.
    hasEntryToday && dream.hasEntryToday && money.hasEntryToday`).
  - **DÖRT provider'a "bugün bir kaydı var mı" getter'ı EKLENDİ** (üçü zaten
    vardı — `GratitudeProvider.isTodayComplete`/`MoodProvider.todayMood`/
    `WaterProvider.todayEntry`, doğrudan kullanılabiliyordu):
    `GoalsProvider.hasAnyRecordToday` (`_goals.any((g) => g.completedDates.
    contains(today))`), `ManifestProvider.hasEntryToday`, `MoneyProvider.
    hasEntryToday` (HANGİ kategoriden geldiği önemsiz — üçünü de tarıyor),
    `DreamJournalProvider.hasEntryToday`. **`DreamJournalProvider`'ınki
    BİLEREK ham `DateTime.now()` kullanıyor** — bu provider'ın (diğer
    modül provider'larının AKSİNE) hiç enjekte edilebilir bir saati YOK
    (`addDream` da zaten doğrudan `DateTime.now()` kullanıyor), bu yüzden
    yeni getter AYNI kaynağı paylaşarak öz-tutarlı kalıyor.
  - **`RootScreen`'e kablolama — `AppStreakProvider.recordOpenForToday()`
    ile BİREBİR AYNI İKİ tetikleme noktası:** `initState`'in
    postFrameCallback'i (soğuk başlangıç) + `didChangeAppLifecycleState`'in
    `resumed` dalı (uygulama HER öne gelişte — kullanıcı gece yarısı
    civarında uygulamayı arka planda tutup öne getirse bile sayılsın diye).
    `BadgeCoordinator(...)` çağrısına `hiddenBadge:
    context.read<HiddenBadgeProvider>()` eklendi. `main.dart`'ta
    `HiddenBadgeProvider(uid: uid)` — **BİLEREK `now:` parametresi
    VERİLMİYOR** (varsayılan cihaz saati kullanılsın diye, `AppStreakProvider`'ın
    `now: () => context.read<TrustedTimeProvider>().now()` enjeksiyonunun
    TAM TERSİ).
  - **Görseller** kullanıcının masaüstündeki İKİ AYRI klasörden geldi —
    üç gerçek rozet `rozetler/GizliEğlenceli Rozetler` ALT klasöründe,
    paylaşılan gizem görseli (`gizli_rozet.png`) bir üstteki `rozetler`
    klasöründe (ALT klasörün DIŞINDA) — `tool/process_hidden_badge_images.dart`
    (YENİ, önceki kategori betiklerinden FARKLI olarak bir `Directory.
    listSync()` DEĞİL, açık bir dosya YOLU listesi kullanıyor, çünkü tek
    bir kaynak klasörden okumuyor) bunu doğru şekilde ele alıp dördünü de
    (dosya adları AYNEN korunarak, 512px'e küçültülerek) kopyaladı — hepsi
    kopyalamadan ÖNCE piksel-alfa ölçümüyle temiz/şeffaf olduğu doğrulandı.
  - **ARB — 10 yeni anahtar (TR/EN/ES):** `badgeCategoryHidden` +
    `badgeHiddenPlaceholder` ("???", HER ÜÇ dilde de AYNI literal ama
    projenin "kullanıcıya görünen HER metin ARB'de olmalı" konvansiyonu
    gereği yine de bir ARB anahtarı) + 3× `badgeName<X>` + 3×
    `badgeRequirement<X>`.
  - **`BadgeProvider.debugGrantRandomBadge()` (Ayarlar'daki GEÇİCİ test
    paneli) YİNE HİÇBİR DEĞİŞİKLİK GEREKTİRMEDİ** — artık yirmi bir rozetin
    (5+6+4+3+3+3) HERHANGİ birini rastgele kazandırabiliyor; gizli
    rozetlerden biri rastgele seçilirse bile `reconcileConsistencyBadges`
    ile BİREBİR AYNI "gerçek akışla kazandır" yolundan geçtiği için galeri
    kartı da doğru şekilde (kazanılmış olarak, gerçek görsel/isim/koşul/
    ödülle) güncellenir — test paneli `isHidden`'ı hiç BİLMİYOR bile,
    bilmesine de GEREK YOK.
  - **Test: 29 YENİ test.** YENİ `hidden_badge_provider_test.dart` (10 test
    — gündüz saatlerinde no-op, gece yarısı-05:00 arası HER saat sayaç
    artışı, 06:00-08:00 arası HER saat sayaç artışı, saat TAM 05:00/08:00
    sınırında HİÇBİR sayaç artmaz [aralığın KAPALI olduğunun kanıtı], AYNI
    GÜN içinde pencerede birden fazla açılış sayacı YALNIZCA BİR KEZ artırır
    [trivial-gaming koruması], 30 FARKLI gecede 30'a ulaşma, notifyListeners
    yalnızca gerçek değişiklikte, kalıcılık, isReady). `badge_provider_
    test.dart`'a `reconcileHiddenBadges` grubu (8 test — eşik altı no-op,
    üç rozetin her biri için ayrı eşik-aşımı senaryosu [night_owl+early_bird
    AYNI ANDA kazanılıp kutlama sinyalinin EN SONuncuya (early_bird)
    yazıldığı dahil], kazanılan rozetin `isHidden: true` taşımasının
    kazanma mantığını ETKİLEMEDİĞİNİN AÇIK kanıtı, tekrar-bildirmeme,
    kalıcılık). `badge_coordinator_test.dart`'a 5 yeni test (HiddenBadgeProvider
    TEMSİLCİ olarak EAGER/SONRADAN/dispose üçlüsü + `hasAllModulesToday`'in
    koordinatörün KENDİ YEDİ-modül birleştirme mantığını doğrulayan İKİ
    AYRI test — biri yedisi de dolunca kazanıyor, diğeri BİRİ [Rüya
    Günlüğü] eksik kalınca kazanmıyor). `badges_gallery_screen_test.dart`'taki
    mevcut iki test güncellendi (`ColorFiltered` sayımı artık `allBadges.
    length - hiddenBadges.length` [kazanılmamış hidden badge'ler bu sayıma
    HİÇ GİRMİYOR]) + 2 YENİ test (kazanılmadan önce "???"×6 + gerçek
    isim/koşul HİÇBİR YERDE sızmıyor; kazanıldıktan sonra diğer TÜM
    rozetlerle BİREBİR aynı görünüyor + kazanılmamış diğer ikisi HÂLÂ
    "???" gösteriyor). DÖRT provider'ın kendi test dosyasına (`goals_
    provider_test.dart`/`manifest_provider_test.dart`/`dream_journal_
    provider_test.dart`/`money_provider_test.dart`) birer odaklı test
    eklendi (yeni "bugün kaydı var mı" getter'larının HER biri için).
    **Toplam: 529 test** (528 geçti + 1 önceden belgelenmiş `audioplayers`/
    `home_widget` flake'i — `git stash` ile doğrulandı, DEĞİŞMEDEN ÖNCEKİ
    baza karşı da AYNI şekilde başarısız oluyor, bu turun değişiklikleriyle
    İLGİSİZ).
  - **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILAMADI — cihaz bu turun
    sonunda bağlı DEĞİLDİ** (`adb devices` yalnızca offline bir emülatör
    gösterdi, kullanıcının fiziksel cihazı [8b9a14f1] YOKTU) — yalnızca
    `flutter test` (529 test) + `flutter build apk --debug` (sorunsuz,
    APK diskte hazır bekliyor) ile doğrulandı, kuruluma dahi
    GEÇİLEMEDİ. **Kullanıcının kendi cihazını bağlayıp kendi USB test
    akışıyla (bu oturumda kurulan norm) doğrulaması gereken:** Rozetler
    Galerisi'nde Sosyal'in ALTINDA "Gizli Rozetler" başlığı altında ÜÇ
    kartın hepsinin AYNI gizem görseliyle + "???" etiketiyle (isim/koşul/
    ödül HİÇBİRİ görünmeden) listelendiği; Ayarlar'daki test panelinin
    artık bu üç rozeti de rastgele kazandırabildiği VE bir gizli rozet
    rastgele kazanıldığında galeri kartının GERÇEK görsel/isim/koşul/ödülle
    (artık "???" DEĞİL) güncellendiği; VE (gerçek kullanım senaryosu,
    saatler/günler sürer) cihaz saatine göre gece yarısı-05:00 veya
    06:00-08:00 arasında 30 farklı günde uygulamayı açınca veya aynı gün
    7 modülün hepsine kayıt eklenince ilgili rozetlerin GERÇEKTEN otomatik
    kazanıldığı, VE kazanıldığı anda kutlama popup'ının (konfeti + gerçek
    görsel/isim/koşul/777 ZC + "Ödülü Al") NORMAL akışla (diğer
    rozetlerden hiçbir farkı olmadan) çalıştığı.
