package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Su Takibi widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboWaterWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "water"
  override val emoji = "💧"
  override val accentColor = Color.parseColor("#2F7FBF")
}
