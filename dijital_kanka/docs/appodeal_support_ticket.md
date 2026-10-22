# Appodeal destek mesajı taslağı (2026-10-22) — banner hiç yüklenmiyor + init `SdkConfigurationError`

> Kullanıcı Appodeal destek paneline/e-postasına gönderir (Appodeal paneline bu ortamdan giriş yapılamıyor). Kanıtlar ÖLÇÜLMÜŞ veridir.

**Subject:** Banner never loads in production + `SdkConfigurationError` on every initialization (com.dijitalkanka.dijital_kanka)

Hello Appodeal team,

App: **Zibo Dijital Kanka** — package `com.dijitalkanka.dijital_kanka` (Android only, Flutter `stack_appodeal_flutter` 4.2.0, adapters: `applovin` 13.5.1.0 and `vungle` 7.6.1.0). Ad types initialized: Rewarded Video, Interstitial, Banner (embedded `AppodealBanner` / banner view, BANNER size).

**1) Banner never loads in production.** Over the last 28 days our app reported `onBannerFailedToLoad` **26,078 times for 1,061 users** (77% of our users, about 25 attempts per user) and **zero** `onBannerLoaded` / `onBannerShown`. Your dashboard also shows no banner revenue; Monetization shows 0 banner impressions. In the same period Rewarded works (fill 61–87%, eCPM ≈ $1.0) and Interstitial works (fill 13–37%).

**2) Initialization always finishes with an error.** `Appodeal.initialize(... onInitializationFinished)` returns an error on (almost) every launch: `InternalError: SdkConfigurationError` (message `null`). In production ~650 users / 7 days report it; I reproduced it on a Samsung SM-A226BR (Android, debug build, `Appodeal.setTesting(true)`, consent: "Presentation not required").

**3) Warning in logcat:** `ATTENTION: Adapters are not registered in your app: bidmachine`. We intentionally removed the BidMachine adapter (APK/DEX size). I tested adding `adapters:bidmachine:3.7.1.0` back: the warning disappears but **`SdkConfigurationError` remains**, so it is not caused by the missing adapter.

**Questions**
1. What exactly does `SdkConfigurationError` mean and what configuration is missing/invalid for this app?
2. Which networks are enabled for **Banner** for this app in the waterfall, and why do we get no banner requests/impressions at all? Is an AppLovin banner ad unit required/configured?
3. Is anything extra required in SDK 4.2.0 for banner placements (e.g. a specific banner view type, placement name, or the AppLovin/Vungle adapter versions we use)?
4. Please check our app configuration on your side and tell us the fix.

Thank you!
