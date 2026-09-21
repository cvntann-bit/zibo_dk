import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/subscription_products.dart';
import '../models/subscription_offer.dart';
import '../models/subscription_tier.dart';
import '../services/cloud_state_store.dart';
import '../services/purchase_service.dart';

/// Zibo Pro / Zibo Pro+ abonelik durumunun tek kaynağı (single source of
/// truth). `AdFreeProvider` ile AYNI temel desen (constructor'da
/// `restorePurchases()` tetikleme + orphaned-purchase dinleme +
/// `CloudStateStore`) — FARKI: bu KALICI değil, bir SÜRESİ var.
///
/// **Süre (expiry) takibi — "kayan pencere" (rolling window):** Play
/// Billing'in istemci tarafı satın alma nesnesi kesin bitiş tarihini
/// VERMEZ (yalnızca Play Developer API'de var, sunucu gerektirir — bkz.
/// `docs/decisions/012-subscription-tier-tracking.md`). Bunun yerine her
/// başarılı satın alma/`restorePurchases` onayında [_rollingWindow] kadar
/// ileri itilir. Uygulama düzenli açıldığı sürece bu pencere sürekli
/// tazelenir; Play artık aboneliği onaylamazsa VEYA kullanıcı pencere
/// kadar uygulamayı hiç açmazsa durum otomatik "free"ye düşer (bkz. [tier]
/// getter'ı).
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({
    this.uid,
    PurchaseService purchaseService = const MockPurchaseService(),
    FirebaseFirestore? firestore,
    DateTime Function() now = DateTime.now,
  }) : _purchaseService = purchaseService,
       _now = now,
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

  static const _prefsKey = 'subscriptionState';

  /// Bkz. sınıf dokümantasyonundaki "kayan pencere" notu — her onaydan
  /// sonra bitiş tarihi bu kadar ileri itilir. Aylık VE yıllık planların
  /// İKİSİ için de güvenli (uygulama en az bu sıklıkla açılırsa asla
  /// yanlışlıkla "free"ye düşmez).
  static const _rollingWindow = Duration(days: 35);

  final String? uid;
  final PurchaseService _purchaseService;
  final CloudStateStore _store;
  final DateTime Function() _now;
  StreamSubscription<String>? _orphanedSub;

  SubscriptionTier _storedTier = SubscriptionTier.free;
  DateTime? _expiryDate;
  String? _productId;

  /// Süresi geçmişse (bkz. sınıf dokümantasyonu) otomatik `free` sayılır —
  /// çağıran taraf HER ZAMAN bunu kullanmalı, [_storedTier]'ı DOĞRUDAN
  /// DEĞİL (ham kalıcı değer, süre kontrolü İÇERMEZ).
  SubscriptionTier get tier {
    if (_storedTier == SubscriptionTier.free) return SubscriptionTier.free;
    final expiry = _expiryDate;
    if (expiry == null || _now().isAfter(expiry)) return SubscriptionTier.free;
    return _storedTier;
  }

  bool get isPro =>
      tier == SubscriptionTier.pro || tier == SubscriptionTier.proPlus;
  bool get isProPlus => tier == SubscriptionTier.proPlus;

  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      try {
        _storedTier = SubscriptionTierJson.fromJson(
          data['subscriptionTier'] as String? ?? 'free',
        );
        final expiryRaw = data['subscriptionExpiryDate'] as String?;
        _expiryDate = expiryRaw == null ? null : DateTime.parse(expiryRaw);
        _productId = data['subscriptionProductId'] as String?;
      } catch (_) {
        // Bozuk/eski formatlı kayıtlı veri — sessizce free'ye düş, uygulamanın
        // çökmesindense veri kaybı tercih edilir (diğer TÜM provider'larla
        // AYNI kural).
        _storedTier = SubscriptionTier.free;
        _expiryDate = null;
        _productId = null;
      }
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() => _store.save({
    'subscriptionTier': _storedTier.toJson(),
    'subscriptionExpiryDate': _expiryDate?.toIso8601String(),
    'subscriptionProductId': _productId,
  });

  /// Play Store'dan (varsa) [offer]'ın canlı/yerelleştirilmiş fiyat metnini
  /// sorgular — `null` dönerse çağıran taraf sabit/görsel bir fiyata düşer.
  Future<String?> queryLocalizedPrice(SubscriptionOffer offer) =>
      _purchaseService.querySubscriptionLocalizedPrice(offer);

  /// [offer]'ın satın alma akışını başlatır. Başarılıysa katmanı HEMEN
  /// günceller ve true döner; kullanıcı vazgeçerse/ödeme başarısız olursa
  /// false döner.
  Future<bool> purchase(SubscriptionOffer offer) async {
    final success = await _purchaseService.purchaseSubscription(offer);
    if (success) await _confirmActive(offer.tier, offer.productId);
    return success;
  }

  /// Kullanıcının hâlihazırda AKTİF bir aboneliği ([_productId], ör.
  /// `zibo_pro`) varken [offer]'a (ör. `zibo_proplus`) YÜKSELTİR —
  /// [purchase]'ın aksine sıfırdan yeni bir abonelik BAŞLATMAZ, Play
  /// Billing'in "abonelik değiştirme" akışını kullanır (bkz.
  /// `PurchaseService.upgradeSubscription`). Aktif bir abonelik yoksa
  /// (`_productId == null`) `false` döner — çağıran taraf (paywall) zaten
  /// bu butonu yalnızca `isPro` iken gösteriyor olmalı.
  Future<bool> upgradeToProPlus(SubscriptionOffer offer) async {
    final oldProductId = _productId;
    if (oldProductId == null) return false;
    final success = await _purchaseService.upgradeSubscription(
      offer,
      oldProductId: oldProductId,
    );
    if (success) await _confirmActive(offer.tier, offer.productId);
    return success;
  }

  /// [PurchaseService.orphanedPurchaseProductIds]'ten gelen, bir önceki
  /// oturumdan kalan VEYA `restorePurchases()`'ın geri oynattığı bir
  /// abonelik — `productId` yalnızca ÜRÜN kimliğini verir (`zibo_pro`/
  /// `zibo_proplus`), hangi temel plandan geldiği ÖNEMLİ DEĞİL (katman
  /// zaten ürün kimliğinden belli).
  void _onOrphanedPurchase(String productId) {
    SubscriptionOffer? matched;
    for (final candidate in subscriptionOffers) {
      if (candidate.productId == productId) {
        matched = candidate;
        break;
      }
    }
    if (matched == null) return;
    unawaited(_confirmActive(matched.tier, matched.productId));
  }

  Future<void> _confirmActive(SubscriptionTier tier, String productId) async {
    _storedTier = tier;
    _productId = productId;
    _expiryDate = _now().add(_rollingWindow);
    notifyListeners();
    await _save();
  }

  /// **Yalnızca debug panelinden çağrılır** (bkz. `settings_screen.dart`
  /// `_SubscriptionDebugPanel`, `kDebugMode` ile korunuyor) — gerçek satın
  /// alma yapmadan UI'ı manuel test edebilmek için.
  Future<void> debugSetTier(SubscriptionTier tier) async {
    _storedTier = tier;
    _expiryDate = tier == SubscriptionTier.free
        ? null
        : _now().add(_rollingWindow);
    _productId = switch (tier) {
      SubscriptionTier.free => null,
      SubscriptionTier.pro => 'zibo_pro',
      SubscriptionTier.proPlus => 'zibo_proplus',
    };
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    _orphanedSub?.cancel();
    super.dispose();
  }
}
