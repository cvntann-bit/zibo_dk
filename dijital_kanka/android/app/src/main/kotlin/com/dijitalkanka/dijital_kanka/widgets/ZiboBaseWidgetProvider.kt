package com.dijitalkanka.dijital_kanka.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import com.dijitalkanka.dijital_kanka.MainActivity
import com.dijitalkanka.dijital_kanka.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Ana ekran widget'larının (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü)
 * kompakt (2x2) ÜÇ modül provider'ının (Su Takibi/Para ve Birikim/Günlük
 * Giriş Ödülleri — "Zibo'nun Sözü"/"İstatistiklerim" kendi AYRI carousel
 * layout'larını kullanıyor, bu sınıfı extend ETMİYOR) paylaştığı ortak
 * render mantığı — `res/layout/widget_module.xml` (TEK, paylaşılan
 * RemoteViews şablonu) doldurulur. Her alt sınıf yalnızca [dataKeyPrefix]
 * (Flutter tarafının `HomeWidget.saveWidgetData` ile hangi anahtar
 * önekiyle yazdığı, bkz. `lib/services/home_widget_service.dart`), [emoji],
 * [accentColor] VE [backgroundFrames]'i belirtir — geri kalan HER ŞEY
 * burada, tek yerde.
 *
 * Flutter tarafı `widgetData`'ya üç alan yazıyor (önek + alan adı):
 * `{prefix}_title`, `{prefix}_primary`, `{prefix}_secondary`,
 * `{prefix}_progress` (int, -1 = ilerleme çubuğu gizli). Hiç veri
 * yazılmamışsa (uygulama daha hiç açılmadı / henüz senkronize olmadı)
 * güvenli, dolaylı bir "—" / boş durum gösterilir — asla çökmez.
 */
abstract class ZiboBaseWidgetProvider : HomeWidgetProvider() {
  abstract val dataKeyPrefix: String
  abstract val emoji: String
  abstract val accentColor: Int

  /**
   * **2026 güncellemesi — kullanıcı isteği "her widget'in kendi
   * animasyonu olsun".** Bu alt sınıfa ÖZGÜ, önceden çizilmiş arka plan
   * "sahne" drawable id'lerinin sırası (bkz. `tool/
   * generate_widget_bg_animations.dart`) — [onUpdate] bunları
   * `R.id.widget_bg_flipper`'a (bkz. `widget_module.xml`) sırayla
   * `addView` ile ekleyip TAMAMEN NATIVE (launcher sürecinin kendi
   * zamanlayıcısı) bir `ViewFlipper` döngüsü kurar, "Zibo'nun Sözü"
   * widget'ındaki AYNI teknik.
   */
  abstract val backgroundFrames: List<Int>

  /** [accentColor]'ın DÜŞÜK opaklıklı hâli — rozetin arkasındaki "halo" için
   * (bkz. `widget_module.xml`'deki 2026 görsel güncellemesi). */
  private fun withAlpha(color: Int, alpha: Int): Int =
      Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.widget_module).apply {
            val title = widgetData.getString("${dataKeyPrefix}_title", null)
            val primary = widgetData.getString("${dataKeyPrefix}_primary", null)
            val secondary = widgetData.getString("${dataKeyPrefix}_secondary", null)
            val progress = widgetData.getInt("${dataKeyPrefix}_progress", -1)

            setTextViewText(R.id.widget_icon_emoji, emoji)
            setInt(R.id.widget_icon_halo, "setColorFilter", withAlpha(accentColor, 40))
            setInt(R.id.widget_icon_bg, "setColorFilter", accentColor)
            setInt(R.id.widget_accent_bar, "setBackgroundColor", accentColor)
            setTextViewText(R.id.widget_title, title ?: "Zibo")
            setTextViewText(R.id.widget_primary, primary ?: "—")
            setTextViewText(R.id.widget_secondary, secondary ?: "")

            if (progress in 0..100) {
              setViewVisibility(R.id.widget_progress, View.VISIBLE)
              setProgressBar(R.id.widget_progress, 100, progress, false)
            } else {
              setViewVisibility(R.id.widget_progress, View.GONE)
            }

            removeAllViews(R.id.widget_bg_flipper)
            backgroundFrames.forEach { frameRes ->
              val page = RemoteViews(context.packageName, R.layout.widget_bg_frame)
              page.setImageViewResource(R.id.widget_bg_frame_image, frameRes)
              addView(R.id.widget_bg_flipper, page)
            }

            // Widget'ın HERHANGİ bir yerine dokununca uygulama açılır —
            // modüle özel derin bağlantı (deep link) YOK, bilerek — bkz.
            // CLAUDE.md dokümantasyonu, kapsam bilinçli olarak basit
            // tutuldu (bildirime dokununca Ana Sayfa'ya gitme deseniyle
            // AYNI basitlik tercihi).
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
