# `lib/providers/` — Provider kuralları

Bu proje `provider` paketi kullanır. ~40 `ChangeNotifier`, `main.dart`'ta `MultiProvider` ile bağlı.

## Kalıcılık: `CloudStateStore`

Her kullanıcı-verisi provider'ı `lib/services/cloud_state_store.dart` üzerinden hem `SharedPreferences`
hem Firestore'a (`users/{uid}/state/{prefsKey}`) senkron. Ayrıntı → `docs/decisions/001-firestore-cloudstatestore.md`.

- Constructor `uid`'i OPSİYONEL alır (varsayılan `null`). `uid == null` → saf yerel (test / Firebase yok).
- Constructor enjekte edilebilir `firestore` de alabilir (`fake_cloud_firestore` ile test).
- Güne-bağlı provider'lar (`GoalsProvider`, `DailyRewardsProvider`, `WaterProvider`, `GratitudeProvider`, `MoodProvider`, `AppStreakProvider`, `CoinProvider` günlük sınırlar, `ProfileStatsArchiveProvider`) enjekte edilebilir `now: DateTime Function()` alır — `main.dart`'ta `() => context.read<TrustedTimeProvider>().now()` (güvenlik). Bkz. `docs/decisions/003-trusted-time-anti-cheat.md`.
- **İstisna** — `HiddenBadgeProvider` BİLEREK `now:` almaz (cihaz saati; Gece/Erken Kuş rozetleri).

## Yeni bir `required` alan eklerken (model göçü)

"Oku-zamanı-göç-et": `_entryFromJson` / `_loadFromPrefs` eski (alansız) kayıtlara güvenli bir
varsayılan atar, bir sonraki `_save()`'de kalıcı olur. Ayrı migrasyon betiği YAZMA. Örnekler:
`MoneyEntry.date` (→ `_now()`), `MoneyEntry.currencyCode` (→ `'TRY'`), `AppStreakProvider.totalDaysOpened` (→ `currentStreak`).

## `notifyListeners()` disiplini

Dışarıdan çağrılan bir "reconcile / senkronize et" metodu, SONUCU DEĞİŞTİRMESE BİLE
`notifyListeners()` çağırmalı. `IndexedStack`'te sürekli monte kalan widget'lar (özellikle
`DailyRewardsTriggerButton` gibi trigger butonları) aksi halde SESSİZCE eski durumu göstermeye
devam eder. Maliyeti neredeyse sıfır (gereksiz bir rebuild), atlaması kullanıcının fark ettiği
"takılı kalma" hissi yaratır.

## `_AppStartupGate` (splash kapısı)

YEDİ provider `isReady == true` olana kadar uygulama `AppLoadingScreen` gösterir:
`ThemeProvider`, `AppThemeProvider`, `LocaleProvider`, `CoinProvider`, `CostumeProvider`,
`OnboardingProvider`, `ProfileProvider`. **Bu kapıya sekizinci bir provider eklersen** `main.dart`'taki
`_AppStartupGate.build()`'e bir `context.watch<X>()` daha ekle (`ConsumerN` sugar'ı 6'da bitiyor).
`isReady`, `_loadFromPrefs()`'in HER çıkış yolunda koşulsuz `true` yapılmalı.

`ProfileProvider` bu kapıya SONRADAN eklendi — tembel `create` yüzünden Onboarding'in `setName()`
çağrısıyla asenkron `_loadFromPrefs()` arasında bir yarış vardı (kullanıcının yazdığı ismi sessizce
siliyordu). Yeni bir provider'ın "ilk erişimi" bir kullanıcı akışında oluyorsa aynı yarışa dikkat.

## `BadgeCoordinator` / diğer koordinatörler

`HomeWidgetSyncCoordinator`, `BadgeCoordinator` — provider'ları CONSTRUCTOR'dan DEĞİL parametre
olarak alır, dışarıdan `addListener` ekler (kalıcı bağımlı değil). `RootScreen.initState`'in
`addPostFrameCallback`'inde kurulur (gövdede senkron çağrı "setState during build" çökmesi verir).
`BadgeCoordinator._reconcile()` en başta `if (!badges.isReady) return;` guard'ı taşır (yoksa
`_earned` boşken yanlış "yeni kazanıldı" üretip popup'ı sonsuza dek tetikler) + `badges`'i de dinler.

## Test: `_buildAppWithClock()` provider listesi

`widget_test.dart`'ın `_buildAppWithClock()` yardımcısı `RootScreen`'in ihtiyaç duyduğu HER
provider'ı içermeli. `main.dart`'a (veya `RootScreen`'in `context.read` ettiği kümeye) yeni bir
provider eklersen bu yardımcıyı GÜNCELLE — yoksa `ProviderNotFoundException` yalnızca ilgili testte
değil ondan SONRAKİ TÜM testlerde kademeli olarak görünür. Detay → `test/CLAUDE.md`.
