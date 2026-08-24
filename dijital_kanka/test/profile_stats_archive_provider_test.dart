// ProfileStatsArchiveProvider'ın ay değişimini doğru algıladığını, önceki
// ayın CANLI puanlarını arşivlediğini, aynı ay içindeki tekrar çağrıların
// no-op olduğunu ve kalıcılığı doğrudan (widget pump'lamadan) test eder.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/profile_stats_archive_provider.dart';
import 'package:dijital_kanka/utils/profile_stats.dart';

const _jan = [
  CategoryStat(category: ProfileStatCategory.money, hasData: true, score: 7.5),
  CategoryStat(category: ProfileStatCategory.gratitudeManifest, hasData: true, score: 4),
  CategoryStat(category: ProfileStatCategory.consistency, hasData: false),
  CategoryStat(category: ProfileStatCategory.selfCareHealth, hasData: true, score: 9),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('İlk çağrı hiçbir şey arşivlemez, yalnızca temel ayı işaretler', () async {
    final provider = ProfileStatsArchiveProvider();
    await Future<void>.delayed(Duration.zero);

    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 15));

    expect(provider.snapshots, isEmpty);
  });

  test('Aynı ay içindeki tekrar çağrılar arşivlemez', () async {
    final provider = ProfileStatsArchiveProvider();
    await Future<void>.delayed(Duration.zero);

    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 5));
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 20));

    expect(provider.snapshots, isEmpty);
  });

  test('Ay değişince ÖNCEKİ ay, o anki puanlarla arşivlenir', () async {
    final provider = ProfileStatsArchiveProvider();
    await Future<void>.delayed(Duration.zero);

    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 15));
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 2, 3));

    expect(provider.snapshots, hasLength(1));
    final snapshot = provider.snapshots.first;
    expect(snapshot.year, 2026);
    expect(snapshot.month, 1);
    expect(snapshot.scoreFor(ProfileStatCategory.money), 7.5);
    expect(snapshot.scoreFor(ProfileStatCategory.gratitudeManifest), 4);
    expect(snapshot.scoreFor(ProfileStatCategory.selfCareHealth), 9);
    // hasData == false olan kategori arşive HİÇ girmez.
    expect(snapshot.scoreFor(ProfileStatCategory.consistency), isNull);
  });

  test('Birden fazla ay birikince en yeni ay listenin BAŞINDA olur', () async {
    final provider = ProfileStatsArchiveProvider();
    await Future<void>.delayed(Duration.zero);

    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 15));
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 2, 3));
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 3, 2));

    expect(provider.snapshots, hasLength(2));
    expect(provider.snapshots[0].month, 2);
    expect(provider.snapshots[1].month, 1);
  });

  test(
    'Kalıcı depoya yazar; uygulama yeniden başlatılsa bile (yeni provider) hatırlanır',
    () async {
      final firstLaunch = ProfileStatsArchiveProvider();
      await Future<void>.delayed(Duration.zero);
      firstLaunch.archiveIfMonthChanged(_jan, DateTime(2026, 1, 15));
      firstLaunch.archiveIfMonthChanged(_jan, DateTime(2026, 2, 3));
      await Future<void>.delayed(Duration.zero);

      final secondLaunch = ProfileStatsArchiveProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.snapshots, hasLength(1));
      expect(secondLaunch.snapshots.first.month, 1);
      expect(secondLaunch.snapshots.first.scoreFor(ProfileStatCategory.money), 7.5);

      // İkinci başlatmada aynı ay (Şubat) içinde tekrar çağrı arşivlemiyor.
      secondLaunch.archiveIfMonthChanged(_jan, DateTime(2026, 2, 20));
      expect(secondLaunch.snapshots, hasLength(1));
    },
  );

  test('Kalıcı depodaki JSON beklenen şekle sahip', () async {
    final provider = ProfileStatsArchiveProvider();
    await Future<void>.delayed(Duration.zero);
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 1, 15));
    provider.archiveIfMonthChanged(_jan, DateTime(2026, 2, 3));
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('profileStatsArchive')!) as Map<String, dynamic>;
    expect(saved['lastSeenMonthKey'], '2026-2');
    final snapshots = saved['snapshots'] as List;
    expect(snapshots, hasLength(1));
    expect(snapshots.first['year'], 2026);
    expect(snapshots.first['month'], 1);
  });
}
