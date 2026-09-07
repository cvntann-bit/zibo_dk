# Mimari Kararlar

İleride Claude'un (veya bir geliştiricinin) **yanlış karar vermesini önleyecek** kalıcı kararlar.
Her küçük değişiklik için dosya YOK — yalnızca gerçekten kritik olanlar.

| # | Karar | Özet |
|---|---|---|
| [001](001-firestore-cloudstatestore.md) | `CloudStateStore` ile çift kalıcılık | Her provider yerel + Firestore'a senkron, `uid==null` = saf yerel |
| [002](002-no-cloud-functions.md) | Cloud Functions YOK, GitHub Actions | Blaze plandan kaçınma; zamanlanmış işler `firebase-admin` + cron |
| [003](003-trusted-time-anti-cheat.md) | `TrustedTimeProvider` cihaz saati değil ağ | Günlük ödül/streak/rozet hilesini engeller; `_verifiedThisSession` |
| [004](004-anonymous-auth-google-linking.md) | Anonim auth + opsiyonel Google linking | `linkWithCredential` uid korur; uid değişimi `KeyedSubtree` ile |
| [005](005-coin-economy-client-authoritative.md) | Coin ekonomisi istemci-yetkili | `firestore.rules` yalnızca hız engelleyici; tam koruma Blaze ister |
| [006](006-content-pools-in-dart.md) | İçerik havuzları ARB'de değil Dart'ta | `xTr/xEn/xEs` + `xForLocale`, index-tabanlı seçim, eşit uzunluk |
| [007](007-appodeal-mediation.md) | Tek reklam ağı değil Appodeal mediation | AdMob hesap banı riski; `AdService` soyutlaması geçişi kolaylaştırdı |
| [008](008-photos-local-only.md) | Fotoğraflar yalnızca cihazda | Firebase Storage Blaze ister; yol senkronize, baytlar değil |
| [009](009-permanent-ids-and-gift-contracts.md) | Kalıcı ID'ler + rozet hediye map'i | Kostüm/tema/rozet ID'leri değişmez; `badge_gift_rewards.dart` |
| [010](010-r8-keep-xml.md) | Çalışma-zamanı string kaynakları `keep.xml`'de | R8 release'de sessizce siler → çökme/sessiz eksiklik |
| [011](011-dart-package-name-unchanged.md) | Dart paket adı `dijital_kanka` sabit | Kullanıcı-görünür ad "Zibo" yalnızca ARB + manifest label |
