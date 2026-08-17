import 'package:audioplayers/audioplayers.dart';

/// `AdService`/`NotificationService` ile AYNI "gerçek implementasyon, testte
/// enjekte edilebilir sahte" deseni — kısa UI ses efektleri (şimdilik yalnızca
/// Zibo dokunma sesi) için. Gerçek implementasyon `audioplayers` paketinin
/// platform kanalına dokunduğu için `flutter_test`'te kullanılamaz.
abstract class SoundEffectsService {
  const SoundEffectsService();

  /// Zibo'ya dokununca çalınan kısa "tık" sesi (bkz.
  /// `assets/sounds/zibo_tap_sound.wav`).
  Future<void> playZiboTap();

  /// Uygulama kapanırken/widget dispose edilirken native oynatıcı
  /// kaynaklarını serbest bırakır.
  void dispose();
}

class AudioPlayersSoundEffectsService extends SoundEffectsService {
  AudioPlayersSoundEffectsService()
    : _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  final AudioPlayer _player;

  @override
  Future<void> playZiboTap() async {
    try {
      // Önceki ses tam bitmeden yeni bir dokunuş gelirse ÖNCEKİNİ kesip
      // yeniden başlatıyoruz — kullanıcı isteği: art arda hızlı
      // tıklamalarda seslerin üst üste binip rahatsız edici olmaması için.
      // Ayrı bir debounce zamanlayıcısına gerek kalmadan bu tek `stop()` +
      // `play()` çifti yeterli.
      await _player.stop();
      await _player.play(AssetSource('sounds/zibo_tap_sound.wav'));
    } catch (_) {
      // Ses çalma altyapısı bu ortamda/cihazda kullanılamıyor — sessizce
      // devre dışı kalır, dokunma etkileşiminin geri kalanı (poz/söz
      // değişimi) etkilenmez.
    }
  }

  @override
  void dispose() => _player.dispose();
}

class FakeSoundEffectsService extends SoundEffectsService {
  const FakeSoundEffectsService();

  @override
  Future<void> playZiboTap() async {}

  @override
  void dispose() {}
}
