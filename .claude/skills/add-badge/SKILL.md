---
name: add-badge
description: Zibo rozet sistemine yeni bir rozet (veya yeni bir rozet kategorisi) ekler. Kullanıcı "yeni rozet ekle", "şu koşulu sağlayınca rozet versin", "yeni rozet kategorisi" dediğinde kullan. Rozet sistemi 6 kategorili, otomatik tetikleme + konfeti kutlaması + ZC ödülü mimarisine sahip.
---

# Yeni rozet ekleme prosedürü

Tam bağlam: `dijital_kanka/docs/history/badge-system.md`. Mimari özet: `dijital_kanka/docs/ARCHITECTURE.md` §10 civarı + `docs/decisions/009`.

## Mevcut yapı

- 6 kategori: `BadgeCategory` enum (`consistency`/`moduleMastery`/`collection`/`loyalty`/`social`/`hidden`).
- Her kategori: `lib/data/<kategori>_badges.dart` — `List<ZiboBadgeDefinition>`.
- `allBadges` (`lib/data/consistency_badges.dart`'ta) tüm kategori listelerini birleştirir.
- `BadgeProvider.reconcile<Kategori>Badges({...sayaçlar})` — her kategorinin kendi eşik kontrolü, "tek slot, en son yeni kazanılan `pendingBadgePopup`'a yazılır".
- `BadgeCoordinator` ~14 provider'ı dinler, `_reconcile()` TÜM kategorileri art arda çağırır.

## Adımlar (yeni rozet, MEVCUT bir kategoriye)

1. **ID belirle** — kalıcı, `snake_case`, benzersiz (`grep -rn "'yeni_id'" lib/`). Kalıcı contract → `docs/decisions/009`.
2. **`lib/data/<kategori>_badges.dart`** — yeni `ZiboBadgeDefinition(id, imageAsset, ...)`. `zcReward` belirle.
3. **Görsel** — kullanıcının verdiği PNG'yi `assets/images/`'e (`tool/process_<kategori>_badge_images.dart` veya `process_badge_images.dart` ile 512px). **ÖNCE piksel-alfa ile şeffaflık doğrula** (bkz. `tool/CLAUDE.md`).
4. **ARB** — `badgeName<Id>` + `badgeRequirement<Id>` (TR/EN/ES üçü de) → `flutter gen-l10n`. `ZiboBadgeDefinition.localizedName`/`localizedRequirement` switch'lerine `case` ekle.
5. **Eşik mantığı** — `BadgeProvider.reconcile<Kategori>Badges` içine yeni rozetin koşulunu ekle. Yeni bir sayaç gerekiyorsa ilgili provider'a getter ekle (örn. `WaterProvider.totalDaysRecorded`).
6. **Hediye (opsiyonel)** — kostüm/tema hediye edilecekse `lib/data/badge_gift_rewards.dart` map'ine satır (`BadgeGiftReward.costume(id)` / `.theme()`). Bkz. `docs/decisions/009`.
7. **Test** — `test/badge_provider_test.dart`'a `reconcile<Kategori>Badges` grubuna: eşik-altı no-op + yeni rozet için eşik-aşımı + tekrar-bildirmeme + kalıcılık. `test/badges_gallery_screen_test.dart`'taki `allBadges.length` sayımı otomatik güncellenir.

## Adımlar (YENİ kategori)

Yukarıya ek: `BadgeCategory` enum'a değer + yeni `lib/data/<kategori>_badges.dart` + `allBadges`'e
spread + `BadgeProvider.reconcile<YeniKategori>Badges` metodu + `BadgeCoordinator._reconcile()`'a çağrı
+ `BadgeCoordinator`'ın dinlediği provider listesine yeni bağımlılık(lar) + `RootScreen.initState`
kurulum çağrısı + `BadgesGalleryScreen._categoryTitle` switch'ine case + `badgeCategory<X>` ARB.

## Gotcha'lar

- `BadgeCoordinator._reconcile()` en başta `if (!badges.isReady) return;` guard'ı TAŞIR (yoksa `_earned` boşken yanlış "yeni kazanıldı" → popup sonsuz döngü). Yeni kategori eklerken bu guard'ın çalıştığından emin ol.
- Gizli (`hidden`) kategori: `isHidden: true` → galeri kartı kazanılana kadar isim/koşulu "???" gösterir AMA ZC ödül miktarı GÖRÜNÜR.
- `flutter test` + `flutter build apk --debug` ile doğrula. Gerçek cihaz görsel doğrulaması genelde yapılmaz (mantık saf/deterministik) — Ayarlar'daki geçici test paneli KALDIRILDI, `debugGrantRandomBadge()` de silindi.
