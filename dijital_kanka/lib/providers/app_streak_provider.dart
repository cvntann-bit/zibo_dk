import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

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
  int _totalDaysOpened = 0;
  bool _isReady = false;

  /// Bu ay şimdiye kadar kullanılan ücretsiz Streak Freeze sayısı — bkz.
  /// [remainingFreeStreakFreezes]/[_maybeResetMonthlyFreezeQuota].
  int _freeStreakFreezesUsedThisMonth = 0;

  /// Bir sonraki aylık sıfırlama tarihi — `null` ise henüz hiç
  /// ilklendirilmemiş (kullanıcı hiç Freeze kullanmadı/kontrol etmedi).
  DateTime? _freeStreakFreezeResetDate;

  bool get isReady => _isReady;
  int get currentStreak => _currentStreak;

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
        // Faz 4 (B3) — bu iki alan eklenmeden ÖNCEki kayıtlı veride yok;
        // bulunmazsa sırasıyla 0/`null`'a düşülür (`_maybeResetMonthlyFreezeQuota`
        // ilk erişimde `null` resetDate'i normal şekilde ilklendirir).
        _freeStreakFreezesUsedThisMonth =
            data['freeStreakFreezesUsedThisMonth'] as int? ?? 0;
        final rawResetDate = data['freeStreakFreezeResetDate'] as String?;
        _freeStreakFreezeResetDate = rawResetDate != null
            ? DateTime.tryParse(rawResetDate)
            : null;
      }
    } catch (_) {
      // Bozuk/okunamayan veri — sıfırdan başla, diğer provider'lardaki AYNI
      // "asla çökme" güvenlik ağı.
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() {
    return _store.save({
      'lastOpenDate': _lastOpenDate?.toIso8601String(),
      'currentStreak': _currentStreak,
      'totalDaysOpened': _totalDaysOpened,
      'freeStreakFreezesUsedThisMonth': _freeStreakFreezesUsedThisMonth,
      'freeStreakFreezeResetDate': _freeStreakFreezeResetDate?.toIso8601String(),
    });
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
  /// [usedFreeQuota] `true` ise aylık ücretsiz sayaç +1 artırılır; `false`
  /// ise (çağıran taraf `CoinProvider.spendStreakFreeze()`'i ZATEN başarıyla
  /// çağırdığı için) sayaca dokunulmaz.
  void repairMissedDayWithFreeze({required bool usedFreeQuota}) {
    final today = _dateOnly(_now());
    _currentStreak += 1;
    _totalDaysOpened += 1;
    _lastOpenDate = today;
    if (usedFreeQuota) {
      _maybeResetMonthlyFreezeQuota();
      _freeStreakFreezesUsedThisMonth += 1;
    }
    notifyListeners();
    _save();
  }

  /// **Yalnızca debug'dan çağrılır** (bkz. `settings_screen.dart`
  /// `_SubscriptionDebugPanel` ile AYNI gerekçe/desen) — [isStreakAtRisk]
  /// senaryosunu GERÇEK cihazda test edebilmek için `_lastOpenDate`'i
  /// "bugün - 2 gün"e çeker. `TrustedTimeProvider`'ın cihaz-saati-manipülasyonu
  /// korumasından ETKİLENMEZ (doğrudan alanı değiştirir, saat okumaz) —
  /// bilerek yalnızca `kDebugMode`de çağrılabilir bir test kolaylığı.
  void debugSimulateMissedDay() {
    if (!kDebugMode) return;
    if (_currentStreak == 0) _currentStreak = 3;
    _lastOpenDate = _dateOnly(_now()).subtract(const Duration(days: 2));
    notifyListeners();
    _save();
  }

  /// Uygulama her açıldığında/öne geldiğinde çağrılır (`RootScreen.initState`
  /// postFrameCallback'i + `didChangeAppLifecycleState`'in `resumed` dalı —
  /// `GoalsProvider.reconcileForToday`/`DailyRewardsProvider.
  /// reconcileForToday` ile AYNI tetikleme deseni). Bugün ZATEN kaydedilmişse
  /// no-op; dün kaydedilmişse seri +1; aksi halde (bugünden ÖNCE bir gün
  /// kaçırılmışsa VEYA hiç kayıt yoksa) seri 1'e sıfırlanır.
  void recordOpenForToday() {
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
    _totalDaysOpened += 1;
    _lastOpenDate = today;
    notifyListeners();
    _save();
  }
}
