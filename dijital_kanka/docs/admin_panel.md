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
