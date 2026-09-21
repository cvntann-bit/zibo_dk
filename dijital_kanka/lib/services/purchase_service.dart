import '../models/coin_package.dart';
import '../models/subscription_offer.dart';

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
  /// notu). **`AdFreeProvider` da AYNI stream'i, cihaz/hesap değişiminde
  /// [restorePurchases] sonrası geri gelen KALICI ürünü yakalamak için
  /// dinler** — bu yüzden `main.dart`'ta CoinProvider'la AYNI
  /// [PurchaseService] örneği paylaşılmalı. Varsayılan: hiçbir zaman olay
  /// yayınlamayan boş bir stream.
  Stream<String> get orphanedPurchaseProductIds => const Stream.empty();

  /// "Reklamsız Zibo" (bkz. `AdFreeProvider.productId`) KALICI/tek seferlik
  /// ürününün satın alma akışını başlatır — [purchaseCoinPackage]'ın
  /// tüketilebilir akışından FARKLI (`buyNonConsumable`). Kullanıcı ödemeyi
  /// tamamladıysa true döner.
  Future<bool> purchaseAdRemoval() async => false;

  /// Cihaz/hesap değiştiğinde (yeniden kurulum, yeni telefon) daha önce
  /// satın alınmış KALICI ürünleri Play Store'dan sorgulayıp geri oynatır.
  /// Sonuç bu metodun kendi dönüş değeri DEĞİL, [orphanedPurchaseProductIds]
  /// stream'i üzerinden (varsa `AdFreeProvider`'a) ulaşır — bkz.
  /// `iap_purchase_service.dart`.
  Future<void> restorePurchases() async {}

  /// "Reklamsız Zibo" ürününün Play Store'dan sorgulanan canlı/yerelleştirilmiş
  /// fiyat metnini döner — [queryLocalizedPrice] ile AYNI gerekçe: Play
  /// Console'da girilen fiyat KDV/vergi ile GERÇEKTE kullanıcıya gösterilenden
  /// farklı olabiliyor (bkz. `AdFreeProvider.queryLocalizedPrice`
  /// dokümantasyonu — gerçek cihazda 159,90 TL yerine 189,90 TL çıkması BU
  /// yüzden). `null` dönerse çağıran taraf sabit/görsel fiyata (bkz.
  /// `paywall_screen.dart`'taki `adFreeFallbackPrice`) düşer.
  Future<String?> queryAdRemovalLocalizedPrice() async => null;

  /// Bir abonelik teklifinin ([SubscriptionOffer] — ürün + temel plan)
  /// satın alma akışını başlatır. [purchaseAdRemoval] ile AYNI
  /// istek/yanıt sözleşmesi (`Future<bool>`) — [SubscriptionProvider]
  /// başarı sonrası kendi durumunu günceller, makbuz burada
  /// doğrulanmaz (bkz. `docs/decisions/005-coin-economy-client-
  /// authoritative.md` — IAP'lerin TAMAMI AYNI mimari boşlukta).
  Future<bool> purchaseSubscription(SubscriptionOffer offer) async => false;

  /// [offer]'ın Play Store'dan sorgulanan canlı/yerelleştirilmiş fiyat
  /// metnini döner — [queryLocalizedPrice] ile AYNI gerekçe. `null`
  /// dönerse çağıran taraf sabit/görsel bir fiyata düşer.
  Future<String?> querySubscriptionLocalizedPrice(
    SubscriptionOffer offer,
  ) async => null;

  /// Kullanıcının hâlihazırda AKTİF olan [oldProductId] aboneliğini
  /// (ör. `zibo_pro`) [newOffer]'a (ör. `zibo_proplus` yıllık) YÜKSELTİR/
  /// DEĞİŞTİRİR — [purchaseSubscription]'ın aksine SIFIRDAN bir abonelik
  /// başlatmaz, Play Billing'in "abonelik değiştirme" akışını (Android'e
  /// özgü `ChangeSubscriptionParam`) kullanır. Eski satın almanın TOKEN'ı
  /// burada AYRICA saklanmaz — gerçek implementasyon her çağrıda Play'in
  /// yerel önbelleğinden TAZE sorgular (bkz. `iap_purchase_service.dart`).
  /// `docs/decisions/012-subscription-tier-tracking.md`'deki AYNI istemci-
  /// yetkili mimari boşluk burada da geçerli.
  Future<bool> upgradeSubscription(
    SubscriptionOffer newOffer, {
    required String oldProductId,
  }) async => false;
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

  @override
  Future<bool> purchaseAdRemoval() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionOffer offer) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<bool> upgradeSubscription(
    SubscriptionOffer newOffer, {
    required String oldProductId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
