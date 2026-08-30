package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color
import com.dijitalkanka.dijital_kanka.R

/** Günlük Giriş Ödülleri widget'ı — bkz. ZiboBaseWidgetProvider.
 * [backgroundFrames] — hafifçe yükselip alçalan hediye kutusu sahneleri
 * (bkz. `tool/generate_widget_bg_animations.dart`), kullanıcı isteği. */
class ZiboDailyRewardsWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "dailyRewards"
  override val emoji = "🎁"
  override val accentColor = Color.parseColor("#C79A3D")
  override val backgroundFrames =
      listOf(
          R.drawable.widget_bg_daily_rewards_1,
          R.drawable.widget_bg_daily_rewards_2,
          R.drawable.widget_bg_daily_rewards_3,
          R.drawable.widget_bg_daily_rewards_4,
      )
}
