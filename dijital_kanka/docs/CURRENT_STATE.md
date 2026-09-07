# Zibo — Şu Anki Durum

Bu dosya projenin **ŞU ANKİ GERÇEĞİNİ** anlatır — changelog DEĞİL. Bir şey değiştiğinde bu dosya
GÜNCELLENİR (eski gerçek `docs/history/`'ye gitmez, sadece buradaki cümle değişir).

Son güncelleme bağlamı: sürüm `1.8.1+25`, `flutter test` ~530 test yeşil (+1 belgelenmiş flake).

---

## Platform & dağıtım

- **Yalnızca Android.** iOS yapılandırması yok (`FirebaseOptions` elle verilmemiş — web/iOS'ta Firebase sessizce devre dışı).
- **Play Console**: "ZiboDk" kişisel hesabı altında "Zibo" uygulaması var. İlk sürüm Internal testing'e yüklendi. Ödeme profili dolduruldu, doğrulama bekliyor.
- Release build imzalı (`android/upload-keystore.jks` + `android/key.properties`, ikisi de `.gitignore`'da). **Play App Signing aktif** — Google APK'yı KENDİ anahtarıyla yeniden imzalar.
- **AAB üretimi**: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`. Her yüklemede `pubspec.yaml` `+N` artırılmalı. Prosedür → `.claude/skills/release-aab/`.

## Kimlik doğrulama

- **Firebase Anonymous Auth** varsayılan — her cihaz otomatik bir `uid` alır, `SharedPreferences`'ta kalıcı.
- **Google Sign-In linking** aktif: kullanıcı anonim hesabını Google'a bağlayabilir (`linkWithCredential`, aynı uid korunur), başka cihazda aynı hesapla giriş yapıp verisini kurtarabilir. Ayarlar'da "Çıkış Yap" / "Hesap Değiştir" butonları (yalnızca bağlıyken görünür).
- **Bilinen açık sorun**: Google ile giriş bazı gerçek kullanıcılarda çalışmıyordu. Kök neden zincirinin SON halkası: `google-services.json`'a Play App Signing Key SHA-1'i (`EB:AA:2E:93:01:06:D6:DB:54:1D:9A:BC:53:7D:B4:9A:61:F3:CF:32`) eklendi ve dosya güncellendi (4 cert hash var) — **ama bu düzeltme henüz yeni bir sürüme paketlenip Play'e yüklenmedi.** Kullanıcı güncellemeyi alınca doğrulanmalı. Detaylı zincir → `docs/history/backend-auth-security-referral.md`.

## Backend / veritabanı

- **Firestore (Spark / ücretsiz plan).** Cloud Functions / Blaze **YOK** — bilinçli karar (`docs/decisions/`). Zamanlanmış işler GitHub Actions + `firebase-admin` ile.
- `firestore.rules` elle yönetilir — Console > Firestore > Rules'a TAM içerik yapıştırılır (üzerine EKLEME değil). Otomatik deploy yok.
- Kullanıcının Console'da tamamlaması gereken (belki yapıldı, doğrulanmalı): Firestore DB oluşturma, Anonymous + Google auth açma, güncel rules yayınlama, `founderBadgeStatus/status` seed (`init-founder-badge-counter.yml`, `dry_run: false` — asistan bu production yazımını tetikleyemez, kullanıcı elle yapar).

## Para kazanma

- **Reklam: Appodeal mediation** (`stack_appodeal_flutter`). Yalnızca rewarded + interstitial.
  - Dolgu: Appodeal kendi (IAB/Bidon) + AppLovin + BidMachine (Appodeal varsayılan hesabı üzerinden).
  - Unity Ads adaptörü `android/app/build.gradle.kts`'te HAZIR ama Appodeal Console "Store URL required" (uygulama Play'de yayında olunca 24 saatte otomatik doğrulanır) yüzünden Console'da OFF.
  - **AdMob geçmişi**: eski AdMob hesabı Google tarafından devre dışı bırakıldı ("ilişkili hesap"), itiraz gönderildi, sonuç belirsiz. Appodeal'e geçiş bu yüzden. `google_mobile_ads` paketi tamamen kaldırıldı.
- **IAP: Google Play Billing** (`in_app_purchase`), 5 tüketilebilir coin paketi (`coins_100`…`coins_10000`), Play Console'da oluşturuldu.
  - **AÇIK GÜVENLİK BOŞLUĞU**: satın alma makbuzu sunucu tarafında (Google Play Developer API) doğrulanmıyor — istemcinin "purchased" durumuna güveniliyor. Tam çözüm Cloud Functions/backend gerektirir (Blaze kararı bekliyor). Launch öncesi ele alınmalı.
- **Zibo ADS** ("reklamsız deneyim") = tamamen GÖRSEL MOCKUP. Gerçek satın alma yok, "Yakında" SnackBar'ı.

## Yerel bildirimler

- **`flutter_local_notifications` tabanlı zamanlanmış hatırlatmalar RAFTA** — `lib/config/notification_config.dart`'taki `notificationsFeatureEnabled = false`. Sebep: MIUI/OEM arka plan kısıtlamaları yüzünden zamanlanmış bildirimler gelmiyor, kod içinden atlatılamıyor. Provider/servis kodu SAĞLAM — tek yapılması gereken flag'i `true` yapmak.
- Ayarlar'daki bildirim ayar kartı + debug paneli bu flag'le gate'li.

## FCM Push bildirimleri (AYRI sistem, aktif)

- 5 zamanlanmış iş: `daily-motivation` (günde 4 hedef saat), `streak-reminder`, `daily-reward-reminder`, `re-engagement`, `water-reminder`. Hepsi `.github/workflows/*.yml` — **saatlik** cron, her betik kullanıcının KENDİ saat dilimindeki hedef saate + catch-up penceresine göre gönderir.
- Dil: `notification-scripts/src/content.js` (TR/EN/ES). Kullanıcı dili `users/{uid}/state/languageCode`'dan.
- Kullanıcı opt-out'u YOK (Ayarlar kartı kaldırıldı) — herkes 4 türün hepsini alır.
- Özel bildirim sesi `zibo_notification.wav` (`res/raw/`, `keep.xml`'de korunuyor).
- Ayrı bir bakım işi: `cleanup-stale-anonymous-users.yml` (yalnızca elle, `dry_run` varsayılan `true`).
- **Kurulum ön koşulu**: GitHub Secret `FIREBASE_SERVICE_ACCOUNT_JSON` (Firebase Console > Service accounts > yeni private key).

## Tamamlanmış feature'lar (kod tarafı çalışıyor)

Ana Sayfa (zaman/ruh-hali ağırlıklı motivasyon sözü sistemi + olay-tetiklemeli mesajlar) · Konuşma Balonu (favori/paylaş butonları) · Hedef Takibi (7 günlük döngü, kalıcı geçmiş, "Tamamlanan Hedefler" ekranı, ardışık gün numaraları, haftalık coin farming koruması) · Zibo Coin ekonomisi · Mağaza (5 coin paketi + Kostümler + Temalar segmentleri, gerçek TL fiyatları) · 16 Kostüm · 22 Tema (15 statik + 7 premium/animasyonlu) · Zibo Poz/Animasyon sistemi (dokunuşla ilerleyen, 8 ekranda senkron) · Şans Çarkı (günlük 3 çevirme sınırı) · Günlük Giriş Ödülleri (7 gün) · Para ve Birikim (3 kategori, çoklu para birimi, fl_chart trend grafiği) · Ayarlar (3 bölüm, Görünüm=Açık/Koyu/Sistem, Ses Efektleri, Dil, gerçek Gizlilik/Kullanım metinleri) · Zibonu Paylaş (9:16 kart, 8 gradyan + 5 font ön ayarı) · Alt Gezinme Çubuğu (kod-tabanlı) · Rüya/Şükran/Ruh Hali/Su/Manifest Günlükleri · Profil ("İstatistiklerim" 4 kategori + dairesel gauge animasyonu, "Zibo ile Bağın" 8 satır, "Geçmiş Ay İstatistikleri" arşivi) · Açılış splash + Onboarding · Level/XP sistemi · Odak Sayacı (immersive karanlık mod) · Instagram Takip Kartı · Davet Et (referral) · Kurucu Üye Rozeti (Google'a bağlanan ilk 500) · Ana Ekran Widget'ları (5) · **Rozet Sistemi — 6 kategori tamamlandı** (İstikrar 5 / Modül Ustalığı 6 / Koleksiyon 4 / Sadakat 3 / Sosyal 3 / Gizli 3 = 24 rozet, otomatik tetikleme + konfeti kutlaması + ZC ödülü + 9 rozette kostüm/tema hediye) · ses efektleri (8 tür) · Crashlytics.

## Bilinen sorunlar / teknik borç

| Konu | Durum |
|---|---|
| Google Sign-In gerçek kullanıcılarda | Firebase'e App Signing SHA-1 eklendi; yeni sürüm yayınlanınca doğrulanmalı |
| IAP makbuz doğrulaması | Sunucu tarafı YOK — launch öncesi Cloud Functions gerekir (Blaze) |
| Coin ekonomisi | Client-authoritative — `firestore.rules` yalnızca "hız engelleyici". Sürdürülen scripted saldırıya açık. Tam çözüm Blaze |
| Kostüm/tema `ownedIds` | Firestore'da korumasız (istemci ödemeden ID ekleyebilir) — bilinçli kabul |
| Ana Ekran Widget'ları — uygulama içi "Ekle" | MIUI launcher `requestPinAppWidget`'ı sessizce no-op yapıyor → UI artık "Ekle iddiası" yerine 3 adımlı manuel talimat sheet'i gösteriyor |
| Widget picker önizlemesi | `previewImage` PNG'leri üretildi; gerçek launcher'da GÖRSEL doğrulama tamamlanmadı |
| Yerel zamanlanmış bildirimler | Rafta (`notificationsFeatureEnabled = false`) — OEM kısıtlaması |
| Fotoğraflar (profil/manifest) | Yalnızca cihazda yerel; hesap değişince "kırık" olur → `reconcileMissingPhotos` temizler. Firebase Storage entegrasyonu Blaze gerektiriyor, yapılmadı |
| `flutter analyze` | Bu makinede çöküyor — kullanma |
| `audioplayers`/`home_widget` test flake'i | "Zibo'ya dokununca söz değişir" testi platform-kanalı `MissingPluginException` sızıntısı — bu değişikliklerle ilgisiz, ayrı görev |
| Play Console listeleme/derecelendirme/veri güvenliği formları | Tamamlanmadı |
| Gizlilik Politikası / Kullanım Koşulları | Uygulama içinde TR/EN/ES metin var; `getzibo.com/privacy` + `/terms` URL'de YAYINLANMASI gerekiyor (ayrı `zibo-website` projesi, bu oturumdan erişilemiyor) |

## Ortam / config

- Flutter SDK: `C:\flutter\bin` (PATH'te değil). `flutter analyze` çöküyor → `flutter test`.
- Çalışma dizini: `C:\dev\Zibo DK`; Flutter projesi `dijital_kanka/` alt klasöründe.
- Web önizleme: `.claude/launch.json` `dijital_kanka_web` (8.3 kısa yol hack'i — proje taşınırsa yeniden hesapla).
- Görsel doğrulama: web preview (`flutter run -d web-server`) + Browser araçları; gerçek cihaz `adb` (`MSYS_NO_PATHCONV=1` gerekebilir).
- `google-services.json`: `android/app/` — 4 OAuth cert hash (upload key, debug key, önceki yanlış App Signing girişi, doğru App Signing key).
- GitHub token: `git credential fill` ile alınabilir (`gh` CLI bu makinede YOK).
