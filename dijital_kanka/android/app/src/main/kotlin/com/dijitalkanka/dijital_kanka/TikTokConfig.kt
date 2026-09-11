package com.dijitalkanka.dijital_kanka

/**
 * TikTok Business SDK (kurulum/olay takibi) yapılandırması — TEK Kotlin
 * config noktası. `lib/config/appodeal_config.dart`'taki AYNI "yeni bir
 * kimlik gerekirse yalnızca bu dosya değişir" deseni — ama SDK yalnızca
 * native tarafta ([MainActivity]) başlatıldığı için Dart'a hiç taşınmadı.
 *
 * Bu üç değer TikTok Ads Manager > Events Manager > Data sources > Zibo
 * uygulaması bağlantısından alındı (2026-09-12). [ACCESS_TOKEN] TikTok'un
 * kendi arayüzünde "App Secret" olarak adlandırılıyor ve "anyone with
 * access can send data on your behalf" diye uyarılıyor — YİNE DE resmi SDK
 * API'si bunu doğrudan `TTConfig` constructor'ına, yani derlenmiş APK'nın
 * İÇİNE gömülecek şekilde alıyor (Appodeal App Key'iyle AYNI sınıf: gerçek
 * bir sunucu sırrı değil, uygulamaya gömülü bir istemci kimliği).
 */
object TikTokConfig {
    /** Play Console `applicationId` ile birebir aynı — TikTok "App ID" diyor. */
    const val APP_ID = "com.dijitalkanka.dijital_kanka"

    /** TikTok Ads Manager'ın bu uygulamaya verdiği sayısal kimlik. */
    const val TT_APP_ID = "7684339603290882066"

    /** TikTok'taki adı "App Secret" — SDK'da `TTConfig` constructor'ının
     * `accessToken` parametresi. */
    const val ACCESS_TOKEN = "TT6k6tEFSt4oK38y0nDL9kbwSwXcItaa"
}
