import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/coin_package.dart';
import '../models/subscription_offer.dart';
import 'purchase_service.dart';

/// Gerçek Google Play Billing entegrasyonu (`in_app_purchase` paketi).
/// Tüm coin paketleri Play Console'da TÜKETİLEBİLİR (consumable) ürünler
/// olarak tanımlanmalı — `CoinPackage.id` (ör. `coins_100`) BİREBİR Play
/// Console'daki ürün id'siyle eşleşmeli (bkz. CLAUDE.md "Google Play
/// Billing (IAP) Entegrasyonu" bölümü).
///
/// **Mimari — `PurchaseService.purchaseCoinPackage()`'ın basit
/// istek/yanıt (`Future<bool>`) sözleşmesi ile `in_app_purchase`'ın
/// STREAM-tabanlı API'si arasında bir köprü kuruyor.** `_pending` haritası,
/// AKTİF bir `purchaseCoinPackage()` çağrısının hangi ürün id'sini
/// beklediğini tutar; `purchaseStream`'den gelen her olay önce bu haritada
/// eşleşen bir `Completer` arar, varsa onu tamamlar. **Eşleşen bir
/// `Completer` YOKSA** (bkz. altta "orphaned purchase" notu) olay
/// [orphanedPurchaseProductIds] stream'ine yayınlanır — `CoinProvider` bunu
/// dinleyip coin'i yine de teslim eder.
///
/// **Orphaned purchase — neden gerekli:** `buyConsumable(autoConsume:
/// true)` başlatıldıktan SONRA ama `purchaseStream`'in `purchased` olayı
/// bu servise ULAŞMADAN ÖNCE uygulama çökerse/kapanırsa, ödeme Google'da
/// GERÇEKLEŞMİŞ ama coin HİÇ teslim EDİLMEMİŞ olur — "para alındı, ürün
/// verilmedi" gibi kötü bir sonuç. Google Play, tamamlanmamış (henüz
/// `completePurchase` ile "acknowledge" edilmemiş) satın almaları BİR
/// SONRAKİ `isAvailable()`/stream dinleme başlangıcında OTOMATİK olarak
/// tekrar oynatır — bu servis constructor'da hemen dinlemeye başladığı
/// için, uygulama bir SONRAKİ açılışında bu "yetim" satın almayı yakalar
/// ve `orphanedPurchaseProductIds` üzerinden geç de olsa teslim eder.
class InAppPurchasePurchaseService extends PurchaseService {
  InAppPurchasePurchaseService({InAppPurchase? inAppPurchase})
    : _iap = inAppPurchase ?? InAppPurchase.instance {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {
        // Stream'in kendisi bozulursa (nadir) sessizce yut — aktif
        // bekleyen satın almalar zaten kendi `queryProductDetails`/
        // `buyConsumable` çağrısındaki try/catch'lerle `false`'a düşecek.
      },
    );
  }

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, Completer<bool>> _pending = {};
  final _orphanedController = StreamController<String>.broadcast();

  /// Kullanıcı, Play Billing ödeme ekranını başlattıktan SONRA (ör. sistem
  /// GERİ tuşuyla) öyle bir şekilde kapatabiliyor ki `purchaseStream` HİÇBİR
  /// olay yayınlamıyor (gerçek cihazda GÖZLEMLENEN bir davranış — 2026-09-12,
  /// "Zibo ADS" satın alma testinde). Bu olmadan o denemenin `Completer`'ı
  /// SONSUZA KADAR beklerdi. **İLK düzeltmede bu tek başına yeterli
  /// SANILDI ama DEĞİLDİ** — `purchaseCoinPackage`/`purchaseAdRemoval` HER
  /// çağrıda [_pending]'de eski bir kayıt varsa onu PAYLAŞIP YENİ bir
  /// `buyConsumable`/`buyNonConsumable` HİÇ BAŞLATMIYORDU; kullanıcı ilk
  /// denemeden hemen SONRA (süre dolmadan, saniyeler içinde) tekrar
  /// bastığında buton YİNE tepkisiz kalıyordu (Play Store ekranı bir daha
  /// açılmıyordu) — bkz. 2026-09-12 ikinci kullanıcı raporu. Gerçek düzeltme
  /// aşağıda: HER çağrı [_pending]'i KOŞULSUZ üzerine yazıp YENİ bir akış
  /// başlatıyor (aynı-widget'ta hızlı çift-tıklamayı zaten arayüz katmanı
  /// `_purchasing`/`_loading` bayrağıyla engelliyor, bkz. `ad_free_promo_
  /// sheet.dart`/`store_screen.dart` — servis katmanının AYRICA bunu
  /// engellemesine gerek YOK, tam tersi zararlı çıktı). Bu süre artık
  /// yalnızca "kullanıcı hiç tekrar denemeden sonsuza dek beklerse" durumu
  /// için bir güvenlik ağı — dolunca "başarısız" sayılır; olay YİNE DE bu
  /// süreden SONRA gelirse [_onPurchaseUpdate] onu "yetim satın alma" olarak
  /// ele alıp [orphanedPurchaseProductIds] üzerinden GEÇ de olsa teslim eder
  /// — coin/reklamsız durumu hiçbir senaryoda KAYBOLMAZ.
  static const _purchaseTimeout = Duration(minutes: 2);

  Future<bool> _awaitPendingWithTimeout(
    String productId,
    Completer<bool> completer,
  ) {
    return completer.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _pending.remove(productId);
        return false;
      },
    );
  }

  @override
  Stream<String> get orphanedPurchaseProductIds => _orphanedController.stream;

  void dispose() {
    _subscription?.cancel();
    _orphanedController.close();
  }

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async {
    // `isAvailable()`/`queryProductDetails()` de (`buyConsumable()` gibi)
    // platform kanalına dokunuyor — desteklenmeyen bir platformda/ortamda
    // (ör. flutter_test, mağaza hesabı bağlı olmayan bir emülatör) bunlar
    // beklenmedik şekilde fırlatabilir; TÜM akış tek bir try/catch'e
    // sarılı, hiçbir dal `false` dönmeden önce istisna DIŞARI SIZDIRMIYOR.
    try {
      if (!await _iap.isAvailable()) return false;

      final response = await _iap.queryProductDetails({package.id});
      if (response.error != null || response.productDetails.isEmpty) {
        return false;
      }

      final completer = Completer<bool>();
      _pending[package.id] = completer;

      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
        autoConsume: true,
      );
      if (!started) {
        _pending.remove(package.id);
        return false;
      }

      return await _awaitPendingWithTimeout(package.id, completer);
    } catch (_) {
      _pending.remove(package.id);
      return false;
    }
  }

  @override
  Future<bool> purchaseAdRemoval() async {
    // `AdFreeProvider.productId` sabitini burada import ETMİYORUZ —
    // `purchase_service.dart` (bu dosyanın uyguladığı arayüz) provider
    // katmanına bağımlı olmamalı, bu yüzden ID doğrudan (coin paketlerinin
    // Play Console id'leri gibi) burada sabit yazılı. İkisi de AYNI
    // string'i taşımalı: `remove_ads_lifetime`.
    const productId = 'remove_ads_lifetime';

    try {
      if (!await _iap.isAvailable()) return false;

      final response = await _iap.queryProductDetails({productId});
      if (response.error != null || response.productDetails.isEmpty) {
        return false;
      }

      final completer = Completer<bool>();
      _pending[productId] = completer;

      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: response.productDetails.first,
        ),
      );
      if (!started) {
        _pending.remove(productId);
        return false;
      }

      return await _awaitPendingWithTimeout(productId, completer);
    } catch (_) {
      _pending.remove(productId);
      return false;
    }
  }

  /// `queryProductDetails({productId})`'in Android'de bir abonelik ürünü
  /// için döndürdüğü liste — ürünün HER temel planı/teklifi için AYRI bir
  /// `GooglePlayProductDetails` girdisi içerir (`GooglePlayProductDetails.
  /// fromProductDetails` — bkz. `in_app_purchase_android` paket kaynağı).
  /// [ProductDetails.id] hepsinde AYNI (ürün id'si) kalır, temel planı
  /// ayırt eden şey `subscriptionOfferDetails[subscriptionIndex].
  /// basePlanId`'dir — bu yüzden düz `queryProductDetails({package.id})`
  /// gibi TEK bir eşleşme yeterli DEĞİL, [offer.basePlanId] ile eşleşen
  /// GİRDİYİ bulmamız gerekiyor.
  GooglePlayProductDetails? _findBasePlanDetails(
    List<ProductDetails> productDetailsList,
    SubscriptionOffer offer,
  ) {
    for (final details in productDetailsList) {
      if (details is! GooglePlayProductDetails) continue;
      if (details.id != offer.productId) continue;
      final index = details.subscriptionIndex;
      if (index == null) continue;
      final basePlanId =
          details.productDetails.subscriptionOfferDetails?[index].basePlanId;
      if (basePlanId == offer.basePlanId) return details;
    }
    return null;
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionOffer offer) async {
    try {
      if (!await _iap.isAvailable()) return false;

      final response = await _iap.queryProductDetails({offer.productId});
      if (response.error != null) return false;
      final matched = _findBasePlanDetails(response.productDetails, offer);
      if (matched == null) return false;

      final completer = Completer<bool>();
      _pending[offer.productId] = completer;

      final started = await _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: matched,
          offerToken: matched.offerToken,
        ),
      );
      if (!started) {
        _pending.remove(offer.productId);
        return false;
      }

      return await _awaitPendingWithTimeout(offer.productId, completer);
    } catch (_) {
      _pending.remove(offer.productId);
      return false;
    }
  }

  @override
  Future<String?> querySubscriptionLocalizedPrice(
    SubscriptionOffer offer,
  ) async {
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({offer.productId});
      if (response.error != null) return null;
      final matched = _findBasePlanDetails(response.productDetails, offer);
      return matched?.price;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      // Ağ yok/mağaza kullanılamıyor — sessizce yut, `AdFreeProvider` yerel
      // kalıcı bayrağıyla (varsa) çalışmaya devam eder.
    }
  }

  @override
  Future<String?> queryLocalizedPrice(CoinPackage package) async {
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({package.id});
      if (response.error != null || response.productDetails.isEmpty) {
        return null;
      }
      return response.productDetails.first.price;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> queryAdRemovalLocalizedPrice() async {
    const productId = 'remove_ads_lifetime';
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({productId});
      if (response.error != null || response.productDetails.isEmpty) {
        return null;
      }
      return response.productDetails.first.price;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      final completer = _pending.remove(purchase.productID);
      final succeeded =
          purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;

      if (completer != null) {
        if (!completer.isCompleted) completer.complete(succeeded);
      } else if (succeeded) {
        // Bu servisin BAŞLATMADIĞI (bekleyen bir Completer'ı olmayan) bir
        // satın alma — bir önceki oturumdan kalan "yetim" bir işlem (bkz.
        // sınıfın başındaki dokümantasyon).
        _orphanedController.add(purchase.productID);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
