// MoneyProvider'ın kategori bazlı ekleme/silme/toplam mantığını doğrudan
// (widget pump'lamadan) test eder — üç kategori (Harcamalar/Birikimler/
// Gelen Para), her kaydın bir tarih taşıması ve eski (kategori
// birleştirmeden önceki, tarihsiz) kayıtlı verinin doğru göç etmesi dahil.

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

      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5);
      provider.addEntry(MoneyCategory.expense, name: 'Kira', amount: 5000);

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

      provider.addEntry(MoneyCategory.saving, name: '  ', amount: 100);
      provider.addEntry(MoneyCategory.saving, name: 'Test', amount: 0);
      provider.addEntry(MoneyCategory.saving, name: 'Test', amount: -10);

      expect(provider.entriesFor(MoneyCategory.saving), isEmpty);
    });

    test('removeEntry yalnızca belirtilen kaydı kaldırır', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.income, name: 'Maaş', amount: 30000);
      provider.addEntry(MoneyCategory.income, name: 'Ek gelir', amount: 1000);

      final firstId = provider.entriesFor(MoneyCategory.income).first.id;
      provider.removeEntry(MoneyCategory.income, firstId);

      final remaining = provider.entriesFor(MoneyCategory.income);
      expect(remaining, hasLength(1));
      expect(remaining.first.name, 'Ek gelir');
      expect(provider.totalFor(MoneyCategory.income), 1000);
    });

    test('updateEntry ad/tutarı günceller, id/date korunur', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5);
      final original = provider.entriesFor(MoneyCategory.expense).first;

      provider.updateEntry(
        MoneyCategory.expense,
        id: original.id,
        name: 'Süpermarket',
        amount: 300,
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
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5);
      final original = provider.entriesFor(MoneyCategory.expense).first;

      provider.updateEntry(MoneyCategory.expense, id: original.id, name: '  ', amount: 300);
      provider.updateEntry(MoneyCategory.expense, id: original.id, name: 'Yeni', amount: 0);

      final unchanged = provider.entriesFor(MoneyCategory.expense).first;
      expect(unchanged.name, 'Market');
      expect(unchanged.amount, 250.5);
    });

    test('updateEntry var olmayan bir id için hiçbir şey yapmaz', () {
      final provider = MoneyProvider();
      provider.addEntry(MoneyCategory.expense, name: 'Market', amount: 250.5);

      provider.updateEntry(MoneyCategory.expense, id: 'yok', name: 'Yeni', amount: 300);

      expect(provider.entriesFor(MoneyCategory.expense), hasLength(1));
      expect(provider.entriesFor(MoneyCategory.expense).first.name, 'Market');
    });

    test(
      'Kayıt eklemek kalıcı depoya yazar; uygulama yeniden başlatılsa bile '
      '(yeni MoneyProvider) hatırlanır',
      () async {
        final firstLaunch = MoneyProvider();
        firstLaunch.addEntry(MoneyCategory.saving, name: 'Birikim', amount: 1000);
        // addEntry'nin kalıcı depoya yazması asenkron (bkz. _save) — yeni
        // provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = MoneyProvider();
        await Future<void>.delayed(Duration.zero);

        final restored = secondLaunch.entriesFor(MoneyCategory.saving);
        expect(restored, hasLength(1));
        expect(restored.first.name, 'Birikim');
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
      },
    );
  });
}
