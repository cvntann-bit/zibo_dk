# 005 — Coin ekonomisi istemci-yetkili; `firestore.rules` yalnızca hız engelleyici

## Context
Kullanıcı coin ekonomisini mod APK / hile koruması için sağlamlaştırmak istedi. `CoinProvider` bir
`ChangeNotifier` (sunucu değil) — TÜM kazanma/harcama mantığı cihazda çalışır, sonuç `CloudStateStore`
ile OLDUĞU GİBİ Firestore'a yazılır.

## Decision
`firestore.rules`'un `users/{uid}/state/coinState` bloğuna KISMİ bir doğrulama eklendi (tam sunucu
yetkisi DEĞİL):
1. **Şekil**: `balance`/`totalEarned`/`totalSpent` negatif olmayan tam sayı.
2. **Monotonluk**: `update`'te `totalEarned`/`totalSpent` yalnızca ARTABİLİR.
3. **Matematiksel tutarlılık**: `Δbalance == ΔtotalEarned − ΔtotalSpent`.
4. **Tek-yazım sınırı**: kazanma ≤ 10000 (en büyük coin paketi), harcama ≤ 33000 (en pahalı kostüm).
5. `create` (ilk göç) delta kuralına tabi değil, yalnızca şekil + gevşek üst sınır (≤200000).
6. `delete: if false`.

## Neden
- **TAM lockdown (`coinState`'e istemci yazması YOK) YALNIZCA bir Cloud Function ile BİRLİKTE yapılabilir** — sunucu tarafı mutasyon yolu olmadan `allow write: if false` yazmak TÜM kazanma/harcamayı sessizce engellerdi (bkz. [001](001-firestore-cloudstatestore.md) — `save()`'in try/catch'i hatayı yutar, coin senkronu SESSİZCE durar, Google linking'in "cihazlar arası bakiye" vaadi bozulur).
- Cloud Function = Blaze = kullanıcının vermediği karar ([002](002-no-cloud-functions.md)).

## Sonuçlar / Kısıtlar
- **Bu KISMİ düzeltme sürdürülen/scripted saldırıya karşı KORUMASIZ** — rules'un izin verdiği küçük "kural dostu" yazımları (5 ZC check-in) bir betikle sınırsız tekrarlayan bir saldırgan zamanla istediği bakiyeye ulaşır. Rules'un zaman/sıklık hafızası YOK.
- **Kostüm/tema `ownedIds` listeleri hâlâ TAMAMEN korumasız** — istemci ödemeden ID ekleyebilir. Rules-only bir izin listesi `costumes.dart`/`app_themes.dart` ile sürekli senkron tutulması gereken kırılgan bir yük olurdu — bilerek kapsam dışı.
- **KRİTİK BAKIM**: yeni bir daha pahalı coin paketi / kostüm / tema eklenirse `firestore.rules`'taki `10000` / `33000` üst sınırları ELLE yükselt — yoksa o TEK satın alma Firestore'a yazılamaz (sessiz senkron durması).
- **IAP makbuz doğrulaması da AYNI mimari boşlukta** — `purchaseStream`'in `purchased` durumu tek başına güvenilir değil. Tam çözüm: istemci makbuzu bir backend'e gönderir → Google Play Developer API ile doğrulanır → Admin SDK ile `coinState` güncellenir, istemci artık coin EKLEMEZ. Launch öncesi ele alınmalı.

## İlgili
`firestore.rules` (uzun yorumlar) · `docs/history/backend-auth-security-referral.md`
