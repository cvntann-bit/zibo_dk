# ARŞİV — Kostümler, Zibo Poz/Animasyon Sistemi, Temalar

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 735–1392).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

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
> **TARİHSEL — bu alt bölümün TAMAMI (goal-tabanlı ücretsiz kostüm açma mekaniği) 2026'da
> KULLANICI İSTEĞİYLE TAMAMEN KALDIRILDI** (bkz. altta "Kostüm/Tema Hediye Sistemi — Rozet
> Kazanımına Bağlı" bölümü, `data/badge_gift_rewards.dart`) — `CostumeUnlockType`/
> `CostumeUnlockRequirement`/`Costume.unlockRequirement`/`CostumeProvider.reconcileGoalUnlocks`/
> `CostumeCard`'ın ilerleme satırı hepsi SİLİNDİ. Kullanıcının gerekçesi: kostümler artık YALNIZCA
> parayla satın alınabilsin VEYA (çok daha DAR kapsamlı, yalnızca DOKUZ belirli rozetin verdiği)
> bir rozet hediyesiyle kazanılsın — "TÜM kostümler hedefle açılabilsin" mantığı TAMAMEN terk
> edildi. Bu bölüm SİLİNMEDİ, yalnızca o zamanki kararın GEREKÇESİNİ (özellikle
> `childAspectRatio`/fiyat-zorluk ölçekleme dersleri) kaybetmemek için tarihsel bağlam olarak
> tutuluyor — aşağıdaki `CostumeUnlockType`/`reconcileGoalUnlocks`/`unlockRequirement`
> referanslarının HİÇBİRİ artık koda karşılık GELMİYOR.
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

