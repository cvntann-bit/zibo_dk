# Zibo — Büyüme Yol Haritası (başlangıç: 2026-10-21)

Durum: TR Play "Yaşam Tarzı" ilk 100'e girdi (~98. sıra), 2500+ indirme. Hedef: reklam gelirini
ciddiye almak, kararlılığı (crash) ve kitleyi tutmayı (retention) yükseltmek. Bu dosya bir
**çalışma planıdır**; her faz bitince durum satırı güncellenir.

> Dürüst not: aşağıdaki fazlar önceliklendirilmiş TASLAKTIR. "Doğrulanacak" işaretli yerler henüz
> ölçülmedi/okunmadı; varsayım değil, ilk adımda kontrol edilecek.

> **Zarar etmemek ana kuraldır:** her faz kararı `docs/unit_economics.md` (kullanıcı başı gelir/gider) ile kontrol edilir.

## Başlangıç gerçekleri (koddan okundu)

- Reklam: Appodeal (`stack_appodeal_flutter ^4.2.0`), yalnızca rewarded + interstitial. Banner kodu var ama gerçek istek/doluluk yok (bkz. hafıza: banner 0 fill).
- Yüklü adaptörler: **yalnızca AppLovin 13.5.1.0 + Vungle 7.6.1.0** (`android/app/build.gradle.kts:147-148`). Unity Ads / BidMachine, Play'in %25 DEX optimizasyon eşiği için çıkarıldı. **Yeni ağ eklemek DEX'i yeniden şişirir → her ekleme sonrası mapping/DEX ölçülmeli.**
- Satın alma makbuzu sunucuda doğrulanmıyor (açık güvenlik boşluğu, CURRENT_STATE).
- Sürüm: 1.15.0+52 hazır; sonraki versionCode 53+.

## Faz 0 — Ölçüm tabanı (önce bu; geri kalan her şey buna bağlı)

1. Crashlytics: son 30 gün çökme-yok oranı, en sık 5 çökme/ANR, hangi sürümde. → Faz 1'e girdi.
2. Firebase/Play: gün-1 / gün-7 / gün-30 retention, DAU, oturum süresi, onboarding'de kayıp (doğrulanacak: hangi olaylar zaten loglanıyor — `ad_analytics.dart` yalnızca reklam olayları).
3. Appodeal paneli: ağ bazlı fill rate, eCPM, günlük gelir (banner hariç). Referans olarak mevcut durumu yaz.
4. Play Console: Android vitals (ANR/crash eşikleri), kategori sıra/indirme trendi.

Çıktı: tek tablo "bugünkü rakamlar". Sonraki fazların başarısı bununla kıyaslanır.

### Faz 0 SONUÇLARI (2026-10-22, Firebase Console'dan Chrome ile okundu — ölçülmüş veri)

| Kaynak | Ölçüm |
|---|---|
| Crashlytics (7 gün, 16–22 Eki) | Çökmesiz kullanıcı **%98,86**, çökmesiz oturum **%99,16**; **25 çökme, 11 kullanıcı** etkilenmiş. Yayındaki sürüm **1.15.0 (52)** (son saatte 36 aktif kullanıcı) |
| Analytics — aktif kullanıcı | **DAU 194 · WAU 724 · MAU ~1,4 bin** (21 Eki); yapışkanlık DAU/MAU ≈ %14. Tamamı Türkiye. Artış ağırlıkla 1.15.0'da |
| Analytics — katılım | Aktif kullanıcı başı ortalama **7 dk 04 sn**, kullanıcı başı **1,7 etkileşimli oturum** |
| Analytics — kohort tutma (hafta) | Hafta 1 **%14,6** · Hafta 2 **%6,3** · Hafta 3 **%3,7** · Hafta 4 **%1,7** · Hafta 5 %3,8 (tüm kullanıcılar) |
| Firestore (son 24 sa) | **69 bin okuma, 23 bin yazma**, silme yok; saatlik tepe 20,7 bin okuma (cron). Blaze'de ücretsiz günlük kotanın (50 bin okuma/20 bin yazma) küçük bir aşımı → maliyet şu an ihmal edilebilir |
| Fatura | Plan **Blaze (pay as you go)** ✓ · fatura hesabı "My Billing Account 1" · para birimi **TRY** · **bütçe TANIMLI DEĞİL** (Faz B'nin ilk işi) · Firestore için hizmet-bazlı harcama tavanı sunulmuyor (yalnızca Gemini/Cloud Run/Functions) |

Yorum: (a) kararlılık kötü değil ama tek bir çökme türü baskın (aşağıda); (b) **asıl sorun tutma: ilk haftadan sonra kullanıcıların ~%85'i dönmüyor** → Faz R (intro) ve Faz 4 (retention) doğrulandı; (c) Firestore okumasının büyük kısmı saatlik cron taraması olmalı (kullanıcı belgesi sayısı × 120 tarama/gün ≈ günlük okumanın çoğu) — cron düzeltmesi hâlâ mantıklı ama acil değil.

**Faz 1 düzeltmeleri (2026-10-22, commit `beb6275`):** (1) `_WidgetsAppState._onUnknownRoute` — 17 olay/6 kullanıcı: uygulama çalışırken yeni Intent (büyük olasılıkla ana ekran widget dokunuşu) → motor `pushRouteInformation` → uygulamada `onUnknownRoute` yoktu → release'te Null check çökmesi. Çözüm: `main.dart`'ta kendini kapatan şeffaf yedek rota. (2) `ImagePickerPhotoService.saveToPermanentStorage` PathNotFoundException (cache/scaled_….jpg kaybolmuş) → `PhotoUnavailableException` + "fotoğraf okunamadı" uyarısı (profil + manifest). (3) `_PaywallContentState._loadLivePrices` — provider'lar `await` öncesi okunur + `mounted` kontrolü. Doğrulama: Crashlytics'te bu 3 sorun yeni sürümde (1.15.1+) görünmemeli. NOT: widget dokunuşunun gerçek cihazda hâlâ doğru modülü açtığı cihazda DENENMELİ (kullanıcı müsait olunca).

**Play Console (aynı gün, hesap `cvntann@gmail.com` → "ZiboDk", uygulama id 4973229712138231125):** son 28 gün: **cihaz edinimi 2,33 bin (+%841)**, ilk açılış 652, **aylık etkin cihaz 747 (+%430)**, toplam yükleme 1,04 bin; **ANR oranı %0,27**; **ortalama puan 4,857 ★ (varsayılan Play puanı 4,714), puan veren yalnızca 21 kullanıcı** (≈ edinimin %1'i → Faz S doğrulandı); **Google Play geliri "–" (28 günde HİÇ IAP/abonelik geliri yok)**. En yeni üretim sürümü: 5 Eki 2026 (1.15.0+52), yayınlanmamış değişiklik yok.

**Fatura bütçesi KURULDU (2026-10-22, kullanıcı onayıyla):** Google Cloud Billing → "Zibo aylik butce 300 TRY": aylık ₺300, yalnızca uyarı, eşikler %50 (₺150) / %90 (₺270) / %100 (₺300) fiili harcama, e-posta faturalama yöneticilerine/kullanıcılarına. Bu ay şu ana kadar ₺2,20. NOT: bütçe harcamayı DURDURMAZ, yalnızca uyarır; Firestore için hizmet-bazlı tavan yok.

Bu sayfa açılışta henüz bakılmadı: Play Console Android vitals; Analytics "Gün 1" tutma; ANR/non-fatal (Crashlytics filtresi yalnızca "Crashes").

## Faz 1 — Kararlılık (crash) — önce

- Faz 0 verisinden en sık çökmeleri sırala, kök nedeni oku (tahmin yok), düzelt, test ekle.
- Çıkış ölçütü: çökme-yok oranı hedefi (Faz 0'da gerçek değere bakıp birlikte belirleriz), Play vitals eşiklerinin altında.

## Faz 2 — Appodeal SDK güncellemesi (büyük değişiklik; ayrı sürüm)

- Kontrol: `stack_appodeal_flutter` ve Android adaptörleri için güncel sürümler + release notları + kırıcı değişiklikler (doğrulanacak; internetten okuyacağım, hafızadan söylemeyeceğim).
- Güncelleme sonrası: banner callback imzaları (`main.dart`), adaptör sürüm uyumu (adaptör sürümleri SDK ile eşleşmeli), R8/keep kuralları, release derleme, gerçek cihazda rewarded + interstitial denemesi.
- Risk: SDK güncellemesi DEX ve davranışı değiştirir → mapping/DEX ölçümü zorunlu. Ayrı sürüm olarak çıkar (özellik değişiklikleriyle karıştırma).

## Faz 3 — Reklam ağları + Yandex hesabı (adım adım, birlikte)

Netleştirilecek (ilk soru): "Yandex boost" ile tam olarak ne kastedildiği — Yandex Ads / Yandex Mobile Ads ağı mı, başka bir "Boost" ürünü mü? Hesap kurulumu, ödeme/vergi bilgileri ve şifreler **senin tarafında** yapılır (ben kimlik/ödeme/şifre girmem); ben adımları yönlendirir, kodu/yapılandırmayı yaparım.

Sıra:
1. Appodeal'in desteklediği ağlar ve her birinin DEX maliyeti (adaptör boyutu) → liste.
2. Ağ ağ ekle: hesap (sen) → Appodeal paneline bağla → adaptör bağımlılığı → DEX/mapping ölç → debug APK ile test → sonraki ağ.
3. Banner: Appodeal desteğinden gelecek cevaba göre; Mintegral banner test teklifi hâlâ onay bekliyor (bkz. hafıza). Adaptörlere destek cevabı gelmeden dokunma kuralı geçerli.
4. Her ağ sonrası: fill rate / eCPM'i Faz 0 tablosuyla kıyasla; kötü ağı kapat.
5. Appodeal'de "Store URL" doğrulaması bekleyen ağlar (Unity vb.): uygulama artık yayında → panelden doğrulamayı kontrol et.

## Faz 4 — Retention (kitleyi tutma)

Faz 0 verisine göre belirlenir; aday fikirler (henüz seçilmedi, önce veri):
- İlk 3 günün deneyimi: onboarding sonrası ilk ödül, ilk kostüm hediyesi, ilk hedef.
- Günlük dönüş sebebi: günlük ödül/seri vurgusu, Oyun Salonu, yeni kostümler (nadirlik + toplama motivasyonu zaten eklendi).
- Bildirimler: yerel bildirim sistemi rafta (`notificationsFeatureEnabled=false`); FCM push zaten aktif → zamanlama/içerik iyileştirmesi.
- Yorum/puan isteme (mutlu anda tek seferlik).
- Her değişiklik için: hipotez → ölçülecek metrik → sürüm sonrası karşılaştırma.

## Faz B — Blaze fatura koruması (Faz 5'ten ÖNCE, hemen)

Kullanıcı 2026-10-21'de Blaze'e geçti. Blaze'de bütçe uyarısı harcamayı DURDURMAZ, yalnızca e-posta atar; sert tavan yok.
1. Google Cloud Console > Billing > Budgets & alerts: aylık bütçe (düşük tutulur) + %50/%90/%100 e-posta eşikleri (kullanıcı yapar; tutarı birlikte seçeriz).
2. Fatura e-postası: doğru ve düzenli bakılan adrese gitmeli.
3a. **BULGU (2026-10-21):** saatlik cron'daki 5 bildirim işinin HER BİRİ `fetchAllUsers()` ile TÜM `users` koleksiyonunu okuyor (`notification-scripts/src/common.js:156`) → günde ~120 tam tarama = kullanıcı sayısı × 120 okuma/gün (10k kullanıcıda ~1,2M/gün). En büyük maliyet kalemi; tek paylaşılan tarama ya da sorgu ile filtreleme (ör. yalnızca fcmToken'lı/aktif) ile büyük ölçüde kısılabilir.
3. Firestore kullanım takibi (okuma/yazma/gün) + beklenmedik sıçrama uyarısı; `notification-scripts` ve app tarafında sınırsız okuma döngüsü taraması.
4. Cloud Functions yazılırsa: `maxInstances` düşük, bölge sabit, yalnızca gerekli tetikleyiciler, sonsuz-döngü/yeniden-tetikleme korumaları.
5. İsteğe bağlı sert kesme (Pub/Sub ile faturalamayı kapatma): çalışan servisleri komple durdurur → ancak gerçek bir kesme istenirse ve sonuçları anlatıldıktan sonra.

## Faz D — DEX optimizasyonu (başlama emri bekleniyor — kullanıcı "müsait olunca başlayacağız" dedi, UNUTMA)

Amaç: Play DEX optimizasyon skoru şu an **%27** (eşik %25, Şubat 2027'de zorunlu) → yeni SDK'lara (Yandex vb.) yer açmak için marj artırmak. Kullanıcı %40 istedi; ölçüme göre %40 gerçekçi değil, tahmin %30–34 (garanti yok).

Ölçüm (1.15.0+52 `mapping.txt`, vekil skor; Play'in skoruyla aynı ölçek DEĞİL, yalnızca göreli):
- Korunan (karartılmayan) ağırlık: gms.internal 10,3 · AppLovin 8,7 · **io.flutter.** (bizim kural) 6,7** · Firebase Analytics 2,8 · okhttp3 2,5 · recaptcha 2,0 · **androidx.work (bizim) 1,8** · Appodeal 1,6 · **androidx.credentials (bizim) 1,4** · **com.tiktok (bizim) 0,6**.
- Bizim `proguard-rules.pro` kurallarının toplam payı ~10,5 vekil puan; gerisi SDK'ların kendi consumer `-keep` kuralları (projeden kaldırılamaz).
- Geçmiş: BidMachine adaptörünü çıkarmak %24→%27 yapmıştı.

Plan (sırayla, hepsi proguard-rules.pro; Dart'a dokunmaz):
1. `-keep class io.flutter.** {*;}` ve alt kurallarını daralt (Flutter Gradle eklentisi çoğunu zaten ekliyor; yanlışsa AÇILIŞTA çökme riski).
2. `androidx.work.**` keep'ini yalnızca `WorkDatabase_Impl`/Room `_Impl` sınıflarına daralt (geçmişte tüm keep kaldırılınca açılışta WorkDatabase çökmüştü — dikkat).
3. `androidx.credentials.**` ve `com.tiktok.**` kurallarını daralt (küçük kazanç).
4. recaptcha bağımlılığını dışlama: RİSKLİ (Firebase Auth), şimdilik YAPILMAYACAK.
Doğrulama: derle → `mapping.txt` vekil skoru önce/sonra rakamla karşılaştır → release AAB'yi dahili teste yükle, telefonda AÇ + Google ile giriş + reklam + bildirim + çark dene (çökmeler yalnızca cihazda çıkıyor, derlemede değil) → çökme yoksa yayınla; Play skoru birkaç gün gecikmeli güncellenir.
Kural: canlı sürümün üzerine debug build kurma. Bu iş AYRI sürüm olarak (1.15.0+52 ayrı tutulur), özellik değişiklikleriyle karışmaz.

## Faz R — Intro/Onboarding yenileme (kullanıcı kararı 2026-10-21; "Özellik grafiği" listeden SİLİNDİ)

Amaç: ilk açılışta Zibo'yu sevdirmek + uygulamanın ne işe yaradığını YORMADAN göstermek → retention (gün-1/7) artışı.
Bugün (`lib/screens/onboarding/onboarding_screen.dart`, 12 sayfa): Dil → İsim → 8 modül tanıtımı (Hedef, Su, Şükran, Ruh Hali, Rüya, Manifest, Mağaza, Profil) → Kapanış. Hikâye yok, öğretici salt metin.
Plan (taslak, kullanıcıyla netleşecek):
1. Dil (aynen).
2. **Zibo hikâyesi:** 3–5 slayt, kullanıcının ÜRETECEĞİ görseller + kısa metin (TR/EN/ES ARB), kaydırma/dokunma, "Geç".
3. İsim ("Sana ne diyelim?" hikâyenin devamı gibi Zibo sorar).
4. **Kısa öğretici (≤4 adım):** 8 modül sayfasının yerine; pasif metin yerine mümkünse "ilk küçük görev" (ör. Zibo'ya dokun, Z menüsünü aç, ilk hedef/su). Atlanabilir; Ayarlar'dan tekrar izlenebilir.
5. Kapanış.
Ölçüm: Firebase olayları (`onboarding_step_viewed`, `onboarding_skipped`, `onboarding_completed`) → hangi adımda kayıp var; eski akışla (varsa) kıyas.
Girdi bekleyen: Zibo hikâyesi/lore (kullanıcı yazacak ya da taslak onaylayacak), görseller (adet/boyut aşağıda), öğretici adımları.

## Faz S — Yıldız/yorum teşviki (kullanıcı kararı 2026-10-21; HENÜZ BAŞLAMADI — not)

Hedef: daha çok yıldız + yorum (mağaza sıralaması, ilk 100'e girildi — bkz. growth-milestone). Kullanıcı istekleri: **teşviki artır, daha SIK göster, mümkünse Google Play uygulama-içi yorum API'sini doğrudan uygulama içinden bağla.**

Bugünkü sistem (koddan okundu):
- `lib/utils/rate_prompt_trigger.dart`: mutlu anlarda (7 günlük hedef, para girişi, günlük kayıtlar, rozet…) `chance = 0.2`, `cooldown = 5 gün`, `minDaysOpened = 3`; `markCompleted()` sonrası ASLA sormaz. Pencere `rate_prompt_dialog.dart` + `rate_us_sheet.dart`.
- Yorum sayfasına `launchUrl` ile gidiyor (`market://details?id=…` → `https://play.google.com/store/apps/details`), uygulama-içi API KULLANILMIYOR (`pubspec.yaml`'da `in_app_review` YOK).
- Sorun: kullanıcı butona dokunur dokunmaz `markCompleted()` işaretleniyor — gerçekten puan vermemiş olsa bile bir daha sorulmuyor (Google puan verilip verilmediğini bildirmiyor).

Plan (taslak, kullanıcı onayıyla):
1. **Uygulama-içi yorum API'si:** Flutter `in_app_review` paketi (Google Play In-App Review API sarmalayıcısı; `isAvailable()` + `requestReview()`) — paket ve sürüm uyumu eklemeden önce DOĞRULANACAK. Zibo balonlu mevcut isteği tetikleyici olarak tut, onaylayınca API'yi çağır; kullanılamazsa/gösterilmezse eski Play sayfası bağlantısına düş. Ayarlar/Profil'e kalıcı "Bizi puanla" satırı.
2. **Daha sık:** `chance`/`cooldown`/`minDaysOpened` değerlerini gevşet + yeni mutlu anlar (seviye atlama, seri kilometre taşları, günlük ödül, Oyun Salonu'nda yüksek skor, kostüm satın alma/giyme). Not: Google, uygulama-içi pencerenin gösterim sıklığına KOTA koyar (API çağrılsa bile pencere gösterilmeyebilir) — "daha sık" en çok bizim ön-pencereyi/tetikleyicileri artırmak demek; gerçek sınır Google'da.
3. **`markCompleted` mantığı:** yalnızca API gerçekten çalıştırıldıysa/kullanıcı "Zaten puanladım" dediyse işaretle; sadece dokunmakla kalıcı kapatma.
4. **UYARI — politika:** ZC/ödül karşılığı yıldız-yorum isteme YASAK olabilir (Google Play'in "Puan, Yorum ve Yükleme" politikası teşvikli/manipüle edilmiş yorumu yasaklar — yazmadan önce güncel politikayı DOĞRULA). Yalnızca mutlu anlarda sor; olumsuz kullanıcıyı filtreleme ("beğendin mi?" ön sorusu) riskini politikadan kontrol et.
5. **Ölçüm:** `rate_prompt_shown / accepted / dismissed / api_available` Firebase olayları; puan ortalaması ve yorum sayısı Play Console'dan haftalık.

## Faz 5 — Güvenlik/gelir sağlamlığı (zamanı gelince)

- Satın alma makbuzu sunucu doğrulaması (Cloud Functions/Blaze kararı gerekir) — gerçek kullanıcı sayısı arttıkça önceliği yükselir.
- iOS (hedef: 10 bin kullanıcı) — ayrı karar.

## Çalışma kuralları (bu plan için)

- Her faz ayrı sürüm/ayrı commit; SDK güncellemesi ile özellik değişikliği karışmaz.
- Gerçek kullanıcı var: canlı sürümün üzerine debug build kurma (imza uyuşmazlığı → veri silinir).
- Rakam isteyen her iddia ölçülerek gelir; kestirim varsa "tahmin" diye işaretlenir.
- AAB'yi sen "hazırla" demeden üretmem.

## Durum

| Faz | Durum |
|---|---|
| 0 Ölçüm tabanı | **büyük ölçüde TAMAM** (Firebase + Appodeal ölçüldü; Chrome uzantısı bağlı). Eksik: Play Console vitals, Gün-1 tutma, ANR/non-fatal |
| 1 Crash | **ilk 3 çökme düzeltildi** (`beb6275`, 3 regresyon testi; yeni AAB + canlı doğrulama bekliyor). Sıradaki: ANR/non-fatal bak, düzeltme sonrası Crashlytics'te 3 sorunun kapandığını doğrula |
| 2 Appodeal SDK | başlamadı |
| 3 Reklam ağları + Yandex | **banner teşhisi yapıldı** (aşağıda); destek mesajı hazır `docs/appodeal_support_ticket.md` (kullanıcı gönderecek). Yandex/yeni ağlar: başlamadı |
| 4 Retention | başlamadı (veri: hafta-1 tutma %14,6; intro hikâyesi hazır, bağlama bekliyor) |
| D DEX optimizasyonu (%27 → hedef daha yüksek) | kullanıcı onayı bekliyor, "müsait olunca" başlanacak |
| B Blaze fatura koruması | **bütçe KURULDU** (₺300/ay, %50/90/100). Kalan: cron tam tarama düzeltmesi (acil değil: günlük okuma 69K) |
| S Yıldız/yorum teşviki | **KODLANDI** (main): uygulama-içi Google Play yorum API'si (`in_app_review`) + Play Store yedeği, daha sık tetikleyici (%35 / 3 gün / 2. gün), dokununca 45 gün bekleme (kalıcı kapanış yok), yaşam boyu en fazla 8, kostüm alımında yeni tetikleyici. Cihazda DENENECEK |
| R Intro/Onboarding yenileme | **main'e BAĞLANDI** (dil → hikâye → isim → bildirim izni → final); cihazda APK ile denenecek, yüksek çözünürlüklü görseller bekleniyor — `docs/onboarding_story.md` |
| 5 Güvenlik/iOS | beklemede (Blaze artık açık → makbuz doğrulaması yapılabilir) |


### Faz S uygulama notları (2026-10-22)
`lib/services/review_service.dart` (`InAppReviewService`: `isAvailable` → `requestReview`; **600 ms'den kısa dönen çağrı "gösterilmedi" sayılıp Play Store sayfasına düşülür** — Google kota yüzünden pencereyi göstermezse API sessizce döner, kullanıcı "hiçbir şey olmadı" demesin). `RatePromptTrigger`: chance 0.2→0.35, cooldown 5→3 gün, minDaysOpened 3→2; `markRateTapped()` (45 gün) ayrıldı, `markCompleted()` yalnızca "Zaten puanladım"/Ayarlar "Bizi puanla"; `maxShows = 8`. Ayarlardaki kalıcı "Bizi puanla" Play Store sayfasını açmaya devam eder (Google yönergesi). **Karşılığında ZC/ödül YOK** (teşvikli yorum politika riski). Bağımlılık `in_app_review ^2.0.12` (Play review kütüphanesi ekler → DEX etkisi küçük, Faz D'de ölç). Cihazda: yıldıza dokununca sistem yorum sayfası açılıyor mu, ikinci kez hemen çıkmıyor mu.


## CİHAZ TEST KONTROL LİSTESİ (kullanıcı telefonu bağlayınca, APK ile — AAB YOK)

**Önce güvenlik:** `adb shell dumpsys package com.dijitalkanka.dijital_kanka | grep -E "installerPackageName|versionName"`. Telefonda Play'den kurulu CANLI sürüm varsa debug/yerel APK imza uyuşmazlığı verir → `uninstall` gerekir = yerel veri + anonim hesap (uid) KAYBI. Karar kullanıcıya sorulur; kullanıcı onaylamadan `uninstall` yapma. Seçenekler: (a) yedek/ikinci telefon, (b) kullanıcı kendi verisini feda eder, (c) emülatör (gerçek Firebase/reklam trafiği riski → reklamlar KAPALI olmalı).
1. **Intro (Faz R):** temiz kurulumda dil → hikâye 5 slayt (geçişler, uzun ekran kırpması, "Geç") → isim (klavye, taşma) → bildirim izni (İzin Ver / Reddet / Şimdi Değil; Android 13+ sistem penceresi) → final → Ana Sayfa. "Şimdi Değil" sonrası açılışta ikinci izin penceresi ÇIKMAMALI. Mevcut kullanıcıda intro çıkmamalı.
2. **Yorum (Faz S):** Profil/Ayarlar "Bizi puanla" Play sayfasını açar; mutlu anlarda pencere çıkar, yıldıza dokununca sistem yorum sayfası açılır (açılmazsa Play Store sayfası); dokundan sonra hemen tekrar çıkmaz; kostüm alımından sonra çıkabilir.
3. **Çökme düzeltmeleri (Faz 1):** ana ekran widget'ına dokunmak (uygulama açıkken ve kapalıyken) çökmeden doğru modülü açar; profil/manifest'te fotoğraf seçme; paywall'ı hızlıca açıp kapatma.
4. Genel: Google ile giriş, reklam (rewarded), coin akışları, bildirim.


### Cihaz testi sonucu (2026-10-22, Samsung SM-A226BR, debug APK 1.15.0+52, `adb install -r`)
Telefonda zaten DEBUG (`installer=null`, DEBUGGABLE) 1.13.1 vardı → aynı imzayla güncellendi, veri kaybı yok. Kullanıcı onayıyla `pm clear` yapıldı → **yeni intro gerçek cihazda çalıştı** (hikâye, isim, bildirim izni penceresi; kullanıcı "güzel oldu" dedi). Günlükte FATAL/çökme YOK. Henüz cihazda denenmeyenler: yorum penceresi, widget dokunuşu (çökme düzeltmesi), fotoğraf seçme, paywall, "Şimdi Değil" yolu (açılışta ikinci izin penceresi çıkmamalı).

**Cihaz testi — otomatik adb turu (2026-10-22, SM-A226BR, debug 1.15.0+52) — SONUÇLAR:**
- Widget Intent (`es.antonborri.home_widget.action.LAUNCH` + `zibowidget://open/<modül>`): uygulama AÇIKKEN (`water`) VE soğuk başlangıçta (`money`) çökme YOK, doğru modül açıldı → Faz 1 bilinmeyen-rota düzeltmesi cihazda ✓.
- "Şimdi Değil" yolu: dil → hikâye(5 dokunuş) → isim("Ayse") → bildirim adımı kendi adıyla selamlıyor → "Şimdi Değil" → final metni doğru → Ana Sayfa; logcat'te **izin penceresi (GrantPermissions) YOK**, `POST_NOTIFICATIONS granted=false` (seçim saygı gördü); Zibo adıyla hitap ediyor ✓. İsim adımı klavye açıkken taşmıyor (Zibo küçülüyor) ✓.
- Ayarlar > "Bizi Puanlayın" → yıldız sayfası → 5. yıldız → Play Store'da Zibo sayfası açıldı ✓ (sayfada 1.15.0 sürüm notları görünüyor).
- Denenemeyen: uygulama-içi yorum API'si (YALNIZCA Play'den kurulu sürümde çalışır; sideload/debug'da gösterilmez → fallback beklenir) → dahili test kanalıyla denenmeli; rastgele "mutlu an" yorum penceresi; fotoğraf seçme; paywall aç-kapa.
- **UYARI:** Bu telefonun Play hesabı Zule Lozada'ya ait görünüyor (Zibo sayfasında onun 5★ yorumu). Telefonda iki kez `pm clear` yapıldı (kullanıcı onayıyla, "test cihazı" varsayımıyla). Hesap Google ile bağlıysa Ayarlar > "Google ile Bağlan" ile verisi geri gelir; bağlı değilse yerel anonim veri kayıp. Kullanıcı bilgilendirilecek.

**Düzeltme (2026-10-22):** Ayarlar > "Bizi Puanlayın" yıldız sayfası eskiden DOĞRUDAN Play Store sayfasını açıyordu (yalnızca mutlu-an penceresi uygulama-içi API'ye bağlıydı). Şimdi o da önce uygulama-içi yorumu dener, Google göstermezse Play Store'a düşer (`showRateUsSheet(reviewService:)`); `markCompleted` yerine `markRateTapped` (45 gün). **NOT:** uygulama-içi pencere YALNIZCA Play'den kurulu sürümde görünür; sideload/debug APK'da API anında döner → Play Store sayfası açılması BEKLENEN davranıştır.


### Faz 3 — banner/Appodeal teşhisi (2026-10-22, ölçülmüş)
**Üretim:** `banner_failed` 26.078 olay/1.061 kullanıcı (28 gün), `banner_loaded`/`shown` = 0; Crashlytics non-fatal `_initializeAppodeal` sorunu 7 günde **6,5 bin olay / ~650 kullanıcı** (iki varyant: banner başarısızlığı ~5,9K olay/639 kullanıcı; init hatası ~620 olay/349 kullanıcı); 1.9.2'den beri. **Cihaz:** her açılışta `Appodeal init errors: InternalError: SdkConfigurationError null` (test modunda da). Native uyarı: `Adapters are not registered: bidmachine`.
**Deney (debug, test modu, geçici — COMMİTLENMEDİ):** `debugImplementation(adapters:bidmachine:3.7.1.0)` eklenince uyarı kayboldu ama `SdkConfigurationError` DEVAM etti → sebep BidMachine eksikliği DEĞİL; **BidMachine'i geri eklemeye gerek yok (DEX korunur)**. Gerçek reklam birimleriyle kendi cihazımızdan test YASAK (AdMob ban dersi) → üretimi yeniden üretemeyiz; kök neden Appodeal tarafında (Console/ağ yapılandırması) olabilir.
**Yapıldı:** `onBannerFailedToLoad` artık oturum başına yalnızca İLK başarısızlığı Analytics+Crashlytics'e yazar (gürültü ~12× azalır). **Sıradaki (kullanıcı):** `docs/appodeal_support_ticket.md` mesajını Appodeal desteğine gönder; cevaba göre Console düzeltmesi / SDK güncellemesi (Faz 2).

**Appodeal Console incelemesi (2026-10-22, kullanıcının diğer Chrome profili, salt-okunur — hiçbir şey değiştirilmedi):**
- Uygulama: Zibo Dijital Kanka (id 785018), SDK 4.2.0 ✔, bundle `com.dijitalkanka.dijital_kanka` ✔, tek Mediation Group "Default" (ON). COPPA/mature filtre kapalı, test modu "Use SDK settings".
- **Banner ağları AÇIK:** Ad Server Campaigns, **AppLovin** (Appodeal hesabı; `applovin_banner` + `applovin_phone_banner_320x480_bid_*` birimleri ON), **BidMachine, Mintegral, Vungle, Yandex**. Uygulamada yalnızca applovin + vungle adaptörü var → BidMachine/Mintegral/Yandex banner için waterfall'da ama adaptörleri YOK (APK'da bulunmayan ağlara istek gidemez).
- AppLovin banner birimleri panelde tanımlı ve açık; yani "birim yok" değil — sorun istemci tarafı/Appodeal sunucu yapılandırması (`SdkConfigurationError`) olabilir. Panelde bu hatayı açıklayan bir uyarı görülmedi.
- Ağ hesapları: Yandex hesabı bağlı (kullanıcının Yandex e-postası) → Faz 3'te Yandex için zemin hazır; Meta/Admob/Amazon "manuel bağlanmalı".
- Destek mesajına eklenecek: "Banner waterfall'da BidMachine/Mintegral/Yandex ON ama adaptörleri uygulamada yok; AppLovin banner birimleri ON ama istek yok."

**Yandex kurulumu (2026-10-22, Appodeal paneli, Banner sekmesi):** Yandex Partner'da uygulama ID `19995639` (test modu; SDK isteği gelince çıkar), bloklar `R-M-19995639-1` banner / `-2` interstitial / `-3` rewarded. AppMetrica uygulama ID `6353002` (API anahtarı AppMetrica > Ayarlar > Main'de; anahtarı kullanıcı yapıştırdı). Appodeal > Ad Units > Banners > Yandex: Page ID `19995639`, AppMetrica ID `6353002`, API key, ad unit `yandex_banner` = `R-M-19995639-1` (eCPM 0, ON) — yenilemeden sonra kalıcı doğrulandı. **Henüz yapılmadı:** interstitial/rewarded Yandex birimleri; uygulamaya Yandex adaptörü (kod tarafı, kullanıcı onayı + DEX ölçümü bekliyor). Adaptör eklenmeden Yandex'e istek gitmez.
**Yandex birimleri tamam (2026-10-22):** Appodeal > Ad Units'te Yandex için 3 birim ON (eCPM 0, All Countries): `yandex_banner` = `R-M-19995639-1`, `yandex_interstitial` = `R-M-19995639-2`, `yandex_rewarded` = `R-M-19995639-3`. Panel tarafı bitti; sıradaki: uygulamaya Yandex adaptörü (debug APK, DEX ölçümü, kullanıcı onayı).
**Yandex adaptör DENEYİ (2026-10-22, `android/app/build.gradle.kts` içinde `adapters:yandex:7.18.2.0` — COMMİTLENMEDİ):** release APK (54,7 MB) `mapping.txt` ölçümü: Yandex+AppMetrica **5.644 sınıf / 4.185 karartılmamış / 131.136 üye** (toplam 28.842 sınıf, 876.508 üye; AppLovin 50K, Vungle 15K, Appodeal 64K üye) → BidMachine'le (~139K, çıkarılmıştı) aynı boyutta; DEX skoru (%27, alt sınır %25) büyük olasılıkla düşer, kesin skor yalnızca Play Console'dan okunur. Debug APK telefonda (1.15.0+52 debug üzerine `-r`): `YandexAds 7.18.2 integrated successfully`, çökme yok, uyarı listesinde yalnızca `bidmachine`; `SdkConfigurationError` DEVAM ediyor (adaptörle ilgisiz). Debug test modunda olduğundan GERÇEK fill ölçülemez (ancak yayında ölçülür). Karar bekliyor: yayına alıp ölçmek mi, geri almak mı.

**Faz D uygulandı + TikTok SDK kaldırıldı + Yandex adaptörü KALICI (2026-10-22):** `proguard-rules.pro`: `io.flutter.**` keep'leri kaldırıldı, `androidx.work` → yalnızca `androidx.work.impl.**_Impl`, `androidx.credentials` → yalnızca `playservices.**`; TikTok SDK (gradle, JitPack, `TikTokConfig.kt`, MainActivity init, main.dart köprüsü, proguard) silindi (kullanıcı TikTok'ta reklam vermiyor). Ölçüm (release `mapping.txt`, kilitli=karartılmayan sınıf): Yandex'li başlangıç 19.577/28.842 (%67,9) → Faz D 17.723/27.680 (%64,0) → TikTok'suz **17.380/27.385 (%63,5)**. Doğrulama: `flutter test` 737 geçti (1 bilinen audioplayers flake'i); release APK telefona (kaldır+kur, kullanıcı onayıyla) kuruldu: açılış + ana ekran + Ayarlar sorunsuz, `WorkDatabase`/FATAL logu yok. Play'in gerçek DEX skoru yeni sürüm yayına çıkınca Play Console'dan okunur. AAB henüz YOK (kullanıcı onayı bekleniyor); sürüm 1.15.1+53 olacak.

**Mintegral adaptör deneyi (2026-10-22, GERİ ALINDI):** `adapters:mintegral:17.1.81.1` (Appodeal çekirdeği 4.x uyumlu; panelde Mintegral banner Appodeal hesabıyla ON, "Mintegral banner bidding" birimi — kurulum gerekmedi; interstitial/rewarded "Appodeal hesabına bağlı değil" → kapalı). Release `mapping.txt`: Mintegral **3.542 sınıf / 3.499 karartılmamış / 107.541 üye**; toplam kilitli sınıf 17.380 (%63,5) → 20.896 (%67,5) — Faz D kazancını geri yiyor. Karar: önce Yandex'li 1.15.1+53 yayınlansın, Play DEX skoru + Yandex banner fill'i ölçülsün; Yandex dolduramazsa ve skor payı varsa Mintegral tek satırla (`implementation("com.appodeal.ads.sdk.adapters:mintegral:17.1.81.1")`) eklenir.
