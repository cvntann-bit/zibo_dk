// xp_level.dart'taki saf fonksiyonların (cumulativeXpForLevel/
// xpNeededForNextLevel/levelForTotalXp/levelProgressForTotalXp) doğrudan
// testi — hiçbir provider/widget'a bağımlı değil.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/models/xp_level.dart';

void main() {
  test('Level 1, 0 XP gerektirir', () {
    expect(cumulativeXpForLevel(1), 0);
  });

  test('xpNeededForNextLevel doğrusal artıyor (50*level)', () {
    expect(xpNeededForNextLevel(1), 50);
    expect(xpNeededForNextLevel(2), 100);
    expect(xpNeededForNextLevel(5), 250);
  });

  test('cumulativeXpForLevel — 1->2->3->4 eşikleri tutarlı (25*L*(L-1))', () {
    expect(cumulativeXpForLevel(2), 50); // 25*2*1
    expect(cumulativeXpForLevel(3), 150); // 25*3*2
    expect(cumulativeXpForLevel(4), 300); // 25*4*3
  });

  test('levelForTotalXp — 0 XP ile Level 1', () {
    expect(levelForTotalXp(0), 1);
  });

  test('levelForTotalXp — tam eşikte bir üst seviyeye geçer', () {
    expect(levelForTotalXp(49), 1);
    expect(levelForTotalXp(50), 2);
    expect(levelForTotalXp(149), 2);
    expect(levelForTotalXp(150), 3);
  });

  test('levelProgressForTotalXp — seviye içi ilerleme doğru hesaplanır', () {
    final progress = levelProgressForTotalXp(70); // Level 2, 50 XP'de başladı
    expect(progress.level, 2);
    expect(progress.xpIntoLevel, 20); // 70 - 50
    expect(progress.xpForNextLevel, 100); // xpNeededForNextLevel(2)
    expect(progress.fraction, closeTo(0.2, 0.0001));
  });

  test('levelProgressForTotalXp — 0 XP ile fraction 0', () {
    final progress = levelProgressForTotalXp(0);
    expect(progress.level, 1);
    expect(progress.xpIntoLevel, 0);
    expect(progress.fraction, 0);
  });

  test('İlerleme eğrisi düşük seviyelerde hızlı, yüksek seviyelerde yavaş', () {
    // Level 1'den 2'ye 50 XP, Level 9'dan 10'a 450 XP — açıkça artan maliyet.
    expect(xpNeededForNextLevel(1), lessThan(xpNeededForNextLevel(9)));
  });
}
