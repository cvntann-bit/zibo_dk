package com.dijitalkanka.dijital_kanka.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.dijitalkanka.dijital_kanka.MainActivity
import com.dijitalkanka.dijital_kanka.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "İstatistiklerim" — beş kaldırılan basit widget'ın (Hedef Takibi/Rüya
 * Günlüğü/Şükran Günlüğü/Ruh Hali Takibi/Manifest Günlüğü) YERİNE geçen,
 * Profil ekranındaki DÖRT kategoriyi (bkz. `lib/utils/profile_stats.dart`)
 * bir `ViewFlipper` ile sırayla, animasyonla döndüren carousel widget'ı —
 * bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü. `ZiboMotivationWidgetProvider`
 * ile AYNI `RemoteViews.addView(...)` + `ViewFlipper` deseni ve AYNI
 * `{prefix}_item{i}_*` anahtar sözleşmesi (`HomeWidgetService.pushCarousel`),
 * ama her sayfanın accent rengi FARKLI (bkz. altta [pageLayoutForIndex]) ve
 * bu widget `value`nun YANINDA `label`/`progress`/`hasData`'yı da kullanıyor.
 *
 * Flutter tarafı ([HomeWidgetSyncCoordinator._syncProfileStats]) DAİMA
 * `ProfileStats.compute()`'un döndürdüğü SABİT sırayla (Para Yönetimi,
 * Şükür ve Manifest, İstikrar, Öz Saygı ve Sağlık — `ProfileStatCategory`
 * enum sırası) gönderiyor — bu sınıf `i` (0-3) İNDEKSİNE göre HANGİ
 * önceden-tonlanmış `widget_stat_page_*` layout'unun kullanılacağını
 * seçiyor (bkz. o dosyaların dokümantasyonundaki "sıfır reflection riski"
 * notu).
 */
class ZiboProfileStatsWidgetProvider : HomeWidgetProvider() {
  private val dataKeyPrefix = "profileStats"

  private fun pageLayoutForIndex(index: Int): Int =
      when (index) {
        0 -> R.layout.widget_stat_page_money
        1 -> R.layout.widget_stat_page_gratitude
        2 -> R.layout.widget_stat_page_consistency
        else -> R.layout.widget_stat_page_selfcare
      }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.widget_profile_stats).apply {
            val title = widgetData.getString("${dataKeyPrefix}_title", null)
            setTextViewText(R.id.widget_title, title ?: "Zibo")

            val itemCount = widgetData.getInt("${dataKeyPrefix}_itemCount", 0)
            removeAllViews(R.id.widget_stats_flipper)
            if (itemCount > 0) {
              for (i in 0 until itemCount) {
                val hasData = widgetData.getInt("${dataKeyPrefix}_item${i}_hasData", 0) == 1
                val label = widgetData.getString("${dataKeyPrefix}_item${i}_label", null) ?: continue
                val value = widgetData.getString("${dataKeyPrefix}_item${i}_value", null) ?: continue
                val progress = widgetData.getInt("${dataKeyPrefix}_item${i}_progress", -1)

                val page = RemoteViews(context.packageName, pageLayoutForIndex(i))
                page.setTextViewText(R.id.widget_stat_label, label)
                page.setTextViewText(R.id.widget_stat_value, if (hasData) value else "—")
                if (hasData && progress in 0..100) {
                  page.setProgressBar(R.id.widget_stat_progress, 100, progress, false)
                } else {
                  page.setProgressBar(R.id.widget_stat_progress, 100, 0, false)
                }
                addView(R.id.widget_stats_flipper, page)
              }
            } else {
              // Henüz hiç senkronize olmadı — güvenli, tek sayfalık bir
              // "—" durumu.
              val page = RemoteViews(context.packageName, R.layout.widget_stat_page_money)
              page.setTextViewText(R.id.widget_stat_label, "Zibo")
              page.setTextViewText(R.id.widget_stat_value, "—")
              addView(R.id.widget_stats_flipper, page)
            }

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
