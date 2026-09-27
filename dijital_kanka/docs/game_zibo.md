# Zibo Oyun Salonu — mini oyunlar + Oyun Puanı ekonomisi

> **Durum (2026-09-27):** Tasarım ve ekonomi kararları VERİLDİ, oynanabilir HTML taslakları HAZIR,
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
- **2048 kostüm sırası:** 2 Klasik (`zibo_yeni`), 4 Hippi, 8 Sporcu, 16 Asker, 32 Hoca, 64 Punk,
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

## 8. Uygulama planı (limit sıfırlanınca)

**Aşama 0 — deneme (tek oyun):** `webview_flutter` ekle, Zibo Hafıza'yı (ya da Kule'yi) köprüsüyle
telefonda aç; açılış süresi, dokunma, ses, geri tuşu, Appodeal rewarded akışı gerçek cihazda doğrulanır.
Kullanıcı onaylarsa hibrit yol kesinleşir.

**Aşama 1 — ilk sürüm:**
- `GamePointsProvider` (yeni, `CloudStateStore` → `users/{uid}/state/gamePointsState`): puan bakiyesi,
  haftalık takas (`weekEx`), oyun başına günlük hak/reklam sayaçları, rekorlar, açılan süsler.
- Takas Gişesi ekranı + Oyun Salonu ekranı + modül menüsüne giriş.
- İlk oyunlar: **Hafıza + 2048** (bulmaca).
- TR/EN/ES ARB anahtarları (Flutter tarafı) + oyun içi sözlükler.
- Testler: provider (kur hesabı, tavan, hafta/gün sıfırlama, tur tavanı doğrulaması), köprü mesaj işleme.
- `docs/subscribe_model.md`'ye Pro/Pro+ takas tavanı perk'i, `docs/theme_new.md`'ye onaylı ekranlar.

**Aşama 2:** Coin Yakala + Zibo Tren. **Aşama 3:** Zıpla, Tuğla, Kule.
Her aşama ayrı sürüm → her güncellemede "yeni oyun geldi" haberi.

## 9. Bekleyen kararlar

1. Hibrit (WebView) yolun son onayı — Aşama 0 denemesinden sonra.
2. Hafıza ve 2048 puanları diğer oyunlarla aynı seviyeye çekilsin mi?
3. Zibo 2048 tasarımındaki 3 soru (bölüm 5).
4. İlk sürümde hangi oyunlar (öneri: Hafıza + 2048).
5. Haftalık puan sıralaması gerçek mi olacak (backend gerekir) yoksa ilk sürümde çıkarılsın mı?
