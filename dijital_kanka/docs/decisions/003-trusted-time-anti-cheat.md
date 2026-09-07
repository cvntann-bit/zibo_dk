# 003 — `TrustedTimeProvider`: cihaz saati değil doğrulanmış ağ zamanı

## Context
Günlük Giriş Ödülleri, Hedef Takibi döngüleri, Şükran/Su Takibi günlük ödülleri, streak/rozet zaman
pencereleri — hepsi "bugün hangi gün" sorusuna bağlı. Kullanıcı telefonun tarihini ileri alarak
günlük ödülleri tekrar tekrar tetikleyebilirdi.

## Decision
`lib/providers/trusted_time_provider.dart` — `now()`:
- Bir ağ doğrulaması **BU OTURUMDA** tamamlandıysa (`_verifiedThisSession == true`) → `verifiedUtc + _stopwatch.elapsed`. `Stopwatch` donanım saatine dayalı → cihaz TARİH ayarından bağımsız (ileri/geri fark etmez).
- Aksi halde → cihaz saatine güvenle düşer (yalnızca ilk doğrulama tamamlanana kadarki kısa bootstrap penceresi).

Zaman kaynağı: `uid != null` → `CompositeTrustedTimeService([FirestoreTrustedTimeService, HttpDateTrustedTimeService])` (Firestore `_serverTime/ping` `serverTimestamp()` yaz-oku, o başarısızsa HTTP `Date`). `uid == null` → yalnızca HTTP `Date`.

## Neden
- İlk (hatalı) tasarım "cihaz saati taban değerden büyükse kabul et" idi — bu yalnızca GERİYE alınan saate karşı koruyordu, İLERİYE alınana karşı hiç işe yaramıyordu (kullanıcı saati ileri alınca `deviceUtc` HER ZAMAN tabanın ilerisinde sayılıyordu).
- İkinci bir gerçek bug: `_lastVerifiedUtc` kalıcı depodan yüklenince kod bunu "bu oturumda doğrulandı" sanıyordu → ağ kalıcı olarak başarısızsa `now()` GÜNLERCE dondurulmuş eski bir tarihte kalabiliyordu (`todayIndex` asla ilerlemiyordu). `_verifiedThisSession` guard'ı bunu çözdü.

## Sonuçlar / Kısıtlar
- Kullanıcı verisi taşıyan TÜM "güne bağlı" provider'lar `now: () => context.read<TrustedTimeProvider>().now()` ile enjekte edilmeli. Yeni bir güne-bağlı ödül/streak mekaniği eklerken bu deseni kullan.
- **İSTİSNA — kozmetik/eğlence özellikler cihaz saatini KULLANIR (bilinçli):**
  - `motivation_quote_selector.dart` `timeBucketFor(DateTime)` — sabah/öğle/akşam/gece sözü. Kullanıcı farklı saat dilimine seyahat ederse doğrulanmış-UTC-çıpa yeni yerel saate uymayabilir; bu özellik kullanıcının O ANKİ gerçek yerel saatini yansıtmalı.
  - `HiddenBadgeProvider` (Gece Kuşu 00:00–05:00, Erken Kuş 06:00–08:00 rozetleri) — kullanıcı "cihaz saatine göre" dedi. Kabul edilen ödünleşim: cihaz saati manipülasyonuyla erken kazanılabilir (griefing, gerçek ekonomi kaybı değil).
- "Taban/floor" karşılaştırmalarında hangi YÖNDEKİ sapmaya karşı korunmak istediğini açıkça düşün — simetrik bir kural yalnızca tek yönlü saldırıya karşı doğrudur.

## İlgili
`docs/history/backend-auth-security-referral.md` · `docs/history/push-notifications-sounds.md`
