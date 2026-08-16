// NotificationProvider'ın sıklık/saat tercihini doğru tuttuğunu, bunu
// SharedPreferences ile kalıcı sakladığını ve her değişiklikte
// NotificationService'i (cancelAll + doğru sayıda scheduleDaily) doğru
// çağırdığını doğrudan (widget pump'lamadan) test eder. Gerçek platform
// channel'a hiç dokunulmaz — sahte bir NotificationService enjekte edilir.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/notification_provider.dart';
import 'package:dijital_kanka/services/notification_service.dart';

class _RecordingFakeNotificationService extends NotificationService {
  _RecordingFakeNotificationService();

  int cancelAllCallCount = 0;
  final List<({int id, TimeOfDay time, String title, String body})>
  scheduledCalls = [];

  @override
  Future<void> initialize({required void Function() onNotificationTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
    scheduledCalls.clear();
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    scheduledCalls.add((id: id, time: time, title: title, body: body));
  }

  bool batteryOptimizationIgnored = false;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async =>
      batteryOptimizationIgnored;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    batteryOptimizationIgnored = true;
  }

  int openAutostartCallCount = 0;

  @override
  Future<void> openAutostartOrAppSettings() async {
    openAutostartCallCount++;
  }

  int openUnusedAppsCallCount = 0;

  @override
  Future<void> openUnusedAppsSettings() async {
    openUnusedAppsCallCount++;
  }

  @override
  Future<bool> hasPermission() async => true;

  int showNowCallCount = 0;

  @override
  Future<void> showTestNotificationNow() async {
    showNowCallCount++;
  }

  Duration? lastScheduledTestDelay;

  @override
  Future<void> scheduleTestNotificationIn(Duration delay) async {
    lastScheduledTestDelay = delay;
  }

  @override
  Future<void> showNow({required String title, required String body}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Varsayılan sıklık Günde 3, üç zaman dilimi de varsayılan saatlerde', () async {
    final service = _RecordingFakeNotificationService();
    final provider = NotificationProvider(notificationService: service);
    await Future<void>.delayed(Duration.zero);

    expect(provider.frequency, NotificationFrequency.thrice);
    expect(provider.times, [
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
    ]);
  });

  test(
    'initializeAndSchedule Günde 3 iken üç farklı sözle üç bildirim planlar',
    () async {
      final service = _RecordingFakeNotificationService();
      final provider = NotificationProvider(notificationService: service);
      await provider.initializeAndSchedule();

      expect(service.cancelAllCallCount, 1);
      expect(service.scheduledCalls.length, 3);
      expect(
        service.scheduledCalls.map((c) => c.id).toSet(),
        {0, 1, 2},
      );
      // Her dilim birbirinden farklı bir söz almalı.
      expect(
        service.scheduledCalls.map((c) => c.body).toSet().length,
        3,
      );
    },
  );

  test('setFrequency(off) tüm bildirimleri iptal eder, yeniden planlamaz', () async {
    final service = _RecordingFakeNotificationService();
    final provider = NotificationProvider(notificationService: service);
    await provider.initializeAndSchedule();
    service.cancelAllCallCount = 0; // initializeAndSchedule'daki çağrıyı say dışı bırak

    await provider.setFrequency(NotificationFrequency.off);

    expect(provider.frequency, NotificationFrequency.off);
    expect(service.cancelAllCallCount, 1);
    expect(service.scheduledCalls, isEmpty);
  });

  test(
    'setFrequency(once) yalnızca Öğlen dilimi için tek bildirim planlar',
    () async {
      final service = _RecordingFakeNotificationService();
      final provider = NotificationProvider(notificationService: service);
      await provider.initializeAndSchedule();

      await provider.setFrequency(NotificationFrequency.once);

      expect(service.scheduledCalls.length, 1);
      expect(service.scheduledCalls.single.id, NotificationProvider.onceSlotIndex);
    },
  );

  test('setFrequency kalıcı depoya yazılır ve yeniden başlatmada hatırlanır', () async {
    final firstLaunch = NotificationProvider(
      notificationService: _RecordingFakeNotificationService(),
    );
    await firstLaunch.setFrequency(NotificationFrequency.once);

    final secondLaunch = NotificationProvider(
      notificationService: _RecordingFakeNotificationService(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(secondLaunch.frequency, NotificationFrequency.once);
  });

  test('setTime bir dilimin saatini günceller, kalıcı depoya yazar ve yeniden planlar', () async {
    final service = _RecordingFakeNotificationService();
    final provider = NotificationProvider(notificationService: service);
    await provider.initializeAndSchedule();

    const newTime = TimeOfDay(hour: 8, minute: 30);
    await provider.setTime(0, newTime);

    expect(provider.times[0], newTime);
    expect(
      service.scheduledCalls.firstWhere((c) => c.id == 0).time,
      newTime,
    );

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('notificationState')!) as Map<String, dynamic>;
    expect((saved['times'] as List)[0], '08:30');
  });

  test(
    'initializeAndSchedule pil optimizasyonu durumunu da günceller',
    () async {
      final service = _RecordingFakeNotificationService()
        ..batteryOptimizationIgnored = true;
      final provider = NotificationProvider(notificationService: service);

      expect(provider.isBatteryOptimizationIgnored, isFalse);
      await provider.initializeAndSchedule();

      expect(provider.isBatteryOptimizationIgnored, isTrue);
    },
  );

  test(
    'requestIgnoreBatteryOptimizations servise sorar ve durumu yeniler',
    () async {
      final service = _RecordingFakeNotificationService();
      final provider = NotificationProvider(notificationService: service);
      await provider.initializeAndSchedule();
      expect(provider.isBatteryOptimizationIgnored, isFalse);

      await provider.requestIgnoreBatteryOptimizations();

      expect(provider.isBatteryOptimizationIgnored, isTrue);
    },
  );

  test('openAutostartOrAppSettings servisi çağırır', () async {
    final service = _RecordingFakeNotificationService();
    final provider = NotificationProvider(notificationService: service);

    await provider.openAutostartOrAppSettings();

    expect(service.openAutostartCallCount, 1);
  });

  test('openUnusedAppsSettings servisi çağırır', () async {
    final service = _RecordingFakeNotificationService();
    final provider = NotificationProvider(notificationService: service);

    await provider.openUnusedAppsSettings();

    expect(service.openUnusedAppsCallCount, 1);
  });
}
