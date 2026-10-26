import 'package:shared_preferences/shared_preferences.dart';

/// Geçiş reklamının (interstitial) çıkabileceği "anlamlı akış" noktaları.
/// Ana Sayfa gezintisi BİLEREK yok — Zibo'ya art arda dokunurken açılan
/// reklam kazara tıklama üretiyordu (Appodeal CTR %55, bkz.
/// docs/unit_economics.md §2c). Yeni bir yerleşim eklemek = buraya bir değer
/// eklemek; analitikte `placement` parametresi olarak görünür.
enum InterstitialPlacement {
  /// Günlük giriş ödülü alındı (`DailyRewardsScreen`).
  dailyReward,

  /// Bir hedefin 7/7 döngüsü tamamlandı, kutlama bitti (`GoalTrackingScreen`).
  goalCycle,

  /// Şükran/rüya günlüğüne kayıt yapılıp ekrandan çıkıldı.
  journalSaved,
}

/// Bir geçiş reklamının neden GÖSTERİLMEDİĞİ (analitik `reason`).
enum InterstitialSkipReason {
  /// Kayıtlı durum henüz yüklenmedi — emin olamıyorsak göstermiyoruz.
  notReady,

  /// Uygulama bu cihazda ilk açıldıktan sonraki koruma süresi dolmadı.
  newUserShield,

  /// Bugünkü gösterim hakkı doldu.
  dailyCap,

  /// Son gösterimden bu yana bekleme süresi geçmedi.
  cooldown,
}

/// Sıklık kuralları — kullanıcı kararı (2026-10-26): ilk 3 saat hiç
/// interstitial yok, günde en fazla 2, iki gösterim arası en az 4 dakika.
class InterstitialPacingRules {
  const InterstitialPacingRules({
    this.newUserShield = const Duration(hours: 3),
    this.maxPerDay = 2,
    this.cooldown = const Duration(minutes: 4),
  });

  final Duration newUserShield;
  final int maxPerDay;
  final Duration cooldown;
}

/// Geçiş reklamı sıklık bekçisi — `CoinProvider.showInterstitialAd` her
/// gösterimden önce [check] eder, başarılı gösterimden sonra [recordShown]
/// çağırır. Durum YALNIZCA cihazda (`SharedPreferences`) tutulur: reklam
/// sıklığı cihaz başına bir deneyim kuralı, buluta senkronu gereksiz yazma
/// maliyeti olurdu.
///
/// "İlk açılış" anı bu sınıfın ilk yüklendiği an — bu sürüme güncelleyen
/// eski kullanıcılar da bir kez 3 saatlik korumadan geçer (zararsız).
class InterstitialPacer {
  InterstitialPacer({
    DateTime Function()? now,
    this.rules = const InterstitialPacingRules(),
  }) : _now = now ?? DateTime.now;

  static const _firstSeenKey = 'adPacing.firstSeenAt';
  static const _dayKey = 'adPacing.day';
  static const _countKey = 'adPacing.count';
  static const _lastShownKey = 'adPacing.lastShownAt';

  final DateTime Function() _now;
  final InterstitialPacingRules rules;

  bool _ready = false;
  DateTime? _firstSeenAt;
  String? _day;
  int _count = 0;
  DateTime? _lastShownAt;

  bool get isReady => _ready;

  static String _dayString(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstSeen = DateTime.tryParse(prefs.getString(_firstSeenKey) ?? '');
      if (firstSeen == null) {
        _firstSeenAt = _now();
        await prefs.setString(_firstSeenKey, _firstSeenAt!.toIso8601String());
      } else {
        _firstSeenAt = firstSeen;
      }
      _day = prefs.getString(_dayKey);
      _count = prefs.getInt(_countKey) ?? 0;
      _lastShownAt = DateTime.tryParse(prefs.getString(_lastShownKey) ?? '');
    } catch (_) {
      // Okunamadıysa ilk açılış sayılır — en kötü ihtimalle koruma bir kez
      // daha uygulanır, reklam fazla gösterilmez.
      _firstSeenAt ??= _now();
    }
    _ready = true;
  }

  /// Bugün gösterilmiş geçiş reklamı sayısı (gün değiştiyse 0).
  int get shownToday => _day == _dayString(_now()) ? _count : 0;

  /// Şu an gösterilebiliyorsa `null`, değilse engelleyen kural.
  InterstitialSkipReason? check() {
    if (!_ready || _firstSeenAt == null) return InterstitialSkipReason.notReady;
    final now = _now();
    if (now.difference(_firstSeenAt!) < rules.newUserShield) {
      return InterstitialSkipReason.newUserShield;
    }
    if (shownToday >= rules.maxPerDay) return InterstitialSkipReason.dailyCap;
    final last = _lastShownAt;
    // Saat geri alınmışsa (last gelecekte) de bekleme süresi uygulanır.
    if (last != null && now.difference(last) < rules.cooldown) {
      return InterstitialSkipReason.cooldown;
    }
    return null;
  }

  Future<void> recordShown() async {
    final now = _now();
    final today = _dayString(now);
    _count = _day == today ? _count + 1 : 1;
    _day = today;
    _lastShownAt = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dayKey, today);
      await prefs.setInt(_countKey, _count);
      await prefs.setString(_lastShownKey, now.toIso8601String());
    } catch (_) {}
  }
}
