import 'package:flutter/foundation.dart';

/// Bildirime dokunulduğunda (uygulama zaten açıkken, ön/arka planda)
/// [RootScreen]'in Ana Sayfa sekmesine atlaması için dinlediği basit bir
/// sinyal. Değerin kendisi önemli değil — her artış "Ana Sayfa'ya geç"
/// anlamına gelir (soğuk başlangıçta zaten [RootScreen] varsayılan olarak
/// Ana Sayfa'da açıldığı için bu yalnızca uygulama ZATEN ÇALIŞIRKEN gelen
/// bir dokunuş için gerekli).
final ValueNotifier<int> homeTabRequest = ValueNotifier<int>(0);

/// [RootScreen]'in şu an gösterilen sekmesinin Ana Sayfa olup olmadığı —
/// varsayılan `true` (uygulama Ana Sayfa'da açılıyor). `AnimatedThemeOverlay`
/// (bkz. o dosyadaki 2026 güncellemesi) bunu dinleyip Premium/Animasyonlu
/// tema parçacık efektini YALNIZCA Ana Sayfa aktifken çiziyor — diğer
/// sekmelerde/pushed ekranlarda (Hedef Takibi, Su Takibi, Mağaza, Profil,
/// Ayarlar vb.) tema rengi/arka planı uygulanmaya devam ediyor, yalnızca
/// hareketli katman gizleniyor (performans + dikkat dağıtmama).
final ValueNotifier<bool> isHomeTabActive = ValueNotifier<bool>(true);

/// [homeTabRequest] ile AYNI desen — Hedef Takibi sekmesine atlanmasını
/// istemek için (bkz. "Streak Hatırlatması" push bildirimine dokununca,
/// `PushNotificationService`). Değerin kendisi önemli değil, her artış
/// "Hedef Takibi'ne geç" anlamına gelir.
final ValueNotifier<int> goalsTabRequest = ValueNotifier<int>(0);

/// Ana Sayfa'ya geçtikten HEMEN SONRA Günlük Giriş Ödülleri popup'ının
/// açılmasını istemek için (bkz. "Günlük Ödül Hatırlatması" push
/// bildirimine dokununca). `RootScreen` bunu dinleyip Ana Sayfa'ya
/// geçtikten sonra `DailyRewardsScreen`'i `showDialog` ile açıyor —
/// `DailyRewardsTriggerButton`'ın kendi `onTap`'iyle AYNI mekanizma,
/// yalnızca tetikleyicisi farklı. **2026 güncellemesi — artık "Günlük
/// Giriş Ödülleri" widget'ına dokununca da (bkz. `RootScreen.
/// _handleWidgetModuleTap`) AYNI sinyal kullanılıyor.**
final ValueNotifier<int> dailyRewardsPopupRequest = ValueNotifier<int>(0);

/// **2026 yeni özellik — widget derin bağlantısı.** Su Takibi widget'ına
/// dokununca `WaterTrackingScreen`'in DOĞRUDAN (Ana Sayfa'dan geçmeden)
/// push edilmesini istemek için — [goalsTabRequest] ile AYNI "değerin
/// kendisi önemli değil, her artış bir eylem anlamına gelir" deseni.
/// `RootScreen` bunu dinleyip `modules_menu_sheet.dart`'ın Su Takibi'ni
/// açtığı AYNI `MaterialPageRoute` ile push ediyor.
final ValueNotifier<int> waterModuleRequest = ValueNotifier<int>(0);

/// [waterModuleRequest] ile AYNI desen — Para ve Birikim widget'ına
/// dokununca `MoneyScreen`'in doğrudan push edilmesini istemek için.
final ValueNotifier<int> moneyModuleRequest = ValueNotifier<int>(0);

/// [goalsTabRequest] ile AYNI desen — "İstatistiklerim" widget'ına
/// dokununca Profil sekmesine geçilmesini istemek için (push
/// bildirimlerinin hiçbirinin ihtiyaç duymadığı, bu yüzden önceden hiç
/// olmayan YENİ bir sinyal — bkz. `RootScreen._profileTabIndex`).
final ValueNotifier<int> profileTabRequest = ValueNotifier<int>(0);
