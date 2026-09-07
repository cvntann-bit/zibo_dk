# ARŞİV — FCM Push + GitHub Actions, Anonim Auth temizliği, Bildirim/Dokunma sesleri

> Bu dosya eski `CLAUDE.md`'nin ilgili bölümlerinin BİREBİR kopyasıdır (satır 3747–4664).
> Yalnızca gerektiğinde okunur — bkz. `docs/history/README.md`. Otomatik context'e YÜKLENMEZ.

## Push Bildirimleri — FCM + GitHub Actions ([push_notification_type.dart](lib/models/push_notification_type.dart), [push_notification_provider.dart](lib/providers/push_notification_provider.dart), [push_notification_service.dart](lib/services/push_notification_service.dart), workspace kökü [notification-scripts/](../notification-scripts/) + [.github/workflows/](../.github/workflows/))

- **2026 yeni özellik — eski yerel bildirim sisteminden (bkz. "Bildirimler" bölümü, hâlâ rafta,
  `notificationsFeatureEnabled = false`) TAMAMEN BAĞIMSIZ, sunucu taraflı bir push sistemi.**
  Kullanıcı isteği dört bildirim türü: Günlük Motivasyon, Streak Hatırlatması, Günlük Ödül
  Hatırlatması, Geri Kazanma — Cloud Functions + Cloud Scheduler ile (GitHub Actions DEĞİL, zaten
  Firebase ekosistemindeyiz).
- **İstemci tarafı (Flutter) — "alma" mantığı:**
  - `PushNotificationType` enum — 4 tür, her birinin `wireValue`'su (`daily_motivation`/
    `streak_reminder`/`daily_reward`/`re_engagement`) Cloud Functions'ın gönderdiği
    `RemoteMessage.data['type']` ile birebir eşleşiyor.
  - `PushNotificationProvider` — `CloudStateStore` Varyant A (`pushNotificationState` doküman,
    4 bool tercih). **2026 güncellemesi — Ayarlar'daki "Push Bildirimleri" kartı (4 `SwitchListTile`)
    KULLANICI İSTEĞİYLE TAMAMEN KALDIRILDI** ("bu gereksiz bir ayrım" — kullanıcının kendi ifadesi;
    `settings_screen.dart`'taki `_PushNotificationSettingsCard` sınıfı SİLİNDİ, `PushNotificationProvider`/
    `PushNotificationType` importları kullanılmadığı için kaldırıldı). **Provider'ın kendisi VE
    sunucu tarafı filtreleme mantığı DOKUNULMADAN kaldı** — yalnızca kullanıcının bunu Ayarlar'dan
    tek tek kapatabildiği arayüz gitti. Bunun PRATİK SONUCU: `PushNotificationProvider`'ın 4 alanı
    da varsayılan `true` olarak kalıcı depoda takılı kalır (hiçbir kullanıcı arayüzden değiştiremez),
    yani **tüm kullanıcılar artık fiilen dört bildirim türünün TAMAMINI alır, hiçbir opt-out yolu
    YOK** (sistem düzeyinde OS'un kendi bildirim izni HARİÇ). Bu, kullanıcının açık isteğiydi ("türlere
    göre ayrı seçenek gerekmiyor" gerekçesiyle) — provider/backend kodu SİLİNMEDİ ki ileride tekrar
    bir arayüz eklenmek istenirse (ör. tek bir genel "bildirimleri kapat" anahtarı) `isEnabled`/
    `setEnabled` API'si hâlâ hazır dursun.
    Eskiden kullanıcı bir türü kapatırsa Cloud Functions/betik tarafı bunu (aşağıdaki `isTypeEnabled`
    kontrolü ile) okuyup o türü GÖNDERMİYORDU — istemci tarafında bir "bastırma" mantığı YOK,
    filtreleme SUNUCUDA; bu mekanizma HÂLÂ ÇALIŞIR durumda, yalnızca artık hiçbir kullanıcı `false`
    değerine ERİŞEMEDİĞİ için pratikte hep `true` okunuyor.
  - `PushNotificationService` (`AdService`/`NotificationService` ile AYNI gerçek+fake desen) —
    `FirebaseMessagingPushNotificationService.initialize()`: izin ister, FCM token'ı alıp
    `users/{uid}.fcmToken`/`fcmTokenUpdatedAt`'e yazar (`onTokenRefresh` ile de senkron tutar),
    `FirebaseMessaging.onMessage`/`onMessageOpenedApp`/`getInitialMessage()`'ı bağlar.
    `touchLastActive(uid)` → `users/{uid}.lastActiveAt` — Geri Kazanma fonksiyonunun "kaç gündür
    açılmadı" kontrolü için TEK veri kaynağı, `RootScreen`'in `didChangeAppLifecycleState`'inde
    (`resumed`) her öne gelişte tazeleniyor.
  - **`FirebaseMessaging.onMessage` foreground'da OS bildirimini OTOMATİK GÖSTERMEZ** — bu yüzden
    `NotificationService.showNow({title, body})` (YENİ metot, `LocalNotificationService`/
    `FakeNotificationService`'e eklendi) `PushNotificationService` tarafından çağrılıp uygulama
    açıkken gelen mesajı elle bir yerel bildirim olarak gösteriyor.
  - **`firebaseMessagingBackgroundHandler`** (top-level, `@pragma('vm:entry-point')`) `main()`'de
    `Firebase.initializeApp()`'ten HEMEN SONRA, `runApp`'tan ÖNCE kaydediliyor — gövdesi no-op
    (`notification` alanlı mesajlar OS tarafından uygulama arka plandayken/kapalıyken otomatik
    gösteriliyor, handler'ın yalnızca KAYITLI OLMASI güvenilir Android teslimatı için yeterli).
  - **Bildirime dokununca yönlendirme:** `goalsTabRequest`/`dailyRewardsPopupRequest` (YENİ,
    `homeTabRequest` ile AYNI `ValueNotifier<int>` deseni, `tab_navigation.dart`) —
    `RootScreen._handlePushNotificationTap(type)` türe göre `homeTabRequest`/`goalsTabRequest`'i
    artırıyor veya `DailyRewardsScreen` dialogunu açıyor.
  - **`RootScreen`'in `uid`'e erişimi `context.read<String?>()` ile, constructor parametresi
    DEĞİL** — bkz. `main.dart`'taki kritik `MaterialApp.home` const-kimlik notu (altta).
- **Sunucu tarafı — 2026 GÜNCELLEMESİ: Cloud Functions/Cloud Scheduler DEĞİL, GitHub Actions.**
  İlk tasarım Cloud Functions v2 (`onSchedule`) kullanıyordu, ama bu **Blaze (ücretli) plana
  geçiş gerektiriyordu** — kullanıcı şimdilik Blaze'e geçmek istemediği için mimari tamamen
  GitHub Actions cron'larına taşındı. **Firestore okuma/yazma VE FCM gönderimi Spark (ücretsiz)
  planda da tam çalışır** — yalnızca Cloud Functions/Cloud Scheduler'ın KENDİSİ Blaze
  gerektiriyordu, bu ihtiyaç artık YOK. Eski `functions/` (Cloud Functions) projesi tamamen
  SİLİNDİ, yerine workspace kökünde (`Zibo DK/`, `dijital_kanka/`'ın DIŞINDA — Cloud Functions'la
  aynı "proje bazlı" konum kararı) **`notification-scripts/`** (bağımsız Node.js betikleri) ve
  **`.github/workflows/`** (4 ayrı cron workflow'u) geldi.
  - **`notification-scripts/src/common.js`** — paylaşılan yardımcılar: `firebase-admin`'i
    `FIREBASE_SERVICE_ACCOUNT_JSON` ortam değişkenindeki (GitHub Secret'tan gelen) JSON ile
    başlatan `initAdmin()`, `fetchAllUsers()` (`users` koleksiyonunun tamamı), `isTypeEnabled
    (uid, field)` (`users/{uid}/state/pushNotificationState`'i okuyup kullanıcının o türü AÇIK
    bıraktığını doğrular — doküman/alan yoksa varsayılan `true`, istemcideki
    `PushNotificationProvider` varsayılanıyla AYNI), `sendToUser(user, type, title, body)`
    (`isTypeEnabled` kontrolünden geçerse `messaging.send(...)`, token geçersizse/eskimişse
    hatayı yutup loglar — tek kullanıcının başarısızlığı `Promise.all` batch'ini durdurmasın diye),
    `istanbulDateKey`/`istanbulMinutesOfDay` (aşağıya bakın).
  - **5 betik** (`src/dailyMotivation.js`, `src/streakReminder.js`, `src/dailyRewardReminder.js`,
    `src/reEngagement.js`, `src/waterReminder.js`) — mantık Cloud Functions taslağıyla BİREBİR AYNI,
    yalnızca "ne zaman çalıştırıldıkları" artık `onSchedule` yerine GitHub Actions `schedule:` cron'u:
    - **Günlük Motivasyon** — **2026 GÜNCELLEMESİ — GERÇEK BİR OLAYLA BULUNAN, MİMARİYİ DEĞİŞTİREN
      bir GitHub Actions kısıtlaması:** İlk tasarım, GitHub Actions cron'unun (Cloud Scheduler
      gibi) "rastgele saat" desteklememesi yüzünden, "her kullanıcıya günde 1 kez, 09:00-11:00
      arası RASTGELE bir saatte" isteğini `pickSlot(uid, dateKey, 8)` hash'iyle karşılıyordu:
      workflow 09:00-10:45 (Europe/Istanbul) arası 15 dakikada bir (`cron: '0,15,30,45 6-7 * * *'`,
      8 tetikleme) çalışıp her seferinde yalnızca o anki dilime denk gelen kullanıcılara gönderim
      yapıyordu. **Kullanıcı gerçek bir çalıştırmadan sonra bildirim gelmediğini bildirdi — GitHub
      Actions'ın run geçmişi incelenince şu bulundu:** o gün planlanan 8 tetiklemeden GitHub
      yalnızca **1'ini** gerçekleştirdi, o da **22 dakika GECİKMEYLE** (`minutesOfDay=667` yani
      11:07 Istanbul, 09:00-10:45 penceresinin TAMAMEN DIŞINDA) — script'in kendi pencere
      koruması bu geç çalıştırmayı görüp `"Pencere dışı (minutesOfDay=667), gönderim yapılmadı."`
      diyerek HİÇBİR kullanıcıya gönderim yapmadan sessizce sonlandı (log, `GET /repos/{owner}/
      {repo}/actions/jobs/{job_id}/logs` API'siyle doğrulandı). **Kök neden — GitHub'ın kendi
      dokümantasyonu:** "The schedule event can be delayed during periods of high loads... High
      load times include the start of every hour" — cron'umuzun kullandığı `:00/:15/:30/:45`
      dakikaları TAM OLARAK GitHub'ın "yoğun" dediği anlar, ve saatte birden fazla (8 kez/2 saat)
      sık bir cron bu yoğunlukta GÜVENİLİR ÇALIŞMIYOR (7/8 tetikleme hiç gerçekleşmedi).
      **Düzeltme — mimari basitleştirildi:** `pickSlot` TAMAMEN kaldırıldı (`common.js`'den de
      silindi); GÜNDE TEK bir tetikleme kondu, `cron: '7 6 * * *'` (09:07 Europe/Istanbul) —
      dakika BİLEREK `:07` (GitHub'ın "yoğun" dediği dakikaların DIŞINDA). Betik TÜM
      kullanıcılara AYNI çalıştırmada, AYNI rastgele seçilmiş sözle gönderiyor (kullanıcıya göre
      FARKLI dakika nüansı feda edildi) — sıkı 15dk'lık pencere kontrolü de kaldırılıp yerine
      yalnızca GitHub'ın çalıştırmayı KATASTROFİK derecede geç tetiklemesine karşı geniş bir
      güvenlik ağı (`SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE`, `dailyMotivation.js`) kondu. **Ders
      — genel kural bu betiklerin HEPSİNE uygulandı:** GitHub Actions cron'larında dakika alanı
      olarak ASLA `:00/:15/:30/:45` kullanmayın, bunun yerine `:07` gibi sıra dışı bir dakika
      seçin — sıklık değil, DAKİKA SEÇİMİ asıl risk faktörü.
      - **2026 İKİNCİ güncelleme — kullanıcı isteğiyle günde 1 → 4 tetiklemeye çıkarıldı.**
        Kullanıcı raporu: sabah 11'de gelen tek motivasyon sözü yetersiz geldi, günde 3-4 kez
        istendi. Yukarıdaki dersten (SIKLIK değil DAKİKA SEÇİMİ asıl risk) hareketle, `pickSlot`
        tarzı "kullanıcıya göre farklı dakika" karmaşıklığına GERİ DÖNÜLMEDİ — bunun yerine DÖRT
        BAĞIMSIZ, birbirinden habersiz basit çalıştırma eklendi, HER BİRİ kendi sabit ve
        yoğun-olmayan dakikasında: `7 6 * * *` (09:07), `22 9 * * *` (12:22), `37 13 * * *`
        (16:37), `52 17 * * *` (20:52) — hepsi Europe/Istanbul. Her çalıştırma TÜM kullanıcılara
        kendi rastgele seçtiği sözle gönderiyor, yani bir kullanıcı günde 4 FARKLI söz alıyor.
        `SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE` de dört tetiklemenin hepsini kapsayacak şekilde
        07:00-23:00'e genişletildi (eskiden yalnızca 07:00-13:00'ü kapsıyordu, tek tetikleme
        olduğu için yeterliydi).
    - **Streak Hatırlatması** — `7 17 * * *` (UTC) ≈ 20:00 Istanbul. `users/{uid}/state/goals`'u
      okuyup en az bir hedefin bugün işaretlenmediğini kontrol ediyor; hiç hedef yoksa göndermiyor.
    - **Günlük Ödül Hatırlatması** — `7 12 * * *` (UTC) ≈ 15:00 Istanbul. **BİLİNEN SINIRLAMA
      (kullanıcıya açıkça belirtildi):** Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
      mi" alanı YOK (bkz. "Şans Çarkı" bölümü), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
      claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.
    - **Su Hatırlatması (2026 yeni özellik)** — `7 13 * * *` (UTC) ≈ 16:07 Istanbul.
      `users/{uid}/state/waterState`'i (bkz. `water_provider.dart`) okuyup bugüne ait bir `entries`
      kaydı YOKSA (hiç başlanmamış) veya varsa ama `unitCount < goalUnitCount`'sa (yarım kalmış)
      gönderiyor; `waterState` dokümanı hiç yoksa (kullanıcı su takibini hiç kullanmamışsa)
      `streakReminder.js`'in "hiç hedef yoksa gönderme" deseniyle AYNI gerekçeyle HİÇ göndermiyor
      (kullanılmayan bir özelliği push ile "reklamını yapmak" yerine yalnızca zaten kullanan
      kullanıcılara hatırlatma). Mesaj: "Suyunu içtin mi kanka? Hemen bir bardak iç, hedefine bir
      adım daha yaklaş! 💧" (TR/EN/ES, `content.js`).
    - **Geri Kazanma** — `7 8 * * *` (UTC) ≈ 11:00 Istanbul. `users/{uid}.lastActiveAt` 2 günden
      eski olan kullanıcılara gönderiyor.
    - GitHub Actions cron'ları HER ZAMAN UTC'dir — Europe/Istanbul (sabit UTC+3) karşılıkları her
      workflow dosyasının yorumunda AÇIKÇA yazılı, ileride saat değiştirmek isteyen biri yeniden
      hesaplamak zorunda kalmasın diye.
    - **GitHub Actions run/job loglarını sorgulama tarifi (bu bulguyu çıkarmak için kullanıldı,
      `gh` CLI bu ortamda YOK):** `git credential fill` ile (zaten `git push` için depolanmış)
      GitHub token'ını alıp `curl -H "Authorization: token $TOKEN"` ile REST API'ye istek atmak —
      `GET /repos/{owner}/{repo}/actions/workflows/{id}/runs` (run listesi + `created_at`) →
      `GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs` (job id) → `GET /repos/{owner}/{repo}/
      actions/jobs/{job_id}/logs` (ham log metni). Token asla ekrana yazdırılmadan tek bir
      alt-shell içinde `eval "$(... | sed -n 's/^password=/GH_TOKEN=/p')"` ile ortam değişkenine
      alınıp kullanıldı.
  - **`.github/workflows/*.yml`** (4 dosya) — her biri `schedule:` (cron) + `workflow_dispatch:`
    (elle manuel tetikleme, ilk kurulum testinde kullanılacak) tetikleyicisiyle: `actions/checkout`
    → `actions/setup-node@v4` (Node 20) → `npm install` (`notification-scripts/` içinde,
    `working-directory` ile) → ilgili `npm run <script>` komutu, `FIREBASE_SERVICE_ACCOUNT_JSON`
    GitHub Secret'ını ortam değişkeni olarak geçirerek.
  - **Bu ortamda Node.js/npm/GitHub CLI YOK** — betikler dikkatle elle yazıldı ama YEREL OLARAK
    ÇALIŞTIRILIP TEST EDİLEMEDİ. `workflow_dispatch` sayesinde kullanıcı ilk kurulumdan sonra her
    workflow'u GitHub Actions sekmesinden ELLE bir kez tetikleyip loglardan doğrulayabilir (bkz.
    altta "Kullanıcının tamamlaması gereken adımlar").
- **2026 GÜNCELLEMESİ — bildirimler artık kullanıcının arayüz diline göre gönderiliyor (TR/EN/ES),
  eskiden HER ZAMAN Türkçe gidiyordu.** Kullanıcı raporu (verbatim özet): "admoba geçmeden önce
  bildirimler sadece Türkçe gidiyor, yabancı biri (ör. İspanyolca) kullanıyorsa bildirimler de o
  dilde gitmeli." İnceleme sonucu kök neden doğrulandı: `dailyMotivation.js` TEK bir Türkçe
  `MOTIVATION_QUOTES` dizisinden TÜM kullanıcılara aynı sözü gönderiyordu, `streakReminder.js`/
  `dailyRewardReminder.js`/`reEngagement.js` üçü de `sendToUser(...)`'a doğrudan sabit bir Türkçe
  string literal geçiriyordu — DÖRDÜNDE de hiçbir dil-farkındalığı YOKTU.
  - **`common.js`'e YENİ `getLanguageCode(uid)` eklendi** — istemcideki `LocaleProvider`'ın AYNI
    şemasını okuyor (`users/{uid}/state/languageCode` dokümanı, `value` alanı,
    `['tr','en','es']` dışında/eksik/hatalıysa varsayılan `'tr'` — istemcinin kendi varsayılanıyla
    BİREBİR aynı). `db` çağrısı `isTypeEnabled`'daki AYNI desende try/catch'e sarılı — Firestore
    hatası/ağ sorunu olursa sessizce `'tr'`'ye düşer, tüm çalıştırmayı bozmaz.
  - **YENİ `notification-scripts/src/content.js`** — 4 türün TR/EN/ES içeriğini TEK yerde
    toplayan bir modül (Günlük Motivasyon: 8'er söz/dil; diğer üçü: tek body string/dil).
    Çeviriler `lib/data/zibo_messages.dart`'taki AYNI felsefeyle (birebir çeviri değil, Zibo'nun
    sıcak tonu o dilde doğal duracak şekilde uyarlama — TR "Kanka"/EN "Buddy"/ES "Amigo")
    yazıldı. Üç dil de Günlük Motivasyon'da BİREBİR aynı sayıda (8) söz içeriyor.
  - **4 betiğin HEPSİ** artık `sendToUser(...)`'ı çağırmadan ÖNCE ilgili kullanıcı(lar) için
    `getLanguageCode(uid)`'i çözüp `content.js`'teki doğru dildeki metni seçiyor —
    `dailyMotivation.js`'de bu, ESKİDEN "tüm kullanıcılara aynı çalıştırmada aynı rastgele söz"
    olan tasarımı "her kullanıcı KENDİ dilinde, kendi rastgele sözünü alır" hâline getirdi (hâlâ
    aynı çalıştırmada, `Promise.all` ile paralel); diğer üçünde zaten per-user bir döngü/filtre
    olduğu için yalnızca `sendToUser` çağrısından hemen önce bir `getLanguageCode` eklemek yeterli
    oldu.
  - **Bu ortamda Node.js YOK, betikler yalnızca dikkatli kod incelemesiyle doğrulandı** (aynı
    "yerel olarak çalıştırılamıyor" sınırlaması, bkz. yukarı) — kullanıcının GitHub Actions'tan
    `workflow_dispatch` ile elle tetikleyip (ideal olarak EN/ES `languageCode`'lu bir test
    kullanıcısıyla) doğrulaması gerekiyor.
- **2026 ÜÇÜNCÜ güncelleme — bildirimler artık kullanıcının KENDİ saat dilimine göre gönderiliyor,
  eskiden HEPSİ sabit Europe/Istanbul saatine göre gidiyordu.** Kullanıcı raporu: Kolombiya'da
  (testerscommunity.com üzerinden bulunan) bir test kullanıcısı, günlük motivasyon bildirimini
  yerel saatiyle sabah 4'te aldığını bildirdi — kök neden buydu, kullanıcının GERÇEK konumu/saat
  dilimi hiçbir zaman dikkate alınmıyordu.
  - **İstemci tarafı — `PushNotificationService.touchLastActive(uid)`** (zaten `RootScreen`'in her
    açılışında/`AppLifecycleState.resumed`'da çağırdığı, `lastActiveAt`'i güncelleyen metot) artık
    AYRICA cihazın GÜNCEL IANA saat dilimini (`flutter_timezone` paketi, `FlutterTimezone.
    getLocalTimezone().identifier` — ör. `America/Bogota`) okuyup `users/{uid}.timeZone` alanına
    yazıyor. Saat dilimi okuması AYRI bir try/catch'te — bu adım başarısız olsa bile (desteklenmeyen
    platform vb.) `lastActiveAt` güncellemesi ("Geri Kazanma" bildiriminin TEK veri kaynağı)
    ETKİLENMİYOR. Ayrı bir yazım turu/mekanizma GEREKMEDİ — mevcut "her resume'da tazele" çağrısına
    tek bir alan eklendi, bu da kullanıcı SEYAHAT ettiğinde bile saat diliminin makul bir sıklıkla
    güncel kalmasını sağlıyor.
  - **Sunucu tarafı — `notification-scripts/src/common.js`'e İKİ yeni yardımcı eklendi:**
    `userLocalHour(user, date)` (kullanıcının KENDİ yerel saatindeki saat değeri, 0-23) ve
    `userDateKey(user, date)` (kullanıcının KENDİ yerel takvim günü, `YYYY-MM-DD`) — ikisi de
    Node'un YERLEŞİK `Intl.DateTimeFormat` desteğiyle IANA saat dilimi isimlerini kullanıyor (ek bir
    npm paketi GEREKMEDİ), bu da yaz/kış saatini (DST) otomatik doğru hesaplıyor. `users/{uid}.
    timeZone` alanı YOKSA (eski uygulama sürümü, henüz güncellemeyen kullanıcı) VEYA geçersiz bir
    IANA ismiyse `Europe/Istanbul`'a düşülüyor — 2026 güncellemesinden ÖNCEki davranışla TUTARLI bir
    geri düşüş, kimse "kırılmıyor". Eski `istanbulDateKey`/`istanbulMinutesOfDay` (yalnızca sabit
    Istanbul saatine göre hesaplayan) fonksiyonları, tüm kullanım yerleri değiştirildikten sonra
    TAMAMEN kaldırıldı — artık hiçbir yerde kullanılmıyorlardı.
  - **Mimari değişiklik — 5 betiğin HEPSİ "sabit Istanbul saatinde bir kez çalış, herkese gönder"
    yerine "SAATTE BİR çalış, yalnızca KENDİ yerel saati hedefe denk gelen kullanıcılara gönder"
    modeline geçti:**
    - `dailyMotivation.js`: `TARGET_LOCAL_HOURS = [9, 12, 16, 20]` (eski dört sabit Istanbul
      saatiyle AYNI ruh, artık HERKESİN KENDİ 9/12/16/20'sinde). Eski `SAFETY_MIN_MINUTE`/
      `SAFETY_MAX_MINUTE` güvenlik penceresi TAMAMEN kaldırıldı — YENİ tasarım zaten yalnızca
      kullanıcının hesaplanan yerel saati hedefe denk geldiğinde gönderim yaptığı için o güvenlik
      ağına gerek kalmadı ("yanlış saatte gönderim" riski tasarım gereği yok).
    - `streakReminder.js` (`TARGET_LOCAL_HOURS = [20]`), `dailyRewardReminder.js`
      (`= [15]`), `waterReminder.js` (`= [16]`) — üçü de HEM saat filtresini HEM "bugün" tanımını
      (`istanbulDateKey` yerine `userDateKey`) kullanıcının yerel saat dilimine göre hesaplıyor;
      Firestore alt-doküman okuması (goals/dailyRewards/waterState) yalnızca saat filtresini
      GEÇEN kullanıcılar için yapılıyor (gereksiz okuma maliyetini önlemek için filtre ÖNCE).
    - `reEngagement.js` (`TARGET_LOCAL_HOURS = [11]`) — "2 gündür açılmadı mı" kontrolü zaten ham
      milisaniye farkına dayandığı için saat dilimi bağımsızdı, DEĞİŞMEDİ; yalnızca gönderim ANI
      artık kullanıcının yerel saatine göre.
  - **`.github/workflows/*.yml` (4 dosya, `cleanup-stale-anonymous-users.yml` HARİÇ) — cron'lar
    GÜNDE BİR/DÖRT sabit tetiklemeden SAATTE BİR'e çevrildi**, her biri KENDİ sabit, yoğun-olmayan
    dakikasında (GitHub'ın `:00/:15/:30/:45`'i "yoğun" işaretlediği, gerçek bir olayla doğrulanmış
    gecikme riski — bkz. `daily-motivation.yml`'deki tarihsel not — bu yüzden her workflow farklı
    ve yuvarlak olmayan bir dakika kullanıyor, hem GitHub'ın yoğun dakikalarından kaçınmak hem
    4 workflow'un aynı anda çakışmaması için): `daily-motivation` `:07`, `streak-reminder` `:14`,
    `daily-reward-reminder` `:21`, `re-engagement` `:42`, `water-reminder` `:49`.
  - **Bilinçli ölçek/maliyet notu (şimdilik sorun DEĞİL, ileride revize edilebilir):** saatlik
    çalıştırma, `fetchAllUsers()`'ın (tüm `users` koleksiyonunu okuyan) çağrı sıklığını ~9 kat
    artırdı (günde ~9 çalıştırmadan 5×24=120 çalıştırmaya). Küçük bir kapalı test kullanıcı
    tabanında (birkaç düzine kişi) bu, Firestore'un Spark (ücretsiz) plan kotasının (günde 50.000
    okuma) çok altında kalıyor — ama kullanıcı sayısı ileride binlere çıkarsa (ör. 1000+ kullanıcı)
    bu tasarım günde 100.000+ okumaya çıkıp ücretsiz kotayı aşabilir. O noktaya gelinirse çözüm:
    her kullanıcının "hedef saat kovası"nı (ör. `timeZone`'dan türetilen bir UTC-saat ofseti)
    Firestore'da AYRI bir alan olarak SAKLAYIP, sorguyu `where('targetHourBucket', '==', currentUtcHour)`
    gibi bir Firestore sorgusuna çevirmek (tüm koleksiyonu her seferinde ÇEKMEK yerine yalnızca o
    anki kovaya denk gelenleri sorgulamak) — şimdilik bu optimizasyon YAPILMADI, "bilinçli
    basitleştirme" (mevcut ölçekte gereksiz karmaşıklık).
  - **Bu ortamda Node.js YOK, betikler (aynı yukarıdaki sınırlama) yalnızca dikkatli kod
    incelemesiyle doğrulandı, `flutter test` (299/299) ile Flutter tarafının derlendiği/geçtiği
    doğrulandı.** Kullanıcının GitHub Actions'tan `workflow_dispatch` ile elle tetikleyip (ideal
    olarak farklı `timeZone` değerlerine sahip birkaç test kullanıcısıyla) doğrulaması gerekiyor —
    özellikle Kolombiya'daki test kullanıcısının bir sonraki bildirimi artık KENDİ yerel saatinde
    (gece yarısı/sabaha karşı DEĞİL) aldığını teyit etmek.
  - **Yeni versiyon gerektiren kısım YALNIZCA istemci tarafı** (`touchLastActive`'in `timeZone`
    yazması) — sunucu tarafı (`notification-scripts`/`.github/workflows`) değişiklikleri repoya
    push edilir edilmez, kullanıcı hiçbir şey yapmadan devreye girer. Eski uygulama sürümündeki
    (henüz güncellemeyen) kullanıcılar `timeZone` alanı yazmadığı için Europe/Istanbul'a düşer —
    yani KIRILMIYORLAR, yalnızca güncelleyene kadar eski (sabit Istanbul saatli) davranışı
    görmeye devam ediyorlar.
- **2026 DÖRDÜNCÜ güncelleme — saat-dilimi dağıtımından SONRA bildirimler 33+ saat boyunca
  TAMAMEN durdu, "catch-up" penceresine geçilerek düzeltildi.** Kullanıcı raporu: yukarıdaki
  saat-dilimi güncellemesinden beri hiçbir bildirim gelmiyordu, GitHub'dan manuel tetiklemek de
  hiçbir şey göndermiyordu. `gh run list`/`gh run view --log` ile canlı teşhis edildi:
  - **Kanıt — kesin bir ÖNCE/SONRA sınırı bulundu.** Son başarılı gönderim 2026-08-25 19:20 UTC'de
    (`daily_motivation`, 16 kullanıcıya) gerçekleşmişti; saat-dilimi commit'i (`9071c82`) TAM
    2026-08-25 21:54 UTC'de deploy edildi; o andan itibaren — kullanıcının manuel tetiklemesi DAHİL
    — TÜM betiklerin TÜM çalıştırmaları (5 betik × onlarca çalıştırma, 33+ saat) istisnasız
    `"N kullanıcıdan 0'i şu an hedef yerel saatte"` diye loglandı. Bu net zaman sınırı, saat-dilimi
    değişikliğinin kendisini kesin şüpheli yaptı.
  - **Kök neden — "TAM o saat mi?" kontrolü GitHub Actions'ın kendi cron güvenilirliğine karşı
    çok kırılgandı.** `.github/workflows/*.yml`'in cron'ları GERÇEKTEN saatlik (`'7 * * * *'` vb.)
    olsa da, GERÇEK çalıştırma zaman damgaları incelenince GitHub'ın bu tetiklemelerin ÇOĞUNU
    (bazen 2-4+ saatlik boşluklarla) GECİKTİRDİĞİ/hiç ateşlemediği görüldü — bu, projede DAHA
    ÖNCE de karşılaşılmış, GitHub'ın kendi dokümantasyonunda kabul edilen bir sınırlama (bkz.
    yukarıdaki "Günlük Motivasyon" bölümündeki ilk `pickSlot` deneyiminin dersi), ama SAATLİK + 5
    AYRI workflow'a geçişle (eskiden günde birkaç sabit tetikleme) yük ÇOK artıp gecikme/atlama
    çok daha SIK hale geldi. Eski tasarım `userLocalHour(u, now) === TARGET`'in TAM O DAKİKADA
    yakalanmasını gerektiriyordu — bir tetikleme gecikir/atlanırsa, o kullanıcının o günkü dilimi
    BİR DAHA HİÇ yakalanamıyordu (ertesi gün `now` ilerleyip hedef saat GERİDE kalana kadar) —
    GitHub'ın gecikme sıklığı göz önüne alınca bu, PRATİKTE neredeyse HİÇBİR gönderimin
    gerçekleşmemesine yol açtı.
  - **Düzeltme — `common.js`'e `pendingNotifyHours`/`markNotifyHoursSent` eklendi, TÜM 5 betik
    bunu kullanacak şekilde güncellendi.** Kontrol artık "şu an TAM hedef saat mi?" DEĞİL, "hedef
    saat(ler) GEÇTİ mi VE bugün bu tür için henüz `users/{uid}.notifyState[type]` = `{dateKey,
    sentHours}`'a işlenmedi mi?" — `fetchAllUsers()` zaten TÜM kullanıcı dokümanını çektiği için bu
    EK bir Firestore okuması GEREKTİRMİYOR. Gecikmiş/atlanmış bir tetikleme artık GÜN İÇİNDE
    SONRAKİ (gecikmeli de olsa) herhangi bir çalıştırmada hâlâ doğru şekilde yakalanıyor. Hem
    GERÇEKTEN gönderim yapıldığında HEM DE altta yatan koşul zaten karşılandığı için (hedef zaten
    işaretli, su hedefi zaten tamamlanmış vb.) gönderim BİLİNÇLİ olarak atlandığında
    `markNotifyHoursSent` çağrılıyor — ikisi de "bu dilim bugün için değerlendirildi" anlamına
    gelir, aksi halde aynı günün SONRAKİ bir çalıştırmasında (koşul o sırada değişmiş olabileceği
    için) aynı kullanıcıya birden fazla bildirim gitme riski doğardı. **Günlük Motivasyon'un DÖRT
    hedef saati** için: birden fazla dilim BİRDEN aynı çalıştırmada "geçmiş" bulunursa (uzun bir
    GitHub gecikmesi/atlaması sonucu) kullanıcıya TEK bir (spam olmayan) bildirim gidip TÜM geçmiş
    dilimler birlikte "işlendi" işaretleniyor — 4 ayrı bildirim yerine bir "yakalama" bildirimi.
  - **Doğrulanamadı (bu ortamda Node.js yok, bkz. bölümün genelindeki AYNI sınırlama)** — kod
    yalnızca dikkatli inceleme + yukarıdaki kanıt zinciriyle doğrulandı. **Kullanıcının doğrulaması
    gereken:** bir sonraki GitHub Actions çalıştırmasından (otomatik veya `workflow_dispatch` ile
    manuel) sonra loglarda `"Gönderildi: uid=..."` satırlarının tekrar görünmesi VE gerçek cihazda
    bir bildirimin gelmesi.
- **2026 BEŞİNCİ güncelleme — üç bağımsız gerçek kullanıcı raporu birlikte incelendi ve düzeltildi:
  "bildirimler 3 kez birden ve düzensiz geliyor", "bildirimlerde hep aynı motivasyon cümleleri
  tekrar ediyor", "günlük Zibo Coin ödülü 1. günde takılı kalıyor".** Üçü de kanıta dayalı ayrı ayrı
  araştırıldı (kör tahminle düzeltmeye başlanmadı) — kökleri BİRBİRİNDEN TAMAMEN BAĞIMSIZ çıktı:
  1. **"3 bildirim birden" — KÖK NEDEN: 5 bildirim türünün `TARGET_LOCAL_HOURS`'ları arasında
     ÇAKIŞMA, tekrarlayan/çift tetikleyici DEĞİL.** `gh run list`/`gh run view --log` ile
     onlarca çalıştırma incelendi — GitHub Actions'ın saatlik cron'ları GÜVENİLİR şekilde
     ateşleniyordu (önceki "33+ saat tamamen durdu" olayından farklı olarak) VE `pendingNotifyHours`/
     `markNotifyHoursSent` catch-up penceresi (bkz. yukarıdaki DÖRDÜNCÜ güncelleme) tek bir türün
     kendi içinde çift gönderim yapmasını zaten doğru şekilde engelliyordu — sorun tekilleştirme
     DEĞİL, ZAMANLAMA tasarımıydı: eski hedef saatler `dailyMotivation=[9,12,16,20]`,
     `waterReminder=[16]` (dailyMotivation'ın 16'sıyla TAM çakışıyordu),
     `dailyRewardReminder=[15]` (16'ya yalnızca 1 saat mesafede), `streakReminder=[20]`
     (dailyMotivation'ın 20'siyle TAM çakışıyordu) idi — bir kullanıcı 15:XX-16:XX arası ödül +
     motivasyon + su (ÜÇ bildirim, ~60-90 dakika içinde) ve 20:XX'te motivasyon + streak (İKİ
     bildirim, AYNI saatte) alabiliyordu. **Düzeltme — saatler yeniden dağıtıldı, hiçbir türün
     GÜNLÜK SIKLIĞI azaltılmadı** (dailyMotivation'ın 4x/gün'ü ÖNCEKİ bir kullanıcı isteğiydi,
     geri alınmadı — yalnızca ÇAKIŞMA giderildi): `waterReminder` `16→14` (dailyMotivation'ın 12 ve
     16 dilimlerinin tam ortası), `dailyRewardReminder` `15→18` (dailyMotivation'ın 16 ve 20
     dilimlerinin tam ortası), `streakReminder` `20→21` (dailyMotivation'ın son diliminden yalnızca
     1 saat sonra — TAM çakışmadan çok daha iyi, ayrıca "gün bitmeden son şans" anlamına da daha
     uygun düştü). `reEngagement=[11]` DEĞİŞTİRİLMEDİ (hiçbir türle TAM çakışmıyordu, kapsam dışı
     bırakıldı — gereksiz risk eklemeden minimal müdahale). **Yeni tam program (yerel saat):**
     `9, 11, 12, 14, 16, 18, 20, 21` — en dar boşluk artık 1 saat (11-12, 20-21), eskiden 0 saat
     (tam çakışma) olan İKİ nokta tamamen giderildi. `.github/workflows/{streak-reminder,
     daily-reward-reminder,water-reminder}.yml`'in dokümantasyon yorumları da yeni saatlere göre
     güncellendi (cron'un kendisi zaten saatlik, `TARGET_LOCAL_HOURS` filtrelemesi JS tarafında).
  2. **"Hep aynı sözler tekrar ediyor" — KÖK NEDEN DOĞRULANDI (bkz. "content.js" dosyasının kendi
     eski yorumu): `notification-scripts/src/content.js`'in `daily_motivation` havuzu YALNIZCA
     8 söz/dil içeriyordu, Ana Sayfa'nın KENDİSİNİN kullandığı `lib/data/zibo_messages.dart`'taki
     TAM 279'luk havuzla senkron DEĞİLDİ** ("küçük temsili bir alt küme kullanılıyor" diye dosyanın
     kendi yorumunda bilerek işaretlenmiş bir basitleştirmeydi). Günde 4 kez 8 sözlük bir havuzdan
     rastgele seçim yapınca birkaç gün içinde kaçınılmaz tekrar oluyordu. **Düzeltme — İKİ AYRI
     katman:**
     - **`tool/generate_content_js_daily_motivation.dart` (YENİ, tekrar çalıştırılabilir betik)**
       — `lib/data/zibo_messages.dart`'ı DOĞRUDAN import ETMEDEN (o dosya `package:flutter/
       material.dart` import ediyor, plain `dart run` Flutter framework'ünü çözemeyip çöküyordu —
       ilk denemede yakalandı) kaynağı düz metin olarak okuyup `const ziboMessagesXx =
       <String>[...]` bloklarını satır-satır ayrıştırıyor (tek/çift tırnaklı Dart string
       literallerini, aralardaki dokümantasyon yorumlarını atlayarak) ve `jsonEncode` ile
       (JSON string literalleri her zaman geçerli JS string literalleridir) hatasız bir JS çıktısı
       üretiyor — 837 satırı (279×3 dil) ELLE kopyalamak yerine. **Gotcha (yakalanıp düzeltildi):**
       ilk sürüm çift-tırnaklı satırlardaki `\"` iç-tırnak kaçışlarını unescape ETMİYORDU (`Say one
       \\\"no\\\" today...` gibi ÇİFT kaçışlı, geçersiz bir çıktı üretiyordu) — genel bir `\X → X`
       unescape'e (hem `\'` hem `\"` için) geçilerek düzeltildi, iki dedicated regex yerine.
       `content.js`'in `daily_motivation` bloğu artık bu betiğin ÜRETTİĞİ, `lib/data/
       zibo_messages.dart` ile BİREBİR senkron TR/EN/ES 279'ar sözden oluşuyor.
     - **"En azından son birkaç günde kullanılmamış" garantisi (kullanıcının AÇIKÇA istediği
       ikinci gereksinim)** — `dailyMotivation.js`'e `pickQuoteAvoidingRecent(quotes,
       recentIndices)` eklendi: `users/{uid}.notifyState.daily_motivation.recentQuoteIndices`
       (kalıcı, en fazla `RECENT_QUOTE_MEMORY=20` elemanlı bir dizi — günde 4 gönderimle ~5 günlük
       tekrarsızlık penceresi) son gönderilen söz INDEX'lerini tutuyor, yeni seçim bu indexleri
       HARİÇ TUTARAK yapılıyor (279'luk havuzda hepsi hariç tutulacak kadar dolması pratikte
       imkansız, yine de bir güvenlik ağı olarak havuz tükenirse TÜM havuza geri düşülüyor). Bu
       index dizisi DİLDEN BAĞIMSIZ — TR/EN/ES havuzları AYNI sırada/anlamda hizalı olduğu için
       (`content.js`'in kendi yorumu) kullanıcı dil değiştirse bile aynı kavramsal söz kısa sürede
       tekrar gelmiyor. `markNotifyHoursSent` (paylaşılan, 5 betiğin HEPSİNİN kullandığı) SÖZLEŞMESİ
       DEĞİŞTİRİLMEDİ — `recordQuoteIndex` AYRI, küçük bir `db.set(..., {merge:true})` çağrısı
       (Firestore'un nested map alanlarını `merge:true` ile REKÜRSİF birleştirdiği doğrulandı, bu
       yüzden iki ayrı `set` çağrısı `notifyState.daily_motivation` altında `dateKey`/`sentHours`/
       `recentQuoteIndices` üçünü de kaybetmeden bir araya geliyor).
     - **Doğrulandı (2026-08-29) — `content.js`'in söz dizimi ÖNCE elle + brace/parantez
       sayımıyla, SONRA GERÇEK bir GitHub Actions çalıştırmasıyla doğrulandı.**
       `daily-motivation.yml` `gh workflow run` ile elle tetiklendi, log şunu gösterdi:
       `"39 kullanıcıdan 1'i şu an hedef yerel saatte... — günlük motivasyon gönderiliyor."`
       ardından `"Gönderildi: uid=... type=daily_motivation"` — betik HİÇBİR JS söz dizimi/çalışma
       zamanı hatası fırlatmadan çalıştı (279 satırlık `content.js` bloğu VE `pickQuoteAvoidingRecent`
       ikisi de gerçekte hatasız çözüldü). **Hâlâ kullanıcının doğrulaması gereken:** birkaç gün
       gerçek kullanımda aynı sözün ardı ardına gelmediğini (yeni 279'luk havuz + tekrar-önleme
       penceresi sayesinde) gözlemlemek — bu, YALNIZCA zaman geçtikçe gözlemlenebilecek bir
       davranış, tek bir çalıştırmayla kanıtlanamaz.
  3. **"Günlük ödül 1. günde takılı kalıyor" — KÖK NEDEN: `TrustedTimeProvider`'da cross-session
     staleness, `DailyRewardsProvider`'ın KENDİSİNDE DEĞİL.** `daily_rewards_provider.dart`
     (`reconcileForToday`/`claimToday`/`todayIndex`) incelendi — bu dosyanın ÖNCEKİ bir oturumda
     tam olarak bu semptom için düzeltilmiş `idx < 0` mantığı hâlâ doğru duruyordu, provider
     KENDİ İÇİNDE bir bug barındırmıyordu. Şüphe `TrustedTimeProvider.now()`'a kaydı — sınıfın
     KENDİ dokümantasyonu "ilk doğrulama HİÇ TAMAMLANMADAN cihaz saatine GEÇİCİ olarak düşülür"
     diyordu, ama KOD bunu UYGULAMIYORDU: `_loadFromPrefs()` kalıcı depodan (ÖNCEKİ bir oturumdan,
     saatler/günler eski olabilecek) bir `_lastVerifiedUtc` yüklediği ANDA, `now()` bunu SANKİ BU
     OTURUMDA taze doğrulanmış gibi (`verified + _stopwatch.elapsed`, `_stopwatch` BU oturumun
     başında sıfırdan başlamış olsa BİLE) kullanmaya başlıyordu — "kalıcı depodan bir değer okundu"
     ile "BU oturumda gerçekten doğrulandı" birbirine KARIŞTIRILMIŞTI. Eğer bir cihazda/oturumda ağ
     senkronizasyonu TUTARLI şekilde başarısız olursa (ör. soğuk başlangıçta henüz bağlanmamış
     Wi-Fi/mobil veri — MIUI'nin agresif ağ kısıtlaması bu projede DAHA ÖNCE de karşılaşılan bilinen
     bir sorun, bkz. "Bildirimler" bölümündeki arka plan teslimat notu), `now()` GÜNLERCE
     dondurulmuş eski bir tarihte kalabiliyordu — her gün uygulama açıldığında "bugün" hep AYNI
     (eski) günü gösterip `todayIndex`'in ASLA ilerlememesine yol açıyordu; kullanıcının GERÇEKTEN
     force-close edip her gün soğuk başlangıç yaptığı bir kullanım deseninde bu GÜNLÜK olarak
     tekrarlanabilirdi. **Düzeltme:** `TrustedTimeProvider`'a `_verifiedThisSession` (bool) eklendi
     — `now()` artık yalnızca BU OTURUMDA gerçekten bir ağ doğrulaması TAMAMLANDIYSA `verified +
     _stopwatch.elapsed` kullanıyor; kalıcı depodan yüklenmiş ama BU oturumda henüz tazelenmemiş
     bir değer varken (`hasVerifiedTime` `true` dönse BİLE geçerli bir durum) `now()` güvenle cihaz
     saatine düşüyor — TAM OLARAK sınıfın zaten VAAT ETTİĞİ (ama kodun uygulamadığı) davranış.
     Güvenlik özelliği (bir doğrulama BU oturumda tamamlandıktan sonra cihaz saati bir daha ASLA
     danışılmaz — kullanıcı saati manuel ileri/geri alarak günlük ödülleri tekrar tetikleyemez)
     KORUNUYOR, yalnızca cross-session staleness kapatıldı.
     - **Test:** YENİ `test/trusted_time_provider_test.dart` (5 test) — özellikle "KRİTİK" testi bu
       TAM senaryoyu simüle ediyor (kalıcı depoda yıllar eski bir doğrulama + bu oturumda ağ
       senkronu BAŞARISIZ → `now()` eski/dondurulmuş tarihi DEĞİL, gerçek cihaz saatini döndürmeli)
       — bu test DÜZELTMEDEN ÖNCEKİ kodda BAŞARISIZ olurdu, düzeltmeden SONRA geçiyor; bu, fix'in
       gerçekten bu regresyonu yakaladığının somut kanıtı. `flutter test` tam yeşil: **330/330.**
     - **Gerçek cihazda doğrulanmadı** (ağın soğuk başlangıçta kasıtlı olarak kesilmesini gerektiren
       bir senaryo, kontrollü şekilde tekrarlaması zor) — mantığı test edilen, saf/deterministik bir
       provider metodudur, risk düşük kabul edildi. Kullanıcı isterse: uçak modunu aç → uygulamayı
       kapat → uçak modunu kapatmadan (veya ağı gerçekten yavaş bırakarak) uygulamayı yeniden aç →
       Günlük Giriş Ödülleri'nin ESKİ günü DEĞİL, `DateTime.now()`'a yakın bir günü göstermesi
       gerekir (kalıcı depoda önceden doğrulanmış bir zaman varsa bile).
  - **Genel doğrulama (2026-08-29, kullanıcı isteğiyle: "önce apkyı telefonuma kur sonra tetikle
    loglara bak onaylıyorum") — 1/2/3'ün HEPSİ tek bir turda birlikte doğrulandı:** `flutter build
    apk --debug` ile yeniden derlenip telefona kurulup çöküş olmadan açıldığı (`adb shell monkey` +
    `pidof`, logcat'te `FATAL EXCEPTION` YOK) doğrulandıktan SONRA, saat çakışması düzeltmesinden
    etkilenen DÖRT workflow (`daily-motivation`, `daily-reward-reminder`, `streak-reminder`,
    `water-reminder`) `gh workflow run` ile elle tetiklenip loglar okundu — DÖRDÜ de hatasız
    tamamlandı (`✓` durumu), tek "hata" sınıfı birkaç `NotRegistered` (eski/geçersiz FCM token,
    betiğin zaten beklediği/sessizce atladığı zararsız bir durum, KOD hatası DEĞİL). **Şeffaf bir
    not:** bu manuel tetikleme günün akşam saatine denk geldiği için, YENİ saatlere (`reward=18`,
    `water=14`) geçişten SONRAKİ İLK çalıştırma olduğundan catch-up mekanizması o an "bugün için
    henüz işlenmemiş" bulduğu birçok kullanıcıya ÖDÜL VE SU hatırlatmasını ARKA ARKAYA gönderdi —
    bu, YENİ saatlerin KENDİSİNİN bir çakışması DEĞİL, yalnızca bu BİR KEZLİK manuel/gündüz-dışı
    test tetiklemesinin yan etkisiydi; normal saatlik zamanlamada her tür kendi saatinde, günün
    farklı anlarında tetiklenmeye devam edecek. `streak-reminder` "0 kullanıcı hedef saatte" dedi
    (beklenen — tetikleme anında hiçbir kullanıcının yerel saati henüz 21 değildi), bu da mantığın
    YANLIŞ POZİTİF üretmediğinin kanıtı.
- **2026 ALTINCI güncelleme — kullanıcı raporu: "bildirimler şimdi de 2şer tane gelmeye başladı."**
  Kanıta dayalı araştırma, kör tahminle "muhtemelen sunucu tarafı" diye düzeltmeye BAŞLANMADI —
  önce `gh run view --log` ile 5 betiğin TAMAMININ son ~15'er çalıştırması tek tek incelendi:
  - **SUNUCU tarafında (`notification-scripts`) bir çift-gönderim bulunamadı.** Her çalıştırma
    log'u, uygunluk saati/dilim koşulunu karşılayan HER kullanıcı için TAM BİR `"Gönderildi:
    uid=... type=..."` satırı üretiyordu — iki kez değil. `daily_motivation`'ın AYNI 15 kullanıcıya
    ~3 saat arayla (06:10 VE 09:10 UTC) tekrar göndermesi İLK BAKIŞTA bir çift-gönderim gibi
    göründü, ama bu tamamen BEKLENEN bir davranıştı: bu kullanıcılar Türkiye saatinde (UTC+3),
    `TARGET_LOCAL_HOURS = [9, 12, 16, 20]`'nin İKİ AYRI değerine (yerel 09:10 → hedef 9, yerel
    12:10 → hedef 12) denk geliyorlardı — kullanıcının kendi önceki isteğiyle ZATEN "günde 3-4 kez"
    olacak şekilde tasarlanmış özelliğin doğru çalışması, bir hata DEĞİL. Diğer dört türün
    (`streak_reminder`/`water_reminder`/`daily_reward`/`re_engagement`, hepsi TEK bir hedef saate
    sahip) günlük tekrarları da (~24 saat arayla) aynı şekilde BEKLENEN, tek-günlük cadence'e uygun
    çıktı — hiçbir türde AYNI gün İÇİNDE, AYNI hedef saat için iki ayrı "Gönderildi" satırı
    bulunmadı.
  - **Kök neden İSTEMCİ tarafında bulundu — `NotificationService.showNow()`'ın rastgele bildirim
    id'si.** FCM'in kendi teslimat garantisi resmi olarak "en az bir kez" (at-least-once), "TAM
    OLARAK bir kez" DEĞİL (Firebase'in kendi dokümantasyonu) — ağ yeniden bağlanması gibi durumlarda
    AYNI mantıksal mesaj istemcinin `FirebaseMessaging.onMessage` akışına İKİNCİ kez düşebiliyor.
    `PushNotificationService`'in `onMessage` handler'ı bunu `NotificationService.showNow()`'a
    iletiyordu, ve `showNow()` HER çağrıda `DateTime.now().millisecondsSinceEpoch.remainder(100000)`
    ile YENİ/rastgele bir bildirim id'si üretiyordu — Android'de `_plugin.show(id: ...)`'ün AYNI
    id'yle çağrılması mevcut bildirimin ÜZERİNE YAZAR/günceller, FARKLI id'yle çağrılması ise
    TAMAMEN AYRI, İKİNCİ bir kart EKLER. Rastgele id, bu yeniden-teslimatı Android'in gözünde
    "alakasız yeni bir bildirim" gibi gösteriyordu — kullanıcı bu yüzden AYNI bildirimin "2 tane"
    geldiğini görüyordu.
  - **Düzeltme — iki katmanlı:**
    1. **Kök/asıl düzeltme — `messageId` tabanlı dedup.** `FirebaseMessagingPushNotificationService`'e
       `_recentMessageIds` (en fazla 20 elemanlı, FIFO) eklendi — `onMessage` handler'ı artık FCM'in
       HER mesaja verdiği benzersiz `message.messageId`'yi bu listede ARAYIP zaten işlenmişse
       `showNow()`'ı hiç ÇAĞIRMADAN sessizce çıkıyor.
    2. **İkinci savunma hattı — deterministik bildirim id'si.** `NotificationService.showNow()`'a
       opsiyonel bir `int? id` parametresi eklendi (verilmezse eski rastgele davranışa düşülür —
       geriye dönük uyumlu, TEK çağıran yeri `PushNotificationService` olduğu için risksiz bir
       değişiklik); `onMessage` artık `id: messageId?.hashCode` geçiriyor — (1)'i her nasılsa
       kaçıran bir yeniden teslimat (ör. `messageId` `null` gelirse) olsa bile, Android'in kendi
       "aynı id = güncelle, yeni kart EKLEME" davranışı ikinci bir güvenlik ağı oluyor.
  - **Doğrulanamadı — bu, gerçek bir FCM yeniden-teslimat senaryosunu (ağ kesintisi/yeniden bağlanma
    ANINDA bir bildirim gelmesi) KONTROLLÜ olarak tetiklemek pratik olmadığı için gerçek cihazda
    UÇTAN UCA doğrulanamadı** (yalnızca `flutter test`, 358/358 yeşil — `showNow()`'ın imza
    değişikliği hiçbir mevcut çağrı yerini bozmadı). `PushNotificationService`/
    `FirebaseMessagingPushNotificationService` zaten gerçek Firebase Messaging'e ihtiyaç duyduğu
    için (bkz. bu bölümün en başındaki "flutter_test'te DOĞRUDAN test EDİLEMİYOR" notu, diğer
    Firebase-bağımlı servislerle AYNI sınırlama) otomatik bir regresyon testi de YAZILAMADI. **Bu
    KESİN bir kanıtlanmış çözüm DEĞİL, ama Firebase'in KENDİ resmi "at-least-once, id'lerinizi
    deterministik tutun" tavsiyesine dayanan, doğru/standart bir düzeltme** — kullanıcının birkaç
    gün gerçek kullanımda "2 tane geliyor" örüntüsünün TEKRARLANIP tekrarlanmadığını gözlemlemesi
    gerekiyor.
- **2026 YEDİNCİ güncelleme — kullanıcı raporu: ALTINCI güncellemeden SONRA "3 kez" gitti ama
  Günlük Motivasyon (günde 4 hedef saatiyle en sık tetiklenen tür) ÖZELLİKLE hâlâ 2 kez geliyor.**
  Yine kanıta dayalı — kör tahminle başlanmadı: (1) `.github/workflows/daily-motivation.yml`'de
  TEK bir `cron:` girdisi olduğu, GİZLİ bir ikinci tetikleyici OLMADIĞI doğrulandı; (2)
  `gh run list --workflow=daily-motivation.yml` ile son ~30 çalıştırma (tam bir gün) çekilip her
  birinin `event: schedule`, TEKİL ve saatlik aralıklarla geldiği (GitHub'ın workflow'u ÇİFT
  TETİKLEMEDİĞİ) doğrulandı; (3) `gh run view --log` ile bu 30 çalıştırmanın TAMAMINDAKİ
  `"Gönderildi: uid=..."` satırları çıkarılıp AYNI uid'in İKİ ARDIŞIK saatlik çalıştırmada
  (dolayısıyla AYNI hedef saat için) tekrar ETMEDİĞİ doğrulandı — sunucu YİNE tek bir çalıştırma
  İÇİNDE çift göndermiyordu.
  - **Gerçek kök neden — `users/{uid}.fcmToken` hesap DEĞİŞİMLERİNDE (Ayarlar > "Çıkış Yap"/
    "Hesap Değiştir") ESKİ uid'in belgesinden HİÇ SİLİNMİYORDU.** FCM token'ı Firebase Auth
    kullanıcısından BAĞIMSIZ, cihazın/uygulama kurulumunun kendisine ait — `_saveToken(uid, token)`
    yalnızca O ANKİ uid'in belgesine YAZIYOR, `signOut()`/`signIn()` (Google hesap değiştirme/çıkış,
    bkz. "Google Hesap Bağlama" bölümü) sonrasında ESKİ uid'in `fcmToken`'ı orada YAŞAMAYA devam
    ediyordu. Bu projenin test cihazı (ve muhtemelen kullanıcının kendi telefonu) bu turdan ÖNCE
    onlarca kez anonim↔Google-bağlı↔farklı-hesap geçişi yaptığı için (bkz. "Google Hesap Bağlama"
    bölümündeki uzun geçmiş), AYNI fiziksel cihazın `fcmToken`'ı BİRDEN FAZLA `users/{uid}`
    belgesinde AYNI ANDA canlı kalabiliyordu — iki (veya daha fazla) uid BAĞIMSIZ olarak
    "eligible" olduğunda AYNI cihaza İKİ AYRI FCM mesajı (İKİ FARKLI `messageId`) gidiyordu.
    **ALTINCI güncellemenin `messageId` dedup'ı bunu YAKALAYAMAZ** — bunlar GERÇEKTEN iki farklı
    sunucu-kaynaklı mesaj, FCM'in kendi yeniden-teslimatı DEĞİL. Günlük Motivasyon'un günde DÖRT
    hedef saati olması (diğer dört türün her biri yalnızca BİR), bu riske istatistiksel olarak DÖRT
    KAT daha fazla maruz kalması anlamına geliyordu — kullanıcının yalnızca bu türü fark etmesinin
    doğal açıklaması.
  - **Düzeltme — iki katmanlı, kök neden + geriye dönük güvenlik ağı:**
    1. **Kök/asıl düzeltme (istemci) — `GoogleAuthService.signOut()`/`signIn()`'e YENİ
       `_clearFcmTokenForCurrentUser()` çağrısı eklendi**, uid GERÇEKTEN değişmeden HEMEN ÖNCE
       (hâlâ ESKİ kullanıcı olarak kimlik doğrulanmışken — Firestore rules `request.auth.uid ==
       uid` gerektirdiği için switch'ten SONRA yazmaya çalışmak sessizce reddedilirdi) eski uid'in
       `fcmToken`'ını `null`'a set ediyor. `linkCurrentUser()` (uid'i DEĞİŞTİRMEYEN "bağlama" akışı)
       BİLEREK bu çağrıyı YAPMIYOR — orada bir uid switch'i yok, temizlenecek bir "eski" uid de yok.
    2. **Geriye dönük güvenlik ağı (sunucu) — `notification-scripts/src/common.js`'e YENİ
       `dedupeByFcmToken(users)`.** `fetchAllUsers()`'ın (5 bildirim betiğinin TAMAMININ paylaştığı
       TEK kaynak — `cleanupStaleAnonymousUsers.js`/`processReferralRewards.js`/`initFounderBadge
       Counter.js` bunu kullanmıyor, etkilenmiyor) döndürdüğü listede AYNI `fcmToken` değerine
       sahip birden fazla kullanıcı varsa, yalnızca `fcmTokenUpdatedAt`'i EN YENİ olan (o token'ın
       o anki GERÇEK/aktif sahibi — terk edilmiş eski uid'ler token'ı bir daha hiç YENİLEMEDİĞİ
       için zaman damgaları DONMUŞ kalır, `_saveToken` her `initialize()`'da/uygulama açılışında
       çağrıldığı için AKTİF uid'in damgası SÜREKLİ tazeleniyor) tutulup diğerleri elenir — AYNI
       fiziksel cihaza tekrar gönderim ENGELLENİR. Bu, (1)'den ÖNCE oluşmuş ESKİ duplicate
       token'ları da kapsıyor — kullanıcının uygulamayı güncellemesini/tekrar oturum açmasını
       BEKLEMEDEN, bir SONRAKİ zamanlanmış çalıştırmada devreye giriyor. Token'ı OLMAYAN
       kullanıcılar (henüz izin vermemiş) bu filtrelemeden hiç ETKİLENMİYOR.
  - **Test:** `flutter test` — tam suite yeşil (541/542, yalnızca önceden belgelenmiş
    `audioplayers`/`home_widget` flake'i hariç, bu değişiklikle İLGİSİZ). `common.js` (Node.js,
    bu ortamda ÇALIŞTIRILAMIYOR — bkz. bölümün başındaki AYNI sınırlama) yalnızca dikkatli kod
    incelemesiyle doğrulandı. **Doğrulanamadı** — hem istemci düzeltmesi (gerçek bir hesap
    değişimi + ardından iki farklı hedef saatte notification alıp almadığının GÜNLER süren gözlemi
    gerektiriyor) hem sunucu güvenlik ağı (bir SONRAKİ zamanlanmış çalıştırmada `dedupeByFcmToken`
    log satırlarının GERÇEKTEN bir çift bulup bulmadığı) bu turda GÖZLEMLENEMEDİ. **Kullanıcının
    doğrulaması gereken:** birkaç gün gerçek kullanımda Günlük Motivasyon'un artık TEK geldiğini
    gözlemlemek; isterse GitHub Actions > "Günlük Motivasyon Bildirimi" workflow'unun bir SONRAKİ
    çalıştırma logunda `"dedupeByFcmToken: AYNI cihaz için birden fazla uid bulundu..."` satırı
    ARANARAK geçmişte GERÇEKTEN bir duplicate token'ın var olup olmadığı (VE artık elendiği)
    somut olarak teyit edilebilir.
- **`firestore.rules` — DEĞİŞİKLİK GEREKMEDİ (Cloud Functions taslağındaki gerekçeyle AYNI).**
  Mevcut kural zaten `match /users/{userId}/{document=**}` (bkz. "Firestore Veri Kalıcılığı"
  bölümü) ile `users/{uid}` dokümanının TÜM alanlarını (`fcmToken`/`lastActiveAt` dahil) sahibine
  açıyor — Admin SDK (GitHub Actions'taki `firebase-admin`) zaten TÜM güvenlik kurallarını atlıyor,
  bu yüzden bu betiklerin okuma/yazmaları hiçbir şekilde etkilenmiyor.
- **Blaze plan GEREKMİYOR.** Firestore (Spark/ücretsiz planda da tam işlevsel, cömert bir günlük
  ücretsiz kotayla) ve Firebase Cloud Messaging (plan bağımsız, HER ZAMAN ücretsiz) — GitHub
  Actions'ın kendi ücretsiz dakika kotası (public repo'larda sınırsız, private repo'larda ayda
  2000 dakika) bu 4 küçük, saniyeler süren workflow için fazlasıyla yeterli. **Blaze'e geçilmesi
  gereken TEK senaryo:** ileride Şans Çarkı'nın "bugün çevrildi" durumunu Firestore'a
  senkronize etmek için bir `Cloud Function` (ör. bir Firestore trigger) eklenmek istenirse —
  bu, şu anki mimarinin bir parçası DEĞİL.
- **Servis hesabı (GitHub Secrets) — kullanıcının Firebase Console'da yapması gereken adımlar:**
  1. Firebase Console → proje → dişli ikonu → **Project settings** → **Service accounts** sekmesi.
  2. **Generate new private key** butonuna bas → bir `.json` dosyası iner (bu dosyanın İÇİNDEKİ
     `private_key` alanı bir sır — asla kod deposuna commit etme, asla paylaşma).
  3. GitHub'da repo → **Settings** → **Secrets and variables** → **Actions** → **New repository
     secret**.
  4. İsim: `FIREBASE_SERVICE_ACCOUNT_JSON`. Değer: indirilen `.json` dosyasının TÜM içeriğini
     olduğu gibi (metin editöründe açıp kopyala-yapıştır) yapıştır.
  5. Kaydet — bu andan itibaren workflow'lar `${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}` ile
     bu değere erişebiliyor, GitHub bunu loglarda otomatik olarak maskeliyor.
- **Kritik gotcha — bu arc'ta bulunan ve düzeltilen bir `MaterialApp.home` const-kimlik bug'ı:**
  FCM için `RootScreen`'in anonim `uid`'e ihtiyacı olduğu için ilk yazımda `uid` bir constructor
  parametresi olarak `_AppStartupGate`/`RootScreen`'e eklenmiş, bu da ikisini de `const`
  OLMAKTAN çıkarmıştı. Sonuç: `MaterialApp.home`'un her rebuild'de (ör. Ayarlar'dan Koyu Tema
  değiştirilince, `ThemeProvider.notifyListeners()` → `Consumer3` → yeni `MaterialApp` widget'ı)
  YENİ (const OLMAYAN) bir widget kimliği alması — `flutter test`'te "Koyu Tema anahtarı açılınca
  uygulama koyu temaya geçer" testinin `RootScreen`'i ARTIK BULAMADIĞI (element ağacından tamamen
  kaybolduğu) şeklinde ortaya çıktı. **Düzeltme:** `_AppStartupGate`/`RootScreen` `const` kalmaya
  devam ediyor; `uid` bunun yerine `main.dart`'ın `MultiProvider.providers` listesine
  `Provider<String?>.value(value: uid)` olarak eklendi, `RootScreen` bunu `context.read<String?>()`
  ile okuyan bir `_uid` getter'ı üzerinden alıyor. **Kural: `MaterialApp.home`'a (veya ana
  `Navigator`'ın ilk route'una) verilen bir widget'ın kimliği rebuild'ler arası SABİT (`const` veya
  en azından aynı runtimeType+key) kalmalı — "app-session-constant ama compile-time-const olmayan"
  bir değeri (uid gibi) geçirmek gerekiyorsa, widget'a constructor parametresi olarak DEĞİL, bir
  `Provider<T>.value` ile `MultiProvider`'a ekleyip `context.read<T>()` ile okutun.**
  - **Ayrı ve daha küçük bir test gotcha'sı, AYNI test içinde:** Bu testte Ayarlar sayfası
    `RootScreen`'in ÜSTÜNE push edilmiş haldeyken (Koyu Tema anahtarı Ayarlar'da), `Theme.of
    (tester.element(find.byType(RootScreen)))` çağrısı — `RootScreen` teknik olarak hâlâ element
    ağacında (state korunuyor) ama Navigator onu artık BOYAMIYOR (yalnızca en üstteki route
    render ediliyor) — flutter_test'in VARSAYILAN `find.byType` finder'ı (`skipOffstage: true`)
    böyle "offstage" (boyanmayan ama hâlâ mount edilmiş) elemanları ATLAR. **Çözüm:**
    `find.byType(RootScreen, skipOffstage: false)` — bir widget'ın altında BAŞKA bir route
    push edilmişken o widget'ı `find.byType` ile ararken bu deseni kullanın.

### Firebase Anonymous Auth Temizliği — terkedilmiş test kullanıcılarını silme ([cleanupStaleAnonymousUsers.js](../notification-scripts/src/cleanupStaleAnonymousUsers.js), [.github/workflows/cleanup-stale-anonymous-users.yml](../.github/workflows/cleanup-stale-anonymous-users.yml))

- **2026 bakım işi — BİR KERELİK, cron'a BAĞLI DEĞİL.** Kullanıcı isteği: geliştirme boyunca
  yapılan onlarca test kurulumu/kaldırma (her taze kurulum, bkz. "Firestore veri kalıcılığı,
  Anonymous Auth ve güvenilir zaman" bölümü, `main()`'de `signInAnonymously()` ile YENİ bir
  anonim kimlik oluşturuyor) Firebase'de "boşuna" birikmiş, bir daha asla açılmayacak anonim
  kullanıcılar bıraktı — bunlar hem Authentication hem Firestore'da (`users/{uid}/...`) yer
  kaplıyor. Kullanıcı bunun **bir kerelik bir temizliğini** istedi, periyodik/otomatik bir
  mekanizma İSTEMEDİ (bkz. altta "neden `schedule:` yok" notu).
- **Bu ortamda Node.js/npm YOK** (diğer 4 bildirim betiğiyle AYNI sınırlama, bkz. "Push
  Bildirimleri" bölümü) — betik dikkatle elle yazıldı ama YEREL OLARAK ÇALIŞTIRILIP TEST
  EDİLEMEDİ. Kullanıcının GitHub Actions'tan `workflow_dispatch` ile elle tetikleyip
  doğrulaması gerekiyor.
- **`notification-scripts/src/common.js`'e `auth` (yalnızca bu betik için `app.auth()`)
  eklendi** — diğer 4 betik bunu hiç kullanmıyor, yalnızca `db`/`messaging` yeterli oluyordu.
- **`cleanupStaleAnonymousUsers.js` — "terkedilmiş" tanımı, İKİ sinyalden HANGİSİ daha
  YENİYSE onu kullanan, KASITLI OLARAK temkinli bir hesaplama:**
  1. Firestore `users/{uid}.lastActiveAt` (bkz. `PushNotificationService.touchLastActive` —
     `RootScreen`'in her öne gelişinde tazelenir) — yalnızca push bildirimi özelliği
     eklendikten SONRA en az bir kez açılmış kurulumlar için mevcut.
  2. Firebase Auth'un KENDİ `metadata.lastRefreshTime`/`lastSignInTime`/`creationTime`'ı —
     Firebase'in HER kullanıcı için OTOMATİK tuttuğu, bizim kodumuza bağımlı OLMAYAN bir
     sinyal; push bildirimi eklenmeden ÖNCEki eski test kullanıcıları için TEK kaynak bu.
  İki sinyalden İKİSİ de yoksa (teorik olarak imkansız — Auth her zaman `creationTime` taşır)
  güvenlik gereği o kullanıcıya DOKUNULMUYOR, atlanıyor. Eşik `MIN_INACTIVE_DAYS` (varsayılan
  **30 gün** — kullanıcının seçtiği değer, `AskUserQuestion` ile "3/7/30 gün" arasından
  seçildi) — bu SÜREDİR hiç aktivite izi olmayan kullanıcılar silinmeye aday.
- **GÜVENLİK — varsayılan DRY RUN.** Betik `DRY_RUN=false` AÇIKÇA verilmedikçe HİÇBİR ŞEY
  SİLMEZ, yalnızca "şu uid'ler silinecekti" diye Actions log'una yazar. Workflow'un
  `dry_run` girdisi VARSAYILAN `'true'` — kullanıcı ÖNCE dry-run ile listeyi gözden geçirip,
  sonra emin olunca `dry_run: false` ile TEKRAR tetiklemeli. **Bu iki aşamalı onay bilerek
  eklendi** — tersine çevrilemez bir silme işlemi (gerçek Auth kaydı + kullanıcı verisi) kör
  bir şekilde tek seferde çalıştırılmasın diye.
- **Silme işleminin kendisi — hem Auth HEM Firestore, TEK bir kullanıcı için birlikte:**
  `deleteFirestoreUserData(uid)` önce `users/{uid}/state/*` alt koleksiyonundaki TÜM
  dokümanları (`listDocuments()` ile enumere edilip) TEK bir `batch()` içinde `users/{uid}`
  dokümanının kendisiyle BİRLİKTE siliyor (proje ölçeğinde bir kullanıcının `state`
  koleksiyonu ~20 doküman, `WriteBatch`'in 500 yazma sınırına asla yaklaşmıyor) — SONRA
  `auth.deleteUser(uid)` ile Authentication kaydı siliniyor. Yalnızca Firestore verisini
  silip Auth kaydını BIRAKMAK (veya tersi) YARIM bir temizlik olurdu, ikisi BİRLİKTE
  siliniyor.
- **Neden `schedule:` (otomatik/periyodik tetikleyici) YOK — diğer 4 workflow'un AKSİNE:**
  Kullanıcı `AskUserQuestion` ile açıkça "bir kerelik temizlik" seçeneğini seçti
  ("bir kerelik + haftalık otomatik" veya "yalnızca otomatik" DEĞİL) — bu yüzden
  `.github/workflows/cleanup-stale-anonymous-users.yml`'de yalnızca `workflow_dispatch`
  var, `schedule:` YOK. İleride tekrar gerekirse (ör. birkaç ay sonra yeniden birikirse)
  kullanıcı Actions sekmesinden elle tekrar tetikleyebilir — betiğin/workflow'un kendisi
  KALICI olarak repoda duruyor, tek seferlik kullanılıp silinen bir şey DEĞİL.
- **Doğrulama YAPILAMADI (yerel Node.js yokluğu) — kullanıcının GitHub Actions'tan
  tamamlaması gereken adımlar:**
  1. Actions sekmesi → "Terkedilmiş Anonim Kullanıcıları Temizle" → **Run workflow** →
     `dry_run: true` (varsayılan) ile çalıştır.
  2. Log'u aç, "SİLİNECEK" satırlarını gözden geçir — özellikle KENDİ telefonundaki AKTİF
     kurulumun uid'sinin listede OLMADIĞINDAN emin ol (30 gündür açılmamış olması gerekirdi,
     aktif kullanımda olan bir kurulum bu listede görünmemeli).
  3. Liste doğru görünüyorsa, **Run workflow**'u bu sefer `dry_run: false` ile TEKRAR
     tetikle — bu sefer GERÇEKTEN silinir.

### Push Bildirimi Özel Sesi ([notification_service.dart](lib/services/notification_service.dart), `android/app/src/main/res/raw/zibo_notification.wav`)

- **2026 yeni özellik.** Kullanıcı `assets/sounds/` altına özel bir bildirim sesi (`Zibo
  notification new.wav`) ekledi, push bildirimlerinde (FCM) varsayılan sistem sesi yerine bu sesin
  çalması istendi.
- **Kritik: Android bildirim kanalı sesleri Flutter asset'inden DEĞİL, native `res/raw/`
  kaynağından atanır.** `assets/sounds/`'taki dosya bu özellik için hiç KULLANILMIYOR — Android'in
  kendi bildirim sistemi yalnızca `android.resource://<package>/raw/<isim>` gibi native
  kaynaklara veya `content://` URI'lerine erişebiliyor. Dosya
  `android/app/src/main/res/raw/zibo_notification.wav` olarak KOPYALANDI (orijinali
  `assets/sounds/`'ta da duruyor — **2026 İKİNCİ güncelleme**: `assets/sounds/` klasörü SONRADAN
  Zibo dokunma sesi özelliği için `pubspec.yaml`'ın `flutter: assets:` listesine eklendi, bkz.
  "Zibo Dokunma Sesi" bölümü — bu, o klasördeki `zibo_notification.wav`'ı da bir Flutter asset'i
  haline getirdi ama bu YİNE de bildirim kanalı sesi için KULLANILMIYOR, yalnızca zararsız bir
  yan etki).
  - **Dosya adı yeniden adlandırıldı — Android raw kaynak adlandırma kısıtlaması:** orijinal
    "Zibo notification new.wav" (boşluklu, büyük harfli) Android'in raw kaynak adı kurallarını
    (yalnızca küçük harf, rakam, alt çizgi — `^[a-z0-9_]+$`) İHLAL ediyordu; Gradle bu dosyayı
    `res/raw/` altında görünce derleme hatası verirdi. `zibo_notification.wav` olarak kopyalandı.
  - **Format dönüşümü GEREKMEDİ** — dosya standart PCM WAV (`RIFF ... WAVE audio`), Android
    bildirim sesleri için MP3/WAV/OGG'nin hepsi desteklenir, WAV'ı OGG'ye çevirmeye gerek yoktu.
- **`LocaleNotificationService`'e (bkz. "Bildirimler" bölümündeki mevcut `daily_reminders`
  kanalından AYRI) yeni bir `push_notifications` kanalı eklendi** —
  `AndroidNotificationChannel(sound: RawResourceAndroidNotificationSound('zibo_notification'))`.
  İki kanal BİLEREK ayrı: `daily_reminders` hâlâ rafta olan eski yerel hatırlatma sistemine ait
  (bkz. `notificationsFeatureEnabled`), `push_notifications` yalnızca FCM push bildirimleri için.
- **Kanal, uygulamanın HER başlangıcında erkenden ve koşulsuz oluşturuluyor** —
  `PushNotificationService.initialize()` (her açılışta `main()`'den çağrılıyor, `uid` varsa) artık
  `localNotificationService.initialize(onNotificationTap: () {})`'i FCM izni istemeden ÖNCE
  çağırıyor. **Gerekçe — Android O+'ın kritik bir davranışı:** bir FCM mesajı, henüz cihazda hiç
  oluşturulmamış bir kanala (`android.notification.channel_id`) işaret ederse, bildirim SESSİZCE
  DÜŞÜRÜLÜR (hata fırlatmaz, hiçbir yerde görünmez) — bu yüzden kanalın uygulama arka planda/
  kapalıyken gelen İLK bildirimden bile ÖNCE var olması şart, yalnızca bir bildirim gösterilirken
  "tembel" oluşturmak yetmiyor.
- **Bulunan ve düzeltilen gerçek bir bug — `showNow()` hiçbir zaman `initialize()`'ı
  ÇAĞIRMIYORDU:** `PushNotificationService`, ön plandaki FCM mesajlarını göstermek için
  `NotificationService.showNow()`'ı çağırıyordu, ama eski yerel hatırlatma sistemi kapalı olduğu
  için (`notificationsFeatureEnabled == false`) `RootScreen` hiçbir zaman `NotificationProvider.
  initializeAndSchedule()`'ı çağırmıyor, dolayısıyla `flutter_local_notifications` eklentisinin
  KENDİSİ (`_plugin.initialize()`) hiç başlatılmamış oluyordu — `showNow()` bu durumda `_plugin.
  show()`'u SESSİZCE (try/catch içinde) başarısız kılıyordu, yani **ön planda gelen HİÇBİR FCM
  mesajı hiçbir zaman gösterilmiyordu.** Düzeltme: `showNow()` artık kendi başına `initialize
  (onNotificationTap: () {})`'i (idempotent, `_initialized` bayrağıyla korunuyor) çağırıp emin
  oluyor.
- **`notification-scripts/src/common.js`'deki `sendToUser`'a `android.notification.channelId:
  'push_notifications'` ve `sound: 'zibo_notification'` eklendi** — bu, uygulama ARKA PLANDA/
  KAPALIYKEN OS'in doğrudan gösterdiği bildirimlerin (ön planda `showNow` üzerinden gösterilenlerin
  DIŞINDaki asıl senaryo) doğru kanala (dolayısıyla doğru sese) yönlenmesini sağlıyor —
  channel_id verilmezse Android varsayılan bir kanal kullanır, bu da varsayılan sistem sesi demek.
- **Test:** Ses/kanal atamasının kendisi platform kanalına dokunduğu için `flutter test`'te
  DOĞRULANAMIYOR (mevcut `LocalNotificationService`'in TÜM platform-kanalı metotları zaten try/
  catch'li ve testte sessizce no-op oluyor, bkz. "Bildirimler" bölümündeki genel gerekçe) — gerçek
  doğrulama yalnızca cihazda mümkün, bkz. altta.
- **Gerçek cihazda doğrulama adımları (kullanıcı için):**
  1. Yeni derlenen `app-debug.apk`'yı kur (aşağıdaki "Kurulum" talimatına bakın).
  2. Uygulamayı aç (bu, `PushNotificationService.initialize()`'ı tetikleyip kanalı + FCM token'ını
     kaydeder) — telefon Android 13+ ise bir bildirim izni isteği görmelisin, izin ver.
  3. GitHub Actions'tan (`Actions` sekmesi) herhangi bir bildirim workflow'unu `workflow_dispatch`
     ile elle çalıştır (bkz. "Push Bildirimleri" bölümündeki test talimatları).
  4. Telefonda bildirim gelince (uygulama AÇIK/ön plandayken VEYA kapalıyken/arka plandayken)
     **özel Zibo sesinin** çaldığını, varsayılan sistem "ping" sesinin ÇALMADIĞINI doğrula.
  5. **Eğer hâlâ varsayılan ses çalıyorsa:** Ayarlar > Uygulamalar > Zibo > Bildirimler > "Push
     Bildirimleri" kanalına gir, kanalın sesinin gerçekten "Zibo" (ya da benzer bir isim) olarak
     ayarlı olduğunu kontrol et. **Önemli Android davranışı:** bir bildirim kanalı BİR KEZ
     oluşturulduktan sonra, uygulama kodundaki sesi/ayarları DEĞİŞTİRMEK kanalı GÜNCELLEMEZ — eğer
     bu APK'dan ÖNCE zaten bir `push_notifications` kanalı oluşmuşsa (olası değil, bu kanal bu
     arc'ta YENİ eklendi, ama ihtimal dahilinde) uygulamayı TAMAMEN kaldırıp yeniden kurmak
     (yalnızca yeniden derlemek YETMEZ) gerekebilir — bu, Android'in kanal sistemine özgü, kod
     tarafından atlatılamayan bir kısıtlama.
- **2026 İKİNCİ güncelleme — 4 bildirim türünün TÜMÜ tek sese/kanala bağlı olduğu doğrulandı,
  KOD DEĞİŞİKLİĞİ GEREKMEDİ.** Kullanıcı isteği: "Günlük Motivasyon/Streak Hatırlatması/Günlük
  Ödül Hatırlatması/Geri Kazanma bildirimlerinin HEPSİ aynı `zibo_notification.wav` sesini
  çalsın." İnceleme sonucu: `notification-scripts/src/*.js`'teki 4 betiğin (`dailyMotivation.js`,
  `streakReminder.js`, `dailyRewardReminder.js`, `reEngagement.js`) HEPSİ ZATEN `common.js`'teki
  TEK bir paylaşılan `sendToUser(...)` fonksiyonunu çağırıyordu (bkz. "Push Bildirimleri"
  bölümü) — `channelId: 'push_notifications'`/`sound: 'zibo_notification'` bu TEK fonksiyonda
  bir önceki oturumda zaten ayarlanmıştı, dolayısıyla 4 türün hepsi otomatik olarak AYNI kanala/
  sese bağlıydı. Bu istek, bir önceki arc'ta zaten tam olarak tamamlanmış bir işin
  DOĞRULANMASIYDI — hiçbir dosya değişmedi.
- **2026 ÜÇÜNCÜ güncelleme — kullanıcı raporu: gerçek cihazda özel ses HİÇ çalmıyor, varsayılan
  sistem sesi geliyor.** Kod tekrar incelendi — `push_notifications` kanalının oluşturma kodu
  (`LocalNotificationService.initialize()`) VE `zibo_notification.wav` dosyası (`android/app/
  src/main/res/raw/`) ikisi de doğru/eksiksiz. **Teşhis — bu yukarıdaki "Önemli Android
  davranışı" notunda BAHSEDİLEN, o zaman "olası değil ama ihtimal dahilinde" diye işaretlenmiş
  senaryonun TAM OLARAK gerçekleştiği durum:** kullanıcının cihazında Ayarlar > Uygulamalar >
  Zibo > Bildirimler > "Push Bildirimleri" kanalı kontrol edildiğinde ses "Varsayılan" görünüyordu
  — yani bu kanal, ses doğru şekilde bağlanmadan ÖNCEki bir APK sürümünde (bu proje boyunca aynı
  cihaza onlarca kez kurulup kaldırılmıştı) zaten oluşmuş ve Android'e "yapışmış". **Kod
  tarafında YAPILACAK HİÇBİR ŞEY YOK** — çözüm KESİNLİKLE uygulamayı cihazdan TAMAMEN kaldırıp
  (yalnızca `adb install -r` ile üzerine kurmak YETMEZ) yeniden kurmak, bu Android'in kanal
  sistemine özgü, programatik olarak atlatılamayan bir kısıtlama. **Bu ders genelleştirilebilir:**
  bir bildirim kanalının sesi/adı/açıklaması ile ilgili "kod doğru ama cihazda çalışmıyor"
  raporu alındığında, İLK yapılacak şey kodu şüphelenmek DEĞİL, kullanıcıdan cihazın Ayarlar
  uygulamasında o kanalın GERÇEKTE ne gösterdiğini sormak — kanal zaten yanlış konfigürasyonla
  cihaza kaydolmuşsa hiçbir kod değişikliği bunu düzeltmez, yalnızca kaldır+yeniden kur düzeltir.
- **2026 DÖRDÜNCÜ güncelleme — kaldır+yeniden kurulumdan SONRA bulunan, AYRI bir kafa karıştırıcı
  durum: Android bildirim ayarlarında İKİ kanal görünüyordu.** Yeniden kurulum "Push Bildirimleri"
  kanalının sesini düzeltti (ÖNCEKİ madde), ama kullanıcı Ayarlar'da BİR DE **"Günlük
  Hatırlatmalar"** adında, "Varsayılan" ses gösteren İKİNCİ bir kanal olduğunu fark etti — bu,
  push bildirimleriyle İLGİSİZ, `notificationsFeatureEnabled = false` ile rafa kaldırılmış ESKİ
  yerel hatırlatma sisteminin kanalı (bkz. "Bildirimler" bölümü). **Kök neden:**
  `LocalNotificationService.initialize()` HER İKİ kanalı da (push + eski yerel) KOŞULSUZ
  oluşturuyordu — `PushNotificationService.initialize()` her uygulama açılışında bu metodu
  çağırdığı için, özellik devre dışı olsa bile `daily_reminders` kanalı yine de Android'e
  kaydoluyordu, yalnızca hiçbir zaman KULLANILMIYORDU (zararsız ama kafa karıştırıcı — kullanıcı
  hangisinin "gerçek" motivasyon kanalı olduğunu ayırt edemedi). **Düzeltme:** `notificationsFeatureEnabled`
  sabiti dairesel import olmadan hem `NotificationProvider` hem `NotificationService` tarafından
  okunabilsin diye YENİ [notification_config.dart](lib/config/notification_config.dart) dosyasına
  taşındı (`notification_provider.dart` geriye dönük uyumluluk için onu `export` ediyor, mevcut
  importlar DEĞİŞMEDİ); `daily_reminders` kanalının oluşturulması artık `if
  (notificationsFeatureEnabled)` ile SARILI — özellik kapalıyken bu kanal ARTIK HİÇ oluşmuyor,
  yeniden etkinleştirilirse bir sonraki `initialize()` çağrısında (her açılış) otomatik geri
  gelir. **Ders:** iki BAĞIMSIZ özelliğin (aktif push sistemi + rafa kaldırılmış eski yerel
  sistem) altyapı kurulumunu (`initialize()`) TEK bir metotta birleştirmek, birinin "kapalı"
  durumunun diğerinin yan etkilerini (burada: kullanılmayan bir Android kanalının kalıcı olarak
  cihaza kaydolması) engellemeyebilir — her alt kurulum adımı kendi özelliğinin açık/kapalı
  bayrağına göre AYRI AYRI kapılanmalı.
- **2026 BEŞİNCİ güncelleme — ASIL kök neden bulundu: `res/raw/zibo_notification.wav`
  RELEASE APK'DAN TAMAMEN SİLİNMİŞTİ (kaynak küçültücü tarafından).** Yukarıdaki İKİ düzeltmeden
  (kanal önbelleği + ölü ikinci kanal) SONRA bile kullanıcı sesin HÂLÂ çalmadığını bildirdi —
  kanal Ayarlar'da doğru isimle ("zibo_notification") görünmeye devam ediyordu ama gerçek çalma
  anında HİÇBİR ses çıkmıyordu. Sistemli bir şekilde elenen ihtimaller: (1) ses dosyasının
  kendisi sessiz/bozuk mu? — PowerShell ile `.wav`'ın PCM örneklerini elle okuyup tepe genliğini
  ölçtük (%100, sağlıklı), DEĞİL; (2) kullanıcının yeni eklediği `assets/sounds/
  zibo_notification_new.wav` farklı bir dosya mı? — `md5sum` ile karşılaştırıldı, mevcut
  `res/raw/zibo_notification.wav` ile BİREBİR AYNI, DEĞİL; (3) `adb uninstall`in SESSİZCE
  başarısız olup (`DELETE_FAILED_INTERNAL_ERROR`) eski/bozuk kanalın kalıntısını bırakmış olması
  mı? — telefonun KENDİ arayüzünden (adb değil) kaldırılıp `adb shell pm list packages` ile
  paketin GERÇEKTEN gittiği doğrulandıktan sonra tertemiz yeniden kurulum yapıldı, DEĞİL (sorun
  aynen devam etti). **Asıl kanıt — derlenen release APK'nın kendisi `aapt2 dump resources` ile
  incelendi:** `raw/zibo_notification` kaynağı APK'da HİÇ YOKTU (yalnızca AGP'nin kendi
  ürettiği, boş bir `raw/keep` girdisi vardı) — **kaynak küçültücü (`isShrinkResources = true`,
  bkz. "Release İmzalama" bölümü) dosyayı "kullanılmıyor" sanıp APK'dan SİLMİŞTİ.** Kök neden:
  `flutter_local_notifications`'ın `RawResourceAndroidNotificationSound('zibo_notification')`'ı
  bu kaynağa yalnızca ÇALIŞMA ZAMANINDA bir METİN İSMİYLE (platform kanalı üzerinden) referans
  veriyor — Java/Kotlin/XML'de statik bir `R.raw.zibo_notification` referansı YOK, bu yüzden
  kaynak küçültücünün statik kullanım analizi bu dosyayı hiç "görmüyor" ve güvenle silinebilir
  sanıyor. **Kanal OLUŞTURMA kodu bu yüzden hiç hata VERMİYORDU** (yalnızca bir Uri/isim
  kaydediyor, dosyanın var olup olmadığını kontrol etmiyor) — hata yalnızca gerçek ÇALMA anında,
  sessizce ortaya çıkıyordu. **Düzeltme — Android'in resmi/standart mekanizması:**
  [android/app/src/main/res/raw/keep.xml](android/app/src/main/res/raw/keep.xml) (YENİ) eklendi:
  ```xml
  <resources xmlns:tools="http://schemas.android.com/tools"
      tools:keep="@raw/zibo_notification" />
  ```
  Bu, küçültücüye bu KAYNAĞA DOKUNMAMASINI açıkça söylüyor. **Doğrulama İKİ aşamalı yapıldı:**
  önce statik olarak, `aapt2 dump resources` ile yeniden derlenen APK'da `raw/zibo_notification`'ın
  artık GERÇEKTEN var olduğu teyit edildi; sonra gerçek cihazda kurulup **kullanıcı bildirim
  sesinin GERÇEKTEN çaldığını doğruladı** — sorun KALICI olarak çözüldü. **Ders — genelleştirilebilir
  bir Android/R8 kalıbı:** bir
  native platform eklentisinin (herhangi bir Flutter eklentisi) bir Android kaynağına yalnızca
  bir STRING/isim üzerinden ÇALIŞMA ZAMANINDA referans verdiği HER durumda (raw ses/video
  dosyaları, drawable'lar vb. — `R.xxx.yyy` gibi statik bir Java/Kotlin/XML referansı yerine),
  release build'de kaynak küçültme AÇIKSA (`isShrinkResources = true`) bu kaynak SESSİZCE
  silinme riski taşır — kanıt/hata YOK, yalnızca çalışma zamanında sessiz bir eksiklik. Bu tür
  bir kaynak eklerken PROAKTİF olarak `res/raw/keep.xml`'e (veya ilgili kaynak türü için
  benzerine) eklemek, sorunu TESPİT ETMEK için saatler harcamaktan çok daha ucuz.

### Zibo Dokunma Sesi ([sound_effects_service.dart](lib/services/sound_effects_service.dart), [sound_effects_provider.dart](lib/providers/sound_effects_provider.dart), `assets/sounds/zibo_tap_new.wav`)

- **2026 yeni özellik.** Kullanıcı `assets/sounds/zibo_tap_sound.wav` ekledi, Ana Sayfa'da Zibo'ya
  her dokunuşta (mevcut poz/söz değişim animasyonuyla AYNI anda) bu sesin çalmasını istedi —
  art arda hızlı dokunuşlarda seslerin üst üste binmemesi ve Ayarlar'da bir "Ses Efektleri"
  anahtarına bağlı olması şartıyla.
- **2026 İKİNCİ güncelleme — ses dosyası değiştirildi.** Kullanıcı `zibo_tap_sound.wav`'ı iptal edip
  yerine `zibo_tap_new.wav`'ı ekledi — `AudioPlayersSoundEffectsService.playZiboTap()`'teki
  `AssetSource(...)` yolu güncellendi, eski dosya `assets/sounds/`'tan SİLİNDİ (artık hiçbir yerde
  referans edilmiyor). Mekanizmanın kendisi (stop+play, `SoundEffectsProvider`, `HomeScreen`
  enjeksiyonu) HİÇ değişmedi — yalnızca hangi ses dosyasının çalındığı değişti.
- **`audioplayers: ^6.0.0`** (pubspec.yaml, `flutter pub get` ile `6.8.1`'e çözüldü) — projede
  daha önce hiçbir ses ÇALMA paketi yoktu (yalnızca `flutter_local_notifications`'ın kendi dahili
  ses mekanizması vardı, bkz. yukarıdaki "Push Bildirimi Özel Sesi" bölümü — bu TAMAMEN AYRI bir
  ihtiyaç, native bildirim kanalı değil, uygulama İÇİNDE anlık bir ses efekti). `assets/sounds/`
  klasörü `pubspec.yaml`'ın `flutter: assets:` listesine eklendi (önceden yalnızca
  `assets/images/` vardı) — `AudioPlayer.play(AssetSource(...))` Flutter asset bundle'ından
  okuduğu için (native `res/raw/`'dan DEĞİL, bkz. yukarıdaki bildirim sesi bölümündeki AYNI ayrım
  ama TERSİ yönde) bu adım gerekliydi.
- **`SoundEffectsService`** (`AdService`/`NotificationService` ile AYNI "gerçek + fake, testte
  enjekte edilebilir" desen — `audioplayers` da bir platform kanalı kullandığı için
  `flutter_local_notifications` gibi `flutter_test`'te doğrudan kullanılamaz):
  - `AudioPlayersSoundEffectsService` — tek bir `AudioPlayer` örneği (`ReleaseMode.stop`).
    `playZiboTap()` her çağrıldığında ÖNCE `_player.stop()` SONRA `_player.play(AssetSource
    ('sounds/zibo_tap_new.wav'))` çağırıyor — kullanıcının "art arda hızlı tıklamalarda önceki
    sesi kesip yeniden başlat" isteği bu TEK `stop()`+`play()` çiftiyle karşılanıyor, ayrı bir
    debounce zamanlayıcısına gerek KALMADI (daha basit, daha az durum yönetimi).
  - `FakeSoundEffectsService` — `const`, no-op (diğer Fake* servislerle AYNI desen).
- **`SoundEffectsProvider`** — `ThemeProvider` ile BİREBİR AYNI Varyant C (`CloudStateStore`, tek
  bool, `{'value': ...}` sarmalı) deseni; `enabled` varsayılan `true`. Bilerek genel/soyut
  isimlendirildi ("Ses Efektleri", tekil "Zibo dokunma sesi" DEĞİL) — şu an tek bir ses efekti
  kontrol ediyor olsa da, ileride başka UI ses efektleri (ör. coin kazanma sesi) eklenirse AYNI
  anahtarı paylaşabilsin diye.
- **`HomeScreen`'e enjeksiyon** — `RootScreen.pushNotificationService` ile AYNI desen:
  `HomeScreen({this.soundEffectsService})` opsiyonel bir constructor parametresi (varsayılan
  gerçek `AudioPlayersSoundEffectsService()`), `_HomeScreenState` bunu `late final` bir alanda
  tutup `dispose()`'ta serbest bırakıyor. `_onZiboTap()` (poz/söz değişiminin olduğu AYNI metot)
  artık `context.read<SoundEffectsProvider>().enabled` kontrolünden geçerse
  `_soundEffectsService.playZiboTap()`'i de çağırıyor — poz/söz değişimiyle TAM OLARAK aynı anda
  tetikleniyor (kullanıcının açık isteği).
  - **Yalnızca Ana Sayfa'da — kapsam bilinçli olarak dar tutuldu.** Kullanıcı "Zibo'nun
    tıklanabilir olduğu diğer yerlerde de" dedi, ama incelemede diğer 7 modül ekranının HİÇBİRİNDE
    Zibo görseli tıklanabilir DEĞİL (`GestureDetector`/`onTap` yok, bkz. "Zibo Poz/Animasyon
    Sistemi" bölümü — yalnızca Ana Sayfa'nın `_onZiboTap`'i poz/söz ilerletiyor) — bu yüzden
    şu an fiilen yalnızca Ana Sayfa'da ses çalıyor, kapsam eksiksiz. **İleride başka bir ekranda
    Zibo tıklanabilir hale getirilirse, aynı `_soundEffectsService.playZiboTap()` deseni oraya da
    eklenmeli.**
- **Ayarlar'a yeni "Ses Efektleri" anahtarı** — `settings_screen.dart`'taki "Genel" kartında,
  "Koyu Tema" satırının HEMEN ALTINDA (`Icons.volume_up_outlined`, yeni `settingsSoundEffects`
  ARB anahtarı, TR/EN/ES üçünde de eklendi). Kart artık ÜÇ satır (Koyu Tema/Ses Efektleri/Dil) —
  bu, `settings_screen.dart`'ın "yeni içerik eklerken altındaki testler `scrollUntilVisible`
  gerektirebilir" gotcha'sını (bkz. "Test kalıpları" bölümü) TEKRAR tetikledi: "Gizlilik
  Politikası"/"Kullanım Koşulları" testindeki `tester.tap(find.text(...))` çağrıları artık
  hit-test uyuşmazlığı yaşıyordu (kaydırma sonrası satır AppBar'a çok yakın kalıyordu) —
  `tester.widget<ListTile>(...).onTap!()` ile DOĞRUDAN çağrıya çevrildi (GridView/hit-test
  uyuşmazlığı deseniyle AYNI çözüm, bkz. "Test kalıpları").
- **Test:** YENİ `test/sound_effects_provider_test.dart` (`ThemeProvider` testleriyle AYNI desen:
  varsayılan açık, `setEnabled` hem durumu hem kalıcı depoyu günceller, yeniden başlatmada
  hatırlanır) + YENİ `test/home_screen_sound_test.dart` (`manifest_journal_screen_test.dart`'taki
  "bağımsız test uygulaması + sahte servis enjeksiyonu" deseniyle: Ses Efektleri açıkken Zibo'ya
  dokununca `playZiboTap` çağrılır, kapalıyken ÇAĞRILMAZ). **Gotcha (tekrar yaşandı):**
  `Image.asset()` providers boot olduktan hemen sonra yükseklik=0 raporlayıp `tester.tap()`'in
  hit-test'ini şaşırtabiliyor (bkz. "Test kalıpları" bölümündeki aynı gotcha) — çözüm yine
  `pumpAndSettle()`'dan sonra `tester.runAsync(() => Future.delayed(Duration(milliseconds:
  100)))` + bir `pumpAndSettle()` daha. `widget_test.dart`'ın `_buildAppWithClock()`'una da
  `SoundEffectsProvider` eklendi (RootScreen'in ihtiyaç duyduğu HER provider kuralı, bkz. "Test
  kalıpları").
- **Gerçek cihazda doğrulama:** APK yeniden derlenip telefona kurulup çöküş izi olmadan açıldığı
  doğrulandı (`adb shell monkey`/`pidof`) — sesin GERÇEKTEN duyulup duyulmadığı (ve Ayarlar'daki
  anahtarın gerçekten sesi açıp kapattığı) kullanıcının kendi cihazında dinleyerek doğrulaması
  gerekiyor, bu arc'ta yalnızca kod seviyesinde (`flutter test`, 244 test) doğrulandı.
- **2026 ÜÇÜNCÜ güncelleme — üç YENİ ses efekti: coin kazanma, coin satın alma, hedef tamamlama.**
  Kullanıcı isteği (verbatim özet): `zc_reward.wav` coin kazanılan HER senaryoda (check-in, günlük
  görev, streak bonusu, çark, günlük giriş ödülü, reklam karşılığı coin, su/şükran/manifest
  hedefleri), `zc_buy.wav` Mağaza'dan gerçek para karşılığı coin paketi satın alınca, `zibo_target.
  wav` Hedef Takibi'nde bugünün kutucuğu işaretlenince (bkz. altta "Hedef Tamamlama Kutlaması"
  bölümü) çalsın. `SoundEffectsService`'in kapsamı yukarıdaki "yalnızca Zibo dokunma sesi"
  yorumundan TAM OLARAK öngörüldüğü gibi genişletildi (bkz. `SoundEffectsProvider`'ın "ileride
  başka ses efektleri eklenirse AYNI anahtarı paylaşsın" notu — GERÇEKTEN öyle oldu, tek "Ses
  Efektleri" anahtarı hepsini birden açıp kapatıyor, ayrı bir anahtar EKLENMEDİ).
  - **`SoundEffectsService`'e üç yeni soyut metot eklendi:** `playCoinReward()`, `playCoinPurchase()`,
    `playGoalComplete()` — `playZiboTap()` ile AYNI imza deseni. `AudioPlayersSoundEffectsService`
    içindeki tekrarlı stop+play mantığı ortak bir `_play(String assetPath)` yardımcı metoduna
    çıkarıldı (dört genel metot da bunu çağırıyor) — TEK bir `AudioPlayer` örneği hâlâ yeterli
    çünkü her tüketici (`HomeScreen`, `CoinProvider`, `GoalTrackingScreen`) KENDİ AYRI
    `SoundEffectsService` örneğini oluşturuyor (bkz. altta), farklı bağlamlardaki sesler
    birbirini KESMİYOR.
  - **`CoinProvider`'a `SoundEffectsService`/`bool Function() isSoundEnabled` enjeksiyonu** —
    `CoinProvider` bir widget OLMADIĞI için `HomeScreen`'in yaptığı gibi doğrudan
    `context.read<SoundEffectsProvider>()` çağıramıyor; `now: DateTime Function()` (`TrustedTimeProvider`
    için) ile AYNI enjekte edilebilir callback deseni `isSoundEnabled` için de kullanıldı.
    `main.dart`'ta `SoundEffectsProvider` artık `CoinProvider`'dan ÖNCE listelendi (`MultiProvider`
    listesinde ÖNCEKİ provider'lar SONRAKİlerin `context`'inden görünür olduğu için —
    `TrustedTimeProvider`'ın EN BAŞTA olma gerekçesiyle AYNI) — `CoinProvider`'ın `create` callback'i
    `() => context.read<SoundEffectsProvider>().enabled` geçiriyor.
  - **Merkezi tetikleme noktası — `_earn()`.** `CoinProvider._earn(int amount, String reason,
    {bool playRewardSound = true})` artık `playRewardSound && _isSoundEnabled()` iken
    `playCoinReward()` çalıyor — bu, `_earn()`'ün ZATEN TÜM kazanma mekaniklerinin (yukarıdaki
    kullanıcı listesinin tamamı) TEK geçiş noktası olması sayesinde HİÇBİR `earn*` metoduna elle
    ses çağrısı eklemeden otomatik olarak kapsandı. **TEK istisna — `purchaseCoinPackage()`:**
    `_earn(..., playRewardSound: false)` ile "kazanma" sesini BASTIRIP hemen ardından KENDİ ayrı
    `playCoinPurchase()`'ini çalıyor — "kazanma" ile "satın alma" arasında işitsel bir ayrım olsun
    diye kasıtlı.
  - **`CoinProvider.dispose()` eklendi** — `_soundEffectsService.dispose()` çağırıyor (önceden
    `CoinProvider`'ın hiç `dispose()` override'ı yoktu).
  - **Test:** `coin_provider_test.dart`'a YENİ `_RecordingSoundEffectsService` + "CoinProvider -
    kazanma/satın alma sesleri" grubu (3 test: kazanma mekanikleri `playCoinReward` çalar
    `playCoinPurchase` ÇALMAZ; satın alma tersi; `isSoundEnabled: () => false` iken HİÇBİRİ
    çalmaz).
- **2026 DÖRDÜNCÜ güncelleme — üç YENİ ses efekti: kostüm satın alma, tema satın alma, su damlası.**
  Kullanıcı `assets/sounds/` klasörüne üç yeni dosya ekledi: `zibo_costume_buy.wav` (Mağaza'da bir
  kostüm satın alınca), `theme_buy.wav` (bir tema satın alınca — kostümden BİLEREK AYRI bir ses,
  kullanıcının açık isteği), `water_drop.wav` (Su Takibi'nde bir bardak/şişe dolum kutucuğuna
  dokunup su içildiği işaretlenince, dolma animasyonuyla EŞ ZAMANLI). Hepsi mevcut "Ses Efektleri"
  anahtarına bağlı (`SoundEffectsProvider.enabled`) ve mevcut stop+play deseni sayesinde üst üste
  binmiyor — yeni bir mimari GEREKMEDİ, yalnızca mevcut `SoundEffectsService` sözleşmesine üç yeni
  metot eklendi.
  - **`SoundEffectsService`'e üç yeni soyut metot: `playCostumeBuy()`, `playThemeBuy()`,
    `playWaterDrop()`** — `playCoinReward()`/`playCoinPurchase()`/`playGoalComplete()` ile AYNI
    imza deseni, `AudioPlayersSoundEffectsService` içindeki ortak `_play(String assetPath)`
    yardımcısını çağırıyor (stop+play, üst üste binmeyi engelliyor). `FakeSoundEffectsService`'te
    üçü de no-op.
  - **`CoinProvider.spendOnCostume`/`spendOnTheme`** artık harcama BAŞARILI olduğunda (yetersiz
    bakiye durumunda `_spend` `false` döndüğü için ses HİÇ çalınmıyor) kendi sesini çalıyor —
    `playCoinReward`'ın aksine bunlar `_earn()`'ün merkezi ses yoluna GİRMİYOR (bunlar birer
    HARCAMA, kazanma değil), `spendOnCostume`/`spendOnTheme` gövdelerinde doğrudan
    `_soundEffectsService.playCostumeBuy()`/`playThemeBuy()` çağrılıyor (ikisi de
    `_isSoundEnabled()` kontrolünden geçtikten sonra).
  - **`WaterTrackingScreen`** yeni bir opsiyonel `soundEffectsService` constructor parametresi
    kazandı (`HomeScreen`/`GoalTrackingScreen` ile AYNI test-injection deseni, varsayılan gerçek
    `AudioPlayersSoundEffectsService()`). `_tapGlass` yalnızca ARTIŞ (bardağı/şişeyi DOLDURMA)
    dalında `playWaterDrop()` çağırıyor, azaltma (geri alma/undo) dalında ÇAĞIRMIYOR — kullanıcının
    "kullanıcı... su içtiğini işaretlediğinde çalsın" isteğiyle birebir örtüşüyor.
  - **Test:** `coin_provider_test.dart`'ın "kazanma/satın alma sesleri" grubuna 3 yeni test eklendi
    (kostüm satın alma sesi çalar, tema satın alma sesi çalar, yetersiz bakiyede İKİSİ de
    çalmaz) + mevcut "isSoundEnabled false" testi kostüm/tema seslerinin de susturulduğunu
    doğruyacak şekilde genişletildi. YENİ `test/water_tracking_sound_test.dart` (Ses Efektleri
    açıkken bir birim işaretlenince `playWaterDrop` çağrılır) — `find.byIcon(Icons.
    water_drop_outlined)`/`find.byIcon(Icons.water_drop)` ile bulunuyor (`_WaterGlass` yalnızca
    ikon render ediyor, görünür bir sayı metni YOK — `find.text('1')` gibi bir finder işe
    yaramaz). `goal_completion_celebration_test.dart`/`home_screen_sound_test.dart`'taki yerel
    `_RecordingSoundEffectsService` sınıflarına da (bu dosyalar kostüm/tema/su sesini test
    ETMİYOR ama Dart'ın soyut sınıf sözleşmesini karşılamak için) üç yeni metodun no-op override'ı
    eklendi.
  - **Test suite'i tam yeşil:** 262/262 geçti.

