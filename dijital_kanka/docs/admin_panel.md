# Zibo Yönetici Uygulaması (Admin Paneli) — FİKİR, 2026-10-29

Durum: **SIRADA DEĞİL** — kullanıcı: "Zibo'nun Evi bitince" (`docs/zibo_home.md`). Kod YOK.

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
