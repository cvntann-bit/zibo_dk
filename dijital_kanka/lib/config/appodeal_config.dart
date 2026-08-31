/// Appodeal yapılandırması — TEK Dart config noktası (AdMob'daki
/// `AdMobConfig`'in AYNI deseni). Yeni bir Appodeal App Key'i gerekirse
/// (ör. ayrı bir iOS App Key eklenirse) yalnızca bu dosya güncellenir,
/// `AppodealAdService`/`main.dart` gibi başka HİÇBİR Dart dosyasına
/// dokunmaya gerek YOK.
///
/// **2026 — AdMob → Appodeal geçişi.** Kullanıcının AdMob hesabı "related
/// account" politika ihlaliyle devre dışı bırakıldı (bkz. CLAUDE.md "AdMob/
/// AdSense hesabı devre dışı bırakıldı" notu, itiraz sonucu beklemede).
/// Appodeal bir mediation platformu — AdMob'u da (istenirse) bir ağ olarak
/// kullanabiliyor ama tek bir ağa bağımlı olmadığı için TEK BİR ağın
/// hesap yasaklamasının reklam gelirini tamamen durdurmasını önlüyor.
///
/// **App Key, AdMob'un App ID + Ad Unit ID ikilisinin YERİNE geçen TEK bir
/// değer** — `Appodeal.initialize(appKey: ...)` çağrısına Dart tarafından
/// doğrudan geçiriliyor (AdMob'un App ID'sinin aksine native manifest'ten
/// OKUNMUYOR, bu yüzden AndroidManifest'te ayrıca bir meta-data GEREKMİYOR).
class AppodealConfig {
  const AppodealConfig._();

  /// Appodeal Console'da oluşturulan "Zibo" uygulamasının App Key'i
  /// (bundle id `com.dijitalkanka.dijital_kanka` ile eşleşiyor).
  static const appKey = '6c5e7e6022e1a98028a71951d73681a9f587c7a1993d9114';
}
