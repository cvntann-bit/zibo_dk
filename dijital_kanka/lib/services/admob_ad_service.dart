import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Google AdMob SDK'sı (`google_mobile_ads`) ile gerçek bir ödüllü reklam
/// (rewarded video) gösteren implementasyon — bkz. [AdService] dokümantasyonu.
///
/// **Reklam birimi ID'leri:** Varsayılan olarak Google'ın HERKESE AÇIK,
/// hesap gerektirmeyen resmi test reklam birimini ([testRewardedAdUnitId])
/// kullanır — bu, gerçek bir AdMob hesabı/onayı olmadan da SDK'nın uçtan
/// uca (yükleme → gösterim → ödül) gerçekten çalıştığını doğrulamak için.
/// **Gerçek yayına geçmeden önce** kullanıcının kendi AdMob Console'undan
/// aldığı gerçek Ödüllü Reklam birimi ID'si `rewardedAdUnitId` parametresiyle
/// verilmeli (bkz. CLAUDE.md "AdMob Entegrasyonu" bölümü) — test ID'siyle
/// canlıya çıkmak Google'ın politikasını ihlal eder ve gerçek gelir üretmez.
///
/// **Ön-yükleme (preload) deseni:** Ödüllü reklamlar AdMob'da ÖNCEDEN
/// yüklenmesi gereken bir format — `showRewardedAd()` çağrıldığı anda
/// sıfırdan yüklemeye başlamak kullanıcıyı saniyelerce bekletirdi. Bu yüzden
/// servis constructor'da VE her gösterimden hemen sonra arka planda bir
/// sonraki reklamı önceden yüklemeye başlar; `showRewardedAd()` çağrıldığında
/// genellikle zaten hazır bir reklam bulur, yalnızca henüz yüklenmemişse
/// (ör. ilk çağrı ya da çok hızlı art arda iki kez izlenirse) kısa bir
/// zaman aşımıyla (8sn) bekler.
class AdMobAdService extends AdService {
  AdMobAdService({String? rewardedAdUnitId, String? interstitialAdUnitId})
    : _adUnitId = rewardedAdUnitId ?? testRewardedAdUnitId,
      _interstitialAdUnitId =
          interstitialAdUnitId ?? testInterstitialAdUnitId {
    _loadAd();
    _loadInterstitialAd();
  }

  /// Google'ın resmi, herkese açık Android Ödüllü Reklam test birimi —
  /// bkz. https://developers.google.com/admob/android/test-ads.
  static const testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Google'ın resmi, herkese açık Android Geçiş (interstitial) reklam test
  /// birimi — bkz. https://developers.google.com/admob/android/test-ads.
  /// [interstitialAdUnitId] verilmediği sürece (kullanıcı henüz AdMob
  /// Console'dan gerçek bir Geçiş reklam birimi OLUŞTURMADI) kullanılır —
  /// `rewardedAdUnitId`'nin ilk sürümündeki AYNI geçici durum, bkz.
  /// CLAUDE.md "AdMob Entegrasyonu" bölümü.
  static const testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  final String _adUnitId;
  final String _interstitialAdUnitId;
  RewardedAd? _rewardedAd;
  Completer<void>? _pendingLoad;
  InterstitialAd? _interstitialAd;
  Completer<void>? _pendingInterstitialLoad;

  Future<void> _loadAd() {
    final pending = _pendingLoad;
    if (pending != null) return pending.future;
    if (_rewardedAd != null) return Future.value();

    final completer = Completer<void>();
    _pendingLoad = completer;
    void failSilently([Object? error, StackTrace? stackTrace]) {
      // SDK başlatılmadıysa/platform kanalı yoksa (ör. flutter_test ortamı)
      // — sessizce başarısız ol, showRewardedAd() aşağıda false dönecek.
      _rewardedAd = null;
      _pendingLoad = null;
      if (!completer.isCompleted) completer.complete();
    }

    try {
      // `RewardedAd.load(...)`'un döndürdüğü Future, platform kanalı
      // hatalarını (ör. testte hiç kayıtlı handler yok) fırlatabiliyor —
      // bu Future'ı `await`lemeden ateşleyip unutursak (fire-and-forget)
      // bu hata YAKALANAMAZ bir "unhandled Future rejection" olarak
      // Flutter test framework'üne sızar. `catchError` ile BURADA
      // yakalanması ŞART.
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _pendingLoad = null;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _pendingLoad = null;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      ).catchError(failSilently);
    } catch (error, stackTrace) {
      failSilently(error, stackTrace);
    }
    return completer.future;
  }

  @override
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      try {
        await _loadAd().timeout(const Duration(seconds: 8));
      } catch (_) {
        return false;
      }
    }
    final ad = _rewardedAd;
    if (ad == null) return false;
    // Tek kullanımlık — bir sonraki gösterim için hemen arkadan yeni bir
    // reklam yüklenmeye başlanacak (bkz. altta).
    _rewardedAd = null;

    final rewardCompleter = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        // Ödül zaten kazanılıp completer tamamlandıysa bu no-op'tur —
        // yalnızca kullanıcı ödülü kazanmadan (erken) kapatırsa false'a düşer.
        if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (adWithReward, reward) {
          if (!rewardCompleter.isCompleted) rewardCompleter.complete(true);
        },
      );
    } catch (_) {
      if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
    }

    final earned = await rewardCompleter.future;
    unawaited(_loadAd());
    return earned;
  }

  /// `_loadAd()` ile AYNI ön-yükleme deseni, `RewardedAd` yerine
  /// `InterstitialAd` için — ikisi SDK'da farklı sınıflar/yükleme API'leri
  /// olduğu için ayrı bir alan seti gerekiyor, ama mantık birebir aynı.
  Future<void> _loadInterstitialAd() {
    final pending = _pendingInterstitialLoad;
    if (pending != null) return pending.future;
    if (_interstitialAd != null) return Future.value();

    final completer = Completer<void>();
    _pendingInterstitialLoad = completer;
    void failSilently([Object? error, StackTrace? stackTrace]) {
      _interstitialAd = null;
      _pendingInterstitialLoad = null;
      if (!completer.isCompleted) completer.complete();
    }

    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _pendingInterstitialLoad = null;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _pendingInterstitialLoad = null;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      ).catchError(failSilently);
    } catch (error, stackTrace) {
      failSilently(error, stackTrace);
    }
    return completer.future;
  }

  @override
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      try {
        await _loadInterstitialAd().timeout(const Duration(seconds: 8));
      } catch (_) {
        return false;
      }
    }
    final ad = _interstitialAd;
    if (ad == null) return false;
    // Tek kullanımlık — bir sonraki gösterim için hemen arkadan yeni bir
    // reklam yüklenmeye başlanacak (bkz. altta).
    _interstitialAd = null;

    final shownCompleter = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        if (!shownCompleter.isCompleted) shownCompleter.complete(true);
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        if (!shownCompleter.isCompleted) shownCompleter.complete(false);
      },
    );

    try {
      await ad.show();
    } catch (_) {
      if (!shownCompleter.isCompleted) shownCompleter.complete(false);
    }

    final shown = await shownCompleter.future;
    unawaited(_loadInterstitialAd());
    return shown;
  }
}
