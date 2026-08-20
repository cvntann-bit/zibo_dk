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

- **State management:** `provider` paketi. Yirmi adet `ChangeNotifier`, `main.dart`'ta
  `MultiProvider` ile uygulama köküne bağlanıyor: `TrustedTimeProvider`, `AuthLinkProvider`
  (2026 yeni özellik — bkz. "Google Hesap Bağlama" bölümü), `AppThemeProvider`,
  `CoinProvider`, `CostumeProvider`, `DailyRewardsProvider`, `DreamJournalProvider`,
  `FavoriteQuotesProvider`, `GoalsProvider`, `GratitudeProvider`, `LocaleProvider`,
  `ManifestProvider`, `MoneyProvider`, `MoodProvider`, `NotificationProvider`,
  `OnboardingProvider`, `ProfileProvider`, `ThemeProvider`, `WaterProvider`,
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
- **Servis soyutlamaları:** `AdService` ve `PurchaseService` soyut arayüzler; şu an sadece
  `MockAdService`/`MockPurchaseService` (600ms gecikmeyle her zaman başarı dönen sahte
  implementasyonlar) var. Gerçek AdMob/IAP entegrasyonu geldiğinde yalnızca bu arayüzleri uygulayan
  yeni sınıflar yazılıp `CoinProvider`'a constructor'dan verilecek — `CoinProvider` ve onu çağıran
  ekranların hiçbir satırı değişmeyecek. `ShareService`/`NotificationService`/`ManifestPhotoService`
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
  bonusu 50, 30-gün bonusu 250, referans 100 — harcama: streak freeze 80, kişilik modu 500, replik
  paketi 150, kozmetik parametrik 100-300 aralığı).
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
- **2026 güncellemesi — ödül alınınca bir geçiş (interstitial) reklamı da gösteriliyor.** Kullanıcı
  isteği: "kişi günlük giriş ödülünü alınca da geçilebilir reklam olsun" — BİLEREK ÖDÜLLÜ
  (rewarded) DEĞİL, "Zibo'ya Art Arda Dokunma" bölümündeki AYNI `CoinProvider.
  showInterstitialAd()` çağrısı (bkz. o bölüm). `_DailyRewardsScreenState._claimDay()`,
  `earnDailyLoginReward(amount)`'tan HEMEN SONRA `unawaited(coin.showInterstitialAd())`
  çağırıyor — coin bakiyesini/işlem geçmişini HİÇ etkilemiyor, günde en fazla BİR kez tetiklenir
  (ödül zaten günde bir kez alınabildiği için ayrı bir sınırlama koduna gerek YOK). Reklam
  yüklenemezse (ağ yok, envanter boş) `showInterstitialAd()` sessizce `false` döner, ödülün
  kendisi HİÇ etkilenmez — coin zaten reklamdan ÖNCE eklenmiş durumda.
  - **Test gotcha'sı — gerçek `AdMobAdService` kullanan bir teste YENİ bir reklam çağrısı
    eklemek "A Timer is still pending" hatasına yol açtı:** `widget_test.dart`'taki "Günlük Giriş
    Ödülleri: bugünün kutucuğuna dokununca ödül alınır..." testi `const DijitalKankaApp()`
    (varsayılan, gerçek `AdMobAdService`) kullanıyordu — `showInterstitialAd()`'ın `flutter_test`
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
      **Kullanım Koşulları** — ikisi de `LegalPlaceholderScreen`'e (YENİ, tek parametreli
      `title`/`body` alan paylaşımlı bir widget — iki AYRI ekran dosyası yerine, ikisi de yapısal
      olarak birebir aynı olduğu için) push ediliyor, şu an `settingsLegalPlaceholderBody` ARB
      metnini ("Bu içerik yakında burada olacak.") gösteriyor — gerçek hukuki metinler hazır
      olduğunda yalnızca bu iki `LegalPlaceholderScreen(body: ...)` çağrısındaki `body` parametresi
      güncellenecek, yeni bir ekran/route GEREKMİYOR.
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
- **Coin Test Paneli kullanıcı isteğiyle tamamen kaldırıldı** (bkz. Yerelleştirme bölümü — bu, dil
  desteğiyle AYNI değişiklik setinde yapıldı). **Su Takibi'nin günlük hedef ayarı BURADA DEĞİL** —
  Su Takibi'nin kendi ekranındaki AppBar ayar ikonunda yaşıyor (bkz. "Su Takibi" bölümündeki
  Tarihçe notu; başlangıçta burada bir kart olarak yaşıyordu, modülün TEK ayarı olduğu için
  kullanıcı isteğiyle modülün kendi ekranına taşındı).

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
    - **İstikrar:** `%40` aktif hedeflerin güncel döngüdeki ortalama ilerlemesi `+ %60` son 8
      haftada tamamlanan TAM 7-günlük döngü sayısı (haftada-bir-tamamlama beklentisine oranlanır)
      — geçmiş performansa güncel andan daha fazla ağırlık veriliyor, çünkü istikrar tek bir
      döngünün ortasında yakalanmaktan çok zaman içindeki tutarlılığı ölçüyor.
    - **Öz Saygı ve Sağlık:** son 30 günün kaçında Su Takibi'ndeki günlük hedefin tamamlandığı
      (kayıt hiç girilmemiş günler de "tamamlanmadı" sayılır, 30 sabit payda — birkaç gün kullanıp
      bırakmak yapay yüksek puana yol açmasın diye).
  - **Bulunan gerçek davranış — İstikrar kartı pratikte HİÇBİR ZAMAN "veri yok" göstermez:**
    `GoalsProvider` ilk kurulumda otomatik bir örnek hedef ekliyor (bkz. "Hedef Takibi" bölümü),
    bu yüzden `goals.goals` neredeyse her kullanıcı için baştan boş DEĞİL — İstikrar kartı bu
    yüzden hemen hemen her zaman 0 puanla (kırmızı, "veri var" durumunda) başlıyor, teşvik
    mesajı YERİNE. Bu bilinçli olarak bug OLARAK ele alınmadı (0 puanlı kırmızı gösterge zaten
    kendi başına bir teşvik sinyali) ama testlerde AÇIKÇA belgelendi (bkz. `profile_stats_test.
    dart`) ki gelecekte biri bunu "neden boş durumu hiç görmüyorum" diye bug sanmasın.
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

### Zibo ADS (reklamsız deneyim mockup'ı) ([ad_free_promo_trigger.dart](lib/utils/ad_free_promo_trigger.dart), [ad_free_promo_sheet.dart](lib/widgets/ad_free_promo_sheet.dart))
- **2026 yeni özellik — TAMAMEN GÖRSEL BİR MOCKUP, gerçek bir satın alma akışı YOK.** Kullanıcı
  isteği (verbatim özet): Mağaza ziyaretlerinde ara sıra gösterilen, üstte kırmızı bir "Zibo ADS"
  şeridi olan, reklamsız olmanın faydalarını listeleyen, "Satın Al" butonu ŞİMDİLİK yalnızca bir
  "Yakında!" mesajı gösteren, kullanıcının kapatabildiği (zorunlu olmayan) bir tanıtım ekranı.
  Gerçek AdMob/IAP entegrasyonu geldiğinde (bkz. "Şu an mock/placeholder olan şeyler" bölümü)
  `_maybeShowAdFreePromo`/`showAdFreePromoSheet`'in "Satın Al" `onPressed`'i gerçek bir satın alma
  akışına (muhtemelen `PurchaseService` soyutlamasına, `CoinProvider`'ın kullandığı desenle aynı)
  bağlanacak — bu ARAYÜZ/TETİKLEME kablolaması o zaman DEĞİŞMEYECEK, yalnızca buton içindeki eylem.
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
  - **`static const _totalPages = 9` elle sabitlenmiş bir tamsayı, `_moduleIntros.length`'ten
    TÜRETİLMEDİ** — Dart'ta `List.length`, `const` bir liste üzerinde bile bir `static const`
    ifadesinde kullanılamıyor (derleme hatası: "The property 'length' can't be accessed... in a
    constant expression"). **`_moduleIntros` listesi değişirse bu sabit ELLE güncellenmeli**
    (1 isim + modül sayısı + 1 kapanış).
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
  - **4 betik** (`src/dailyMotivation.js`, `src/streakReminder.js`, `src/dailyRewardReminder.js`,
    `src/reEngagement.js`) — mantık Cloud Functions taslağıyla BİREBİR AYNI, yalnızca "ne zaman
    çalıştırıldıkları" artık `onSchedule` yerine GitHub Actions `schedule:` cron'u:
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
      silindi); artık GÜNDE TEK bir tetikleme var, `cron: '7 6 * * *'` (09:07 Europe/Istanbul) —
      dakika BİLEREK `:07` (GitHub'ın "yoğun" dediği dakikaların DIŞINDA). Betik artık TÜM
      kullanıcılara AYNI çalıştırmada, AYNI rastgele seçilmiş sözle gönderiyor (kullanıcıya göre
      FARKLI dakika nüansı feda edildi) — sıkı 15dk'lık pencere kontrolü de kaldırılıp yerine
      yalnızca GitHub'ın çalıştırmayı KATASTROFİK derecede geç (07:00-13:00 Istanbul dışında)
      tetiklemesine karşı geniş bir güvenlik ağı (`SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE`,
      `dailyMotivation.js`) kondu. **Ders — genel kural bu dört workflow'un HEPSİNE uygulandı:**
      GitHub Actions cron'larında dakika alanı olarak ASLA `:00/:15/:30/:45` kullanmayın, bunun
      yerine `:07` gibi sıra dışı bir dakika seçin — tek-tetiklemeli workflow'lar (aşağıdaki
      diğer üçü) bu yüzden çökmüyordu (yalnızca geç çalışıyorlardı, bir "pencere dışı" reddi
      yoktu) ama onlar da AYNI riski taşıdığı için dakikaları `:07`'ye kaydırıldı.
    - **Streak Hatırlatması** — `7 17 * * *` (UTC) ≈ 20:00 Istanbul. `users/{uid}/state/goals`'u
      okuyup en az bir hedefin bugün işaretlenmediğini kontrol ediyor; hiç hedef yoksa göndermiyor.
    - **Günlük Ödül Hatırlatması** — `7 12 * * *` (UTC) ≈ 15:00 Istanbul. **BİLİNEN SINIRLAMA
      (kullanıcıya açıkça belirtildi):** Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
      mi" alanı YOK (bkz. "Şans Çarkı" bölümü), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
      claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.
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
  `settings_screen_test.dart` (aynı bölüm). **`test/wheel_screen_test.dart` KISA SÜRE var oldu,
  SONRA SİLİNDİ** — Şans Çarkı sonrası reklam denemesiyle birlikte geldi, kullanıcı o özelliği
  istemeyince (bkz. "Zibo'ya Art Arda Dokunma → Geçiş Reklamı" bölümündeki geri alma notu) testi
  de anlamsızlaştığı için kaldırıldı.
  **Toplam: 276 test.**
- `widget_test.dart` içindeki `_buildAppWithClock()` yardımcı fonksiyonu enjekte edilebilir saatli
  testler için — **`RootScreen`'in ihtiyaç duyduğu HER provider'ı içermeli** (`AppThemeProvider`,
  `AuthLinkProvider`, `CoinProvider`, `CostumeProvider`, `DailyRewardsProvider`,
  `FavoriteQuotesProvider`, `GoalsProvider`, `GratitudeProvider`, `ManifestProvider`,
  `MoneyProvider`, `NotificationProvider`, `ProfileProvider`, `SoundEffectsProvider`,
  `ThemeProvider`, `TrustedTimeProvider`, `WaterProvider`, `ZiboPoseProvider`), çünkü `RootScreen`
  tüm sekmeleri hemen kuruyor (artık `ProfileScreen` de bir sekme olduğu için onun transitif olarak
  izlediği TÜM provider'lar da burada olmalı — bkz. "Alt Gezinme Çubuğu" bölümündeki Profil↔Birikim
  yer değiştirme notu). **Gotcha (gerçekten yaşandı):**
  `AppThemeProvider` `main.dart`'a eklenirken bu yardımcıya eklenmesi UNUTULMUŞTU — sonuç, o
  yardımcıyı kullanan İLK testte değil, `ProviderNotFoundException`'ın `widget_test.dart`'ın
  KENDİSİNDEN SONRA gelen HER testi (aynı test ikili dosyasında art arda koştukları için) etkilemesi,
  tek dosyada 20 test başarısızlığına yol açması oldu (bkz. "Temalar" bölümü). **`main.dart`'a yeni
  bir `ChangeNotifierProvider` eklerken bu yardımcıyı GÜNCELLEMEYİ unutmayın** — unutulursa hata
  yalnızca doğrudan ilgili testte değil, ondan sonraki TÜM testlerde görünür, kökeni bulmak zorlaşır.
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

- `MockPurchaseService` — gerçek IAP (uygulama içi satın alma) SDK'sı hâlâ bağlanmadı. **AdMob
  ARTIK gerçek** (bkz. altta "AdMob Entegrasyonu" bölümü) — `MockAdService` yalnızca testlerde
  enjekte edilen bir sahte olarak kaldı.
  - **YAPILMASI GEREKENLER (gerçek IAP bağlanırken ASLA atlanmamalı — bkz. "Coin Ekonomisi
    Güvenliği" bölümü):** `IapPurchaseService.purchaseCoinPackage()` gerçek bir satın alma akışı
    tamamlandığında coin'i DOĞRUDAN EKLEMEMELİ — makbuz (receipt/purchase token), Google Play
    Developer API'ye karşı SUNUCU TARAFINDA (Cloud Function veya eşdeğer bir backend, İSTEMCİDE
    DEĞİL) doğrulanmadan `CoinProvider._earn()` ÇAĞRILMAMALI. İstemci tarafı `in_app_purchase`
    paketinin "satın alma başarılı" callback'i TEK BAŞINA yeterli GÜVEN kaynağı DEĞİL — bir mod
    APK bu callback'i doğrudan sahte tetikleyebilir. Doğru akış: istemci satın almayı başlatır →
    Play Store makbuzu döner → istemci bu makbuzu (coin miktarıyla BİRLİKTE) bir Cloud
    Function'a gönderir → Function, Google Play Developer API (`purchases.products.get`) ile
    makbuzun GERÇEKTEN GEÇERLİ ve BU UYGULAMAYA ait olduğunu doğrular → yalnızca DOĞRULANMIŞSA
    Function Admin SDK ile `coinState`'i (rules'u bypass ederek) günceller.
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

## AdMob Entegrasyonu ([ad_service.dart](lib/services/ad_service.dart), [admob_ad_service.dart](lib/services/admob_ad_service.dart))

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

### Reklamlar tam ekranı kaplamıyor (bug düzeltmesi) — `AdActivity` tema override + blur yedek katmanı

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

### Zibo'ya Art Arda Dokunma → Geçiş (Interstitial) Reklamı / Reklamsız Zibo Teklifi ([home_screen.dart](lib/screens/home_screen.dart), [ad_service.dart](lib/services/ad_service.dart), [admob_ad_service.dart](lib/services/admob_ad_service.dart))

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
  - **Reklam karşılığı coin (Şans Çarkı + Mağaza'nın Ücretsiz kartı):** `AdMobAdService.
    showRewardedAd()`'ın `onUserEarnedReward` callback'i gerçek AdMob SDK'sından geliyor (bu, saf
    bir istemci-tarafı flag'den daha güvenilir — Google'ın kendi reklam gösterim mantığına bağlı)
    ama YİNE DE istemci tarafında değerlendiriliyor, sunucu tarafı doğrulama (SSV) YOK (bkz. altta
    4. madde).
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
