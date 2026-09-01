import 'package:flutter/foundation.dart';

/// Ana Sayfa'nın konuşma balonunda, gerçekleştiği anda ÖZEL bir mesaj
/// göstermesi gereken olaylar — bkz. CLAUDE.md "Olay Tetiklemeli Özel
/// Mesajlar" bölümü VE `data/zibo_event_messages.dart`. Bu olaylar
/// GENELLİKLE Ana Sayfa'nın KENDİSİNDE değil BAŞKA ekranlarda (Hedef
/// Takibi, Mağaza, Günlük Giriş Ödülleri) gerçekleşir.
enum ZiboEventType {
  /// Bir hedefin 7/7 günlük döngüsü tamamlandı (bkz. `GoalCard.
  /// onCycleCompleted`).
  goalCycleCompleted,

  /// Kaçırılan bir gün yüzünden bir hedefin döngüsü sıfırlandı (bkz.
  /// `GoalsProvider.reconcileForToday`).
  streakBroken,

  /// Yeni bir kostüm veya tema açıldı — satın alınarak VEYA bir hedef
  /// tamamlanarak (bkz. `CostumeCard`/`ThemeOptionCard._buy`,
  /// `CostumeProvider.reconcileGoalUnlocks`).
  costumeOrThemeUnlocked,

  /// Günlük Giriş Ödülleri'nin 7. günü alındı (bkz.
  /// `DailyRewardsScreen._claimDay`) VEYA (ileride gerçek bir 30-günlük
  /// mekanik eklenirse) `CoinProvider.earnStreak30Bonus()` çağrıldı — bkz.
  /// o metodun dokümantasyonu, bu mekanik BU TURDA İCAT EDİLMEDİ, yalnızca
  /// mesaj kancası hazırlandı.
  loginStreakBonus,
}

/// Ana Sayfa'nın (bkz. `HomeScreen._pickAndSetQuote`) BİR SONRAKİ söz
/// seçiminde göstermesi gereken, henüz TÜKETİLMEMİŞ bir olay — `tab_
/// navigation.dart`'taki `homeTabRequest`/`isHomeTabActive` ile AYNI
/// "basit, kalıcılık gerektirmeyen, widget ağacının dışından da
/// yazılabilen global sinyal" deseni. Kalıcı DEĞİL (uygulama kapanırsa
/// kaybolur) — bilerek, bu kozmetik bir özellik, `_recentZiboTaps` gibi
/// diğer oturum-içi durumlarla AYNI basitleştirme.
///
/// **Tek bir slot, kuyruk DEĞİL** — aynı anda birden fazla olay
/// gerçekleşirse (ör. bir hedef tamamlanır tamamlanmaz bir kostüm de
/// açılırsa) yalnızca EN SON olay gösterilir, öncekiler kaybolur. Bu,
/// mesajların arka arkaya sıraya girip kullanıcıyı ekranlarca "Zibo'ya
/// dokun"a zorlamaması için bilinçli bir basitleştirme.
final ValueNotifier<ZiboEventType?> pendingZiboEvent =
    ValueNotifier<ZiboEventType?>(null);
