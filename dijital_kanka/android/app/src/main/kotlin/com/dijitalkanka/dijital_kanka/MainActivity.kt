package com.dijitalkanka.dijital_kanka

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

/**
 * 2026 güncellemesi — "AdMob reklamı tam ekranı kaplamıyor" bug'ının
 * (bkz. CLAUDE.md "AdMob Entegrasyonu" bölümü, AdActivity'nin manifest tema
 * override'ı) İKİNCİ bir savunma katmanı. Flutter'ın kendi motoru, Android
 * 15+ hedefleyen uygulamalarda `Activity` oluşturulurken
 * `decorFitsSystemWindows`'u KENDİSİ `false`'a ayarlayabiliyor (edge-to-edge
 * desteği) — bu, `styles.xml`'deki manifest-tema düzeyindeki
 * `windowOptOutEdgeToEdgeEnforcement` bayrağının etkisini ÇALIŞMA ZAMANINDA
 * geçersiz kılabilir. `super.onCreate()` çağrısından (Flutter'ın kendi
 * ayarlamasından) HEMEN SONRA burada AÇIKÇA `true`'ya geri döndürerek,
 * `MainActivity`'nin GELENEKSEL (opak durum çubuğu, edge-to-edge OLMAYAN)
 * davranışta KESİN olarak kaldığını KOD SEVİYESİNDE garanti ediyoruz —
 * manifest temasının tek başına yeterli olup olmadığından bağımsız olarak.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, true)
    }
}
