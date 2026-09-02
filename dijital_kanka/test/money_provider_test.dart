// MoneyProvider'ın kategori bazlı ekleme/silme/toplam mantığını doğrudan
// (widget pump'lamadan) test eder — üç kategori (Harcamalar/Birikimler/
// Gelen Para), her kaydın bir tarih VE (2026 güncellemesi) kendi para
// birimini taşıması, eski (kategori birleştirmeden önceki, tarihsiz VE
// para-birimsiz) kayıtlı verinin doğru göç etmesi dahil.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/money_entry.dart';
import 'package:dijital_kanka/providers/money_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MoneyProvider', () {
    test('Yeni provider her kategoride boş başlar', () {
      final provider = MoneyProvider();

      for (final category in MoneyCategory.values) {
        expect(provider.entriesFor(category), isEmpty);
        expect(provider.totalFor(category), 0);
      }
    });

    test('addEntry ilgili kategoriye ekler, tarih atar ve toplamı günceller', () {
      final provider = MoneyProvider();

      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.expense, name: 'Kira', amount: 5000, currencyCode: 'TRY');

      expect(provider.entriesFor(MoneyCategory.expense), hasLength(2));
      expect(provider.totalFor(MoneyCategory.expense), 5250.5);
      expect(
        provider.entriesFor(MoneyCategory.expense).first.date.difference(DateTime.now()).inMinutes.abs() < 1,
        isTrue,
      );
      // Diğer kategoriler etkilenmemiş olmalı.
      expect(provider.entriesFor(MoneyCategory.saving), isEmpty);
      expect(provider.entriesFor(MoneyCategory.income), isEmpty);
    });

    test('Boş ad veya sıfır/negatif tutar reddedilir', () {
      final provider = MoneyProvider();

      provider.addEntry(MoneyCategory.saving, name: '  ', amount: 100, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.saving, name: 'Test', amount: 0, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.saving, name: 'Test', amount: -10, currencyCode: 'TRY');

      expect(provider.entriesFor(MoneyCategory.saving), isEmpty);
    });

    test('removeEntry yalnızca belirtilen kaydı kaldırır', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.income, name: 'Maaş', amount: 30000, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.income, name: 'Ek gelir', amount: 1000, currencyCode: 'TRY');

      final firstId = provider.entriesFor(MoneyCategory.income).first.id;
      provider.removeEntry(MoneyCategory.income, firstId);

      final remaining = provider.entriesFor(MoneyCategory.income);
      expect(remaining, hasLength(1));
      expect(remaining.first.name, 'Ek gelir');
      expect(provider.totalFor(MoneyCategory.income), 1000);
    });

    test('updateEntry ad/tutarı günceller, id/date korunur', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5, currencyCode: 'TRY');
      final original = provider.entriesFor(MoneyCategory.expense).first;

      provider.updateEntry(
        MoneyCategory.expense,
        id: original.id,
        name: 'Süpermarket',
        amount: 300,
        currencyCode: 'TRY',
      );

      final updated = provider.entriesFor(MoneyCategory.expense).first;
      expect(updated.id, original.id);
      expect(updated.name, 'Süpermarket');
      expect(updated.amount, 300);
      expect(updated.date, original.date);
      expect(provider.totalFor(MoneyCategory.expense), 300);
    });

    test('updateEntry boş ad veya sıfır/negatif tutarla hiçbir şey değiştirmez', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5, currencyCode: 'TRY');
      final original = provider.entriesFor(MoneyCategory.expense).first;

      provider.updateEntry(
        MoneyCategory.expense,
        id: original.id,
        name: '  ',
        amount: 300,
        currencyCode: 'TRY',
      );
      provider.updateEntry(
        MoneyCategory.expense,
        id: original.id,
        name: 'Yeni',
        amount: 0,
        currencyCode: 'TRY',
      );

      final unchanged = provider.entriesFor(MoneyCategory.expense).first;
      expect(unchanged.name, 'Market');
      expect(unchanged.amount, 250.5);
    });

    test('updateEntry var olmayan bir id için hiçbir şey yapmaz', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5, currencyCode: 'TRY');

      provider.updateEntry(
        MoneyCategory.expense,
        id: 'yok',
        name: 'Yeni',
        amount: 300,
        currencyCode: 'TRY',
      );

      expect(provider.entriesFor(MoneyCategory.expense), hasLength(1));
      expect(provider.entriesFor(MoneyCategory.expense).first.name, 'Market');
    });

    test(
      'Kayıt eklemek kalıcı depoya yazar; uygulama yeniden başlatılsa bile '
      '(yeni MoneyProvider) hatırlanır',
      () async {
        final firstLaunch = MoneyProvider();
        firstLaunch.addEntry(MoneyCategory.saving, name: 'Birikim', amount: 1000, currencyCode: 'USD');
        // addEntry'nin kalıcı depoya yazması asenkron (bkz. _save) — yeni
        // provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = MoneyProvider();
        await Future<void>.delayed(Duration.zero);

        final restored = secondLaunch.entriesFor(MoneyCategory.saving);
        expect(restored, hasLength(1));
        expect(restored.first.name, 'Birikim');
        expect(restored.first.currencyCode, 'USD');
        expect(secondLaunch.totalFor(MoneyCategory.saving), 1000);
      },
    );

    test(
      'Eski (kategori birleştirmeden önceki) "payment" listesi Harcamalara katılır',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'moneyEntries',
          '{"nextId": 2, "entries": {'
          '"expense": [{"id": "0", "name": "Market", "amount": 250.5}],'
          '"payment": [{"id": "1", "name": "Elektrik", "amount": 300}],'
          '"saving": []'
          '}}',
        );

        final migrated = MoneyProvider();
        await Future<void>.delayed(Duration.zero);

        final expenses = migrated.entriesFor(MoneyCategory.expense);
        expect(expenses, hasLength(2));
        expect(expenses.map((e) => e.name), containsAll(['Market', 'Elektrik']));
        // Eski (tarihsiz) kayıtlar göç anındaki "şimdi" ile dolduruldu.
        final now = DateTime.now();
        for (final entry in expenses) {
          expect(entry.date.difference(now).inMinutes.abs() < 1, isTrue);
        }
        // Eski (para birimsiz) kayıtlar 'TRY'ye düştü — bkz.
        // MoneyProvider._entryFromJson dokümantasyonu.
        for (final entry in expenses) {
          expect(entry.currencyCode, 'TRY');
        }
      },
    );
  });

  // **2026 yeni özellik — her kayıt kendi para birimini taşıyabilir.**
  group('MoneyProvider — çoklu para birimi', () {
    test('totalsByCurrencyFor kayıtları para birimine göre gruplar', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 500, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.expense, name: 'Kira', amount: 200, currencyCode: 'TRY');
      provider.addEntry(MoneyCategory.expense, name: 'Netflix', amount: 15, currencyCode: 'USD');
      provider.addEntry(MoneyCategory.expense, name: 'Spotify', amount: 10, currencyCode: 'EUR');

      final totals = provider.totalsByCurrencyFor(MoneyCategory.expense);

      expect(totals, {'TRY': 700, 'USD': 15, 'EUR': 10});
      // totalFor hâlâ ham/para-birimi-kör bir toplam döner (geriye dönük
      // uyumluluk için dokunulmadı) — burada bilerek yanlış/anlamsız bir
      // sayı olduğu kabul ediliyor, UI artık bunu KULLANMIYOR.
      expect(provider.totalFor(MoneyCategory.expense), 725);
    });

    test('boş kategori için totalsByCurrencyFor boş map döner', () {
      final provider = MoneyProvider();
      expect(provider.totalsByCurrencyFor(MoneyCategory.saving), isEmpty);
    });

    test('updateEntry bir kaydın para birimini de değiştirebilir', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.income, name: 'Freelance', amount: 100, currencyCode: 'TRY');
      final original = provider.entriesFor(MoneyCategory.income).first;

      provider.updateEntry(
        MoneyCategory.income,
        id: original.id,
        name: 'Freelance',
        amount: 100,
        currencyCode: 'USD',
      );

      expect(provider.entriesFor(MoneyCategory.income).first.currencyCode, 'USD');
      expect(provider.totalsByCurrencyFor(MoneyCategory.income), {'USD': 100});
    });

    test(
      'currencyCode alanı eklenmeden ÖNCEki kayıtlı veri göç anında TRY\'ye düşer',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'moneyEntries',
          '{"nextId": 1, "entries": {'
          '"expense": [{"id": "0", "name": "Market", "amount": 250.5, '
          '"date": "2026-01-01T00:00:00.000"}],'
          '"saving": [], "income": []'
          '}}',
        );

        final migrated = MoneyProvider();
        await Future<void>.delayed(Duration.zero);

        expect(migrated.entriesFor(MoneyCategory.expense).single.currencyCode, 'TRY');
      },
    );

    test(
      'hasEntryToday: bugün hiç kayıt yokken false, HANGİ kategoriden '
      'gelirse gelsin bir kayıt eklenince true döner (Denge Ustası — '
      'Gizli/Eğlenceli Rozetler)',
      () {
        final currentDate = DateTime(2026, 1, 5);
        final provider = MoneyProvider(now: () => currentDate);

        expect(provider.hasEntryToday, isFalse);

        provider.addEntry(
          MoneyCategory.income,
          name: 'Maaş',
          amount: 100,
          currencyCode: 'TRY',
        );

        expect(provider.hasEntryToday, isTrue);
      },
    );
  });
}
