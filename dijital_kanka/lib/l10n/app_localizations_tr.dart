// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Zibo';

  @override
  String get homeAppBarTitle => 'Zibo';

  @override
  String coinBalanceLabel(int count) {
    return '$count Zibo Coin';
  }

  @override
  String get insufficientCoins => 'Yetersiz Zibo Coin';

  @override
  String get coinProBonusLabel => '1,5x Pro bonusu!';

  @override
  String get coinProPlusBonusLabel => '2x Pro+ bonusu!';

  @override
  String get historyLimitCardTitle => 'Daha eski kayıtlar Pro\'da';

  @override
  String get historyLimitCardSubtitle =>
      'Daha eski kayıtları görmek için Zibo Pro\'ya geç';

  @override
  String get historyLimitCardButton => 'Pro\'ya Geç';

  @override
  String get streakFreezeOfferTitle => 'Serin tehlikede!';

  @override
  String streakFreezeOfferBody(int streak) {
    return '$streak günlük serin kırılmak üzere! Streak Freeze kullanarak koruyabilirsin.';
  }

  @override
  String streakFreezeOfferFreeButton(int remaining, int quota) {
    return 'Ücretsiz Kullan ($remaining/$quota kaldı)';
  }

  @override
  String streakFreezeOfferCoinButton(int cost) {
    return '$cost ZC ile Kullan';
  }

  @override
  String get streakFreezeOfferDeclineButton => 'Vazgeç';

  @override
  String streakFreezeRepairedMessage(int streak) {
    return 'Serin kurtarıldı! $streak gün üst üste devam ediyor.';
  }

  @override
  String streakFreezeOfferOwnedButton(int count) {
    return 'Stoktan Kullan ($count adet var)';
  }

  @override
  String get streakFreezeStoreSectionTitle => 'Seri Koruması';

  @override
  String get streakFreezeStoreCardTitle => 'Streak Freeze';

  @override
  String streakFreezeStoreCardSubtitle(int count) {
    return 'Bir gün kaçırırsan serini korur · Stoğunda: $count';
  }

  @override
  String streakFreezePurchasedMessage(int count) {
    return 'Streak Freeze stoğuna eklendi! Artık $count adet var.';
  }

  @override
  String get streakFreezeBalanceTitle => 'Streak Freeze Stoğun';

  @override
  String streakFreezeBalanceHint(int price) {
    return 'Bir gün kaçırırsan serini korur. Mağaza\'dan $price ZC\'ye alabilirsin.';
  }

  @override
  String get ziboImagePlaceholder => 'Zibo';

  @override
  String get tapZiboHint => 'Yeni bir söz için Zibo\'ya dokun';

  @override
  String get tabHome => 'Ana Sayfa';

  @override
  String get tabGoalTracking => 'Hedef Takibi';

  @override
  String get bottomBarGoalsLabel => 'Hedefler';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String goalProgressLabel(int completed) {
    return '$completed/7 gün';
  }

  @override
  String goalDayToday(int day) {
    return 'Gün $day, bugün';
  }

  @override
  String goalDayDone(int day) {
    return 'Gün $day, tamamlandı';
  }

  @override
  String goalDayMissed(int day) {
    return 'Gün $day, kaçırıldı';
  }

  @override
  String goalDayFrozen(int day) {
    return 'Gün $day, Streak Freeze ile donduruldu';
  }

  @override
  String streakFreezeOfferGoalsLine(String goals) {
    return 'Dün şu hedeflerini de işaretlemedin: $goals. Streak Freeze o günü dondurur ❄️, hedeflerin sıfırlanmaz.';
  }

  @override
  String streakFreezeOfferGoalsOnlyBody(String goals) {
    return 'Dün şu hedeflerini işaretlemeyi kaçırdın: $goals. Streak Freeze kullanırsan o gün donar ❄️ ve hedeflerin sıfırlanmadan devam eder.';
  }

  @override
  String get streakFreezeGoalsRepairedMessage =>
      'Dünün donduruldu ❄️ Hedeflerin kaldığı yerden devam ediyor.';

  @override
  String goalDayUpcoming(int day) {
    return 'Gün $day, henüz açılmadı';
  }

  @override
  String get goalCycleCompleted =>
      'Harika! 7 günlük hedefi tamamladın, +50 Zibo Coin kazandın.';

  @override
  String goalStreakReset(String goalNames) {
    return '$goalNames hedefinde bir gün kaçırıldı, seri sıfırlandı. Bugünden yeniden başlıyoruz.';
  }

  @override
  String get addGoalButton => 'Yeni Hedef Ekle';

  @override
  String get addGoalDialogTitle => 'Yeni Hedef';

  @override
  String get addGoalDialogHint => 'ör. Günde 30 dakika kitap oku';

  @override
  String get deleteGoalTooltip => 'Hedefi sil';

  @override
  String get completedGoalsButtonTooltip => 'Tamamlanan Hedefler';

  @override
  String get completedGoalsScreenTitle => 'Tamamlanan Hedefler';

  @override
  String get completedGoalsEmpty =>
      'Henüz tamamlanan bir hedef yok. İlk 7 günlük döngünü tamamlayınca burada görünecek!';

  @override
  String get completedGoalsBadgeLabel => '1 haftalık tamamlama';

  @override
  String completedGoalsGroupCount(int count) {
    return '$count tamamlama';
  }

  @override
  String completedGoalsDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsAbout => 'Uygulama Hakkında';

  @override
  String get settingsDarkTheme => 'Koyu Tema';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsThemeModeLight => 'Açık';

  @override
  String get settingsThemeModeDark => 'Koyu';

  @override
  String get settingsThemeModeSystem => 'Sistemi Takip Et';

  @override
  String get settingsSoundEffects => 'Ses Efektleri';

  @override
  String get settingsProPlusSoundTitle => 'Bildirim Sesi';

  @override
  String get settingsProPlusSoundLockedSubtitle =>
      'Pro+\'a özel — geçmek için dokun';

  @override
  String get settingsProPlusSoundPreviewTooltip => 'Sesi dinle';

  @override
  String get settingsProPlusSoundDefault => 'Varsayılan';

  @override
  String settingsProPlusSoundOption(int number) {
    return 'Ses $number';
  }

  @override
  String get settingsSectionGeneral => 'Genel';

  @override
  String get settingsSectionSupport => 'Destek';

  @override
  String get settingsSectionPushNotifications => 'Push Bildirimleri';

  @override
  String get pushNotificationDailyMotivationTitle => 'Günlük Motivasyon';

  @override
  String get pushNotificationDailyMotivationSubtitle =>
      'Her sabah 9-11 arası rastgele bir motivasyon sözü al';

  @override
  String get pushNotificationStreakReminderTitle => 'Streak Hatırlatması';

  @override
  String get pushNotificationStreakReminderSubtitle =>
      'Günü kaçırmak üzereysen akşam hatırlat';

  @override
  String get pushNotificationDailyRewardTitle => 'Günlük Ödül Hatırlatması';

  @override
  String get pushNotificationDailyRewardSubtitle =>
      'Günlük ödülünü almadıysan öğleden sonra hatırlat';

  @override
  String get pushNotificationReEngagementTitle => 'Seni Özledik';

  @override
  String get pushNotificationReEngagementSubtitle =>
      '2 gündür uğramadıysan Zibo seni özler';

  @override
  String get settingsContactUs => 'Bize Ulaşın';

  @override
  String get settingsRateUs => 'Bizi Puanlayın';

  @override
  String get settingsRateUsSubtitle =>
      'Play Store\'da yıldız ver, Zibo\'nun gelişmesine yardımcı ol';

  @override
  String get rateUsSheetTitle => 'Zibo\'yu Seviyor musun?';

  @override
  String get rateUsSheetSubtitle =>
      'Yıldızlara dokun, Play Store\'da bizi değerlendir!';

  @override
  String get ratePromptTitle => 'Zibo\'yla Aran Nasıl?';

  @override
  String get ratePromptBody =>
      'Google Play\'de birkaç yıldız ve kısa bir yorum, Zibo\'nun daha çok kankaya ulaşmasını sağlar.';

  @override
  String get ratePromptStarHint => 'Bir yıldıza dokun';

  @override
  String get ratePromptRateButton => 'Google Play\'de Puanla';

  @override
  String get ratePromptLaterButton => 'Daha Sonra';

  @override
  String get ratePromptAlreadyRatedButton => 'Zaten puanladım';

  @override
  String ratePromptStarLabel(int count) {
    return '$count yıldız';
  }

  @override
  String get settingsVersion => 'Sürüm';

  @override
  String get settingsWebsite => 'Web Sitesi';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsTermsOfService => 'Kullanım Koşulları';

  @override
  String get settingsLegalPlaceholderBody => 'Bu içerik yakında burada olacak.';

  @override
  String get settingsCouldNotOpenLink => 'Açılamadı, lütfen tekrar deneyin.';

  @override
  String get tabMoney => 'Para ve Birikim';

  @override
  String get bottomBarMoneyLabel => 'Birikim';

  @override
  String get moneyModuleDescription =>
      'Harcama, birikim ve gelen paranı takip et';

  @override
  String get moneyScreenTitle => 'Harcamalar ve Birikimler';

  @override
  String get moneyExpenses => 'Harcamalar';

  @override
  String get moneySavings => 'Birikimler';

  @override
  String get moneyIncome => 'Gelen Para';

  @override
  String get moneyTrendSectionTitle => 'Mevcut Durum';

  @override
  String get moneyAdvancedAnalysisTitle => 'Gelişmiş Analiz';

  @override
  String get moneyAdvancedAnalysisAvgExpense => 'Ortalama Aylık Harcama';

  @override
  String get moneyAdvancedAnalysisAvgSaving => 'Ortalama Aylık Birikim';

  @override
  String get moneyAdvancedAnalysisTopExpense => 'En Çok Harcadığın Kalem';

  @override
  String get moneyAdvancedAnalysisEmpty =>
      'Analiz için henüz yeterli veri yok.';

  @override
  String get lockedChartCta => 'Zibo Pro+\'a Bugün Geç';

  @override
  String get moneyExpenseBreakdownTitle => 'Harcama Dağılımı';

  @override
  String get moneyExpenseOtherLabel => 'Diğer';

  @override
  String get moneyCurrencyTotalsTitle => 'Para Birimlerine Göre';

  @override
  String get moneyTrendEmpty =>
      'Trend grafiği için henüz yeterli veri yok. Harcama veya birikim ekleyince burada görünecek.';

  @override
  String get moneyTrendExpenseLegend => 'Harcama';

  @override
  String get moneyTrendSavingLegend => 'Birikim';

  @override
  String get moneyTrendGranularityDaily => 'Günlük';

  @override
  String get moodTrendTitle => 'Ruh Hali Trendi';

  @override
  String get moodTrendGranularityWeek => 'Haftalık';

  @override
  String get moodTrendGranularityMonth => 'Aylık';

  @override
  String get moodTrendEmptyState =>
      'Trend grafiği için henüz yeterli ruh hali kaydı yok.';

  @override
  String get moneyTrendGranularityWeekly => 'Haftalık';

  @override
  String get moneyTrendGranularityMonthly => 'Aylık';

  @override
  String get moneyEmptyCategory => 'Henüz kayıt yok';

  @override
  String get moneyAddEntryButton => 'Ekle';

  @override
  String get moneyAddEntryTitle => 'Yeni Kayıt';

  @override
  String get moneyEditEntryTitle => 'Kaydı Düzenle';

  @override
  String get moneyEntryNameHint => 'Ad';

  @override
  String get moneyEntryAmountHint => 'Tutar';

  @override
  String get moneyEntryCurrencyLabel => 'Para Birimi';

  @override
  String get moneyDeleteEntryTooltip => 'Kaydı sil';

  @override
  String get moneyCurrencyTooltip => 'Para birimi';

  @override
  String get moneyCurrencyPickerTitle => 'Para Birimi Seç';

  @override
  String moneyCategoryTotal(String amount) {
    return 'Toplam: $amount';
  }

  @override
  String get storeButtonTooltip => 'Coin satın al';

  @override
  String get storeTitle => 'Mağaza';

  @override
  String get storeAdFreeSectionTitle => 'Reklamsız Zibo';

  @override
  String get storeAdFreeCardTitle => 'Reklamları Kaldır';

  @override
  String get storeAdFreeCardSubtitle => 'Tüm reklamları kalıcı olarak kapat';

  @override
  String get storeAdFreeCardPurchasedLabel => 'Satın Alındı';

  @override
  String get storePackagesSectionTitle => 'Coin Paketleri';

  @override
  String storeCoinAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String storeCoinBonus(int amount) {
    return '+$amount bonus';
  }

  @override
  String get storeBuyButton => 'Satın Al';

  @override
  String get storeFreeSectionTitle => 'Ücretsiz';

  @override
  String get storeWatchAdTitle => 'Reklam İzle';

  @override
  String storeWatchAdSubtitle(int amount) {
    return '$amount Zibo Coin kazan, tamamen ücretsiz';
  }

  @override
  String get storeWatchAdButton => 'İzle';

  @override
  String get dailyAdLimitReachedMessage =>
      'Bugünkü hakların bitti, yarın tekrar gel!';

  @override
  String storeCoinsAdded(int amount) {
    return '$amount Zibo Coin hesabına eklendi!';
  }

  @override
  String get storePurchaseFailedMessage =>
      'Satın alma tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get shareButtonTooltip => 'Bu sözü paylaş';

  @override
  String get favoriteQuoteAddTooltip => 'Bu sözü favorile';

  @override
  String get favoriteQuoteRemoveTooltip => 'Favorilerden çıkar';

  @override
  String get shareSheetTitle => 'Zibonu Paylaş';

  @override
  String get shareBackgroundLabel => 'Arka plan';

  @override
  String get shareTextStyleLabel => 'Yazı Stili';

  @override
  String get shareActionButton => 'Paylaş';

  @override
  String get shareErrorMessage => 'Paylaşım başlatılamadı, tekrar dener misin?';

  @override
  String get storeCoinsTabLabel => 'Coin Al';

  @override
  String get storeCostumesTabLabel => 'Kostümler';

  @override
  String get costumeNameZiboHippi => 'Hippi Zibo';

  @override
  String get costumeNameZiboSporcu => 'Sporcu Zibo';

  @override
  String get costumeNameZiboAsker => 'Asker Zibo';

  @override
  String get costumeNameZiboHoca => 'Hoca Zibo';

  @override
  String get costumeNameZiboPunk => 'Punk Zibo';

  @override
  String get costumeNameZiboRapci => 'Rapçi Zibo';

  @override
  String get costumeNameZiboGladyator => 'Gladyatör Zibo';

  @override
  String get costumeNameZiboKorsan => 'Korsan Zibo';

  @override
  String get costumeNameZiboZombi => 'Zombi Zibo';

  @override
  String get costumeNameZiboAltin => 'Altın Zibo';

  @override
  String get costumeNameZiboElmas => 'Elmas Kaplama Zibo';

  @override
  String get costumeNameZiboGentleman => 'Centilmen Zibo';

  @override
  String get costumeNameZiboSamurai => 'Samuray Zibo';

  @override
  String get costumeNameZiboCyborg => 'Siborg Zibo';

  @override
  String get costumeNameZiboAstronot => 'Astronot Zibo';

  @override
  String get costumeNameZiboKing => 'Kral Zibo';

  @override
  String get costumeOwnedBadge => 'Sahip olunan';

  @override
  String get costumeEquippedBadge => 'Giyili';

  @override
  String costumePurchasedMessage(String name) {
    return '$name satın alındı!';
  }

  @override
  String costumeLockedSemanticLabel(String name, int price) {
    return '$name, kilitli, $price Zibo Coin';
  }

  @override
  String costumeEquipSemanticLabel(String name) {
    return '$name giy';
  }

  @override
  String costumeUnequipSemanticLabel(String name) {
    return '$name çıkar';
  }

  @override
  String costumeUnlockViaStreak(int current, int target) {
    return '🎯 $current/$target gün seri ile ücretsiz aç';
  }

  @override
  String costumeUnlockViaCompletions(int current, int target) {
    return '🎯 $current/$target hedef tamamlayarak ücretsiz aç';
  }

  @override
  String costumeUnlockViaWater(int current, int target) {
    return '🎯 $current/$target gün su takibiyle ücretsiz aç';
  }

  @override
  String costumeUnlockedViaGoalMessage(String name) {
    return '🎉 $name hedefini tamamlayarak ücretsiz açtın!';
  }

  @override
  String get storeThemesTabLabel => 'Temalar';

  @override
  String get storeProTabLabel => 'Zibo Pro';

  @override
  String get adFreePromoTitle => 'Zibo ADS';

  @override
  String get adFreePromoSubtitle => 'Reklamsız Deneyim';

  @override
  String get adFreePromoBenefitNoAds => 'Reklam yok';

  @override
  String get adFreePromoBenefitUninterrupted => 'Kesintisiz kullanım';

  @override
  String get adFreePromoBenefitSupport => 'Zibo\'ya destek ol';

  @override
  String get adFreePromoBuyButton => 'Satın Al';

  @override
  String get adFreePromoDismissButton => 'Belki Sonra';

  @override
  String get adFreePromoComingSoon =>
      'Yakında! Reklamsız deneyim çok yakında sunulacak.';

  @override
  String get adFreePromoPurchaseSuccess =>
      'Teşekkürler! Artık reklam görmeyeceksin.';

  @override
  String get adFreePromoPurchaseFailed =>
      'Satın alma tamamlanamadı, lütfen tekrar dene.';

  @override
  String get adFreePromoPurchaseFailedDismissButton => 'Tamam';

  @override
  String get themeNameSunset => 'Gün Batımı';

  @override
  String get themeNameOcean => 'Okyanus';

  @override
  String get themeNameForest => 'Orman';

  @override
  String get themeNameNightSky => 'Gece Gökyüzü';

  @override
  String get themeNameGoldenAge => 'Altın Çağ';

  @override
  String get themeNameWinterSnow => 'Kış Teması';

  @override
  String get themeNameGalaxyStars => 'Galaksi';

  @override
  String get themeNamePartyConfetti => 'Parti Konfeti';

  @override
  String get themeNameHeartsLove => 'Kalpli Tema';

  @override
  String get themeNameMusicNotes => 'Nota Teması';

  @override
  String get themeNameTropicalParadise => 'Tropikal Tema';

  @override
  String get themeNameCherryBlossom => 'Çiçekli Tema';

  @override
  String get themeNameLavenderGarden => 'Lavanta Bahçesi';

  @override
  String get themeNameCoralReef => 'Mercan Resifi';

  @override
  String get themeNameCherryOrchard => 'Vişne Bahçesi';

  @override
  String get themeNameMintGreens => 'Nane Yeşillikleri';

  @override
  String get themeNameDesertDunes => 'Çöl Kumulları';

  @override
  String get themeNameMoonlight => 'Ay Işığı';

  @override
  String get themeNameCopperHills => 'Bakır Tepeler';

  @override
  String get themeNameEmeraldValley => 'Zümrüt Vadisi';

  @override
  String get themeNameAmethystCave => 'Ametist Mağarası';

  @override
  String get themeNameDustyRoseDream => 'Gül Kurusu Rüyası';

  @override
  String get storeThemesStandardSectionTitle => 'Standart Temalar';

  @override
  String get storeThemesPremiumSectionTitle => 'Premium / Animasyonlu';

  @override
  String get storeThemesPremiumSectionSubtitle =>
      'Ekranında hafif bir hareket efekti olan özel temalar';

  @override
  String get themeOwnedBadge => 'Sahip olunan';

  @override
  String get themeActiveBadge => 'Aktif';

  @override
  String themePurchasedMessage(String name) {
    return '$name teması satın alındı!';
  }

  @override
  String themeLockedSemanticLabel(String name, int price) {
    return '$name teması, kilitli, $price Zibo Coin';
  }

  @override
  String themeApplySemanticLabel(String name) {
    return '$name temasını uygula';
  }

  @override
  String themeRemoveSemanticLabel(String name) {
    return '$name temasını kaldır';
  }

  @override
  String get wheelTriggerTooltip => 'Şans Çarkı';

  @override
  String get wheelTitle => 'Şans Çarkı';

  @override
  String get wheelSpinButton => 'Reklam İzle\nve Çevir';

  @override
  String get wheelCloseTooltip => 'Kapat';

  @override
  String get wheelResultTitle => 'Tebrikler!';

  @override
  String wheelResultMessage(int amount) {
    return '$amount Zibo Coin kazandın!';
  }

  @override
  String get wheelResultButton => 'Harika!';

  @override
  String get dailyRewardsTriggerTooltip => 'Günlük Ödüller';

  @override
  String get dailyRewardsTitle => 'Günlük Giriş Ödülleri';

  @override
  String get dailyRewardsCloseTooltip => 'Kapat';

  @override
  String dailyRewardsDayLabel(int day) {
    return 'Gün $day';
  }

  @override
  String dailyRewardsPromptToday(int day, int amount) {
    return 'Bugünün ödülünü almak için Gün $day kutusuna dokun: $amount Zibo Coin!';
  }

  @override
  String dailyRewardsAlreadyClaimedToday(int amount) {
    return 'Bugün $amount Zibo Coin aldın! Yarın tekrar gel.';
  }

  @override
  String dailyRewardsClaimedSemanticLabel(int day, int amount) {
    return 'Gün $day, $amount Zibo Coin alındı';
  }

  @override
  String dailyRewardsClaimSemanticLabel(int day, int amount) {
    return 'Gün $day ödülünü al, $amount Zibo Coin';
  }

  @override
  String dailyRewardsLockedSemanticLabel(int day, int amount) {
    return 'Gün $day, henüz açılmadı, $amount Zibo Coin';
  }

  @override
  String get notificationsSectionTitle => 'Bildirimler';

  @override
  String get notificationFrequencyOff => 'Kapalı';

  @override
  String get notificationFrequencyOnce => 'Günde 1';

  @override
  String get notificationFrequencyThrice => 'Günde 3';

  @override
  String get notificationSlotMorning => 'Sabah';

  @override
  String get notificationSlotNoon => 'Öğlen';

  @override
  String get notificationSlotEvening => 'Akşam';

  @override
  String get notificationReliabilityTitle =>
      'Bildirimlerin güvenilir gelmesi için';

  @override
  String get notificationBatteryOptimizationWarning =>
      'Pil optimizasyonu bildirimleri geciktirebilir';

  @override
  String get notificationBatteryOptimizationOk => 'Pil optimizasyonu kapalı';

  @override
  String get notificationBatteryOptimizationButton => 'Kapat';

  @override
  String get notificationAutostartDescription =>
      'Bazı telefonlarda (Xiaomi, Huawei, Oppo, Vivo gibi) bildirimlerin gelmesi için ayrıca \"otomatik başlatma\" izni gerekir';

  @override
  String get notificationUnusedAppsDescription =>
      'Telefon, uygulamayı \"kullanılmıyor\" sayıp bildirimleri durdurabilir — bu ayarı da kapatmak gerekebilir';

  @override
  String get notificationUnusedAppsButton => 'Ayarları Aç';

  @override
  String get notificationAutostartButton => 'Ayarları Aç';

  @override
  String get dreamJournalTooltip => 'Rüya Günlüğü';

  @override
  String get dreamJournalTitle => 'Rüya Günlüğü';

  @override
  String get dreamAddButton => 'Yeni Rüya Ekle';

  @override
  String get dreamEmptyState =>
      'Henüz bir rüya yazmadın. Bugün gördüğün bir rüya var mı?';

  @override
  String get dreamMoodCorrelationNote => 'O gün ruh halin de düşüktü 😔';

  @override
  String get dreamTitleHint => 'Başlık';

  @override
  String get dreamTextHint => 'Rüyanı anlat...';

  @override
  String get dreamSaveButton => 'Kaydet';

  @override
  String get dreamNewEntryTitle => 'Yeni Rüya';

  @override
  String get dreamEditEntryTitle => 'Rüyayı Düzenle';

  @override
  String get dreamDeleteEntryTooltip => 'Sil';

  @override
  String get dreamDeleteConfirmTitle => 'Rüyayı sil?';

  @override
  String get dreamDeleteConfirmBody => 'Bu rüya kalıcı olarak silinecek.';

  @override
  String get dreamDeleteConfirmButton => 'Sil';

  @override
  String get gratitudeSettingsTitle => 'Şükran Günlüğü';

  @override
  String get gratitudeScreenTitle => 'Şükran Günlüğü';

  @override
  String gratitudeFieldLabel(int n) {
    return '$n. Şükran cümlen';
  }

  @override
  String get gratitudeSaveButton => 'Kaydet';

  @override
  String get gratitudeTodayDoneTitle => 'Bugün tamamlandı!';

  @override
  String get gratitudeTodayDoneBody =>
      '3 şükran cümleni yazdın ve 5 Zibo Coin kazandın. Yarın tekrar gel!';

  @override
  String get gratitudeHistoryTitle => 'Geçmiş Kayıtlar';

  @override
  String get gratitudeHistoryEmpty => 'Henüz tamamlanmış bir kayıt yok.';

  @override
  String get gratitudeCoinRewardMessage => '+5 Zibo Coin kazandın!';

  @override
  String get gratitudeEntryDetailCloseButton => 'Kapat';

  @override
  String get gratitudeEditTooltip => 'Düzenle';

  @override
  String get moodSettingsTitle => 'Günlük Ruh Hali Takibi';

  @override
  String get moodScreenTitle => 'Günlük Ruh Hali Takibi';

  @override
  String get moodWeekSummaryTitle => 'Son 7 Gün';

  @override
  String get moodHistoryTitle => 'Geçmiş';

  @override
  String get moodNoteHint =>
      'Bugün nasıl hissettiğini kısaca yazabilirsin (opsiyonel)';

  @override
  String get moodHistoryEmpty => 'Henüz bir kayıt yok.';

  @override
  String get moodLabelVeryUnhappy => 'Çok kötü';

  @override
  String get moodLabelUnhappy => 'Kötü';

  @override
  String get moodLabelNeutral => 'Nötr';

  @override
  String get moodLabelHappy => 'İyi';

  @override
  String get moodLabelVeryHappy => 'Çok iyi';

  @override
  String get modulesMenuZButtonTooltip => 'Ek modülleri aç';

  @override
  String get modulesMenuTitle => 'Ek Modüller';

  @override
  String get dreamModuleDescription => 'Gördüğün rüyaları yaz, geçmişini gör';

  @override
  String get gratitudeModuleDescription =>
      'Günde 3 şükran cümlesi yaz, Zibo Coin kazan';

  @override
  String get moodModuleDescription => 'Bugünkü ruh halini emoji ile işaretle';

  @override
  String get waterSettingsTitle => 'Su Takibi';

  @override
  String get waterModuleDescription =>
      'Günlük su hedefini bardak bardak takip et';

  @override
  String get waterScreenTitle => 'Su Takibi';

  @override
  String waterProgressLabel(int count, int goal, String unit) {
    return '$count/$goal $unit';
  }

  @override
  String waterProgressMl(int consumedMl, int goalMl) {
    return '$consumedMl ml / $goalMl ml';
  }

  @override
  String waterProgressMlShort(int ml) {
    return '$ml ml';
  }

  @override
  String get waterTrendTitle => 'Su Tüketimi Trendi';

  @override
  String get waterTrendEmptyState =>
      'Trend grafiği için henüz yeterli su takibi kaydı yok.';

  @override
  String get waterGoalRateTitle => 'Ortalama Hedef Tutturma';

  @override
  String waterGlassFilledLabel(int index, String unit) {
    return '$index. $unit, dolu';
  }

  @override
  String waterGlassEmptyLabel(int index, String unit) {
    return '$index. $unit, boş';
  }

  @override
  String get waterGoalCompletedMessage =>
      'Günlük su hedefini tamamladın! +5 Zibo Coin kazandın!';

  @override
  String get waterTodayCompleteBody =>
      'Bugün su hedefini tamamladın, harikasın kanka!';

  @override
  String get waterGoalSettingsTitle => 'Günlük Su Hedefi';

  @override
  String get waterGoalDialogTitle => 'Günlük Su Hedefi';

  @override
  String waterGoalDialogUnitCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get waterUnitGlass => 'bardak';

  @override
  String get waterUnitBottle => 'şişe';

  @override
  String get waterUnitSectionLabel => 'Birim';

  @override
  String waterMlPerUnitLabel(String unit) {
    return '1 $unit = kaç ml?';
  }

  @override
  String get waterHistoryTitle => 'Geçmiş';

  @override
  String get waterHistoryEmpty => 'Henüz geçmiş kayıt yok.';

  @override
  String get homeWidgetNewBadge => 'YENİ';

  @override
  String get homeWaterWidgetTitle => 'Su';

  @override
  String homeWaterRemainingLabel(int count, String unit) {
    return '$count $unit kaldı';
  }

  @override
  String get homeWaterCompleteLabel => 'Bugünkü hedef tamamlandı!';

  @override
  String get homeGoalWidgetTitle => 'Hedef';

  @override
  String get homeGoalCompleteLabel => 'Bugün hepsi tamam!';

  @override
  String get homeGoalEmptyLabel => 'Henüz hedef yok';

  @override
  String get homeQuickWidgetEditTooltip => 'Widget\'ı değiştir';

  @override
  String get homeQuickWidgetPickerTitle => 'Widget\'ı Değiştir';

  @override
  String get homeQuickWidgetDoneTodayLabel => 'Bugün eklendi';

  @override
  String get homeQuickWidgetNotDoneTodayLabel => 'Bugün henüz eklenmedi';

  @override
  String get homeMoodWidgetNotSetLabel => 'Henüz seçilmedi';

  @override
  String homeFocusWidgetTodayLabel(String duration) {
    return 'Bugün $duration odaklandın';
  }

  @override
  String get homeFocusWidgetNotDoneTodayLabel => 'Bugün henüz odaklanmadın';

  @override
  String waterHistoryCompletedEntry(String date) {
    return '$date tarihinde hedef tamamlandı';
  }

  @override
  String waterHistoryPartialEntry(String date, int count, int goal) {
    return '$date: $count/$goal';
  }

  @override
  String get manifestSettingsTitle => 'Manifest Günlüğü';

  @override
  String get manifestModuleDescription =>
      'Fotoğraf ve niyetinle günlük vizyon panonu oluştur';

  @override
  String get manifestScreenTitle => 'Manifest Günlüğü';

  @override
  String get manifestPhotoPickerHint => 'Bir fotoğraf seç';

  @override
  String get manifestPhotoSemanticLabel => 'Yüklenen fotoğraf';

  @override
  String get manifestIntentionHint => 'Bugün ne manifest etmek istiyorsun?';

  @override
  String get photoPickEmptyError =>
      'Bu fotoğraf okunamadı (dosya boş görünüyor). Telefonuna tamamen inmemiş bir bulut fotoğrafı olabilir, lütfen başka bir fotoğraf seç.';

  @override
  String get manifestSaveButton => 'Kaydet';

  @override
  String get manifestSavedMessage => 'Bugünün girişi kaydedildi.';

  @override
  String get manifestDeleteEntryTooltip => 'Sil';

  @override
  String get manifestDeleteConfirmTitle => 'Hayalini silmek istiyor musun?';

  @override
  String get manifestDeleteConfirmBody => 'Bu kayıt kalıcı olarak silinecek.';

  @override
  String get manifestDeleteConfirmYes => 'Evet';

  @override
  String get manifestDeleteConfirmNo => 'Hayır';

  @override
  String get manifestCoinRewardMessage => '+5 Zibo Coin kazandın!';

  @override
  String get manifestHistoryTitle => 'Geçmiş Kayıtlar';

  @override
  String get manifestHistoryEmpty =>
      'Henüz bir kayıt yok. Bugün ilk vizyonunu ekle!';

  @override
  String get manifestDetailCloseButton => 'Kapat';

  @override
  String get manifestDecorateButton => '🎨 Süsle ve Paylaş';

  @override
  String get manifestDecorateNowButton => '🎨 Hemen Süsle';

  @override
  String get manifestCollageButton => '🧩 Kolaj Yap';

  @override
  String get manifestCollageTitle => 'Kolaj Yap';

  @override
  String get manifestEditorTabTemplate => 'Şablon';

  @override
  String get manifestEditorTabBackground => 'Arka Plan';

  @override
  String get manifestCollagePickTitle => 'Bu kutuya fotoğraf seç';

  @override
  String get manifestCollageFromManifests => 'Manifestlerimden';

  @override
  String get manifestCollageFromGallery => '📷 Telefon galerisinden seç';

  @override
  String get manifestCollageEmptyTile => 'Dokun, fotoğraf seç';

  @override
  String get manifestTemplateTwoStacked => '2\'li';

  @override
  String get manifestTemplateTwoSide => '2\'li yan';

  @override
  String get manifestTemplateThree => '3\'lü';

  @override
  String get manifestTemplateFour => '4\'lü';

  @override
  String get manifestTemplateSix => '6\'lı';

  @override
  String get manifestTemplatePolaroidWall => 'Polaroid';

  @override
  String get manifestBgCream => 'Krem';

  @override
  String get manifestBgHoney => 'Bal';

  @override
  String get manifestBgGold => 'Altın';

  @override
  String get manifestBgNight => 'Gece';

  @override
  String get manifestBgDots => 'Noktalı';

  @override
  String get manifestEditorTitle => 'Manifestini Süsle';

  @override
  String get manifestEditorShareButton => 'Paylaş';

  @override
  String get manifestEditorRatioPost => 'Gönderi';

  @override
  String get manifestEditorRatioSquare => 'Kare';

  @override
  String get manifestEditorRatioStory => 'Hikâye';

  @override
  String get manifestEditorTabFrame => 'Çerçeve';

  @override
  String get manifestEditorTabSticker => 'Sticker';

  @override
  String get manifestEditorTabText => 'Yazı';

  @override
  String get manifestFrameNone => 'Yok';

  @override
  String get manifestFramePolaroid => 'Polaroid';

  @override
  String get manifestFrameFilm => 'Film';

  @override
  String get manifestFrameWashi => 'Washi';

  @override
  String get manifestFrameGold => 'Altın';

  @override
  String get manifestFrameStars => 'Yıldızlı';

  @override
  String get manifestFrameHearts => 'Kalpli';

  @override
  String get manifestFrameNotebook => 'Defter';

  @override
  String get manifestFrameAlbum => 'Albüm';

  @override
  String get manifestFramePop => 'Pop';

  @override
  String get manifestFrameStamp => 'Pul';

  @override
  String get manifestFrameNeon => 'Neon';

  @override
  String get manifestFrameFloral => 'Çiçekli';

  @override
  String get manifestFrameNight => 'Gece Gökyüzü';

  @override
  String get manifestFrameRoyal => 'Kraliyet';

  @override
  String get manifestFrameZibo => 'Zibo\'lu';

  @override
  String get manifestEmojiGroupLuck => 'Manifest & şans';

  @override
  String get manifestEmojiGroupLove => 'Sevgi';

  @override
  String get manifestEmojiGroupNature => 'Doğa';

  @override
  String get manifestEmojiGroupGoals => 'Hedef & başarı';

  @override
  String get manifestEmojiGroupParty => 'Kutlama';

  @override
  String manifestEditorLockedPreview(int price) {
    return '🔒 Önizleme · $price ZC ile aç';
  }

  @override
  String manifestEditorUnlockTitle(String name) {
    return '$name çerçevesini aç';
  }

  @override
  String manifestEditorUnlockBody(int price) {
    return 'Bu çerçeveyi $price Zibo Coin ile kalıcı olarak açmak ister misin?';
  }

  @override
  String manifestEditorUnlockButton(int price) {
    return '$price ZC ile Aç';
  }

  @override
  String manifestEditorUnlockedMessage(String name) {
    return '$name çerçevesi artık senin! 🎉';
  }

  @override
  String manifestEditorCostumeLocked(String name) {
    return '$name kostümüne sahip olunca bu sticker açılır.';
  }

  @override
  String get manifestEditorCustomText => '✏️ Kendi yazın';

  @override
  String get manifestEditorCustomTextHint => 'Olumlaman';

  @override
  String get manifestEditorAddText => 'Ekle';

  @override
  String get manifestEditorColorLabel => 'Renk';

  @override
  String get manifestEditorDeleteSticker => 'Sil';

  @override
  String get manifestEditorResizeSticker => 'Büyüt veya küçült';

  @override
  String get manifestEditorExportTitle => 'Manifestin hazır! 🎉';

  @override
  String get manifestEditorExportPost => '4:5 · Instagram gönderisi için ideal';

  @override
  String get manifestEditorExportSquare => '1:1 · Kare, her yerde paylaşılır';

  @override
  String get manifestEditorExportStory =>
      '9:16 · Instagram ve WhatsApp hikâyesi';

  @override
  String get manifestEditorSaveToGallery => 'Galeriye Kaydet';

  @override
  String get manifestEditorWatermarkNote =>
      'Köşede küçük bir “zibo” logosu olur · Zibo Pro\'da logo yok';

  @override
  String get manifestEditorSaved => 'Galeriye kaydedildi ✅';

  @override
  String get manifestEditorSaveFailed =>
      'Kaydedilemedi. Galeri iznini kontrol edip tekrar dene.';

  @override
  String get manifestEditorShareCaption => 'Zibo ile manifestim ✨';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileModuleDescription =>
      'Fotoğrafını, ismini ve alışkanlık istatistiklerini gör';

  @override
  String get profilePhotoSemanticLabel =>
      'Profil fotoğrafı, değiştirmek için dokun';

  @override
  String get profileNameHint => 'İsmini yaz';

  @override
  String get profileStatsSectionTitle => 'İstatistiklerim';

  @override
  String get profileStatMoneyTitle => 'Para Yönetimi';

  @override
  String get profileStatGratitudeManifestTitle => 'Şükür ve Manifest';

  @override
  String get profileStatConsistencyTitle => 'İstikrar';

  @override
  String get profileStatSelfCareTitle => 'Öz Saygı ve Sağlık';

  @override
  String get profileStatMoneyEmpty =>
      'Henüz veri yok — Para ve Birikim\'i kullanmaya başla!';

  @override
  String get profileStatGratitudeManifestEmpty =>
      'Henüz veri yok — Şükran Günlüğü veya Manifest Günlüğü\'nü kullanmaya başla!';

  @override
  String get profileStatConsistencyEmpty =>
      'Henüz veri yok — Hedef Takibi\'ni kullanmaya başla!';

  @override
  String get profileStatSelfCareEmpty =>
      'Henüz veri yok — Su Takibi\'ni kullanmaya başla!';

  @override
  String get profileBondSectionTitle => 'Zibo ile Bağın';

  @override
  String get bondLevelScreenTitle => 'Zibo ile Bağ Seviyesi';

  @override
  String profileBondLevelRowSubtitle(int days) {
    return 'Zibo ile $days gündür kankasın';
  }

  @override
  String profileBondNextLevelHint(int days, String tier) {
    return '$days gün sonra $tier olacaksın';
  }

  @override
  String get profileBondMaxLevelHint => 'Zaten en üst kademedesin, tebrikler!';

  @override
  String get bondLevelNewBuddy => 'Yeni Kanka';

  @override
  String get bondLevelGettingClose => 'Yakınlaşan Dost';

  @override
  String get bondLevelOldFriend => 'Eski Dost';

  @override
  String get bondLevelSoulBuddy => 'Can Kanka';

  @override
  String get bondLevelLifetimeBuddy => 'Ömür Boyu Dost';

  @override
  String get longestStreakScreenTitle => 'En Uzun Seri Rekoru';

  @override
  String profileStreakRowSubtitle(int days) {
    return 'En uzun serin: $days gün';
  }

  @override
  String get longestStreakScreenSubtitle =>
      'Zibo\'yu art arda en çok kaç gün açtığının rekoru';

  @override
  String get longestStreakEncouragement =>
      'Bu rekoru geçmek için bugün de Zibo\'yu aç!';

  @override
  String get profileCostumeClosetRowTitle => 'Kostüm Dolabı';

  @override
  String get profileCostumeClosetEmpty =>
      'Henüz bir kostümün yok — Mağaza\'dan birini seç!';

  @override
  String get coinSummaryScreenTitle => 'Zibo Coin Özeti';

  @override
  String get coinSummaryTotalEarnedLabel => 'Toplam Kazanılan';

  @override
  String get coinSummaryTotalSpentLabel => 'Toplam Harcanan';

  @override
  String coinSummaryAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String profileCoinSummaryRowSubtitle(int earned, int spent) {
    return 'Kazanılan $earned ZC · Harcanan $spent ZC';
  }

  @override
  String get addressTermScreenTitle => 'Hitap Tercihi';

  @override
  String get addressTermScreenDescription =>
      'Zibo sana nasıl seslensin? Yazdığın kelime, sözlerinde \"kanka\" geçen yerlerde kullanılır.';

  @override
  String get addressTermFieldHint =>
      'Zibo sana nasıl seslensin? Örn: Kanka, Reis, Aslanım...';

  @override
  String profileAddressTermRowSubtitle(String term) {
    return 'Zibo sana \"$term\" diyor';
  }

  @override
  String get favoriteQuotesScreenTitle => 'Favori Sözler';

  @override
  String get favoriteQuotesEmpty =>
      'Henüz favori sözün yok — Ana Sayfa\'daki kalp ikonuyla sevdiğin sözleri kaydet!';

  @override
  String get customMessagesButtonTooltip => 'Kendi mesajını ekle';

  @override
  String get customMessagesScreenTitle => 'Özel Mesajlarım';

  @override
  String get customMessagesSubtitle =>
      'Zibo\'nun sana ara sıra söylemesini istediğin kendi cümlelerini ekle — standart sözlerle karışık, rastgele gösterilirler.';

  @override
  String get customMessagesEmpty => 'Henüz özel mesaj eklemedin.';

  @override
  String get customMessagesAddButton => 'Yeni Mesaj Ekle';

  @override
  String get customMessagesFieldHint => 'Zibo bunu sana söylesin...';

  @override
  String get customMessagesSaveButton => 'Kaydet';

  @override
  String get customMessagesCancelButton => 'İptal';

  @override
  String get customMessagesDeleteTooltip => 'Sil';

  @override
  String profileFavoriteQuotesRowSubtitle(int count) {
    return '$count favori söz';
  }

  @override
  String get profileShareCardRowTitle => 'Profil Kartını Paylaş';

  @override
  String get profileShareCardRowSubtitle =>
      'Bağ seviyeni ve istatistiklerini bir kartta paylaş';

  @override
  String get monthlyStatsRowTitle => 'Geçmiş Ay İstatistikleri';

  @override
  String monthlyStatsRowSubtitle(int count) {
    return '$count ay arşivlendi';
  }

  @override
  String get monthlyStatsScreenTitle => 'Geçmiş Ay İstatistikleri';

  @override
  String get monthlyStatsEmpty =>
      'Henüz arşivlenmiş bir ay yok. İlk ay sonunda burada görünmeye başlayacak.';

  @override
  String get profileShareCardTitle => '🐣 Zibo ile Bağım';

  @override
  String get onboardingLanguageStepTitle => 'Hangi dili konuşalım?';

  @override
  String get onboardingLanguageStepSubtitle =>
      'Uygulamanın geri kalanı seçtiğin dilde açılacak — istersen sonra Ayarlar\'dan değiştirebilirsin.';

  @override
  String get onboardingNameStepTitle => 'Sana ne diyelim?';

  @override
  String get onboardingNameStepSubtitle =>
      'Zibo seninle bu isimle konuşacak — istersen sonra Profil\'den değiştirebilirsin.';

  @override
  String get onboardingContinueButton => 'Devam Et';

  @override
  String get onboardingNextButton => 'İleri';

  @override
  String get onboardingSkipButton => 'Geç';

  @override
  String get onboardingStartButton => 'Hadi Başlayalım!';

  @override
  String get onboardingGoalsDescription =>
      'Büyük hayallerini küçük adımlara böl.';

  @override
  String get onboardingWaterDescription =>
      'Vücuduna verdiğin en küçük sözü bile tutmayı öğren.';

  @override
  String get onboardingGratitudeDescription =>
      'Güne, sahip olduklarını hatırlayarak bak.';

  @override
  String get onboardingMoodDescription =>
      'Duygularını görmezden gelme, onları takip et.';

  @override
  String get onboardingDreamJournalDescription =>
      'Bilinçaltının sana ne anlattığını keşfet.';

  @override
  String get onboardingManifestDescription =>
      'Hayal ettiğin hayatı gözünün önüne seriyorsun.';

  @override
  String get onboardingStoreDescription =>
      'Emeğini renklendir, Zibo\'yu kendi tarzınla giydir.';

  @override
  String get onboardingProfileDescription =>
      'Zibo\'yla olan bağını ve ilerlemeni tek bakışta gör.';

  @override
  String get onboardingClosingTitle => 'Zibo ile Yolculuğun Başlıyor!';

  @override
  String onboardingClosingMessage(String name) {
    return 'Artık hazırsın, $name! Küçük adımlarla büyük değişimler yaratacağız — hedeflerini takip et, kendine iyi bak, ben hep yanındayım. Hadi başlayalım kanka!';
  }

  @override
  String get googleLinkRowTitleUnlinked => 'Google ile Bağla';

  @override
  String get googleLinkRowTitleLinked => 'Google Hesabın';

  @override
  String get googleLinkRowSubtitle =>
      'Satın alımlarını ve verilerini güvende tut';

  @override
  String get googleLinkSuccessMessage => 'Google hesabına başarıyla bağlandı!';

  @override
  String get googleLinkFailedMessage =>
      'Bağlanırken bir sorun oluştu, tekrar dene.';

  @override
  String get googleAlreadyLinkedDialogTitle =>
      'Bu hesap başka bir cihaza bağlı';

  @override
  String get googleAlreadyLinkedDialogBody =>
      'Bu Google hesabı zaten başka bir cihazdaki verilerle ilişkili. O hesaba geçip verilerine ulaşmak istersen, bu cihazdaki mevcut ilerleme kaybolur.';

  @override
  String get googleSignInInsteadButton => 'Google ile Giriş Yap';

  @override
  String get googleSignInSuccessMessage =>
      'Google hesabınla giriş yapıldı, verilerin geri yüklendi!';

  @override
  String get googleSignInFailedMessage =>
      'Giriş yapılırken bir sorun oluştu, tekrar dene.';

  @override
  String get googleLinkPromoTitle => 'Satın Alımlarını Güvende Tut';

  @override
  String get googleLinkPromoBody =>
      'Google hesabınla bağlanırsan, Zibo Coin\'lerin ve tüm ilerlemen cihaz değişse bile kaybolmaz.';

  @override
  String get googleLinkPromoSkipButton => 'Şimdilik Atla';

  @override
  String get googleSignOutButton => 'Çıkış Yap';

  @override
  String get googleSwitchAccountButton => 'Hesap Değiştir';

  @override
  String get googleSignOutConfirmTitle => 'Çıkış Yap';

  @override
  String get googleSignOutConfirmBody =>
      'Çıkış yapmak istediğine emin misin? Bu hesaba bağlı verilerin kaybolmaz — aynı Google hesabıyla tekrar giriş yaptığında geri yüklenir.';

  @override
  String get googleSignOutFailedMessage =>
      'Çıkış yapılırken bir sorun oluştu, tekrar dene.';

  @override
  String get referralScreenTitle => 'Arkadaşını Davet Et';

  @override
  String get referralRowTitle => 'Arkadaşını Davet Et';

  @override
  String get referralRowSubtitle => 'Davet et, ikiniz de Zibo Coin kazanın';

  @override
  String get referralCodeLabel => 'Davet Kodun';

  @override
  String get referralCopyButton => 'Kopyala';

  @override
  String get referralCodeCopiedMessage => 'Davet kodu panoya kopyalandı!';

  @override
  String get referralShareButton => 'Paylaş';

  @override
  String referralShareMessage(String code, int amount) {
    return 'Zibo\'yu deniyorum, sen de katıl! Davet kodum: $code — Profil > Arkadaşını Davet Et\'ten gir, ikimiz de $amount Zibo Coin kazanalım! 🎉';
  }

  @override
  String get referralRedeemFieldLabel => 'Bir davet kodun var mı?';

  @override
  String get referralRedeemButton => 'Kullan';

  @override
  String get referralRedeemSuccessMessage =>
      'Kodun gönderildi! Coin\'in kısa süre içinde hesabına eklenecek.';

  @override
  String get referralRedeemSelfCodeError => 'Kendi davet kodunu kullanamazsın.';

  @override
  String get referralRedeemInvalidCodeError => 'Geçerli bir davet kodu gir.';

  @override
  String get referralAlreadyRedeemedStatus =>
      'Davet kodunu kullandın, teşekkürler!';

  @override
  String get referralUnavailableMessage =>
      'Davet sistemi şu an kullanılamıyor, daha sonra tekrar dene.';

  @override
  String get founderBadgeTooltip => 'Kurucu Üye';

  @override
  String get founderBadgeEarnedSubtitle => 'İlk 500 kullanıcıdan birisin';

  @override
  String get subscriptionBadgeProTooltip => 'Zibo Pro';

  @override
  String get subscriptionBadgeProPlusTooltip => 'Zibo Pro+';

  @override
  String get shareCardProWatermarkSemanticLabel => 'Zibo Pro filigranı';

  @override
  String get founderBadgePromoTitle => 'Kurucu Üye Rozeti Kazan';

  @override
  String founderBadgePromoBody(int remaining) {
    return 'Google hesabını bağlayan ilk 500 kişiden biri ol — $remaining hak kaldı!';
  }

  @override
  String get founderBadgeClaimedMessage => '🏅 Kurucu Üye rozetini kazandın!';

  @override
  String get widgetTitleGoals => 'Hedef Takibi';

  @override
  String get widgetTitleWater => 'Su Takibi';

  @override
  String get widgetTitleGratitude => 'Şükran Günlüğü';

  @override
  String get widgetTitleMood => 'Ruh Hali Takibi';

  @override
  String get widgetTitleManifest => 'Manifest Günlüğü';

  @override
  String get widgetTitleDream => 'Rüya Günlüğü';

  @override
  String get widgetTitleMoney => 'Para ve Birikim';

  @override
  String get widgetTitleDailyRewards => 'Günlük Giriş Ödülleri';

  @override
  String get widgetTitleMotivation => 'Zibo\'nun Sözü';

  @override
  String get widgetTitleProfileStats => 'İstatistiklerim';

  @override
  String get widgetGoalsEmptyHint => 'Henüz hedef eklenmedi';

  @override
  String get widgetGoalsActiveHint => 'bugün işaretlenen hedef';

  @override
  String widgetWaterHint(String unit) {
    return '$unit · bugün';
  }

  @override
  String get widgetGratitudeDoneHint => 'Bugün tamamlandı';

  @override
  String get widgetGratitudeEmptyHint => 'Henüz yazılmadı';

  @override
  String get widgetMoodSetHint => 'Bugünkü ruh halin';

  @override
  String get widgetMoodEmptyHint => 'Henüz seçilmedi';

  @override
  String get widgetManifestActiveHint => 'bugün eklenen giriş';

  @override
  String get widgetManifestEmptyHint => 'Henüz giriş yok';

  @override
  String get widgetDreamActiveHint => 'toplam rüya kaydı';

  @override
  String get widgetDreamEmptyHint => 'Henüz rüya eklenmedi';

  @override
  String get widgetMoneyHint => 'bu ay net';

  @override
  String get widgetDailyRewardsClaimedHint => 'Bugün alındı ✓';

  @override
  String get widgetDailyRewardsAvailableHint => 'Bugün alınabilir 🎁';

  @override
  String widgetDailyRewardsPrimary(int day) {
    return 'Gün $day/7';
  }

  @override
  String get widgetsScreenTitle => 'Ana Ekran Widget\'ları';

  @override
  String get widgetsScreenIntro =>
      'Zibo\'nun modüllerini ana ekranından tek bakışta takip et. İstediğin modülün yanındaki butona dokunarak ana ekranına ekle.';

  @override
  String get widgetsScreenAddButton => 'Ekle';

  @override
  String get widgetsScreenAddedSuccessMessage =>
      'Widget eklendi! Ana ekranını kontrol et.';

  @override
  String get widgetsScreenAddFailedMessage =>
      'Widget eklenemedi — cihazın bu özelliği desteklemiyor olabilir, ana ekranına uzun basıp \"Widget\'lar\" listesinden Zibo\'yu da bulabilirsin.';

  @override
  String get widgetsScreenAddSheetTitle => 'Ana Ekranına Nasıl Eklenir?';

  @override
  String get widgetsScreenAddStep1 =>
      'Ana ekranının boş bir alanına parmağını basılı tut.';

  @override
  String get widgetsScreenAddStep2 =>
      'Açılan menüden \"Widget\'lar\" (bazı cihazlarda \"Araçlar\") seçeneğine dokun.';

  @override
  String get widgetsScreenAddStep3 =>
      'Listede Zibo\'yu bulup istediğin widget\'ı ana ekranına sürükle.';

  @override
  String get widgetsScreenAddSheetGotIt => 'Anladım';

  @override
  String get settingsWidgetsRowSubtitle =>
      'Modül durumlarını ana ekranından takip et';

  @override
  String get badgesTriggerTooltip => 'Rozetler';

  @override
  String get badgesGalleryTitle => 'Rozetler';

  @override
  String get badgeCategoryConsistency => 'İstikrar Rozetleri';

  @override
  String get badgeNameFirstStep => 'İlk Adım';

  @override
  String get badgeNameWeekStreak => '1 Haftalık Seri';

  @override
  String get badgeNameMonthStreak => '1 Aylık Seri';

  @override
  String get badgeNameIronWill => 'Demir İrade';

  @override
  String get badgeNameUnyielding => 'Yılmaz';

  @override
  String get badgeRequirementFirstStep => 'İlk 7 günlük hedef döngünü tamamla';

  @override
  String get badgeRequirementWeekStreak => '7 gün üst üste giriş yap';

  @override
  String get badgeRequirementMonthStreak => '30 gün üst üste giriş yap';

  @override
  String get badgeRequirementIronWill => '90 gün üst üste giriş yap';

  @override
  String get badgeRequirementUnyielding => '180 gün üst üste giriş yap';

  @override
  String get badgeClaimRewardButton => 'Ödülü Al';

  @override
  String get badgeGalleryClaimableLabel => 'Ödülü Al';

  @override
  String badgeRewardClaimedMessage(int amount) {
    return '+$amount Zibo Coin kazandın!';
  }

  @override
  String get badgeCategoryModuleMastery => 'Modül Ustalığı Rozetleri';

  @override
  String get badgeNameGratefulHeart => 'Şükreden Kalp';

  @override
  String get badgeNameWaterHero => 'Su Kahramanı';

  @override
  String get badgeNameMoodChronicler => 'Ruh Hali Kaydedicisi';

  @override
  String get badgeNameSavingsMaster => 'Birikim Ustası';

  @override
  String get badgeNameDreamer => 'Hayalperest';

  @override
  String get badgeNameDreamInterpreter => 'Rüya Yorumcusu';

  @override
  String get badgeRequirementGratefulHeart =>
      'Şükran Günlüğü\'nde toplam 30 kayıt oluştur';

  @override
  String get badgeRequirementWaterHero =>
      'Su Takibi\'nde toplam 30 gün kayıt yap';

  @override
  String get badgeRequirementMoodChronicler =>
      'Ruh Hali Takibi\'nde toplam 30 kayıt oluştur';

  @override
  String get badgeRequirementSavingsMaster =>
      'Para ve Birikim\'de toplam 20 kayıt oluştur';

  @override
  String get badgeRequirementDreamer =>
      'Manifest Günlüğü\'nde toplam 15 kayıt oluştur';

  @override
  String get badgeRequirementDreamInterpreter =>
      'Rüya Günlüğü\'nde toplam 15 kayıt oluştur';

  @override
  String get badgeCategoryCollection => 'Koleksiyon Rozetleri';

  @override
  String get badgeNameCollector => 'Koleksiyoncu';

  @override
  String get badgeNameFashionIcon => 'Moda İkonu';

  @override
  String get badgeNameFullWardrobe => 'Tam Gardırop';

  @override
  String get badgeNameThemeHunter => 'Tema Avcısı';

  @override
  String get badgeRequirementCollector => '5 farklı kostüme sahip ol';

  @override
  String get badgeRequirementFashionIcon => '10 farklı kostüme sahip ol';

  @override
  String get badgeRequirementFullWardrobe =>
      'Mağazadaki TÜM kostümlere sahip ol';

  @override
  String get badgeRequirementThemeHunter => '3 farklı temaya sahip ol';

  @override
  String get badgeSpecialRewardComingSoon => 'Özel Ödül (Yakında)';

  @override
  String get badgeSpecialRewardThemeNote => '+ Rastgele Bir Tema Hediyesi';

  @override
  String badgeSpecialRewardThemeGrantedMessage(String themeName) {
    return 'Özel ödülün: $themeName teması hediye edildi! 🎁';
  }

  @override
  String badgeGiftCostumeMessage(String costumeName) {
    return 'Ayrıca $costumeName kazandın! 🎁';
  }

  @override
  String badgeGiftPreviewLabel(String itemName) {
    return 'Hediye: $itemName';
  }

  @override
  String get badgeCategoryLoyalty => 'Sadakat Rozetleri';

  @override
  String get badgeNameFirstWeek => 'İlk Hafta';

  @override
  String get badgeNameLoyalFriend => 'Sadık Dost';

  @override
  String get badgeNameAnniversary => 'Yıl Dönümü';

  @override
  String get badgeRequirementFirstWeek => 'Uygulamayı toplam 7 farklı günde aç';

  @override
  String get badgeRequirementLoyalFriend =>
      'Uygulamayı toplam 100 farklı günde aç';

  @override
  String get badgeRequirementAnniversary =>
      'Zibo ile tanışmanın üzerinden 1 yıl geçsin';

  @override
  String get badgeCategorySocial => 'Sosyal Rozetler';

  @override
  String get badgeNameFirstShare => 'İlk Paylaşım';

  @override
  String get badgeNameAmbassador => 'Elçi';

  @override
  String get badgeNameCommunityFounder => 'Topluluk Kurucusu';

  @override
  String get badgeRequirementFirstShare => 'Bir Zibo kartını ilk kez paylaş';

  @override
  String get badgeRequirementAmbassador =>
      'Davet Et ile 1 arkadaşını başarıyla davet et';

  @override
  String get badgeRequirementCommunityFounder =>
      'Davet Et ile 5 arkadaşını başarıyla davet et';

  @override
  String get badgeCategoryHidden => 'Gizli Rozetler';

  @override
  String get badgeHiddenPlaceholder => '???';

  @override
  String get badgeNameNightOwl => 'Gece Kuşu';

  @override
  String get badgeNameEarlyBird => 'Erken Kuş';

  @override
  String get badgeNameBalanceMaster => 'Denge Ustası';

  @override
  String get badgeRequirementNightOwl =>
      'Gece yarısı ile sabah 05:00 arası 30 kez uygulamayı aç';

  @override
  String get badgeRequirementEarlyBird =>
      'Sabah 06:00-08:00 arası 30 kez uygulamayı aç';

  @override
  String get badgeRequirementBalanceMaster =>
      'Aynı gün içinde uygulamadaki 7 modülün hepsine kayıt ekle';

  @override
  String levelUpCelebrationTitle(int level) {
    return 'Seviye $level\'e Ulaştın!';
  }

  @override
  String get levelUpCelebrationBody =>
      'Zibo ile harika gidiyorsun, büyümeye devam et!';

  @override
  String get levelUpShareButton => 'Paylaş';

  @override
  String get levelUpCloseButton => 'Kapat';

  @override
  String levelUpShareMessage(int level) {
    return 'Zibo\'da Seviye $level\'e ulaştım! 🎉';
  }

  @override
  String get profileLevelRowTitle => 'Seviyen';

  @override
  String profileLevelProgressLabel(int current, int needed) {
    return '$current/$needed XP';
  }

  @override
  String get focusTimerTooltip => 'Odak Sayacı';

  @override
  String get focusModuleDescription =>
      'Odaklanma sürelerini takip et, üretkenliğini artır.';

  @override
  String get focusTimerScreenTitle => 'Odak Sayacı';

  @override
  String get focusModeFreeLabel => 'Serbest';

  @override
  String focusModeMinutesLabel(int minutes) {
    return '$minutes dk';
  }

  @override
  String get focusStartButton => 'Başlat';

  @override
  String get focusPauseButton => 'Duraklat';

  @override
  String get focusResumeButton => 'Devam Et';

  @override
  String get focusFinishButton => 'Bitir ve Kaydet';

  @override
  String get focusResetButton => 'Sıfırla';

  @override
  String focusSessionSavedMessage(int minutes) {
    return '$minutes dakika odaklandın! Harika iş.';
  }

  @override
  String get focusSessionTooShortMessage => 'En az 1 dakika odaklanmalısın.';

  @override
  String get focusTotalTimeLabel => 'Toplam Odak Süren';

  @override
  String get profileFocusRowTitle => 'Odak Süresi';

  @override
  String profileFocusRowSubtitle(String durationText) {
    return 'Toplam $durationText odaklandın';
  }

  @override
  String get instagramFollowCardTitle => 'Bizi Instagram\'da Takip Edin';

  @override
  String get instagramFollowCardBody =>
      '@zibo.app hesabımızı takip et; 100 ZC, bir tema ve bir kostüm kazan!';

  @override
  String get instagramFollowOpenButton => 'Instagram\'ı Aç';

  @override
  String get instagramFollowClaimButton => 'Takip Ettim';

  @override
  String get instagramFollowRewardGrantedMessage =>
      'Ödülün hesabına eklendi! 🎉';

  @override
  String get commonOkButton => 'Tamam';

  @override
  String get paywallAppBarTitle => 'Zibo Pro';

  @override
  String get paywallBannerTitle => 'Zibo\'yla Daha Yakın Kanka';

  @override
  String get paywallBannerSubtitle =>
      'Reklamsız, daha hızlı, daha özel bir deneyim';

  @override
  String get paywallBillingToggleMonthly => 'Aylık';

  @override
  String get paywallBillingToggleYearly => 'Yıllık (2 ay bedava)';

  @override
  String get paywallOneTimeTitle => 'Tek Seferlik Reklamsız';

  @override
  String get paywallOneTimeBenefit => 'Tüm reklamlar kalksın';

  @override
  String get paywallProTitle => 'Zibo Pro';

  @override
  String get paywallProPlusTitle => 'Zibo Pro+';

  @override
  String get paywallMostPopularBadge => 'En Popüler';

  @override
  String get paywallCurrentPlanBadge => 'Mevcut Planın';

  @override
  String get paywallAlreadyProPlusBadge => 'Zaten Pro+ Kullanıcısısın';

  @override
  String get paywallBuyButton => 'Satın Al';

  @override
  String get paywallSubscribeButton => 'Abone Ol';

  @override
  String get paywallUpgradeButton => 'Pro+\'a Yükselt';

  @override
  String get paywallProPerkNoForcedAds => 'Zorunlu reklamlar kalkar';

  @override
  String get paywallProPerkCoinBonus => 'Check-in coin ödülü 1,5 kat';

  @override
  String get paywallProPerkStreakFreeze => 'Ayda 1 ücretsiz Streak Freeze';

  @override
  String get paywallProPerkWheelNoAds =>
      'Şans Çarkı reklamsız + günde 1 ekstra çevirme';

  @override
  String get paywallProPerkUnlimitedHistory => 'Modüllerde sınırsız geçmiş';

  @override
  String get paywallProPerkNotificationTime => 'Bildirim saatini kişiselleştir';

  @override
  String get paywallProPlusPerkAllOfPro => 'Pro\'nun tüm avantajları';

  @override
  String get paywallProPlusPerkCoinBonus => 'Check-in coin ödülü 2 kat';

  @override
  String get paywallProPlusPerkStreakFreeze => 'Ayda 3 ücretsiz Streak Freeze';

  @override
  String get paywallProPlusPerkExclusiveItem =>
      'Ayda 1 Pro\'ya özel kostüm/tema';

  @override
  String get paywallProPlusPerkProfileBadge => 'Özel profil rozeti/çerçevesi';

  @override
  String get paywallProPlusPerkWatermark =>
      'Paylaşım kartlarında özel Pro+ filigranı';

  @override
  String get paywallProPlusPerkTrendChart => 'Detaylı trend grafiği';

  @override
  String get paywallProPlusPerkMoneyAnalysis =>
      'Para & Birikim gelişmiş analiz';

  @override
  String get paywallProPlusPerkNotificationSounds => 'Özel bildirim sesleri';

  @override
  String get paywallCloseTooltip => 'Kapat';

  @override
  String get paywallSocialProofLine =>
      '⭐ 4,8 puan · binlerce mutlu Kanka Zibo Pro kullanıyor';

  @override
  String get paywallCompareTableTitle => 'Hangisi sana uygun?';

  @override
  String get paywallCompareColumnFree => 'Ücretsiz';

  @override
  String get paywallCompareColumnPro => 'Pro';

  @override
  String get paywallCompareColumnProPlus => 'Pro+';

  @override
  String get paywallPurchaseSuccessMessage =>
      'Satın alma başarılı! Zibo\'ya hoş geldin 🎉';

  @override
  String get paywallPurchaseErrorMessage =>
      'Satın alma tamamlanamadı, lütfen tekrar dene.';

  @override
  String get paywallUpgradeSuccessMessage => 'Pro+\'a yükseltme başarılı! 🎉';

  @override
  String get paywallUpgradeErrorMessage =>
      'Yükseltme tamamlanamadı, lütfen tekrar dene.';

  @override
  String get paywallPerMonthSuffix => '/ay';

  @override
  String get paywallPerYearSuffix => '/yıl';

  @override
  String get settingsZiboProRowTitle => 'Zibo Pro';

  @override
  String get settingsZiboProRowSubtitle =>
      'Daha fazla özellik, reklamsız deneyim';

  @override
  String streakFreezePillStreak(int count) {
    return '🔥 $count günlük seri';
  }

  @override
  String streakFreezePillGoals(int count) {
    return '🎯 $count hedef tehlikede';
  }

  @override
  String get streakFreezePillGoalsSaved => '🎯 Hedeflerin devam ediyor';

  @override
  String get streakFreezeBodyStreak =>
      'Dün Zibo\'ya uğramadın. Bir Streak Freeze dünü dondurur ❄️ ve serin kaldığı yerden devam eder.';

  @override
  String get streakFreezeBodyBoth =>
      'Dün Zibo\'ya uğramadın ve bazı hedeflerini işaretlemedin. Tek bir Streak Freeze dünü her yerde dondurur ❄️.';

  @override
  String get streakFreezeBodyGoals =>
      'Serin sağlam ama dün bu hedefleri işaretlemedin. Bir Streak Freeze dünü dondurur ❄️, hedeflerin sıfırlanmaz.';

  @override
  String get streakFreezeGoalsHeader => 'Dün işaretlenmeyen hedeflerin';

  @override
  String get streakFreezeDayYesterday => 'Dün';

  @override
  String get streakFreezeDayToday => 'Bugün';

  @override
  String streakFreezeResourceFree(int remaining, int quota) {
    return 'Pro hakkın: $remaining/$quota bu ay';
  }

  @override
  String streakFreezeResourceOwned(int count) {
    return '❄️ Stoğunda $count adet';
  }

  @override
  String streakFreezeResourceCoins(int balance) {
    return 'Stok yok · Bakiyen $balance ZC';
  }

  @override
  String get streakFreezeUseFreeLabel => 'Ücretsiz Kullan';

  @override
  String get streakFreezeUseOwnedLabel => '❄️ Stoktan Kullan';

  @override
  String get streakFreezeDeclineHintBoth => 'Seri ve hedefler sıfırlanır';

  @override
  String get streakFreezeDeclineHintStreak => 'Seri sıfırlanır';

  @override
  String get streakFreezeDeclineHintGoals => 'Hedefler sıfırlanır';

  @override
  String get streakFreezeDoneTitle => 'Dün donduruldu!';

  @override
  String streakFreezeDoneBodyStreak(int day) {
    return 'Serin kırılmadı, bugün $day. gün 🎉';
  }

  @override
  String get streakFreezeDoneBodyBoth =>
      'Serin ve hedeflerin kaldığı yerden devam ediyor 🎉';

  @override
  String get streakFreezeDoneBodyGoals =>
      'Hedeflerin kaldığı yerden devam ediyor 🎉';

  @override
  String get streakFreezeDoneButton => 'Harika!';
}
