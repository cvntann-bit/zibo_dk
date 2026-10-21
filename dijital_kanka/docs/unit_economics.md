# Zibo — Kullanıcı Başına Gelir/Gider Dengesi (ÖNEMLİ, 2026-10-21)

**Amaç: zarar etmemek.** Her büyüme/özellik/reklam kararı bu dengeye bakılarak alınır.
Kural: **kullanıcı başı (ARPDAU/ARPU) gelir > kullanıcı başı gider** her zaman; fark küçülürse
önce gider kesilir/reklam artırılır, sonra yeni özellik.

> Bu dosyadaki rakamlar **ölçülmemiş TAHMİNdir** (kodu okuyarak hesaplandı). "ÖLÇÜLECEK"
> işaretli her değer Appodeal/Firebase/Play panelinden gerçeğiyle değiştirilecek. Birim
> fiyatlar Firebase fiyat sayfasından teyit edilmeli (bölgeye göre değişir).

## 1. Gider tarafı (kullanıcı sayısına göre)

| Kalem | Mantık | 10 bin kullanıcıda tahmini aylık |
|---|---|---|
| Firestore — saatlik cron tam `users` taraması | 5 iş × 24 saat × kullanıcı sayısı okuma (`notification-scripts/src/common.js:156`) | ~10–22 $ (**düzeltilebilir**) |
| Firestore — uygulama okuma | ~40 belge/oturum, DAU %30–40, 2 oturum/gün | ~3–5 $ |
| Firestore — uygulama yazma | her `save` = 1 tam belge yazma, ~60/gün/aktif | ~8–11 $ |
| Depolama | ~0,8 GB | ~0–1 $ |
| Cloud Functions (makbuz doğrulama, ileride) | 2M çağrı ücretsiz kota | ~0 $ |
| FCM / Crashlytics / Analytics / anonim Auth | ücretsiz | 0 $ |
| GitHub Actions dakikası | saatlik iş, kullanıcıyla uzar; depo özelse kotayı kontrol et | ÖLÇÜLECEK |
| Play komisyonu (IAP/abonelik) | satışın %15–30'u (program koşullarına göre, teyit et) | gelirden kesinti |
| **Toplam (bugünkü kodla)** | | **~15–50 $/ay ≈ 0,0015–0,005 $/kullanıcı/ay** |

Gider kontrol kolları: (a) cron taramasını tek taramaya/sorguya indir (5–50× azalma), (b) `save`
çağrılarını debounce et (yazma azalır), (c) açılışta okunan belge sayısını azalt, (d) bütçe uyarısı
(Faz B, `roadmap_growth_2026-10.md`).

## 2. Gelir tarafı

Kaynaklar: (1) rewarded reklam, (2) interstitial, (3) banner (şu an 0 fill), (4) IAP coin paketleri,
(5) Pro/Pro+ abonelik (**ürün/plan fiyatları `docs/subscribe_model.md`**).

### Mevcut reklam yerleşimleri (koddan)

| Yerleşim | Tür | Kural | Dosya |
|---|---|---|---|
| Mağaza "Reklam izle, coin kazan" | Rewarded | günde en fazla 2 (`maxDailyAdWatches`), ödül 20 ZC | `coin_provider.dart:65,393`, `coin_economy.dart:7` |
| Şans Çarkı | Rewarded | Pro/Pro+ reklamı atlar; free izlemek zorunda; günlük çark hakkı | `coin_provider.dart:544` |
| Ana Sayfa | Interstitial | reklamsız/Pro'da engelli | `home_screen.dart:289` |
| Günlük Ödüller ekranı | Interstitial | aynı | `daily_rewards_screen.dart:56` |
| Hedef Takibi | Interstitial | aynı | `goal_tracking_screen.dart:119` |
| Banner | Banner | kod var, gerçek doluluk yok (bkz. hafıza: banner 0 fill) | `banner_ad_reload_signal.dart` |

Tek giriş noktası `CoinProvider.showInterstitialAd` (Pro/reklamsız kontrolü orada).

### Kullanıcı başı gelir formülü (ÖLÇÜLECEK değerlerle doldurulur)

```
Günlük reklam geliri / DAU =
   (rewarded gösterim/DAU × rewarded eCPM/1000)
 + (interstitial gösterim/DAU × interstitial eCPM/1000)
 + (banner gösterim/DAU × banner eCPM/1000)

Aylık net / kullanıcı = ARPDAU × 30 × (aktiflik oranı)  +  IAP/abonelik net  −  kullanıcı başı gider
```

Girdi tablosu (şu an BOŞ — Faz 0'da Appodeal/Firebase'den doldurulacak):

| Metrik | Değer | Kaynak |
|---|---|---|
| Rewarded eCPM (TR) | ÖLÇÜLECEK | Appodeal paneli |
| Interstitial eCPM (TR) | ÖLÇÜLECEK | Appodeal paneli |
| Rewarded gösterim / DAU / gün | ÖLÇÜLECEK (üst sınır 2 + çark) | `ad_analytics` olayları |
| Interstitial gösterim / DAU / gün | ÖLÇÜLECEK | `ad_analytics` olayları |
| DAU / toplam kullanıcı | ÖLÇÜLECEK | Firebase Analytics |
| Gün-1/7/30 retention | ÖLÇÜLECEK | Firebase/Play |
| IAP + abonelik net gelir / kullanıcı | ÖLÇÜLECEK | Play Console |

## 2b. İLK ÖLÇÜM — Appodeal Overview (12–19 Eki 2026, 8 gün, ekran görüntüsünden okundu)

| Metrik | Değer |
|---|---|
| Toplam reklam geliri (8 gün) | **0,27 $** (günlük ~0,02–0,06 $, ort. ~0,034 $) |
| Active Users (dönem) | 631 (günlük ~65–190, artan eğilim) |
| ARPU (dönem) | 0,0004 $ |
| New Installs | 581 (hepsi organik, 0 ücretli; günlük ~35 → ~115 artıyor) |
| Appodeal bakiyesi (sağ üst) | 1,60 $ |

Türetilen (tahmin): gelir ≈ **1 $/ay** (şu anki trafikle); aktif kullanıcı başı ≈ 0,0015 $/ay,
DAU başı günlük ≈ 0,0002 $.

**Okuma (dürüst):** reklam geliri şu an gider tahminiyle aynı büyüklükte ya da altında (gider
tahmini 2.500 kullanıcıda ~2–4 $/ay; Firebase ücretsiz kota bir kısmını karşılıyor olabilir —
gerçek fatura henüz ölçülmedi). Yani **reklam geliri tek başına bugün dengeyi KURMUYOR**; hâlâ
çok düşük hacim ve düşük DAU başı gösterim/eCPM. Bu ekran gösterim sayısı, eCPM, fill rate,
ağ ve reklam türü kırılımı vermiyor → sebep (az gösterim mi, düşük eCPM mi, düşük fill mi)
henüz BİLİNMİYOR. Sonraki ölçüm: Appodeal > Analytics'te reklam türü + ağ + ülke kırılımı,
impressions, eCPM, fill rate.

Not: 8 günlük pencere, son günler gecikmeli olabilir; trend (yükselen yükleme/aktif kullanıcı,
düşen ARPU) izlenmeli.

## 3. Denge ilkeleri

1. **Her yeni ücretsiz coin kaynağı reklam gelirini yemesin:** Coin ödülü (ör. reklam başı 20 ZC) ile
   kullanıcının harcayabileceği şeylerin (kostüm 440–33000 ZC) gerçek değeri, reklamın eCPM'inden
   kazanılan paradan düşük kalmalı. Ekonomi fiyat kararları (kostüm fiyatları) bu dengeyle bağlantılı.
2. **Rewarded > interstitial** gelir/etki oranı genelde yüksek ve kullanıcıyı daha az rahatsız eder;
   yerleşim eklerken önce rewarded'ı düşün, interstitial'ı sıklık sınırıyla (cooldown) ekle
   (retention'ı düşürürse kazanç değil zarar — Faz 4 ile birlikte ölç).
3. **Reklamsız/Pro:** Pro/Pro+ interstitial'ı kapatıyor → abonelik net geliri, kaybedilen reklam
   gelirinden (aynı kullanıcı için) yüksek olmalı. Fiyat/perk kararı bununla kontrol edilir.
4. **Gider kontrolü büyümeden ÖNCE:** cron taraması ve yazma sıklığı düzeltilmeden büyüme kampanyası
   yapma — gider kullanıcıyla doğrusal artıyor.
5. **Başa baş noktası:** `kullanıcı başı aylık net gelir ≥ kullanıcı başı aylık gider`. Şu an gider
   ~0,0015–0,005 $/kullanıcı/ay; reklam geliri bunun çok üstünde olmalı. Gerçek ARPDAU ölçülünce
   marj hesaplanır.
6. **Her sürüm sonrası** tabloyu güncelle (gelir, gider, retention). Düşen marj = durdur ve düzelt.

## 4. Yapılacaklar (sıra)

1. Faz 0: tablodaki ÖLÇÜLECEK değerleri doldur (Appodeal eCPM, DAU, retention, Firestore günlük okuma/yazma).
2. Gerçek rakamlarla kullanıcı başı net marj hesapla ve bu dosyaya yaz.
3. Gider: cron taraması + yazma debounce (Faz B).
4. Gelir: ağ ekleme (Faz 3, yalnızca eCPM'i yükseltenler), banner doluluğu, yerleşim denemeleri — her biri
   tek tek ölçülerek (A/B değil; sürüm öncesi/sonrası karşılaştırma + retention kontrolü).
5. Pro/Pro+ fiyatlarını marjla çapraz kontrol et.
