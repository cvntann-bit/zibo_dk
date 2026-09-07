# ARŞİV — Rozet Sistemi (6 kategori), Hedef ardışık gün + farming, Kostüm/Tema Hediye Sistemi

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 8340–9677).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

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

#### Kurulumdan hemen sonraki iki düzeltme — gizli rozetlerde ödül miktarı + "Tema Avcısı" tekrar tekrar çıkma bug'ı

- **1) Gizli/Eğlenceli Rozetler'de ödül miktarı ARTIK kazanılmadan önce de
  görünüyor.** Kullanıcı gerçek cihazda test ettikten hemen sonra
  netleştirdi: "bu gizli rozetlerin altına 777 ZC ve ikonu ekle" — bir
  önceki turdaki ilk yorumum ("AMA 777zC VİTRİNDE GÖRÜNSÜN SADECE" cümlesi
  bir yazım kazası olmalı, isim/koşulLA BİRLİKTE ödül de gizlensin
  demek istiyor olmalı) YANLIŞ çıktı — kullanıcı GERÇEKTEN o cümleyi
  kastetmiş: yalnızca isim/koşul "???" kalsın, ZC ödül miktarı/ikonu HER
  ZAMAN görünsün. `_BadgeGalleryCard`'daki ZC ödül `Row`'unu saran `if
  (!hiddenLocked) ...` koşulu KALDIRILIP satır koşulsuz render edilecek
  şekilde değiştirildi — `hiddenLocked` kontrolü artık YALNIZCA isim/koşul
  metinlerini ("???" ile) ve görseli (mystery image) etkiliyor.
  `ZiboBadgeDefinition.isHidden`/`hidden_badges.dart`'ın doc yorumları da
  buna göre güncellendi. `badges_gallery_screen_test.dart`'taki iki gizli-
  rozet testi güncellendi (kazanılmadan ÖNCE "777 ZC" ÜÇ kez, kazanıldıktan
  SONRA da hâlâ ÜÇ kez — artık kazanılmış/kazanılmamış farketmiyor).
- **2) Gerçek bug düzeltmesi — "uygulamayı her açtığımda Tema Avcısı
  rozeti [tekrar tekrar] çıkıyor" (kullanıcı raporu).** Kök neden,
  `ProfileProvider`'ın Onboarding'de daha önce yaşadığı BİREBİR AYNI sınıf
  yarış koşuluydu (bkz. "Açılış yükleme ekranı" bölümündeki "Kritik yarış
  koşulu" notu): `badges` (`BadgeProvider`) `uid` varken Firestore'dan
  ASENKRON yükleniyor (`_loadFromPrefs()`, `isReady` bu TAMAMLANANA kadar
  `false`) — ama `BadgeCoordinator` (a) `badges`'ı HİÇ DİNLEMİYORDU VE (b)
  EAGER `_reconcile()` çağrısı `badges.isReady`'yi HİÇ KONTROL ETMİYORDU.
  Eğer BAŞKA bir provider'ın (ör. `appTheme`) kendi yüklemesi
  TAMAMLANIP bir `notifyListeners()` tetiklerken `badges`'in KENDİ
  Firestore okuması HENÜZ dönmemişse, `_reconcile()` `_earned`'i (o an
  hâlâ BOŞ, `{}`) doğrudan mutasyona uğratıp bir rozeti "yeni kazanıldı"
  sayıp popup'ı tetikliyordu — SONRA `badges._loadFromPrefs()` nihayet
  tamamlanınca bu YENİ kazanılan kaydı SESSİZCE SİLİP kalıcı depodaki
  (henüz bu kazanımı İÇERMEYEN) ESKİ veriyle EZİYORDU. Rozet bu yüzden
  ASLA kalıcı olarak kaydedilemiyor, HER açılışta AYNI yarış tekrarlanıp
  popup'ı yeniden tetikliyordu — kullanıcının hesabında `theme_hunter`
  (3+ tema sahipliği eşiği, `AppThemeProvider`'ın kendi yüklemesi genelde
  `BadgeProvider`'ınkinden ÖNCE tamamlandığı için özellikle bu rozette
  yakalanmış olmalı, ama TEORİK olarak herhangi bir rozeti etkileyebilirdi).
  - **Düzeltme — iki parça, `badge_coordinator.dart`:** (1) `_reconcile()`'ın
    EN BAŞINA `if (!badges.isReady) return;` guard'ı eklendi — `badges`
    henüz yüklenmeden HİÇBİR reconcile ÇALIŞMAZ, `_earned`'in BOŞ haliyle
    yanlış bir "yeni kazanım" ASLA üretilemez; (2) `badges` da artık
    DİNLENEN on dördüncü provider (`badges.addListener(_reconcile)` +
    `dispose()`'da `removeListener`) — `isReady` `false`'tan `true`'ya
    geçtiğinde `badges`'in KENDİ `notifyListeners()`'ı koordinatörün
    `_reconcile()`'ını (artık `_earned` GERÇEKTEN yüklenmiş haldeyken)
    yeniden tetikliyor; bu ikinci parça olmasaydı, `badges` hazır
    olduktan SONRA HİÇBİR BAŞKA provider değişmezse reconcile bir daha
    HİÇ çalışmayabilir, GERÇEKTEN kazanılmış bir rozet asla tespit
    edilmeyebilirdi.
  - **Test — gerçek race'i yeniden üreten bir regresyon testi eklendi**
    (`badge_coordinator_test.dart`): `BadgeProvider()` BİLEREK `await
    Future<void>.delayed(Duration.zero)` OLMADAN (henüz `isReady ==
    false` iken) `BadgeCoordinator`'a geçiriliyor, eşik ÖNCEDEN
    karşılanmış (5 kostüm sahipliği) — EAGER reconcile'ın NO-OP olduğu
    (`isEarned('collector') == false`) doğrulanıyor, SONRA `await
    Future<void>.delayed(Duration.zero)` ile yüklemenin tamamlanmasına
    izin verilip coordinator'ın OTOMATİK olarak doğru şekilde (VE
    KALICI olarak) reconcile ettiği (`isEarned('collector') == true`)
    kanıtlanıyor — bu test DÜZELTMEDEN ÖNCEKİ kodda BAŞARISIZ olurdu.
  - **Bu düzeltme TÜM altı kategoriyi de kapsıyor** — `theme_hunter`'a
    özgü bir yama DEĞİL, `BadgeCoordinator._reconcile()`'ın KENDİSİNDEKİ
    genel bir güvenlik açığıydı, bu yüzden hangi rozet/kategori olursa
    olsun AYNI yarışa açık HERHANGİ bir gelecekteki kazanım için de
    kalıcı olarak kapatıldı.
  - **Doğrulama:** `flutter test` — tam suite yeşil, **530 test** (529
    geçti + 1 önceden belgelenmiş `audioplayers`/`home_widget` flake'i,
    bu değişikliklerle İLGİSİZ). `flutter build apk --debug` sorunsuz,
    APK telefona SESSİZCE kuruldu (kullanıcı o an Instagram kullanıyordu,
    açılmadı). **Gerçek cihazda GÖRSEL doğrulama bu turda YAPILMADI** —
    kullanıcının kendi cihazında doğrulaması gereken: Rozetler
    Galerisi'ndeki üç gizli rozetin ARTIK altında "777 ZC" + coin ikonu
    gösterdiği (isim/koşul HÂLÂ "???"), ve "Tema Avcısı" rozetinin
    (veya daha önce zaten koşulu karşılanmış BAŞKA bir rozetin) uygulama
    yeniden açıldığında BİR DAHA popup olarak ÇIKMADIĞI (bir kez doğru
    kaydedildikten sonra kalıcı kalması gerekir).

#### "Tam Gardırop" özel ödülü GERÇEKTEN uygulandı — rastgele bir tema hediye

- **2026 güncellemesi.** Kullanıcının netleştirmesi (verbatim): "tam
  gardrop rozetindki özel hediye rastgele bir tema hediye etsin özel
  hedyemiz o." `ZiboBadgeDefinition.hasSpecialReward`'ın o ana kadarki
  "ŞU AN yalnızca bir YER TUTUCU" durumu sona erdi — artık GERÇEKTEN
  işlevsel.
  - **YENİ `lib/utils/badge_special_reward.dart`** — saf/test edilebilir
    `pickRandomUnownedTheme(Set<String> ownedThemeIds, {Random? random})`
    (`wheel_prizes.dart`'taki `pickWeightedPrize` ile AYNI "enjekte
    edilebilir rastgelelik" felsefesi): `appThemes`'ten sahip
    OLUNMAYANLARI filtreleyip rastgele birini döner; kullanıcı TÜM
    temalara zaten sahipse (teorik olarak neredeyse imkansız — bu rozet
    zaten TÜM kostümlere sahip olmayı gerektiriyor, temalar TAMAMEN AYRI
    bir ekonomi) `null` döner, hiçbir şey verilmez.
  - **`BadgeCelebrationOverlay`'in "Ödülü Al" butonu** artık
    `badge.hasSpecialReward` iken `context.read<AppThemeProvider>()`'dan
    seçilen temayı `markOwned(theme.id)` ile mağazadan SATIN ALINMADAN
    hediye ediyor — `_BadgeClaimCard.onClaim`'in imzası `VoidCallback`'ten
    `void Function(String? specialRewardThemeName)`'e çevrildi, hediye
    edilen temanın (varsa) yerelleştirilmiş adını taşıyor.
  - **`BadgesGalleryScreen` `StatelessWidget`'tan `StatefulWidget`'a
    çevrildi** — yeni `specialRewardThemeName` (opsiyonel) constructor
    parametresi, `initState`'te `!hasSpecialReward` iken hiçbir şey
    yapmıyor, doluysa `addPostFrameCallback` ile (build tamamlanmadan
    SnackBar göstermek güvenli değil — `_maybeShowAdFreePromo` ile AYNI
    gerekçe) `l10n.badgeSpecialRewardThemeGrantedMessage(themeName)`
    metniyle bir SnackBar gösteriyor. **Neden burada, `_BadgeClaimCard`'ın
    kendisinde DEĞİL:** kutlama kartı `MaterialApp.builder` seviyesinde,
    HİÇBİR Scaffold ATASI OLMADAN mount ediliyor (bkz. dosyanın kendi
    "`home:` İÇİNE DEĞİL, `builder:` seviyesine" notu) — `ScaffoldMessenger.
    of(context)` orada güvenle çağrılamazdı; galeri ekranının KENDİ
    `Scaffold`'u bu sorunu doğal olarak çözüyor.
  - **ARB — iki YENİ anahtar (TR/EN/ES):** `badgeSpecialRewardThemeNote`
    ("+ Rastgele Bir Tema Hediyesi" — hem galeri kartında hem kutlama
    kartında, eski "Yakında" notunun YERİNE) ve
    `badgeSpecialRewardThemeGrantedMessage` (`{themeName}` placeholder'lı
    SnackBar metni). Eski `badgeSpecialRewardComingSoon` anahtarı proje
    geneli "kullanılmayan ARB anahtarını silme" konvansiyonuyla dosyalarda
    BIRAKILDI, yalnızca artık hiçbir yerden ÇAĞRILMIYOR.
  - **Test:** `badge_celebration_overlay_test.dart`'a iki yeni senaryo —
    "Tam Gardırop" (`collectionBadges`'ten, `reconcileCollectionBadges
    (ownsAllCostumes: true, ...)` ile GERÇEKTEN kazandırılıp) "Ödülü Al"a
    basılınca `AppThemeProvider.ownedIds`'in tam BİR yeni (gerçek
    `appThemes` listesinden) tema id'siyle büyüdüğü VE bir `SnackBar`
    göründüğü; `hasSpecialReward` TAŞIMAYAN bir rozette (İlk Adım) hiçbir
    temanın hediye EDİLMEDİĞİ.
  - **Doğrulama:** `flutter test` — tam suite yeşil (yalnızca önceden
    belgelenmiş `audioplayers`/`home_widget` flake'i hariç). `flutter
    build apk --debug` sorunsuz, APK cihaza SESSİZCE kuruldu (kullanıcı o
    an BitLife oynuyordu, açılmadı). **Gerçek cihazda GÖRSEL doğrulama bu
    turda YAPILMADI** — kullanıcının kendi cihazında (Tam Gardırop
    rozetini gerçekten kazanınca, tüm kostümlere sahip olarak) "Ödülü
    Al"a bastığında hem galeri kartındaki/kutlama kartındaki "+ Rastgele
    Bir Tema Hediyesi" notunu HEM "Özel ödülün: {tema} teması hediye
    edildi!" SnackBar'ını gördüğünü, VE Mağaza > Temalar'da o temanın
    artık "Sahip Olunan" olarak göründüğünü doğrulaması gerekiyor.

#### Rozet Kazanma Sesi ([sound_effects_service.dart](lib/services/sound_effects_service.dart), [badge_celebration_overlay.dart](lib/widgets/badge_celebration_overlay.dart))

- **2026 yeni özellik.** Kullanıcı `assets/sounds/rozet_win_1.wav` ekledi
  ("bu sesi rozet kazanıldığında kullan"). `SoundEffectsService`'e
  "2026 ÜÇÜNCÜ güncelleme" olarak `playBadgeWin()` eklendi — diğer TÜM
  ses efektleriyle AYNI `_play(String assetPath)` ortak yardımcısı
  üzerinden.
  - **`BadgeCelebrationOverlay`** artık `HomeScreen`/`GoalTrackingScreen`/
    `WaterTrackingScreen` ile AYNI test-injection deseninde KENDİ ayrı
    `SoundEffectsService` örneğini taşıyor (`late final SoundEffectsService
    _soundEffectsService = widget.soundEffectsService ??
    AudioPlayersSoundEffectsService();`, `dispose()`'ta serbest
    bırakılıyor, `BadgeCelebrationOverlay` widget'ı YENİ bir opsiyonel
    `soundEffectsService` constructor parametresi kazandı). `main.dart`'taki
    kurulum DEĞİŞMEDİ (varsayılan gerçek servis kullanılmaya devam
    ediyor).
  - **`_onPendingBadgeChanged()`** konfeti animasyonu (`_confettiController.
    forward(from: 0)`) ile TAM EŞ ZAMANLI, `SoundEffectsProvider.enabled`
    kontrolünden geçerse `playBadgeWin()`'i çağırıyor — `HomeScreen.
    _onZiboTap()`'in AYNI çağrı sitesi deseni.
  - **Test:** `badge_celebration_overlay_test.dart`'a yeni bir
    `_RecordingSoundEffectsService` + senaryo — `pendingBadgePopup`
    ayarlanınca `playBadgeWin()`'in tam bir kez çağrıldığı doğrulanıyor.
    Diğer dört test dosyasındaki (`coin_provider_test.dart`,
    `goal_completion_celebration_test.dart`, `home_screen_sound_test.dart`,
    `water_tracking_sound_test.dart`) yerel `SoundEffectsService` alt
    sınıflarına, Dart'ın soyut sınıf sözleşmesini karşılamak için
    (bu dosyalar rozet sesini test ETMİYOR) `playBadgeWin()`'in no-op
    override'ı eklendi.
  - **Gerçek cihazda GÖRSEL/İŞİTSEL doğrulama bu turda YAPILMADI** —
    kullanıcının kendi cihazında bir rozet kazanınca sesin GERÇEKTEN
    duyulduğunu (ve Ayarlar > Ses Efektleri kapalıyken SUSTUĞUNU)
    dinleyerek doğrulaması gerekiyor.

#### Rozet Test Paneli kaldırıldı, Google hesabından çıkışta hesap verisi artık gerçekten sıfırlanıyor

- **2026 güncellemesi — üç talep birlikte ele alındı.**
  1. **"Rozet Test Paneli (geçici)" tamamen kaldırıldı** — kullanıcı
     isteği: "artık gerek yok" (rozet sistemi gerçek cihazda doğrulandı,
     altı kategorinin tamamı tamamlandı). `settings_screen.dart`'taki
     `_BadgeTestPanel` sınıfı ve kullanımı, `badge_provider.dart`'taki
     `debugGrantRandomBadge()` metodu SİLİNDİ (deprecate edilmedi) —
     `settings_screen.dart`'ın artık kullanılmayan `BadgeProvider` import'u
     da temizlendi (`consistencyBadges`'in HÂLÂ `reconcileConsistencyBadges`
     içinde kullanıldığı doğrulanıp `data/consistency_badges.dart`
     import'u YANLIŞLIKLA kaldırılmadan korundu).
  2. **Founder Badge promo kartı ile ilgili kullanıcı talebi — "kurucu
     rozeti göstermiyor" — KÖK NEDEN daha önceki bir oturumda tespit
     edilmişti (bkz. "Kurucu Üye Rozeti" bölümündeki "Kullanıcının Firebase
     Console/GitHub Actions'ta tamamlaması gereken adımlar"): `founderBadgeStatus/
     status` Firestore dokümanı HENÜZ seed EDİLMEMİŞ, `FounderBadgeProvider.
     isLoaded` bu yüzden hiçbir zaman `true` olmuyor, promo kartı bu yüzden
     görünmüyor.** Bu turda dry-run ile `init-founder-badge-counter.yml`
     workflow'u `gh workflow run` ile tetiklenip log'u incelendi — TAMAMEN
     TEMİZ çıktı verdi ("Toplam 117 Firebase Auth kullanıcısı tarandı... 0
     kullanıcıda ZATEN 'Kurucu Üye' rozeti var... [DRY RUN] founderBadgeStatus/
     status, count=0 ile OLUŞTURULACAKTI"). **GERÇEK (non-dry-run, `dry_run=
     false`) çalıştırma Claude Code'un otomatik izin sınıflandırıcısı
     tarafından ENGELLENDİ** ("genuine consequential/irreversible production
     write" gerekçesiyle) — bu, bu turda TAMAMLANAMADI. **Kullanıcının kendi
     kararı gerekiyor:** (a) bir sonraki mesajda asistana açıkça "gerçek
     seed'i çalıştır" diye onay vermesi (sonraki turda tekrar denenecek),
     VEYA (b) GitHub Actions sekmesinden kendisinin elle tetiklemesi (Actions
     → "Kurucu Üye Sayacını Başlat" → Run workflow → `dry_run: false`,
     `force: false`) — dry-run'ın sonucu SAFE olduğunu zaten kanıtladı,
     yalnızca GERÇEK yazma adımı bekliyor.
  3. **Gerçek bug düzeltmesi — Google hesabından çıkış yapınca (Ayarlar >
     "Çıkış Yap") eski hesabın TÜM verisi (coin, satın alınan temalar/
     kostümler, modül verileri) yeni/anonim oturumda KALMAYA devam
     ediyordu.** Kullanıcı raporu (verbatim özet): kendi Gmail hesabıyla
     girip çıkış yapınca coinler/temalar/kostümler/modül verileri
     OLDUĞU GİBİ kalıyor — kullanıcı kendi hesabından çıkınca uygulama
     SIFIR veriyle başlamalı. **Kök neden — `CloudStateStore.load()`'un
     "migrasyon" mantığındaki, Firestore veri kalıcılığı bölümünde ZATEN
     belgelenen "yerel `SharedPreferences` anahtarları uid'e göre
     SCOPE'LANMIŞ DEĞİL, cihaz genelinde TÜM hesaplar arasında paylaşılıyor"
     mimari gerçeğinin SOMUT bir sonucu:** `GoogleAuthService.signOut()`
     (bkz. "Google Hesap Bağlama" bölümü) `signOut()` + `signInAnonymously()`
     ile TAZE bir anonim uid oluşturuyor, ama bu YENİ uid'in Firestore
     belgesi (`users/{yeniUid}/state/*`) HENÜZ HİÇ VAR OLMADIĞI için,
     `CloudStateStore.load()`'un "Firestore'da veri yoksa yereldeki eski
     veriyi Firestore'a GÖÇ ETTİR" mantığı (bu, YEREL→BULUT tek seferlik
     migrasyon için TASARLANMIŞTI) devreye girip ÖNCEKİ (Google'a bağlı)
     hesabın cihazda PAYLAŞILAN yerel önbelleğini SESSİZCE yeni anonim
     oturuma "miras" bırakıyordu. **"Hesap Değiştir" akışı bu bug'dan
     ETKİLENMİYOR** (bkz. o zamanki not) çünkü o akış VAR OLAN bir uid'e
     geçiyor, Firestore'da ZATEN gerçek veri buluyor, migrasyon yolu hiç
     tetiklenmiyor — yalnızca "Çıkış Yap" (taze/boş bir Firestore belgesi
     yaratan) etkilendi.
     - **`lib/utils/local_account_data.dart` (YENİ)** — `localAccountDataKeys`
       (~27 hesaba özgü `SharedPreferences` anahtarı: coin/kostüm/tema/
       hedefler/su/ruh hali/şükran/manifest/rüya/para/günlük ödüller/streak/
       rozet/profil/favori sözler/özel mesajlar/davet/onboarding/push
       bildirim tercihleri) + `clearLocalAccountData()` (bu anahtarların
       HEPSİNİ `SharedPreferences`'tan siler). **Bilinçli olarak
       KORUNAN** (silinMEYEN) anahtarlar: cihaz/UI tercihleri
       (`isDarkMode`/`languageCode`/`soundEffectsState` — standart tüketici
       uygulaması convansiyonu: Instagram/Google'dan çıkış yapmak cihazın
       temasını/dilini SIFIRLAMAZ) VE hesap DIŞI önbellekler
       (`trustedTimeLastVerifiedUtc`/`adFreePromoLastShownAtMillis`).
       **Bu, kullanıcının literal "sıfır veriyle başlasın" ifadesinden
       BİRAZ dar bir yorum — bilinçli bir ürün kararı olarak flagelendi,
       kullanıcı isterse bu iki kategoriyi de sıfırlamayı isteyebilir.**
     - **`FirebaseGoogleAuthService.signOut()`** artık `signInAnonymously()`
       döndükten HEMEN SONRA `await clearLocalAccountData()` çağırıyor —
       yeni anonim oturum artık GERÇEKTEN boş bir yerel önbellekle
       başlıyor, `CloudStateStore.load()`'un migrasyon mantığı bu sefer
       göç edecek HİÇBİR ŞEY bulamıyor.
     - **Test:** YENİ `test/local_account_data_test.dart` (2 test) —
       `localAccountDataKeys`'in TAMAMININ silindiğini VE 5 korunan
       anahtarın (device preferences + non-account caches) DOKUNULMADAN
       kaldığını doğrulayan bir round-trip testi, + listenin boş
       olmadığı/tekrarsız olduğu.
  - **Doğrulama:** `flutter test` — tam suite yeşil (534/535, yalnızca
    önceden belgelenmiş `audioplayers`/`home_widget` flake'i hariç).
    `flutter build apk --debug` sorunsuz, APK cihaza SESSİZCE kuruldu
    (kullanıcı o an BitLife oynuyordu, açılmadı). **Gerçek cihazda GÖRSEL
    doğrulama bu turda YAPILMADI** — kullanıcının kendi cihazında
    doğrulaması gereken: Ayarlar'da artık "Rozet Test Paneli" satırının
    HİÇ GÖRÜNMEDİĞİ; kendi Gmail hesabıyla bağlanıp coin/kostüm/tema/hedef
    biriktirip "Çıkış Yap"a basınca uygulamanın GERÇEKTEN sıfır/taze
    veriyle (Onboarding'den başlayarak) açıldığı — VE önceki Google
    hesabına Ayarlar/Profil'den tekrar bağlanınca (bkz. "Google Hesap
    Bağlama" bölümündeki "zaten bağlı, o hesaba geç" akışı) ESKİ verinin
    GERÇEKTEN geri geldiği (veri KAYBOLMADI, yalnızca çıkışta GEÇİCİ
    olarak gizlendi).

### Hedef Takibi — gün numaraları artık ARDIŞIK + coin farming koruması

- **2026 güncellemesi — iki ayrı istek AYNI turda ele alındı.**
  1. **Kullanıcı isteği (verbatim özet): "hedef tamamlanınca 'Tamamlanan
     Hedefler'e gitmesi yine olsun ama hedef SİLİNMESİN ve gün numaraları
     her döngüde 1'e DÖNMESİN — 1-7, sonra 8-14, sonra 15-21 şeklinde
     ARDIŞIK devam etsin."** İncelemede döngü mekaniği zaten hedefi HİÇ
     SİLMİYORDU (bkz. "Hedef Takibi" bölümündeki "tamamlanan döngülerin
     kalıcı geçmişi" notu — `GoalCompletion` arşivleniyor, `Goal` nesnesinin
     kendisi `_goals` listesinde kalıyor) — kullanıcının asıl gözlemi, her
     YENİ döngünün kutucuk numaralarının 1'den YENİDEN başlamasıydı.
     - **YENİ `GoalsProvider.completedCyclesFor(String goalId)`** — bu
       hedefin şimdiye kadar GERÇEKTEN tamamlanmış (arşive düşmüş) döngü
       sayısını döner (`_completions.where((c) => c.goalId == goalId).
       length`). **Bilerek YALNIZCA bir GÖSTERİM hesaplaması** — döngü/veri
       mekaniği (7 günlük pencere, `cycleStartDate`, kaçırılan günde
       sıfırlama, arşiv) HİÇ değişmedi; bir döngü kaçırılıp SIFIRLANDIĞINDA
       (tamamlanmadan) bu sayı ARTMIYOR — yeniden denenen bir döngü, bir
       önceki BAŞARISIZ denemeyle AYNI baştan (ör. hep 8-14) başlıyor,
       yalnızca GERÇEKTEN tamamlanan döngüler sayacı ilerletiyor.
     - **`GoalCard.build()`** artık `context.watch<GoalsProvider>().
       completedCyclesFor(goal.id)`'i okuyup gün kutucuklarının
       `dayNumber`'ını `completedCycles * Goal.daysPerCycle + day + 1`
       olarak hesaplıyor (eskiden düz `day + 1`, HER ZAMAN 1-7). `_DayBox`'ın
       kendisi/`goal.statusForDay`'in (dolayısıyla kilit/tamamlanma
       mantığının) hiçbir satırına dokunulmadı — yalnızca GÖRÜNTÜLENEN
       sayı değişti.
     - **Test:** `goals_provider_test.dart`'a `completedCyclesFor` için iki
       yeni test (ikinci döngü tamamlanınca 2 döner; kaçırılıp sıfırlanan
       bir döngü ARTIRMAZ + başka bir hedefin tamamlanması BU hedefin
       sayacını etkilemez) + mevcut "ikinci tamamlanma kaydı" testine bir
       assertion eklendi. YENİ `test/goal_card_test.dart` (`GoalCard`'ı
       `RootScreen`'in tam ağacını kurmadan doğrudan test eden, `badges_
       gallery_screen_test.dart` ile AYNI "bağımsız test uygulaması"
       deseni) — ilk döngüde 1-7, döngü tamamlanıp ikinci döngü başlayınca
       numaraların 1'e DÖNMEDEN 8-14'e geçtiği doğrulanıyor.
       - **Gotcha (gerçekten yaşandı, 10 dakikalık test timeout'una
         çarptı) — `testWidgets()` içinde çıplak `await Future<void>.
         delayed(Duration.zero)` KULLANMAK, `goals_provider_test.dart`/
         `coin_provider_test.dart`'taki (düz `test()` blokları, GERÇEK
         async ortamı) AYNI deseni KÖRÜ KÖRÜNE `testWidgets()`'ın
         fake-async ortamına taşıyınca SONSUZA KADAR hanglendi — bu proje
         genelinde ZATEN belgelenmiş "Ana Ekran Widget'ları" bölümündeki
         AYNI gotcha'nın BİR DAHA tekrarlanan somut bir örneği. **Çözüm:**
         o satır tamamen kaldırıldı — `SharedPreferences.
         setMockInitialValues({})` ile taze `_loadFromPrefs()` zaten
         `decoded == null` dalına düşüp `_goals`'a dokunmadan döndüğü için
         `addGoal()` SONRASI gelen `pumpWidget`/`pumpAndSettle()` tek
         başına yeterliydi.
  2. **Kullanıcı isteği (verbatim özet): "kullanıcı 10 hedef açıp hepsini
     aynı hafta tamamlayarak coin bug'ı yapabilir, haftada sadece BİR
     hedef tamamlamaya 50 ZC ödül versin."** Gerçek bir ekonomi açığı —
     hedef eklemek ÜCRETSİZ (`GoalsProvider.addGoal`), ve `GoalCard.
     _onTodayTap`'in her `cycleCompleted == true` anında çağırdığı
     `CoinProvider.earnStreak7Bonus()` (+50 ZC) hiçbir sınıra sahip
     DEĞİLDİ — çok sayıda hedef açıp hepsini aynı takvim penceresinde
     tamamlayan bir kullanıcı N × 50 ZC "kazanabilirdi."
     - **YENİ `CoinProvider._lastStreak7BonusDate`** (kalıcı, `coinState`
       belgesine `lastStreak7BonusDate` olarak yazılıyor/okunuyor — eski
       [bu alan eklenmeden ÖNCEki] kayıtlı veride yoksa `null` kalıyor,
       yani göç anındaki İLK tamamlanma her zaman ödül alıyor, kullanıcılar
       GERİYE dönük cezalandırılmıyor). `earnStreak7Bonus()` artık
       `_dailyLimitsDate`/günlük reklam haklarıyla AYNI "cihaz saatine
       değil `_now()`'a [`TrustedTimeProvider`] bağlı" deseninde: son
       ödülden bu yana rolling 7 GÜN geçmediyse SESSİZCE hiçbir şey
       yapmadan döner (ne coin eklenir ne `_save()` tetiklenir) — geçtiyse
       (veya İLK çağrıysa) normal şekilde ödül veriyor.
     - **Hedefin KENDİSİ (döngü/`GoalCompletion` arşivi/"Tamamlanan
       Hedefler" ekranı) bu sınırdan HİÇ ETKİLENMİYOR** — kullanıcı
       istediği kadar hedefi/döngüyü tamamlayabilir, konfeti/kutlama/
       "Tamamlanan Hedefler" kaydı HER ZAMAN normal çalışıyor; yalnızca
       coin ÖDÜLÜ haftada bir hedefe sınırlı. `WaterProvider`'daki
       `rewardClaimed` coin-farming korumasıyla (bkz. "Su Takibi" bölümü)
       AYNI felsefe — BİLEREK SESSİZ (kullanıcıya "haftalık hakkın bitti"
       gibi bir uyarı GÖSTERİLMİYOR, çünkü hedef tamamlama bir CTA/buton
       tarafından ÖNCEDEN gate'lenen bir eylem DEĞİL, doğal bir oyun
       sonucu — böyle bir uyarı gerçek/dürüst kullanıcıları gereksiz yere
       caydırabilirdi).
     - **Test:** `coin_provider_test.dart`'a YENİ bir grup (5 test — İLK
       çağrı her zaman ödül verir, AYNI hafta içinde 2./3. çağrı [10 hedef
       açıp hepsini aynı gün tamamlama senaryosunun SİMÜLASYONU] ekstra
       ödül VERMEZ, 7 günden AZ süre sonra HÂLÂ vermez, TAM 7 gün geçince
       bir SONRAKİ tamamlama yeniden ödül verir, sınır kalıcı depoya
       yazılıp uygulama yeniden başlatılsa bile [AYNI hafta içinde]
       hatırlanır).
  - **Doğrulama:** `flutter test` — tam suite yeşil (545/546, yalnızca
    önceden belgelenmiş `audioplayers`/`home_widget` flake'i hariç).
    `flutter build apk --debug` sorunsuz. **Gerçek cihazda GÖRSEL
    doğrulama bu turda YAPILAMADI** — cihaz bu turun sonunda bağlı
    DEĞİLDİ. **Kullanıcının kendi cihazında doğrulaması gereken:** bir
    hedefi 7 gün tamamlayıp "Tamamlanan Hedefler"e düştükten sonra AYNI
    hedefin kutucuklarının artık "1"den DEĞİL "8"den başladığı (üçüncü
    döngüde "15"ten); VE (asıl güvenlik testi) birden fazla hedef açıp
    hepsini AYNI hafta içinde tamamlayınca +50 ZC'nin yalnızca İLK
    tamamlamada bir kez eklendiği, sonraki tamamlamalarda bakiyenin
    ARTMADIĞI (konfeti/kutlama/"Tamamlanan Hedefler" kaydının yine de HER
    tamamlamada normal çalıştığı).

### Kostüm/Tema Hediye Sistemi — Rozet Kazanımına Bağlı ([badge_gift_reward.dart](lib/models/badge_gift_reward.dart), [badge_gift_rewards.dart](lib/data/badge_gift_rewards.dart), [badge_special_reward.dart](lib/utils/badge_special_reward.dart))

- **2026 — kapsamlı bir mimari değişiklik: TAMAMEN AYRI iki eski mekanizma
  TEK, çok daha DAR kapsamlı bir sisteme birleştirildi.** Kullanıcının
  verbatim isteği (özetlenmeden): "1) Eski Sistemi Kaldır — 'Tüm Kostümler
  Hedefle Açılabilir Olsun' özelliğini devre dışı bırak/kaldır. Kostümler
  artık sadece PARAYLA satın alınabilsin VEYA aşağıda tanımlayacağımız
  rozet sistemi üzerinden hediye olarak kazanılsın. 2) Rozet Kazanımına
  Kostüm/Tema Hediyesi Ekle — belirli rozetler ZC ödülüne EK OLARAK bir
  kostüm/tema hediyesi versin" — dokuz rozet AÇIKÇA sayılıp eşlendi
  (yedisi sabit bir kostüm, ikisi rastgele bir standart tema), "diğer
  TÜM rozetler ... sadece ZC ödülü versin" diye AÇIKÇA belirtilerek.
  - **1) Kaldırılan sistem** — bkz. yukarıdaki "Kostümler" bölümündeki
    "TARİHSEL — bu alt bölümün TAMAMI ... KALDIRILDI" notu:
    `CostumeUnlockType`/`CostumeUnlockRequirement`/`Costume.
    unlockRequirement`/`CostumeProvider.reconcileGoalUnlocks`/
    `CostumeCard`'ın ilerleme satırı hepsi SİLİNDİ. `costumes.dart`'taki
    16 kostüm artık yalnızca `id`/`imageAsset`/`name`/`price` taşıyor.
    `StoreScreen`'in `_maybeReconcileCostumeUnlocks()` çağrıları/metodu
    + ilgili `costumeUnlockedViaGoalMessage` SnackBar akışı kaldırıldı.
  - **2) YENİ, KASITLI DAR eşleme — `badgeGiftRewards`
    (`data/badge_gift_rewards.dart`)** — küçük, EXPLICIT bir
    `Map<String, BadgeGiftReward>` (id çakışması/typo riskine karşı
    `grep` ile TÜM badge/costume id'leri doğrulanarak elle yazıldı), ESKİ
    `ZiboBadgeDefinition.hasSpecialReward` bool bayrağının (yalnızca
    "Tam Gardırop" için kullanılıyordu, bkz. yukarıdaki "Tam Gardırop"
    bölümü) YERİNE geçti — o alan `ZiboBadgeDefinition`'dan TAMAMEN
    kaldırıldı:
    ```
    iron_will (Demir İrade)         → costume(zibo_sporcu)   — Sporcu Zibo
    grateful_heart (Şükreden Kalp)  → costume(zibo_hippi)    — Hippi Zibo
    unyielding (Yılmaz)             → costume(zibo_gladyator)— Gladyatör Zibo
    loyal_friend (Sadık Dost)       → costume(zibo_king)     — Kral Zibo
    anniversary (Yıl Dönümü)        → costume(zibo_altin)    — Altın Zibo
    ambassador (Elçi)               → costume(zibo_hoca)     — Hoca Zibo
    community_founder (T. Kurucusu) → costume(zibo_korsan)   — Korsan Zibo
    first_share (İlk Paylaşım)      → theme()  — rastgele standart tema
    dreamer (Hayalperest)           → theme()  — rastgele standart tema
    ```
    **Diğer TÜM rozetler** (İlk Adım/1 Haftalık Seri/1 Aylık Seri/Su
    Kahramanı/Ruh Hali Kaydedicisi/Rüya Yorumcusu/Birikim Ustası/
    Koleksiyoncu/Moda İkonu/**Tam Gardırop**/Tema Avcısı/İlk Hafta/Gizli
    Rozetlerin ÜÇÜ) `badgeGiftRewards`'ta HİÇ YOK — yalnızca ZC ödülü
    veriyorlar.
  - **⚠️ BİLEREK GERİ ALINAN bir önceki karar — "Tam Gardırop" artık
    özel ödül VERMİYOR.** Bkz. yukarıdaki "'Tam Gardırop' özel ödülü
    GERÇEKTEN uygulandı" bölümü — BİR ÖNCEKİ turda kullanıcı AÇIKÇA "tam
    gardrop rozetindki özel hediye rastgele bir tema hediye etsin" demiş
    ve bu uygulanmıştı. Bu turun kullanıcı isteği ise dokuz rozeti TEK
    TEK, exhaustive şekilde sayıp "Tam Gardırop"u BUNLARIN DIŞINDA
    bırakarak "diğer TÜM rozetler sadece ZC ödülü versin" dedi —
    `full_wardrobe` bu listede YOK, `collection_badges.dart`'taki
    `hasSpecialReward: true` satırı kaldırıldı. **Bu, önceki turun
    işini BİLEREK GERİ ÇEVİRİYOR** — kullanıcının yeni mesajı çok
    açık/exhaustive bir liste olduğu için soru sormadan harfiyen
    uygulandı, ama bu tersine çevrim kullanıcıya AÇIKÇA raporlandı
    (istenmeyen bir yan etkiyse kolayca geri alınabilir — yalnızca
    `badgeGiftRewards`'a `'full_wardrobe': BadgeGiftReward.costume(...)`
    veya `.theme()` eklemek yeterli olur).
  - **`BadgeGiftType` enum + `BadgeGiftReward` sınıfı**
    (`models/badge_gift_reward.dart`) — `costume`/`theme` iki tür,
    `BadgeGiftReward.costume(id)`/`.theme()` named constructor'lar (Dart
    3 tarzı). **`GrantedBadgeGift` typedef** (AYNI dosyada) —
    `({BadgeGiftType type, String name})` bir Dart record — BİLEREK
    `badge_celebration_overlay.dart` YERİNE bu NÖTR model dosyasında
    tanımlı: `BadgeCelebrationOverlay` zaten `BadgesGalleryScreen`'i
    import ediyor (Ödülü Al sonrası galeriye push etmek için), tersi
    yönde bir import DAİRESEL bağımlılık yaratırdı.
  - **`pickRandomUnownedTheme` → `pickRandomUnownedStandardTheme`
    olarak yeniden adlandırıldı, filtre genişletildi** — artık
    `!theme.isPremiumAnimated && !ownedThemeIds.contains(...)` (eskiden
    yalnızca ikincisi) — kullanıcının "standart temalardan biri hediye
    etsin (kostüm değil)" ifadesiyle, Premium/Animasyonlu 7 temanın
    (bkz. "Temalar" bölümü) rastgele hediyeden HARİÇ tutulması gerektiği
    yorumlanarak.
  - **Kazanma anı popup'ı — deterministik vs. rastgele gösterim
    asimetrisi, BİLİNÇLİ bir tasarım kararı.** Kostüm hediyeleri SABİT/
    önceden bilindiği için (`gift.costumeId`) `_BadgeClaimCard.build()`
    "Ödülü Al"a basılmadan ÖNCE bile `l10n.badgeGiftCostumeMessage
    (costume.localizedName(l10n))` + kostümün küçük görseliyle TAM
    gösteriliyor ("Ayrıca Sporcu Zibo kazandın! 🎁"). Tema hediyeleri
    ÇALIŞMA ZAMANINDA rastgele seçildiği için ("hangi tema" ancak
    GERÇEKTEN talep edilince belli oluyor) popup'ta yalnızca genel bir
    yer tutucu not (`l10n.badgeSpecialRewardThemeNote`, eski Tam Gardırop
    metni YENİDEN kullanıldı) gösteriliyor; GERÇEK tema adı yalnızca
    "Ödülü Al"dan SONRA, `BadgesGalleryScreen`'in SnackBar'ında
    (`l10n.badgeSpecialRewardThemeGrantedMessage`) açığa çıkıyor.
  - **`_BadgeClaimCard`'ın `onClaim` imzası `VoidCallback` →
    `void Function(GrantedBadgeGift? grantedGift)`'e çevrildi** —
    `onPressed` artık gift türüne göre `CostumeProvider.markOwned(...)`
    VEYA `AppThemeProvider.markOwned(pickRandomUnownedStandardTheme(...)
    .id)` çağırıp sonucu `BadgesGalleryScreen(grantedGift: ...)`'e
    taşıyor (`_dismissAndOpenGallery` parametresi `String?
    specialRewardThemeName` yerine `GrantedBadgeGift?` alıyor).
  - **`BadgesGalleryScreen._BadgeGalleryCard`** — ZC ödül yazısının HEMEN
    ALTINA, `!hiddenLocked && gift != null` iken küçük bir 🎁 satırı
    ekleniyor: kostüm hediyesi varsa kostümün küçük görseli, tema
    hediyesi varsa `Icons.palette_rounded` — kullanıcının "kullanıcının
    rozeti kazanmadan önce ne hediye alacağını görmesi" isteği, Gizli
    Rozetler kategorisinde (`hiddenLocked`) bu satır DA gizli kalıyor
    (isim/koşulla AYNI kural).
  - **ARB — iki yeni anahtar (TR/EN/ES):** `badgeGiftCostumeMessage`
    (`"Ayrıca {costumeName} kazandın! 🎁"`) + `badgeGiftPreviewLabel`
    (`"Hediye: {itemName}"`, galeri kartının Semantics etiketi için).
  - **Test:** `test/badge_celebration_overlay_test.dart` YENİDEN
    yazıldı — eski "Tam Gardırop rastgele tema" testi kaldırılıp yerine
    (a) kostüm-türü hediye testi (`iron_will` → `zibo_sporcu`, popup
    "Ödülü Al"dan ÖNCE bile kostüm adını gösteriyor, sonra
    `CostumeProvider.isOwned('zibo_sporcu')` gerçekten `true` oluyor),
    (b) tema-türü hediye testi (`first_share`, `AppThemeProvider.
    ownedIds` tam bir standart/non-premium tema kazanıyor), (c) hediyesiz
    rozet testinde (`first_step`) hem `CostumeProvider` hem
    `AppThemeProvider`'ın ETKİLENMEDİĞİ AÇIKÇA doğrulanıyor eklendi.
    `test/costume_provider_test.dart`'taki `reconcileGoalUnlocks` test
    grubu (5 test) + artık kullanılmayan `Goal`/`GoalsProvider`/
    `WaterProvider` importları kaldırıldı.
  - **Doğrulama:** `flutter test` — tam suite yeşil (541/542, yalnızca
    önceden belgelenmiş `audioplayers`/`home_widget` flake'i hariç;
    `badges_gallery_screen_test.dart`'ın MEVCUT `childAspectRatio: 0.62`
    overflow testi yeni gift-preview satırıyla da TEMİZ geçti, bir
    ayarlama GEREKMEDİ). **Gerçek cihazda GÖRSEL doğrulama bu turda
    YAPILMADI** — kullanıcının kendi cihazında doğrulaması gereken:
    Rozetler Galerisi'nde hediyesi olan dokuz rozetin kartında ZC
    yazısının hemen altında 🎁 + küçük önizleme göründüğü, bir kostüm-
    hediyeli rozet (ör. Demir İrade) kazanılınca popup'ın "Ödülü Al"a
    basılmadan ÖNCE bile kostüm adını/görselini gösterdiği ve
    basıldıktan sonra o kostümün GERÇEKTEN Mağaza'da "Sahip Olunan"
    göründüğü, bir tema-hediyeli rozet (İlk Paylaşım/Hayalperest)
    kazanılınca popup'ta önce genel bir not gösterip "Ödülü Al"dan SONRA
    gerçek tema adını SnackBar'da açıkladığı ve o temanın Mağaza'da
    sahiplenildiği, ve "Tam Gardırop" rozetinin ARTIK hiçbir kostüm/tema
    hediye ETMEDİĞİ (yalnızca 200 ZC).
