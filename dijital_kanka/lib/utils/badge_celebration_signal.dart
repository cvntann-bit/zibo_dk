import 'package:flutter/foundation.dart';

import '../models/badge_definition.dart';

/// Yeni kazanılan, HENÜZ kutlanmamış bir rozet — `zibo_event_signal.dart`'taki
/// `pendingZiboEvent` ile AYNI "basit, kalıcılık gerektirmeyen, widget
/// ağacının dışından da yazılabilen global sinyal" deseni.
/// `BadgeCelebrationOverlay` (bkz. o dosya) bunu dinleyip uygulamanın HER
/// YERİNDE (hangi ekranda olursa olsun, `MaterialApp.builder` seviyesinde
/// mount edildiği için) konfeti + kazanım popup'ı gösteriyor.
///
/// **Tek slot, kuyruk DEĞİL** — `pendingZiboEvent` ile AYNI gerekçe: aynı
/// anda birden fazla rozet kazanılırsa (ör. `reconcileConsistencyBadges`
/// tek bir çağrıda birden fazla eşiği aşarsa) yalnızca EN SON rozet
/// gösterilir, öncekiler `BadgeProvider`'da kazanılmış olarak KAYITLI kalır
/// (yalnızca kutlama popup'ı atlanmış olur — kullanıcı Rozetler
/// Galerisi'nde hepsini görebilir).
final ValueNotifier<ZiboBadgeDefinition?> pendingBadgePopup =
    ValueNotifier<ZiboBadgeDefinition?>(null);
