// 2026 güncellemesi — Mağaza'ya eklenen 10 yeni STANDART (statik gradyan)
// temanın veri katmanını doğrudan (widget pump'lamadan) doğrular: id'lerin
// var olduğu, hiçbirinin "Premium/Animasyonlu" bölümüne düşmediği
// (animationType == none), fiyatların mevcut standart aralıkla (250-500 ZC)
// tutarlı olduğu ve toplam tema sayısının beklendiği gibi 22'ye çıktığı.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/app_themes.dart';
import 'package:dijital_kanka/models/app_theme_option.dart';

void main() {
  const newThemeIds = [
    'lavender_garden',
    'coral_reef',
    'cherry_orchard',
    'mint_greens',
    'desert_dunes',
    'moonlight',
    'copper_hills',
    'emerald_valley',
    'amethyst_cave',
    'dusty_rose_dream',
  ];

  test('appThemes toplamda 22 tema içeriyor (12 eski + 10 yeni standart)', () {
    expect(appThemes.length, 22);
  });

  test('10 yeni tema kendi id\'siyle bulunabiliyor ve her biri STANDART '
      '(animasyonsuz) bölümde', () {
    for (final id in newThemeIds) {
      final theme = findAppThemeById(id);
      expect(theme, isNotNull, reason: '$id bulunamadı');
      expect(
        theme!.animationType,
        ThemeAnimationType.none,
        reason: '$id premium/animasyonlu OLMAMALI',
      );
      expect(theme.isPremiumAnimated, isFalse);
    }
  });

  test('yeni temaların fiyatları mevcut standart aralıkla (250-500 ZC) tutarlı', () {
    for (final id in newThemeIds) {
      final theme = findAppThemeById(id)!;
      expect(theme.price, inInclusiveRange(250, 500), reason: '$id fiyatı: ${theme.price}');
    }
  });

  test('her yeni temanın açık VE koyu mod için en az 2 gradyan durağı var', () {
    for (final id in newThemeIds) {
      final theme = findAppThemeById(id)!;
      expect(theme.lightColors.length, greaterThanOrEqualTo(2));
      expect(theme.darkColors.length, greaterThanOrEqualTo(2));
    }
  });
}
