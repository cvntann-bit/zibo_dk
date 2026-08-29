// TrustedTimeProvider birim testleri — özellikle "Günlük Zibo Coin ödülü
// 1. günde takılı kalıyor" bug raporunun kök nedeni olan cross-session
// staleness senaryosunu (bkz. trusted_time_provider.dart'taki "2026 bug
// düzeltmesi" dokümantasyonu) doğruluyor: kalıcı depodan yüklenen ESKİ bir
// `_lastVerifiedUtc`, BU oturumda henüz taze bir ağ doğrulaması
// tamamlanmadan `now()` tarafından KULLANILMAMALI.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/trusted_time_provider.dart';
import 'package:dijital_kanka/services/trusted_time_service.dart';

class _FakeTrustedTimeService extends TrustedTimeService {
  _FakeTrustedTimeService({this.result});

  DateTime? result;
  int callCount = 0;

  @override
  Future<DateTime?> fetchNetworkTime() async {
    callCount++;
    return result;
  }
}

const _prefsKey = 'trustedTimeLastVerifiedUtc';

Future<void> _flushMicrotasks() async {
  // _loadFromPrefs() -> SharedPreferences.getInstance() -> syncIfNeeded()
  // -> fetchNetworkTime() zincirini gerçek zaman beklemeden akıtmak için —
  // GoalsProvider/DailyRewardsProvider testlerindeki AYNI desen.
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Kalıcı veri yok + senkron başarısız → now() cihaz saatine düşer', () async {
    final service = _FakeTrustedTimeService(result: null);
    final provider = TrustedTimeProvider(timeService: service);
    await _flushMicrotasks();

    expect(provider.hasVerifiedTime, isFalse);
    final diff = provider.now().toUtc().difference(DateTime.now().toUtc()).abs();
    expect(diff, lessThan(const Duration(seconds: 5)));
  });

  test('Kalıcı veri yok + senkron başarılı → now() ağdan doğrulanan zamanı kullanır', () async {
    final networkTime = DateTime.utc(2030, 1, 1, 12);
    final service = _FakeTrustedTimeService(result: networkTime);
    final provider = TrustedTimeProvider(timeService: service);
    await _flushMicrotasks();

    expect(provider.hasVerifiedTime, isTrue);
    // `_stopwatch.elapsed` testte çok kısa sürdüğü için birkaç saniyelik
    // bir tolerans yeterli.
    final diff = provider.now().toUtc().difference(networkTime).abs();
    expect(diff, lessThan(const Duration(seconds: 5)));
  });

  test(
    'KRİTİK — kalıcı depoda ESKİ bir doğrulama var + BU OTURUMDA senkron '
    'BAŞARISIZ → now() eski/dondurulmuş tarihi DEĞİL, cihaz saatini döner '
    '(cross-session staleness — "günlük ödül 1. günde takılı kalıyor" bug\'ı)',
    () async {
      final staleUtc = DateTime.utc(2020, 1, 1); // günlerce/yıllarca eski
      SharedPreferences.setMockInitialValues({
        _prefsKey: staleUtc.toIso8601String(),
      });
      final service = _FakeTrustedTimeService(result: null); // bu oturumda ağ HİÇ doğrulanmıyor
      final provider = TrustedTimeProvider(timeService: service);
      await _flushMicrotasks();

      // hasVerifiedTime kalıcı depodan yüklendiği için true dönebilir — ama
      // bu, now()'ın o eski değeri KULLANMASI için YETERLİ değil (bkz. sınıf
      // dokümantasyonu) — asıl garanti now()'ın GERÇEK zamana yakın kalması.
      final result = provider.now().toUtc();
      final diffFromStale = result.difference(staleUtc).abs();
      final diffFromRealNow = result.difference(DateTime.now().toUtc()).abs();

      expect(
        diffFromRealNow,
        lessThan(const Duration(seconds: 5)),
        reason: 'now() gerçek cihaz saatine yakın olmalı, eski kayıtlı değere değil',
      );
      expect(diffFromStale, greaterThan(const Duration(days: 1)));
    },
  );

  test(
    'Kalıcı depoda eski doğrulama var + BU OTURUMDA senkron BAŞARILI → '
    'now() artık taze ağ zamanını kullanır (eski değeri geride bırakır)',
    () async {
      final staleUtc = DateTime.utc(2020, 1, 1);
      SharedPreferences.setMockInitialValues({
        _prefsKey: staleUtc.toIso8601String(),
      });
      final freshUtc = DateTime.utc(2030, 6, 15, 8);
      final service = _FakeTrustedTimeService(result: freshUtc);
      final provider = TrustedTimeProvider(timeService: service);
      await _flushMicrotasks();

      final diff = provider.now().toUtc().difference(freshUtc).abs();
      expect(diff, lessThan(const Duration(seconds: 5)));
    },
  );

  test('force olmadan syncIfNeeded cooldown içindeyse tekrar ağ isteği atmaz', () async {
    final service = _FakeTrustedTimeService(result: DateTime.utc(2030));
    final provider = TrustedTimeProvider(timeService: service);
    await _flushMicrotasks();
    expect(service.callCount, 1);

    await provider.syncIfNeeded();
    await _flushMicrotasks();
    expect(service.callCount, 1, reason: 'cooldown içinde force:false ikinci bir istek atmamalı');
  });
}
