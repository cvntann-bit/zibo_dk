# Proje Geçmişi Arşivi — İNDEKS

Bu klasör eski `CLAUDE.md`'nin (880 KB, ~9700 satır) feature-bazlı bölümlerinin BİREBİR kopyasıdır.
İçerik: implementasyon detayları, çözülmüş bug'ların kök nedenleri, "bu neden böyle yapıldı",
test gotcha'ları, gerçek cihaz doğrulama notları, terk edilmiş yaklaşımlar.

## ⚠️ Bu dosyalar OTOMATİK context'e YÜKLENMEZ ve yüklenmemeli

Root `CLAUDE.md` bunları `@import` ETMEZ. Yalnızca şu durumlarda **TEK ilgili dosyayı** aç:
- Eski bir bug'ın neden böyle çözüldüğünü araştırıyorsun
- Bir sistemin neden değiştirildiğini / eski implementasyonun ne olduğunu bilmen gerekiyor
- Regression araştırması yapıyorsun
- Kullanıcı açıkça geçmişi soruyor

**Asla tüm arşivi context'e yükleme.** Güncel gerçek → `docs/CURRENT_STATE.md`. Nasıl çalışıyor →
`docs/ARCHITECTURE.md`. Karar gerekçesi → `docs/decisions/`.

## Dosyalar

| Dosya | İçerik |
|---|---|
| `home-quotes-goals-coin-store.md` | Ana Sayfa, Motivasyon Sözü Sistemi (zaman/ruh-hali ağırlıklı), Olay Tetiklemeli Mesajlar, Ruh Hali Notu anahtar kelime çıkarımı, Söz Havuzu genişletmeleri, Konuşma Balonu, Hedef Takibi (7 günlük döngü, `GoalCompletion` arşivi), Zibo Coin ekonomisi, Mağaza (coin paketleri, TL fiyatları) |
| `costumes-poses-themes.md` | 16 Kostüm (fiyatlandırma, `localizedName` bug'ı), Zibo Poz/Animasyon Sistemi (dokunuşla ilerleme, GLOBAL boyut normalizasyonu, `width`→`height` geçişi), 22 Tema (statik + 7 premium/animasyonlu parçacık efektleri, `ColorScheme` uygulaması, `ThemeFadeOverlay`) |
| `wheel-dailyrewards-money.md` | Şans Çarkı (ağırlıklı ödül, katman görselleri, günlük sınır), Günlük Giriş Ödülleri (`reconcileForToday` çift-gereksinim, `notifyListeners` bug'ı, cihaz-saati anomalisi), Para ve Birikim (3 kategori, çoklu para birimi, fl_chart trend grafiği, widget senkron) |
| `settings-notifications-share-navigation.md` | Ayarlar (3 bölüm, ThemeMode, Bize Ulaşın, legal metinler, tester geri bildirimi), Yerel Bildirimler (RAFTA — MIUI 3-katmanlı azaltma tanısı), Zibonu Paylaş (9:16 kart, gradyan/font ön ayarları, `share_plus` path bug'ı — YANLIŞ hipotez), Alt Gezinme Çubuğu (kod-tabanlı yeniden yazım, Profil↔Birikim yer değiştirme, kostüme göre Z Coin teması) |
| `journal-modules-profile.md` | Rüya/Şükran/Ruh Hali/Su/Manifest Günlükleri (CRUD, coin farming korumaları, birim/ml/litre — litre KALDIRILDI), Manifest↔Profil fotoğrafı Crashlytics kök nedeni, Profil (İstatistiklerim 4 kategori + formüller + gauge animasyonu, "Zibo ile Bağın" 8 satır, Bond Level, Hitap Tercihi, Favori Sözler, Geçmiş Ay İstatistikleri arşivi) |
| `adfree-theme-splash-onboarding.md` | Zibo ADS reklamsız mockup (3 tetikleme yolu), Tema (`_mustard`/`_honey` palet, `ThemeFadeOverlay` vs `AnimatedTheme`), Açılış splash ekranı (`_AppStartupGate` 7 provider, markalı native splash), Onboarding (9→11 sayfa, isim→Profil+hitap, `ProfileProvider` yarış koşulu düzeltmesi) |
| `push-notifications-sounds.md` | FCM Push + GitHub Actions (5 betik, saat-dilimi dağıtımı, catch-up penceresi, çift-gönderim tanıları, `content.js` dil, `dedupeByFcmToken`), Anonim Auth temizlik betiği, Push Bildirimi Özel Sesi (`res/raw`, kanal önbelleği, R8 `keep.xml`), Zibo Dokunma Sesi + tüm ses efektleri |
| `celebrations-xp-focus-instagram-i18n-tools-tests.md` | Hedef Tamamlama Kutlaması (titreşim + konfeti patlaması + ses zamanlaması), Level/XP Sistemi (`50*L` eğrisi, `_earn` merkezi kancası), Odak Sayacı (immersive karanlık mod), Instagram Takip Kartı, Yerelleştirme (i18n) tam bölümü, Görsel işleme (`tool/`), Test kalıpları ve tüm `flutter_test` tuzakları, "Şu an mock olan şeyler" |
| `ads-monetization-appodeal.md` | AdMob entegrasyon geçmişi (test→gerçek ID, hesap ban itirazı), AdMob→Appodeal geçişi (`stack_appodeal_flutter`, Gradle, Completer köprüsü), Appodeal Console onboarding + Unity Ads adaptörü, Reklamlar tam ekranı kaplamıyor (Android 15 `AdActivity` tema + blur yedek), Art arda dokunma → interstitial / Zibo ADS |
| `backend-auth-security-referral.md` | Firestore veri kalıcılığı + `CloudStateStore` (3 migrasyon varyantı), Güvenilir zaman (`_verifiedThisSession` bug'ı), Google Hesap Bağlama (UZUN bug zinciri: `google_sign_in` v7, SHA-1 App Signing Key, R8 `default_web_client_id`, `idToken == null`), Coin Ekonomisi Güvenliği (`firestore.rules` kısmi doğrulama), Davet Et (referral) sistemi |
| `founder-badge-iap-release-crashlytics.md` | Kurucu Üye Rozeti (ilk 500 KAYIT → Google'a bağlanan ilk 500, CANLI Firestore transaction sayacı, `initFounderBadgeCounter.js` seed, reconcile-on-resume), Google Play Billing/IAP (`buyConsumable`, orphaned purchase, Play Console ürün kurulumu), Release İmzalama (upload keystore, `proguard-rules.pro`, WorkManager/Room `-keep` çökmesi), Crashlytics (AGP 9.0 DSL gotcha'sı, test çökmesi) |
| `home-widgets.md` | Ana Ekran Widget'ları — TÜM turlar: klasik RemoteViews seçimi, 8→5 widget, carousel'ler (`ViewFlipper`), görsel yeniden tasarımlar (denenip reddedilen: Z-desen dokusu, 4-kare sahne animasyonu), RemoteViews inflate whitelist çökmeleri (ham `<View>`, `ProgressBar` tint), MIUI `requestPinAppWidget` no-op, `previewImage` PNG üretimi (gerçek cihazda), dil senkronu yarış koşulu, deep-link |
| `badge-system.md` | Rozet Sistemi — TÜM 6 kategori tur tur (İstikrar/Modül Ustalığı/Koleksiyon/Sadakat/Sosyal/Gizli), `AppStreakProvider`, `BadgeCoordinator` (13→14 provider dinleme), `BadgeCelebrationOverlay` (`rootNavigatorKey`, `late final` çökmesi), kazanma sesi, "Tema Avcısı tekrar tekrar çıkma" yarış koşulu (`isReady` guard'ı), Hedef Takibi ardışık gün numaraları + haftalık farming koruması, Kostüm/Tema Hediye Sistemi (eski "tüm kostümler hedefle açılır" KALDIRILDI) |
| `_full-snapshot-2026-09.md` | Eski `CLAUDE.md`'nin frozen tam kopyası (bölünmemiş) — üstteki 13 dosyada bir şey eksik/bozuksa buradan kurtar. |
