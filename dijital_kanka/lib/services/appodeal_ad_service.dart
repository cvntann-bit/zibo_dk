import 'dart:async';

import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

import '../utils/ad_overlay_state.dart';
import 'ad_service.dart';

/// Appodeal SDK (`stack_appodeal_flutter`) ile gerçek bir ödüllü reklam
/// (rewarded video) VE geçiş reklamı (interstitial) gösteren implementasyon
/// — bkz. [AdService] dokümantasyonu. `AdMobAdService`'in (bkz. CLAUDE.md
/// "AdMob Entegrasyonu" bölümü) YERİNE geçti — AdMob hesabının "related
/// account" politika ihlaliyle devre dışı bırakılması üzerine, Appodeal'ın
/// bir mediation platformu olması (tek bir ağa bağımlı olmama) tercih
/// edildi.
///
/// **Mimari farkı — Appodeal'ın callback'leri AdMob'un AKSİNE GLOBAL/SDK
/// seviyesinde, her `show()` çağrısına ÖZEL değil.** AdMob'da her reklam
/// örneği kendi `FullScreenContentCallback`'ini taşırken, Appodeal
/// `setRewardedVideoCallbacks`/`setInterstitialCallbacks`'i BİR KEZ (bu
/// servisin constructor'ında) kaydediyor — bu yüzden `showRewardedAd()`/
/// `showInterstitialAd()` çağrıldığında, o ANKİ bekleyen isteği temsil eden
/// bir `Completer` bir alanda saklanıp, global callback'ler bu alanı görüp
/// tamamlıyor (`_rewardedCompleter`/`_interstitialCompleter`) — bir
/// "Completer-tabanlı köprü" deseni.
///
/// **Ön-yükleme YOK — Appodeal kendi arka plan yüklemesini KENDİSİ
/// yönetiyor** (AdMob'un aksine, `RewardedAd.load(...)`'u elle
/// tetiklememiz gerekmiyor — `Appodeal.initialize(...)` çağrıldıktan sonra
/// SDK ilgili `adTypes` için sürekli arka planda reklam yüklemeye devam
/// ediyor). Bu yüzden `showX()` yalnızca `Appodeal.isLoaded(...)`'u kısa bir
/// zaman aşımıyla (8sn, AdMob'daki AYNI süre) polling ile bekliyor.
class AppodealAdService extends AdService {
  AppodealAdService() {
    _registerCallbacks();
  }

  Completer<bool>? _rewardedCompleter;
  Completer<bool>? _interstitialCompleter;

  void _registerCallbacks() {
    Appodeal.setRewardedVideoCallbacks(
      onRewardedVideoShowFailed: () {
        isAdShowing.value = false;
        _complete(_rewardedCompleter, false);
      },
      // Kullanıcı videoyu sonuna kadar izleyip ödülü hak ettiğinde tetiklenir
      // — `onRewardedVideoClosed`'dan ÖNCE gelir, bu yüzden ödül burada
      // `true`ya sabitleniyor.
      onRewardedVideoFinished: (amount, reward) {
        _complete(_rewardedCompleter, true);
      },
      // Kullanıcı reklamı KAPATTIĞINDA (erken çıksa da/videoyu bitirse de)
      // tetiklenir — `onRewardedVideoFinished` zaten `true`ya tamamladıysa
      // bu no-op (Completer zaten tamamlanmış); erken kapatılırsa
      // `isFinished == false` ile ödül reddedilir.
      onRewardedVideoClosed: (isFinished) {
        isAdShowing.value = false;
        _complete(_rewardedCompleter, isFinished);
      },
    );

    Appodeal.setInterstitialCallbacks(
      onInterstitialShowFailed: () {
        isAdShowing.value = false;
        _complete(_interstitialCompleter, false);
      },
      // Ödüllü reklamdan farklı olarak burada bir "ödül" kavramı yok —
      // reklam GÖSTERİLDİYSE (kapatıldığında) `true`.
      onInterstitialClosed: () {
        isAdShowing.value = false;
        _complete(_interstitialCompleter, true);
      },
    );
  }

  void _complete(Completer<bool>? completer, bool value) {
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  /// `Appodeal.isLoaded(adType)`'i kısa aralıklarla (300ms) [timeout] dolana
  /// kadar sorguluyor — SDK arka planda kendi kendine yüklüyor, biz yalnızca
  /// "hazır mı?" diye bekliyoruz (AdMob'daki `RewardedAd.load(...)`'un
  /// AKSİNE burada bir yükleme TETİKLEMİYORUZ).
  Future<bool> _waitUntilLoaded(
    AppodealAdType type, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final loaded = await Appodeal.isLoaded(type).catchError((_) => false);
      if (loaded) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return Appodeal.isLoaded(type).catchError((_) => false);
  }

  @override
  Future<bool> showRewardedAd() async {
    try {
      if (!await _waitUntilLoaded(AppodealAdType.RewardedVideo)) return false;

      final completer = Completer<bool>();
      _rewardedCompleter = completer;

      // Reklam Activity'si açılmadan HEMEN ÖNCE — bkz. `AdMobAdService`'teki
      // AYNI `isAdShowing`/`AdBlurOverlay` notu.
      isAdShowing.value = true;
      final triggered = await Appodeal.show(AppodealAdType.RewardedVideo);
      if (!triggered) {
        isAdShowing.value = false;
        return false;
      }

      final earned = await completer.future;
      isAdShowing.value = false;
      return earned;
    } catch (_) {
      isAdShowing.value = false;
      return false;
    }
  }

  @override
  Future<bool> showInterstitialAd() async {
    try {
      if (!await _waitUntilLoaded(AppodealAdType.Interstitial)) return false;

      final completer = Completer<bool>();
      _interstitialCompleter = completer;

      isAdShowing.value = true;
      final triggered = await Appodeal.show(AppodealAdType.Interstitial);
      if (!triggered) {
        isAdShowing.value = false;
        return false;
      }

      final shown = await completer.future;
      isAdShowing.value = false;
      return shown;
    } catch (_) {
      isAdShowing.value = false;
      return false;
    }
  }
}
