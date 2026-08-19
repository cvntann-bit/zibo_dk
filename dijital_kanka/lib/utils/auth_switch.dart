import 'package:flutter/foundation.dart';

/// Kullanıcı yeni bir cihazda "Google ile Giriş Yap" akışıyla önceden
/// bağladığı bir hesabı KURTARDIĞINDA, dönen uid buraya yazılır — `main.
/// dart`'taki `_AppRoot` bunu dinleyip TÜM `MultiProvider` ağacını (ve
/// altındaki her provider'ı) YENİ uid ile SIFIRDAN kuruyor
/// (`KeyedSubtree(key: ValueKey(uid))` — `ProfileScreen`'in istatistik
/// kartları animasyonunu her girişte yeniden oynatmak için kullandığı AYNI
/// "değişen Key ile zorla yeniden kurdurma" tekniği, bkz. CLAUDE.md).
///
/// `isAdShowing`/`isHomeTabActive` (bkz. `ad_overlay_state.dart`/
/// `tab_navigation.dart`) ile AYNI "basit, paylaşılan global sinyal"
/// deseni — `AuthLinkProvider` bir widget OLMADIĞI için (saf bir provider)
/// bu global değişkenden başka bir yolla `main.dart`'ın kök widget'ına
/// "uid'i değiştir" diyemiyor.
final ValueNotifier<String?> switchToUid = ValueNotifier<String?>(null);
