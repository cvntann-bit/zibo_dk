import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/coin_packages.dart';
import '../data/wheel_prizes.dart';
import '../models/coin_economy.dart';
import '../models/coin_package.dart';
import '../models/coin_transaction.dart';
import '../models/wheel_prize.dart';
import '../services/ad_service.dart';
import '../services/cloud_state_store.dart';
import '../services/purchase_service.dart';
import '../services/sound_effects_service.dart';
import '../utils/zibo_event_signal.dart';

/// Zibo Coin bakiyesini ve işlem geçmişini tutan tek kaynak (single source
/// of truth). Tüm kazanma/harcama mekanikleri burada metod olarak
/// tanımlanır; ekranlar doğrudan bakiyeyi değiştirmez, yalnızca bu
/// metodları çağırır. `CloudStateStore` ile kalıcı — [uid] varsa Firestore'a
/// (`users/{uid}/state/coinState`) da yazılır, `SharedPreferences` HER ZAMAN
/// yerel yedek olarak kalır (bkz. `CloudStateStore` dokümantasyonu). Bakiye +
/// işlem geçmişi tek bir belge/anahtar altında; geçmiş sınırsız büyümesin
/// diye yalnızca en yeni [_maxStoredTransactions] işlem saklanır.
class CoinProvider extends ChangeNotifier {
  CoinProvider({
    AdService adService = const MockAdService(),
    PurchaseService purchaseService = const MockPurchaseService(),
    SoundEffectsService? soundEffectsService,
    Random? random,
    String? uid,
    DateTime Function() now = DateTime.now,
    bool Function() isSoundEnabled = _alwaysTrue,
    bool Function() isAdFree = _alwaysFalse,
    bool Function() isPro = _alwaysFalse,
    bool Function() isProPlus = _alwaysFalse,
    void Function(int amount)? onXpEarned,
  }) : _adService = adService,
       _purchaseService = purchaseService,
       _soundEffectsService = soundEffectsService ?? const FakeSoundEffectsService(),
       _random = random ?? Random(),
       _now = now,
       _isSoundEnabled = isSoundEnabled,
       _isAdFree = isAdFree,
       _isPro = isPro,
       _isProPlus = isProPlus,
       _onXpEarned = onXpEarned ?? _noopXpEarned,
       _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
    _orphanedPurchaseSub = _purchaseService.orphanedPurchaseProductIds.listen(
      _onOrphanedPurchase,
    );
  }

  static bool _alwaysTrue() => true;
  static bool _alwaysFalse() => false;
  static void _noopXpEarned(int amount) {}

  static const _prefsKey = 'coinState';
  static const _maxStoredTransactions = 200;

  /// Mağaza'nın "Ücretsiz" kartındaki reklam karşılığı günlük coin kazanma
  /// hakkı (bkz. [remainingAdWatchesToday]).
  static const int maxDailyAdWatches = 2;

  final AdService _adService;
  final PurchaseService _purchaseService;
  final SoundEffectsService _soundEffectsService;
  final CloudStateStore _store;

  /// [PurchaseService.orphanedPurchaseProductIds]'i dinler — bkz.
  /// [_onOrphanedPurchase].
  late final StreamSubscription<String> _orphanedPurchaseSub;

  /// Ses efektlerinin şu an açık olup olmadığı — `main.dart`'ta
  /// `SoundEffectsProvider.enabled`'a bağlanır (`_now`'ın `TrustedTimeProvider`
  /// ile AYNI enjekte edilebilir callback deseni). `CoinProvider`'ın kendisi
  /// bir widget olmadığı için `BuildContext`/`Provider.of` KULLANAMIYOR, bu
  /// yüzden `HomeScreen`'in yaptığı gibi doğrudan `context.read<...>()`
  /// çağıramıyor.
  final bool Function() _isSoundEnabled;

  /// 2026 yeni özellik — "Zibo ADS" (reklamsız deneyim, bkz.
  /// `AdFreeProvider`). `_isSoundEnabled` ile AYNI enjekte edilebilir
  /// callback deseni — `main.dart`'ta `AdFreeProvider.isAdFree`'ye bağlanır.
  /// [showInterstitialAd] TEK giriş noktası olduğu için (bkz. HomeScreen/
  /// DailyRewardsScreen/GoalTrackingScreen'deki ÜÇ çağrı sitesi) kontrolü
  /// BURADA yapmak, her çağrı sitesine ayrı ayrı eklemek yerine, YENİ bir
  /// interstitial çağrısının bu kontrolü unutma riskini ORTADAN KALDIRIYOR.
  final bool Function() _isAdFree;

  /// **Faz 3 (2026-09-22) — Zibo Pro/Pro+ perk "A1: reklamsız deneyim".**
  /// `_isAdFree`/`_isSoundEnabled` ile AYNI enjekte edilebilir callback
  /// deseni — `main.dart`'ta `SubscriptionProvider.isPro`'ya bağlanır
  /// (Pro VE Pro+ ikisi de `true`, bkz. `SubscriptionProvider.isPro`'nun
  /// kendi tanımı). Yalnızca [showInterstitialAd]'ı etkiler — ödüllü
  /// (rewarded) reklamlar ([earnAdWatch]/[watchAdAndSpinWheel]) kullanıcının
  /// KENDİ isteğiyle izlediği reklamlar olduğu için BİLEREK bu kontrolün
  /// DIŞINDA, `_isAdFree` ile AYNI gerekçe.
  final bool Function() _isPro;

  /// **Faz 3 (2026-09-22) — Zibo Pro/Pro+ perk "B1: check-in coin
  /// çarpanı".** `_isPro` ile AYNI enjekte edilebilir callback deseni —
  /// `main.dart`'ta `SubscriptionProvider.isProPlus`'a bağlanır. Yalnızca
  /// Pro+ kullanıcıları ayırt etmek için gerekli (`_isPro` Pro VE Pro+
  /// ikisinde de `true` döner) — bkz. [earnDailyLoginReward].
  final bool Function() _isProPlus;

  /// 2026 yeni özellik — Level/XP Sistemi. `main.dart`'ta
  /// `XpProvider.addXp`'ye bağlanır (`_isSoundEnabled` ile AYNI enjekte
  /// edilebilir callback deseni — `CoinProvider` bir widget OLMADIĞI için
  /// `context.read<XpProvider>()`'ı doğrudan çağıramıyor). `_earn()`'ün
  /// TÜM çağıranları (satın alma HARİÇ, bkz. `awardXp` parametresi)
  /// otomatik olarak kazanılan ZC kadar XP verir.
  final void Function(int amount) _onXpEarned;

  /// Şans Çarkı'nın ağırlıklı ödül seçimi için — testte sabit/kontrollü bir
  /// sonuç enjekte edebilmek amacıyla constructor'dan verilebilir.
  final Random _random;

  /// Günlük reklam haklarının (çark çevirme/ekstra coin) hangi takvim
  /// gününe göre sıfırlanacağını belirler — `GoalsProvider`/`WaterProvider`
  /// ile AYNI desen: cihazın DOĞRUDAN saatine değil, `TrustedTimeProvider.
  /// now()`'a bağlı (main.dart'ta enjekte edilir) — kullanıcı telefonun
  /// tarihini ileri alarak günlük hakları erken sıfırlayamaz.
  final DateTime Function() _now;

  int _balance = 0;
  int get balance => _balance;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Kayıtlı günlük sayaçların ait olduğu gün — bu, [_now]'ın bugünkü
  /// tarihiyle FARKLIYSA sayaçlar "eski" sayılır ve okunurken 0 gibi
  /// davranılır (bkz. altta [wheelSpinsUsedToday]/[adWatchesUsedToday]) —
  /// `WaterProvider`'ın "her erişimde `_today`'i yeniden hesapla" deseniyle
  /// aynı, ayrı bir "reconcile" adımına gerek yok.
  DateTime? _dailyLimitsDate;
  int _wheelSpinsUsedToday = 0;
  int _adWatchesUsedToday = 0;

  /// **2026 güvenlik düzeltmesi — coin farming koruması, kullanıcı
  /// raporuyla bulundu:** hedef eklemek ÜCRETSİZ (bkz. `GoalsProvider.
  /// addGoal`) — bu alan olmadan bir kullanıcı 10 hedef açıp hepsini AYNI
  /// hafta tamamlayarak `earnStreak7Bonus()`'u 10 KEZ tetikleyip 500 ZC
  /// "kazanabilirdi" (gerçek bir alışkanlık ödülü DEĞİL, bir ekonomi
  /// bug'ı). Son ödülün verildiği GÜN (saat bileşeni yok) — bkz.
  /// [earnStreak7Bonus].
  DateTime? _lastStreak7BonusDate;

  /// Bugün ZATEN kullanılmış Şans Çarkı hakkı — kayıtlı sayaç dünden
  /// kalmışsa (gün değiştiyse) 0 döner, ayrı bir sıfırlama adımı GEREKMEZ.
  int get wheelSpinsUsedToday =>
      _dailyLimitsDate == _dateOnly(_now()) ? _wheelSpinsUsedToday : 0;

  /// Bugün ZATEN kullanılmış "reklam izleyip coin kazan" hakkı — yukarıdaki
  /// [wheelSpinsUsedToday] ile AYNI "gün değiştiyse 0" mantığı.
  int get adWatchesUsedToday =>
      _dailyLimitsDate == _dateOnly(_now()) ? _adWatchesUsedToday : 0;

  /// Şans Çarkı'nın günlük çevirme hakkı (bkz. [remainingWheelSpinsToday]).
  /// **Faz 3 (B4)** — Zibo Pro/Pro+ kullanıcılar normal 3 hakkın üstüne +1
  /// alır (Pro/Pro+ arasında ayrım YOK, [_isPro] Pro+'ta da `true` döner).
  int get maxDailyWheelSpins => 3 + (_isPro() ? 1 : 0);

  /// Bugün kalan Şans Çarkı hakkı (0-[maxDailyWheelSpins]) — arayüz bunu
  /// hem "kalan X hak" göstermek hem de 0 olduğunda butonu/kartı pasif
  /// hâle getirmek için kullanır.
  int get remainingWheelSpinsToday =>
      (maxDailyWheelSpins - wheelSpinsUsedToday).clamp(0, maxDailyWheelSpins);

  /// Bugün kalan "reklam izleyip coin kazan" hakkı (0-[maxDailyAdWatches]).
  int get remainingAdWatchesToday =>
      (maxDailyAdWatches - adWatchesUsedToday).clamp(0, maxDailyAdWatches);

  bool get canSpinWheelToday => remainingWheelSpinsToday > 0;
  bool get canWatchAdForCoinsToday => remainingAdWatchesToday > 0;

  /// Bir reklamın GERÇEKTEN ödül verdiği (kullanıcı sonuna kadar izlediği)
  /// anda çağrılır — reklam yüklenemez/erken kapatılırsa hak HİÇ
  /// tüketilmez (kullanıcının "günde 3 hakkı" gerçek başarılı izlemeler
  /// içindir, başarısız denemeler için değil). Gün değiştiyse önce
  /// sayaçları sıfırlıyor. `notifyListeners`/kalıcı kayıt burada YAPILMIYOR
  /// — hemen ardından çağrılan `_earn(...)` zaten ikisini de tetikliyor,
  /// bu yüzden aynı bildirim/kayıt turunda birlikte gidiyorlar.
  void _consumeDailyLimit({required bool isWheelSpin}) {
    final today = _dateOnly(_now());
    if (_dailyLimitsDate != today) {
      _dailyLimitsDate = today;
      _wheelSpinsUsedToday = 0;
      _adWatchesUsedToday = 0;
    }
    if (isWheelSpin) {
      _wheelSpinsUsedToday++;
    } else {
      _adWatchesUsedToday++;
    }
  }

  /// Şimdiye kadar kazanılan/harcanan TOPLAM ZC — bkz. "Profil > Zibo Coin
  /// Özeti". `transactions` listesinden HESAPLANMIYOR çünkü o liste yalnızca
  /// en yeni [_maxStoredTransactions] kaydı tutuyor (bkz. sınıf
  /// dokümantasyonu) — bu iki sayaç ayrı, hiç budanmayan, ömür boyu kalıcı
  /// toplamlar.
  int _totalEarned = 0;
  int _totalSpent = 0;
  int get totalEarned => _totalEarned;
  int get totalSpent => _totalSpent;

  final List<CoinTransaction> _transactions = [];

  /// En yeni işlem başta olacak şekilde salt okunur işlem geçmişi.
  List<CoinTransaction> get transactions => List.unmodifiable(_transactions);

  /// Son işlemin bakiyeye etkisi (ör. +5, -80). UI'da uçan "+N"/"-N"
  /// metni gibi geçici efektler için kullanılır; her bildirimde tazelenir.
  int? get lastDelta =>
      _transactions.isEmpty ? null : _transactions.first.signedAmount;

  /// **Faz 3 (B1)** — [earnDailyLoginReward] Pro/Pro+ çarpanı uyguladıysa
  /// (150 = 1,5x Pro, 200 = 2x Pro+), o çarpanı taşır; `null` ise son
  /// kazanma bir çarpan İÇERMEDİ. `lastDelta` ile AYNI "tek seferlik, en
  /// son işlem" deseni — kalıcı DEĞİL, yalnızca `CoinBalanceWidget`'ın
  /// floating "+N" efektinin altına küçük bir bonus etiketi eklemesi için.
  /// Metni ÇÖZMEK (`AppLocalizations`) widget'ın işi — `CoinProvider` bir
  /// widget olmadığı için `context`'e erişemiyor.
  int? _lastEarnBonusMultiplierPercent;
  int? get lastEarnBonusMultiplierPercent => _lastEarnBonusMultiplierPercent;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe (AppBar'daki
  /// bakiye rakamının sıfırdan gerçek değere aniden "zıplamasını" önlemek).
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded != null) {
      try {
        _balance = decoded['balance'] as int;
        _transactions
          ..clear()
          ..addAll(
            (decoded['transactions'] as List).map((raw) {
              final map = raw as Map<String, dynamic>;
              return CoinTransaction(
                type: CoinTransactionType.values.byName(map['type'] as String),
                amount: map['amount'] as int,
                reason: map['reason'] as String,
                timestamp: DateTime.parse(map['timestamp'] as String),
              );
            }),
          );
        if (decoded['dailyLimitsDate'] != null) {
          _dailyLimitsDate = DateTime.parse(
            decoded['dailyLimitsDate'] as String,
          );
          _wheelSpinsUsedToday = decoded['wheelSpinsUsedToday'] as int? ?? 0;
          _adWatchesUsedToday = decoded['adWatchesUsedToday'] as int? ?? 0;
        }
        // Eski (bu alan eklenmeden ÖNCEki) kayıtlı veride yok — `null`
        // kalıyor, yani göç anındaki İLK tamamlanma her zaman ödül alır
        // (kullanıcıları geriye dönük CEZALANDIRMIYOR).
        if (decoded['lastStreak7BonusDate'] != null) {
          _lastStreak7BonusDate = DateTime.parse(
            decoded['lastStreak7BonusDate'] as String,
          );
        }
        if (decoded.containsKey('totalEarned')) {
          _totalEarned = decoded['totalEarned'] as int;
          _totalSpent = decoded['totalSpent'] as int;
        } else {
          // ÇOK ESKİ (bu alanlar eklenmeden ÖNCEki) kayıtlı veri — tam
          // geçmiş bilinmediği için en iyi tahmin olarak, o an kalıcı
          // depoda duran (en fazla `_maxStoredTransactions` adet) işlemden
          // geriye dönük hesaplanıyor. `_maxStoredTransactions`'ı aşan çok
          // eski işlemler bu toplamda YOK — bilinen, kabul edilmiş bir
          // sınır (bkz. sınıf dokümantasyonu).
          for (final t in _transactions) {
            if (t.type == CoinTransactionType.earn) {
              _totalEarned += t.amount;
            } else {
              _totalSpent += t.amount;
            }
          }
        }
      } catch (_) {
        // Bozuk/eski formatlı kayıtlı veri — sessizce sıfır bakiyeyle devam
        // et, uygulamanın çökmesindense veri kaybı tercih edilir.
      }
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _store.save({
      'balance': _balance,
      'totalEarned': _totalEarned,
      'totalSpent': _totalSpent,
      'dailyLimitsDate': _dailyLimitsDate?.toIso8601String(),
      'wheelSpinsUsedToday': _wheelSpinsUsedToday,
      'adWatchesUsedToday': _adWatchesUsedToday,
      'lastStreak7BonusDate': _lastStreak7BonusDate?.toIso8601String(),
      'transactions': _transactions
          .take(_maxStoredTransactions)
          .map(
            (t) => {
              'type': t.type.name,
              'amount': t.amount,
              'reason': t.reason,
              'timestamp': t.timestamp.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  void _record(CoinTransactionType type, int amount, String reason) {
    _transactions.insert(
      0,
      CoinTransaction(
        type: type,
        amount: amount,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    _save();
  }

  /// [playRewardSound] yalnızca [purchaseCoinPackage] tarafından `false`
  /// geçilir — o akış kendi ayrı satın alma sesini ([SoundEffectsService.
  /// playCoinPurchase]) çalar, "kazanma" ([SoundEffectsService.
  /// playCoinReward]) sesiyle ÇAKIŞMASIN diye. Bu tek istisna dışında TÜM
  /// kazanma mekanikleri (aşağıdaki `earn*` metodları) buradan geçtiği için
  /// ses efekti tek bir yerde, merkezi olarak tetikleniyor.
  ///
  /// [awardXp] (2026 yeni özellik — Level/XP Sistemi) yalnızca
  /// [purchaseCoinPackage]/[_onOrphanedPurchase] tarafından `false` geçilir —
  /// gerçek parayla coin SATIN ALMAK bir "başarı" değil, XP verilmesi
  /// yanıltıcı olurdu (`playRewardSound: false` ile AYNI ayrım felsefesi).
  void _earn(
    int amount,
    String reason, {
    bool playRewardSound = true,
    bool awardXp = true,
    int? bonusMultiplierPercent,
  }) {
    // Faz 3 (B1) — HER kazanma çağrısında (bonus taşımayanlar DAHİL)
    // koşulsuz güncellenir, aksi halde `earnDailyLoginReward`'ın bıraktığı
    // değer sonraki alakasız bir kazanmada (ör. hedef tamamlama) da
    // görünmeye devam eder. `lastDelta`'nın HER zaman en son işlemden
    // taze hesaplanmasıyla AYNI gerekçe.
    _lastEarnBonusMultiplierPercent = bonusMultiplierPercent;
    _balance += amount;
    _totalEarned += amount;
    _record(CoinTransactionType.earn, amount, reason);
    if (playRewardSound && _isSoundEnabled()) {
      _soundEffectsService.playCoinReward();
    }
    if (awardXp) {
      _onXpEarned(amount);
    }
  }

  /// Bakiye yetersizse false döner ve hiçbir şey değişmez; yeterliyse
  /// düşülür ve true döner.
  bool _spend(int amount, String reason) {
    if (_balance < amount) return false;
    _balance -= amount;
    _totalSpent += amount;
    _record(CoinTransactionType.spend, amount, reason);
    return true;
  }

  // --- Kazanma mekanikleri -------------------------------------------

  void earnDailyCheckIn() =>
      _earn(CoinEconomy.dailyCheckIn, 'Günlük check-in');

  /// Ödüllü reklam izletir (şimdilik [MockAdService] ile simüle edilir)
  /// ve kullanıcı ödülü hak ettiyse coin ekler. Reklam tamamlanmazsa
  /// coin eklenmez. Günlük hak ([maxDailyAdWatches]) zaten tükenmişse
  /// reklamı hiç GÖSTERMEDEN `false` döner — arayüz normalde butonu
  /// [canWatchAdForCoinsToday] `false`yken zaten devre dışı bırakıyor
  /// (bkz. `StoreScreen._WatchAdCard`), bu kontrol yalnızca ek bir
  /// güvenlik katmanı.
  Future<bool> earnAdWatch() async {
    if (!canWatchAdForCoinsToday) return false;
    final rewarded = await _adService.showRewardedAd();
    if (rewarded) {
      _consumeDailyLimit(isWheelSpin: false);
      _earn(CoinEconomy.adWatch, 'Reklam izleme');
    }
    return rewarded;
  }

  void earnDailyMiniTask() =>
      _earn(CoinEconomy.dailyMiniTask, 'Günlük mini görev');

  /// **2026 güvenlik düzeltmesi — kullanıcı raporu: "10 hedef açıp hepsini
  /// aynı hafta tamamlayarak coin bug'ı yapılabilir."** Hedef eklemek
  /// ÜCRETSİZ olduğu için bu +50 ZC ödülü, KAÇ TANE hedef tamamlanırsa
  /// tamamlansın, GERİYE dönük bir rolling 7-GÜN penceresinde (son
  /// ödülden bu yana 7 gün geçmediyse) YALNIZCA BİR KEZ veriliyor — `_now`
  /// (`TrustedTimeProvider`) üzerinden, cihaz saatini ileri alarak
  /// atlatılamaz (diğer TÜM "güne bağlı" mekanizmalarla AYNI garanti).
  /// **Hedefin KENDİSİ (döngü/`GoalCompletion` arşivi) bu sınırdan HİÇ
  /// ETKİLENMİYOR** — kullanıcı istediği kadar hedefi tamamlayabilir,
  /// yalnızca coin ÖDÜLÜ haftada bir hedefe sınırlı (`WaterProvider`'ın
  /// `rewardClaimed`'ıyla AYNI "coin farming koruması" felsefesi).
  void earnStreak7Bonus() {
    final today = _dateOnly(_now());
    if (_lastStreak7BonusDate != null &&
        today.difference(_lastStreak7BonusDate!).inDays < 7) {
      return;
    }
    _lastStreak7BonusDate = today;
    _earn(CoinEconomy.streak7Bonus, '7 günlük seri bonusu');
  }

  void earnStreak30Bonus() {
    _earn(CoinEconomy.streak30Bonus, '30 günlük seri bonusu');
    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // bu metodun KENDİSİ bugün itibariyle HİÇBİR YERDEN çağrılmıyor (30
    // günlük gerçek bir mekanik bu turda İCAT EDİLMEDİ) — ama ileride
    // biri bunu bağlarsa, Ana Sayfa'nın konuşma balonu otomatik olarak
    // aynı coşkulu "seri bonusu" havuzunu gösterecek, ayrı bir kablolama
    // gerekmeyecek.
    pendingZiboEvent.value = ZiboEventType.loginStreakBonus;
  }

  void earnReferral() => _earn(CoinEconomy.referral, 'Arkadaş daveti');

  /// Instagram Takip Kartı: kullanıcı "Takip Ettim"e bastığında (bkz.
  /// `InstagramFollowProvider.markClaimed()` — tek seferlik, kalıcı bir
  /// bayrakla korunuyor, bu yüzden burada ayrıca bir tekrar-önleme
  /// kontrolüne gerek YOK, çağıran taraf zaten yalnızca İLK başarılı
  /// `markClaimed()`'den sonra bunu çağırıyor) çağrılır — sabit 100 ZC.
  void earnInstagramFollowReward() =>
      _earn(CoinEconomy.instagramFollowReward, 'Instagram takip ödülü');

  /// Şükran Günlüğü: kullanıcı bugünün 3 şükran cümlesini doldurup
  /// kaydettiğinde çağrılır (bkz. `GratitudeJournalScreen` — `GoalCard`'ın
  /// `cycleCompleted` sonrası `earnStreak7Bonus()` çağırma deseniyle aynı:
  /// `GratitudeProvider.saveToday()` `true` dönerse bu metot tetiklenir).
  void earnGratitudeJournal() =>
      _earn(CoinEconomy.gratitudeJournal, 'Şükran günlüğü');

  /// Su Takibi: kullanıcı günlük su hedefini tamamladığında çağrılır (bkz.
  /// `WaterTrackingScreen` — `GratitudeJournalScreen`'in `saveToday() ==
  /// true` deseniyle aynı: `WaterProvider.incrementUnit()` `true` dönerse,
  /// yani bu dokunuş hedefi TAM O AN tamamladıysa, bu metot tetiklenir).
  void earnWaterGoal() =>
      _earn(CoinEconomy.waterGoalCompleted, 'Su hedefi tamamlandı');

  /// Manifest Günlüğü: kullanıcı günün fotoğrafını + niyet metnini
  /// kaydettiğinde çağrılır (bkz. `ManifestJournalScreen` —
  /// `WaterTrackingScreen`'in `incrementUnit() == true` deseniyle aynı:
  /// `ManifestProvider.addEntry()` yalnızca o günün İLK tamamlanan
  /// girişinde `true` döner, sonraki üzerine yazmalar coin tetiklemez).
  void earnManifestJournal() =>
      _earn(CoinEconomy.manifestJournal, 'Manifest günlüğü');

  /// Günlük Giriş Ödülleri: kullanıcı 7 günlük döngüdeki bugünün kutucuğuna
  /// dokunduğunda çağrılır (bkz. `DailyRewardsProvider.claimToday()` — bu
  /// metodun döndürdüğü miktar günden güne değiştiği için `CoinEconomy`'de
  /// tek bir sabit yerine `dailyLoginRewards` DİZİSİ var; miktar burada
  /// parametre olarak alınır).
  ///
  /// **Faz 3 (B1)** — Zibo Pro 1,5x, Zibo Pro+ 2x çarpan uygular
  /// ([_isProPlus] önce kontrol edilir, `_isPro` Pro+'ta da `true` döner).
  /// Ondalık sonuç `.round()` ile tamsayıya yuvarlanır (ör. 5 ZC × 1,5 =
  /// 7,5 → 8 ZC).
  void earnDailyLoginReward(int amount) {
    _earn(
      previewDailyLoginReward(amount),
      'Günlük giriş ödülü',
      bonusMultiplierPercent: _dailyLoginBonusPercent,
    );
  }

  int? get _dailyLoginBonusPercent {
    if (_isProPlus()) return 200;
    if (_isPro()) return 150;
    return null;
  }

  /// [amount] (bir günün TEMEL ödülü, `CoinEconomy.dailyLoginRewards`)
  /// için — Pro/Pro+ çarpanı uygulandıktan SONRAKİ gerçek tutarı, herhangi
  /// bir yan etki OLMADAN (bakiyeye eklemeden) döner. `DailyRewardsScreen`
  /// bunu kullanıcıya "bu günü alınca kaç ZC kazanacak" diye göstermek için
  /// çağırır — [earnDailyLoginReward] ile AYNI hesaplamayı TEK yerden
  /// yaparak ekranda gösterilen tutarla GERÇEKTEN kazanılan tutarın asla
  /// birbirinden sapmamasını garantiler.
  int previewDailyLoginReward(int amount) {
    if (_isProPlus()) return (amount * 2).round();
    if (_isPro()) return (amount * 1.5).round();
    return amount;
  }

  /// Günlük giriş ödülleri tablosunda her günün yanında gösterilecek
  /// çarpan etiketi — Pro+ "2x", Pro "1.5x", ücretsiz kullanıcı için
  /// `null` (rozet hiç gösterilmez).
  String? get dailyLoginMultiplierLabel {
    if (_isProPlus()) return '2x';
    if (_isPro()) return '1.5x';
    return null;
  }

  /// Rozet Sistemi: bir rozet kazanılıp "Ödülü Al" butonuna basıldığında
  /// çağrılır (bkz. `BadgeCelebrationOverlay`/`BadgeProvider.markClaimed`) —
  /// `earnDailyLoginReward` ile AYNI "dinamik miktar, tek satırlık `_earn`
  /// çağrısı" deseni; `badgeId` yalnızca işlem geçmişi etiketinde ayırt
  /// edici olması için.
  void earnBadgeReward(int amount, String badgeId) =>
      _earn(amount, 'Rozet: $badgeId');

  /// Şans Çarkı: reklam izlettikten (şimdilik [MockAdService] ile simüle
  /// edilir) sonra [wheelPrizes] içinden ağırlıklı rastgele bir ödül seçip
  /// ekler. Reklam tamamlanmazsa hiçbir şey eklenmez ve `null` döner;
  /// tamamlanırsa kazanılan [WheelPrize]'ı döner — arayüz bunu hem çarkı
  /// doğru dilimde durdurmak hem de kutlama diyaloğunda göstermek için
  /// kullanır. Günlük hak ([maxDailyWheelSpins]) zaten tükenmişse reklamı
  /// hiç GÖSTERMEDEN `null` döner — `earnAdWatch()`'taki AYNI ek güvenlik
  /// katmanı gerekçesi (arayüz zaten [canSpinWheelToday] `false`yken
  /// çevirme dokunma alanını devre dışı bırakıyor, bkz. `WheelScreen`).
  ///
  /// **Faz 3 (B4)** — Zibo Pro/Pro+ kullanıcılar ([_isPro]) reklam izleme
  /// adımını ATLAR, doğrudan çevirir; free kullanıcılar aynen reklam
  /// izlemek zorunda.
  Future<WheelPrize?> watchAdAndSpinWheel() async {
    if (!canSpinWheelToday) return null;
    final rewarded = _isPro() || await _adService.showRewardedAd();
    if (!rewarded) return null;
    _consumeDailyLimit(isWheelSpin: true);
    final prize = pickWeightedPrize(wheelPrizes, _random);
    _earn(prize.amount, 'Şans Çarkı');
    return prize;
  }

  /// Mağazadan bir coin paketi satın alma akışını başlatır (şimdilik
  /// [MockPurchaseService] ile simüle edilir). Ödeme tamamlandıysa paketin
  /// coin miktarını ekler ve true döner; kullanıcı vazgeçerse coin
  /// eklenmez.
  Future<bool> purchaseCoinPackage(CoinPackage package) async {
    final success = await _purchaseService.purchaseCoinPackage(package);
    if (success) {
      // `playRewardSound: false` — bu bir "kazanma" değil "satın alma";
      // kendi ayrı sesi aşağıda çalınıyor (bkz. _earn dokümantasyonu).
      // Bakiyeye eklenen tutar `totalCoins` (miktar + bonus) — bkz.
      // `CoinPackage.bonusCoins`.
      _earn(
        package.totalCoins,
        _purchaseReason(package),
        playRewardSound: false,
        awardXp: false,
      );
      if (_isSoundEnabled()) _soundEffectsService.playCoinPurchase();
    }
    return success;
  }

  /// Play Store'dan bu paketin canlı fiyat metnini sorgular (bkz.
  /// [PurchaseService.queryLocalizedPrice]) — `null` dönerse çağıran taraf
  /// [CoinPackage.price]'taki sabit fiyata düşer.
  Future<String?> queryLocalizedPrice(CoinPackage package) =>
      _purchaseService.queryLocalizedPrice(package);

  /// [PurchaseService.orphanedPurchaseProductIds]'ten gelen, bir önceki
  /// oturumdan kalan teslim edilmemiş bir satın alma — coin'i GEÇ de olsa
  /// teslim eder (bkz. `iap_purchase_service.dart`'taki "orphaned purchase"
  /// dokümantasyonu). Eşleşen bir [CoinPackage] bulunamazsa (ör. ürün id'si
  /// artık listede yok) sessizce yok sayılır.
  void _onOrphanedPurchase(String productId) {
    CoinPackage? package;
    for (final candidate in coinPackages) {
      if (candidate.id == productId) {
        package = candidate;
        break;
      }
    }
    if (package == null) return;
    _earn(
      package.totalCoins,
      'Gecikmeli teslim — ${_purchaseReason(package)}',
      playRewardSound: false,
      awardXp: false,
    );
    if (_isSoundEnabled()) _soundEffectsService.playCoinPurchase();
  }

  /// Satın alma işlem geçmişi etiketi — bonus varsa onu da yazar (ör.
  /// "Satın alma: 1000 ZC (+100 bonus)").
  static String _purchaseReason(CoinPackage package) {
    final base = 'Satın alma: ${package.coinAmount} ZC';
    return package.bonusCoins > 0
        ? '$base (+${package.bonusCoins} bonus)'
        : base;
  }

  // --- Harcama mekanikleri ---------------------------------------------

  bool spendStreakFreeze() =>
      _spend(CoinEconomy.streakFreeze, 'Streak Freeze');

  bool spendLockedPersonalityMode() =>
      _spend(CoinEconomy.lockedPersonalityMode, 'Kilitli kişilik modu');

  bool spendSpecialReplyPack() =>
      _spend(CoinEconomy.specialReplyPack, 'Özel replik paketi');

  /// Kostümler parametrik fiyatlanır (bkz. lib/data/costumes.dart). Başarılı
  /// satın almada [SoundEffectsService.playCostumeBuy] çalar — [_spend]'in
  /// diğer çağıranlarından (streak freeze vb.) BİLEREK AYRI tutuldu, o
  /// generik metoda ses eklemek istenmeyen bir yan etki (ör. kişilik modu
  /// kilidi açma) için de aynı sesi çaldırırdı.
  bool spendOnCostume({required String costumeName, required int cost}) {
    final success = _spend(cost, 'Kostüm: $costumeName');
    if (success && _isSoundEnabled()) _soundEffectsService.playCostumeBuy();
    return success;
  }

  /// Kod-tabanlı temalar parametrik fiyatlanır (bkz. lib/data/app_themes.dart).
  /// Başarılı satın almada [SoundEffectsService.playThemeBuy] çalar — bkz.
  /// [spendOnCostume]'daki AYNI gerekçe.
  bool spendOnTheme({required String themeName, required int cost}) {
    final success = _spend(cost, 'Tema: $themeName');
    if (success && _isSoundEnabled()) _soundEffectsService.playThemeBuy();
    return success;
  }

  // --- Reklam gösterimi (coin ekonomisiyle DOĞRUDAN ilgisiz) -----------

  /// Ana Sayfa'da Zibo'ya art arda hızlı dokunulduğunda gösterilen geçiş
  /// (interstitial) reklamı — bkz. `HomeScreen._RapidTapState`
  /// dokümantasyonu. Coin bakiyesini/işlem geçmişini HİÇ etkilemiyor,
  /// yalnızca zaten var olan (main.dart'ta gerçek Appodeal ile kurulan)
  /// [_adService] örneğini yeniden kullanmak için buradan geçiriliyor —
  /// ayrı bir ikinci `AdService` örneği/kablolaması gerekmesin diye.
  /// Kullanıcı "Zibo ADS" satın aldıysa ([_isAdFree]) reklam HİÇ
  /// yüklenmeye/gösterilmeye çalışılmadan `false` döner — ödüllü (rewarded)
  /// reklamlar (kullanıcının KENDİ isteğiyle izlediği, coin karşılığı)
  /// BİLEREK bu kontrolün DIŞINDA, yalnızca zorunlu/geçiş reklamı kapanıyor.
  /// **Faz 3 — Zibo Pro/Pro+ perk "A1"**: Pro/Pro+ kullanıcılar ([_isPro])
  /// için de AYNI şekilde reklam hiç yüklenmeye çalışılmadan `false` döner.
  Future<bool> showInterstitialAd() {
    if (_isAdFree() || _isPro()) return Future.value(false);
    return _adService.showInterstitialAd();
  }

  @override
  void dispose() {
    _orphanedPurchaseSub.cancel();
    _soundEffectsService.dispose();
    super.dispose();
  }
}
