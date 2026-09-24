package com.dijitalkanka.dijital_kanka

import android.media.MediaPlayer
import android.os.Bundle
import com.tiktok.TikTokBusinessSdk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tikTokDiagnosticChannel: MethodChannel? = null
    private var pendingTikTokDiagnostic: String? = null
    private var soundPreviewPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dijital_kanka/sound_preview",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> result.success(playRawSound(call.argument<String>("name")))
                else -> result.notImplemented()
            }
        }
        tikTokDiagnosticChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "dijital_kanka/tiktok_sdk_diagnostic",
            )
        // `initTikTokBusinessSdk()` sonucu, bu kanal kurulmadan ÖNCE gelmiş
        // olabilir (çok küçük bir ihtimal, ama initializeSdk'nın senkron bir
        // erken-hata dönme yolu var) — o durumda kaybolmasın diye burada
        // bekletilip kanal hazır olur olmaz gönderiliyor.
        pendingTikTokDiagnostic?.let {
            sendTikTokDiagnostic(it)
            pendingTikTokDiagnostic = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initTikTokBusinessSdk()
    }

    override fun onDestroy() {
        soundPreviewPlayer?.release()
        soundPreviewPlayer = null
        super.onDestroy()
    }

    /**
     * Ayarlar'daki Pro+ bildirim sesi ▶ önizlemesi — `res/raw/[name]`'i çalar.
     * `audioplayers`'ın `UrlSource`'u `android.resource://` URI'sini
     * çalamıyor (`MediaPlayer.setDataSource(String)` bu şemayı native
     * katmana düz yol olarak veriyor → "Failed to set source"), bu yüzden
     * `MediaPlayer.create(Context, resId)` ile burada çalınıyor. Adla
     * çözüldüğü için kaynaklar `res/raw/keep.xml`'de listeli olmalı.
     * Yeni önizleme çalan öncekini durdurur.
     */
    private fun playRawSound(name: String?): Boolean {
        if (name == null) return false
        val resId = resources.getIdentifier(name, "raw", packageName)
        if (resId == 0) return false
        soundPreviewPlayer?.release()
        soundPreviewPlayer = null
        val player = MediaPlayer.create(this, resId) ?: return false
        soundPreviewPlayer = player
        player.setOnCompletionListener {
            it.release()
            if (soundPreviewPlayer === it) soundPreviewPlayer = null
        }
        player.start()
        return true
    }

    /**
     * TikTok SDK'sının başlatma sonucunu (başarı/hata/istisna) Dart tarafına
     * — oradan da mevcut `FirebaseCrashlytics.instance.recordError(...)`
     * (bkz. main.dart, `AppodealAdService` init hatalarıyla AYNI desen)
     * yoluyla Firebase Console'a — taşır. TEK amaç: Events Manager'da
     * "Pending verification" durumu değişmeden kalırsa (bkz. CLAUDE.md
     * "TikTok Business SDK" bölümü), cihaza fiziksel erişim/adb GEREKMEDEN
     * SDK'nın gerçekte ne yaptığını (sessizce mi başarısız oluyor, hangi
     * hata koduyla) uzaktan görebilmek.
     */
    private fun sendTikTokDiagnostic(message: String) {
        val channel = tikTokDiagnosticChannel
        if (channel == null) {
            pendingTikTokDiagnostic = message
            return
        }
        runOnUiThread { channel.invokeMethod("log", message) }
    }

    /**
     * TikTok Ads — kurulum/olay takibi (bkz. [TikTokConfig] dokümantasyonu).
     * `TTConfig`'in kendi `ProcessLifecycleOwner` dinleyicisi "uygulama
     * kuruldu/açıldı" olayını OTOMATİK gönderiyor — bu çağrının kendisi
     * dışında hiçbir ek kod GEREKMİYOR. Uygulamanın tek `Activity`'si
     * olduğu için burada (Application alt sınıfı açmaya gerek kalmadan)
     * başlatmak yeterli — `getApplication()` zaten tüm süreç ömrü boyunca
     * yaşayan tek örneği veriyor.
     *
     * `TTInitCallback` + `LogLevel.DEBUG`: Events Manager'da hiç event
     * görünmemesi ("No event data yet") üzerine eklendi — `initializeSdk`'nın
     * tek parametreli (callback'siz) overload'u başarı/hata konusunda
     * TAMAMEN sessiz, teşhis imkânsızdı.
     *
     * Appodeal/Firebase gibi diğer HER üçüncü taraf SDK başlatmasıyla AYNI
     * gerekçeyle try/catch'li: bir reklam/ölçüm SDK'sının başlatma hatası
     * uygulamanın AÇILAMAMASINA yol açmamalı.
     */
    private fun initTikTokBusinessSdk() {
        try {
            val config =
                TikTokBusinessSdk.TTConfig(application, TikTokConfig.ACCESS_TOKEN)
                    .setAppId(TikTokConfig.APP_ID)
                    .setTTAppId(TikTokConfig.TT_APP_ID)
                    .setLogLevel(TikTokBusinessSdk.LogLevel.DEBUG)
            TikTokBusinessSdk.initializeSdk(
                config,
                object : TikTokBusinessSdk.TTInitCallback {
                    override fun success() {
                        sendTikTokDiagnostic(
                            "TikTok SDK init OK, isInitialized=" +
                                TikTokBusinessSdk.isInitialized(),
                        )
                    }

                    override fun fail(
                        code: Int,
                        msg: String,
                    ) {
                        sendTikTokDiagnostic("TikTok SDK init FAILED code=$code msg=$msg")
                    }
                },
            )
        } catch (e: Exception) {
            sendTikTokDiagnostic(
                "TikTok SDK init EXCEPTION: ${e.javaClass.simpleName}: ${e.message}",
            )
        }
    }
}
