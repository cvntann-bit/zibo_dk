import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Zibo Dünyası + Zibo'nun Evi analitik olayları (2026-11-06,
/// docs/zibo_world.md düzeltme listesi madde 2): yemek/dekor fiyatlarını,
/// ücretsiz yemek ve reklam haklarını, kilitli kapılara olan ilgiyi TAHMİNLE
/// değil ölçülen veriyle ayarlamak için.
///
/// Firebase başlatılmamışsa (testler, web önizlemesi) hiçbir şey yapmaz; hata
/// sessizce yutulur — analitik ASLA uygulamayı bozmamalı. Olay adları ≤ 40
/// karakter, parametreler yalnızca sayı/metin (Firebase sınırları).
///
/// Olaylar (DebugView'da `world_*` / `home_*` / `event_*` ile süzülür):
/// - `world_place_open` {place, via} — giriş ekranında bir yer açıldı
///   (place: home/games/events; via: building/bubble)
/// - `world_locked_tap` {place} — kilitli kapı (leaderboard/friends) — talep ölçüsü
/// - `home_open` {room, asleep} — ev ekranı açıldı (açılan oda)
/// - `home_room_switch` {to} — odalar arası geçiş
/// - `home_food_pick` {food, kind, cost} — yemek tabağa geldi (kind: free/paid/ad)
/// - `home_food_blocked` {reason, tier} — yemek verilemedi (no_free/no_coins/full)
/// - `home_feed` {food} — Zibo yemeği yedi
/// - `home_bath_done` {soap} — havluyla kurulandı (tertemiz)
/// - `home_sleep` {energy} / `home_wake` {energy} — ışık kapat/aç (o anki enerji %)
/// - `home_wake_prompt` {} — uyurken oda değiştirmeye çalışıldı ("önce uyandır")
/// - `home_tired_bubble` {action} — salondaki yorgunluk balonu (bed/close)
/// - `home_play` {game, gained} — salondan oyun (gained = kazanılan ★)
/// - `home_decor_buy` {room, items, cost, tier} — dekor sepeti satın alındı
/// - `home_soap_buy` {soap, cost, tier} — sabun satın alındı
/// - `home_locked_buy` {item, need, tier} — abone serisi eşyayı abone olmadan almaya çalıştı (paywall talebi)
/// - `event_box_open` {event, day, zc, item} — etkinlik kutusu açıldı
///
/// Reklamla yemek: `rewarded_result{placement: homeFood}` ([AdAnalytics]).
class WorldAnalytics {
  const WorldAnalytics._();

  static void log(String name, [Map<String, Object> params = const {}]) {
    if (Firebase.apps.isEmpty) return;
    unawaited(
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params).catchError((Object e) {
        debugPrint('WorldAnalytics $name gönderilemedi: $e');
      }),
    );
  }
}
