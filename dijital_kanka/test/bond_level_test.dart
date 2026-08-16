// bondLevelForDays/nextBondLevelThreshold'ın gün eşiklerini doğru
// hesapladığını doğrudan (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/models/bond_level.dart';

void main() {
  group('bondLevelForDays', () {
    test('0-6 gün: newBuddy', () {
      expect(bondLevelForDays(0), BondLevel.newBuddy);
      expect(bondLevelForDays(6), BondLevel.newBuddy);
    });

    test('7-29 gün: gettingClose', () {
      expect(bondLevelForDays(7), BondLevel.gettingClose);
      expect(bondLevelForDays(29), BondLevel.gettingClose);
    });

    test('30-89 gün: oldFriend', () {
      expect(bondLevelForDays(30), BondLevel.oldFriend);
      expect(bondLevelForDays(89), BondLevel.oldFriend);
    });

    test('90-364 gün: soulBuddy', () {
      expect(bondLevelForDays(90), BondLevel.soulBuddy);
      expect(bondLevelForDays(364), BondLevel.soulBuddy);
    });

    test('365+ gün: lifetimeBuddy', () {
      expect(bondLevelForDays(365), BondLevel.lifetimeBuddy);
      expect(bondLevelForDays(1000), BondLevel.lifetimeBuddy);
    });
  });

  group('nextBondLevelThreshold', () {
    test('Her ara kademe bir sonraki eşiği döner', () {
      expect(nextBondLevelThreshold(BondLevel.newBuddy), 7);
      expect(nextBondLevelThreshold(BondLevel.gettingClose), 30);
      expect(nextBondLevelThreshold(BondLevel.oldFriend), 90);
      expect(nextBondLevelThreshold(BondLevel.soulBuddy), 365);
    });

    test('En üst kademenin (lifetimeBuddy) bir sonraki eşiği yoktur', () {
      expect(nextBondLevelThreshold(BondLevel.lifetimeBuddy), isNull);
    });
  });
}
