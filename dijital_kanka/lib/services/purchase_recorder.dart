import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_service.dart';

/// [PurchaseService.purchaseReceipts]'ten gelen makbuzları Firestore
/// `purchaseRecords/{sha256(token)}` belgesine yazar — saatlik iş
/// (`notification-scripts/src/verifyPurchases.js`) bunları Google'a sorar.
///
/// **Ödeme akışına DOKUNMAZ:** teslimat bu kayda bağlı değil, burada bir hata
/// olursa kullanıcı ürününü yine alır (kayıt sessizce düşer). Bkz.
/// `docs/purchase_verification.md`.
///
/// Belge kimliği token'ın özeti olduğu için aynı makbuz ikinci kez (başka
/// bir uid'den de) oluşturulamaz: var olan belgeye yazım kural gereği
/// reddedilir (`firestore.rules`). `restorePurchases` abonelikleri her
/// açılışta tekrar oynattığından, yazılanların özeti yerelde de tutulur.
class PurchaseRecorder {
  PurchaseRecorder({
    required this.uid,
    required PurchaseService purchaseService,
    FirebaseFirestore? firestore,
  }) : _firestore =
           firestore ?? (uid == null ? null : FirebaseFirestore.instance) {
    _subscription = purchaseService.purchaseReceipts.listen(record);
  }

  static const _prefsKey = 'recordedPurchaseHashes';

  /// Yerelde tutulan en fazla özet sayısı — yalnızca tekrar yazımı önler,
  /// asıl koruma kuraldaki "belge varsa yazılamaz".
  static const _maxStoredHashes = 50;

  final String? uid;
  final FirebaseFirestore? _firestore;
  late final StreamSubscription<PurchaseReceipt> _subscription;
  final Set<String> _inFlight = {};

  static String hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  Future<void> record(PurchaseReceipt receipt) async {
    final firestore = _firestore;
    if (firestore == null || uid == null || receipt.purchaseToken.isEmpty) {
      return;
    }
    final hash = hashToken(receipt.purchaseToken);
    if (!_inFlight.add(hash)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final recorded = prefs.getStringList(_prefsKey) ?? const <String>[];
      if (recorded.contains(hash)) return;
      try {
        await firestore.collection('purchaseRecords').doc(hash).set({
          'uid': uid,
          'productId': receipt.productId,
          'purchaseToken': receipt.purchaseToken,
          'orderId': receipt.orderId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (error) {
        // Belge zaten var (önceden yazılmış ya da aynı Play hesabı başka
        // uid'de) — tekrar denemenin anlamı yok; diğer hatalarda bir
        // sonraki açılış yeniden dener.
        if (error.code != 'permission-denied') return;
      }
      final updated = [hash, ...recorded].take(_maxStoredHashes).toList();
      await prefs.setStringList(_prefsKey, updated);
    } catch (_) {
      // Kayıt hiçbir koşulda satın almayı etkilememeli.
    } finally {
      _inFlight.remove(hash);
    }
  }

  void dispose() => _subscription.cancel();
}
