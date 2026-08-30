package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color
import com.dijitalkanka.dijital_kanka.R

/** Su Takibi widget'ı — bkz. ZiboBaseWidgetProvider. [backgroundFrames] —
 * yavaşça hareket eden dalga sahneleri (bkz. `tool/
 * generate_widget_bg_animations.dart`), kullanıcı isteği. */
class ZiboWaterWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "water"
  override val emoji = "💧"
  override val accentColor = Color.parseColor("#2F7FBF")
  override val backgroundFrames =
      listOf(
          R.drawable.widget_bg_water_1,
          R.drawable.widget_bg_water_2,
          R.drawable.widget_bg_water_3,
          R.drawable.widget_bg_water_4,
      )
}
