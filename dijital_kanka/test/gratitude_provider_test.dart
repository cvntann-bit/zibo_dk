// GratitudeProvider'ın günlük kilitleme mantığını doğrudan (widget
// pump'lamadan) test eder: bugün için yalnızca bir kayıt kaydedilebilmeli,
// üç metinden biri eksikken kaydedilmemeli, gün değişince yeni bir giriş
// açılmalı ve kayıtlar kalıcı olmalı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/gratitude_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GratitudeProvider', () {
    late DateTime currentDate;
    late GratitudeProvider provider;

    setUp(() {
      currentDate = DateTime(2026, 1, 5);
      provider = GratitudeProvider(now: () => currentDate);
    });

    test('Yeni provider bugün tamamlanmamış başlar', () {
      expect(provider.isTodayComplete, isFalse);
      expect(provider.todayEntry, isNull);
      expect(provider.entries, isEmpty);
    });

    test('Üç metin de doluyken saveToday true döner ve bugünü kilitler', () {
      final saved = provider.saveToday(
        text1: 'Sağlığım',
        text2: 'Ailem',
        text3: 'Güzel bir kahve',
      );

      expect(saved, isTrue);
      expect(provider.isTodayComplete, isTrue);
      expect(provider.todayEntry!.text1, 'Sağlığım');
      expect(provider.todayEntry!.text2, 'Ailem');
      expect(provider.todayEntry!.text3, 'Güzel bir kahve');
      expect(provider.todayEntry!.isComplete, isTrue);
      expect(provider.entries, hasLength(1));
    });

    test('Metinlerden biri boşsa saveToday false döner, kayıt oluşmaz', () {
      final saved = provider.saveToday(text1: 'Sağlığım', text2: '  ', text3: 'Kahve');

      expect(saved, isFalse);
      expect(provider.isTodayComplete, isFalse);
      expect(provider.entries, isEmpty);
    });

    test('Bugün zaten tamamlandıysa ikinci saveToday çağrısı false döner', () {
      provider.saveToday(text1: 'A', text2: 'B', text3: 'C');

      final secondAttempt = provider.saveToday(text1: 'X', text2: 'Y', text3: 'Z');

      expect(secondAttempt, isFalse);
      expect(provider.entries, hasLength(1));
      // İlk kayıt değişmemiş olmalı.
      expect(provider.todayEntry!.text1, 'A');
    });

    test('Gün değişince yeni bir giriş açılır, dünkü kayıt geçmişte kalır', () {
      provider.saveToday(text1: 'A', text2: 'B', text3: 'C');
      expect(provider.isTodayComplete, isTrue);

      currentDate = DateTime(2026, 1, 6); // ertesi gün

      expect(provider.isTodayComplete, isFalse);
      expect(provider.todayEntry, isNull);
      // Ama dünkü kayıt geçmiş listesinde hâlâ duruyor.
      expect(provider.entries, hasLength(1));

      final savedNextDay = provider.saveToday(text1: 'D', text2: 'E', text3: 'F');
      expect(savedNextDay, isTrue);
      expect(provider.entries, hasLength(2));
    });

    test('entries en yeni kayıt en üstte olacak şekilde sıralanır', () {
      provider.saveToday(text1: 'A', text2: 'B', text3: 'C');
      currentDate = DateTime(2026, 1, 6);
      provider.saveToday(text1: 'D', text2: 'E', text3: 'F');
      currentDate = DateTime(2026, 1, 7);
      provider.saveToday(text1: 'G', text2: 'H', text3: 'I');

      expect(
        provider.entries.map((e) => e.text1).toList(),
        ['G', 'D', 'A'],
      );
    });

    test(
      'Kayıt kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni GratitudeProvider) hatırlanır',
      () async {
        final firstLaunch = GratitudeProvider(now: () => currentDate);
        firstLaunch.saveToday(text1: 'Kalıcı 1', text2: 'Kalıcı 2', text3: 'Kalıcı 3');
        // saveToday'in kalıcı depoya yazması asenkron (bkz. _save) — yeni
        // provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = GratitudeProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.isTodayComplete, isTrue);
        expect(secondLaunch.todayEntry!.text1, 'Kalıcı 1');
      },
    );

    test('updateEntry bugünün kaydını düzenler, isTodayComplete kilidi bunu engellemez', () {
      provider.saveToday(text1: 'A', text2: 'B', text3: 'C');

      final updated = provider.updateEntry(
        DateTime(2026, 1, 5),
        text1: 'A2',
        text2: 'B2',
        text3: 'C2',
      );

      expect(updated, isTrue);
      expect(provider.todayEntry!.text1, 'A2');
      expect(provider.todayEntry!.text2, 'B2');
      expect(provider.todayEntry!.text3, 'C2');
      expect(provider.entries, hasLength(1)); // yeni kayıt EKLENMEDİ, üzerine yazıldı
    });

    test('updateEntry geçmişteki (bugün olmayan) bir kaydı da düzenleyebilir', () {
      provider.saveToday(text1: 'Dün 1', text2: 'Dün 2', text3: 'Dün 3');
      currentDate = DateTime(2026, 1, 6);
      provider.saveToday(text1: 'Bugün 1', text2: 'Bugün 2', text3: 'Bugün 3');

      final updated = provider.updateEntry(
        DateTime(2026, 1, 5),
        text1: 'Düzenlenmiş',
        text2: 'Dün 2',
        text3: 'Dün 3',
      );

      expect(updated, isTrue);
      final yesterday = provider.entries.firstWhere((e) => e.date == DateTime(2026, 1, 5));
      expect(yesterday.text1, 'Düzenlenmiş');
      // Bugünün kaydı etkilenmedi.
      expect(provider.todayEntry!.text1, 'Bugün 1');
    });

    test('updateEntry var olmayan bir tarih için ya da boş metinle false döner', () {
      provider.saveToday(text1: 'A', text2: 'B', text3: 'C');

      expect(
        provider.updateEntry(DateTime(2020, 1, 1), text1: 'X', text2: 'Y', text3: 'Z'),
        isFalse,
      );
      expect(
        provider.updateEntry(DateTime(2026, 1, 5), text1: '  ', text2: 'Y', text3: 'Z'),
        isFalse,
      );
      // Orijinal kayıt değişmedi.
      expect(provider.todayEntry!.text1, 'A');
    });
  });
}
