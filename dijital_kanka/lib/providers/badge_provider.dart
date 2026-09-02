import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/consistency_badges.dart';
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

  /// İstikrar Rozetleri'nin (bu turda tek kategori) kazanma kontrolü.
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
