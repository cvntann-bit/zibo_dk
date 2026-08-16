// FavoriteQuotesProvider'ın favorileme/favoriden çıkarma ve kalıcılık
// davranışını doğrudan (widget pump'lamadan) test eder.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Yeni provider boş bir favori listesiyle başlar', () async {
    final provider = FavoriteQuotesProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.quotes, isEmpty);
    expect(provider.isFavorite('herhangi bir söz'), isFalse);
  });

  test('toggleFavorite bir sözü ekler, tekrar çağrılınca çıkarır', () async {
    final provider = FavoriteQuotesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.toggleFavorite('Hadi kanka, bugün de bir şeyler başaracaksın.');
    expect(provider.isFavorite('Hadi kanka, bugün de bir şeyler başaracaksın.'), isTrue);
    expect(provider.quotes, ['Hadi kanka, bugün de bir şeyler başaracaksın.']);

    provider.toggleFavorite('Hadi kanka, bugün de bir şeyler başaracaksın.');
    expect(provider.isFavorite('Hadi kanka, bugün de bir şeyler başaracaksın.'), isFalse);
    expect(provider.quotes, isEmpty);
  });

  test('En son favorilenen söz listenin başında görünür', () async {
    final provider = FavoriteQuotesProvider();
    await Future<void>.delayed(Duration.zero);

    provider.toggleFavorite('Birinci söz');
    provider.toggleFavorite('İkinci söz');

    expect(provider.quotes, ['İkinci söz', 'Birinci söz']);
  });

  test('Favoriler kalıcı depoya yazılır; uygulama yeniden başlatılsa bile '
      '(yeni FavoriteQuotesProvider) hatırlanır', () async {
    final firstLaunch = FavoriteQuotesProvider();
    await Future<void>.delayed(Duration.zero);
    firstLaunch.toggleFavorite('Kalıcı söz');
    await Future<void>.delayed(Duration.zero);

    final secondLaunch = FavoriteQuotesProvider();
    await Future<void>.delayed(Duration.zero);

    expect(secondLaunch.quotes, ['Kalıcı söz']);
  });
}
