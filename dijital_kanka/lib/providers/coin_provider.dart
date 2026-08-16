import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/wheel_prizes.dart';
import '../models/coin_economy.dart';
import '../models/coin_package.dart';
import '../models/coin_transaction.dart';
import '../models/wheel_prize.dart';
import '../services/ad_service.dart';
import '../services/cloud_state_store.dart';
import '../services/purchase_service.dart';

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
    Random? random,
    String? uid,
  }) : _adService = adService,
       _purchaseService = purchaseService,
       _random = random ?? Random(),
       _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'coinState';
  static const _maxStoredTransactions = 200;

  final AdService _adService;
  final PurchaseService _purchaseService;
  final CloudStateStore _store;

  /// Şans Çarkı'nın ağırlıklı ödül seçimi için — testte sabit/kontrollü bir
  /// sonuç enjekte edebilmek amacıyla constructor'dan verilebilir.
  final Random _random;

  int _balance = 0;
  int get balance => _balance;

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

  void _earn(int amount, String reason) {
    _balance += amount;
    _totalEarned += amount;
    _record(CoinTransactionType.earn, amount, reason);
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
  /// coin eklenmez.
  Future<bool> earnAdWatch() async {
    final rewarded = await _adService.showRewardedAd();
    if (rewarded) {
      _earn(CoinEconomy.adWatch, 'Reklam izleme');
    }
    return rewarded;
  }

  void earnDailyMiniTask() =>
      _earn(CoinEconomy.dailyMiniTask, 'Günlük mini görev');

  void earnStreak7Bonus() =>
      _earn(CoinEconomy.streak7Bonus, '7 günlük seri bonusu');

  void earnStreak30Bonus() =>
      _earn(CoinEconomy.streak30Bonus, '30 günlük seri bonusu');

  void earnReferral() => _earn(CoinEconomy.referral, 'Arkadaş daveti');

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
  void earnDailyLoginReward(int amount) =>
      _earn(amount, 'Günlük giriş ödülü');

  /// Şans Çarkı: reklam izlettikten (şimdilik [MockAdService] ile simüle
  /// edilir) sonra [wheelPrizes] içinden ağırlıklı rastgele bir ödül seçip
  /// ekler. Reklam tamamlanmazsa hiçbir şey eklenmez ve `null` döner;
  /// tamamlanırsa kazanılan [WheelPrize]'ı döner — arayüz bunu hem çarkı
  /// doğru dilimde durdurmak hem de kutlama diyaloğunda göstermek için
  /// kullanır.
  Future<WheelPrize?> watchAdAndSpinWheel() async {
    final rewarded = await _adService.showRewardedAd();
    if (!rewarded) return null;
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
      _earn(package.coinAmount, 'Satın alma: ${package.coinAmount} ZC');
    }
    return success;
  }

  // --- Harcama mekanikleri ---------------------------------------------

  bool spendStreakFreeze() =>
      _spend(CoinEconomy.streakFreeze, 'Streak Freeze');

  bool spendLockedPersonalityMode() =>
      _spend(CoinEconomy.lockedPersonalityMode, 'Kilitli kişilik modu');

  bool spendSpecialReplyPack() =>
      _spend(CoinEconomy.specialReplyPack, 'Özel replik paketi');

  /// Kostümler parametrik fiyatlanır (bkz. lib/data/costumes.dart).
  bool spendOnCostume({required String costumeName, required int cost}) =>
      _spend(cost, 'Kostüm: $costumeName');

  /// Kod-tabanlı temalar parametrik fiyatlanır (bkz. lib/data/app_themes.dart).
  bool spendOnTheme({required String themeName, required int cost}) =>
      _spend(cost, 'Tema: $themeName');
}
