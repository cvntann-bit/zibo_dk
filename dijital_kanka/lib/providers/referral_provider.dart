import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// [ReferralProvider.redeemCode]'un dönebileceği sonuçlar — `ReferralScreen`
/// bunlara göre doğru mesajı gösterir.
enum ReferralRedeemResult {
  /// Kayıt gönderildi — kredi ANINDA DEĞİL, `notification-scripts/src/
  /// processReferralRewards.js`'in bir SONRAKİ çalıştırmasında işlenir (bkz.
  /// o betiğin dokümantasyonu).
  success,

  /// Girilen kod kullanıcının KENDİ davet kodu (kendi uid'i).
  selfCode,

  /// Boş/anlamsız bir giriş.
  invalidCode,

  /// Kullanıcı DAHA ÖNCE (başarıyla) bir kod kullanmış — bir kullanıcı en
  /// fazla BİR kez davet kodu kullanabilir.
  alreadyRedeemed,

  /// `uid` yok (Firebase kullanılamıyor) — referral özelliği tamamen devre
  /// dışı, bkz. sınıf dokümantasyonu.
  unavailable,

  /// Firestore'a ulaşılamadı (ağ yok/hata).
  networkError,
}

/// 2026 yeni özellik — Davet Et (referral) sistemi. Kullanıcı isteği: her
/// kullanıcıya özel bir davet kodu (Firebase uid'ine bağlı), davet edilen
/// kişi kodu girip kullanınca HEM davet eden HEM davet edilen coin kazansın.
///
/// **Mimari — "basit metin kodu" (kullanıcının onayladığı kapsam, deep-link/
/// Play Install Referrer KAPSAM DIŞI):** davet kodu = kullanıcının kendi
/// Firebase uid'i — ayrı bir kod üretme/çakışma yönetimi/lookup tablosu
/// GEREKMİYOR. `ReferralScreen` bu kodu `share_plus` ile düz metin olarak
/// paylaşır (bkz. `ShareService.shareText`), davet edilen kişi Profil'deki
/// aynı ekrandan kodu ELLE girer.
///
/// **Ödül kredisi neden ANINDA DEĞİL — mevcut Firestore rules'un doğal bir
/// sonucu:** İKİ AYRI kullanıcının (davet eden + davet edilen) coin
/// bakiyesini AYNI ANDA değiştirmek gerekiyor, ama `firestore.rules`
/// yalnızca `request.auth.uid == userId` olan kullanıcının KENDİ `coinState`
/// belgesine yazmasına izin veriyor (bkz. "Coin Ekonomisi Güvenliği"
/// bölümü) — davet edilenin cihazı davet edenin bakiyesine DOĞRUDAN
/// yazamaz. Bu yüzden [redeemCode] yalnızca KENDİ `referralState` belgesini
/// (bu sınıfın [CloudStateStore]'u, "zaten kullanıldı" bayrağı olarak da
/// işlev görür) VE yeni, dar kapsamlı bir `referralRedemptions` koleksiyon
/// kaydını (create-only, bkz. `firestore.rules`) yazar — asıl coin kredisi
/// `notification-scripts/src/processReferralRewards.js`'in (Admin SDK ile,
/// rules'u atlayarak, GÜVENİLİR taraf olarak) bir SONRAKİ çalıştırmasında
/// gerçekleşir. Bu, projenin genelinde zaten kabul edilmiş "hassas coin
/// mutasyonları GitHub Actions + Admin SDK'ya taşınsın" felsefesiyle
/// TUTARLI (bkz. Push Bildirimleri/Coin Ekonomisi Güvenliği bölümleri).
///
/// **Bilinçli olarak YAPILMAYAN bir client-side kontrol:** [redeemCode]
/// girilen kodun GERÇEKTEN var olan bir kullanıcıya ait olup olmadığını
/// DOĞRULAMAZ — `firestore.rules`'taki kök `users/{uid}` dokümanı
/// yalnızca SAHİBİ tarafından okunabiliyor (`isOwner()`), yani bir
/// istemcinin BAŞKA bir uid'in var olup olmadığını sorgulamasının GÜVENLİ
/// bir yolu yok (bu, mevcut kuralı gevşetmeden çözülemez, bu turda
/// KAPSAM DIŞI bırakıldı). Geçersiz/uydurma bir kod girilirse istek YİNE
/// DE gönderilir (kullanıcıya "gönderildi" denir) — asıl doğrulama
/// (`referrerUid`nin GERÇEKTEN var olan bir kullanıcı olup olmadığı)
/// backend betiğinde yapılır, geçersizse sessizce KREDİLENMEZ.
class ReferralProvider extends ChangeNotifier {
  ReferralProvider({this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance),
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid, firestore: firestore) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'referralState';

  /// Kullanıcının kendi Firebase uid'i — AYNI ZAMANDA kendi davet kodu
  /// (bkz. sınıf dokümantasyonu). `null` ise (Firebase kullanılamıyor)
  /// özellik tamamen devre dışı — [referralCode] `null` döner,
  /// [redeemCode] her zaman [ReferralRedeemResult.unavailable] döner.
  final String? uid;

  final FirebaseFirestore? _firestore;
  final CloudStateStore _store;

  bool _hasRedeemed = false;
  String? _redeemedFromUid;
  bool _isRedeeming = false;
  int _successfulReferralCount = 0;

  /// Kullanıcının PAYLAŞACAĞI davet kodu — kendi uid'i.
  String? get referralCode => uid;

  bool get hasRedeemed => _hasRedeemed;
  String? get redeemedFromUid => _redeemedFromUid;

  /// Kullanıcının davet EDEREK (yani kendi kodunu paylaşıp) kaç arkadaşını
  /// BAŞARIYLA kaydettirdiği — bkz. `notification-scripts/src/
  /// processReferralRewards.js`'teki `creditReferralReward(uid, {isReferrer:
  /// true})` notu. Sosyal/Paylaşım Rozetleri'nin ("Elçi"/"Topluluk
  /// Kurucusu") kaynağı. **ANINDA GÜNCELLENMEZ** — [redeemCode] gibi
  /// istemci tarafı bir eylemin SONUCU DEĞİL, sunucu tarafı betiğin (saatlik
  /// GitHub Actions cron'u) bir SONRAKİ çalıştırmasında Firestore'a yazılır;
  /// istemci bunu ancak [refresh] çağrıldığında (bkz. `RootScreen`'in
  /// `resumed` yaşam döngüsü kancası) görür — `DailyRewardsProvider.
  /// reconcileForToday()` ile AYNI "reconcile-on-resume" felsefesi.
  int get successfulReferralCount => _successfulReferralCount;

  /// [ReferralScreen]'in kod gönderirken küçük bir yükleniyor göstergesi
  /// için — diğer provider'lardaki `isLinking`/`isRedeeming` deseniyle aynı.
  bool get isRedeeming => _isRedeeming;

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data == null) return;
    _hasRedeemed = data['redeemed'] as bool? ?? false;
    _redeemedFromUid = data['referrerUid'] as String?;
    _successfulReferralCount = data['successfulReferralCount'] as int? ?? 0;
    notifyListeners();
  }

  /// [successfulReferralCount]'u Firestore'dan YENİDEN okur — sunucu tarafı
  /// betiğin (`processReferralRewards.js`) bir SONRAKİ çalıştırmasında
  /// sessizce artırdığı sayacı istemcinin görebilmesinin TEK yolu, çünkü
  /// `CloudStateStore.load()` [uid] varken HER ZAMAN önce Firestore'u
  /// dener (bkz. o sınıfın dokümantasyonu) — bu yüzden `_loadFromPrefs()`'i
  /// yeniden çağırmak yeterli, ayrı bir "zorla Firestore'dan oku" yolu
  /// GEREKMEDİ. `BadgeCoordinator` bu provider'ı zaten dinlediği için,
  /// sayaç GERÇEKTEN değiştiyse [notifyListeners] Sosyal/Paylaşım
  /// Rozetleri'nin otomatik reconcile edilmesini tetikler.
  Future<void> refresh() => _loadFromPrefs();

  /// [enteredCode]'u (bir başkasının davet kodu, yani onun uid'i) redeem
  /// etmeye çalışır. Bkz. sınıf dokümantasyonu — başarı, ANINDA coin
  /// kredisi DEĞİL, yalnızca "istek gönderildi" anlamına gelir.
  Future<ReferralRedeemResult> redeemCode(String enteredCode) async {
    if (uid == null || _firestore == null) {
      return ReferralRedeemResult.unavailable;
    }
    if (_hasRedeemed) return ReferralRedeemResult.alreadyRedeemed;
    final code = enteredCode.trim();
    if (code.isEmpty) return ReferralRedeemResult.invalidCode;
    if (code == uid) return ReferralRedeemResult.selfCode;

    _isRedeeming = true;
    notifyListeners();
    try {
      await _firestore.collection('referralRedemptions').add({
        'referrerUid': code,
        'refereeUid': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _hasRedeemed = true;
      _redeemedFromUid = code;
      // `_successfulReferralCount` de AÇIKÇA dahil ediliyor —
      // `CloudStateStore.save()` TAM bir `.set()` (merge DEĞİL), bu satır
      // olmadan bu kullanıcı AYRICA bir davet EDEN'se (yani sunucu tarafı
      // betiğin daha önce artırdığı bir sayacı varsa) bu çağrı o sayacı
      // SESSİZCE SIFIRA döndürürdü.
      await _store.save({
        'redeemed': true,
        'referrerUid': code,
        'successfulReferralCount': _successfulReferralCount,
      });
      return ReferralRedeemResult.success;
    } catch (_) {
      return ReferralRedeemResult.networkError;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }
}
