import '../models/coin_package.dart';

/// Uygulama içi satın alma (IAP) işlemlerinden sorumlu servisin soyut
/// arayüzü. Gerçek implementasyon [InAppPurchasePurchaseService]
/// ([iap_purchase_service.dart](iap_purchase_service.dart)) — `AdService`/
/// `NotificationService` ile AYNI "gerçek servis varsayılan, testte sahte
/// enjekte edilir" felsefesi.
abstract class PurchaseService {
  const PurchaseService();

  /// Paketi satın alma akışını başlatır ve kullanıcı ödemeyi
  /// tamamladıysa true döner. Kullanıcı vazgeçerse, ödeme başarısız
  /// olursa vb. false döner.
  Future<bool> purchaseCoinPackage(CoinPackage package);

  /// Play Store'dan (varsa) bu paketin canlı/yerelleştirilmiş fiyat metnini
  /// sorgular (ör. "₺19,99" — platformun kendi para birimi/bölge/vergi
  /// biçimlendirmesiyle, ASLA elle inşa EDİLMEMİŞ). `null` dönerse (mağaza
  /// kullanılamıyor, ürün Play Console'da henüz AKTİF değil, ağ yok) çağıran
  /// taraf [CoinPackage.price]'taki sabit/görsel fiyata düşer. Varsayılan
  /// implementasyon HER ZAMAN `null` döner — yalnızca gerçek bir mağaza
  /// SDK'sı bunu doldurur.
  Future<String?> queryLocalizedPrice(CoinPackage package) async => null;

  /// Bir önceki oturumdan kalan, henüz teslim edilmemiş (ör. uygulama satın
  /// alma tamamlanmadan çökmüş/kapanmış) satın almalar için — gerçek IAP
  /// servisleri başlangıçta bunları platform mağazasından otomatik olarak
  /// tekrar oynatır. [CoinProvider] bu stream'i dinleyip coin'i GEÇ de olsa
  /// teslim eder (bkz. `iap_purchase_service.dart`'taki "orphaned purchase"
  /// notu). Varsayılan: hiçbir zaman olay yayınlamayan boş bir stream.
  Stream<String> get orphanedPurchaseProductIds => const Stream.empty();
}

/// Gerçek bir ödeme/mağaza SDK'sı bağlanana kadar kullanılan geçici/sahte
/// servis. Kısa bir gecikmeyle (gerçek bir satın alma akışını simüle etmek
/// için) her zaman başarılı sonuç döner.
class MockPurchaseService extends PurchaseService {
  const MockPurchaseService();

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
