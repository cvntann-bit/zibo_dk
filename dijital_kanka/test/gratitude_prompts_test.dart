// gratitudePromptForField'ın saf/deterministik davranışını doğrudan test
// eder — bkz. gratitude_prompts.dart dokümantasyonu.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/gratitude_prompts.dart';

void main() {
  const tr = Locale('tr');
  const en = Locale('en');
  const es = Locale('es');

  test('Üç havuz da (TR/EN/ES) en az 20 öneri içerir ve tekrarsızdır', () {
    for (final pool in [gratitudePromptsTr, gratitudePromptsEn, gratitudePromptsEs]) {
      expect(pool.length, greaterThanOrEqualTo(20));
      expect(pool.toSet().length, pool.length);
    }
  });

  test('Üç havuz da BİREBİR aynı uzunlukta (index-tabanlı seçim güvenli)', () {
    expect(gratitudePromptsEn.length, gratitudePromptsTr.length);
    expect(gratitudePromptsEs.length, gratitudePromptsTr.length);
  });

  test('Aynı gün için üç alan (0,1,2) farklı öneriler döner', () {
    final date = DateTime(2026, 3, 15);
    final p0 = gratitudePromptForField(date, 0, tr);
    final p1 = gratitudePromptForField(date, 1, tr);
    final p2 = gratitudePromptForField(date, 2, tr);
    expect({p0, p1, p2}.length, 3);
  });

  test('Aynı gün + aynı alan için her zaman aynı öneriyi döner (deterministik)', () {
    final date = DateTime(2026, 3, 15);
    expect(
      gratitudePromptForField(date, 0, tr),
      gratitudePromptForField(date, 0, tr),
    );
  });

  test('Gün değişince öneriler değişir', () {
    final today = gratitudePromptForField(DateTime(2026, 3, 15), 0, tr);
    final tomorrow = gratitudePromptForField(DateTime(2026, 3, 16), 0, tr);
    expect(today == tomorrow, isFalse);
  });

  test('Döndürülen her öneri havuzda gerçekten var', () {
    for (var i = 0; i < 5; i++) {
      final prompt = gratitudePromptForField(DateTime(2026, 1, i + 1), 1, tr);
      expect(gratitudePromptsTr, contains(prompt));
    }
  });

  test('Dil İngilizce/İspanyolca iken doğru havuzdan öneri döner', () {
    final date = DateTime(2026, 5, 10);
    expect(gratitudePromptsEn, contains(gratitudePromptForField(date, 0, en)));
    expect(gratitudePromptsEs, contains(gratitudePromptForField(date, 0, es)));
  });

  test('Bilinmeyen bir dil için Türkçe\'ye düşer', () {
    final date = DateTime(2026, 5, 10);
    expect(
      gratitudePromptForField(date, 0, const Locale('fr')),
      gratitudePromptForField(date, 0, tr),
    );
  });

  test('AYNI gün+alan için üç dilin metni FARKLI (gerçek çeviri, aynı index)', () {
    final date = DateTime(2026, 5, 10);
    final trText = gratitudePromptForField(date, 0, tr);
    final enText = gratitudePromptForField(date, 0, en);
    final esText = gratitudePromptForField(date, 0, es);
    expect({trText, enText, esText}.length, 3);
  });

  test('gratitudePromptsForLocale doğru havuzu döner', () {
    expect(gratitudePromptsForLocale(tr), gratitudePromptsTr);
    expect(gratitudePromptsForLocale(en), gratitudePromptsEn);
    expect(gratitudePromptsForLocale(es), gratitudePromptsEs);
  });
}
