# Zibo — Büyüme Yol Haritası (başlangıç: 2026-10-21)

Durum: TR Play "Yaşam Tarzı" ilk 100'e girdi (~98. sıra), 2500+ indirme. Hedef: reklam gelirini
ciddiye almak, kararlılığı (crash) ve kitleyi tutmayı (retention) yükseltmek. Bu dosya bir
**çalışma planıdır**; her faz bitince durum satırı güncellenir.

> Dürüst not: aşağıdaki fazlar önceliklendirilmiş TASLAKTIR. "Doğrulanacak" işaretli yerler henüz
> ölçülmedi/okunmadı; varsayım değil, ilk adımda kontrol edilecek.

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
3. Firestore kullanım takibi (okuma/yazma/gün) + beklenmedik sıçrama uyarısı; `notification-scripts` ve app tarafında sınırsız okuma döngüsü taraması.
4. Cloud Functions yazılırsa: `maxInstances` düşük, bölge sabit, yalnızca gerekli tetikleyiciler, sonsuz-döngü/yeniden-tetikleme korumaları.
5. İsteğe bağlı sert kesme (Pub/Sub ile faturalamayı kapatma): çalışan servisleri komple durdurur → ancak gerçek bir kesme istenirse ve sonuçları anlatıldıktan sonra.

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
| 0 Ölçüm tabanı | başlamadı |
| 1 Crash | başlamadı |
| 2 Appodeal SDK | başlamadı |
| 3 Reklam ağları + Yandex | başlamadı (önce "Yandex boost" netleşecek) |
| 4 Retention | başlamadı |
| B Blaze fatura koruması | sıradaki (Blaze'e geçildi, koruma henüz kurulmadı) |
| 5 Güvenlik/iOS | beklemede (Blaze artık açık → makbuz doğrulaması yapılabilir) |
