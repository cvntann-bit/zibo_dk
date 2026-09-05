// XpProvider'ın toplam XP birikimi + seviye atlama sinyalini (pendingLevelUp)
// doğrudan (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/xp_provider.dart';
import 'package:dijital_kanka/utils/level_up_signal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingLevelUp.value = null;
  });

  test('Yeni provider 0 XP ve Level 1 ile başlar', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.totalXp, 0);
    expect(provider.level, 1);
  });

  test('addXp toplam XP\'yi artırır', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addXp(30);
    expect(provider.totalXp, 30);
    expect(provider.level, 1); // Level 2 eşiği 50
  });

  test('Seviye eşiği aşılınca level artar ve pendingLevelUp ayarlanır', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addXp(50); // tam Level 2 eşiği
    expect(provider.level, 2);
    expect(pendingLevelUp.value, 2);
  });

  test('Seviye eşiği aşılmadıkça pendingLevelUp DEĞİŞMEZ', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addXp(10);
    expect(pendingLevelUp.value, isNull);
  });

  test('addXp(0) veya negatif değer no-op\'tur', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addXp(0);
    provider.addXp(-5);
    expect(provider.totalXp, 0);
  });

  test('Birden fazla seviye eşiği aynı anda aşılabilir, level doğru hesaplanır', () async {
    final provider = XpProvider();
    await Future<void>.delayed(Duration.zero);

    // Tek seferde 300 XP: Level 1 -> Level 4 (cumulativeXpForLevel(4) == 300).
    provider.addXp(300);
    expect(provider.level, 4);
    expect(pendingLevelUp.value, 4);
  });

  test('Toplam XP kalıcı depoya yazılır; yeniden başlatmada hatırlanır', () async {
    final firstLaunch = XpProvider();
    await Future<void>.delayed(Duration.zero);
    firstLaunch.addXp(75);
    await Future<void>.delayed(Duration.zero);

    final secondLaunch = XpProvider();
    await Future<void>.delayed(Duration.zero);

    expect(secondLaunch.totalXp, 75);
    expect(secondLaunch.level, 2);
  });
}
