import 'package:flutter/foundation.dart';

/// Bir seviye atlama gerçekleştiğinde `LevelCelebrationOverlay`'e (bkz. o
/// dosyanın dokümantasyonu) haber vermek için — `pendingBadgePopup`/
/// `pendingZiboEvent` ile AYNI "basit, kalıcılık gerektirmeyen, widget
/// ağacının dışından da yazılabilen global `ValueNotifier`" deseni. Değer,
/// ulaşılan YENİ seviye numarası (`null` = gösterilecek bir popup yok).
/// **Tek bir slot, kuyruk DEĞİL** — `pendingBadgePopup`'taki AYNI gerekçe:
/// art arda birden fazla seviye atlansa bile yalnızca EN SON ulaşılan
/// seviye gösterilir.
final ValueNotifier<int?> pendingLevelUp = ValueNotifier<int?>(null);

/// `LevelCelebrationOverlay`'in kendi `BuildContext`'i Navigator'ın ATASI
/// DEĞİL (`MaterialApp.builder` seviyesinde yaşıyor, bkz. `BadgeCelebrationOverlay`
/// dokümantasyonundaki AYNI kısıtlama) — bu yüzden "Paylaş" butonuna
/// basılınca doğrudan `showModalBottomSheet` ÇAĞRILAMIYOR. Bunun yerine bu
/// sinyal (`dailyRewardsPopupRequest` ile AYNI "iste, Navigator'ın İÇİNDEKİ
/// bir widget karşılasın" deseni) ayarlanır — `RootScreen` bunu dinleyip
/// KENDİ (Navigator'ın altındaki) context'iyle sheet'i açar. Değer, paylaşım
/// mesajının kendisi (`null` = bekleyen bir paylaşım isteği yok).
final ValueNotifier<String?> pendingLevelShareMessage = ValueNotifier<String?>(
  null,
);
