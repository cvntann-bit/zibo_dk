import 'package:in_app_review/in_app_review.dart';

/// Google Play UYGULAMA-İÇİ yorum penceresi (In-App Review API): kullanıcı Play Store'a gitmeden uygulamanın
/// üstünde yıldız/yorum bırakabilir. Soyut arayüz + gerçek implementasyon; test sahte servisle.
///
/// KRİTİK sınırlar (Google): (1) API çağrılsa bile pencere GÖSTERİLMEYEBİLİR (kota) ve kullanıcının puan
/// verip vermediği/pencerenin gösterilip gösterilmediği uygulamaya BİLDİRİLMEZ; (2) ayarlardaki kalıcı
/// "Bizi puanla" satırı bu API'yi değil Play Store sayfasını açmalıdır.
abstract class ReviewService {
  const ReviewService();

  /// `true`: pencere büyük olasılıkla gösterildi. `false`: API yok/başarısız ya da pencere (kota yüzünden)
  /// gösterilmemiş gibi → çağıran Play Store sayfasına düşmelidir.
  Future<bool> requestReview();
}

class InAppReviewService extends ReviewService {
  const InAppReviewService();

  /// Google pencereyi göstermediğinde `requestReview()` neredeyse ANINDA döner; gösterildiğinde kullanıcı
  /// kapatana/puan verene kadar sürer. Bu eşikten kısa süren çağrı "gösterilmedi" sayılır (bilinen sezgisel).
  static const shownThreshold = Duration(milliseconds: 600);

  static bool looksShown(Duration elapsed) => elapsed >= shownThreshold;

  @override
  Future<bool> requestReview() async {
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      final stopwatch = Stopwatch()..start();
      await review.requestReview();
      return looksShown(stopwatch.elapsed);
    } catch (_) {
      return false;
    }
  }
}
