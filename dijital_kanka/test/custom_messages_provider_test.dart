// CustomMessagesProvider'ın ekleme/silme/boş-metin-reddi ve kalıcılık
// davranışını doğrudan (widget pump'lamadan) test eder — FavoriteQuotesProvider
// testleriyle aynı desen.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/custom_messages_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider boş bir mesaj listesiyle başlar', () async {
    final provider = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.messages, isEmpty);
  });

  test('addMessage bir mesajı listenin BAŞINA ekler', () async {
    final provider = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addMessage('Birinci mesaj');
    provider.addMessage('İkinci mesaj');

    expect(provider.messages, ['İkinci mesaj', 'Birinci mesaj']);
  });

  test('addMessage baştaki/sondaki boşlukları kırpar', () async {
    final provider = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addMessage('  Boşluklu mesaj  ');

    expect(provider.messages, ['Boşluklu mesaj']);
  });

  test('addMessage boş veya yalnızca boşluk içeren metni sessizce reddeder', () async {
    final provider = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addMessage('');
    provider.addMessage('   ');

    expect(provider.messages, isEmpty);
  });

  test('removeMessage bir mesajı listeden çıkarır', () async {
    final provider = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.addMessage('Silinecek mesaj');
    provider.removeMessage('Silinecek mesaj');

    expect(provider.messages, isEmpty);
  });

  test('Mesajlar kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni CustomMessagesProvider) hatırlanır', () async {
    final firstLaunch = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);
    firstLaunch.addMessage('Kalıcı mesaj');
    await Future<void>.delayed(Duration.zero);

    final secondLaunch = CustomMessagesProvider();
    await Future<void>.delayed(Duration.zero);

    expect(secondLaunch.messages, ['Kalıcı mesaj']);
  });
}
