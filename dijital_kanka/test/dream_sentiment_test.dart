// `isNegativeDream`'in (bkz. lib/utils/dream_sentiment.dart) saf-fonksiyon
// anahtar kelime taramasını doğrudan test eder — AI/dış servis YOK, yalnızca
// başlık+metinde bilinen "kötü rüya" kelimelerinin (TR+EN+ES birleşik) arandığı
// doğrulanır.

import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/models/dream_entry.dart';
import 'package:dijital_kanka/utils/dream_sentiment.dart';

DreamEntry _dream({String title = '', String text = ''}) {
  return DreamEntry(id: '1', title: title, text: text, date: DateTime(2026, 1, 5));
}

void main() {
  test('Türkçe olumsuz bir kelime içeren rüya olumsuz sayılır', () {
    expect(isNegativeDream(_dream(title: 'Kabus', text: 'Kötü bir şey gördüm')), isTrue);
  });

  test('Metin gövdesindeki (başlıkta değil) bir anahtar kelime de yakalanır', () {
    expect(
      isNegativeDream(_dream(title: 'Garip bir gece', text: 'Karanlıkta kaçıyordum')),
      isTrue,
    );
  });

  test('İngilizce/İspanyolca yazılmış olumsuz bir rüya da yakalanır', () {
    expect(isNegativeDream(_dream(title: 'Nightmare', text: 'I was being chased')), isTrue);
    expect(isNegativeDream(_dream(title: 'Pesadilla', text: 'Tenía mucho miedo')), isTrue);
  });

  test('Büyük/küçük harf duyarsız çalışır', () {
    expect(isNegativeDream(_dream(title: 'KABUS GÖRDÜM', text: '')), isTrue);
  });

  test('Nötr/olumlu bir rüya olumsuz sayılmaz', () {
    expect(
      isNegativeDream(
        _dream(title: 'Güzel bir rüya', text: 'Deniz kenarında yürüyordum, çok huzurluydu'),
      ),
      isFalse,
    );
  });

  test('Boş başlık/metin olumsuz sayılmaz', () {
    expect(isNegativeDream(_dream()), isFalse);
  });
}
