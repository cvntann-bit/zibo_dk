package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Para ve Birikim widget'ı — bkz. ZiboBaseWidgetProvider. Accent rengi
 * uygulamanın kendi Para ve Birikim kategorisi mavisiyle (0xFF1E88E5)
 * BİREBİR AYNI. */
class ZiboMoneyWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "money"
  override val emoji = "💰"
  override val accentColor = Color.parseColor("#1E88E5")
}
