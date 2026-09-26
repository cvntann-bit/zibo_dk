import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// Kaçırılan bir günü tamir eden Streak Freeze'in nereden geldiği.
enum StreakFreezeSource {
  /// Pro/Pro+ aylık ücretsiz hakkı.
  freeQuota,

  /// Mağaza'dan önceden alınmış stok ([AppStreakProvider.ownedStreakFreezes]).
  owned,

  /// Diyalogda anında ZC ile ödendi — çağıran `CoinProvider.spendStreakFreeze()`'i
  /// ZATEN başarıyla çağırmış olmalı.
  coins,
}

/// Uygulamayı HER GÜN açma serisi — Hedef Takibi'nin per-goal 7 günlük
/// döngüsünden TAMAMEN BAĞIMSIZ, yeni/ayrı bir metrik (bkz. CLAUDE.md "Rozet
/// Sistemi" bölümü — kullanıcının `AskUserQuestion` ile seçtiği ölçü).
/// `GoalsProvider.longestStreak`'in AKSİNE bir 7 günlük tavana sahip DEĞİL —
/// [currentStreak] 180+ güne kadar sınırsız büyüyebilir, İstikrar
/// Rozetleri'nin `iron_will`/`unyielding` kademelerinin kaynağı bu.
///
/// **`CoinProvider`/`GoalsProvider` ile AYNI `CloudStateStore` (Varyant A)
/// deseni** — `{'lastOpenDate': iso8601-tarih, 'currentStreak': int}`.
///
/// **GÜVENLİK-KRİTİK — `now` HER ZAMAN `TrustedTimeProvider.now()` ile
/// enjekte edilmeli, cihazın kendi saatiyle DEĞİL** (bkz. CLAUDE.md "Firestore
/// veri kalıcılığı... güvenilir zaman" bölümü) — bu, Günlük Giriş Ödülleri/
/// Hedef Takibi gibi diğer TÜM "güne bağlı" mekanizmalarla AYNI güvenlik
/// garantisi: kullanıcı cihazın tarihini ileri alarak günlük seriyi manipüle
/// edip streak rozetlerini erken/haksız kazanamaz. Testte enjekte edilebilir
/// sahte bir `now` ile serbestçe kontrol edilebilir.
class AppStreakProvider extends ChangeNotifier {
  AppStreakProvider({
    String? uid,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
    bool Function() isPro = _alwaysFalse,
    bool Function() isProPlus = _alwaysFalse,
  }) : _now = now ?? DateTime.now,
       _isPro = isPro,
       _isProPlus = isProPlus,
       _store = CloudStateStore(
         prefsKey: _prefsKey,
         uid: uid,
         firestore: firestore,
       ) {
    _loadFromPrefs();
  }

  static bool _alwaysFalse() => false;

  static const _prefsKey = 'appStreakState';
  final DateTime Function() _now;
  final CloudStateStore _store;

  /// **Faz 4 (B3) — Zibo Pro/Pro+ perk "aylık ücretsiz Streak Freeze".**
  /// `CoinProvider`'daki AYNI enjekte edilebilir callback deseni —
  /// `main.dart`'ta `SubscriptionProvider.isPro`/`isProPlus`'a bağlanır.
  /// Yalnızca [freeStreakFreezeQuota]'yı belirlemek için kullanılır.
  final bool Function() _isPro;
  final bool Function() _isProPlus;

  DateTime? _lastOpenDate;
  int _currentStreak = 0;
  int _longestStreakEver = 0;
  int _totalDaysOpened = 0;
  bool _isReady = false;

  /// Bu ay şimdiye kadar kullanılan ücretsiz Streak Freeze sayısı — bkz.
  /// [remainingFreeStreakFreezes]/[_maybeResetMonthlyFreezeQuota].
  int _freeStreakFreezesUsedThisMonth = 0;

  /// Bir sonraki aylık sıfırlama tarihi — `null` ise henüz hiç
  /// ilklendirilmemiş (kullanıcı hiç Freeze kullanmadı/kontrol etmedi).
  DateTime? _freeStreakFreezeResetDate;

  int _ownedStreakFreezes = 0;

  bool get isReady => _isReady;

  final _readyCompleter = Completer<void>();
  bool _pendingOpen = false;

  /// Kayıtlı veri yüklendiğinde tamamlanır.
  Future<void> get ready => _readyCompleter.future;

  /// Mağaza'dan Zibo Coin ile alınıp stokta bekleyen Streak Freeze sayısı.
  int get ownedStreakFreezes => _ownedStreakFreezes;
  int get currentStreak => _currentStreak;

  /// [currentStreak] gibi bir gün kaçırılınca SIFIRLANMAYAN, MONOTONİK
  /// kalıcı rekor — Profil > "En Uzun Seri Rekoru" ve İstikrar Rozetleri'nin
  /// (`week_streak`/`month_streak`/`iron_will`/`unyielding`) kaynağı bu.
  /// `GoalsProvider.longestStreak`'in AKSİNE 7 günlük bir tavana sahip
  /// DEĞİL (bkz. sınıf dokümantasyonu).
  int get longestStreakEver => _longestStreakEver;

  /// Uygulamanın açıldığı TOPLAM benzersiz gün sayısı — [currentStreak]'in
  /// AKSİNE bir gün kaçırılınca SIFIRLANMAZ, yalnızca MONOTONİK artar.
  /// Sadakat Rozetleri'nin `first_week`/`loyal_friend` eşikleri için (bkz.
  /// `loyalty_badges.dart` — "ardışık olması şart değil" isteği tam olarak
  /// bu alan sayesinde karşılanıyor).
  int get totalDaysOpened => _totalDaysOpened;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadFromPrefs() async {
    try {
      final data = await _store.load();
      if (data != null) {
        final rawDate = data['lastOpenDate'] as String?;
        _lastOpenDate = rawDate != null ? DateTime.tryParse(rawDate) : null;
        _currentStreak = data['currentStreak'] as int? ?? 0;
        // 2026 güncellemesi — bu alan eklenmeden ÖNCEki kayıtlı veride yok;
        // bulunmazsa `currentStreak`'e düşülüyor (en azından o kadar gün
        // açıldığı KESİN biliniyor — GERÇEK toplam daha önce bir kez bile
        // seri kırıldıysa bundan BÜYÜK olabilir, ama bu göç HİÇBİR ZAMAN
        // fazla SAYMAZ, yalnızca olası bir AZ sayım — kabul edilebilir bir
        // bilinçli sadeleştirme, `WaterProvider`'daki eski-format-göçü
        // dersleriyle AYNI ruhta).
        _totalDaysOpened = data['totalDaysOpened'] as int? ?? _currentStreak;
        // Faz 6 göçü — AYNI "oku-zamanı-göç-et" deseni: bu alan eklenmeden
        // ÖNCEki kayıtlı veride yok, bulunmazsa mevcut `currentStreak`'e
        // düşülür (en azından o kadarına ULAŞILDIĞI KESİN biliniyor).
        _longestStreakEver =
            data['longestStreakEver'] as int? ?? _currentStreak;
        // Faz 4 (B3) — bu iki alan eklenmeden ÖNCEki kayıtlı veride yok;
        // bulunmazsa sırasıyla 0/`null`'a düşülür (`_maybeResetMonthlyFreezeQuota`
        // ilk erişimde `null` resetDate'i normal şekilde ilklendirir).
        _freeStreakFreezesUsedThisMonth =
            data['freeStreakFreezesUsedThisMonth'] as int? ?? 0;
        final rawResetDate = data['freeStreakFreezeResetDate'] as String?;
        _freeStreakFreezeResetDate = rawResetDate != null
            ? DateTime.tryParse(rawResetDate)
            : null;
        _ownedStreakFreezes = data['ownedStreakFreezes'] as int? ?? 0;
      }
    } catch (_) {
      // Bozuk/okunamayan veri — sıfırdan başla, diğer provider'lardaki AYNI
      // "asla çökme" güvenlik ağı.
    }
    _isReady = true;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    if (_pendingOpen) {
      _pendingOpen = false;
      recordOpenForToday();
    }
    notifyListeners();
  }

  Future<void> _save() {
    return _store.save({
      'lastOpenDate': _lastOpenDate?.toIso8601String(),
      'currentStreak': _currentStreak,
      'longestStreakEver': _longestStreakEver,
      'totalDaysOpened': _totalDaysOpened,
      'freeStreakFreezesUsedThisMonth': _freeStreakFreezesUsedThisMonth,
      'freeStreakFreezeResetDate': _freeStreakFreezeResetDate?.toIso8601String(),
      'ownedStreakFreezes': _ownedStreakFreezes,
    });
  }

  /// Mağaza satın alımından sonra çağrılır — çağıran taraf
  /// `CoinProvider.spendStreakFreezeStorePurchase()`'i ZATEN başarıyla
  /// çağırmış olmalı.
  void addOwnedStreakFreeze() {
    _ownedStreakFreezes += 1;
    notifyListeners();
    _save();
  }

  /// **Faz 4 (B3)** — kullanıcı TAM 1 gün kaçırdıysa (streak kırılmak
  /// ÜZEREYSE) `true`. `RootScreen`, [recordOpenForToday] çağırmadan ÖNCE
  /// bunu kontrol edip `true` ise `StreakFreezeOfferDialog`'u gösterir.
  /// Yalnızca TEK günlük boşluk kapsanır (Streak Freeze bir seferde yalnızca
  /// 1 günü tamir eder, Duolingo'daki AYNI kısıt) — 2+ gün kaçırıldıysa
  /// `false` döner, seri normal şekilde sıfırlanır.
  bool get isStreakAtRisk {
    if (_lastOpenDate == null || _currentStreak == 0) return false;
    final today = _dateOnly(_now());
    final missedDay = today.subtract(const Duration(days: 2));
    return _dateOnly(_lastOpenDate!) == missedDay;
  }

  /// Pro ayda 1, Pro+ ayda 3 ücretsiz Streak Freeze hakkı (`_isPro`,
  /// Pro+'ta da `true` döndüğü için ÖNCE `_isProPlus` kontrol edilir).
  int get freeStreakFreezeQuota => _isProPlus() ? 3 : (_isPro() ? 1 : 0);

  /// Bu ay kalan ücretsiz Streak Freeze hakkı — `StreakFreezeOfferDialog`
  /// bunu "X/Y ücretsiz hakkın kaldı" olarak gösterir.
  int get remainingFreeStreakFreezes {
    _maybeResetMonthlyFreezeQuota();
    final quota = freeStreakFreezeQuota;
    return (quota - _freeStreakFreezesUsedThisMonth).clamp(0, quota);
  }

  /// `resetDate` geçtiyse sayacı sıfırlar ve `resetDate`'i (kullanıcının
  /// aylarca uygulamayı açmamış olma ihtimaline karşı `while` ile
  /// ZİNCİRLEME) bir sonraki aya ilerletir — her zaman ÖNCEKİ `resetDate`'e
  /// göre ilerletildiği için (`_now()`'a göre DEĞİL) tarih sürüklenmesi
  /// birikmez. Güvenlik-kritik bir sınır DEĞİL (kullanıcının kendi isteği:
  /// basit bir tarih kontrolü yeterli) — `TrustedTimeProvider` şart değil,
  /// ama `_now` zaten öyle enjekte ediliyor (bkz. sınıf dokümantasyonu).
  void _maybeResetMonthlyFreezeQuota() {
    final now = _now();
    if (_freeStreakFreezeResetDate == null) {
      _freeStreakFreezeResetDate = DateTime(now.year, now.month + 1, now.day);
      return;
    }
    var changed = false;
    while (!now.isBefore(_freeStreakFreezeResetDate!)) {
      _freeStreakFreezesUsedThisMonth = 0;
      _freeStreakFreezeResetDate = DateTime(
        _freeStreakFreezeResetDate!.year,
        _freeStreakFreezeResetDate!.month + 1,
        _freeStreakFreezeResetDate!.day,
      );
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _save();
    }
  }

  /// Streak Freeze kullanarak kaçırılan TEK günü tamir eder — [isStreakAtRisk]
  /// `true` iken, `StreakFreezeOfferDialog`'un kabul akışından çağrılır.
  /// Kaçırılan günü açılmış GİBİ SAYMAZ (yalnızca [_currentStreak] kırılmadan
  /// devam eder) — [_totalDaysOpened] yalnızca BUGÜN için +1 artar, kullanıcı
  /// dün GERÇEKTEN açmadığı için o gün için ikinci kez sayılmaz.
  /// [source] harcanan hakkı belirler: `freeQuota` aylık sayacı +1 artırır,
  /// `owned` stoktan 1 düşer (stok boşsa HİÇBİR ŞEY değişmez, `false`
  /// döner), `coins` hiçbir sayaca dokunmaz.
  bool repairMissedDayWithFreeze({required StreakFreezeSource source}) {
    if (source == StreakFreezeSource.owned && _ownedStreakFreezes <= 0) {
      return false;
    }
    final today = _dateOnly(_now());
    _currentStreak += 1;
    if (_currentStreak > _longestStreakEver) _longestStreakEver = _currentStreak;
    _totalDaysOpened += 1;
    _lastOpenDate = today;
    switch (source) {
      case StreakFreezeSource.freeQuota:
        _maybeResetMonthlyFreezeQuota();
        _freeStreakFreezesUsedThisMonth += 1;
      case StreakFreezeSource.owned:
        _ownedStreakFreezes -= 1;
      case StreakFreezeSource.coins:
        break;
    }
    notifyListeners();
    _save();
    return true;
  }

  /// Uygulama açma serisi SAĞLAMKEN (dün açıldı) yalnızca dünü kaçırılmış
  /// HEDEFLERİ dondurmak için bir Streak Freeze harcar — seriye dokunmaz.
  /// [source] kuralları [repairMissedDayWithFreeze] ile aynı.
  bool consumeFreezeForGoals({required StreakFreezeSource source}) {
    switch (source) {
      case StreakFreezeSource.freeQuota:
        if (remainingFreeStreakFreezes <= 0) return false;
        _maybeResetMonthlyFreezeQuota();
        _freeStreakFreezesUsedThisMonth += 1;
      case StreakFreezeSource.owned:
        if (_ownedStreakFreezes <= 0) return false;
        _ownedStreakFreezes -= 1;
      case StreakFreezeSource.coins:
        break;
    }
    notifyListeners();
    _save();
    return true;
  }

  /// Uygulama her açıldığında/öne geldiğinde çağrılır (`RootScreen.initState`
  /// postFrameCallback'i + `didChangeAppLifecycleState`'in `resumed` dalı —
  /// `GoalsProvider.reconcileForToday`/`DailyRewardsProvider.
  /// reconcileForToday` ile AYNI tetikleme deseni). Bugün ZATEN kaydedilmişse
  /// no-op; dün kaydedilmişse seri +1; aksi halde (bugünden ÖNCE bir gün
  /// kaçırılmışsa VEYA hiç kayıt yoksa) seri 1'e sıfırlanır.
  ///
  /// **Kayıtlı veri yüklenmeden çağrılırsa ertelenir** (yükleme bitince
  /// işlenir). Eskiden hemen işleniyordu: ilk karede `_lastOpenDate` henüz
  /// `null` göründüğü için seri HER açılışta 1'e sıfırlanıp buluta
  /// yazılıyordu — "En Uzun Seri Rekoru 1'de takılı" ve "Streak Freeze hiç
  /// çıkmıyor" hatalarının kök nedeni (bkz. `test/app_streak_race_test.dart`).
  void recordOpenForToday() {
    if (!_isReady) {
      _pendingOpen = true;
      return;
    }
    final today = _dateOnly(_now());
    if (_lastOpenDate != null && _dateOnly(_lastOpenDate!) == today) {
      return;
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (_lastOpenDate != null && _dateOnly(_lastOpenDate!) == yesterday) {
      _currentStreak += 1;
    } else {
      _currentStreak = 1;
    }
    if (_currentStreak > _longestStreakEver) _longestStreakEver = _currentStreak;
    _totalDaysOpened += 1;
    _lastOpenDate = today;
    notifyListeners();
    _save();
  }
}
