# ARŞİV — Rüya/Şükran/Ruh Hali/Su/Manifest Günlükleri, Profil

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 2486–3412).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

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
- **2026 yeni özellik — örnek öneri metinleri (placeholder), her gün değişen.** Kullanıcı isteği:
  bugünün formundaki üç metin kutusuna, kullanıcı yazmaya başlamadan önce ilham verici bir öneri
  (`hintText`) gösterilsin, her gün değişsin. YENİ [gratitude_prompts.dart](lib/data/gratitude_prompts.dart)
  — `gratitudePromptForField(DateTime, int, Locale)` saf/deterministik fonksiyonu.
  > **TARİHSEL/DÜZELTME NOT — İLK sürüm BİLEREK yalnızca Türkçe bırakılmıştı**
  > (`zibo_event_messages.dart`'ın "TR only for now" kararıyla AYNI gerekçe — kullanıcı yalnızca
  > Türkçe örnek vermişti, çeviri İSTENMEMİŞTİ). Kullanıcı GERÇEK cihazda test edip "diğer dillere
  > geçince de Türkçe kalıyor" diye bildirdi — bu, diğer TÜM söz havuzlarının
  > (`motivation_pools.dart`/`zibo_messages.dart` vb.) zaten uyguladığı "uygulama dili neyse içerik
  > de o dilde olsun" beklentisiyle tutarsızdı; İLK kapsam kararı YANLIŞ çıktı, düzeltildi (bkz.
  > altta).
  - **Artık `motivation_pools.dart`'taki BİREBİR AYNI `xTr/xEn/xEs` + `xForLocale(Locale)` deseni**
    — `gratitudePromptsTr`/`gratitudePromptsEn`/`gratitudePromptsEs` (her biri 27 öneri, BİREBİR
    aynı uzunlukta — index-tabanlı seçimin güvenle çalışması için şart), çeviriler kelimesi
    kelimesine DEĞİL, Zibo'nun sıcak tonunu o dilde doğal duracak şekilde koruyan bir UYARLAMA
    (`motivation_pools.dart`'ın AYNI felsefesi). `gratitudePromptsForLocale(Locale)` per-pool bir
    Türkçe geri düşüşü de taşıyor (bir dil ileride boşaltılsa bile TÜM sistem Türkçe'ye düşmez).
  - **`gratitude_journal_screen.dart`, `Localizations.localeOf(context)`'ten ZATEN türettiği
    `locale` değişkenini** (aynı değişken `gratitudeQuotesForLocale`/`applyAddressTerm` için de
    kullanılıyor) `gratitudePromptForField`'a üçüncü parametre olarak geçiriyor — dil değişince
    (Ayarlar > Dil) konuşma balonlarındaki AYNI "index sabit, metin o anki dile göre çözülür"
    deseniyle ANINDA doğru dile geçiyor.
  - **Rotasyon deterministik gün-bazlı, gerçek rastgele DEĞİL** — `gratitudePromptForField(date,
    fieldIndex, locale)` yıl+ay+gün'den türeyen basit bir "gün sırası" + `fieldIndex * 9`'luk sabit
    bir ofsetle (havuzun üçte biri, 27/3=9) havuzdan seçim yapıyor — üç alan AYNI ANDA farklı
    önerilerle dolup HEPSİ birlikte, HER GÜN değişiyor. Gerçek rastgelelik/tekrar-önleme mekanizması
    GEREKMEDİ çünkü placeholder yalnızca kullanıcı yazmaya BAŞLAMADAN ÖNCE görünüyor (normal
    `TextField` placeholder davranışı, `hintText` metin girilince otomatik kayboluyor) —
    `motivation_pools.dart`'taki gibi bir "art arda tekrar etmesin" garantisine ihtiyaç yok.
  - **`gratitude_journal_screen.dart`'ın ana formundaki (bugünün girişi) ÜÇ `TextField`'a
    eklendi** — `_GratitudeEditDialogContent`'in (geçmiş bir günü DÜZENLEME diyaloğu) alanlarına
    BİLEREK eklenmedi, çünkü o alanlar zaten MEVCUT metinle dolu geliyor, placeholder hiç
    görünmeyecekti.
  - **Test:** `test/gratitude_prompts_test.dart` (10 test — üç havuzun da büyüklüğü/tekrarsızlığı/
    BİREBİR eşit uzunluğu, aynı gün üç alanın farklı öneriler döndüğü, aynı gün+alan için
    deterministik olduğu, gün değişince önerinin değiştiği, döndürülen her önerinin gerçekten
    havuzda olduğu, EN/ES'in doğru havuzdan döndüğü, bilinmeyen bir dilin Türkçe'ye düştüğü, AYNI
    gün+alan için üç dilin metninin FARKLI olduğu, `gratitudePromptsForLocale`'in doğru havuzu
    döndürdüğü).

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
- **2026 yeni özellik — Level/XP Sistemi entegrasyonu: günün İLK check-in'i +5 XP verir.**
  `MoodProvider.setTodayMood()` coin VERMEDİĞİ için (`CoinProvider`'ı hiç bilmiyor) bu XP
  `CoinProvider._earn()`'ün merkezi kancasından GEÇMİYOR — `mood_tracking_screen.dart`'taki YENİ
  `_selectMood(mood)` yardımcısı, `setTodayMood()`'u çağırmadan ÖNCE `provider.todayMood == null`
  kontrolü yapıp yalnızca GÜNÜN İLK seçiminde `context.read<XpProvider>().addXp(5)` çağırıyor —
  aynı gün ruh halini DEĞİŞTİRMEK (üzerine yazma) ikinci bir XP tetiklemiyor. Bkz. "Level/XP
  Sistemi" bölümü.

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

