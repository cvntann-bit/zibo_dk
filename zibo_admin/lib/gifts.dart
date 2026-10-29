import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_log.dart';

/// `notification-scripts/src/grantGift.js`'in panel karşılığı — AYNI belge şekilleri.
/// Zibo'daki karşılıkları: `CoinProvider._save` (coinState), `SubscriptionProvider._save`
/// (subscriptionState), `GamePointsProvider` (gamePointsState.unlimitedPlays).

/// `CoinProvider._maxStoredTransactions` ile AYNI.
const _maxStoredTransactions = 200;

/// "Süresiz" üyelik — grantGift.js ile aynı uzak tarih (rules: ISO metin, ≤ 40 karakter).
const kFarFutureExpiry = '2099-12-31T00:00:00.000Z';

const kProductByTier = {'pro': 'zibo_pro', 'proplus': 'zibo_proplus'};

DocumentReference<Map<String, dynamic>> _state(String uid, String name) =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('state').doc(name);

class GiftException implements Exception {
  const GiftException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// ZC ekler. [grantId] diyalog açılırken BİR KEZ üretilir — aynı id ile ikinci deneme
/// (çift dokunma, ağ tekrarı) ZC'yi tekrar eklemez.
Future<void> grantCoins({
  required String uid,
  required int coins,
  required String grantId,
  String? note,
}) async {
  final db = FirebaseFirestore.instance;
  final coinRef = _state(uid, 'coinState');
  final grantRef = db.collection('users').doc(uid).collection('giftGrants').doc(grantId);
  await db.runTransaction((tx) async {
    final grantSnap = await tx.get(grantRef);
    if (grantSnap.exists) throw const GiftException('Bu hediye zaten uygulanmış.');
    final snap = await tx.get(coinRef);
    // Bulutta coinState yoksa Zibo açılışta YEREL veriyi göç ettirir; buraya yazmak o
    // göçü engeller ve kullanıcının yerel bakiyesini sildirir → bilerek reddediliyor.
    if (!snap.exists) throw const GiftException('Bu kullanıcının bulutta coin kaydı yok.');
    final data = snap.data()!;
    final balance = (data['balance'] as num? ?? 0).toInt();
    final totalEarned = (data['totalEarned'] as num? ?? 0).toInt();
    final transactions = [
      {
        'type': 'earn',
        'amount': coins,
        'reason': 'Hediye',
        'timestamp': DateTime.now().toIso8601String(),
      },
      ...(data['transactions'] as List? ?? const []),
    ].take(_maxStoredTransactions).toList();
    tx.update(coinRef, {
      'balance': balance + coins,
      'totalEarned': totalEarned + coins,
      'transactions': transactions,
    });
    tx.set(grantRef, {'coins': coins, 'grantedAt': FieldValue.serverTimestamp(), 'by': 'panel'});
    tx.set(
      newAdminLogRef(),
      adminLogEntry(
        action: 'ZC hediye',
        target: 'users/$uid',
        before: {'balance': balance},
        after: {'balance': balance + coins},
        note: note,
      ),
    );
  });
}

/// Pro / Pro+ verir. [expiryIso] `null` değil — süreli ya da [kFarFutureExpiry].
Future<void> grantSubscription({
  required String uid,
  required String tier,
  required String expiryIso,
  required Map<String, Object?> before,
  String? note,
}) async {
  final after = {
    'subscriptionTier': tier,
    'subscriptionExpiryDate': expiryIso,
    'subscriptionProductId': kProductByTier[tier],
  };
  final batch = FirebaseFirestore.instance.batch();
  batch.set(_state(uid, 'subscriptionState'), after, SetOptions(merge: true));
  addAdminLog(batch, action: 'Üyelik hediye', target: 'users/$uid', before: before, after: after, note: note);
  await batch.commit();
}

/// Oyun Salonu günlük hak sınırını kaldırır/geri getirir (Zibo 1.14.1+ okur).
Future<void> setUnlimitedPlays({required String uid, required bool value, required bool before}) async {
  final batch = FirebaseFirestore.instance.batch();
  batch.set(_state(uid, 'gamePointsState'), {'unlimitedPlays': value}, SetOptions(merge: true));
  addAdminLog(
    batch,
    action: 'Sınırsız oyun',
    target: 'users/$uid',
    before: {'unlimitedPlays': before},
    after: {'unlimitedPlays': value},
  );
  await batch.commit();
}
