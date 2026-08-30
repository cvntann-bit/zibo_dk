package com.dijitalkanka.dijital_kanka.widgets

import android.graphics.Color
import com.dijitalkanka.dijital_kanka.R

/** Para ve Birikim widget'ı — bkz. ZiboBaseWidgetProvider. Accent rengi
 * uygulamanın kendi Para ve Birikim kategorisi mavisiyle (0xFF1E88E5)
 * BİREBİR AYNI. [backgroundFrames] — Zibo logolu (küçük "Z" işaretli),
 * yeşil tonda banknot silüetleri (bkz. `tool/
 * generate_widget_bg_animations.dart`), kullanıcı isteği. */
class ZiboMoneyWidgetProvider : ZiboBaseWidgetProvider() {
  override val dataKeyPrefix = "money"
  override val emoji = "💰"
  override val accentColor = Color.parseColor("#1E88E5")
  override val backgroundFrames =
      listOf(
          R.drawable.widget_bg_money_1,
          R.drawable.widget_bg_money_2,
          R.drawable.widget_bg_money_3,
          R.drawable.widget_bg_money_4,
      )
}
