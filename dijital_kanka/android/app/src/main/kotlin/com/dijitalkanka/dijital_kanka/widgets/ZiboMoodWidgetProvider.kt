package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Günlük Ruh Hali Takibi widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboMoodWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "mood"
  override val emoji = "😊"
  override val accentColor = Color.parseColor("#D6672B")
}
