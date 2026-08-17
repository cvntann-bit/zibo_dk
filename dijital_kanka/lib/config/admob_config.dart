/// AdMob yapılandırması — TEK Dart config noktası. Yeni bir AdMob hesabından
/// gerçek Ödüllü Reklam birimi ID'si alındığında yalnızca [rewardedAdUnitId]
/// güncellenir; `AdMobAdService`/`main.dart` gibi başka HİÇBİR Dart dosyasına
/// dokunmaya gerek YOK.
///
/// **2026 güncellemesi — hesap değişikliği:** İlk "Zibo-Dijital Kankan" AdMob
/// hesabı **Kuruluş (Organization)** türünde açılmıştı, ödeme profilini
/// tamamlarken bir **VAT ID sorunu** çıktı — kullanıcı bu hesabı terk edip
/// yeni bir **Bireysel (Individual)** AdMob hesabı açtı. Aşağıdaki
/// [rewardedAdUnitId], bu YENİ Bireysel hesaptan alınan GERÇEK Ad Unit
/// ID'si — bkz. CLAUDE.md "AdMob Entegrasyonu" bölümü.
///
/// **KRİTİK İSTİSNA — Android App ID bu dosyadan OKUNAMAZ:**
/// `google_mobile_ads` SDK'sı App ID'yi Flutter motoru/Dart kodu HİÇ
/// çalışmadan ÖNCE, native Android `Application.onCreate()` sırasında
/// `AndroidManifest.xml`'deki `com.google.android.gms.ads.APPLICATION_ID`
/// meta-data'sından okur — bu, SDK'nın kendisinden gelen teknik bir
/// kısıtlama, Dart tarafından hiçbir şekilde enjekte edilemez. Bu YENİ
/// hesabın App ID'si de o dosyada AYNI ANDA güncellendi (bkz. o dosyadaki
/// yorum) — bir sonraki hesap/ID değişikliğinde toplamda değiştirilecek
/// YALNIZCA İKİ değer/İKİ satır var, başka hiçbir kod satırına
/// dokunulmuyor.
class AdMobConfig {
  const AdMobConfig._();

  /// Yeni Bireysel AdMob hesabının GERÇEK Ödüllü Reklam birimi ID'si.
  static const rewardedAdUnitId = 'ca-app-pub-2881957853109429/1933318716';
}
