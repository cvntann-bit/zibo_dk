package com.dijitalkanka.dijital_kanka

import android.media.MediaPlayer
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
}
