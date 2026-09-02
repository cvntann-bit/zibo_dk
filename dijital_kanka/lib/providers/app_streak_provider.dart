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
  }) : _now = now ?? DateTime.now,
       _store = CloudStateStore(
         prefsKey: _prefsKey,
         uid: uid,
         firestore: firestore,
       ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'appStreakState';
  final DateTime Function() _now;
  final CloudStateStore _store;

  DateTime? _lastOpenDate;
  int _currentStreak = 0;
  int _totalDaysOpened = 0;
  bool _isReady = false;

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
    });
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
