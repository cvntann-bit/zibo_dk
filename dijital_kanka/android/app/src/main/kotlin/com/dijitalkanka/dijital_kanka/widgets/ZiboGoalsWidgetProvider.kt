package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Hedef Takibi widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboGoalsWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "goals"
  override val emoji = "🎯"
  override val accentColor = Color.parseColor("#A9711F")
}
