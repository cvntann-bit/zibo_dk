package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color

/** Günlük Giriş Ödülleri widget'ı — bkz. ZiboBaseWidgetProvider. */
class ZiboDailyRewardsWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "dailyRewards"
  override val emoji = "🎁"
  override val accentColor = Color.parseColor("#C79A3D")
}
