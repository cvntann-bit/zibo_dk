/// Ödüllü reklam (rewarded video) göstermekten sorumlu servisin soyut
/// arayüzü. Gerçek AdMob entegrasyonu geldiğinde, bu arayüzü uygulayan
/// yeni bir `AdMobAdService` yazılıp [CoinProvider]'a verilecek —
/// [CoinProvider] ve onu çağıran ekranların hiçbir satırı değişmeyecek.
abstract class AdService {
  const AdService();

  /// Reklamı gösterir ve kullanıcı ödülü hak ettiyse (videoyu sonuna
  /// kadar izlediyse) true döner. Reklam yüklenemezse, kullanıcı erken
  /// kapatırsa vb. false döner.
  Future<bool> showRewardedAd();
}

/// AdMob SDK'sı bağlanana kadar kullanılan geçici/sahte servis. Kısa bir
/// gecikmeyle (gerçek bir reklam izleme deneyimini simüle etmek için)
/// her zaman başarılı sonuç döner.
class MockAdService extends AdService {
  const MockAdService();

  @override
  Future<bool> showRewardedAd() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
