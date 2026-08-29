package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Manifest Günlüğü widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboManifestWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "manifest"
  override val emoji = "✨"
  override val accentColor = Color.parseColor("#8E5FC4")
}
