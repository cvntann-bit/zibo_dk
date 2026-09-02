import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/collection_badges.dart';
import '../data/consistency_badges.dart';
import '../data/loyalty_badges.dart';
import '../data/module_mastery_badges.dart';
import '../models/badge_definition.dart';
import '../models/badge_record.dart';
import '../services/cloud_state_store.dart';
import '../utils/badge_celebration_signal.dart';

/// Rozet Sistemi'nin kalıcı durumu — hangi rozetler kazanıldı, ne zaman, ödülü
/// alındı mı. `CoinProvider`/`GoalsProvider` ile AYNI `CloudStateStore`
/// (Varyant A, tek JSON blob) deseni — `{'earned': {badgeId: {earnedAt,
/// claimed}}}` şeklinde tek bir Firestore/`SharedPreferences` belgesi.
///
/// **Kazanma kontrolü BURADA, yani `reconcileConsistencyBadges(...)` içinde
/// yapılıyor — [ZiboBadgeDefinition] yalnızca GÖRÜNTÜLEME/ödül bilgisini
/// taşıyor (bkz. o sınıfın dokümantasyonu).** `BadgeCoordinator` (bkz. o
/// dosya) bu metodu ilgili streak/hedef verisi her güncellendiğinde otomatik
/// çağırıyor — kullanıcı manuel bir "rozetleri kontrol et" eylemi TETİKLEMİYOR.
///
/// **Tek slot kutlama sinyali:** aynı reconcile çağrısında birden fazla rozet
/// YENİ kazanılırsa (ör. `appOpenStreak` bir sıçramada 30'u geçip hem
/// `week_streak` hem `month_streak`'i aynı anda tetiklerse), TÜMÜ kalıcı
/// olarak kazanılmış sayılır ama yalnızca EN SON'u (`consistencyBadges`
/// listesindeki sıralamaya göre) `pendingBadgePopup`'a yazılır — bkz. o
/// sinyalin kendi dokümantasyonu.
class BadgeProvider extends ChangeNotifier {
  BadgeProvider({String? uid, FirebaseFirestore? firestore})
    : _store = CloudStateStore(
        prefsKey: _prefsKey,
        uid: uid,
        firestore: firestore,
      ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'badgeState';
  final CloudStateStore _store;

  Map<String, BadgeRecord> _earned = {};
  bool _isReady = false;

  /// `_AppStartupGate`'in yedi provider'ıyla AYNI "ilk yükleme bitene kadar
  /// bekle" desenini BİLEREK TEKRARLAMIYOR — rozet verisi açılış ekranını
  /// bloke edecek kadar kritik değil, `false` iken çağıranlar (ör. Rozetler
  /// Galerisi) basitçe yükleniyor durumu gösterebilir.
  bool get isReady => _isReady;

  bool isEarned(String badgeId) => _earned.containsKey(badgeId);

  bool isClaimed(String badgeId) => _earned[badgeId]?.claimed ?? false;

  BadgeRecord? recordFor(String badgeId) => _earned[badgeId];

  Future<void> _loadFromPrefs() async {
    try {
      final data = await _store.load();
      if (data != null) {
        final raw = data['earned'] as Map<String, dynamic>? ?? const {};
        _earned = raw.map(
          (key, value) =>
              MapEntry(key, BadgeRecord.fromJson(value as Map<String, dynamic>)),
        );
      }
    } catch (_) {
      // Bozuk/okunamayan veri — boş başlangıca sessizce düş, diğer
      // provider'lardaki AYNI "asla çökme" güvenlik ağı.
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() {
    return _store.save({
      'earned': _earned.map((key, value) => MapEntry(key, value.toJson())),
    });
  }

  /// İstikrar Rozetleri'nin kazanma kontrolü (bkz. altta
  /// [reconcileModuleMasteryBadges]/[reconcileCollectionBadges]/
  /// [reconcileLoyaltyBadges] — diğer kategoriler için AYNI desen).
  /// [hasCompletedFirstGoalCycle] — `GoalsProvider.completions.isNotEmpty`.
  /// [appOpenStreak] — `AppStreakProvider.currentStreak` (uygulamayı her gün
  /// açma serisi, Hedef Takibi'nden BAĞIMSIZ — bkz. o provider'ın
  /// dokümantasyonu).
  void reconcileConsistencyBadges({
    required bool hasCompletedFirstGoalCycle,
    required int appOpenStreak,
  }) {
    ZiboBadgeDefinition? lastNewlyEarned;
    for (final badge in consistencyBadges) {
      if (_earned.containsKey(badge.id)) continue;
      final meetsRequirement = switch (badge.id) {
        'first_step' => hasCompletedFirstGoalCycle,
        'week_streak' => appOpenStreak >= 7,
        'month_streak' => appOpenStreak >= 30,
        'iron_will' => appOpenStreak >= 90,
        'unyielding' => appOpenStreak >= 180,
        _ => false,
      };
      if (meetsRequirement) {
        _earned[badge.id] = BadgeRecord(earnedAt: DateTime.now(), claimed: false);
        lastNewlyEarned = badge;
      }
    }
    if (lastNewlyEarned != null) {
      notifyListeners();
      unawaited(_save());
      pendingBadgePopup.value = lastNewlyEarned;
    }
  }

  /// Modül Ustalığı Rozetleri'nin kazanma kontrolü — `reconcileConsistencyBadges`
  /// ile AYNI "tek slot, en son yeni kazanılan yazılır" desen, yalnızca
  /// koşullar ARDIŞIK bir seri DEĞİL, ilgili modülün TOPLAM kayıt sayısı
  /// (bkz. `module_mastery_badges.dart`). Parametreler `BadgeCoordinator`'ın
  /// ilgili altı provider'dan (Şükran/Su/Ruh Hali/Para/Manifest/Rüya)
  /// okuduğu güncel sayaçlar.
  void reconcileModuleMasteryBadges({
    required int gratitudeCount,
    required int waterDaysCount,
    required int moodCount,
    required int moneyCount,
    required int manifestCount,
    required int dreamCount,
  }) {
    ZiboBadgeDefinition? lastNewlyEarned;
    for (final badge in moduleMasteryBadges) {
      if (_earned.containsKey(badge.id)) continue;
      final meetsRequirement = switch (badge.id) {
        'grateful_heart' => gratitudeCount >= 30,
        'water_hero' => waterDaysCount >= 30,
        'mood_chronicler' => moodCount >= 30,
        'savings_master' => moneyCount >= 20,
        'dreamer' => manifestCount >= 15,
        'dream_interpreter' => dreamCount >= 15,
        _ => false,
      };
      if (meetsRequirement) {
        _earned[badge.id] = BadgeRecord(earnedAt: DateTime.now(), claimed: false);
        lastNewlyEarned = badge;
      }
    }
    if (lastNewlyEarned != null) {
      notifyListeners();
      unawaited(_save());
      pendingBadgePopup.value = lastNewlyEarned;
    }
  }

  /// Koleksiyon Rozetleri'nin kazanma kontrolü — `reconcileModuleMasteryBadges`
  /// ile AYNI desen, yalnızca eşikler ilgili modülün TOPLAM KAYDI değil
  /// sahip olunan kostüm/tema SAYISI (bkz. `collection_badges.dart`).
  /// [ownedCostumeCount] — `CostumeProvider.ownedRealCostumeCount`.
  /// [ownsAllCostumes] — `CostumeProvider.ownsAllCostumes` (sayım
  /// KARŞILAŞTIRMASI değil, her kostümün TEK TEK doğrulanması — bkz. o
  /// getter'ın dokümantasyonu). [ownedThemeCount] —
  /// `AppThemeProvider.ownedIds.length`.
  void reconcileCollectionBadges({
    required int ownedCostumeCount,
    required bool ownsAllCostumes,
    required int ownedThemeCount,
  }) {
    ZiboBadgeDefinition? lastNewlyEarned;
    for (final badge in collectionBadges) {
      if (_earned.containsKey(badge.id)) continue;
      final meetsRequirement = switch (badge.id) {
        'collector' => ownedCostumeCount >= 5,
        'fashion_icon' => ownedCostumeCount >= 10,
        'full_wardrobe' => ownsAllCostumes,
        'theme_hunter' => ownedThemeCount >= 3,
        _ => false,
      };
      if (meetsRequirement) {
        _earned[badge.id] = BadgeRecord(earnedAt: DateTime.now(), claimed: false);
        lastNewlyEarned = badge;
      }
    }
    if (lastNewlyEarned != null) {
      notifyListeners();
      unawaited(_save());
      pendingBadgePopup.value = lastNewlyEarned;
    }
  }

  /// Sadakat Rozetleri'nin kazanma kontrolü — AYNI "tek slot" deseni ama
  /// İSTİKRAR'ın AKSİNE ARDIŞIKLIK gerektirmiyor (bkz. `loyalty_badges.
  /// dart`). [totalDaysOpened] — `AppStreakProvider.totalDaysOpened`
  /// (uygulamanın açıldığı TOPLAM benzersiz gün, `currentStreak`'ten
  /// FARKLI — bir gün kaçırılsa da sıfırlanmaz). [daysSinceFirstUsed] —
  /// `ProfileProvider.daysSinceFirstUsed()`.
  void reconcileLoyaltyBadges({
    required int totalDaysOpened,
    required int daysSinceFirstUsed,
  }) {
    ZiboBadgeDefinition? lastNewlyEarned;
    for (final badge in loyaltyBadges) {
      if (_earned.containsKey(badge.id)) continue;
      final meetsRequirement = switch (badge.id) {
        'first_week' => totalDaysOpened >= 7,
        'loyal_friend' => totalDaysOpened >= 100,
        'anniversary' => daysSinceFirstUsed >= 365,
        _ => false,
      };
      if (meetsRequirement) {
        _earned[badge.id] = BadgeRecord(earnedAt: DateTime.now(), claimed: false);
        lastNewlyEarned = badge;
      }
    }
    if (lastNewlyEarned != null) {
      notifyListeners();
      unawaited(_save());
      pendingBadgePopup.value = lastNewlyEarned;
    }
  }

  /// **GEÇİCİ** — Ayarlar'daki "Rozet Test Paneli" için (bkz. o dosyadaki
  /// `_BadgeTestPanel`, `_CoinTestPanel`'in AYNI "açıkça geçici, kolayca
  /// kaldırılabilir" deseni). `allBadges`'ten henüz kazanılmamış rastgele
  /// bir rozeti GERÇEK kazanma akışıyla (`reconcileConsistencyBadges`)
  /// BİREBİR AYNI şekilde kazandırır — kazanılmış say, kalıcı hale getir,
  /// `pendingBadgePopup`'a yaz (bu da uygulama genelindeki konfeti + kutlama
  /// popup'ını tetikler). Ödül (ZC) burada VERİLMİYOR — gerçek akışla aynı
  /// şekilde, yalnızca kullanıcı popup'taki "Ödülü Al"a bastığında
  /// `CoinProvider.earnBadgeReward` çağrılır. Tüm rozetler zaten
  /// kazanılmışsa `null` döner (no-op).
  ZiboBadgeDefinition? debugGrantRandomBadge() {
    final unearned = allBadges.where((b) => !_earned.containsKey(b.id)).toList();
    if (unearned.isEmpty) return null;
    final badge = (unearned..shuffle()).first;
    _earned[badge.id] = BadgeRecord(earnedAt: DateTime.now(), claimed: false);
    notifyListeners();
    unawaited(_save());
    pendingBadgePopup.value = badge;
    return badge;
  }

  /// Kutlama popup'ındaki "Ödülü Al" butonu çağırıyor — `claimed`'i kalıcı
  /// olarak `true` yapar. Zaten kazanılmamış VEYA zaten alınmış bir rozet
  /// için no-op (çift ödül verilmesin diye).
  Future<void> markClaimed(String badgeId) async {
    final record = _earned[badgeId];
    if (record == null || record.claimed) return;
    _earned[badgeId] = record.copyWith(claimed: true);
    notifyListeners();
    await _save();
  }
}
