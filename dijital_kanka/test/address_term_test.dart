// applyAddressTerm'in söz havuzlarındaki sabit "Kanka"/"kanka" kelimesini
// kullanıcının hitap tercihiyle doğru büyük/küçük harfle değiştirdiğini
// doğrudan (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/zibo_messages.dart';
import 'package:dijital_kanka/utils/address_term.dart';

void main() {
  test('Varsayılan terim (Kanka) seçiliyken metin hiç değişmez', () {
    const text = 'Kanka bugün kendine iyi davran.';
    expect(applyAddressTerm(text, 'Kanka'), text);
  });

  test('Cümle başındaki büyük harfli "Kanka" seçilen terimle (büyük harfle) değişir', () {
    expect(
      applyAddressTerm('Kanka bugün kendine iyi davran.', 'Reis'),
      'Reis bugün kendine iyi davran.',
    );
  });

  test('Cümle içindeki küçük harfli "kanka" seçilen terimle (küçük harfle) değişir', () {
    expect(
      applyAddressTerm('Tembellik seni sevmiyor kanka.', 'Patron'),
      'Tembellik seni sevmiyor patron.',
    );
  });

  test('Aynı metinde hem büyük hem küçük harfli geçişler birlikte değişir', () {
    expect(
      applyAddressTerm('Kanka bugün de mi kanka moduna geçtin?', 'Abi/Abla'),
      'Abi/Abla bugün de mi abi/abla moduna geçtin?',
    );
  });

  test('Terimde geçmeyen metinler değişmeden kalır', () {
    const text = 'Bugün suyunu içtin mi?';
    expect(applyAddressTerm(text, 'Reis'), text);
  });

  // 2026 güncellemesi — Ana Sayfa konuşma balonu söz havuzuna eklenen 179
  // yeni söz (kullanıcının verdiği 250 satırlık listeden, hem kendi içinde
  // hem mevcut havuzla çakışan tekrarlar ayıklandıktan sonra) doğrudan bu
  // AYNI mekanizmadan geçiyor — ayrı bir kod yolu YOK, yalnızca veri.
  test(
    'ziboMessagesTr havuzundaki yeni sözler de applyAddressTerm ile doğru değişir',
    () {
      const sample = 'Kanka bugün de ayaktasın, bu bile bir şey.';
      expect(ziboMessagesTr, contains(sample));
      expect(
        applyAddressTerm(sample, 'Aslan'),
        'Aslan bugün de ayaktasın, bu bile bir şey.',
      );
    },
  );

  test('ziboMessagesTr havuzunda birebir tekrar eden söz yok', () {
    expect(ziboMessagesTr.toSet().length, ziboMessagesTr.length);
  });
}
