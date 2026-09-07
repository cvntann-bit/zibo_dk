# 009 — Kalıcı ID'ler + rozet hediye contract'ı

## Context
Kostüm, tema, rozet ID'leri hem Firestore'da (`ownedIds`, `badgeState`) hem kod içi `switch`
eşlemelerinde (`localizedName`, `localizedRequirement`) hem `badge_gift_rewards.dart` map'inde
kullanılıyor.

## Decision / Kısıtlar
- **Kostüm ID'leri** (`lib/data/costumes.dart`): `zibo_hippi`, `zibo_sporcu`, `zibo_asker`, `zibo_hoca`, `zibo_punk`, `zibo_rapci`, `zibo_gentleman`, `zibo_samurai`, `zibo_gladyator`, `zibo_korsan`, `zibo_cyborg`, `zibo_astronot`, `zibo_king`, `zibo_zombi`, `zibo_altin`, `zibo_elmas` — DEĞİŞMEZ. Fiyata göre sıralı tanımlı (Mağaza ızgarası listeyi olduğu gibi dolaşır).
- **`founder_badge`** = `costumes.dart`'ta OLMAYAN, satılamayan pseudo-kostüm ID. `CostumeProvider.markOwned('founder_badge')` çalışır (provider satın-alma agnostik). `ownedRealCostumeCount` / `ownsAllCostumes` bunu BİLEREK DIŞLAR (`every((c) => isOwned(c.id))`, sayım DEĞİL — sayım `founder_badge` yüzünden yanlış pozitif verir).
- **Tema ID'leri** (`lib/data/app_themes.dart`): 22 tema. `pickRandomUnownedStandardTheme` yalnızca `!isPremiumAnimated` olanlardan seçer.
- **Rozet ID'leri** (`lib/data/*_badges.dart`): 24 rozet, 6 kategori. `BadgeCategory` enum: `consistency`/`moduleMastery`/`collection`/`loyalty`/`social`/`hidden`. `allBadges` (`consistency_badges.dart`'ta) tüm kategori listelerini birleştirir.
- **`badge_gift_rewards.dart`** — `Map<String, BadgeGiftReward>`, 9 rozet → kostüm/tema hediyesi:
  ```
  iron_will→zibo_sporcu · grateful_heart→zibo_hippi · unyielding→zibo_gladyator
  loyal_friend→zibo_king · anniversary→zibo_altin · ambassador→zibo_hoca
  community_founder→zibo_korsan · first_share→rastgele standart tema · dreamer→rastgele standart tema
  ```
  Bu map elle yazıldı, TÜM badge/costume ID'leri `grep` ile doğrulanarak. Diğer 15 rozet yalnızca ZC ödülü verir. **`full_wardrobe` (Tam Gardırop) hediye VERMEZ** (bir ara verdiriliyordu, kullanıcı exhaustive listede saymadığı için geri alındı — istenirse map'e satır eklemek yeterli).
- **`CoinPackage.id`** (`lib/data/coin_packages.dart`): `coins_100`/`coins_250`/`coins_500`/`coins_1000`/`coins_10000` — Play Console tüketilebilir ürün "Product ID"leriyle BİREBİR eşleşmeli. (Play Console'un ayrı "Satın alma seçeneği kimliği" alanı tire-li — kodda hiç referans edilmez.)

## Yeni bir kostüm/tema/rozet eklerken
1. `lib/data/`'daki ilgili listeye ekle (kostüm fiyat sırasına).
2. `localizedName`/`localizedRequirement` switch'lerine `case` ekle + 3 ARB anahtarı (`badgeName<X>` vb.) + `flutter gen-l10n`.
3. Rozet ise: `BadgeProvider.reconcileXBadges` + `BadgeCoordinator`'ın dinlediği provider listesi.
4. Görsel: `assets/images/` (glob zaten dahil), önce piksel-alfa ölçümüyle şeffaflık doğrula.
5. Daha pahalı bir paket/kostüm/tema ise → `firestore.rules`'taki coin üst sınırlarını güncelle ([005](005-coin-economy-client-authoritative.md)).

## İlgili
`docs/history/badge-system.md` · `docs/history/costumes-poses-themes.md`
