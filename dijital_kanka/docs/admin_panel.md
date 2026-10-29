# Zibo Yönetici Uygulaması (Admin Paneli) — FİKİR, 2026-10-29

Durum: **YAPILIYOR (v1)** — 2026-10-29 başladı, Zibo'nun Evi'nden ÖNCE. Kod: repo kökünde `zibo_admin/`. Adımlar aşağıda "BAŞLADI" bölümünde.

## Kullanıcının istediği
Her şeyi tek yerden kontrol edip değiştirmek: düzenlemeler/değişiklikler, **tüm kitleye mesaj ("mail")**,
**challenge ekleme**, **kişilere ödül verme**, "vs vs".

## Fizibilite (Claude, ölçülen mevcut durum)
- **Mümkün.** Altyapının yarısı zaten var:
  - Uzaktan ayar: Firestore `config/games` (uygulama açılışta okur) — aynı desen ev fiyatları, challenge'lar,
    sezonluk ürünler için genişletilir (`config/home`, `config/challenges` …).
  - Kişiye ödül: `notification-scripts/src/grantGift.js` zaten var (ör. `gamePointsState.unlimitedPlays`);
    elle çalıştırılıyor → panelde bir düğme olur.
  - Toplu bildirim: `notification-scripts/` (FCM, GitHub Actions cron) → panelden "şimdi gönder".
- **"Tüm kitleye mail" — DİKKAT:** kullanıcıların çoğu **anonim giriş** yapıyor; e-posta yalnızca Google ile
  bağlayanlarda var. Ayrıca toplu pazarlama e-postası KVKK/GDPR açık rıza ister. → Doğru kanal **push bildirimi**
  (FCM, herkese ulaşır) + **uygulama içi duyuru kutusu** (Ana Sayfa'da açılan mesaj). E-posta yalnızca rıza veren
  Google hesaplarına, ileride.
- **Coin vermek:** `coinState` kuralları (monotonluk/delta doğrulaması) dışarıdan doğrudan yazmayı BİLEREK
  zorlaştırıyor → güvenli yol: kullanıcıya **"hediye" kaydı** yazılır (`users/{uid}/gifts/...`), uygulama açılınca
  kullanıcı "Hediyeni al" der ve coin uygulamanın kendi akışıyla eklenir (kuralları gevşetmeden).

## Mimari önerisi
- **Ayrı bir Flutter uygulaması** (web + Android; kendi telefonundan da kullanılabilir), aynı Firebase projesi.
- **Giriş:** yalnızca senin Google hesabın; Firestore kurallarında yönetici yetkisi (custom claim `admin: true`,
  bir kez Admin SDK betiğiyle verilir). Normal kullanıcı uygulaması bu yetkiyi asla alamaz.
- **Yetki isteyen işler** (herkese bildirim, hediye yazma, kullanıcı arama): Firestore'a "iş emri" yazılır →
  GitHub Actions / ileride Cloud Functions çalıştırır (Blaze bütçe koruması kurulu; function deploy öncesi maliyet
  kontrolü — `CLAUDE.md` kuralı).
- **Ekranlar (ilk taslak):** Gösterge paneli (kullanıcı/gelir özetleri) · Uzaktan ayarlar (oyun/ev fiyatları,
  reklam sıklığı) · Duyuru & bildirim gönder · Challenge'lar (oluştur, tarih, ödül) · Kullanıcı bul → hediye ver ·
  Sezonluk ürünler aç/kapat.
- **Güvenlik kritik:** panel ele geçirilirse herkesin verisi risk altında → 2 adımlı doğrulama zorunlu, her yönetici
  işlemi kayıt altına alınır (`adminLog`), toplu işlemler önizleme + onay ister.

## Netleşecek sorular
1. ~~Panel nerede çalışsın?~~ **KARAR (kullanıcı, 2026-10-29): TELEFONDA** → ayrı Android uygulaması (Flutter),
   Play'e YAYINLANMAZ — yalnızca imzalı APK ile kendi telefonuna kurulur (ya da Play'de dahili test kanalı, tek
   test kullanıcısı). Ayrı `applicationId` (ör. `com.dijitalkanka.zibo_admin`), aynı Firebase projesi.
2. Challenge örnekleri (ör. "7 gün su hedefi", "hafta sonu oyun turnuvası") ve ödül türleri.
3. Başka yönetici olacak mı (ekip), yoksa yalnızca sen mi?

## Etkileşimli taslak (2026-10-29)
`docs/admin_prototype/index.html`, yayın: https://claude.ai/artifact/2Kj7jdXL7mHc68T3hM8WcE (sayılar örnek)
- **Özet:** günlük aktif, kurulum, reklam geliri, çökmesiz oran, 14 günlük grafik, "Dikkat" uyarıları, coin ekonomisi.
- **Ayarlar:** config/games, config/home, config/ads değerleri (−/+), sezonluk ürün anahtarları; "Gözden geçir" eski→yeni
  farkını gösterir, "Yayınla" ile onay.
- **Duyuru:** bildirim + uygulama içi; dil (TR/ES/EN) ve kitle (herkes / Pro / 7 gündür gelmeyen), önizleme, ulaşacak kişi
  sayısı, zamanlama, onay penceresi, son gönderilenler (açılma oranı).
- **Challenge:** liste (yayında/planlandı/bitti + ilerleme), yeni challenge formu (hedef, ne sayılır, tarih, ödül basamakları).
- **Kullanıcı:** arkadaş koduyla bul, bilgi kartı, hediye (coin / eşya-kostüm / sınırsız oyun / Pro 7 gün — kutuya düşer),
  Online şikâyetleri (sorun yok / uyar / engelle).
- **🧾 İşlem kaydı:** her yönetici işlemi zaman damgasıyla.
Kullanıcı geri bildirimi buraya yazılacak.

## "Önce bunu mu yapsak?" — değerlendirme (2026-10-29, kullanıcı sordu; KARAR BEKLİYOR)
Öneri: **evet ama yalın "Yönetici v1"** — bugün var olan şeyleri yöneten kısım. Challenge ve şikâyet ekranları,
o özellikler (Ev, Online) yapılınca eklenir; şimdi yapılırsa boş ekran olur.

**v1 kapsamı (ölçülen mevcut durum):**
| Parça | Bugün ne var | v1'de gereken |
|---|---|---|
| Giriş + güvenlik | yok | ayrı Flutter uygulaması, Google girişi, `admin` custom claim (bir kez betikle), Firestore kuralları, işlem kaydı |
| Ayarlar | `config/games` zaten uzaktan okunuyor | düzenleme ekranı + fark/onay. Reklam sıklığı (`InterstitialPacer` maxPerDay=2 vb.) şu an KODDA sabit → `config/ads`'e taşımak Zibo'da küçük değişiklik + sürüm |
| Hediye | `notification-scripts/src/grantGift.js` (elle) | panelden tetikleme; coin/eşya için Zibo'da "Hediyeni al" kutusu (sürüm) |
| Duyuru | bildirim betikleri var (cron, saatlik) | anında gönderim için tetikleyici: Firestore'a "iş emri" → Cloud Function (Blaze bütçe uyarısı kurulu; maliyet ~0) ya da saatlik cron (gecikme ≤1 sa). Uygulama içi duyuru kutusu Zibo'ya eklenir (sürüm) |
| Özet | Firebase Analytics/Appodeal verisi telefondan doğrudan OKUNAMAZ (sunucu anahtarı gerekir) | günlük cron istatistikleri `stats/daily` belgesine yazar (kullanıcı sayısı, coin akışı, Appodeal gelir API'si); Crashlytics sayıları v1'de yok |

**Süre tahmini (tahmin):** kod tarafı ~4–6 çalışma oturumu; takvimde kullanıcının test hızına göre ~1–2 hafta.
İçinde 1 Zibo sürümü var (uzaktan reklam ayarı + hediye kutusu + duyuru kutusu). Ev ve Online geldikçe panele
kendi ekranları eklenir (her biri ~1 oturum).

## BAŞLADI — Yönetici v1 uygulama planı (kullanıcı: "şimdiden başlayalım", 2026-10-29)
Mimari kararlar (mevcut kısıtlara göre — `docs/decisions/002`: Cloud Functions YOK, Node bu makinede YOK):
- Proje: repo kökünde **`zibo_admin/`** (Flutter, yalnız Android), `applicationId com.dijitalkanka.zibo_admin`,
  aynı Firebase projesi. Play'e yüklenmez; imzalı APK ile kullanıcının telefonuna kurulur.
- **Yetki:** Google ile giriş + Firestore kuralında `isAdmin()` = `request.auth.token.email == 'cvntann@gmail.com'`
  && `email_verified` (custom claim betiği gerekmez). Google hesabında 2 adımlı doğrulama açık olmalı.
- **Ayarlar / hediye:** panel Firestore'a DOĞRUDAN yazar (kural: yalnız admin). Hediye = `grantGift.js` mantığının
  Dart karşılığı (coinState/subscriptionState/gamePointsState, `GRANT_ID` ile çift-ekleme koruması) → Zibo sürümü
  GEREKMEZ.
- **Kullanıcı bulma:** davet kodu = uid (`ReferralProvider.referralCode`) → panelde uid ile arama.
- **Duyuru (bildirim):** panel `broadcasts/{id}` (status `pending`, zaman, dil, kitle, metin) yazar →
  `hourly-jobs.yml` içindeki yeni adım bir sonraki saat gönderir (ek workflow/dakika yok; "Hemen" = ≤1 saat).
- **Özet:** saatlik iş `stats/daily` belgesine sayıları yazar (kullanıcı sayısı, aktif, coin akışı); Appodeal geliri
  sonra (API anahtarı secret).
- **İşlem kaydı:** her yazım `adminLog/{id}` (zaman, işlem, eski→yeni).

Adımlar:
- [x] A0 Firebase (2026-10-29): Android uygulaması `com.dijitalkanka.zibo_admin` ("Zibo Yonetici", App ID
  `1:855986625717:android:a81b32e2b8a0cfaab032fc`) kaydedildi; SHA-1'ler: **upload** `CD:E6:95:…:44:A3` (release imzası —
  ana uygulamanın `dijital_kanka/android/key.properties`'i ORTAK) + **debug** `AD:E5:CB:…:55:5B`.
  `zibo_admin/android/app/google-services.json` repoda. Firebase konsolu hesabı: **contact@getzibo.com** (Chrome
  "personal" profili, `/u/0/`) — cvntann@gmail.com'da bu proje YOK. Debug APK telefonda açıldı (giriş ekranı).
- [x] A1 İskelet (2026-10-29, kod; cihazda test A0'dan sonra): `zibo_admin/lib/` — `theme.dart` (taslağın renkleri,
  siyah üst şerit, sticker kart), `admin_auth.dart` (Google → Firebase giriş, `kAdminEmail` kapısı), `main.dart`
  (`AuthGate`: giriş yok → giriş ekranı, yönetici değil → "yönetici değil" + çıkış), `screens/home_shell.dart`
  (5 sekme: Özet · Ayarlar · Duyuru · Kullanıcı · Kayıt; henüz yapılmayanlar "Yakında · A?"), `admin_log.dart`
  (her yazım `adminLog` ile AYNI batch'te), `screens/admin_log_screen.dart` (son 100 işlem). Release imzası = ana
  uygulamanın upload anahtarı; `res/raw/keep.xml` `default_web_client_id`'yi korur (ana uygulamadaki release-giriş
  hatasının aynısı önlendi). Challenge sekmesi v1'de YOK (özellik yok).
- [x] A2 `firestore.rules` (2026-10-29, **Console'da YAYINLANDI 21:34** — öncesinde canlı kuralın repodaki eski sürümle birebir aynı olduğu SHA-1 ile doğrulandı): `isAdmin()` + v1'in TÜM yönetici
  izinleri tek seferde — `config/games` yazma; `users/{uid}` + `state/*` okuma; `coinState` yazma (yalnız şekil, delta
  sınırı yok = Admin SDK ile aynı yetki); `subscriptionState` yazma (aynı şekil kuralı); diğer `state/*` yazma;
  `giftGrants` okuma/oluşturma; `adminLog` okuma/oluşturma (değiştirilemez/silinemez); `broadcasts` okuma/yazma;
  `stats` okuma. Kullanıcıların kendi (isOwner) kuralları DEĞİŞMEDİ, yönetici izinleri OR ile eklendi.
- [x] A3 Ayarlar (2026-10-29, kod): `screens/games_config_screen.dart` — `config/games`'i sunucudan okur, Zibo'nun
  `GamesConfig.defaults` AYNASIYLA birleştirip etkin değeri gösterir (**Zibo'da varsayılan değişirse panelde de
  değiştir**); günlük haklar, reklamla ek hak, her oyun için aç/kapa + tüm sayılar (−/+, sayıya dokununca elle yazma);
  "Gözden geçir" eski→yeni listesi → "Yayınla": yalnızca DEĞİŞEN alanlar `merge` ile yazılır (exchangeLadder vb.
  dokunulmaz) + `adminLog`. Takas Gişesi basamakları v1'de düzenlenmiyor.
- [x] A3 telefonda doğrulandı (2026-10-29, kullanıcı: "çalıştı" — Google girişi + ayar yayınlama + kayıt).
- [x] A4 Kullanıcı + Hediye (2026-10-29, kod + APK telefonda; **hediye yazımı cihazda henüz denenmedi**):
  `screens/user_screen.dart` + `gifts.dart` (grantGift.js'in Dart karşılığı, aynı belge şekilleri). Davet kodu (= uid)
  ile bul → kart: ad (profileState.name), son aktif, saat dilimi, ZC (bakiye/kazanılan/harcanan), üyelik (Zibo'nun
  süre-geçti→free mantığıyla), Oyun ★, sınırsız oyun, XP. Hediyeler (her biri onay penceresi + `adminLog`):
  - **ZC** (1–100.000): transaction; `giftGrants/panel-<ms>` diyalog başına tek id → çift ekleme yok; işlem listesine
    "Hediye" kaydı (en çok 200 = `CoinProvider._maxStoredTransactions`; grantGift.js'te 50 kalmış, eski).
    Bulutta `coinState` YOKSA reddeder (yazmak Zibo'nun yerel→bulut göçünü engeller, yerel bakiye silinirdi).
  - **Pro / Pro+**: 7 gün / 30 gün / süresiz (2099). Zibo bitiş tarihine uyuyor; gerçek Play abonesi açılışta yeniden doğrulanır.
  - **Sınırsız oyun** aç/kapat (`gamePointsState.unlimitedPlays`).
  - Son 30 dk'da aktif kullanıcıda uyarı: açık oturum hediyeyi kapatıp açana kadar göremez (eski bakiye kural gereği
    buluta yazılamaz; o oturumda kazanılan ZC yeniden açılışta buluttaki değerle ezilebilir — grantGift.js ile aynı sınır).
- [x] İkon (2026-10-29, kullanıcı isteği): Kral Zibo (`zibo_king.webp`, baş+kaftan kırpımı), turuncu radyal zemin,
  beyaz+siyah sticker kontur; uyarlanabilir ikon (`mipmap-anydpi-v26`) + eski PNG'ler. Üretici: `zibo_admin/tool/make_icon.py`.
  Uygulama adı "Zibo Yönetici". Telefonda başlatıcı önbelleği yüzünden kaldır-kur gerekti.
- [x] A4 telefonda doğrulandı (2026-10-29, kullanıcı: "çalıştı").
- [x] A5 Duyuru (2026-10-29, **uçtan uca DOĞRULANDI**: run 40935741032 → "TEST gönderildi=1", bildirim telefonda `push_notifications` kanalında görüldü; gerçek kitleye henüz gönderilmedi):
  - Panel `screens/broadcast_screen.dart`: TR/EN/ES metin (seçilmeyen dildeki kullanıcıya GİTMEZ), kitle (herkes /
    Pro+Pro+ süresi geçmemiş / 7+ gün gelmeyen), zaman (hemen = sonraki saat başı +07 dk, ya da planlı tarih-saat),
    bildirim önizlemesi, "Önce teste gönder" (`testUid` = Zibo davet kodu, boş gelir; token yoksa uyarır; kitle/dil filtresi yok),
    ulaşım tahmini = `users where fcmToken != null` count (ölçüldü: 2336), son 20 duyuru (durum + sayılar), bekleyeni iptal.
  - Sunucu `notification-scripts/src/sendBroadcasts.js` → `hourlyAll.js` JOBS'un İLK işi (yeni workflow/step YOK, dakika
    maliyeti ~0). `status=='pending'` sorgusu + `sendAfter` JS'te; transaction ile `pending→sending` (çift gönderim yok);
    sonuç `sentCount/skippedCount/failedCount`. `sendToUser` artık gönderdiyse `true` döner; `broadcast` türü için
    tür anahtarı kontrolü yok. FCM `data.type='broadcast'` — Zibo bilinmeyen türü de gösterir (dokununca yalnız açılır)
    → **Zibo sürümü GEREKMEZ**.
  - İlk canlı test (2026-10-29 21:50, elle tetiklenen hourly-jobs run 40934500055): betik çalıştı — "Bekleyen 1, zamanı
    gelen 1 → TEST gönderildi=0 atlandı=1". Sebep: test kutusu yönetici uygulamasının uid'iyle doluydu; o hesabın
    `fcmToken`'ı yok (telefondaki Zibo farklı uid). Düzeltme: kutu boş geliyor + sıraya almadan önce `fcmToken` kontrolü.
  - Bilinen sınır: "Hemen" herkese aynı anda gider (yerel saat penceresi yok) — gece göndermemek yöneticiye kalmış.
    İleride: kullanıcı yerel saatine göre (ör. 10–21) bekletme.
- [~] A5b Uygulama içi mesaj kartı (2026-10-29, kullanıcı isteği: "uygulama içi ve bildirim şeklinde ikiye ayıralım"):
  - Panel: Duyuru sekmesinin üstünde **Bildirim | Uygulama içi** seçimi (`screens/announce_screen.dart`, iki ekran
    `IndexedStack` ile taslağı korur). `screens/in_app_message_screen.dart`: TR/EN/ES başlık (≤60) + mesaj (≤500),
    simge (8 emoji), kitle (herkes / ücretsiz / Pro+Pro+), başlangıç (şimdi/planlı), süre (3/7/14/30 gün), isteğe bağlı
    "yalnızca bu hesap" (`onlyUid`), Zibo kartının önizlemesi, liste (Planlı/Yayında/Bitti) + "Durdur" (`endAt = şimdi`).
  - Firestore `inAppMessages/{id}`: `startAt`, `endAt`, `emoji`, `audience`, `texts{lang:{title,body}}`, `onlyUid?`,
    `createdAt`. Kural: giriş yapmış herkes OKUR, yalnız yönetici YAZAR (**Console'da yayınlandı 2026-10-29 22:11**; öncesinde canlı = 21:34 sürümü, SHA-1 ile doğrulandı; panel listesi izin hatasız yükleniyor).
  - Zibo (**sürüm gerektirir — 1.18.0**): `models/in_app_message.dart` (`fromFirestore` + `pickInAppMessage`: tarih
    aralığı, dil metni yoksa GÖSTERME, kitle, onlyUid, görülmemiş, en yeni başlayan), `providers/in_app_message_provider.dart`
    (açılışta tek sorgu `endAt > şimdi` limit 10; görülenler YALNIZ yerelde `SharedPreferences inAppMessageSeenIds`, en çok
    50 — buluta yazım maliyeti yok), `widgets/in_app_message_card.dart` (sticker pencere: emoji dairesi, başlık, metin,
    "Tamam"), `RootScreen._maybeShowInAppMessage` (Ana Sayfa seçili + üstte pencere yokken, 2 sn gecikme, koşul tutmazsa
    3 sn arayla ≤20 deneme; oturum başına EN FAZLA 1 kart; gösterilince görüldü sayılır). Testler: `test/in_app_message_test.dart`
    (8), paket 759/759 yeşil. **Telefonda denenmedi**: telefondaki Zibo Play sürümü — debug kurmak kaldır-kur = veri kaybı.
- [x] A6 Özet (2026-10-29, **canlı doğrulandı** — run 40938330516 + panel telefonda):
  - Sunucu `notification-scripts/src/dailyStats.js` = `hourlyAll.js` SON işi → `stats/{YYYY-MM-DD}` (İstanbul günü; mevcut
    `stats/{statId}` kuralı, yeni kural yok). Her saat count sorguları: `totalUsers`, `withToken`, `active1d/7d/30d`
    (`lastActiveAt`). Günde bir (`heavyAt` yoksa): tüm `users` → coinState + subscriptionState `getAll` (kullanıcı başı ~3
    okuma ≈ 7 bin okuma/gün, ölçülen tarama ~4 sn) → `coin{balance,earned,spent,holders}`, `subs{pro,proplus}` (süresi
    geçmemiş). collectionGroup toplamı bilerek YOK (`gamePointsState.totalEarned` karışırdı + elle indeks gerekirdi).
  - İlk ölçüm (2026-10-29 22:15): 2425 hesap, bildirim alabilen 2339, aktif 24 sa 211 / 7 g 797 / 30 g 2200;
    dolaşımda 1.443.433 ZC (1156 hesapta); etkin Pro 1, Pro+ 3.
  - Panel `screens/summary_screen.dart`: 4 sayı kartı, 15 günlük "24 sa aktif" çubuk grafiği (sabit 15 yuva, dokununca
    değer), coin kartları (günlük kazanılan/harcanan = son iki ağır sayımın farkı → ikinci günden itibaren), Pro/Pro+.
    Sıralama `orderBy('date')` — `documentId` ters sıralaması ayrı bileşik indeks istiyordu (FAILED_PRECONDITION görüldü).
  - Yok: reklam geliri (Appodeal API anahtarı secret olarak gerekir), Crashlytics sayıları.
  - **Sahip hesapları hariç + hile şüphesi listesi** (2026-10-29, kullanıcı isteği; `HEAVY_VERSION = 2`): `EXCLUDED_EMAILS`
    (cvntann, zuleturquia) Auth'tan uid'e çevrilip coin VE üyelik sayılarından çıkarılır (`excluded{accounts,balance}`).
    `suspects` = en yüksek 25 bakiye + işaretliler (≤40), Auth e-posta/sağlayıcı/oluşturulma + profil adıyla; işaretler:
    `mismatch` (bakiye ≠ kazanılan−harcanan — kural yalnız İLK yazımda buna izin verir), `bigEarn` (satın alma dışı tek kazanç
    > 1000; meşru en büyük = 777 rozet), `fastEarn` (satın alma/hediye hariç > 1000 ZC/gün). Kişisel veri yalnız Firestore'da
    (yönetici okur), Actions log'unda yok. Panel: Özet > "🔍 Dikkat", dokun = uid kopyala.
  - İlk sonuç (run 40939902085): hariç 2 hesap = 372.749 ZC; dolaşım 1.443.433 → 1.070.696; Pro+ 3 → 1 (2'si sahibin).
    **İşaretli hesap 0.** Dolaşımın ~1.028.000'i İKİ hesapta: birebir aynı rakamlı (514.022 ZC, ~590.000 "Satın alma")
    iki uid — biri isimli, biri anonim; aynı cihaz verisinin iki uid'e kopyalandığını düşündürüyor (hesap değiştirme /
    yerel→bulut göçü) — büyük olasılıkla sahibin test satın almaları. Üçüncü büyük: ~76.700 satın almalı tek hesap.
    Gerçek kullanıcılarda en yüksek bakiye ~1.500 ZC, hepsi organik (günlük giriş, çark, rozet) — hile belirtisi yok.

**Yönetici v1 TAMAM (2026-10-29)** — A0–A6 + uygulama içi mesaj kartı (A5b; Zibo tarafı 1.18.0 sürümüyle gelir).
- Sonra (Zibo sürümü gerektirenler): uygulama içi duyuru kutusu, reklam sıklığını `config/ads`'e taşıma.
