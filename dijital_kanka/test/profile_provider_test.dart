// ProfileProvider'ın isim/fotoğraf yolunu doğru tuttuğunu ve
// SharedPreferences üzerinden kalıcı olarak sakladığını (uygulama yeniden
// başlatılsa bile hatırlandığını) doğrudan (widget pump'lamadan) test eder.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/profile_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider boş isim ve fotoğrafsız başlar', () async {
    final provider = ProfileProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.name, isEmpty);
    expect(provider.photoPath, isNull);
  });

  test('setName ismi günceller (baştaki/sondaki boşluklar kırpılır)', () async {
    final provider = ProfileProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.setName('  Ayşe  ');

    expect(provider.name, 'Ayşe');
  });

  test('setPhotoPath fotoğraf yolunu günceller', () async {
    final provider = ProfileProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.setPhotoPath('/tmp/photo.jpg');

    expect(provider.photoPath, '/tmp/photo.jpg');
  });

  test(
    'İsim ve fotoğraf kalıcı depoya yazılır; uygulama yeniden başlatılsa bile (yeni ProfileProvider) hatırlanır',
    () async {
      final firstLaunch = ProfileProvider();
      await firstLaunch.setName('Mehmet');
      await firstLaunch.setPhotoPath('/tmp/mehmet.jpg');

      final secondLaunch = ProfileProvider();
      await Future<void>.delayed(Duration.zero);

      expect(secondLaunch.name, 'Mehmet');
      expect(secondLaunch.photoPath, '/tmp/mehmet.jpg');
    },
  );

  test('İLK açılışta firstUsedAt bugüne sabitlenir ve bir daha değişmez', () async {
    var now = DateTime(2026, 1, 1);
    final firstLaunch = ProfileProvider(now: () => now);
    await Future<void>.delayed(Duration.zero);

    expect(firstLaunch.firstUsedAt, DateTime(2026, 1, 1));

    // Gerçek zaman ilerlese bile (uygulama sonraki günlerde tekrar açılsa),
    // ikinci açılışta firstUsedAt İLK kaydedilen tarihte kalmalı.
    now = DateTime(2026, 1, 10);
    final secondLaunch = ProfileProvider(now: () => now);
    await Future<void>.delayed(Duration.zero);

    expect(secondLaunch.firstUsedAt, DateTime(2026, 1, 1));
  });

  test('daysSinceFirstUsed bugünle firstUsedAt arasındaki tam gün farkını döner', () async {
    var now = DateTime(2026, 1, 1);
    final provider = ProfileProvider(now: () => now);
    await Future<void>.delayed(Duration.zero);

    expect(provider.daysSinceFirstUsed(), 0);

    now = DateTime(2026, 1, 15);
    expect(provider.daysSinceFirstUsed(), 14);
  });

  test('addressTerm varsayılan olarak Kanka; setAddressTerm günceller ve kalıcı olur', () async {
    final provider = ProfileProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.addressTerm, 'Kanka');

    await provider.setAddressTerm('Reis');
    expect(provider.addressTerm, 'Reis');

    final reloaded = ProfileProvider();
    await Future<void>.delayed(Duration.zero);
    expect(reloaded.addressTerm, 'Reis');
  });

  test('setAddressTerm boş (veya yalnızca boşluk) bir değer verilirse varsayılana döner', () async {
    final provider = ProfileProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.setAddressTerm('Reis');
    expect(provider.addressTerm, 'Reis');

    await provider.setAddressTerm('   ');
    expect(provider.addressTerm, 'Kanka');
  });

  group('reconcileMissingPhoto (2026 — Crashlytics bug düzeltmesi)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('profile_reconcile_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'diskte GERÇEKTEN var olmayan bir photoPath kalıcı olarak null\'a çevrilir',
      () async {
        final provider = ProfileProvider();
        await Future<void>.delayed(Duration.zero);
        await provider.setPhotoPath('${tempDir.path}/hic-var-olmadi.jpg');

        provider.reconcileMissingPhoto();

        expect(provider.photoPath, isNull);
      },
    );

    test('diskte GERÇEKTEN var olan bir photoPath\'e DOKUNULMAZ', () async {
      final realFile = File('${tempDir.path}/gercek.jpg')..writeAsBytesSync([1, 2, 3]);
      final provider = ProfileProvider();
      await Future<void>.delayed(Duration.zero);
      await provider.setPhotoPath(realFile.path);

      provider.reconcileMissingPhoto();

      expect(provider.photoPath, realFile.path);
    });

    test('photoPath zaten null iken no-op (dosya sistemine hiç dokunmaz)', () async {
      final provider = ProfileProvider();
      await Future<void>.delayed(Duration.zero);
      expect(provider.photoPath, isNull);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reconcileMissingPhoto();

      expect(provider.photoPath, isNull);
      expect(notifyCount, 0);
    });

    test('kalıcı depoya yazılır — yeniden başlatmada null olarak hatırlanır', () async {
      final firstLaunch = ProfileProvider();
      await Future<void>.delayed(Duration.zero);
      await firstLaunch.setPhotoPath('${tempDir.path}/hic-var-olmadi.jpg');

      firstLaunch.reconcileMissingPhoto();
      await Future<void>.delayed(Duration.zero);

      final secondLaunch = ProfileProvider();
      await Future<void>.delayed(Duration.zero);
      expect(secondLaunch.photoPath, isNull);
    });
  });
}
