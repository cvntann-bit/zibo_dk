// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zibo';

  @override
  String get homeAppBarTitle => 'Zibo';

  @override
  String coinBalanceLabel(int count) {
    return '$count Zibo Coin';
  }

  @override
  String get insufficientCoins => 'Not enough Zibo Coin';

  @override
  String get ziboImagePlaceholder => 'Zibo';

  @override
  String get tapZiboHint => 'Tap Zibo for a new saying';

  @override
  String get tabHome => 'Home';

  @override
  String get tabGoalTracking => 'Goal Tracking';

  @override
  String get bottomBarGoalsLabel => 'Goals';

  @override
  String get tabSettings => 'Settings';

  @override
  String goalProgressLabel(int completed) {
    return '$completed/7 days';
  }

  @override
  String goalDayToday(int day) {
    return 'Day $day, today';
  }

  @override
  String goalDayDone(int day) {
    return 'Day $day, done';
  }

  @override
  String goalDayMissed(int day) {
    return 'Day $day, missed';
  }

  @override
  String goalDayUpcoming(int day) {
    return 'Day $day, not open yet';
  }

  @override
  String get goalCycleCompleted =>
      'Amazing! You completed the 7-day goal and earned +50 Zibo Coin.';

  @override
  String goalStreakReset(String goalNames) {
    return '$goalNames missed a day, streak reset. Starting again from today.';
  }

  @override
  String get addGoalButton => 'Add New Goal';

  @override
  String get addGoalDialogTitle => 'New Goal';

  @override
  String get addGoalDialogHint => 'e.g. Read 30 minutes a day';

  @override
  String get deleteGoalTooltip => 'Delete goal';

  @override
  String get completedGoalsButtonTooltip => 'Completed Goals';

  @override
  String get completedGoalsScreenTitle => 'Completed Goals';

  @override
  String get completedGoalsEmpty =>
      'No completed goals yet. Finish your first 7-day cycle and it\'ll show up here!';

  @override
  String get completedGoalsBadgeLabel => '1 week completed';

  @override
  String completedGoalsGroupCount(int count) {
    return '$count completions';
  }

  @override
  String completedGoalsDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'About the App';

  @override
  String get settingsDarkTheme => 'Dark Theme';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeModeLight => 'Light';

  @override
  String get settingsThemeModeDark => 'Dark';

  @override
  String get settingsThemeModeSystem => 'Follow System';

  @override
  String get settingsSoundEffects => 'Sound Effects';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionPushNotifications => 'Push Notifications';

  @override
  String get pushNotificationDailyMotivationTitle => 'Daily Motivation';

  @override
  String get pushNotificationDailyMotivationSubtitle =>
      'Get a random motivational quote every morning between 9-11';

  @override
  String get pushNotificationStreakReminderTitle => 'Streak Reminder';

  @override
  String get pushNotificationStreakReminderSubtitle =>
      'Get reminded in the evening if you\'re about to miss your streak';

  @override
  String get pushNotificationDailyRewardTitle => 'Daily Reward Reminder';

  @override
  String get pushNotificationDailyRewardSubtitle =>
      'Get reminded in the afternoon if you haven\'t claimed your daily reward';

  @override
  String get pushNotificationReEngagementTitle => 'We Miss You';

  @override
  String get pushNotificationReEngagementSubtitle =>
      'Zibo misses you if you haven\'t visited in 2 days';

  @override
  String get settingsContactUs => 'Contact Us';

  @override
  String get settingsRateUs => 'Rate Us';

  @override
  String get settingsRateUsSubtitle =>
      'Leave a rating on the Play Store and help Zibo grow';

  @override
  String get rateUsSheetTitle => 'Enjoying Zibo?';

  @override
  String get rateUsSheetSubtitle =>
      'Tap the stars to rate us on the Play Store!';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsWebsite => 'Website';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsLegalPlaceholderBody => 'This content will be here soon.';

  @override
  String get settingsCouldNotOpenLink => 'Couldn\'t open, please try again.';

  @override
  String get tabMoney => 'Money & Savings';

  @override
  String get bottomBarMoneyLabel => 'Savings';

  @override
  String get moneyModuleDescription =>
      'Track your expenses, savings and income';

  @override
  String get moneyScreenTitle => 'Expenses & Savings';

  @override
  String get moneyExpenses => 'Expenses';

  @override
  String get moneySavings => 'Savings';

  @override
  String get moneyIncome => 'Income';

  @override
  String get moneyTrendSectionTitle => 'Current Status';

  @override
  String get moneyTrendEmpty =>
      'Not enough data for a trend chart yet. Add an expense or saving and it\'ll show up here.';

  @override
  String get moneyTrendExpenseLegend => 'Expense';

  @override
  String get moneyTrendSavingLegend => 'Saving';

  @override
  String get moneyTrendGranularityDaily => 'Daily';

  @override
  String get moneyTrendGranularityWeekly => 'Weekly';

  @override
  String get moneyEmptyCategory => 'No entries yet';

  @override
  String get moneyAddEntryButton => 'Add';

  @override
  String get moneyAddEntryTitle => 'New Entry';

  @override
  String get moneyEditEntryTitle => 'Edit Entry';

  @override
  String get moneyEntryNameHint => 'Name';

  @override
  String get moneyEntryAmountHint => 'Amount';

  @override
  String get moneyEntryCurrencyLabel => 'Currency';

  @override
  String get moneyDeleteEntryTooltip => 'Delete entry';

  @override
  String get moneyCurrencyTooltip => 'Currency';

  @override
  String get moneyCurrencyPickerTitle => 'Choose Currency';

  @override
  String moneyCategoryTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get storeButtonTooltip => 'Buy coins';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeAdFreeSectionTitle => 'Ad-Free Zibo';

  @override
  String get storeAdFreeCardTitle => 'Remove Ads';

  @override
  String get storeAdFreeCardSubtitle => 'Turn off all ads for good';

  @override
  String get storePackagesSectionTitle => 'Coin Packages';

  @override
  String storeCoinAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String get storeBuyButton => 'Buy';

  @override
  String get storeFreeSectionTitle => 'Free';

  @override
  String get storeWatchAdTitle => 'Watch an Ad';

  @override
  String storeWatchAdSubtitle(int amount) {
    return 'Earn $amount Zibo Coin, completely free';
  }

  @override
  String get storeWatchAdButton => 'Watch';

  @override
  String get dailyAdLimitReachedMessage =>
      'You\'re out of chances for today, come back tomorrow!';

  @override
  String storeCoinsAdded(int amount) {
    return '$amount Zibo Coin added to your balance!';
  }

  @override
  String get storePurchaseFailedMessage =>
      'Purchase couldn\'t be completed. Please try again.';

  @override
  String get shareButtonTooltip => 'Share this saying';

  @override
  String get favoriteQuoteAddTooltip => 'Favorite this saying';

  @override
  String get favoriteQuoteRemoveTooltip => 'Remove from favorites';

  @override
  String get shareSheetTitle => 'Share your Zibo';

  @override
  String get shareBackgroundLabel => 'Background';

  @override
  String get shareTextStyleLabel => 'Text Style';

  @override
  String get shareActionButton => 'Share';

  @override
  String get shareErrorMessage => 'Couldn\'t start sharing, please try again.';

  @override
  String get storeCoinsTabLabel => 'Buy Coins';

  @override
  String get storeCostumesTabLabel => 'Costumes';

  @override
  String get costumeNameZiboHippi => 'Hippie Zibo';

  @override
  String get costumeNameZiboSporcu => 'Athlete Zibo';

  @override
  String get costumeNameZiboAsker => 'Soldier Zibo';

  @override
  String get costumeNameZiboHoca => 'Professor Zibo';

  @override
  String get costumeNameZiboPunk => 'Punk Zibo';

  @override
  String get costumeNameZiboRapci => 'Rapper Zibo';

  @override
  String get costumeNameZiboGladyator => 'Gladiator Zibo';

  @override
  String get costumeNameZiboKorsan => 'Pirate Zibo';

  @override
  String get costumeNameZiboZombi => 'Zombie Zibo';

  @override
  String get costumeNameZiboAltin => 'Golden Zibo';

  @override
  String get costumeNameZiboElmas => 'Diamond-Plated Zibo';

  @override
  String get costumeNameZiboGentleman => 'Gentleman Zibo';

  @override
  String get costumeNameZiboSamurai => 'Samurai Zibo';

  @override
  String get costumeNameZiboCyborg => 'Cyborg Zibo';

  @override
  String get costumeNameZiboAstronot => 'Astronaut Zibo';

  @override
  String get costumeNameZiboKing => 'King Zibo';

  @override
  String get costumeOwnedBadge => 'Owned';

  @override
  String get costumeEquippedBadge => 'Worn';

  @override
  String costumePurchasedMessage(String name) {
    return '$name purchased!';
  }

  @override
  String costumeLockedSemanticLabel(String name, int price) {
    return '$name, locked, $price Zibo Coin';
  }

  @override
  String costumeEquipSemanticLabel(String name) {
    return 'Wear $name';
  }

  @override
  String costumeUnequipSemanticLabel(String name) {
    return 'Take off $name';
  }

  @override
  String costumeUnlockViaStreak(int current, int target) {
    return '🎯 Unlock free with a $target-day streak ($current/$target)';
  }

  @override
  String costumeUnlockViaCompletions(int current, int target) {
    return '🎯 Unlock free by completing $target goals ($current/$target)';
  }

  @override
  String costumeUnlockViaWater(int current, int target) {
    return '🎯 Unlock free with $target days of water tracking ($current/$target)';
  }

  @override
  String costumeUnlockedViaGoalMessage(String name) {
    return '🎉 You unlocked $name for free by reaching your goal!';
  }

  @override
  String get storeThemesTabLabel => 'Themes';

  @override
  String get adFreePromoTitle => 'Zibo ADS';

  @override
  String get adFreePromoSubtitle => 'Ad-Free Experience';

  @override
  String get adFreePromoBenefitNoAds => 'No ads';

  @override
  String get adFreePromoBenefitUninterrupted => 'Uninterrupted use';

  @override
  String get adFreePromoBenefitSupport => 'Support Zibo';

  @override
  String get adFreePromoBuyButton => 'Buy Now';

  @override
  String get adFreePromoDismissButton => 'Maybe Later';

  @override
  String get adFreePromoComingSoon =>
      'Coming soon! The ad-free experience will be available soon.';

  @override
  String get themeNameSunset => 'Sunset';

  @override
  String get themeNameOcean => 'Ocean';

  @override
  String get themeNameForest => 'Forest';

  @override
  String get themeNameNightSky => 'Night Sky';

  @override
  String get themeNameGoldenAge => 'Golden Age';

  @override
  String get themeNameWinterSnow => 'Winter';

  @override
  String get themeNameGalaxyStars => 'Galaxy';

  @override
  String get themeNamePartyConfetti => 'Party Confetti';

  @override
  String get themeNameHeartsLove => 'Hearts Theme';

  @override
  String get themeNameMusicNotes => 'Music Notes Theme';

  @override
  String get themeNameTropicalParadise => 'Tropical Theme';

  @override
  String get themeNameCherryBlossom => 'Cherry Blossom Theme';

  @override
  String get themeNameLavenderGarden => 'Lavender Garden';

  @override
  String get themeNameCoralReef => 'Coral Reef';

  @override
  String get themeNameCherryOrchard => 'Cherry Orchard';

  @override
  String get themeNameMintGreens => 'Mint Greens';

  @override
  String get themeNameDesertDunes => 'Desert Dunes';

  @override
  String get themeNameMoonlight => 'Moonlight';

  @override
  String get themeNameCopperHills => 'Copper Hills';

  @override
  String get themeNameEmeraldValley => 'Emerald Valley';

  @override
  String get themeNameAmethystCave => 'Amethyst Cave';

  @override
  String get themeNameDustyRoseDream => 'Dusty Rose Dream';

  @override
  String get storeThemesStandardSectionTitle => 'Standard Themes';

  @override
  String get storeThemesPremiumSectionTitle => 'Premium / Animated';

  @override
  String get storeThemesPremiumSectionSubtitle =>
      'Special themes with a subtle motion effect on your screen';

  @override
  String get themeOwnedBadge => 'Owned';

  @override
  String get themeActiveBadge => 'Active';

  @override
  String themePurchasedMessage(String name) {
    return '$name theme purchased!';
  }

  @override
  String themeLockedSemanticLabel(String name, int price) {
    return '$name theme, locked, $price Zibo Coin';
  }

  @override
  String themeApplySemanticLabel(String name) {
    return 'Apply $name theme';
  }

  @override
  String themeRemoveSemanticLabel(String name) {
    return 'Remove $name theme';
  }

  @override
  String get wheelTriggerTooltip => 'Lucky Wheel';

  @override
  String get wheelTitle => 'Lucky Wheel';

  @override
  String get wheelSpinButton => 'Watch Ad\nto Spin';

  @override
  String get wheelCloseTooltip => 'Close';

  @override
  String get wheelResultTitle => 'Congratulations!';

  @override
  String wheelResultMessage(int amount) {
    return 'You won $amount Zibo Coin!';
  }

  @override
  String get wheelResultButton => 'Awesome!';

  @override
  String get dailyRewardsTriggerTooltip => 'Daily Rewards';

  @override
  String get dailyRewardsTitle => 'Daily Login Rewards';

  @override
  String get dailyRewardsCloseTooltip => 'Close';

  @override
  String dailyRewardsDayLabel(int day) {
    return 'Day $day';
  }

  @override
  String dailyRewardsPromptToday(int day, int amount) {
    return 'Tap Day $day to claim today\'s reward: $amount Zibo Coin!';
  }

  @override
  String dailyRewardsAlreadyClaimedToday(int amount) {
    return 'You claimed $amount Zibo Coin today! Come back tomorrow.';
  }

  @override
  String dailyRewardsClaimedSemanticLabel(int day, int amount) {
    return 'Day $day, $amount Zibo Coin claimed';
  }

  @override
  String dailyRewardsClaimSemanticLabel(int day, int amount) {
    return 'Claim Day $day reward, $amount Zibo Coin';
  }

  @override
  String dailyRewardsLockedSemanticLabel(int day, int amount) {
    return 'Day $day, not yet unlocked, $amount Zibo Coin';
  }

  @override
  String get notificationsSectionTitle => 'Notifications';

  @override
  String get notificationFrequencyOff => 'Off';

  @override
  String get notificationFrequencyOnce => 'Once a day';

  @override
  String get notificationFrequencyThrice => '3 times a day';

  @override
  String get notificationSlotMorning => 'Morning';

  @override
  String get notificationSlotNoon => 'Noon';

  @override
  String get notificationSlotEvening => 'Evening';

  @override
  String get notificationReliabilityTitle => 'For reliable notifications';

  @override
  String get notificationBatteryOptimizationWarning =>
      'Battery optimization may delay notifications';

  @override
  String get notificationBatteryOptimizationOk => 'Battery optimization is off';

  @override
  String get notificationBatteryOptimizationButton => 'Turn off';

  @override
  String get notificationAutostartDescription =>
      'Some phones (Xiaomi, Huawei, Oppo, Vivo, etc.) require \"autostart\" permission for notifications to arrive';

  @override
  String get notificationUnusedAppsDescription =>
      'Your phone may treat the app as \"unused\" and stop notifications — this setting may need to be turned off too';

  @override
  String get notificationUnusedAppsButton => 'Open settings';

  @override
  String get notificationAutostartButton => 'Open settings';

  @override
  String get dreamJournalTooltip => 'Dream Journal';

  @override
  String get dreamJournalTitle => 'Dream Journal';

  @override
  String get dreamAddButton => 'Add New Dream';

  @override
  String get dreamEmptyState =>
      'You haven\'t written a dream yet. Did you have one today?';

  @override
  String get dreamMoodCorrelationNote => 'Your mood was low that day too 😔';

  @override
  String get dreamTitleHint => 'Title';

  @override
  String get dreamTextHint => 'Tell your dream...';

  @override
  String get dreamSaveButton => 'Save';

  @override
  String get dreamNewEntryTitle => 'New Dream';

  @override
  String get dreamEditEntryTitle => 'Edit Dream';

  @override
  String get dreamDeleteEntryTooltip => 'Delete';

  @override
  String get dreamDeleteConfirmTitle => 'Delete this dream?';

  @override
  String get dreamDeleteConfirmBody =>
      'This dream will be permanently deleted.';

  @override
  String get dreamDeleteConfirmButton => 'Delete';

  @override
  String get gratitudeSettingsTitle => 'Gratitude Journal';

  @override
  String get gratitudeScreenTitle => 'Gratitude Journal';

  @override
  String gratitudeFieldLabel(int n) {
    return 'Gratitude $n';
  }

  @override
  String get gratitudeSaveButton => 'Save';

  @override
  String get gratitudeTodayDoneTitle => 'Done for today!';

  @override
  String get gratitudeTodayDoneBody =>
      'You wrote 3 things you\'re grateful for and earned 5 Zibo Coin. Come back tomorrow!';

  @override
  String get gratitudeHistoryTitle => 'Past Entries';

  @override
  String get gratitudeHistoryEmpty => 'No completed entries yet.';

  @override
  String get gratitudeCoinRewardMessage => 'You earned 5 Zibo Coin!';

  @override
  String get gratitudeEntryDetailCloseButton => 'Close';

  @override
  String get gratitudeEditTooltip => 'Edit';

  @override
  String get moodSettingsTitle => 'Daily Mood Tracker';

  @override
  String get moodScreenTitle => 'Daily Mood Tracker';

  @override
  String get moodWeekSummaryTitle => 'Last 7 Days';

  @override
  String get moodHistoryTitle => 'History';

  @override
  String get moodNoteHint =>
      'You can briefly write how you\'re feeling today (optional)';

  @override
  String get moodHistoryEmpty => 'No entries yet.';

  @override
  String get moodLabelVeryUnhappy => 'Very unhappy';

  @override
  String get moodLabelUnhappy => 'Unhappy';

  @override
  String get moodLabelNeutral => 'Neutral';

  @override
  String get moodLabelHappy => 'Happy';

  @override
  String get moodLabelVeryHappy => 'Very happy';

  @override
  String get modulesMenuZButtonTooltip => 'Open extra modules';

  @override
  String get modulesMenuTitle => 'Extra Modules';

  @override
  String get dreamModuleDescription =>
      'Write down your dreams, browse your history';

  @override
  String get gratitudeModuleDescription =>
      'Write 3 things you\'re grateful for daily, earn Zibo Coin';

  @override
  String get moodModuleDescription => 'Mark today\'s mood with an emoji';

  @override
  String get waterSettingsTitle => 'Water Tracking';

  @override
  String get waterModuleDescription =>
      'Track your daily water goal, glass by glass';

  @override
  String get waterScreenTitle => 'Water Tracking';

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
    return '$unit $index, full';
  }

  @override
  String waterGlassEmptyLabel(int index, String unit) {
    return '$unit $index, empty';
  }

  @override
  String get waterGoalCompletedMessage =>
      'You completed today\'s water goal! +5 Zibo Coin earned!';

  @override
  String get waterTodayCompleteBody =>
      'You\'ve hit your water goal today, way to go!';

  @override
  String get waterGoalSettingsTitle => 'Daily Water Goal';

  @override
  String get waterGoalDialogTitle => 'Daily Water Goal';

  @override
  String waterGoalDialogUnitCount(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get waterUnitGlass => 'glass';

  @override
  String get waterUnitBottle => 'bottle';

  @override
  String get waterUnitSectionLabel => 'Unit';

  @override
  String waterMlPerUnitLabel(String unit) {
    return '1 $unit = how many ml?';
  }

  @override
  String get waterHistoryTitle => 'History';

  @override
  String get waterHistoryEmpty => 'No history yet.';

  @override
  String waterHistoryCompletedEntry(String date) {
    return 'Goal completed on $date';
  }

  @override
  String waterHistoryPartialEntry(String date, int count, int goal) {
    return '$date: $count/$goal';
  }

  @override
  String get manifestSettingsTitle => 'Manifestation Journal';

  @override
  String get manifestModuleDescription =>
      'Build your daily vision board with a photo and intention';

  @override
  String get manifestScreenTitle => 'Manifestation Journal';

  @override
  String get manifestPhotoPickerHint => 'Choose a photo';

  @override
  String get manifestPhotoSemanticLabel => 'Uploaded photo';

  @override
  String get manifestIntentionHint => 'What do you want to manifest today?';

  @override
  String get manifestSaveButton => 'Save';

  @override
  String get manifestSavedMessage => 'Today\'s entry was saved.';

  @override
  String get manifestCoinRewardMessage => 'You earned 5 Zibo Coin!';

  @override
  String get manifestHistoryTitle => 'Past Entries';

  @override
  String get manifestHistoryEmpty =>
      'No entries yet. Add your first vision today!';

  @override
  String get manifestDetailCloseButton => 'Close';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileModuleDescription => 'See your photo, name and habit stats';

  @override
  String get profilePhotoSemanticLabel => 'Profile photo, tap to change';

  @override
  String get profileNameHint => 'Write your name';

  @override
  String get profileStatsSectionTitle => 'My Stats';

  @override
  String get profileStatMoneyTitle => 'Money Management';

  @override
  String get profileStatGratitudeManifestTitle => 'Gratitude & Manifest';

  @override
  String get profileStatConsistencyTitle => 'Consistency';

  @override
  String get profileStatSelfCareTitle => 'Self-Care & Health';

  @override
  String get profileStatMoneyEmpty =>
      'No data yet — start using Money & Savings!';

  @override
  String get profileStatGratitudeManifestEmpty =>
      'No data yet — start using the Gratitude Journal or Manifestation Journal!';

  @override
  String get profileStatConsistencyEmpty =>
      'No data yet — start using Goal Tracking!';

  @override
  String get profileStatSelfCareEmpty =>
      'No data yet — start using Water Tracking!';

  @override
  String get profileBondSectionTitle => 'Your Bond with Zibo';

  @override
  String get bondLevelScreenTitle => 'Bond Level with Zibo';

  @override
  String profileBondLevelRowSubtitle(int days) {
    return 'You\'ve been Zibo\'s buddy for $days days';
  }

  @override
  String profileBondNextLevelHint(int days, String tier) {
    return 'In $days days you\'ll become $tier';
  }

  @override
  String get profileBondMaxLevelHint =>
      'You\'ve already reached the top tier, congrats!';

  @override
  String get bondLevelNewBuddy => 'New Buddy';

  @override
  String get bondLevelGettingClose => 'Getting Close';

  @override
  String get bondLevelOldFriend => 'Old Friend';

  @override
  String get bondLevelSoulBuddy => 'Soul Buddy';

  @override
  String get bondLevelLifetimeBuddy => 'Lifetime Buddy';

  @override
  String get longestStreakScreenTitle => 'Longest Streak Record';

  @override
  String profileStreakRowSubtitle(int days) {
    return 'Your longest streak: $days days';
  }

  @override
  String get longestStreakScreenSubtitle =>
      'Your longest unbroken streak in Goal Tracking';

  @override
  String get longestStreakEncouragement =>
      'Mark a goal today to beat this record!';

  @override
  String get profileCostumeClosetRowTitle => 'Costume Closet';

  @override
  String get profileCostumeClosetEmpty =>
      'You don\'t own any costumes yet — pick one from the Store!';

  @override
  String get coinSummaryScreenTitle => 'Zibo Coin Summary';

  @override
  String get coinSummaryTotalEarnedLabel => 'Total Earned';

  @override
  String get coinSummaryTotalSpentLabel => 'Total Spent';

  @override
  String coinSummaryAmount(int amount) {
    return '$amount ZC';
  }

  @override
  String profileCoinSummaryRowSubtitle(int earned, int spent) {
    return 'Earned $earned ZC · Spent $spent ZC';
  }

  @override
  String get addressTermScreenTitle => 'Address Preference';

  @override
  String get addressTermScreenDescription =>
      'How should Zibo address you? What you type replaces \"buddy\" wherever it appears in your sayings.';

  @override
  String get addressTermFieldHint =>
      'How should Zibo call you? E.g.: Buddy, Boss, Champ...';

  @override
  String profileAddressTermRowSubtitle(String term) {
    return 'Zibo calls you \"$term\"';
  }

  @override
  String get favoriteQuotesScreenTitle => 'Favorite Sayings';

  @override
  String get favoriteQuotesEmpty =>
      'No favorite sayings yet — tap the heart icon on the Home screen to save the ones you love!';

  @override
  String get customMessagesButtonTooltip => 'Add your own message';

  @override
  String get customMessagesScreenTitle => 'My Custom Messages';

  @override
  String get customMessagesSubtitle =>
      'Add your own lines for Zibo to say every once in a while — they\'re mixed in with the standard sayings and shown at random.';

  @override
  String get customMessagesEmpty =>
      'You haven\'t added any custom messages yet.';

  @override
  String get customMessagesAddButton => 'Add New Message';

  @override
  String get customMessagesFieldHint => 'Have Zibo say...';

  @override
  String get customMessagesSaveButton => 'Save';

  @override
  String get customMessagesCancelButton => 'Cancel';

  @override
  String get customMessagesDeleteTooltip => 'Delete';

  @override
  String profileFavoriteQuotesRowSubtitle(int count) {
    return '$count favorite sayings';
  }

  @override
  String get profileShareCardRowTitle => 'Share Profile Card';

  @override
  String get profileShareCardRowSubtitle =>
      'Share your bond level and stats in one card';

  @override
  String get monthlyStatsRowTitle => 'Past Months\' Stats';

  @override
  String monthlyStatsRowSubtitle(int count) {
    return '$count months archived';
  }

  @override
  String get monthlyStatsScreenTitle => 'Past Months\' Stats';

  @override
  String get monthlyStatsEmpty =>
      'No archived months yet. They\'ll start appearing here at the end of the first month.';

  @override
  String get profileShareCardTitle => '🐣 My Bond with Zibo';

  @override
  String get onboardingLanguageStepTitle => 'Which language do you speak?';

  @override
  String get onboardingLanguageStepSubtitle =>
      'The rest of the app will open in the language you pick — you can change it later from Settings.';

  @override
  String get onboardingNameStepTitle => 'What should we call you?';

  @override
  String get onboardingNameStepSubtitle =>
      'Zibo will use this name with you — you can change it later from Profile.';

  @override
  String get onboardingContinueButton => 'Continue';

  @override
  String get onboardingNextButton => 'Next';

  @override
  String get onboardingSkipButton => 'Skip';

  @override
  String get onboardingStartButton => 'Let\'s Get Started!';

  @override
  String get onboardingGoalsDescription =>
      'Break your big dreams into small steps.';

  @override
  String get onboardingWaterDescription =>
      'Learn to keep even the smallest promise to your body.';

  @override
  String get onboardingGratitudeDescription =>
      'Look at your day by remembering what you already have.';

  @override
  String get onboardingMoodDescription =>
      'Don\'t ignore your feelings — track them.';

  @override
  String get onboardingDreamJournalDescription =>
      'Discover what your subconscious is telling you.';

  @override
  String get onboardingManifestDescription =>
      'Lay the life you dream of out in front of you.';

  @override
  String get onboardingStoreDescription =>
      'Add some color to your effort — dress Zibo in your own style.';

  @override
  String get onboardingProfileDescription =>
      'See your bond with Zibo and your progress at a glance.';

  @override
  String get onboardingClosingTitle => 'Your Journey with Zibo Begins!';

  @override
  String onboardingClosingMessage(String name) {
    return 'You\'re all set, $name! We\'ll make big changes with small steps — track your goals, take care of yourself, I\'ve got your back. Let\'s get started, buddy!';
  }

  @override
  String get googleLinkRowTitleUnlinked => 'Link Google Account';

  @override
  String get googleLinkRowTitleLinked => 'Your Google Account';

  @override
  String get googleLinkRowSubtitle => 'Keep your purchases and data safe';

  @override
  String get googleLinkSuccessMessage =>
      'Successfully linked to your Google account!';

  @override
  String get googleLinkFailedMessage =>
      'Something went wrong linking your account, try again.';

  @override
  String get googleAlreadyLinkedDialogTitle =>
      'This account is linked to another device';

  @override
  String get googleAlreadyLinkedDialogBody =>
      'This Google account is already associated with data on another device. If you switch to that account, your current progress on this device will be lost.';

  @override
  String get googleSignInInsteadButton => 'Sign in with Google';

  @override
  String get googleSignInSuccessMessage =>
      'Signed in with Google — your data has been restored!';

  @override
  String get googleSignInFailedMessage =>
      'Something went wrong signing in, try again.';

  @override
  String get googleLinkPromoTitle => 'Keep Your Purchases Safe';

  @override
  String get googleLinkPromoBody =>
      'Link your Google account so your Zibo Coins and progress don\'t get lost if you switch devices.';

  @override
  String get googleLinkPromoSkipButton => 'Skip for Now';

  @override
  String get googleSignOutButton => 'Sign Out';

  @override
  String get googleSwitchAccountButton => 'Switch Account';

  @override
  String get googleSignOutConfirmTitle => 'Sign Out';

  @override
  String get googleSignOutConfirmBody =>
      'Are you sure you want to sign out? Your data tied to this account won\'t be lost — it\'ll be restored the next time you sign in with the same Google account.';

  @override
  String get googleSignOutFailedMessage =>
      'Something went wrong signing out, try again.';

  @override
  String get referralScreenTitle => 'Invite a Friend';

  @override
  String get referralRowTitle => 'Invite a Friend';

  @override
  String get referralRowSubtitle => 'Invite someone, you both earn Zibo Coin';

  @override
  String get referralCodeLabel => 'Your Invite Code';

  @override
  String get referralCopyButton => 'Copy';

  @override
  String get referralCodeCopiedMessage => 'Invite code copied to clipboard!';

  @override
  String get referralShareButton => 'Share';

  @override
  String referralShareMessage(String code, int amount) {
    return 'I\'m trying out Zibo, join me! My invite code: $code — enter it under Profile > Invite a Friend and we\'ll both earn $amount Zibo Coin! 🎉';
  }

  @override
  String get referralRedeemFieldLabel => 'Have an invite code?';

  @override
  String get referralRedeemButton => 'Use Code';

  @override
  String get referralRedeemSuccessMessage =>
      'Your code was sent! Your coins will be added shortly.';

  @override
  String get referralRedeemSelfCodeError =>
      'You can\'t use your own invite code.';

  @override
  String get referralRedeemInvalidCodeError => 'Enter a valid invite code.';

  @override
  String get referralAlreadyRedeemedStatus =>
      'You\'ve already used an invite code, thanks!';

  @override
  String get referralUnavailableMessage =>
      'Invites aren\'t available right now, try again later.';

  @override
  String get founderBadgeTooltip => 'Founding Member';

  @override
  String get founderBadgePromoTitle => 'Earn the Founding Member Badge';

  @override
  String founderBadgePromoBody(int remaining) {
    return 'Be one of the first 500 people to link a Google account — $remaining spots left!';
  }

  @override
  String get founderBadgeClaimedMessage =>
      '🏅 You earned the Founding Member badge!';

  @override
  String get widgetTitleGoals => 'Goal Tracking';

  @override
  String get widgetTitleWater => 'Water Tracking';

  @override
  String get widgetTitleGratitude => 'Gratitude Journal';

  @override
  String get widgetTitleMood => 'Mood Tracker';

  @override
  String get widgetTitleManifest => 'Manifest Journal';

  @override
  String get widgetTitleDream => 'Dream Journal';

  @override
  String get widgetTitleMoney => 'Money & Savings';

  @override
  String get widgetTitleDailyRewards => 'Daily Login Rewards';

  @override
  String get widgetTitleMotivation => 'A Word From Zibo';

  @override
  String get widgetTitleProfileStats => 'My Stats';

  @override
  String get widgetGoalsEmptyHint => 'No goals added yet';

  @override
  String get widgetGoalsActiveHint => 'goals checked off today';

  @override
  String widgetWaterHint(String unit) {
    return '$unit · today';
  }

  @override
  String get widgetGratitudeDoneHint => 'Completed today';

  @override
  String get widgetGratitudeEmptyHint => 'Not written yet';

  @override
  String get widgetMoodSetHint => 'Today\'s mood';

  @override
  String get widgetMoodEmptyHint => 'Not set yet';

  @override
  String get widgetManifestActiveHint => 'entries added today';

  @override
  String get widgetManifestEmptyHint => 'No entries yet';

  @override
  String get widgetDreamActiveHint => 'dreams logged in total';

  @override
  String get widgetDreamEmptyHint => 'No dreams logged yet';

  @override
  String get widgetMoneyHint => 'net this month';

  @override
  String get widgetDailyRewardsClaimedHint => 'Claimed today ✓';

  @override
  String get widgetDailyRewardsAvailableHint => 'Available today 🎁';

  @override
  String widgetDailyRewardsPrimary(int day) {
    return 'Day $day/7';
  }

  @override
  String get widgetsScreenTitle => 'Home Screen Widgets';

  @override
  String get widgetsScreenIntro =>
      'Keep an eye on Zibo\'s modules right from your home screen. Tap the button next to a module to add it.';

  @override
  String get widgetsScreenAddButton => 'Add';

  @override
  String get widgetsScreenAddedSuccessMessage =>
      'Widget added! Check your home screen.';

  @override
  String get widgetsScreenAddFailedMessage =>
      'Couldn\'t add the widget — your device may not support this. You can also long-press your home screen and find Zibo in the widget list.';

  @override
  String get widgetsScreenAddSheetTitle => 'How to Add to Your Home Screen';

  @override
  String get widgetsScreenAddStep1 =>
      'Long-press an empty spot on your home screen.';

  @override
  String get widgetsScreenAddStep2 => 'Tap \"Widgets\" in the menu that opens.';

  @override
  String get widgetsScreenAddStep3 =>
      'Find Zibo in the list and drag the widget you want to your home screen.';

  @override
  String get widgetsScreenAddSheetGotIt => 'Got It';

  @override
  String get settingsWidgetsRowSubtitle =>
      'Track module status from your home screen';

  @override
  String get badgesTriggerTooltip => 'Badges';

  @override
  String get badgesGalleryTitle => 'Badges';

  @override
  String get badgeCategoryConsistency => 'Consistency Badges';

  @override
  String get badgeNameFirstStep => 'First Step';

  @override
  String get badgeNameWeekStreak => '1-Week Streak';

  @override
  String get badgeNameMonthStreak => '1-Month Streak';

  @override
  String get badgeNameIronWill => 'Iron Will';

  @override
  String get badgeNameUnyielding => 'Unyielding';

  @override
  String get badgeRequirementFirstStep =>
      'Complete your first 7-day goal cycle';

  @override
  String get badgeRequirementWeekStreak => 'Open the app 7 days in a row';

  @override
  String get badgeRequirementMonthStreak => 'Open the app 30 days in a row';

  @override
  String get badgeRequirementIronWill => 'Open the app 90 days in a row';

  @override
  String get badgeRequirementUnyielding => 'Open the app 180 days in a row';

  @override
  String get badgeClaimRewardButton => 'Claim Reward';

  @override
  String get badgeCategoryModuleMastery => 'Module Mastery Badges';

  @override
  String get badgeNameGratefulHeart => 'Grateful Heart';

  @override
  String get badgeNameWaterHero => 'Water Hero';

  @override
  String get badgeNameMoodChronicler => 'Mood Chronicler';

  @override
  String get badgeNameSavingsMaster => 'Savings Master';

  @override
  String get badgeNameDreamer => 'Dreamer';

  @override
  String get badgeNameDreamInterpreter => 'Dream Interpreter';

  @override
  String get badgeRequirementGratefulHeart =>
      'Create a total of 30 entries in the Gratitude Journal';

  @override
  String get badgeRequirementWaterHero =>
      'Log your water intake on a total of 30 days';

  @override
  String get badgeRequirementMoodChronicler =>
      'Create a total of 30 entries in Mood Tracking';

  @override
  String get badgeRequirementSavingsMaster =>
      'Create a total of 20 entries in Money & Savings';

  @override
  String get badgeRequirementDreamer =>
      'Create a total of 15 entries in the Manifest Journal';

  @override
  String get badgeRequirementDreamInterpreter =>
      'Create a total of 15 entries in the Dream Journal';

  @override
  String get badgeCategoryCollection => 'Collection Badges';

  @override
  String get badgeNameCollector => 'Collector';

  @override
  String get badgeNameFashionIcon => 'Fashion Icon';

  @override
  String get badgeNameFullWardrobe => 'Full Wardrobe';

  @override
  String get badgeNameThemeHunter => 'Theme Hunter';

  @override
  String get badgeRequirementCollector => 'Own 5 different costumes';

  @override
  String get badgeRequirementFashionIcon => 'Own 10 different costumes';

  @override
  String get badgeRequirementFullWardrobe => 'Own EVERY costume in the store';

  @override
  String get badgeRequirementThemeHunter => 'Own 3 different themes';

  @override
  String get badgeSpecialRewardComingSoon => 'Special Reward (Coming Soon)';

  @override
  String get badgeCategoryLoyalty => 'Loyalty Badges';

  @override
  String get badgeNameFirstWeek => 'First Week';

  @override
  String get badgeNameLoyalFriend => 'Loyal Friend';

  @override
  String get badgeNameAnniversary => 'Anniversary';

  @override
  String get badgeRequirementFirstWeek =>
      'Open the app on a total of 7 different days';

  @override
  String get badgeRequirementLoyalFriend =>
      'Open the app on a total of 100 different days';

  @override
  String get badgeRequirementAnniversary =>
      'It\'s been 1 year since you met Zibo';

  @override
  String get badgeCategorySocial => 'Social Badges';

  @override
  String get badgeNameFirstShare => 'First Share';

  @override
  String get badgeNameAmbassador => 'Ambassador';

  @override
  String get badgeNameCommunityFounder => 'Community Founder';

  @override
  String get badgeRequirementFirstShare =>
      'Share a Zibo card for the first time';

  @override
  String get badgeRequirementAmbassador =>
      'Successfully invite 1 friend with Invite a Friend';

  @override
  String get badgeRequirementCommunityFounder =>
      'Successfully invite 5 friends with Invite a Friend';
}
