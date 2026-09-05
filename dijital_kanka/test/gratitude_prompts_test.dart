// gratitudePromptForField'ın saf/deterministik davranışını doğrudan test
// eder — bkz. gratitude_prompts.dart dokümantasyonu.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/gratitude_prompts.dart';

void main() {
  test('Havuz en az 20 öneri içerir ve tekrarsızdır', () {
    expect(gratitudePromptsTr.length, greaterThanOrEqualTo(20));
    expect(gratitudePromptsTr.toSet().length, gratitudePromptsTr.length);
  });

  test('Aynı gün için üç alan (0,1,2) farklı öneriler döner', () {
    final date = DateTime(2026, 3, 15);
    final p0 = gratitudePromptForField(date, 0);
    final p1 = gratitudePromptForField(date, 1);
    final p2 = gratitudePromptForField(date, 2);
    expect({p0, p1, p2}.length, 3);
  });

  test('Aynı gün + aynı alan için her zaman aynı öneriyi döner (deterministik)', () {
    final date = DateTime(2026, 3, 15);
    expect(
      gratitudePromptForField(date, 0),
      gratitudePromptForField(date, 0),
    );
  });

  test('Gün değişince öneriler değişir', () {
    final today = gratitudePromptForField(DateTime(2026, 3, 15), 0);
    final tomorrow = gratitudePromptForField(DateTime(2026, 3, 16), 0);
    expect(today == tomorrow, isFalse);
  });

  test('Döndürülen her öneri havuzda gerçekten var', () {
    for (var i = 0; i < 5; i++) {
      final prompt = gratitudePromptForField(DateTime(2026, 1, i + 1), 1);
      expect(gratitudePromptsTr, contains(prompt));
    }
  });
}
