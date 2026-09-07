# ARŞİV — Ana Ekran Widget'ları — tüm turlar

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 7430–8339).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

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

