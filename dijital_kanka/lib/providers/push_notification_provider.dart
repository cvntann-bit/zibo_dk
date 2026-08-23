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
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'pushNotificationState';

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

  bool isEnabled(PushNotificationType type) => switch (type) {
    PushNotificationType.dailyMotivation => _dailyMotivation,
    PushNotificationType.streakReminder => _streakReminder,
    PushNotificationType.dailyReward => _dailyReward,
    PushNotificationType.reEngagement => _reEngagement,
    PushNotificationType.waterReminder => _waterReminder,
  };

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      _dailyMotivation = data['dailyMotivation'] as bool? ?? true;
      _streakReminder = data['streakReminder'] as bool? ?? true;
      _dailyReward = data['dailyReward'] as bool? ?? true;
      _reEngagement = data['reEngagement'] as bool? ?? true;
      _waterReminder = data['waterReminder'] as bool? ?? true;
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
    await _store.save({
      'dailyMotivation': _dailyMotivation,
      'streakReminder': _streakReminder,
      'dailyReward': _dailyReward,
      'reEngagement': _reEngagement,
      'waterReminder': _waterReminder,
    });
  }
}
