package com.dijitalkanka.dijital_kanka.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.dijitalkanka.dijital_kanka.MainActivity
import com.dijitalkanka.dijital_kanka.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Zibo'nun Sözü" — büyük, ViewFlipper tabanlı carousel widget'ı (bkz.
 * CLAUDE.md "Ana Ekran Widget'ları" bölümü). Diğer sekiz modülün paylaştığı
 * [ZiboBaseWidgetProvider]'ı EXTEND ETMİYOR — çünkü o sınıf
 * `R.layout.widget_module`u (emoji rozeti + ilerleme çubuğu olan) sabit
 * varsayıyor; bu widget'ın kendi düzeni yeterince farklı.
 *
 * **2026 güncellemesi — kullanıcı isteği "sözler 3 dakikada bir değişsin".**
 * Flutter tarafı ([HomeWidgetSyncCoordinator._syncMotivation]) artık TEK bir
 * söz değil, `CarouselItem` listesiyle `HomeWidgetService.pushCarousel`
 * çağırıp `motivation_itemCount` + `motivation_item{i}_value` (bu widget'ta
 * yalnızca `value` alanı kullanılıyor — `label`/`progress`/`hasData`
 * "İstatistiklerim" carousel'inin ihtiyacı, bkz. `ZiboProfileStatsWidgetProvider`)
 * şeklinde BİRDEN FAZLA söz gönderiyor — bu sınıf bunları
 * `RemoteViews.addView(...)` ile ÇALIŞMA ZAMANINDA `R.layout.
 * widget_quote_page`den örnekleyip `R.id.widget_quote_flipper`e (bir
 * `ViewFlipper`, `android:flipInterval="180000"` + `autoStart="true"` XML'de
 * STATİK tanımlı) ekliyor — hangi sözün ne zaman göründüğü TAMAMEN NATIVE
 * (launcher sürecindeki `ViewFlipper`'ın kendi `Handler` tabanlı zamanlayıcısı)
 * kontrolünde, Dart/uygulama tarafının HİÇBİR sonraki müdahalesine gerek
 * kalmadan dönmeye devam ediyor.
 */
class ZiboMotivationWidgetProvider : HomeWidgetProvider() {
  private val dataKeyPrefix = "motivation"

  /** **2026 güncellemesi — kullanıcı isteği "her widget'in kendi
   * animasyonu olsun": ampul/fikir temalı arka plan sahneleri** (bkz.
   * `tool/generate_widget_bg_animations.dart`) — `R.id.widget_bg_flipper`'a
   * (içerik carousel'i `widget_quote_flipper`'DAN TAMAMEN AYRI/bağımsız)
   * eklenen SABİT dört kare. */
  private val backgroundFrames =
      listOf(
          R.drawable.widget_bg_motivation_1,
          R.drawable.widget_bg_motivation_2,
          R.drawable.widget_bg_motivation_3,
          R.drawable.widget_bg_motivation_4,
      )

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val accentColor = ContextCompat.getColor(context, R.color.widget_accent_default)
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.widget_motivation).apply {
            val title = widgetData.getString("${dataKeyPrefix}_title", null)
            setInt(R.id.widget_accent_bar, "setBackgroundColor", accentColor)
            setTextViewText(R.id.widget_title, title ?: "Zibo")

            removeAllViews(R.id.widget_bg_flipper)
            backgroundFrames.forEach { frameRes ->
              val bgPage = RemoteViews(context.packageName, R.layout.widget_bg_frame)
              bgPage.setImageViewResource(R.id.widget_bg_frame_image, frameRes)
              addView(R.id.widget_bg_flipper, bgPage)
            }

            val itemCount = widgetData.getInt("${dataKeyPrefix}_itemCount", 0)
            removeAllViews(R.id.widget_quote_flipper)
            if (itemCount > 0) {
              for (i in 0 until itemCount) {
                val quote = widgetData.getString("${dataKeyPrefix}_item${i}_value", null) ?: continue
                val page = RemoteViews(context.packageName, R.layout.widget_quote_page)
                page.setTextViewText(R.id.widget_quote_text, quote)
                addView(R.id.widget_quote_flipper, page)
              }
            } else {
              // Henüz hiç senkronize olmadı (uygulama daha hiç açılmadı) —
              // güvenli, tek sayfalık bir "—" durumu.
              val page = RemoteViews(context.packageName, R.layout.widget_quote_page)
              page.setTextViewText(R.id.widget_quote_text, "—")
              addView(R.id.widget_quote_flipper, page)
            }

            // Diğer widget'larla AYNI basit tıklama deseni — bkz.
            // ZiboBaseWidgetProvider dokümantasyonu.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
