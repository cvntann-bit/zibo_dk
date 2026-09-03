// ManifestProvider'ın çoklu-günlük-giriş + coin ödülü mantığını doğrudan
// (widget pump'lamadan) test eder: aynı gün içinde istenildiği kadar giriş
// eklenebilmeli (üzerine yazma YOK), coin ödülü yalnızca o günün İLK
// tamamlanan girişinde verilmeli (Su Takibi'ndeki rewardClaimed koruma
// deseniyle aynı, ama artık GÜN düzeyinde), gün değişince yeniden
// kazanılabilmeli ve kayıtlar kalıcı olmalı.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/manifest_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ManifestProvider', () {
    late DateTime currentDate;
    late ManifestProvider provider;

    setUp(() {
      currentDate = DateTime(2026, 1, 5);
      provider = ManifestProvider(now: () => currentDate);
    });

    test('Yeni provider bugün için hiç kayıt olmadan başlar', () {
      expect(provider.history, isEmpty);
      expect(provider.isTodayRewardClaimed, isFalse);
    });

    test(
      'Bugünün İLK girişi true döner (coin ödülüne hak kazanır) ve geçmişte görünür',
      () {
        final justCompleted = provider.addEntry(
          photoPath: '/tmp/photo1.jpg',
          intentionText: 'Bol bereket ve huzur',
        );
        expect(justCompleted, isTrue);
        expect(provider.isTodayRewardClaimed, isTrue);
        expect(provider.history, hasLength(1));
        expect(provider.history.first.photoPath, '/tmp/photo1.jpg');
        expect(provider.history.first.intentionText, 'Bol bereket ve huzur');
        expect(provider.history.first.date, DateTime(2026, 1, 5));
      },
    );

    test(
      'Boş fotoğraf yolu veya boş (trim sonrası) niyet metniyle kaydedilemez',
      () {
        expect(
          provider.addEntry(photoPath: '', intentionText: 'Bir niyet'),
          isFalse,
        );
        expect(
          provider.addEntry(photoPath: '/tmp/photo.jpg', intentionText: '   '),
          isFalse,
        );
        expect(provider.history, isEmpty);
      },
    );

    test(
      'Aynı gün içinde ikinci bir giriş eklemek İLKİNİN ÜZERİNE YAZMAZ, ayrı '
      'bir kayıt olarak eklenir ve coin ödülü İKİNCİ KEZ verilmez',
      () {
        final first = provider.addEntry(
          photoPath: '/tmp/photo1.jpg',
          intentionText: 'İlk niyetim',
        );
        expect(first, isTrue);

        final second = provider.addEntry(
          photoPath: '/tmp/photo2.jpg',
          intentionText: 'İkinci niyetim',
        );
        expect(second, isFalse); // coin TEKRAR verilmez

        // İki kayıt da ayrı ayrı duruyor — birincisi silinmedi/değişmedi.
        expect(provider.history, hasLength(2));
        expect(provider.history.map((e) => e.intentionText), [
          'İkinci niyetim', // en yeni en üstte
          'İlk niyetim',
        ]);
        expect(provider.isTodayRewardClaimed, isTrue);
      },
    );

    test('Gün değişince ödül durumu sıfırlanır, yeni gün yeniden kazanabilir', () {
      expect(
        provider.addEntry(photoPath: '/tmp/a.jpg', intentionText: 'Dün'),
        isTrue,
      );

      currentDate = DateTime(2026, 1, 6); // ertesi gün
      expect(provider.isTodayRewardClaimed, isFalse);

      final newDayCompletion = provider.addEntry(
        photoPath: '/tmp/b.jpg',
        intentionText: 'Bugün',
      );
      expect(newDayCompletion, isTrue); // yeni günde tekrar kazanılabilir
      expect(provider.history, hasLength(2)); // dünkü kayıt da hâlâ duruyor
    });

    test(
      'Kayıt kalıcı depoya yazılır; uygulama yeniden başlatılsa bile (yeni '
      'ManifestProvider) hatırlanır',
      () async {
        final firstLaunch = ManifestProvider(now: () => currentDate);
        firstLaunch.addEntry(photoPath: '/tmp/photo1.jpg', intentionText: 'Birinci');
        firstLaunch.addEntry(photoPath: '/tmp/photo2.jpg', intentionText: 'İkinci');
        // Kalıcı depoya yazma asenkron (bkz. _save) — yeni provider'ı
        // oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = ManifestProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.history, hasLength(2));
        expect(secondLaunch.isTodayRewardClaimed, isTrue);
      },
    );

    test(
      'Eski (id\'siz, günde tek kayıtlı) kayıtlı veri doğru okunur',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'manifestEntries',
          '[{"date": "2026-01-04T00:00:00.000", "photoPath": "/tmp/old.jpg", '
          '"intentionText": "Eski niyet", "rewardClaimed": true}]',
        );

        final migrated = ManifestProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(migrated.history, hasLength(1));
        expect(migrated.history.first.intentionText, 'Eski niyet');
        expect(migrated.isTodayRewardClaimed, isFalse); // eski kayıt DÜNE ait
      },
    );

    test(
      'hasEntryToday: bugün hiç giriş yokken false, eklenince true döner '
      '(Denge Ustası — Gizli/Eğlenceli Rozetler)',
      () {
        expect(provider.hasEntryToday, isFalse);

        provider.addEntry(photoPath: '/tmp/photo.jpg', intentionText: 'Niyet');

        expect(provider.hasEntryToday, isTrue);
      },
    );

    group('reconcileMissingPhotos (2026 — Crashlytics bug düzeltmesi)', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('manifest_reconcile_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test(
        'diskte GERÇEKTEN var olmayan bir photoPath kalıcı olarak null\'a '
        'çevrilir, kayıt (niyet metni) SİLİNMEZ',
        () async {
          provider.addEntry(
            photoPath: '${tempDir.path}/hic-var-olmadi.jpg',
            intentionText: 'Bu niyet kalmalı',
          );
          expect(provider.history.single.photoPath, isNotNull);

          provider.reconcileMissingPhotos();

          expect(provider.history.single.photoPath, isNull);
          expect(provider.history.single.intentionText, 'Bu niyet kalmalı');
        },
      );

      test('diskte GERÇEKTEN var olan bir photoPath\'e DOKUNULMAZ', () {
        final realFile = File('${tempDir.path}/gercek.jpg')..writeAsBytesSync([1, 2, 3]);
        provider.addEntry(photoPath: realFile.path, intentionText: 'Gerçek fotoğraf');

        provider.reconcileMissingPhotos();

        expect(provider.history.single.photoPath, realFile.path);
      });

      test('kalıcı depoya yazılır — yeniden başlatmada null olarak hatırlanır', () async {
        provider.addEntry(
          photoPath: '${tempDir.path}/hic-var-olmadi.jpg',
          intentionText: 'Niyet',
        );
        provider.reconcileMissingPhotos();
        await Future<void>.delayed(Duration.zero);

        final restarted = ManifestProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(restarted.history.single.photoPath, isNull);
      });

      test('değişiklik yoksa notifyListeners GEREKSİZ yere ÇAĞRILMAZ', () {
        final realFile = File('${tempDir.path}/gercek.jpg')..writeAsBytesSync([1]);
        provider.addEntry(photoPath: realFile.path, intentionText: 'Niyet');

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.reconcileMissingPhotos();

        expect(notifyCount, 0);
      });
    });
  });
}
