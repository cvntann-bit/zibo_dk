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
| ~~Ana Sayfa (Zibo'ya hızlı dokunma)~~ | Interstitial | **2026-10-26 KALDIRILDI** — dokunurken açılıp kazara tıklama üretiyordu (CTR %55) | — |
| Günlük Ödüller ekranı | Interstitial | `dailyReward` yerleşimi | `daily_rewards_screen.dart` |
| Hedef Takibi 7/7 | Interstitial | `goalCycle` | `goal_tracking_screen.dart` |
| Şükran kaydı → ekrandan çıkış / yeni rüya kaydı → listeye dönüş | Interstitial | `journalSaved` (2026-10-26) | `gratitude_journal_screen.dart`, `dream_entry_form_screen.dart` |
| Mağaza "Bugünün vitrini" | Rewarded | kostüm nadirliğine göre 1–5 video → 24 saat deneme, günde 1 deneme (2026-10-26) | `store_screen.dart` `_CostumeTrialCard`, `costume_provider.dart` |
| Oyun Salonu ikinci şans / ekstra hak | Rewarded | tur başına 1 devam, 5 sn sayaç (2026-10-26) | `assets/games/{tren,tugla,kule}` |
| Banner | Banner | kod var, gerçek doluluk yok (bkz. hafıza: banner 0 fill) | `banner_ad_reload_signal.dart` |

Tek giriş noktası `CoinProvider.showInterstitialAd(placement)` (Pro/reklamsız kontrolü + sıklık kuralları orada).

**Interstitial sıklık kuralları (2026-10-26, `lib/services/interstitial_pacer.dart`, yalnız cihazda):** ilk açılıştan sonra
3 saat hiç yok (kullanıcı kararı: 24 sa yerine 3 sa), günde en fazla 2, iki gösterim arası ≥4 dk. Her karar Firebase'e
`interstitial_shown` / `interstitial_skipped{reason}` / `interstitial_unavailable` olarak `placement` ile düşer.

**Rewarded sınırları (kullanıcı "kendi denklemini kur" dedi):** toplam bir üst sınır KONMADI — rewarded en iyi gelir
kalemi (fill %60–87, eCPM ~1 $) ve kullanıcı kendi isteğiyle izliyor; her kaynak zaten kendi doğal sınırına sahip:
mağaza coin 2/gün, çark günlük hak, oyun devam turu başına 1 (turlar günlük oyun hakkıyla sınırlı), kostüm denemesi
günde 1 deneme (≤5 video). Coin VERMEYEN rewarded'lar (deneme, oyun devamı) coin ekonomisini şişirmez.

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

## 2c. Appodeal Monetization Dashboard (14–21 Eki 2026, 8 gün; son gün kısmi)

| Metrik | Değer |
|---|---|
| Gösterim (impressions) | **235** (günde ~21–51) |
| Waterfall istekleri | 5.104 |
| Fill rate | 32,5% (günlük %25–57) |
| Display rate | **14,2%** (dolan reklamın yalnızca ~%14'ü gösteriliyor) |
| CTR | 55,7% (anormal yüksek — aşağıya bak) |
| eCPM | 0,77 $ (günlük 0,15–1,70 $) |
| Reklam geliri | 0,18 $ |
| Active users | 708 · Ad ARPU 0,0003 $ |

Kontrol: 235 × 0,7662 / 1000 ≈ 0,18 $ ✓.

**Darboğaz = gösterim sayısı** (eCPM değil): ~120 DAU ile günde ~30 gösterim ≈ DAU başı ~0,25 gösterim/gün.
Aynı eCPM'de (0,77 $, tahmin) DAU başı 3 gösterim/gün ≈ 0,0023 $/DAU/gün ≈ 0,07 $/DAU/ay →
3,5 bin DAU'da ~240 $/ay (10 bin kullanıcı varsayımı, ölçülmemiş) — gider tahmininin (15–50 $) üstünde.

Koddan neden az gösterim (okundu): interstitial yalnızca (1) Zibo'ya art arda hızlı dokunma (rastgele: reklam VEYA
Reklamsız tanıtımı), (2) Günlük Ödüller ekranı girişi, (3) Hedef Takibi 7 günlük döngü tamamlanışında (haftada ~1)
tetikleniyor; rewarded günde en fazla 2 + çark. Yani gösterim kullanıcı davranışına bağlı, tasarlanmış bir
sıklık yok. Reklam hazır değilse (`_waitUntilLoaded`) hiç gösterilmiyor.

**Dikkat edilecekler:**
- **CTR %55,7 çok yüksek** (tipik beklenti çok altında; küçük örneklem 235 gösterim). Kazara tıklama / tıklamaya
  yol açan yerleşim olabilir; ad ağları geçersiz trafiği cezalandırır → reklamların tam ekran kapanış/geçiş anlarını
  ve tıklama kaynağını incele. Henüz sebep BİLİNMİYOR, ölçüm gerek.
- Display rate %14: dolan reklamların çoğu önceden yükleniyor ama gösterilmiyor (normal olabilir; asıl sorun
  gösterim tetikleyicisinin azlığı).
- Fill rate %32,5: istekler çoğu boş kalıyor; yalnızca AppLovin + Vungle adaptörü var → ağ eklemek fill'i artırır
  (DEX maliyetiyle, Faz 3).
- 5.104 istek / 235 gösterim: gereksiz istek (pil/veri), ama fatura etkisi yok.

## 2d. Reklam türü kırılımı (ekranda görünen 4 gün: 18–21 Eki; kalan 4 gün henüz görülmedi)

| Gün | Tür | Gösterim | İstek | Fill | Display | CTR | Gelir | eCPM |
|---|---|---|---|---|---|---|---|---|
| 21 (kısmi) | Interstitial | 3 | 110 | %37,3 | %7,3 | %66,7 | 0 | 0 |
| 21 (kısmi) | Rewarded | 6 | 67 | %86,6 | %10,3 | %83,3 | 0 | 0 |
| 20 | Interstitial | 35 | 550 | %26,2 | %24,3 | %31,4 | 0,01 $ | 0,21 $ |
| 20 | Rewarded | 16 | 266 | %75,2 | %8,0 | %56,3 | 0 | 0 |
| 19 | Interstitial | 17 | 678 | %12,8 | %19,5 | %64,7 | 0,02 $ | 0,92 $ |
| 19 | Rewarded | 15 | 283 | %61,1 | %8,7 | %66,7 | 0,02 $ | 1,04 $ |
| 18 | Interstitial | 28 | 515 | %21,4 | %25,5 | %53,6 | 0,03 $ | 1,04 $ |
| 18 | Rewarded | 7 | 247 | %66,8 | %4,2 | %57,1 | 0,01 $ | 1,11 $ |
| Hepsi | **Banner** | **0** | **0** | — | — | — | 0 | 0 |

Okuma:
- **Banner: 0 istek, 0 gösterim** → gelir katkısı sıfır (bilinen durum; destek cevabı bekleniyor, adaptörlere dokunma).
- **Rewarded:** fill çok iyi (%61–87), eCPM ~1,0–1,1 $ (interstitial'dan genelde yüksek), kullanıcıyı rahatsız etmiyor
  (kendi isteğiyle izliyor) → ölçeklenecek ana kalem. Display rate düşük çünkü reklam önceden yükleniyor, kullanıcı butona basınca gösteriliyor.
- **Interstitial:** fill düşük (%13–37), eCPM dalgalı (0,21–1,04 $). Aynı gün 16 rewarded + 35 interstitial gösterimi
  ama 20 Eki gelir ≈ 0,01 $ → **bazı gösterimler 0 gelir getirmiş** (veri gecikmesi/rapor olgunlaşması olabilir —
  son günlerin geliri sonradan güncellenir; kesin değil, 2–3 gün sonra tekrar bak).
- Bu tabloda ağ kırılımı yok (hangi ağ ne kadar kazandırıyor?) → "Network (Monetization)" kutusu işaretlenip bakılacak.

## 2e. Ağ kırılımı (ekranda görünen 19–21 Eki satırları; toplam waterfall isteği ağ başına sayıldığı için 9.185)

| Tür | AppLovin | Vungle |
|---|---|---|
| Rewarded | fill %61–87, gösterim 6/16/15 (21/20/19), eCPM ~1,04 $ (19 Eki) | gösterim 0, fill %0,9–11 |
| Interstitial | fill %11–21, gösterim 3/18/13, eCPM ~1,08 $ (19 Eki) | fill %1,5–16, gösterim 0/17/4, eCPM ~0,39–0,44 $ |

Okuma: **gelirin neredeyse tamamı AppLovin'den**; Vungle çok düşük dolduruyor ve eCPM'i ~yarısı. Görünen satırlarda başka
ağ yok → tek ağa bağımlılık riski (AppLovin hesabı/politikası sorunu = gelirin tamamı gider). Fill'i ve rekabeti
artırmanın yolu yeni ağ eklemek (Faz 3), ama her adaptör DEX maliyeti getirir (bkz. `project_ad_network_dex_cleanup`).
Kalan 5 günün satırları ve Appodeal'in kendi talebi (varsa) bu ekranda görülmedi.

## 2f. Kullanıcı sayıları (Firebase Analytics, 21 Eki 2026) — gelir hesabı için doğru payda

DAU **194** · WAU **724** · MAU **~1,4 bin**. Appodeal'in "Active Users 631/708" (8 günlük pencere) bununla tutarlı.
Güncel gelir ≈ 0,18–0,27 $ / 8 gün → **DAU başı günlük ≈ 0,0001–0,0002 $**. Firestore (24 sa): 69 bin okuma + 23 bin yazma → Blaze ücretsiz kotası aşımı çok küçük (ihmal edilebilir); gider tahminindeki 2.500 kullanıcı varsayımı yerine **gerçek MAU ~1,4 bin** kullanılmalı.

## 2g. Play Console gelir/puan (son 28 gün, 22 Eki 2026)

**Google Play geliri: "–" → hiç IAP / abonelik satışı yok** (coin paketleri, Reklamsız, Pro/Pro+ dahil). Yani tüm gelir şu an ~1 $/ay reklam. Puan: 4,857 ★ (21 kullanıcı). Edinim 2,33 bin, aylık etkin cihaz 747. → Dönüşüm (satış) sıfır: paywall/mağaza fiyat-değer dengesi ve ilk-deneyim (onboarding) incelenmeli; "zarar etmemek" için en büyük kaldıraç gösterim sayısı + ilk satın alma dönüşümü.

## 2h. Banner ÜRETİM verisi (Firebase Analytics olayları, 24 Eki-21 Eki, 28 gün)

`banner_failed` **26.078 olay · 1.061 kullanıcı (kullanıcıların %77'si, kullanıcı başı ~25 deneme)** — en sık olay; 2 Eki'de (1.14.1 teşhis olayları) başlıyor. **`banner_loaded`, `banner_shown`, `banner_clicked`, `banner_show_failed` HİÇ YOK** → banner üretimde ASLA yüklenmiyor (docs'taki yorum tablosu: failed >> loaded = sorun TALEP/yapılandırma tarafı, bizim yerleşimimiz değil). `appodeal_init`: 2.180 olay, 1.073 kullanıcı (parametreleri `ok`/`errors` özel boyut olarak kayıtlı olmadığı için konsolda görünmüyor).
**Cihaz bulgusu (2026-10-22, SM-A226BR, debug 1.15.0):** açılışta `Appodeal init errors: InternalError: SdkConfigurationError null` (consent "Presentation not required" normal). Bu hatanın banner başarısızlığıyla ilgili olup olmadığı BİLİNMİYOR → Faz 3'te: hata ayrıntısı, `appodeal_init` parametrelerini özel boyut yap veya BigQuery, Appodeal desteği. Banner başına ~25 başarısız deneme = gereksiz istek/pil; gelir katkısı SIFIR.

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
