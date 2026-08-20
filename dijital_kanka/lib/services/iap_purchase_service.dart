import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/coin_package.dart';
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

  @override
  Stream<String> get orphanedPurchaseProductIds => _orphanedController.stream;

  void dispose() {
    _subscription?.cancel();
    _orphanedController.close();
  }

  @override
  Future<bool> purchaseCoinPackage(CoinPackage package) async {
    // Aynı paket için ZATEN bekleyen bir satın alma varsa (ör. kullanıcı
    // butona iki kez hızlıca bastı) ikinci bir `buyConsumable` çağrısı
    // BAŞLATMA — aynı Completer'ın sonucunu paylaş.
    final existing = _pending[package.id];
    if (existing != null) return existing.future;

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

      return await completer.future;
    } catch (_) {
      _pending.remove(package.id);
      return false;
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
