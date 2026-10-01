import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Banner reklam teşhis olayları (2026-10-02): Appodeal panelinde canlı banner
/// isteğinin neredeyse HİÇ görünmemesinin nedenini TAHMİNLE değil ölçülen
/// veriyle bulmak için — SDK'nın banner'ı canlıda gerçekten yükleyip
/// yükleyemediği, gösterip gösteremediği Firebase'de görünsün.
///
/// Firebase başlatılmamışsa (testler, web önizlemesi) hiçbir şey yapmaz; hata
/// sessizce yutulur — analitik ASLA reklamı/uygulamayı bozmamalı.
///
/// Olaylar (hepsi `banner_` ile başlar; DebugView'da `banner_*` ile süzülür):
/// - `banner_loaded` {precache} — SDK bir banner'ı önbelleğe aldı (FILL VAR)
/// - `banner_failed` {} — SDK banner'ı yükleyemedi (no-fill / ağ hatası)
/// - `banner_shown` {} — banner ekranda gösterildi (gelir ancak bununla)
/// - `banner_show_failed` {} — yüklenmiş banner gösterilemedi (yerleşim/ebeveyn sorunu)
/// - `banner_clicked` {} — kullanıcı banner'a dokundu
/// - `banner_expired` {} — önbellekteki banner süresi doldu
/// - `appodeal_init` {ok, errors} — SDK başlatma sonucu (errors = hata sayısı)
///
/// Yorumlama: `failed` >> `loaded` ise sorun TALEP (no-fill, Appodeal/ağ
/// tarafı); `loaded` var ama `shown` yok ise sorun BİZİM yerleşimimiz
/// (`BannerAdSlot`); hiçbir `banner_*` yok ise SDK banner'ı hiç istemiyor
/// (init türü / ebeveyn / consent).
class AdAnalytics {
  const AdAnalytics._();

  static void log(String name, [Map<String, Object> params = const {}]) {
    if (Firebase.apps.isEmpty) return;
    unawaited(
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params).catchError((Object e) {
        debugPrint('AdAnalytics $name gönderilemedi: $e');
      }),
    );
  }
}
