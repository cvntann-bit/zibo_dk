/// Ödüllü reklam (rewarded video) VE geçiş reklamı (interstitial)
/// göstermekten sorumlu servisin soyut arayüzü. Gerçek AdMob entegrasyonu
/// geldiğinde, bu arayüzü uygulayan yeni bir `AdMobAdService` yazılıp
/// [CoinProvider]'a verilecek — [CoinProvider] ve onu çağıran ekranların
/// hiçbir satırı değişmeyecek.
abstract class AdService {
  const AdService();

  /// Reklamı gösterir ve kullanıcı ödülü hak ettiyse (videoyu sonuna
  /// kadar izlediyse) true döner. Reklam yüklenemezse, kullanıcı erken
  /// kapatırsa vb. false döner.
  Future<bool> showRewardedAd();

  /// 2026 güncellemesi — Ana Sayfa'da Zibo'ya art arda hızlı dokunulduğunda
  /// gösterilen geçiş (interstitial) reklamı. Ödüllü reklamın AKSİNE bir
  /// "ödül" kavramı yok — reklam başarıyla GÖSTERİLEBİLDİYSE (kullanıcı
  /// erken kapatsa bile) true döner, hiç gösterilemediyse (yüklenemedi vb.)
  /// false döner.
  Future<bool> showInterstitialAd();
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

  @override
  Future<bool> showInterstitialAd() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }
}
