# Zibo Pro / Pro+ Abonelik Modeli

> **Durum:** Faz 1 (altyapı) + Faz 2 (paywall ekranı) tamamlandı. Bu dosya
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
| Check-in coin ödülü 1,5x/2x (B1) | ⏳ Yalnızca paywall'da METİN |
| Şans Çarkı reklamsız + ekstra çevirme (B4) | ⏳ Yalnızca paywall'da METİN |
| Modüllerde sınırsız geçmiş (D1) | ⏳ Yalnızca paywall'da METİN |
| Ayda 1/3 ücretsiz Streak Freeze | ⏳ Yalnızca paywall'da METİN |
| Diğer Pro+'a özel perk'ler (kostüm/tema, profil rozeti, filigran, trend grafiği, Para&Birikim analizi, bildirim sesi) | ⏳ Yalnızca paywall'da METİN |

## Paywall ekranı (`lib/screens/paywall_screen.dart`)

3 seçenek TEK ekranda: Tek Seferlik Reklamsız + Zibo Pro + Zibo Pro+, üstte
Aylık/Yıllık geçiş anahtarı. Kullanıcı zaten Pro/Pro+ ise:
- **Tek Seferlik Reklamsız kart GİZLİ** (Pro zaten reklamları kaldırıyor).
- **Pro kartı**: kullanıcı Pro ise "Mevcut Planın" rozeti; Pro+ ise "Zaten
  Pro+ Kullanıcısısın" rozeti (satın alma butonu YOK).
- **Pro+ kartı**: kullanıcı Pro ise buton "Pro+'a Yükselt"e döner (gerçek
  Play Billing "abonelik değiştirme" akışı — aşağıya bkz.); Pro+ ise "Zaten
  Pro+ Kullanıcısısın" rozeti.

Görsel parçalar (`_PaywallHeaderBanner`, `_PlanCard`, `_PerkRow`) BİLEREK
küçük, ayrı private widget'lara bölündü — ileride yalnızca görsel/asset
değişikliği (kullanıcı isteği) tek bir widget'ı düzenlemek kadar kolay olsun
diye.

### Giriş noktaları (hepsi AYNI `PaywallScreen`'i açar)

1. **Ayarlar** — en üstte, kendi "Zibo Pro" satırı (`settings_screen.dart`).
2. **Ana Sayfa'da Zibo'ya art arda 5 hızlı dokunma** — %25 ihtimalle (bkz.
   `home_screen.dart` `_showRapidTapPromoOrAd`).
3. **Mağaza'daki kalıcı "Reklamsız Zibo" kartı** (`store_screen.dart`
   `_AdFreeCard`) — her zaman ekranda durur.
4. **Mağaza'ya periyodik ziyaret promosu** (`AdFreePromoTrigger` — her 5.
   ziyaret + 3 günlük cooldown, `store_screen.dart`
   `_maybeShowAdFreePromo`).

Eskiden (Faz 2 ÖNCESİ) bu 4 giriş noktası yalnızca tek seferlik reklamsız
paketi satan dar bir bottom sheet'i (`ad_free_promo_sheet.dart`) açıyordu —
o dosya SİLİNDİ, hepsi artık kapsamlı paywall'a yönlendiriyor.

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
