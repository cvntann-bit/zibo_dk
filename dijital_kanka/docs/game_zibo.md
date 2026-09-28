# Zibo Oyun Salonu — mini oyunlar + Oyun Puanı ekonomisi

> **Durum (2026-09-28): yol haritası hazır (bölüm 8), kodlamaya başlanmadı.** Önceki durum (2026-09-27): Tasarım ve ekonomi kararları VERİLDİ, oynanabilir HTML taslakları HAZIR,
> kart görselleri repoda. **Uygulamaya henüz tek satır kod eklenmedi.** Kodlamaya, kullanıcının
> Claude haftalık limiti sıfırlandıktan sonra başlanacak (2026-09-29 Salı 20:00 TR).
> Bu dosya tek kaynak: bir karar değişince burası güncellenir.

## 1. Özet

- Uygulamaya bir **Oyun Salonu** eklenecek (Z butonunun açtığı modül menüsünden girilen yeni ekran).
- Oyunlar **doğrudan Zibo Coin vermez**. Hepsi **Oyun Puanı (★)** verir.
- Puan, **Takas Gişesi**'nde haftalık, giderek pahalılaşan bir kurla ZC'ye çevrilir.
- Amaç (kullanıcının sözleri): coin kazanmak kolay olmasın ("bug gibi olur, her şeyi satın alırlar"),
  ZC arz-talep dengesi korunsun, kullanıcı gerçek parayla ZC almaya yönelsin.
- Kullanıcı puan oranlarını hep **DÜŞÜK** istedi. Ayar yaparken cimri tarafta kal.

## 2. Mimari karar — HİBRİT (WebView)

Kullanıcıyla konuşulup önerildi (2026-09-27), son onay limit sıfırlanınca ilk adımda alınacak.

- **Flutter'da (native) yazılacaklar:** Oyun Salonu ana ekranı, Oyun Puanı cüzdanı, günlük haklar,
  Takas Gişesi, puanla açılan süsler, paket önerisi. Ekonomi kuralları, Firestore senkronu ve
  tavan kontrolleri BURADA. Mevcut `CoinProvider` / `SubscriptionProvider` / `TrustedTimeProvider`
  ile konuşur.
- **WebView'da (HTML olarak) açılacaklar:** 7 oyunun kendisi. Taslaklardaki kod neredeyse olduğu
  gibi kullanılır, oyun başına ayrı HTML dosyası, APK içinden (internetsiz) yüklenir.
- **Neden:** Flutter'da baştan yazmak = her detayı elle çevirmek, bir şey atlanırsa oyun "taslakta
  güzeldi, uygulamada eksik" olur; limit tahmini ~%25-40. WebView'da oyun taslakla BİREBİR aynı,
  tahmini ~%10-15.
- **Artı/eksi:** WebView açılışı ~0,5 sn; uygulama boyutu çok az artar (sistem WebView'i);
  oyunun içi widget testiyle test edilemez, köprü (bridge) Dart tarafında test edilir.
- **Paket:** `webview_flutter` (henüz pubspec'te yok — eklerken DEX/R8 etkisini ölç, bkz.
  memory `project_ad_network_dex_cleanup`).

### Köprü (bridge) taslağı

Flutter → oyun (sayfa yüklenince `runJavaScript`):
```js
window.ziboInit({
  locale: 'tr' | 'en' | 'es',
  tier: 'free' | 'pro' | 'plus',
  playsLeft: 3, best: 14,
  owned: { nightBg: false, iceBacks: false },
  pointsBalance: 1250
});
```
Oyun → Flutter (`JavaScriptChannel` adı `ZiboBridge`, JSON mesaj):
| `type` | Alanlar | Flutter ne yapar |
|---|---|---|
| `start` | `game` | Hakkı düşer, cevap `window.ziboStartResult(ok)` |
| `finish` | `game, points, stats{...}` | Puanı DOĞRULAR (oyunun tur tavanı, bu tura tek finish) ve cüzdana ekler |
| `requestAd` | `reason: 'undo' \| 'continue' \| 'extraPlay'` | Pro ise reklamsız onay; değilse Appodeal rewarded açar; cevap `window.ziboAdResult(true/false)` |
| `exit` | — | Oyun Salonu'na döner |

- Taslaklardaki sahte "5 saniyelik reklam sayacı" (`playAd`) yerine `requestAd` gelecek.
- Taslaklardaki `localStorage` cüzdanı ve üyelik düğmeleri GİDECEK; bu bilgiler Flutter'dan gelir.
- Metinler şu an yalnızca TR → oyun başına küçük TR/EN/ES sözlüğü, dili `locale` belirler.
- Fontlar taslakta Google Fonts'tan → uygulamadaki Baloo 2 / Nunito dosyaları oyun klasörüne
  konup `@font-face` ile yüklenmeli (internetsiz çalışsın).
- Hile notu: HTML de Dart kadar değiştirilebilir; güvenlik Flutter tarafındaki tavan/hak
  kontrollerindedir.

### Değişiklik / bakım modeli (kullanıcıyla kararlaştırıldı 2026-09-27)

| Ne değişecek | Nasıl | Güncelleme gerekir mi |
|---|---|---|
| Oyun görünümü, mekaniği, yeni özellik | `assets/games/<oyun>/index.html` düzenlenir → önce tarayıcıda oynanabilir link olarak kullanıcıya gösterilir → onay → yeni AAB | Evet (yeni sürüm) |
| Puan oranı, tur tavanı, günlük hak, reklam hakkı, takas kuru/tavanı | **Firebase'de tutulan ayar** (Remote Config ya da tek bir Firestore config dokümanı) → Flutter okur → `ziboInit` ile oyuna iletir | **Hayır, anında** (uygulamanın bir sonraki açılışında) |
| Yeni oyun | Yeni HTML dosyası + Oyun Salonu'na kart + ayar kaydı | Evet |

Kurallar:
- **Rakamlar HTML'e GÖMÜLMEZ.** Oyunlar puan/tavan/hak değerlerini `ziboInit` config'inden okur; varsayılanlar
  Dart'ta tek bir ayar dosyasında durur (Firebase'e ulaşılamazsa bunlar kullanılır). Kullanıcı ekonomiyle sık
  oynuyor (2026-09-27'de 3 oyunun puanı bir günde değişti) → uzaktan ayar ilk sürümde kurulmalı.
- **Oyun HTML'leri APK içinde kalır**, internetten yüklenmez (internetsiz çalışsın, açılış hızlı olsun, hatalı bir
  değişiklik Play incelemesi olmadan herkese gitmesin).
- **Tek kaynak:** uygulamaya girince `assets/games/` asıl dosyalar olur; `docs/game_prototypes/` ayrı kopya olarak
  tutulmaz (ya kaldırılır ya da `assets/games/`'e yönlendirilir).
- Flutter tarafı yine de tavanı kendisi doğrular (oyundan gelen puan, config'teki tavanı aşamaz).

## 2b. Navigasyon kararı (kullanıcı, 2026-09-28)

- Alt barın 2. sekmesi **🚩 Hedefler → 🎮 Oyun Salonu** olur. Kullanıcı oyunlara buradan ulaşır.
- **Hedefler**, Z butonunun açtığı modül menüsüne (`modules_menu_sheet.dart`) taşınır, listenin **EN BAŞINA**.
- Alt bar tamamen kod-tabanlı (`lib/widgets/main_bottom_bar.dart`, emoji + l10n etiketi) → yeni görsel GEREKMEZ.

Koddan ölçülen etki (2026-09-28) — Faz 3'te hepsi ele alınacak:
| Yer | Şu an | Yapılacak |
|---|---|---|
| `root_screen.dart` `_goalTrackingTabIndex = 1`, `IndexedStack`'teki `GoalTrackingScreen(isActive: ...)` | Hedefler 2. sekme | Sekme Oyun Salonu olur; Hedefler `Navigator.push` ile açılan ekran olur (`isActive` hep true) |
| `root_screen.dart` `_onGoalsTabRequested()` | Bir sinyal gelince Hedefler sekmesine geçiyor | Sinyal kaynağını bul; sekmeye geçmek yerine Hedefler ekranını push etmeli |
| `root_screen.dart` AppBar'daki 🏆 "tamamlanan hedefler" butonu | Yalnızca Hedefler sekmesindeyken görünüyor | Hedefler ekranının kendi AppBar'ına taşınır |
| `main_bottom_bar.dart` `onGoalsTap`, `tabGoalTracking` / `bottomBarGoalsLabel` | 🚩 Hedefler | 🎮 + yeni l10n etiketi (TR/EN/ES); eski ARB anahtarları silinmez (proje kuralı) |
| `test/widget_test.dart` | 10 yerde `find.bySemanticsLabel('Hedef Takibi')` ile sekmeye geçiliyor | Modül menüsünden açılacak şekilde güncellenir |
| `IndexedStack` | Tüm sekmeler hemen kurulur | Oyun Salonu sekmesi hafif olmalı; WebView yalnızca oyuna dokununca açılır |

## Geliştirme / deneme akışı (kullanıcı, 2026-09-28)

- Oyun Salonu geliştirmesi boyunca her adım **debug APK** olarak kullanıcının telefonuna (`adb`, cihaz
  `R9AT507F27M`) kurulup denenir. **Her adımda AAB alınıp paylaşılmaz**; AAB yalnızca kullanıcı "yayınlayalım"
  deyince (release-aab skill'i).
- Kurmadan önce APK zaman damgası kontrol edilir (eski APK kurma hatası yaşandı) ve cihazdaki kurulumun Play'den
  gelmediği doğrulanır (`installerPackageName`).
- **Başlama zamanını kullanıcı söyler.** O zamana kadar bu işe kod yazılmaz.

## 3. Ekonomi

### Ölçülen mevcut kazanç (2026-09-27, koddan)
Aktif ücretsiz kullanıcı günde ~**145 ZC** kazanıyor (haftada ~1.000):
günlük giriş ort. ~31 (`dailyLoginRewards` 5-100), 2 reklam × 20 = 40, 3 çark çevirme × ort. ~17 = ~51
(`wheel_prizes.dart` beklenen değeri), modüller 15, 7 günlük hedef bonusu ~7.
En ucuz paket 110 ZC = 16,99 TL. `earnDailyCheckIn` / `earnDailyMiniTask` tanımlı ama hiç çağrılmıyor.
→ Asıl "kolay coin" sızıntısı mevcut kaynaklarda (özellikle çark); ayrıca ele alınabilir, bu işin kapsamı DEĞİL.

### Takas Gişesi — haftalık kademeli kur (pazartesi sıfırlanır)
| Basamak | Kur | Kim | Gereken puan |
|---|---|---|---|
| İlk 20 ZC | 50 ★ = 1 ZC | Herkes | 1.000 |
| Sonraki 20 ZC | 100 ★ = 1 ZC | Herkes | 2.000 |
| Sonraki 20 ZC | 200 ★ = 1 ZC | Herkes | 4.000 |
| +20 ZC | 250 ★ = 1 ZC | Pro, Pro+ | 5.000 |
| +20 ZC | 300 ★ = 1 ZC | Pro+ | 6.000 |

- Haftalık tavan: **Ücretsiz 60 ZC, Pro 80, Pro+ 100** (bu, paywall'a yeni perk olarak eklenebilir →
  `docs/subscribe_model.md` workflow'u).
- Puan birikir, silinmez. Tavan dolunca "Bu haftalık takas limitin doldu · Pazartesi yenilenir".
- Takas UI: −/+ ile ZC miktarı, "Alabildiğim kadar", bedel basamaklar arasında otomatik hesap.
- Hafta sınırı `TrustedTimeProvider` ile (cihaz saati hilesine karşı).
- `coinState` Firestore kuralları şu an sadece şekil + üst sınır (200.000) kontrol ediyor, tek yazımda
  delta sınırı yok → takas mevcut coin kazanma yolundan (`CoinProvider` earn) geçmeli.

### Günlük oyun hakları
- Her oyun için günde **3** hak (Pro 5, Pro+ 8), gece yarısı yenilenir.
- Hak bitince **ödüllü reklam → +1 hak**, oyun başına günde en fazla 2 kez. Pro/Pro+'ta reklam yok.

### Puanla açılanlar (coin'e dokunmaz, puana değer kazandırır)
- Gece Gökyüzü — Zibo Zıpla arka planı — 3.000 ★
- Buz Kartlar — Hafıza kart arkası — 2.500 ★
- Haftalık puan sıralaması (taslakta örnek isimlerle; gerçek sıralama backend ister → sonraya).

### Satın almaya yönlendirme
- Takas Gişesi'nde: bakiyenin yetmediği bir sonraki kostüm + kalan ZC + "sadece oyunlarla ~N hafta" +
  eksiği kapatan paket butonu (110/275/550/1100 ZC).
- Ücretsiz kullanıcıya: "Pro ile haftalık takas limiti 80 ZC".

## 4. Oyunlar (7) — güncel kurallar

Tüm oyunlarda: günde 3 hak (yukarıdaki kural), sonuç ekranı "+N puan", Takas Gişesi'ne kısayol.

| Oyun | Mekanik | Puan (GÜNCEL) | Tur tavanı | Kaybetme / devam |
|---|---|---|---|---|
| **Zibo Zıpla** | Flappy tarzı: dokun-zıpla, sütun aralarından geç | **coin × 5** (sütun puan vermez, sadece rekor) | 600 | Çarpınca biter |
| **Zibo Hafıza** | 16 kostümle kart eşleştirme, başta ezberleme süresi | Kolay 100 / Orta 180 / Zor 300 × yıldız (3★ tam, 2★ %60, 1★ %30) | — | Hamle limiti dolarsa **0** |
| **Coin Yakala** | Düşen coinleri yakala, bombalardan kaç, 45 sn, 3 can | **1 skor = 1 ★** (coin 1, kese 3) | 400 | Canlar biterse **0** |
| **Zibo 2048** | Kostüm birleştirme (2 Klasik → … → 2048 Altın → 4096 Elmas) | skor ÷ 20 + en yüksek kostüm bonusu (Samuray 50, Kral 100, Altın 200) | 600 | Hamle kalmayınca biter; geri al en fazla 3 (ücretsiz: her biri reklam, Pro: bedava) |
| **Zibo Tren** | Snake: Zibo + arkasında coin vagonları | **coin × 5** (kese = 3 coin) | 600 | Çarpınca biter; 1 kez "geri dön" (reklam / Pro bedava) |
| **Zibo Tuğla** | Bricks n Balls: nişan al, sayılı tuğlaları kır, +1 halkalar | **tuğla × 1** | 400 | Tuğlalar dibe inince biter; 1 kez "3 sırayı sil" (reklam / Pro bedava) |
| **Zibo Kule** | Stack: kayan bloğu zamanında bırak, taşan kesilir | **kat × 2 + mükemmel × 1** | 250 | Iskalayınca biter; 1 kez "tekrar dene" (reklam / Pro bedava) |

Not: Hafıza ve 2048 şu an diğerlerinden daha çok puan veriyor olabilir — kullanıcıya soruldu, cevap bekleniyor.

### Oyun detayları (taslaktaki değerler)
- **Hafıza:** Kolay 12 kart / 11 hamle / 3 sn ezber; Orta 16 / 14 / 2 sn; Zor 20 / 16 / 1,5 sn.
  3★ eşikleri ≤8 / ≤10 / ≤12 hamle, 2★ ≤10 / ≤12 / ≤14.
- **Coin Yakala:** bomba oranı %20 → %40 (zamanla), düşüş hızı 210 → 450, erken zikzak,
  dar yakalama alanı, ağır Zibo, mıknatıs 3 sn (kullanıcı "çok kolay" dedi, zorlaştırıldı).
- **2048 başla penceresi GİZEMLİ (kullanıcı kararı 2026-09-27):** kostüm sırası gösterilmez; yalnızca Klasik + 5 adet "?" kart ve "Birleştirdikçe yeni kostümler açılır. Hepsini keşfedebilecek misin?". Hedef olarak Altın Zibo görünmeye devam ediyor.
- **2048 kostüm sırası (oyuncuya önceden gösterilmez):** 2 Klasik (`zibo_yeni`), 4 Hippi, 8 Sporcu, 16 Asker, 32 Hoca, 64 Punk,
  128 Rapçi, 256 Samuray, 512 Korsan, 1024 Kral, 2048 Altın, 4096 Elmas.
- **Tren:** 15×24 ızgara, her 6 coinde bir kaya, buz küpü 4 sn yavaşlatır, coin topladıkça hızlanır.
- **Tuğla:** 7 sütun, her tur yeni sıra (hp = tur, %22 ihtimalle 2×tur), atış 4 sn'yi geçerse ×2 hız.
- **Kule:** mükemmel = ±5 px, 3 mükemmel kombo bloğu +8 px genişletir, hız kat sayısıyla artar.

## 5. Tasarım

- Görsel dil: uygulamanın "Çizgi Roman Çıkartması" teması (`docs/theme_new.md`) — krem/altın,
  kalın siyah kontur, düz ofset gölge, Baloo 2 + Nunito. Oyun ekranları taslakta hep AÇIK tema.
- **Oyun Puanı ikonu:** buz mavisi daire içinde ★ (`#8FD3FF`, mürekkep `#0E3A5C`) — ZC'nin altınından ayrışsın.
- **Zibo 2048 ayrıntılı tasarımı** (ayrı taslak): Kostüm Yolu şeridi (12 kostüm, ulaşılan renkli,
  sıradaki buz mavisi kesikli ve nabız atan), skor / rekor / "Bu tur ★" kutuları, karo renkleri
  krem → turuncu tek skala + yüksek seviyede kenar halkası (Samuray–Korsan gümüş, Kral altın,
  Altın parıltı, Elmas buz), "Yeni: Samuray Zibo! +50 ★" şeridi, Altın Zibo kutlaması (dönen ışınlar).
  **Açık sorular (cevap bekliyor):**
  1. Karo renkleri tek skala + kenar halkası mı?
  2. "Yeni kostüm" şeridi her seviyede mi, sadece bonuslu seviyelerde mi (Samuray/Kral/Altın)?
  3. Oyun ekranı koyu temaya uysun mu, hep açık mı kalsın?

## 6. Görseller

- Oyun kartı görselleri (kullanıcı ChatGPT ile üretti, 256×256 webp'ye küçültüldü, commit `0e01b96`):
  `assets/images/game_{zipla,hafiza,yakala,2048,tren,tugla,kule}_thumb.webp`. Henüz kodda kullanılmıyor.
- Görsel üretim kuralı (kart görselleri için verilen komutlar): kare 1:1, Zibo göğüsten yukarı yakın çekim,
  tek ana nesne, sade krem-bal arka plan, **köşe yuvarlama / çerçeve / yazı / sayı YOK** (kart kendi
  çerçevesini çiziyor). 1024+ px üret → 256 px webp'ye küçült (`cwebp -resize 256 256 -q 88`).
- Oyun içi görseller mevcut asset'ler: `zibo_df_pose1/3/4`, `zibo_yeni`, 16 kostüm (`zibo_<id>.webp`), `zibo_coin`.

## 7. Taslaklar

Repodaki kopyalar (tarayıcıda doğrudan açılır, görseller `../../assets/images/`'tan gelir):
- `docs/game_prototypes/oyun_salonu.html` — 7 oyun + ortak ★ cüzdanı + Takas Gişesi + puanla açılanlar.
  Oyun kodları buradan WebView dosyalarına ayrılacak.
- `docs/game_prototypes/zibo_2048_tasarim.html` — 2048 ayrıntılı tasarım önerisi.

Yayınlanmış hâlleri (kullanıcının claude.ai hesabında, özel):
- Oyun Salonu: https://claude.ai/artifact/BTRj5w4JeAJQXwX7rFfkF3
- Zibo 2048 tasarımı: https://claude.ai/artifact/KiuZEoAZfu2SHLmagTGmoY
- (Eski, tek oyunluk ilk taslaklar — artık Oyun Salonu'nun içinde, kuralları ESKİ:
  Zıpla `CJRjuzMhifCHajha7bmdy4`, Hafıza `DYc6VaAPac1HBxthn4uqEo`, Coin Yakala `1G457Cy6PEbPhEDaZGxiS3`)

## 8. Yol haritası (2026-09-28)

> Her faz kendi başına tamamlanır, test edilir, commit + push edilir. Bir faz bitmeden sonrakine geçilmez.
> "Limit" sütunu kullanıcının Claude haftalık limitinden **kaba tahmin** — ölçülmüş değer değil.
> Karar kapıları (🚦) kullanıcı onayı olmadan geçilmez.

### Özet tablo

| Faz | Ne | Kullanıcıya görünen | Sürüm | Tahmini limit |
|---|---|---|---|---|
| **0** | Bekleyen kararları netleştir (seri sorunu kapandı) | — | — | %1-2 |
| **1** | Teknik deneme: tek oyun (Kule) WebView'da | Hiçbir şey (sadece debug APK) | — | %5-8 |
| **2** | Altyapı: ayarlar, puan cüzdanı, köprü | Hiçbir şey (arka plan) | — | %8-12 |
| **3** | Ekranlar: Oyun Salonu + Takas Gişesi | — (Faz 4 ile birlikte çıkar) | — | %8-12 |
| **4** | İlk oyunlar: Hafıza + 2048 | **Oyun Salonu açılır** | **1.14.0** | %8-12 |
| **5** | İzleme ve denge (1-2 hafta) | Rakamlar güncellemesiz ayarlanır | — | %2-4 |
| **6** | Coin Yakala + Zibo Tren | "2 yeni oyun" | 1.15.0 | %5-8 |
| **7** | Zıpla + Tuğla + Kule | "3 yeni oyun" | 1.16.0 | %6-10 |
| **8** | İsteğe bağlı: gerçek sıralama, yeni süsler, eski coin kaynaklarının dengesi | — | sonra | ayrıca |

Sürüm numaraları öneri; versionCode her Play yüklemesinde +1 (şu an 48 → sıradaki 49).

---

### Faz 0 — Kararlar
~~Seri / Streak Freeze sorunu~~ **KAPANDI (2026-09-28):** kullanıcı cihaz tarihini elle ileri almadan gerçek
günleri bekleyerek denedi, seri ve Streak Freeze doğru çalıştı. Önceki "sorun" büyük ihtimalle elle tarih
değiştirmekten (uygulama `TrustedTimeProvider` ile cihaz saatine güvenmiyor). **Ders (Oyun Salonu için de):**
günlük hak / haftalık takas testleri elle tarih değiştirerek değil, enjekte edilen saatle (unit test) yapılmalı;
cihazda gerçek gün beklenmeli.
- Bölüm 9'daki bekleyen kararları kullanıcıyla netleştir.
- **Çıktı:** kararlar bu dosyaya işlenir. Kod yok, sürüm yok.

### Faz 1 — Teknik deneme (tek oyun) 🚦
**Amaç:** hibrit yolun gerçek telefonda işe yaradığını kanıtlamak, büyük işe girmeden.
- `webview_flutter` ekle. Önce/sonra ölç: APK/AAB boyutu, DEX (bkz. memory `project_ad_network_dex_cleanup`).
- Deneme oyunu **Zibo Kule** (kısa tur, dokunma yoğun, kolay port). `assets/games/kule/index.html`.
- Asgari köprü: `ziboInit` (dil, üyelik) → oyun; `finish` + `requestAd` → Flutter. Reklam gerçek Appodeal rewarded.
- Fontlar yerel (`@font-face` ile Baloo 2 / Nunito), internet kapalıyken dene.
- Gerçek cihazda kontrol listesi: açılış süresi, akıcılık (FPS), dokunma gecikmesi, Android geri tuşu,
  uygulamayı arka plana alıp dönme, ekran döndürme kilidi, koyu tema, eski/zayıf cihaz (varsa).
- **🚦 Karar kapısı:** kullanıcı telefonda oynar → "hibrit yol tamam" ya da "Flutter'da yazalım".
- **Çıktı:** debug APK + ölçüm notu (boyut farkı, açılış süresi). Yayın yok.

### Faz 2 — Altyapı (arka plan, görünmez)
- **Ayarlar (config):** tüm rakamlar tek yerde. Dart varsayılanları `lib/data/games_config.dart` +
  uzaktan ayar. Öneri: **Firestore `config/games` dokümanı** (yeni SDK yok, DEX artmaz; Remote Config
  alternatifi). `firestore.rules`'a herkese açık OKUMA kuralı eklenir (Console'a elle yapıştırılır).
  Ulaşılamazsa Dart varsayılanları. Kapsam: oyun başı puan oranı + tur tavanı, günlük hak (free/pro/plus),
  reklam hakkı, takas basamakları + haftalık tavanlar, süs fiyatları, oyun açık/kapalı anahtarı.
- **`GamePointsProvider`** (`CloudStateStore` → `users/{uid}/state/gamePointsState`): ★ bakiyesi, haftalık
  takas (`weekEx`, hafta anahtarı), oyun başına günlük hak/reklam/bonus, rekorlar, açılan süsler.
  Gün/hafta sınırı `TrustedTimeProvider` ile. `ready` deseni (Faz 0'daki yarış dersine uy).
- **Takas:** kur hesabı (basamaklar arası), ZC ekleme mevcut `CoinProvider` earn yolundan, analitik olayı.
- **`GameWebViewScreen`** (tüm oyunlar için tek genel ekran) + köprü mesaj işleyici: `start` (hak düş),
  `finish` (puanı config tavanına göre DOĞRULA, tura tek finish), `requestAd`, `exit`.
- **Testler:** kur hesabı, tavanlar, gün/hafta sıfırlama, tur tavanı doğrulama, çift finish reddi,
  köprü mesajları (WebView'sız, mesaj işleyiciyle).
- **Çıktı:** testleri geçen altyapı, commit. Kullanıcıya görünen değişiklik yok.

### Faz 3 — Ekranlar 🚦
- Mockup → onay → kod (tema workflow'u): **Oyun Salonu** (oyun kartları `game_*_thumb.webp`, ★ bakiyesi,
  haftalık takas çubuğu) ve **Takas Gişesi** (basamaklar, −/+ miktar, "Alabildiğim kadar", tavan mesajı,
  kostüm + paket önerisi, Pro satırı, puanla açılanlar). Taslak zaten var: `docs/game_prototypes/oyun_salonu.html`.
- **Navigasyon değişikliği (bölüm 2b):** alt barın 2. sekmesi 🚩 Hedefler → 🎮 Oyun Salonu; Hedefler, Z butonunun
  modül menüsünün EN BAŞINA taşınır. Aşağıdaki etki listesinin hepsi bu fazda yapılır.
- Sonuç ekranı ve "hak bitti / reklam izle" akışı Flutter tarafında (dil ve tema tutarlılığı için) —
  bölüm 9'daki karara bağlı.
- TR/EN/ES ARB anahtarları.
- `docs/theme_new.md` (onaylı ekranlar) + `docs/subscribe_model.md` (Pro/Pro+ takas tavanı perk'i, paywall satırı).
- **Çıktı:** ekranlar + widget testleri. Henüz yayın yok (oyunsuz salon çıkmaz).

### Faz 4 — İlk oyunlar: Hafıza + 2048 → **1.14.0 yayını**
- Taslaktan port: `localStorage` cüzdanı, üyelik düğmeleri ve sahte reklam sayacı çıkar; rakamlar `ziboInit`
  config'inden; TR/EN/ES sözlük; yerel fontlar; `docs/game_prototypes/` → `assets/games/` (tek kaynak).
- 2048: ayrıntılı tasarım (Kostüm Yolu şeridi, karo halkaları, "Yeni kostüm" şeridi, Altın kutlaması) —
  bölüm 5'teki 3 soru cevaplandıktan sonra. Başla penceresi gizemli (onaylı).
- Analitik olaylar: `game_start`, `game_finish` (oyun, puan, süre), `game_ad_used`, `points_exchanged`,
  `exchange_cap_hit`, `game_upsell_tap` — Faz 5'teki denge için şart.
- Gerçek cihazda tam tur testi, Crashlytics kontrolü, sürüm notları (TR/EN/ES), AAB.
- **Çıktı:** 1.14.0 AAB → kullanıcı dahili teste → üretime.

### Faz 5 — İzleme ve denge (yayından 1-2 hafta sonra)
- Analytics'ten ölç: tur başına ortalama ★, günde kaç tur, takas oranı, haftalık tavana ulaşan kullanıcı oranı,
  reklamla ek hak kullanımı, paket önerisine tıklama / satın alma.
- Rakamları `config/games`'ten ayarla (güncellemesiz). Kural: kullanıcı düşük oranları tercih ediyor, cimri başla.
- Bu dosyaya "ölçülen değerler" bölümü ekle.

### Faz 6 — Coin Yakala + Zibo Tren → 1.15.0
- Aynı port kalıbı (Faz 4). Tren için kaydırma hassasiyeti ve geri dönme akışı gerçek cihazda ayarlanır.
- Hareketli oyunlarda eski/zayıf cihaz performansı ayrıca kontrol edilir.

### Faz 7 — Zıpla + Tuğla + Kule → 1.16.0
- Kule Faz 1'de denendiği için hazır sayılır; Zıpla ve Tuğla port edilir.
- Puanla açılan süsler (Gece Gökyüzü, Buz Kartlar) bu fazda ya da Faz 4'te — kullanıcı kararı.

### Faz 8 — İsteğe bağlı / sonra
- **Gerçek haftalık sıralama:** Blaze'siz mümkün — `notification-scripts/` gibi GitHub Actions betiği saatlik
  `leaderboards/weekly` dokümanı üretir. Gizlilik: takma ad, sadece ilk N.
- Yeni süsler (her oyuna bir arka plan / kart arkası).
- Mevcut coin kaynaklarının dengesi (bölüm 3: günde ~145 ZC, çark ortalama ~51) — ayrı iş, ayrı karar.
- Yeni oyun adayları: Günlük Kelime, Üçlü Eşleştirme, Köstebek Zibo.

## 9. Bekleyen kararlar

1. Hibrit (WebView) yolun son onayı — Faz 1 denemesinden sonra.
2. Hafıza ve 2048 puanları diğer oyunlarla aynı seviyeye çekilsin mi?
3. Zibo 2048 tasarımındaki 3 soru (bölüm 5).
4. İlk sürümde hangi oyunlar (öneri: Hafıza + 2048).
5. Haftalık puan sıralaması gerçek mi olacak (Faz 8, GitHub Actions ile Blaze'siz mümkün) yoksa ilk sürümde çıkarılsın mı?
6. 2048 başla penceresinde Altın Zibo hedefi de gizlensin mi (siluet + "Hedef: ??? Zibo")?
7. Oyun sonu ekranı ve "hak bitti" akışı HTML'de mi kalsın, Flutter'a mı taşınsın (öneri: Flutter — dil/tema tutarlılığı)?
8. Puanla açılan süsler ilk sürümde (Faz 4) mi, sonra mı (Faz 7)?
9. Uzaktan ayar: Firestore `config/games` dokümanı (öneri) mı, Firebase Remote Config mi?

### Verilen kararlar (Faz 0, 2026-09-29)
- **Sıra:** önce Oyun Salonu; bildirim sesi düzeltmesi (Play yorumu sözü, bkz. `CURRENT_STATE.md`) sonra.
- **İlk sürüm oyunları:** Hafıza + 2048 (madde 4 kapandı).
- **Uzaktan ayar:** Firestore `config/games` dokümanı (madde 9 kapandı).
- **Sonuç ekranı + "hak bitti / reklam" akışı:** oyunun İÇİNDE (HTML) kalır (madde 7 kapandı) → her oyun
  kendi TR/EN/ES metinlerini taşır; Flutter yine puanı doğrular (`finish` → `ziboFinishResult`).
- Açık kalanlar: 2, 3, 5, 6, 8 (ilgili faza gelince sorulacak).

### Faz 1 ilerleme (2026-09-29)
- `webview_flutter ^4.14.1` eklendi. `assets/games/kule/index.html` (tek başına oyun: TR/EN/ES, yerel fontlar
  `../../fonts/`, görseller `../../images/`, köprü yoksa tarayıcıda DEMO modu).
- `lib/screens/game_webview_screen.dart` — genel oyun ekranı; köprü mesajları `ready/start/finish/requestAd/exit`,
  puan `cap` ile doğrulanıyor, açılış süresi `ZIBO_GAME ... ready in N ms` olarak loglanıyor.
  Haklar/puanlar Faz 1'de BELLEKTE (ekran kapanınca sıfırlanır) — Faz 2'de `GamePointsProvider`.
- `CoinProvider.showGameRewardedAd()` — oyunlar için ödüllü reklam (coin vermez, Pro'da reklamsız true).
- Z menüsünde YALNIZCA debug derlemede "Zibo Kule (deneme)" girişi (`kDebugMode`).
- Cihazda deneme kontrol listesi: bölüm 8 Faz 1.

### 🚦 Faz 1 karar kapısı GEÇİLDİ (2026-09-29)
Kullanıcı Zibo Kule'yi telefonda WebView'da denedi: "tamamdır" → **hibrit (WebView) yol kesin** (madde 1 kapandı).

### Navigasyon değişikliği YAPILDI (2026-09-29, bölüm 2b)
- Alt bar 2. sekme: 🎮 **Oyun Salonu** (`lib/screens/game_hall_screen.dart`, etiket `bottomBarGamesLabel`,
  erişilebilirlik `tabGameHall`). Kartlar `game_*_thumb.webp`; şimdilik yalnızca Kule oynanabilir, diğerleri "Yakında".
- **Hedefler** artık `GoalTrackingPage` (kendi AppBar'ı: coin bakiyesi + 🏆 tamamlanan hedefler). Girişler:
  Z menüsünün EN BAŞI, Ana Sayfa hedef kartı ve seri hatırlatma bildirimi (`goalsTabRequest` → `openGoalTrackingPage`).
- Sayfa Ana Sayfa'nın üstüne açıldığı için `isHomeTabActive` sayfa açıkken kapatılıyor (tema parçacıkları/banner
  Hedefler'de görünmesin — eski sekme davranışı; değer microtask ile değiştiriliyor, build sırasında değil).
- Geçici debug "Zibo Kule (deneme)" girişi kaldırıldı.
- Testler: `_openGoalsPage` yardımcısı (Z menüsü → Hedef Takibi), gizlenen `RootScreen` için `skipOffstage: false`,
  Hedefler sonrası Ana Sayfa'ya dönüş `Geri` ile. Tam suite yeşil (+ bilinen ses flake'i).

### 7 oyunun hepsi uygulamada (2026-09-29, debug APK ile telefonda)
`assets/games/{kule,hafiza,2048,yakala,tren,zipla,tugla}/index.html` — hepsi aynı kalıp: tek başına HTML, TR/EN/ES,
yerel fontlar, `ZiboBridge` (`ready/start/finish/requestAd/exit`), sonuç ekranı oyun içinde, rakamlar `ziboInit`
config'inden (`lib/screens/game_webview_screen.dart` sonundaki `*GameConfig` sabitleri — Faz 2'de `config/games`'e taşınacak).
Oyun başına devam/geri alma: 2048 `requestAd('undo')`, Tren/Tuğla/Kule `requestAd('continue')`; Pro'da reklamsız.
Kullanıcı Kule, Hafıza, 2048, Coin Yakala ve Tren'i telefonda denedi: "çalışıyor". Zıpla ve Tuğla denenmeyi bekliyor.
**Hâlâ geçici:** haklar/puanlar/rekorlar ekran kapanınca sıfırlanıyor → Faz 2 (`GamePointsProvider`), Takas Gişesi → Faz 3.

### Faz 2 YAPILDI (2026-09-29)
- `lib/data/games_config.dart` — `GamesConfig`: tüm rakamlar + `defaults`; `fromJson` Firestore `config/games`'i
  varsayılanların üstüne yazar (yalnızca sayı/bool; bozuk alan yok sayılır). `enabled: false` = oyunu "Yakında"ya çevirir.
- `lib/providers/games_config_provider.dart` — açılışta `config/games`'i bir kez okur (yoksa/hata → varsayılan).
- `lib/providers/game_points_provider.dart` — `gamePointsState` (CloudStateStore): ★ `points`, `totalEarned`,
  `weekPoints`, `weekExchanged` (Faz 3 için), oyun başına günlük `used/bonus/ads`, `best`. Gün/hafta (pazartesi)
  `TrustedTimeProvider` saatinden. `consumePlay`, `grantAdPlay` (yalnızca free, oyun başına günde `maxAdPlaysPerGame`),
  `recordFinish` (tur tavanına kısar, rekor günceller). `ready` future'ı.
- `GameWebViewScreen` artık bu ikisini kullanıyor; oyunlara her cevapta `playsLeft` + `canAdForPlay` gidiyor.
- `firestore.rules`: `config/games` → giriş yapmış herkes OKUR, yazma kapalı. **Console'a elle yapıştırılmalı.**
  Doküman oluşturulmazsa uygulama varsayılanlarla çalışır.
- Test: `test/game_points_provider_test.dart` (9 test).

### Faz 3 YAPILDI (2026-09-29)
- **Oyun Salonu** üstünde ★ kutusu: bakiye, "Bu hafta X / cap ZC takas edildi" çubuğu, **Takas Gişesi** düğmesi.
- **`lib/screens/game_exchange_screen.dart`** (taslaktaki düzen): kur basamakları (✓ dolan / buz mavisi mevcut + ilerleme /
  🔒 Pro-Pro+), −/+ miktar, "Alabildiğim kadar", bedel, "X ★ → N ZC takas et"; tavan dolunca bilgi kutusu; bakiyenin
  yetmediği en ucuz sahip olunmayan kostüm + "Sadece oyunlarla ~N hafta" + "Mağazada coin al" (`storeTabRequest` →
  Mağaza sekmesi); ücretsizde "Pro ile haftalık takas limiti 80 ZC" → Paywall.
- `GamesConfig.exchangeLadder` (varsayılan 20@50, 20@100, 20@200, +20@250 Pro, +20@300 Pro+; Firestore'dan
  değiştirilebilir). `GamePointsProvider`: `costFor`, `maxAffordable`, `weeklyCap`, `weeklyRoom`, `currentRate`,
  `exchange`, `daysUntilWeekReset`. ZC ekleme: `CoinProvider.earnGameExchange` (işlem adı "Takas Gişesi").
- Puanla açılan süsler (Gece Gökyüzü, Buz Kartlar) henüz YOK (karar 8 açık). Haftalık sıralama YOK (Faz 8).
- Testler: Takas Gişesi grubu (4 test).
