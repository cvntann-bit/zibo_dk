# Zibo Pro / Pro+ Abonelik Modeli

> **Durum:** Faz 1 (altyapı) + Faz 2 (paywall ekranı) tamamlandı, paywall
> 2026-09-23'te komple yeniden tasarlanıp Mağaza'ya taşındı, "Pro+ Analitik/
> Grafik Genişletmesi" (2026-09-24, aşağıya bkz.) devam ediyor. Bu dosya
> abonelik sistemiyle ilgili HER ŞEYİN (ürünler, fiyatlar, perk listeleri,
> giriş noktaları, teknik mimari) tek kaynağı — **abonelik modeliyle ilgili
> her değişiklikte (yeni perk, fiyat güncellemesi, yeni giriş noktası vb.)
> bu dosya da güncellenir**, `docs/theme_new.md`'nin devam eden tasarım
> değişikliği için oynadığı role BİREBİR benzer.

## Play Console ürün/plan yapısı

**2 ürün, her birinde 2 temel plan** (4 düz ürün ID'si DEĞİL):

| Ürün ID | Temel plan ID | Katman | Süre |
|---|---|---|---|
| `zibo_pro` | `monthly` | Pro | Aylık |
| `zibo_pro` | `yearly-plan` | Pro | Yıllık |
| `zibo_proplus` | `monthly` | Pro+ | Aylık |
| `zibo_proplus` | `yearly-plan` | Pro+ | Yıllık |

Kod tarafında bu 4 teklif `lib/data/subscription_products.dart`'taki
`subscriptionOffers` sabit listesinde (`SubscriptionOffer` — bkz.
`lib/models/subscription_offer.dart`) tanımlı. Buna ek olarak, aboneliklerden
BAĞIMSIZ **tek seferlik/kalıcı** bir ürün daha var: `remove_ads_lifetime`
("Tek Seferlik Reklamsız", `AdFreeProvider` üzerinden yönetiliyor).

**Referans fiyatlar** (Play Console'a girilen, KDV dahil — `SubscriptionOffer.
fallbackPrice`'ta sabit/görsel yer tutucu olarak da tutuluyor):

| Katman | Aylık | Yıllık |
|---|---|---|
| Zibo Pro | 59,90₺ | 449,90₺ |
| Zibo Pro+ | 99,90₺ | 749,90₺ |
| Tek Seferlik Reklamsız | — | 159,90₺ (tek seferlik) |

## Katman perk listeleri

**Zibo Pro:**
- Zorunlu reklamlar kalkar
- Check-in coin ödülü 1,5 kat
- Ayda 1 ücretsiz Streak Freeze
- Şans Çarkı reklamsız + günde 1 ekstra çevirme
- Modüllerde sınırsız geçmiş
- Bildirim saatini kişiselleştir

**Zibo Pro+** (Pro'nun tüm avantajları +):
- Check-in coin ödülü 2 kat (Pro'nun 1,5 katı yerine)
- Ayda 3 ücretsiz Streak Freeze (Pro'nun 1'i yerine)
- Ayda 1 Pro'ya özel kostüm/tema
- Özel profil rozeti/çerçevesi
- Paylaşım kartlarında özel Pro+ filigranı
- Detaylı trend grafiği
- Para & Birikim gelişmiş analiz
- Özel bildirim sesleri

> **NOT — bu perk'lerin ÇOĞU henüz GERÇEKTEN uygulanmadı.** Faz 2 yalnızca
> paywall'ı (satın alma arayüzü + perk METİNLERİ) kurdu — "check-in coin 1,5x"
> gibi gerçek davranış değişiklikleri (`CoinProvider`, `AppStreakProvider`
> vb.'de `SubscriptionProvider.isPro`/`isProPlus` kontrolü) AYRI, gelecek
> fazların işi. Bu dosyanın "Perk uygulama durumu" tablosu (aşağıda) hangi
> perk'in gerçekten koda bağlandığını izler.

### Perk uygulama durumu

| Perk | Durum |
|---|---|
| Zorunlu reklamlar kalkar (A1) | ✅ Uygulandı — `CoinProvider.showInterstitialAd()` (interstitial) VE `BannerAdSlot` (banner) `isPro` kontrolü. Şans Çarkı'nın "çevirmek için reklam izle" zorunluluğu bu kapsamda DEĞİL, ayrı perk → bkz. B4. |
| Check-in coin ödülü 1,5x/2x (B1) | ✅ Uygulandı — `CoinProvider.earnDailyLoginReward()`, `isPro`/`isProPlus` callback'leri (`lib/main.dart`), bonus etiketi `CoinBalanceWidget` (`coinProBonusLabel`/`coinProPlusBonusLabel`) |
| Şans Çarkı reklamsız + ekstra çevirme (B4) | ✅ Uygulandı — `CoinProvider.watchAdAndSpinWheel()` (`isPro` ise reklam atlanır) + `maxDailyWheelSpins` instance getter'ı (Pro/Pro+ +1 hak). Çark ekranındaki "Reklam İzle ve Çevir" görseli (`zibo_cark_frame.png`) HENÜZ güncellenmedi — Pro'da da aynı görünüyor, davranış doğru çalışıyor |
| Modüllerde sınırsız geçmiş (D1) | ✅ Uygulandı — Şükran/Ruh Hali/Manifest ekranları `isPro` değilse listeyi son 30 güne filtreliyor (veri SİLİNMİYOR), gizli kayıt varsa ortak `HistoryLimitUpsellCard` (`lib/widgets/history_limit_upsell_card.dart`) gösteriliyor |
| Ayda 1/3 ücretsiz Streak Freeze (B3) | ✅ Uygulandı — Streak Freeze mekaniği SIFIRDAN yazıldı (kodda hiç yoktu, yalnızca fiyat sabiti vardı). "Kaçırılan günü tamir et" modeli: `AppStreakProvider.isStreakAtRisk` + `StreakFreezeOfferDialog` (`lib/widgets/streak_freeze_offer_dialog.dart`), `RootScreen._recordAppStreakOpen()`. Aylık kota `freeStreakFreezesUsedThisMonth`/`freeStreakFreezeResetDate` (`appStreakState` dokümanı) |
| Bildirim saati kişiselleştirme (E1) | ⏳ Yalnızca paywall'da METİN — planlandı ama kullanıcı Faz 5'e geçince ertelendi, henüz onay YOK |
| Profil rozeti/çerçevesi (C2) | ✅ Uygulandı — GERÇEK görsel: `ProfileScreen` avatarının TAMAMINI saran halka (`pro_profile_frame.webp`/`proplus_profile_frame.webp`, Zibo Pro(+) materyalleri — ilk placeholder köşe-rozeti yerine geçti) |
| Zibo logosu Pro/Pro+ varyantı (ek istek) | ✅ Uygulandı — `RootScreen` AppBar'ındaki Zibo logosu artık abonelik durumuna göre `zibo_pro_logo.webp`/`zibo_pro_plus_logo.webp` (Pro+ dosyası bir dama-deseni arka plan sorunu taşıyordu, `tool/` ile temizlendi) |
| Paylaşım kartında Pro filigranı (C3) | ✅ Uygulandı — `ZiboShareCard`, Pro VE Pro+ ikisi de görüyor (`pro_watermark.png`, HÂLÂ PLACEHOLDER). NOT: paywall metni bunu Pro+'a ÖZEL diye listeliyor, kullanıcının bu turki isteğiyle çelişiyor — ayrı görev olarak flaglendi |
| Aylık rotasyonlu Pro+'a özel kostüm/tema (C1) | 🚫 Kullanıcı isteğiyle KAPSAM DIŞI — uygulanmayacak |
| Pro+'a özel bildirim sesleri (E2) | ✅ Uygulandı — 5 YENİ Android bildirim kanalı (`push_notifications_proplus_1..5`, immutable kanal-sesi kısıtı yüzünden), `PushNotificationProvider.proPlusSoundChoice` (`users/{uid}` kök alanı, Pattern B), `notification-scripts/src/common.js`'in `sendToUser`'ı tek yerden çözüyor. **2026-09-23** — kullanıcının Masaüstü'ne koyduğu 5 GERÇEK ses dosyası (`zibo_alert_1..5.mp3`) `android/app/src/main/res/raw/proplus_sound_1..5.mp3` olarak eklendi, artık placeholder DEĞİL. Kanal immutable kısıtı yüzünden ZATEN 1/2/3 kanalıyla kurulmuş bir cihaz (bu makinedeki test cihazı dahil) eski sesi duymaya devam eder — yeni sesi duymak için uygulamanın TAMAMEN kaldırılıp yeniden kurulması gerekir. **2026-09-23 EK** — Ayarlar'daki seçicide bir seçeneğe dokununca sesi ANINDA önizler (`_playProPlusSoundPreview`, `audioplayers` + `android.resource://` URI'siyle native `res/raw/` kaynağını doğrudan çalıyor, Flutter asset kopyası GEREKMEDİ). Sunucu tarafı yalnızca kod incelemesiyle doğrulandı, Node.js bu makinede yok |
| Ruh Hali detaylı trend grafiği (D2) | ✅ Uygulandı — `MoodTrendDetailChart` (`fl_chart`, `MoneyTrendChart` ile AYNI desen), `Mood.score` (1-5) extension'ı eklendi. **2026-09-24 yeniden tasarım/taşıma** — Profil > İstatistiklerim'den kaldırılıp Ruh Hali Takibi'nin kendi ekranına ("Son 7 Gün" şeridinin altına) taşındı; günlük ham skor yerine seçilen granülariteye göre (haftalık ISO hafta/aylık takvim ayı) ORTALAMA skoru kovalayıp çiziyor, son 8 haftalık/6 aylık dolu kova gösteriliyor. İlk mount'ta düz taban çizgisinden gerçek değerlere "dolma" animasyonu eklendi (`LineChart`'ın implicit `duration`/`curve`'ü) — projedeki ilk grafik giriş animasyonu, diğer trend grafikleri için şablon. **2026-09-24 İKİNCİ güncelleme — kilit deseni değişti**: artık Pro+ olmayan kullanıcıdan TAMAMEN gizlenmiyor, `LockedFeatureOverlay` ile başlık/toggle görünür kalıp yalnızca çizim alanı bulanıklaştırılıyor (bkz. aşağıdaki "Pro+ grafik kilidi" bölümü). Veri yoksa VE kilitliyse sabit bir örnek dalga bulanıklaştırılıyor (gerçek veri gibi sunulmuyor) |
| Para & Birikim gelişmiş analiz (D3) | ✅ Uygulandı, **2026-09-24 TAMAMEN yeniden tasarlandı** — eski 3 satırlık metin özeti (ortalama aylık harcama/birikim, en çok harcanan kalem) KALDIRILDI, yerine: (1) her para biriminin KENDİ ayrı kartında üç kategori toplamı (`MoneyProvider.totalsByCurrencyFor`, otomatik kur çevirisi YOK — mevcut çoklu para birimi mimarisiyle AYNI kural), (2) harcama kalemlerinin donut grafiği (`fl_chart` `PieChart`, en büyük 4 kalem + "Diğer" dilimi, `MoneyProvider.expenseBreakdownByNameFor` — YENİ getter, TAM dağılım döner). `averageMonthlyFor`/`topExpenseItemByCurrency` getter'ları KODDA KALDI (silinmedi, artık UI'da kullanılmıyor). Bölüm `LockedFeatureOverlay` ile bulanıklaştırılıyor (aşağıya bkz.). Bonus: "Mevcut Durum" trend grafiğine (bu bölümün DIŞINDA, HERKESE açık) üçüncü bir "Aylık" granülarite seçeneği eklendi |
| Su Takibi trend grafiği + hedef oranı (2026-09-24, YENİ) | ✅ Uygulandı — `WaterTrendChart` (`lib/widgets/water_trend_chart.dart`), Mood/Money ile AYNI desen: Günlük/Haftalık/Aylık `SegmentedButton` (Haftalık/Aylık metinleri `moneyTrendGranularityWeekly/Monthly` ARB anahtarları YENİDEN KULLANILIYOR, aynı metin olduğu için yeni anahtar açılmadı), günlük görünüm son 14 güne ait ham `consumedMl`, haftalık/aylık ISO-hafta/takvim-ayı bazında ORTALAMA (son 8/6 dolu kova, boş kova atlanıyor). Grafiğin üstünde hedefi gösteren kesikli yatay referans çizgisi (`ExtraLinesData`/`HorizontalLine`, `goalMl`), altında ortalama hedef tutturma yüzdesi özeti (`_GoalRateSummary`, tüm `WaterEntry.unitCount/goalUnitCount` ortalaması). `LockedFeatureOverlay` ile bulanıklaştırılıyor; veri yoksa VE kilitliyse 7 noktalık sabit örnek seri kullanılıyor. `WaterEntry` geçmiş günlerin O GÜNKÜ hedef/birim ayarını koruduğu için hedef çizgisi/oran hesap doğru kalıyor |

## Paywall ekranı (`lib/screens/paywall_screen.dart`)

**2026-09-23'te "sticker" görsel diline göre komple yeniden tasarlandı**
(bkz. Güncelleme geçmişi) — Zibo karakteri + dönen teşvik balonu, sosyal
kanıt satırı, yan yana Pro/Pro+ kartları (Pro+ öne çıkarılmış, "En Popüler"
rozeti — kartlar EŞİT yükseklikte, `Row`'a `stretch` + kartın içine `Spacer`
ile hizalanıyor), altında de-emphasize edilmiş Tek Seferlik Reklamsız satırı,
Ücretsiz/Pro/Pro+ karşılaştırma tablosu. İlk mount'ta fade+slide giriş
animasyonu + CTA butonlarında sonlu (3 döngü, `repeat()` DEĞİL — testlerin
`pumpAndSettle()`'ını sonsuza kadar bekletmemesi için) bir nabız animasyonu.

Ekran ikiye ayrıldı: **`PaywallContent`** (asıl içerik, `embedded: bool`
parametresiyle hem tam ekran modal hem Mağaza'ya gömülü kullanılabiliyor) +
**`PaywallScreen`** (`embedded: false` için ince `Scaffold` sarmalayıcısı,
sağ üstte KASITLI olarak her zaman görünür/erişilebilir kapatma X'i — Play
Store politikası satın almaya teşvik ederken kapatmayı gizlemeyi/
zorlaştırmayı yasaklıyor).

3 seçenek TEK ekranda: Tek Seferlik Reklamsız + Zibo Pro + Zibo Pro+, üstte
Aylık/Yıllık geçiş anahtarı. Kullanıcı zaten Pro/Pro+ ise:
- **Tek Seferlik Reklamsız kart GİZLİ** (Pro zaten reklamları kaldırıyor).
- **Pro kartı**: kullanıcı Pro ise "Mevcut Planın" rozeti; Pro+ ise "Zaten
  Pro+ Kullanıcısısın" rozeti (satın alma butonu YOK).
- **Pro+ kartı**: kullanıcı Pro ise buton "Pro+'a Yükselt"e döner (gerçek
  Play Billing "abonelik değiştirme" akışı — aşağıya bkz.); Pro+ ise "Zaten
  Pro+ Kullanıcısısın" rozeti.

### Giriş noktaları

1. **Mağaza'nın "Zibo Pro" sekmesi** (`store_screen.dart`, `StoreSection.pro`)
   — **2026-09-23'te Ayarlar'ın YERİNE geçti** (kullanıcı isteği: "artık
   ayarlar kısmında durmasın"). `PaywallContent(embedded: true)` DOĞRUDAN
   gömülü — kapatma X'i YOK (sekme zaten "kapatılabilir"), kendi kaydırması
   YOK (dış `ListView`'a bırakılıyor), satın alma sonrası sekmeden
   AYRILMIYOR. Coin Al/Kostümler/Temalar'ın yanına 4. segment olarak eklendi.
2. **Ana Sayfa'da Zibo'ya art arda 5 hızlı dokunma** — %25 ihtimalle (bkz.
   `home_screen.dart` `_showRapidTapPromoOrAd`). Tam ekran `PaywallScreen`
   (`embedded: false`) açar.
3. **Mağaza'daki kalıcı "Reklamsız Zibo" kartı** (`store_screen.dart`
   `_AdFreeCard`) — her zaman ekranda durur, tam ekran `PaywallScreen` açar.
4. **Mağaza'ya periyodik ziyaret promosu** (`AdFreePromoTrigger` — her 5.
   ziyaret + 3 günlük cooldown, `store_screen.dart`
   `_maybeShowAdFreePromo`). Tam ekran `PaywallScreen` açar.
5. **Ayarlar'daki kilitli Pro+ özellik satırları** (ör. "Bildirim Sesi" —
   Pro+ değilse 🔒 + dokununca paywall) — bunlar STANDALONE bir "Zibo Pro"
   girişi DEĞİL, bir özelliğin İÇİNDEKİ kontextual kilit/upsell, bu yüzden
   madde 1'in aksine Ayarlar'dan KALDIRILMADI.

Eskiden (Faz 2 ÖNCESİ) bu giriş noktaları yalnızca tek seferlik reklamsız
paketi satan dar bir bottom sheet'i (`ad_free_promo_sheet.dart`) açıyordu —
o dosya SİLİNDİ, hepsi artık kapsamlı paywall'a yönlendiriyor.

## Pro+ grafik kilidi — `LockedFeatureOverlay` (2026-09-24)

**Kullanıcı isteğiyle GATİNG FELSEFESİ değişti**: Pro+'a özel grafikler
artık `if (isProPlus) ... else gösterme` (tam gizleme) deseniyle DEĞİL,
paylaşılan `lib/widgets/locked_feature_overlay.dart` ile gösteriliyor —
başlık/toggle HER ZAMAN görünür (kullanıcı bölümün var olduğunu ve neyi
kaçırdığını görsün), yalnızca asıl çizim alanı `BackdropFilter`/
`ImageFilter.blur` ile bulanıklaştırılıp üstüne 🔒 rozeti + "Zibo Pro+'a
Bugün Geç" (`l10n.lockedChartCta`) yazısı bindiriliyor, dokununca
`PaywallScreen`'e yönlendiriyor. Veri YOKSA ve kilitliyse (yeni kullanıcı)
bulanıklaştıracak bir şey olsun diye sabit bir ÖRNEK veri seti kullanılıyor
(gerçek veri gibi SUNULMUYOR).

Şu an bu deseni kullanan grafikler: Ruh Hali Trendi (`MoodTrendDetailChart`),
Para & Birikim Gelişmiş Analiz (`money_screen.dart`'taki
`_AdvancedAnalysisSection`), Su Takibi Trendi (`WaterTrendChart`). **Devam
eden "Pro+ analitik/grafik genişletmesi" girişiminin** (aşağıya bkz.) TÜM
yeni grafikleri bu deseni kullanacak — ortak görsel dil olarak sabitlendi.

## Pro+ Analitik/Grafik Genişletmesi (2026-09-24, DEVAM EDİYOR)

Kullanıcının 6 maddelik iri bir istek listesi — adım adım ilerleniyor:

| # | Madde | Durum |
|---|---|---|
| 1 | Ruh Hali grafiğini Profil'den kendi moduluna taşı, haftalık/aylık ortalamaya yeniden tasarla | ✅ Tamamlandı (yukarıdaki D2 satırı) |
| 2 | Para ve Birikim'e çoklu para birimi kartları + kategori pasta grafiği + trend genişletmesi | ✅ Tamamlandı (yukarıdaki D3 satırı) |
| 3 | Su Takibi'ne trend grafiği + hedef oranı özeti | ✅ Tamamlandı (yukarıdaki "Su Takibi trend grafiği" satırı) |
| 4 | Şükran Günlüğü'ne katkı ısı haritası, Hedef Takibi'ne tamamlama/streak çubuk grafiği | ⏳ Bekliyor |
| 5 | Haftalık/Aylık "Zibo Karnesi" özet raporu + paylaşılabilir kart | ⏳ Bekliyor |
| 6 | Ortak grafik tasarım standardı (renk/font/animasyon, boş durum, giriş animasyonu) | 🔶 Kısmen — `LockedFeatureOverlay` (kilit deseni) + `LineChart`'ın "taban çizgisinden dolma" giriş animasyonu (madde 1'de kuruldu) şu ana kadarki ÜÇ grafikte uygulandı, madde 4-5'e de uygulanacak |

## Pro → Pro+ yükseltme mekanizması

Play Billing'in "abonelik değiştirme" akışı (`ChangeSubscriptionParam` +
`ReplacementMode.withTimeProration` — kalan süre orantılı olarak Pro+'a
kredilendirilir). Eski satın almanın token'ı AYRICA saklanmıyor —
`InAppPurchaseAndroidPlatformAddition.queryPastPurchases()` her seferinde
Play'in yerel önbelleğinden taze sorgulanıyor (bkz.
`iap_purchase_service.dart` `upgradeSubscription`/`_findActivePurchase`).
Aylık↔yıllık plan değişimi (AYNI katman içinde) bu fazda YOK — yalnızca
Pro→Pro+ katman yükseltmesi var.

## Mimari notlar / kısıtlar

- **`SubscriptionProvider`** (`lib/providers/subscription_provider.dart`) tek
  kaynak: `tier`, `isPro`, `isProPlus`, `purchase(offer)`,
  `upgradeToProPlus(offer)`. Firestore'da `users/{uid}/state/subscriptionState`
  altında (`subscriptionTier`/`subscriptionExpiryDate`/`subscriptionProductId`).
- **İstemci-yetkili, TAM sunucu doğrulaması YOK** — coin ekonomisiyle
  (`docs/decisions/005`) AYNI mimari kısıt, proje backend'siz (`docs/decisions/002`).
  Detaylı gerekçe → `docs/decisions/012-subscription-tier-tracking.md`.
- **Süre (expiry) "kayan pencere" ile TAHMİN ediliyor** (her başarılı
  satın alma/restore onayında `now + 35 gün`'e uzatılır) — Play Billing'in
  istemci API'si kesin bitiş tarihi VERMİYOR, bkz. karar 012.
- **Debug test paneli** — Ayarlar'ın en altında (`kDebugMode` ile korunan
  `_SubscriptionDebugPanel`), gerçek satın alma yapmadan Free/Pro/Pro+ arası
  geçiş.

## Güncelleme geçmişi

- **2026-09-22 — Faz 1**: `SubscriptionProvider`, Play Console ürün/plan
  kurulumu, `in_app_purchase` abonelik entegrasyonu. Paywall UI YOK.
- **2026-09-22 — Faz 2**: `PaywallScreen`, 4 giriş noktasının tamamının
  yönlendirilmesi, Pro→Pro+ yükseltme akışı, eski `ad_free_promo_sheet.dart`
  silindi.
- **2026-09-23 — Paywall komple yeniden tasarım**: sticker görsel dili,
  Zibo karakteri + dönen teşvik balonu, yan yana Pro/Pro+ kartları,
  karşılaştırma tablosu, giriş/nabız animasyonları. `PaywallScreen` →
  `PaywallContent` (`embedded`) + ince `PaywallScreen` sarmalayıcısına
  ayrıldı. Pro/Pro+ kart yükseklik orantısızlığı düzeltildi (`Row.stretch`
  + kartın içinde `Spacer`).
- **2026-09-23 — Paywall'ı Mağaza'ya taşı**: Ayarlar'ın en üstündeki
  standalone "Zibo Pro" satırı KALDIRILDI, yerine Mağaza'da Coin Al/
  Kostümler/Temalar'ın yanına 4. bir "Zibo Pro" sekmesi eklendi
  (`PaywallContent(embedded: true)` doğrudan gömülü).
- **2026-09-23 — Pro+ bildirim sesleri**: kullanıcının hazırladığı 5 gerçek
  ses dosyası `res/raw/proplus_sound_1..5.mp3` olarak eklendi (artık
  placeholder değil), 2 yeni kanal (4/5) + seçicide dokununca ANINDA
  önizleme (`android.resource://` URI'siyle).
- **2026-09-24 — Pro+ Analitik/Grafik Genişletmesi başladı** (kullanıcının
  6 maddelik iri isteği, adım adım): Ruh Hali trend grafiği Profil'den
  Ruh Hali Takibi'ne taşındı ve haftalık/aylık ORTALAMAYA yeniden tasarlandı
  (madde 1) → Para & Birikim'e çoklu para birimi kartları + harcama donut
  grafiği eklendi (madde 2) → gating deseni "tam gizleme"den paylaşılan
  `LockedFeatureOverlay` (bulanıklaştır + kilit rozeti + paywall
  yönlendirmesi) desenine geçirildi, HER İKİ grafiğe de uygulandı (madde 6,
  kısmen) → Su Takibi'ne Günlük/Haftalık/Aylık trend grafiği + hedef
  tutturma oranı özeti eklendi, AYNI `LockedFeatureOverlay` deseniyle
  (madde 3). Devam ediyor — bkz. yukarıdaki durum tablosu.
