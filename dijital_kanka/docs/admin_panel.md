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
- [ ] A5 Duyuru: `broadcasts` + saatlik iş adımı (Actions log'u ile doğrulama).
- [ ] A6 Özet: `stats/daily`.
- Sonra (Zibo sürümü gerektirenler): uygulama içi duyuru kutusu, reklam sıklığını `config/ads`'e taşıma.
