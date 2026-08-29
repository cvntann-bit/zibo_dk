package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Şükran Günlüğü widget'ı — bkz. ZiboBaseWidgetProvider. Accent rengi
 * uygulamanın kendi `_gratitudeGreen` sabitiyle (bkz. gratitude_journal_screen.dart)
 * BİREBİR AYNI. */
class ZiboGratitudeWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "gratitude"
  override val emoji = "🙏"
  override val accentColor = Color.parseColor("#4CAF50")
}
