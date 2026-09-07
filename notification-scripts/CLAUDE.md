# `notification-scripts/` — Sunucu tarafı zamanlanmış işler

Bağımsız Node.js (CommonJS, Node 20) betikleri. `firebase-admin` ile DOĞRUDAN Firestore okuyup FCM'e
gönderir. **Cloud Functions / Cloud Scheduler / Blaze plan KULLANMAZ** — gerekçe → `docs/decisions/002`
(bkz. `dijital_kanka/docs/`). GitHub Actions cron'larından (`../.github/workflows/*.yml`) çalışır.

## ⚠️ Bu betikler bu makinede ÇALIŞTIRILAMAZ

Node.js/npm bu geliştirme makinesinde YOK. `flutter test` bunları KAPSAMAZ. Değişiklikten sonra:
1. Kod incelemesi + brace/parantez sayımı.
2. Kullanıcı `gh workflow run <workflow>.yml -f dry_run=true` ile elle tetikleyip log'u okur (`gh` de bu makinede yok → kullanıcı yapar veya `git credential fill` + `curl` GitHub REST API).

## Betikler

| Betik | Cron dakikası | Hedef yerel saat(ler) | Ne yapar |
|---|---|---|---|
| `dailyMotivation.js` | `:07` | 9, 12, 16, 20 | `content.js`'ten tekrar-önlemeli rastgele söz (`recentQuoteIndices`, son 20) |
| `streakReminder.js` | `:14` | 21 | Bugün işaretlenmemiş hedef varsa (`users/{uid}/state/goals`) |
| `dailyRewardReminder.js` | `:21` | 18 | Bugün Günlük Giriş Ödülü alınmamışsa |
| `waterReminder.js` | `:49` | 14 | `waterState` var ama bugün yarım/başlanmamışsa |
| `reEngagement.js` | `:42` | 11 | `users/{uid}.lastActiveAt` 2+ gün eski |
| `processReferralRewards.js` | `:28` | (her çalıştırma) | `referralRedemptions` `pending` → her iki tarafa 100 ZC, `dry_run` varsayılan `false` |
| `cleanupStaleAnonymousUsers.js` | yalnızca `workflow_dispatch` | — | 30+ gün terkedilmiş anonim kullanıcıları sil, `dry_run` varsayılan `true`, İKİ AŞAMALI onay |
| `initFounderBadgeCounter.js` | yalnızca `workflow_dispatch` | — | `founderBadgeStatus/status`'u GERÇEK sayıyla seed et, `dry_run` varsayılan `true`, `FORCE` guard'ı |

## `common.js` — paylaşılan yardımcılar

- `initAdmin()` — `FIREBASE_SERVICE_ACCOUNT_JSON` env (GitHub Secret). `db`/`messaging`/`auth` export.
- **Saat dilimi**: `userLocalHour(user, date)` / `userDateKey(user, date)` — `users/{uid}.timeZone` (istemci `touchLastActive()`'te `flutter_timezone` ile yazar) + Node yerleşik `Intl.DateTimeFormat` (DST otomatik). `timeZone` yoksa `Europe/Istanbul` fallback.
- **Catch-up penceresi**: `pendingNotifyHours(user, type, targetHours, now)` + `markNotifyHoursSent(...)` — "şu an TAM hedef saat mi" DEĞİL, "hedef saat(ler) GEÇTİ mi VE bugün bu tür için `users/{uid}.notifyState[type]`'a işlenmedi mi". GitHub'ın cron gecikmelerine karşı dayanıklı. Gerçekten gönderildiğinde DE, altta yatan koşul zaten karşılandığı için gönderim atlandığında DA `markNotifyHoursSent` çağrılır.
- **Dil**: `getLanguageCode(uid)` (`users/{uid}/state/languageCode`, `['tr','en','es']` dışı → `'tr'`) + `content.js` (4 tür × TR/EN/ES). `dailyMotivation`'ın 279 sözlük havuzu `tool/generate_content_js_daily_motivation.dart` ile `zibo_messages.dart`'tan üretilir — elle senkron tutma.
- **Dedup**: `sendToUser` FCM mesajına `messageId` (istemci `messageId?.hashCode` bildirim id'si) + `dedupeByFcmToken(users)` — AYNI `fcmToken`'a sahip birden fazla uid varsa yalnızca `fcmTokenUpdatedAt` EN YENİ olanı tut (terk edilmiş hesap-değişimi uid'leri token'ı yenilemez). İstemci de `signOut()`/`signIn()`'de eski uid'in `fcmToken`'ını `null`'lar.
- `sendToUser` → `android.notification.channelId: 'push_notifications'` + `sound: 'zibo_notification'` (özel ses için — bkz. `dijital_kanka/android/CLAUDE.md` + `docs/decisions/010`).
- `isTypeEnabled(uid, field)` — `users/{uid}/state/pushNotificationState` (Ayarlar kartı kaldırıldı → hep `true`, ama sunucu filtresi HÂLÂ çalışır).

## Cron dakikası KURALI

`.github/workflows/*.yml`'de dakika alanı olarak ASLA `:00/:15/:30/:45` (GitHub'ın "yoğun"
saatleri — gecikme/atlama). Her workflow farklı ve yuvarlak-olmayan bir dakika kullanır (yukarıdaki
tablo). Cron'un kendisi SAATLİK (`X * * * *`), `TARGET_LOCAL_HOURS` filtresi JS tarafında.

## GitHub Secret ön koşulu

`FIREBASE_SERVICE_ACCOUNT_JSON` = Firebase Console > Project settings > Service accounts > Generate
new private key → indirilen JSON'ın TÜM içeriği → GitHub repo > Settings > Secrets > Actions.
