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
/// yalnızca tetikleyicisi farklı.
final ValueNotifier<int> dailyRewardsPopupRequest = ValueNotifier<int>(0);
