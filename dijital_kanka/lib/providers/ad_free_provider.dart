import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';
import '../services/purchase_service.dart';

/// 2026 yeni özellik — "Zibo ADS" (reklamsız deneyim), Play Console'daki
/// KALICI (managed/non-consumable) `remove_ads_lifetime` ürünü. Coin
/// paketlerinin AKSİNE (tüketilebilir, her satın alımda tekrar), bu TEK
/// SEFERLİK — `InstagramFollowProvider` ile AYNI "tek bir kalıcı bool
/// bayrak" `CloudStateStore` deseni.
///
/// **Cihaz/hesap değişiminde kurtarma:** constructor'da HEMEN
/// `_purchaseService.restorePurchases()` tetiklenir — Play Store bu
/// kullanıcının hesabına bağlı geçmiş satın almayı [PurchaseService.
/// orphanedPurchaseProductIds] stream'i üzerinden "restored" olarak geri
/// oynatır (bkz. `iap_purchase_service.dart`'taki "orphaned purchase"
/// dokümantasyonu — AYNI mekanizma, farklı amaç: orada çökme kurtarma,
/// burada cihaz/hesap değişimi kurtarma). `main.dart`'ta `CoinProvider`'la
/// AYNI [PurchaseService] ÖRNEĞİ paylaşılmalı — aksi halde iki ayrı
/// `purchaseStream` aboneliği aynı satın almayı iki kez `completePurchase`
/// etmeye çalışabilir.
class AdFreeProvider extends ChangeNotifier {
  AdFreeProvider({
    this.uid,
    PurchaseService purchaseService = const MockPurchaseService(),
    FirebaseFirestore? firestore,
  }) : _purchaseService = purchaseService,
       _store = CloudStateStore(
         prefsKey: _prefsKey,
         uid: uid,
         firestore: firestore,
       ) {
    _loadFromPrefs();
    _orphanedSub = _purchaseService.orphanedPurchaseProductIds.listen(
      _onOrphanedPurchase,
    );
    unawaited(_purchaseService.restorePurchases());
  }

  static const _prefsKey = 'adFreeState';

  /// Play Console'daki KALICI (managed) ürün ID'si — `iap_purchase_service.
  /// dart`'taki sabitle BİREBİR eşleşmeli.
  static const productId = 'remove_ads_lifetime';

  final String? uid;
  final PurchaseService _purchaseService;
  final CloudStateStore _store;
  StreamSubscription<String>? _orphanedSub;

  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      _isAdFree = data['isAdFree'] as bool? ?? false;
    }
    _isReady = true;
    notifyListeners();
  }

  /// Play Store'dan (varsa) canlı/yerelleştirilmiş fiyat metnini sorgular —
  /// `CoinProvider.queryLocalizedPrice` ile AYNI gerekçe (KDV/vergi dahil
  /// GERÇEK fiyat, `paywall_screen.dart`'taki sabit `adFreeFallbackPrice`
  /// TAHMİNDEN farklı olabiliyor — gerçek cihazda 159,90 TL yerine 189,90 TL
  /// çıkması TAM BU yüzden, bkz. 2026-09-12 kullanıcı raporu). `null`
  /// dönerse çağıran taraf sabit fiyata düşer.
  Future<String?> queryLocalizedPrice() =>
      _purchaseService.queryAdRemovalLocalizedPrice();

  /// Satın alma akışını başlatır. Başarılıysa reklamsız durumu HEMEN kalıcı
  /// hale getirir ve true döner; kullanıcı vazgeçerse/ödeme başarısız
  /// olursa false döner.
  Future<bool> purchase() async {
    final success = await _purchaseService.purchaseAdRemoval();
    if (success) await _markAdFree();
    return success;
  }

  void _onOrphanedPurchase(String orphanedProductId) {
    if (orphanedProductId != productId) return;
    unawaited(_markAdFree());
  }

  Future<void> _markAdFree() async {
    if (_isAdFree) return;
    _isAdFree = true;
    notifyListeners();
    await _store.save({'isAdFree': true});
  }

  @override
  void dispose() {
    _orphanedSub?.cancel();
    super.dispose();
  }
}
