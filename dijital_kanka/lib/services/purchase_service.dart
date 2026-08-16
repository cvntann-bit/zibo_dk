import '../models/coin_package.dart';

/// Uygulama içi satın alma (IAP) işlemlerinden sorumlu servisin soyut
/// arayüzü. Gerçek IAP entegrasyonu (ör. `in_app_purchase` paketi) geldiğinde
/// bu arayüzü uygulayan yeni bir `IapPurchaseService` yazılıp
/// [CoinProvider]'a verilecek — [CoinProvider] ve onu çağıran ekranların
/// hiçbir satırı değişmeyecek.
abstract class PurchaseService {
  const PurchaseService();

  /// Paketi satın alma akışını başlatır ve kullanıcı ödemeyi
  /// tamamladıysa true döner. Kullanıcı vazgeçerse, ödeme başarısız
  /// olursa vb. false döner.
  Future<bool> purchaseCoinPackage(CoinPackage package);
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
