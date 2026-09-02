import 'package:flutter/material.dart';

/// `MaterialApp.navigatorKey`'e bağlanan global anahtar — `BadgeCelebrationOverlay`
/// gibi `MaterialApp.builder` SEVİYESİNDE yaşayan widget'ların (kendi
/// `BuildContext`'i Navigator'ın ATASI DEĞİL — `MaterialApp.builder`'ın
/// `context` parametresi `MaterialApp`'in KENDİSİNİN üstünde/dışında kalır,
/// bu yüzden `Navigator.of(context)` orada ÇALIŞMAZ) uygulamanın GERÇEK
/// Navigator'ına erişebilmesi için — Flutter'ın "widget ağacının dışından/
/// üstünden gezinme" ihtiyacı için standart/belgelenmiş çözüm (push
/// bildirimi/deep-link handler'larında da yaygın kullanılan desen).
final rootNavigatorKey = GlobalKey<NavigatorState>();
