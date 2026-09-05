/// Zibo Coin ekonomisindeki tüm kazanma/harcama tutarları tek yerde.
/// Miktarları dengelemek istediğinizde yalnızca bu dosyayı güncellemeniz
/// yeterli — provider ve ekranlar bu sabitleri kullanır.
abstract final class CoinEconomy {
  // Kazanma mekanikleri
  static const int dailyCheckIn = 5;
  static const int adWatch = 20;
  static const int dailyMiniTask = 15;
  static const int streak7Bonus = 50;
  static const int streak30Bonus = 250;
  static const int referral = 100;
  // 2026 yeni özellik — Instagram Takip Kartı ve Ödülü (bkz.
  // `InstagramFollowProvider`/`instagram_follow_card.dart`). Tek seferlik,
  // kalıcı bir bayrakla korunuyor.
  static const int instagramFollowReward = 100;
  // 2026 güncellemesi — kullanıcı isteğiyle 2 → 5 ZC'ye yükseltildi (üç
  // günlük-modül ödülü de tutarlı kalsın diye BİRLİKTE değiştirildi).
  static const int gratitudeJournal = 5;
  static const int waterGoalCompleted = 5;
  static const int manifestJournal = 5;

  /// Günlük Giriş Ödülleri: 7 günlük döngüdeki her günün miktarı, sırayla
  /// (index 0 = Gün 1). Diğer sabitlerin aksine tek bir sayı değil, artan
  /// bir dizi — kullanıcı isteğiyle belirlendi.
  static const List<int> dailyLoginRewards = [5, 10, 15, 20, 30, 40, 100];

  // Harcama mekanikleri
  static const int streakFreeze = 80;
  static const int lockedPersonalityMode = 500;
  static const int specialReplyPack = 150;

  // Kostümler parametrik fiyatlanıyor — gerçek fiyatlar
  // lib/data/costumes.dart içinde tanımlı (400-30000 ZC arası).
}
