package com.dijitalkanka.dijital_kanka.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.dijitalkanka.dijital_kanka.MainActivity
import com.dijitalkanka.dijital_kanka.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Ana ekran widget'larının (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü)
 * SEKİZ modül provider'ının TÜMÜNÜN paylaştığı ortak render mantığı —
 * `res/layout/widget_module.xml` (TEK, paylaşılan RemoteViews şablonu)
 * doldurulur. Her alt sınıf yalnızca [dataKeyPrefix] (Flutter tarafının
 * `HomeWidget.saveWidgetData` ile hangi anahtar önekiyle yazdığı, bkz.
 * `lib/services/home_widget_service.dart`), [emoji] ve [accentColor]'ı
 * belirtir — geri kalan HER ŞEY burada, tek yerde.
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
            setInt(R.id.widget_icon_bg, "setColorFilter", accentColor)
            setTextViewText(R.id.widget_title, title ?: "Zibo")
            setTextViewText(R.id.widget_primary, primary ?: "—")
            setTextViewText(R.id.widget_secondary, secondary ?: "")

            if (progress in 0..100) {
              setViewVisibility(R.id.widget_progress, View.VISIBLE)
              setProgressBar(R.id.widget_progress, 100, progress, false)
            } else {
              setViewVisibility(R.id.widget_progress, View.GONE)
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
