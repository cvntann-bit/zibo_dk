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
 * "Zibo'nun Sözü" — dokuzuncu, DAHA BÜYÜK ana ekran widget'ı (bkz.
 * CLAUDE.md "Ana Ekran Widget'ları" bölümü). Diğer sekiz modülün
 * paylaştığı [ZiboBaseWidgetProvider]'ı EXTEND ETMİYOR — çünkü o sınıf
 * `R.layout.widget_module`u (emoji rozeti + ilerleme çubuğu olan) sabit
 * varsayıyor; bu widget'ın kendi düzeni (`R.layout.widget_motivation`,
 * Zibo karakter görseli + çok satırlı söz metni) yeterince farklı olduğu
 * için ayrı, küçük bir sınıf olarak yazıldı.
 *
 * `dataKeyPrefix` diğerleriyle AYNI kuralı izliyor —
 * [HomeWidgetSyncCoordinator]'ın `motivation_title`/`motivation_primary`
 * anahtarlarıyla BİREBİR eşleşmeli (bkz. `lib/utils/widget_module.dart`).
 * Accent rengi olarak `@color/widget_accent_default`i (uygulamanın kendi
 * "Zibo marka rengi" varsayılanı, açık/koyu temaya göre otomatik doğru
 * çözülüyor) kullanıyor — yeni bir sabit renk İCAT EDİLMEDİ.
 */
class ZiboMotivationWidgetProvider : HomeWidgetProvider() {
  private val dataKeyPrefix = "motivation"

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
            val quote = widgetData.getString("${dataKeyPrefix}_primary", null)

            setInt(R.id.widget_accent_bar, "setBackgroundColor", accentColor)
            setTextViewText(R.id.widget_title, title ?: "Zibo")
            setTextViewText(R.id.widget_quote, quote ?: "…")

            // Diğer sekiz widget'la AYNI basit tıklama deseni — bkz.
            // ZiboBaseWidgetProvider dokümantasyonu.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
