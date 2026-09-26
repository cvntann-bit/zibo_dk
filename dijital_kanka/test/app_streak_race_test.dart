// Seri sayacı yükleme yarışı: `AppStreakProvider` oluşturulur oluşturulmaz
// (kayıtlı veri henüz yüklenmeden) `recordOpenForToday()` çağrılırsa seri
// 1'e sıfırlanıp kalıcı depoya yazılıyordu — gerçek uygulamada RootScreen'in
// ilk karesinde tam olarak bu oluyordu ("En Uzun Seri Rekoru 1'de takılı",
// "Streak Freeze hiç çıkmıyor").

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/app_streak_provider.dart';

void main() {
  final today = DateTime(2026, 9, 26, 10);

  Map<String, Object> stored({required DateTime lastOpen, int streak = 5, int longest = 5}) => {
    'appStreakState': jsonEncode({
      'lastOpenDate': lastOpen.toIso8601String(),
      'currentStreak': streak,
      'longestStreakEver': longest,
      'totalDaysOpened': 20,
    }),
  };

  test('yükleme bitmeden gelen "bugün açıldı" kaydı seriyi sıfırlamaz, dünkü seri +1 olur', () async {
    SharedPreferences.setMockInitialValues(stored(lastOpen: DateTime(2026, 9, 25)));
    final provider = AppStreakProvider(now: () => today);

    // Uygulamadaki gibi: oluşturulur oluşturulmaz, yükleme beklenmeden.
    provider.recordOpenForToday();
    await provider.ready;

    expect(provider.currentStreak, 6);
    expect(provider.longestStreakEver, 6);
    expect(provider.totalDaysOpened, 21);

    // Kalıcı depoya da doğru değer yazılmış olmalı.
    final reloaded = AppStreakProvider(now: () => today);
    await reloaded.ready;
    expect(reloaded.currentStreak, 6);
  });

  test('yükleme bitince dünü kaçırmış kullanıcı "risk altında" görünür (freeze teklifi çıkabilir)', () async {
    SharedPreferences.setMockInitialValues(stored(lastOpen: DateTime(2026, 9, 24)));
    final provider = AppStreakProvider(now: () => today);

    await provider.ready;

    expect(provider.isStreakAtRisk, isTrue);
    expect(provider.currentStreak, 5);
  });
}
