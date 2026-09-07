# 007 — Tek reklam ağı değil Appodeal mediation

## Context
Uygulama başlangıçta gerçek Google AdMob SDK'sıyla entegre edildi. **AdMob hesabı Google
tarafından devre dışı bırakıldı** ("ilişkili/mükerrer hesap" — kullanıcı hem kurumsal hem kişisel
e-postayla kayıt olmuştu; ayrıca geliştirme sırasında gerçek reklam birimiyle test edip ~birkaç TL
gelir oluşturmuştu). İtiraz gönderildi, sonuç belirsiz.

## Decision
`google_mobile_ads` paketi TAMAMEN kaldırıldı. `stack_appodeal_flutter` (Appodeal'in resmi paketi)
ile mediation platformuna geçildi. `AdMobConfig`/`admob_ad_service.dart` silindi, yerine
`AppodealConfig` (tek App Key) + `AppodealAdService`.

## Neden
- Mediation platformu tek bir ağa bağımlı değil — bir ağın hesap yasaklaması gelir akışını TAMAMEN durdurmuyor. Tam da AdMob banının yarattığı riski hedefliyor.
- `AdService` soyutlaması sayesinde geçiş = TEK bir servis sınıfı + `main.dart`'ta tek satır. `CoinProvider` / Mağaza / Şans Çarkı / Ana Sayfa / Günlük Ödüller — çağıran kodun HİÇBİR satırı değişmedi.
- **Kalıcı ders**: geliştirme/test sırasında ASLA gerçek Ad Unit ID kullanma — HER ZAMAN test ID'sine düş. `Appodeal.setTesting(kDebugMode)` bunu debug build'lerde garantiliyor.

## Sonuçlar / Kısıtlar
- Appodeal callback'leri SDK-seviyesinde GLOBAL (her `show()` çağrısına özel değil) → `AppodealAdService` bir `Completer<bool>` köprüsü kullanır.
- `Appodeal.initialize()` Dart API'si HİÇBİR ŞEY döndürmüyor — `await` edilemez, `main()`'de fire-and-forget.
- Ön-yükleme YOK — SDK sürekli arka planda yükler; `_waitUntilLoaded` yalnızca `Appodeal.isLoaded()`'ı polling ile sorar (8sn timeout).
- `android/app/build.gradle.kts`'te yalnızca Appodeal core + IAB adaptörü var. AdMob DAHİL başka ağ eklenmedi. Unity Ads adaptörü eklendi ama Appodeal Console'da "Store URL required" (Play'de yayında olunca 24 saatte otomatik doğrulanır) yüzünden OFF.
- Appodeal S2S reward callback (sunucu-taraflı ödül doğrulama) KURULMADI — [002](002-no-cloud-functions.md)/[005](005-coin-economy-client-authoritative.md) ile aynı backend kararına bağlı.
- **AdMob'a geri dönmek gerekirse** (itiraz kabul edilirse, mediation ağı olarak): tek bir servis sınıfı + `main.dart` bağlaması + `build.gradle.kts` adaptörü. `CoinProvider`/ekranlar değişmez.

## İlgili
`docs/history/ads-monetization-appodeal.md`
