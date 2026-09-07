# 002 — Cloud Functions YOK; zamanlanmış işler GitHub Actions ile

## Context
Push bildirimleri, terkedilmiş anonim kullanıcı temizliği, referral ödül işleme, Kurucu Üye sayacı
seed — hepsi bir "sunucu tarafı zamanlanmış çalıştırma" gerektiriyor. İlk tasarım Cloud Functions v2
(`onSchedule`) idi.

## Decision
Cloud Functions / Cloud Scheduler KULLANILMIYOR. Bunun yerine:
- `notification-scripts/` (repo kökünde) — bağımsız Node.js betikleri, `firebase-admin` ile.
- `.github/workflows/*.yml` — her biri `schedule:` (cron) + `workflow_dispatch:` tetikleyicili.
- GitHub Secret `FIREBASE_SERVICE_ACCOUNT_JSON` ile Admin SDK kimlik doğrulaması.

## Neden
- **Cloud Functions/Scheduler Blaze (faturalandırma) planı gerektiriyor.** Kullanıcı Blaze'e geçmek istemiyor.
- **Firestore okuma/yazma VE FCM gönderimi Spark (ücretsiz) planda tam çalışır** — yalnızca Functions/Scheduler'ın KENDİSİ Blaze istiyordu.
- GitHub Actions ücretsiz dakika kotası bu küçük, saniyeler süren işler için fazlasıyla yeterli.

## Sonuçlar / Kısıtlar
- **GitHub Actions cron'u güvenilmez.** `:00/:15/:30/:45` dakikaları GitHub'ın "yoğun" saatleri → tetiklemeler gecikir/atlanır. KURAL: dakika alanı olarak ASLA yuvarlak değer kullanma, `:07`/`:14`/`:21` gibi seç. Her betik `pendingNotifyHours`/`markNotifyHoursSent` catch-up penceresi taşır (gecikmiş tetikleme gün içindeki sonraki çalıştırmada yakalanır).
- **Node.js bu geliştirme makinesinde YOK** → betikler yalnızca kod incelemesiyle doğrulanabiliyor, `flutter test` onları kapsamıyor. Değişiklikten sonra kullanıcı `gh workflow run ... -f dry_run=true` ile elle doğrulamalı.
- Saatlik çalıştırma `fetchAllUsers()` (tüm koleksiyon okuma) sıklığını artırdı — kapalı test ölçeğinde Spark kotasının çok altında. Binlerce kullanıcıya çıkılırsa `targetHourBucket` alanına göre Firestore query'sine geçilmeli.
- **Gerçek/tam coin güvenliği, IAP makbuz doğrulaması** — bunlar da bir backend gerektiriyor ve AYNI Blaze kararına bağlı. Launch öncesi kullanıcının kararı gerekiyor.
- `initFounderBadgeCounter.js` gibi production'a yazan betikleri `dry_run: false` ile çalıştırmak asistanın izin sınıflandırıcısı tarafından ENGELLENİR — kullanıcı GitHub Actions sekmesinden elle yapar.

## İlgili
`notification-scripts/CLAUDE.md` · `docs/history/push-notifications-sounds.md`
