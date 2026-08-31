/// Ödüllü reklam (rewarded video) VE geçiş reklamı (interstitial)
/// göstermekten sorumlu servisin soyut arayüzü. Gerçek reklam entegrasyonu
/// bu arayüzü uygulayan bir sınıfla (bkz. `AppodealAdService`) sağlanıyor —
/// bir reklam SDK'sından başka birine geçilirken (AdMob → Appodeal geçişinde
/// olduğu gibi, bkz. CLAUDE.md "AdMob Entegrasyonu" bölümü) tek yapılması
/// gereken bu arayüzü uygulayan YENİ bir sınıf yazıp [CoinProvider]'a
/// vermek — [CoinProvider] ve onu çağıran ekranların hiçbir satırı
/// değişmiyor.
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

/// Gerçek bir reklam SDK'sının platform kanalına dokunamayan `flutter_test`
/// ortamında enjekte edilen sahte servis. Kısa bir gecikmeyle (gerçek bir
/// reklam izleme deneyimini simüle etmek için) her zaman başarılı sonuç
/// döner.
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
