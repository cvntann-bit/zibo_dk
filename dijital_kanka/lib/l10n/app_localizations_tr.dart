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
  String get settingsSoundEffects => 'Ses Efektleri';

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
  String get moneyTrendEmpty =>
      'Trend grafiği için henüz yeterli veri yok. Harcama veya birikim ekleyince burada görünecek.';

  @override
  String get moneyTrendExpenseLegend => 'Harcama';

  @override
  String get moneyTrendSavingLegend => 'Birikim';

  @override
  String get moneyTrendGranularityDaily => 'Günlük';

  @override
  String get moneyTrendGranularityWeekly => 'Haftalık';

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
  String get storePackagesSectionTitle => 'Coin Paketleri';

  @override
  String storeCoinAmount(int amount) {
    return '$amount ZC';
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
  String get storeThemesTabLabel => 'Temalar';

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
      '3 şükran cümleni yazdın ve 2 Zibo Coin kazandın. Yarın tekrar gel!';

  @override
  String get gratitudeHistoryTitle => 'Geçmiş Kayıtlar';

  @override
  String get gratitudeHistoryEmpty => 'Henüz tamamlanmış bir kayıt yok.';

  @override
  String get gratitudeCoinRewardMessage => '+2 Zibo Coin kazandın!';

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
  String waterGlassFilledLabel(int index, String unit) {
    return '$index. $unit, dolu';
  }

  @override
  String waterGlassEmptyLabel(int index, String unit) {
    return '$index. $unit, boş';
  }

  @override
  String get waterGoalCompletedMessage =>
      'Günlük su hedefini tamamladın! +2 Zibo Coin kazandın!';

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
  String get manifestSaveButton => 'Kaydet';

  @override
  String get manifestSavedMessage => 'Bugünün girişi kaydedildi.';

  @override
  String get manifestCoinRewardMessage => '+2 Zibo Coin kazandın!';

  @override
  String get manifestHistoryTitle => 'Geçmiş Kayıtlar';

  @override
  String get manifestHistoryEmpty =>
      'Henüz bir kayıt yok. Bugün ilk vizyonunu ekle!';

  @override
  String get manifestDetailCloseButton => 'Kapat';

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
      'Hedef Takibi\'ndeki en uzun kesintisiz serin';

  @override
  String get longestStreakEncouragement =>
      'Bu rekoru geçmek için bugün de bir hedefini işaretle!';

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
      'Kendi hedeflerini belirle, her gün işaretle — 7 günlük bir seriyi tamamladığında Zibo Coin kazanırsın.';

  @override
  String get onboardingWaterDescription =>
      'Günlük su hedefini takip et, bardak bardak ilerlemeni gör — hedefi tamamlayınca ödül seni bekliyor.';

  @override
  String get onboardingGratitudeDescription =>
      'Her gün 3 şeye şükret, küçük anları yazıya dök — hem içini rahatlatır hem de bakış açını değiştirir.';

  @override
  String get onboardingMoodDescription =>
      'Bugün nasıl hissettiğini tek dokunuşla kaydet, zamanla ruh halinin nasıl değiştiğini gör.';

  @override
  String get onboardingManifestDescription =>
      'Hayallerine bir fotoğraf ve niyet ekle — kendi vizyon panonu zamanla büyüt.';

  @override
  String get onboardingStoreDescription =>
      'Zibo Coin biriktir, yeni kostümler ve renkli temalar satın al — Zibo\'yu istediğin gibi giydir.';

  @override
  String get onboardingProfileDescription =>
      'İstatistiklerini gör, Zibo ile bağını takip et, favori sözlerini biriktir — hepsi tek bir yerde.';

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
}
