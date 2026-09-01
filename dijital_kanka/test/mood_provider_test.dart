// MoodProvider'ın günlük üzerine-yazma mantığını doğrudan (widget
// pump'lamadan) test eder: bugün istenildiği kadar değiştirilebilmeli, gün
// değişince yeni bir seçim açılmalı ve kayıtlar kalıcı olmalı.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/models/mood.dart';
import 'package:dijital_kanka/providers/mood_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MoodProvider', () {
    late DateTime currentDate;
    late MoodProvider provider;

    setUp(() {
      currentDate = DateTime(2026, 1, 5);
      provider = MoodProvider(now: () => currentDate);
    });

    test('Yeni provider bugün için hiçbir seçim yapılmamış başlar', () {
      expect(provider.todayMood, isNull);
      expect(provider.entries, isEmpty);
    });

    test('setTodayMood bugünün ruh halini kaydeder', () {
      provider.setTodayMood(Mood.happy);

      expect(provider.todayMood, Mood.happy);
      expect(provider.entries, hasLength(1));
      expect(provider.entries.single.mood, Mood.happy);
    });

    test('Aynı gün içinde tekrar seçim yapmak öncekinin üzerine yazar', () {
      provider.setTodayMood(Mood.veryUnhappy);
      provider.setTodayMood(Mood.veryHappy);

      expect(provider.todayMood, Mood.veryHappy);
      // Üzerine yazıldığı için hâlâ tek kayıt olmalı, iki değil.
      expect(provider.entries, hasLength(1));
    });

    test('Gün değişince yeni bir seçim açılır, dünkü kayıt geçmişte kalır', () {
      provider.setTodayMood(Mood.neutral);
      expect(provider.todayMood, Mood.neutral);

      currentDate = DateTime(2026, 1, 6); // ertesi gün

      expect(provider.todayMood, isNull);
      expect(provider.entries, hasLength(1)); // dünkü kayıt hâlâ duruyor

      provider.setTodayMood(Mood.unhappy);
      expect(provider.entries, hasLength(2));
      expect(provider.todayMood, Mood.unhappy);
    });

    test('entryForDate belirtilen tarihe ait kaydı döner', () {
      provider.setTodayMood(Mood.happy);
      final today = DateTime(2026, 1, 5);
      final yesterday = DateTime(2026, 1, 4);

      expect(provider.entryForDate(today)?.mood, Mood.happy);
      expect(provider.entryForDate(yesterday), isNull);
    });

    test('entries en yeni kayıt en üstte olacak şekilde sıralanır', () {
      provider.setTodayMood(Mood.neutral);
      currentDate = DateTime(2026, 1, 6);
      provider.setTodayMood(Mood.happy);
      currentDate = DateTime(2026, 1, 7);
      provider.setTodayMood(Mood.veryHappy);

      expect(
        provider.entries.map((e) => e.mood).toList(),
        [Mood.veryHappy, Mood.happy, Mood.neutral],
      );
    });

    test(
      'Kayıt kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni MoodProvider) hatırlanır',
      () async {
        final firstLaunch = MoodProvider(now: () => currentDate);
        firstLaunch.setTodayMood(Mood.veryHappy);
        // setTodayMood'un kalıcı depoya yazması asenkron (bkz. _save) —
        // yeni provider'ı oluşturmadan önce bunun tamamlanmasını bekle.
        await Future<void>.delayed(Duration.zero);

        final secondLaunch = MoodProvider(now: () => currentDate);
        await Future<void>.delayed(Duration.zero);

        expect(secondLaunch.todayMood, Mood.veryHappy);
      },
    );

    // 2026 yeni özellik — bugünün ruh haline eşlik eden serbest not.
    group('not (note) alanı', () {
      test('note verilmeden setTodayMood çağrılırsa not null kalır', () {
        provider.setTodayMood(Mood.happy);
        expect(provider.entries.single.note, isNull);
      });

      test('note verilirse kaydedilir', () {
        provider.setTodayMood(Mood.happy, note: 'Bugün harika geçti');
        expect(provider.entries.single.note, 'Bugün harika geçti');
      });

      test(
        'note VERİLMEDEN yalnızca ruh hali değiştirilirse MEVCUT not korunur',
        () {
          provider.setTodayMood(Mood.happy, note: 'İlk notum');
          provider.setTodayMood(Mood.veryHappy); // note parametresi YOK
          expect(provider.todayMood, Mood.veryHappy);
          expect(provider.entries.single.note, 'İlk notum');
        },
      );

      test('boş/yalnızca boşluk içeren note AÇIKÇA verilirse mevcut notu SİLER', () {
        provider.setTodayMood(Mood.happy, note: 'Silinecek not');
        provider.setTodayMood(Mood.happy, note: '   ');
        expect(provider.entries.single.note, isNull);
      });

      test('note trim edilir', () {
        provider.setTodayMood(Mood.happy, note: '  boşluklu  ');
        expect(provider.entries.single.note, 'boşluklu');
      });

      test(
        'Kayıtlı not kalıcı depoya yazılır; yeniden başlatmada hatırlanır',
        () async {
          final firstLaunch = MoodProvider(now: () => currentDate);
          firstLaunch.setTodayMood(Mood.happy, note: 'Kalıcı not');
          await Future<void>.delayed(Duration.zero);

          final secondLaunch = MoodProvider(now: () => currentDate);
          await Future<void>.delayed(Duration.zero);

          expect(secondLaunch.entries.single.note, 'Kalıcı not');
        },
      );
    });
  });
}
