// applyAddressTerm'in söz havuzlarındaki sabit "Kanka"/"kanka" kelimesini
// kullanıcının hitap tercihiyle doğru büyük/küçük harfle değiştirdiğini
// doğrudan (widget pump'lamadan) test eder.

import 'package:flutter/material.dart' show Locale;
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

  // 2026 güncellemesi — applyAddressTerm artık locale-aware: TR "Kanka",
  // EN "Buddy", ES "Amigo" yer tutucusunu değiştiriyor (bkz.
  // utils/address_term.dart'taki tam açıklama). Bu mekanizma İLK KEZ
  // İngilizce/İspanyolca söz havuzlarında da işlevsel hale geldi — önceki
  // sürümde bu iki dildeki sözlerde hitap ASLA kişiselleşmiyordu.
  group('Locale-aware hitap (2026)', () {
    test('İngilizce: "Buddy"/"buddy" seçilen terimle değişir', () {
      expect(
        applyAddressTerm(
          'Buddy, take care of yourself today, I\'m watching.',
          'Champ',
          const Locale('en'),
        ),
        'Champ, take care of yourself today, I\'m watching.',
      );
      expect(
        applyAddressTerm(
          "Laziness doesn't love you, buddy — I do.",
          'Champ',
          const Locale('en'),
        ),
        "Laziness doesn't love you, champ — I do.",
      );
    });

    test('İspanyolca: "Amigo"/"amigo" seçilen terimle değişir', () {
      expect(
        applyAddressTerm(
          'Amigo, cuídate hoy, yo te estoy mirando.',
          'Campeón',
          const Locale('es'),
        ),
        'Campeón, cuídate hoy, yo te estoy mirando.',
      );
      expect(
        applyAddressTerm(
          'La pereza no te quiere, amigo, yo sí.',
          'Campeón',
          const Locale('es'),
        ),
        'La pereza no te quiere, campeón, yo sí.',
      );
    });

    test(
      'Varsayılan terim (Kanka) seçiliyken hiçbir dilde metin değişmez',
      () {
        const enText = 'Buddy, take care of yourself today.';
        const esText = 'Amigo, cuídate hoy.';
        expect(applyAddressTerm(enText, 'Kanka', const Locale('en')), enText);
        expect(applyAddressTerm(esText, 'Kanka', const Locale('es')), esText);
      },
    );

    test('locale verilmezse varsayılan Türkçe davranışa düşer (geriye dönük uyumluluk)', () {
      expect(
        applyAddressTerm('Kanka bugün kendine iyi davran.', 'Reis'),
        'Reis bugün kendine iyi davran.',
      );
    });

    test(
      'ziboMessagesEn/Es havuzlarındaki yeni sözler de doğru değişir',
      () {
        const enSample = "Buddy, you're still standing today, and that's something.";
        const esSample = 'Amigo, sigues en pie hoy, y eso ya es algo.';
        expect(ziboMessagesEn, contains(enSample));
        expect(ziboMessagesEs, contains(esSample));
        expect(
          applyAddressTerm(enSample, 'Aslan', const Locale('en')),
          "Aslan, you're still standing today, and that's something.",
        );
        expect(
          applyAddressTerm(esSample, 'Aslan', const Locale('es')),
          'Aslan, sigues en pie hoy, y eso ya es algo.',
        );
      },
    );
  });

  test('ziboMessagesEn/Es artık TR ile AYNI sayıda söz içeriyor (279)', () {
    expect(ziboMessagesTr.length, 279);
    expect(ziboMessagesEn.length, 279);
    expect(ziboMessagesEs.length, 279);
  });

  test('ziboMessagesEn havuzunda birebir tekrar eden söz yok', () {
    expect(ziboMessagesEn.toSet().length, ziboMessagesEn.length);
  });

  test('ziboMessagesEs havuzunda birebir tekrar eden söz yok', () {
    expect(ziboMessagesEs.toSet().length, ziboMessagesEs.length);
  });
}
