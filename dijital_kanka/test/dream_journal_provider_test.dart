// DreamJournalProvider'ın ekleme/güncelleme/silme/sıralama mantığını
// doğrudan (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/dream_journal_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DreamJournalProvider', () {
    test('Yeni provider boş başlar', () {
      final provider = DreamJournalProvider();

      expect(provider.dreams, isEmpty);
    });

    test('addDream yeni bir kayıt ekler ve tarihi otomatik atar', () {
      final provider = DreamJournalProvider();
      final before = DateTime.now();

      provider.addDream(title: 'Uçmak', text: 'Gökyüzünde uçtuğumu gördüm.');

      expect(provider.dreams, hasLength(1));
      final dream = provider.dreams.single;
      expect(dream.title, 'Uçmak');
      expect(dream.text, 'Gökyüzünde uçtuğumu gördüm.');
      expect(
        dream.date.difference(before).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('Boş başlık veya boş metin reddedilir', () {
      final provider = DreamJournalProvider();

      provider.addDream(title: '  ', text: 'Metin var');
      provider.addDream(title: 'Başlık var', text: '   ');

      expect(provider.dreams, isEmpty);
    });

    test('dreams en yeni kayıt en üstte olacak şekilde sıralanır', () {
      final provider = DreamJournalProvider();

      provider.addDream(title: 'Birinci', text: 'İlk rüya');
      provider.addDream(title: 'İkinci', text: 'İkinci rüya');
      provider.addDream(title: 'Üçüncü', text: 'Üçüncü rüya');

      expect(
        provider.dreams.map((d) => d.title).toList(),
        ['Üçüncü', 'İkinci', 'Birinci'],
      );
    });

    test('updateDream başlığı/metni değiştirir, tarihi korur', () {
      final provider = DreamJournalProvider();
      provider.addDream(title: 'Eski Başlık', text: 'Eski metin');
      final original = provider.dreams.single;

      provider.updateDream(
        original.id,
        title: 'Yeni Başlık',
        text: 'Yeni metin',
      );

      final updated = provider.dreams.single;
      expect(updated.title, 'Yeni Başlık');
      expect(updated.text, 'Yeni metin');
      expect(updated.date, original.date);
    });

    test('removeDream yalnızca belirtilen kaydı kaldırır', () {
      final provider = DreamJournalProvider();
      provider.addDream(title: 'Kalan', text: 'Bu kalacak');
      provider.addDream(title: 'Silinen', text: 'Bu silinecek');
      final toRemove = provider.dreams.firstWhere((d) => d.title == 'Silinen');

      provider.removeDream(toRemove.id);

      expect(provider.dreams, hasLength(1));
      expect(provider.dreams.single.title, 'Kalan');
    });

    test(
      'Kayıt eklemek kalıcı depoya yazar; uygulama yeniden başlatılsa bile '
      '(yeni DreamJournalProvider) hatırlanır',
      () async {
        final firstLaunch = DreamJournalProvider();
        firstLaunch.addDream(title: 'Kalıcı Rüya', text: 'Bu kaybolmamalı.');
        // addDream'in kalıcı depoya yazması asenkron (bkz. _save) — yeni
        // provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = DreamJournalProvider();
        await Future<void>.delayed(Duration.zero);

        final restored = secondLaunch.dreams;
        expect(restored, hasLength(1));
        expect(restored.single.title, 'Kalıcı Rüya');
        expect(restored.single.text, 'Bu kaybolmamalı.');
      },
    );

    test(
      'hasEntryToday: hiç rüya yokken false, eklenince true döner (Denge '
      'Ustası — Gizli/Eğlenceli Rozetler)',
      () {
        final provider = DreamJournalProvider();

        expect(provider.hasEntryToday, isFalse);

        provider.addDream(title: 'Rüya', text: 'Metin');

        expect(provider.hasEntryToday, isTrue);
      },
    );
  });
}
