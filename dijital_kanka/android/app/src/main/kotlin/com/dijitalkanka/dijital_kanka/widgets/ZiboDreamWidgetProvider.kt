package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Rüya Günlüğü widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboDreamWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "dream"
  override val emoji = "🌙"
  override val accentColor = Color.parseColor("#4C5FA8")
}
