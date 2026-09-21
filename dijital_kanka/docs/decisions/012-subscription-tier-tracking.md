# 012 — Abonelik durumu istemci-yetkili; süre "kayan pencere" ile tahmin edilir

## Context
Zibo Pro/Pro+ abonelik altyapısı eklenirken, Play Billing'in istemci tarafı API'si
(`in_app_purchase`) bir aboneliğin KESİN bitiş tarihini vermiyor — bu bilgi yalnızca
Play Developer API'de (sunucu tarafı) var. Projenin backend'i yok
([002](002-no-cloud-functions.md)), bu yüzden coin ekonomisiyle ([005](005-coin-economy-client-authoritative.md))
AYNI mimari kısıt burada da geçerli.

## Decision
1. **Gerçek doğruluk kaynağı HER ZAMAN Play Store'un kendisi.** `SubscriptionProvider`
   constructor'da `restorePurchases()` çağırır (uygulama her açıldığında) —
   Play, süresi gerçekten dolmuş bir aboneliği bu sorguda ARTIK döndürmez, bu yüzden
   "restore sonucu boş" = "abonelik değil" güvenilir bir sinyal.
2. **`subscriptionExpiryDate` KESİN değil, "kayan pencere" (rolling window)
   TAHMİNİ:** her başarılı satın alma/restore onayında bu tarih `now + 35 gün`'e
   güncellenir. Kullanıcı uygulamayı düzenli açtığı sürece pencere sürekli tazelenir.
   35 gün, hem aylık hem yıllık planların yenileme kontrolünü güvenle kapsayacak
   kadar geniş bir tampon.
3. **`firestore.rules`'un `subscriptionState`'e eklediği doğrulama** (bkz. o dosya)
   `coinState` ile AYNI felsefe: yalnızca ŞEKİL + "akıl sağlığı" üst sınırı
   (bariz sahte bir gelecek tarihi engellemek), tam sunucu yetkisi DEĞİL.

## Neden
- **TAM lockdown (Play Developer API ile sunucu tarafı makbuz doğrulaması) YALNIZCA
  Cloud Functions ile mümkün** — kullanıcının vermediği bir karar ([002](002-no-cloud-functions.md)).
- Kesin bitiş tarihini istemciden hesaplamaya çalışmak (`satın alma zamanı + 1 ay/yıl`)
  YANLIŞ olurdu — yenilenen bir aboneliğin `transactionDate`'i restore'da hep İLK
  satın almayı gösterebilir, bu da aktif bir aboneliği erkenden "süresi doldu" sayardı.
  Kayan pencere bu riski TAŞIMAZ çünkü her başarılı onayda ileri itilir.

## Sonuçlar / Kısıtlar
- **Bu KISMİ çözüm sürdürülen bir saldırıya karşı KORUMASIZ** — coinState'teki AYNI
  uyarı (bkz. 005) burada da geçerli: kararlı bir istemci Firestore'a doğrudan
  `subscriptionTier: 'proplus'` yazabilir (şekil kurallarına uyduğu sürece).
- **Kullanıcı 35+ gün uygulamayı hiç açmazsa** (abonelik hâlâ aktif olsa bile) durum
  yerel önbellekte "free"ye düşer — bir sonraki açılışta `restorePurchases()` doğru
  durumu hemen geri getirir, veri kaybı YOK, yalnızca geçici bir gösterim gecikmesi.
- **Plan değiştirme (`monthly`↔`yearly-plan`, `pro`↔`proplus`) bu faza DAHİL DEĞİL** —
  Android'in ayrı "subscription replacement" akışı gerektiriyor, paywall ekranı
  tasarlanınca ele alınacak.

## İlgili
`lib/providers/subscription_provider.dart` · `firestore.rules` (`subscriptionState` bloğu) ·
[005-coin-economy-client-authoritative.md](005-coin-economy-client-authoritative.md)
