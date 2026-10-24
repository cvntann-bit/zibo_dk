// `audioplayers` platform katmanının testlerde KULLANILAN sahte sürümü.
//
// **Neden gerekli:** `AudioPlayersSoundEffectsService()` (ve onu oluşturan `CoinProvider`/ekranlar) kurucuda
// gerçek bir `AudioPlayer()` yaratır; bu, ASENKRON olarak `xyz.luan/audioplayers.global` kanalına `init`
// çağrısı yapar. `flutter test`'te bu kanalın native karşılığı olmadığı için `MissingPluginException` fırlar —
// kimsenin `await` etmediği bir Future'da, yani test bittikten SONRA, o sırada koşan HERHANGİ bir testi
// "başarısız" yapıyordu (bilinen "Zibo'ya dokununca söz değişir..." flake'i). Eklentinin kendi önerdiği yol:
// platform arayüzü örneğini sahtesiyle değiştirmek. Ses efektleri testte zaten duyulmuyor.
import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudioplayersPlatform implements AudioplayersPlatformInterface {
  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream<AudioEvent>.empty();

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<int?> getCurrentPosition(String playerId) async => null;

  // Kalan tüm yöntemler (create, setReleaseMode, play, stop, dispose…) sessizce başarılı olur.
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeGlobalAudioplayersPlatform implements GlobalAudioplayersPlatformInterface {
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream<GlobalAudioEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// `main()`'in başında (veya `setUpAll`'da) bir kez çağır.
void installFakeAudioplayersPlatform() {
  AudioplayersPlatformInterface.instance = _FakeAudioplayersPlatform();
  GlobalAudioplayersPlatformInterface.instance = _FakeGlobalAudioplayersPlatform();
}

/// **İkinci flake kaynağı:** `HomeWidgetPluginService.moduleClicked` (`HomeWidget.widgetClicked`) `home_widget/updates`
/// OLAY kanalını dinler; testte native karşılığı yok → "No implementation found for method listen on channel
/// home_widget/updates" `MissingPluginException`'ı (servis kütüphanesi hatası) test bittikten sonra bile sızıp testi
/// düşürüyordu. Kanal dinlemeyi sessizce kabul eden sahte bir akış işleyicisi kurar. Her testten ÖNCE çağır (`setUp`).
void installFakeHomeWidgetChannel() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('home_widget/updates'),
    MockStreamHandler.inline(onListen: (arguments, events) {}),
  );
}
