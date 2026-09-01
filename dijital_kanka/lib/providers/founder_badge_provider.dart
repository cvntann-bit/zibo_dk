import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/founder_badge.dart';

/// Kurucu Üye rozetinin toplam kontenjanı — Google hesabına bağlanan İLK
/// bu kadar kullanıcı rozeti kazanabilir (bkz. CLAUDE.md "Kurucu Üye
/// Rozeti" bölümü).
const int founderBadgeCapacity = 500;

const _statusCollection = 'founderBadgeStatus';
const _statusDocId = 'status';

/// 2026 güncellemesi — Kurucu Üye rozeti artık "ilk 500 KAYIT OLAN"
/// kullanıcıya DEĞİL, "Google hesabına bağlanan İLK 500 kullanıcı"ya
/// veriliyor (kullanıcının açık isteği), VE bu artık bir kerelik, elle
/// tetiklenen bir Admin SDK betiğiyle DEĞİL — canlı, uygulama içi bir
/// SAYAÇLA çalışıyor (bkz. altta [claimIfEligible]).
///
/// **Neden Cloud Functions'a GEREK KALMADAN atomik/güvenli — Firestore'un
/// KENDİ transaction mekanizması:** `founderBadgeStatus/status` dokümanının
/// TEK bir `count` alanı var. [claimIfEligible] bunu bir Firestore
/// transaction'ı İÇİNDE okuyup `count < founderBadgeCapacity` ise `count+1`
/// yazıyor — Firestore SDK'sı aynı dokümana AYNI ANDA gelen iki
/// transaction'ı KENDİLİĞİNDEN serileştirip (optimistic concurrency,
/// çakışan taraf otomatik retry edilir) ikisinin de AYNI ANDA `499`'u
/// okuyup ikisinin de `500`'e yazmasını engelliyor — bu yüzden Cloud
/// Functions (Blaze plan) OLMADAN bile "ilk N kullanıcı" garantisi
/// atomik şekilde sağlanabiliyor. `firestore.rules`'daki
/// `founderBadgeStatus/status` kuralı bunu İKİNCİ bir savunma katmanı
/// olarak da zorunlu kılıyor (`count`'un yalnızca +1 artabildiği VE
/// `count < 500` iken yazılabildiği rules seviyesinde de doğrulanıyor).
///
/// **Kabul edilen sınırlama — Coin Ekonomisi Güvenliği bölümündeki AYNI
/// istemci-taraflı-güven riski:** bu TAM bir sunucu yetkisi DEĞİL, bir
/// modifiye APK teorik olarak GERÇEKTEN Google'a bağlanmadan bu
/// transaction'ı doğrudan (bir REST çağrısıyla) tetikleyip bir slot
/// "yakabilir" — ama bunun tek sonucu havuzdan bir slotun boşa gitmesi,
/// gerçek bir coin/ödeme kaybı DEĞİL; projenin genelinde zaten kabul
/// edilmiş risk seviyesiyle TUTARLI (bkz. CLAUDE.md).
///
/// **`founderBadgeStatus/status` dokümanı istemci tarafından ASLA
/// OLUŞTURULAMAZ** (`firestore.rules`'da `allow create: if false`) —
/// canlıya alınmadan ÖNCE `notification-scripts/src/
/// initFounderBadgeCounter.js` (bir kerelik Admin SDK betiği) ile TEK
/// SEFER seed edilmesi gerekiyor. Doküman henüz yoksa/okunamıyorsa
/// [isLoaded] hep `false` kalır, [FounderBadgePromoCard] hiçbir zaman
/// görünmez — sessiz/güvenli bir "henüz hazır değil" durumu.
class FounderBadgeProvider extends ChangeNotifier {
  FounderBadgeProvider({String? uid, FirebaseFirestore? firestore})
    : _uid = uid,
      _firestore =
          firestore ?? (uid == null ? null : FirebaseFirestore.instance) {
    if (_uid != null && _firestore != null) {
      _listen();
    }
  }

  final String? _uid;
  final FirebaseFirestore? _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// `null` = sayaç henüz yüklenmedi (uid yok, ağ yok, veya doküman henüz
  /// hiç seed edilmedi) — bu durumda UI hiçbir şey GÖSTERMEMELİ, ne "0/500"
  /// ne "500/500" gibi yanıltıcı bir ilk kare.
  int? _claimedCount;
  bool _isClaiming = false;

  bool get isLoaded => _claimedCount != null;
  int get claimedCount => _claimedCount ?? 0;
  int get remainingSlots =>
      _claimedCount == null
          ? founderBadgeCapacity
          : (founderBadgeCapacity - _claimedCount!).clamp(
            0,
            founderBadgeCapacity,
          );
  bool get isSoldOut => _claimedCount != null && _claimedCount! >= founderBadgeCapacity;

  /// [claimIfEligible] devam ederken `true` — UI bu sürede ikinci bir
  /// çağrıyı tetiklemekten kaçınmak için kullanabilir (bugünkü tek çağıran,
  /// [handleGoogleLinkTap], zaten kendi `try/await` akışıyla doğal olarak
  /// seri çalışıyor, ama alan yine de dışa açıldı).
  bool get isClaiming => _isClaiming;

  void _listen() {
    try {
      _sub = _firestore!
          .collection(_statusCollection)
          .doc(_statusDocId)
          .snapshots()
          .listen((snapshot) {
            final count = snapshot.data()?['count'];
            if (count is int) {
              _claimedCount = count;
              notifyListeners();
            }
          }, onError: (_) {});
    } catch (_) {
      // Firestore'a hiç ulaşılamıyorsa (ağ yok, test ortamı vb.) sessizce
      // "henüz yüklenmedi" durumunda kal — bkz. sınıf dokümantasyonu.
    }
  }

  /// Google hesabına YENİ bağlanan bir kullanıcı için çağrılır (bkz.
  /// `utils/google_link_action.dart`'taki `handleGoogleLinkTap`). Rozeti
  /// KAZANDIYSA `true`, aksi halde (uid yok / sayaç henüz seed edilmemiş /
  /// kontenjan doldu / kullanıcı zaten sahip — tekrar bağlama denemesi vb.)
  /// sessizce `false` döner — hiçbir durumda hata FIRLATMAZ.
  Future<bool> claimIfEligible() async {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) return false;

    _isClaiming = true;
    notifyListeners();
    try {
      return await firestore.runTransaction<bool>((tx) async {
        final statusRef = firestore
            .collection(_statusCollection)
            .doc(_statusDocId);
        final costumeRef = firestore
            .collection('users')
            .doc(uid)
            .collection('state')
            .doc('costumeState');

        final statusSnap = await tx.get(statusRef);
        final costumeSnap = await tx.get(costumeRef);

        // Sayaç henüz seed EDİLMEMİŞ — bkz. sınıf dokümantasyonu, bu
        // durumda özellik sessizce devre dışı kalır.
        if (!statusSnap.exists) return false;

        final count = statusSnap.data()?['count'] as int? ?? 0;
        if (count >= founderBadgeCapacity) return false;

        final ownedIds = List<String>.from(
          (costumeSnap.data()?['ownedIds'] as List?) ?? const [],
        );
        if (ownedIds.contains(founderBadgeCostumeId)) return false;

        tx.update(statusRef, {'count': count + 1});
        if (costumeSnap.exists) {
          tx.update(costumeRef, {
            'ownedIds': FieldValue.arrayUnion([founderBadgeCostumeId]),
          });
        } else {
          // Kullanıcının henüz hiç kostüm dokümanı yok (Mağaza'ya hiç
          // girmemiş) — `CostumeProvider._save()`'in ürettiği ŞEKLE
          // birebir uyumlu, geçerli bir başlangıç dokümanı oluştur.
          tx.set(costumeRef, {
            'ownedIds': [founderBadgeCostumeId],
            'equippedId': null,
          });
        }
        return true;
      });
    } catch (_) {
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
