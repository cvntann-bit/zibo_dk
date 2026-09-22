import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/push_notification_type.dart';
import '../services/cloud_state_store.dart';

/// **2026 yeni özellik — FCM (Firebase Cloud Messaging) tabanlı push
/// bildirimler.** Eski `NotificationProvider`/`notificationsFeatureEnabled`
/// sistemi (bkz. o dosyadaki uzun MIUI/HyperOS tanı notu) tamamen YEREL
/// (`AlarmManager` + `flutter_local_notifications`) bir mekanizmaydı ve
/// üreticiye özel arka plan kısıtlamaları yüzünden güvenilir çalışmıyordu —
/// bu yeni sistem bunun YERİNE değil, YANINA eklendi: gönderim artık
/// workspace kökündeki `notification-scripts/` (GitHub Actions cron'larından
/// çalışan bağımsız Node.js betikleri, Cloud Functions/Scheduler GEREKMEZ)
/// tarafında, sunucu tarafında tetikleniyor; cihazın kendi arka plan
/// alarmına hiç bağımlı değil.
///
/// Bu provider BEŞ push bildirim türünün açık/kapalı tercihini tutar (bkz.
/// `PushNotificationType`) — gerçek token kaydı/dinleme
/// `PushNotificationService`'te. `CloudStateStore` ile kalıcı (`uid` varsa
/// Firestore'a da yazılır) — `notification-scripts/src/common.js`'teki
/// `isTypeEnabled` bu tercihleri Admin SDK ile
/// `users/{uid}/state/pushNotificationState` dokümanından OKUYUP her
/// betikte filtreleme yapıyor (bkz. CLAUDE.md "Push Bildirimleri" bölümü).
class PushNotificationProvider extends ChangeNotifier {
  PushNotificationProvider({String? uid})
    : _uid = uid,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'pushNotificationState';

  final String? _uid;
  final CloudStateStore _store;

  // Varsayılan hepsi AÇIK — kullanıcı isterse Ayarlar'dan tek tek kapatabilir
  // (bildirimler bu uygulamanın ana etkileşim mekanizmalarından biri olarak
  // tasarlandığı için, eski `NotificationProvider`'ın varsayılan "Günde 3"
  // tercihiyle AYNI gerekçe).
  bool _dailyMotivation = true;
  bool _streakReminder = true;
  bool _dailyReward = true;
  bool _reEngagement = true;
  bool _waterReminder = true;

  /// **Faz 5 (E2)** — Zibo Pro+'a özel bildirim sesi tercihi (`'1'|'2'|'3'`,
  /// `null` = varsayılan `zibo_notification` sesi). Yalnızca UI-tarafı
  /// tercih burada tutuluyor (`pushNotificationState` dokümanı,
  /// `CloudStateStore`) — sunucunun (`notification-scripts`) OKUYABİLMESİ
  /// için AYRICA `users/{uid}` KÖK dokümanına da yazılıyor (bkz.
  /// `PushNotificationService.updateProPlusSoundChoice` — `timeZone` ile
  /// AYNI "Pattern B" gerekçesi: 5 bildirim betiğinin HEPSİ aynı seçimi
  /// kullanmalı, `fetchAllUsers()` ile zaten TEK seferde gelen bir kök alan
  /// betik başına ek Firestore sorgusundan daha ucuz).
  String? _proPlusSoundChoice;

  bool isEnabled(PushNotificationType type) => switch (type) {
    PushNotificationType.dailyMotivation => _dailyMotivation,
    PushNotificationType.streakReminder => _streakReminder,
    PushNotificationType.dailyReward => _dailyReward,
    PushNotificationType.reEngagement => _reEngagement,
    PushNotificationType.waterReminder => _waterReminder,
  };

  String? get proPlusSoundChoice => _proPlusSoundChoice;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      _dailyMotivation = data['dailyMotivation'] as bool? ?? true;
      _streakReminder = data['streakReminder'] as bool? ?? true;
      _dailyReward = data['dailyReward'] as bool? ?? true;
      _reEngagement = data['reEngagement'] as bool? ?? true;
      _waterReminder = data['waterReminder'] as bool? ?? true;
      _proPlusSoundChoice = data['proPlusSoundChoice'] as String?;
    }
    notifyListeners();
  }

  Future<void> setEnabled(PushNotificationType type, bool value) async {
    switch (type) {
      case PushNotificationType.dailyMotivation:
        if (_dailyMotivation == value) return;
        _dailyMotivation = value;
      case PushNotificationType.streakReminder:
        if (_streakReminder == value) return;
        _streakReminder = value;
      case PushNotificationType.dailyReward:
        if (_dailyReward == value) return;
        _dailyReward = value;
      case PushNotificationType.reEngagement:
        if (_reEngagement == value) return;
        _reEngagement = value;
      case PushNotificationType.waterReminder:
        if (_waterReminder == value) return;
        _waterReminder = value;
    }
    notifyListeners();
    await _save();
  }

  /// **Faz 5 (E2)** — `'1'|'2'|'3'` (bkz. `LocalNotificationService`'in Pro+
  /// kanalları) veya `null` (varsayılan). Yalnızca Ayarlar'daki Pro+-korumalı
  /// seçim satırından çağrılır. `CloudStateStore`'a ([_store]) EK OLARAK
  /// `users/{uid}` KÖK dokümanına da yazıyor — sunucu betiklerinin
  /// (`notification-scripts/src/common.js`) `fetchAllUsers()` ile ZATEN
  /// aldığı aynı dokümandan okuyabilmesi için (`timeZone`/`lastActiveAt` ile
  /// AYNI desen, bkz. `PushNotificationService.touchLastActive`). `uid`
  /// `null` ise (Firebase kullanılamıyor) yalnızca yerel/`CloudStateStore`
  /// kalıcılığı çalışır — sessizce atlanır, diğer `CloudStateStore` yazma
  /// yollarındaki AYNI "asla çökme" güvenlik ağı.
  Future<void> setProPlusSoundChoice(String? choice) async {
    if (_proPlusSoundChoice == choice) return;
    _proPlusSoundChoice = choice;
    notifyListeners();
    await _save();
    if (_uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'proPlusSoundChoice': _proPlusSoundChoice,
      }, SetOptions(merge: true));
    } catch (_) {
      // Yoksayılır — bir sonraki değişiklikte tekrar denenecek, yerel
      // tercih zaten kaydedildi.
    }
  }

  Future<void> _save() {
    return _store.save({
      'dailyMotivation': _dailyMotivation,
      'streakReminder': _streakReminder,
      'dailyReward': _dailyReward,
      'reEngagement': _reEngagement,
      'waterReminder': _waterReminder,
      'proPlusSoundChoice': _proPlusSoundChoice,
    });
  }
}
