import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Oyun Salonu analitik olayları (docs/game_zibo.md Faz 4-5): yayından sonra
/// puan oranlarını/tavanları TAHMİNLE değil ölçülen veriyle ayarlamak için.
///
/// Firebase başlatılmamışsa (testler, web önizlemesi) hiçbir şey yapmaz.
/// Hata sessizce yutulur — analitik ASLA oyunu bozmamalı. Olay adları ≤ 40
/// karakter, parametreler yalnızca sayı/metin (Firebase sınırları).
///
/// Olaylar:
/// - `game_open` {game} — oyun ekranı açıldı
/// - `game_start` {game, tier} — tur başladı (hak düştü)
/// - `game_no_plays` {game, tier} — hak yokken başlatılmaya çalışıldı
/// - `game_finish` {game, tier, points, claimed, score} — tur bitti
/// - `game_ad` {game, reason, ok} — oyun içi ödüllü reklam (extraPlay/undo/continue)
/// - `points_exchanged` {zc, cost, week_total, tier} — Takas Gişesi
/// - `exchange_cap_hit` {tier} — haftalık takas tavanı dolu hâlde gişe açıldı
/// - `game_upsell_tap` {costume, missing} — "Mağazada coin al"
/// - `game_pro_tap` {} — gişedeki "Pro ile ..." satırı
class GameAnalytics {
  const GameAnalytics._();

  static void log(String name, [Map<String, Object> params = const {}]) {
    if (Firebase.apps.isEmpty) return;
    unawaited(
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params).catchError((Object e) {
        debugPrint('GameAnalytics $name gönderilemedi: $e');
      }),
    );
  }
}
