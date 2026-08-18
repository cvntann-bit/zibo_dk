import 'package:audioplayers/audioplayers.dart';

/// `AdService`/`NotificationService` ile AYNI "gerçek implementasyon, testte
/// enjekte edilebilir sahte" deseni — kısa UI ses efektleri için. Gerçek
/// implementasyon `audioplayers` paketinin platform kanalına dokunduğu için
/// `flutter_test`'te kullanılamaz.
///
/// **2026 güncellemesi — üç yeni ses efekti.** Kullanıcı isteğiyle Zibo
/// dokunma sesinin yanına coin kazanma ([playCoinReward]), coin satın alma
/// ([playCoinPurchase]) ve hedef tamamlama ([playGoalComplete]) sesleri
/// eklendi — her biri farklı bir ekran/provider'dan (`HomeScreen`,
/// `CoinProvider`, `GoalTrackingScreen`) KENDİ ayrı `SoundEffectsService`
/// örneğini oluşturup çağırıyor (bkz. o dosyalardaki dokümantasyon), bu
/// yüzden tek bir `AudioPlayer`'ın farklı bağlamlardaki sesleri birbirini
/// KESMESİ riski yok.
abstract class SoundEffectsService {
  const SoundEffectsService();

  /// Zibo'ya dokununca çalınan kısa "tık" sesi (bkz.
  /// `assets/sounds/zibo_tap_new.wav`).
  Future<void> playZiboTap();

  /// Kullanıcı herhangi bir şekilde Zibo Coin KAZANDIĞINDA (check-in, günlük
  /// görev, streak bonusu, Şans Çarkı, günlük giriş ödülü, reklam karşılığı
  /// coin, su/şükran/manifest hedefleri — `CoinProvider._earn()`'ün
  /// TÜM çağıranları) çalınan ödül sesi (bkz.
  /// `assets/sounds/zc_reward.wav`). Mağazadan gerçek para karşılığı SATIN
  /// ALMA bu kapsamda DEĞİL — bkz. [playCoinPurchase].
  Future<void> playCoinReward();

  /// Kullanıcı Mağaza'dan bir coin paketini gerçek para karşılığı satın
  /// aldığında (bkz. `CoinProvider.purchaseCoinPackage`) çalınan, ayrı ve
  /// KASITLI OLARAK [playCoinReward]'dan farklı bir ses (bkz.
  /// `assets/sounds/zc_buy.wav`) — "kazanma" ile "satın alma" arasında
  /// işitsel bir ayrım olsun diye.
  Future<void> playCoinPurchase();

  /// Hedef Takibi'nde kullanıcı bugünün kutucuğunu YENİ işaretlediğinde
  /// (işaret kaldırma DEĞİL), 2 saniyelik gecikme + konfeti animasyonuyla
  /// TAM EŞ ZAMANLI çalınan kutlama sesi (bkz.
  /// `assets/sounds/zibo_target.wav`, `GoalTrackingScreen`).
  Future<void> playGoalComplete();

  /// Uygulama kapanırken/widget dispose edilirken native oynatıcı
  /// kaynaklarını serbest bırakır.
  void dispose();
}

class AudioPlayersSoundEffectsService extends SoundEffectsService {
  AudioPlayersSoundEffectsService()
    : _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  final AudioPlayer _player;

  Future<void> _play(String assetPath) async {
    try {
      // Önceki ses tam bitmeden yeni bir çağrı gelirse ÖNCEKİNİ kesip
      // yeniden başlatıyoruz — art arda hızlı tetiklenmelerde seslerin üst
      // üste binip rahatsız edici olmaması için (bkz. `playZiboTap`'in
      // orijinal gerekçesi, şimdi TÜM ses efektleri için ortak).
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Ses çalma altyapısı bu ortamda/cihazda kullanılamıyor — sessizce
      // devre dışı kalır, tetikleyen etkileşimin geri kalanı etkilenmez.
    }
  }

  @override
  Future<void> playZiboTap() => _play('sounds/zibo_tap_new.wav');

  @override
  Future<void> playCoinReward() => _play('sounds/zc_reward.wav');

  @override
  Future<void> playCoinPurchase() => _play('sounds/zc_buy.wav');

  @override
  Future<void> playGoalComplete() => _play('sounds/zibo_target.wav');

  @override
  void dispose() => _player.dispose();
}

class FakeSoundEffectsService extends SoundEffectsService {
  const FakeSoundEffectsService();

  @override
  Future<void> playZiboTap() async {}

  @override
  Future<void> playCoinReward() async {}

  @override
  Future<void> playCoinPurchase() async {}

  @override
  Future<void> playGoalComplete() async {}

  @override
  void dispose() {}
}
