# Satın alma doğrulaması (2026-10-30)

Durum: **kod hazır, canlı değil.** Kurallar, API ve Play Console yetkisi tamam (2026-10-30); kalan adımlar aşağıdaki "Yayın sırası"nda.

## Ne çözüyor, ne çözmüyor
- **Çözüyor (görünürlük):** sahte makbuz (Lucky Patcher vb. sahte "satın alındı" yanıtı), iade alıp ürünü tutma, aynı
  makbuzun tekrar kullanılması; abonelikte gerçek bitiş tarihi; panelde tahmin yerine Google'dan gelen veri.
- **Çözmüyor:** coin ekonomisi hâlâ istemci-yetkili (`decisions/005`). Değiştirilmiş APK makbuz hiç yazmadan `coinState`'e
  doğrudan yazabilir (rules tek yazımda 10.500 ZC'ye kadar izin verir). Bu ayrı ve daha büyük bir iş.
- **Şimdilik YALNIZCA ETİKET:** coin/üyelik geri alınmaz. Önce gerçek veride yanlış alarm olmadığı görülecek.

## Neden saatlik iş, neden Cloud Function değil
Satın alma anında Function'a sormak (a) ödeme akışını değiştirir: `autoConsume: false`, Function/ağ hatasında parası alınan
kullanıcı ürününü bekler, (b) `decisions/002`'yi bozar ve deploy hattı ister. Saatlik iş ödeme akışına dokunmaz: hata
olursa kullanıcı ürününü yine alır, en kötü sonuç doğrulamanın gecikmesidir. Bedeli: sahte satın alma en fazla ~1 saat
görünmez. Kayıt + Play API yetkisi + `verifyPurchases.js` ileride anlık doğrulamaya geçilirse aynen kullanılır.

## Akış
1. `InAppPurchasePurchaseService._onPurchaseUpdate` başarılı/geri yüklenen her satın alma için `purchaseReceipts`'e
   `PurchaseReceipt` yayınlar (teslimat buna bağlı değil).
2. `PurchaseRecorder` (`main.dart`, `lazy: false`, listenin başında) `purchaseRecords/{sha256(token)}` yazar:
   `uid, productId, purchaseToken, orderId, status: 'pending', createdAt`. Yazılan özetler yerelde
   `recordedPurchaseHashes`'te (son 50) tutulur, çünkü `restorePurchases` abonelikleri her açılışta tekrar oynatır.
3. `firestore.rules`: yalnızca sahibi, yalnızca `pending` kayıt AÇAR; `update/delete` yok, okuma yalnızca yönetici. Belge
   kimliği token özeti olduğundan aynı makbuz ikinci kez açılamaz (ilk uid kalır). Özeti saatlik iş doğrular.
4. `notification-scripts/src/verifyPurchases.js` (`hourlyAll.js`, `daily-stats`'tan önce):
   - `pending` + `nextCheckAt` gelmiş kayıtlar → `purchases.products.get` / `purchases.subscriptionsv2.get`.
   - Sonuç: `verified` (abonelikte `expiryTime`, `subscriptionState`, günlük `nextCheckAt`), `invalid` (`reason`),
     `canceled`, `expired` (HTTP 410). `purchaseType === 0` / `testPurchase` = test alımı.
   - Günde bir (UTC 03) `voidedpurchases` → eşleşen kayıt `voided` (iade).
   - 401/403/429/5xx → hiçbir belge etiketlenmez, hata `stats/purchases.lastError`'a yazılır, sonraki saat dener.
5. `stats/purchases` (`counts`, `problems` son 20, `lastError`, `updatedAt`) → yönetici Özet "🧾 Satın alma doğrulama".
   Belgede `date` alanı yok, bu yüzden günlük `stats` sorgusuna karışmaz.

## Yayın sırası — bu sıra ÖNEMLİ
1. [x] **`firestore.rules` yayınlandı (2026-10-30).** Canlı sürüm repodakiyle SHA-1 ile aynıydı, yeni sürüm de repoyla aynı. Bu adım 1.18.0'dan ÖNCE şarttı: kural yoksa yazım `permission-denied` alır ve
   `PurchaseRecorder` bunu "zaten var" sayıp bir daha denemez.
2. [x] Google Cloud (`zibo-dijital-kankan`): **Google Play Android Developer API** açıldı (2026-10-30).
3. [x] Play Console > Kullanıcılar ve izinler (2026-10-30): `firebase-adminsdk-fbsvc@zibo-dijital-kankan.iam.gserviceaccount.com`
   eklendi, durum Etkin. Yalnızca Zibo, 3 uygulama izni: **Finansal verileri görüntüleme** (açıklamasında Satın Alma API'si
   erişimi yazıyor) + otomatik gelen uygulama bilgisi ve kalite. Yetkinin yayılması 24–36 saat sürebilir. GitHub secret'ı bu
   hesaptan üretilmiş varsayılıyor (projede 4 servis hesabı var); `lastError` 403 kalırsa önce buna bak.
4. [ ] Zibo **1.18.0** yayınlanır (uygulama içi mesaj kartıyla birlikte). Eski sürümler kayıt yazmaz; abonelikler
   güncelleyip uygulamayı açınca `restorePurchases` ile kendiliğinden kaydolur.
5. [ ] Gerçek bir test alımıyla uçtan uca doğrulanır (ilk Actions log'u + panel kartı). **Node bu makinede yok:
   `verifyPurchases.js` henüz hiç çalıştırılmadı, gerçek Google yanıtlarıyla denenmedi.**
6. [ ] Birkaç hafta veri izlenir, sonra yaptırım kararı (aşağıda).

## Sonraki adımlar (henüz YOK)
- **Yaptırım:** `invalid`/`voided` kayıt için coin/üyelik geri alma. Dikkat: açık uygulama yerel bakiyeyi tutar
  (`grantGift.js` notu), sunucudaki düşüş rules'ta reddedilen yazımlara yol açar → istemci tarafı tasarım gerekir.
- **Gerçek abonelik bitişi:** `SubscriptionProvider` kayan penceresi yerine `expiryTime`; panel Aboneler listesi buradan.
- **Gerçek gelir:** Özet'teki tahmin yerine `verified` kayıtlar.

## Maliyet (tahmin)
Satın alma başına 1 yazma + birkaç kontrol; saatte ~6 okuma + 1 yazma (`stats/purchases`). Play API ücretsiz. Bugünkü
Firestore ücretsiz kotasında fark edilmez.
