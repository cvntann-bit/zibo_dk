import '../l10n/app_localizations.dart';
import '../models/home_quick_module.dart';

/// Ana Sayfa'nın değiştirilebilir mini widget slotlarındaki 8 modülün ortak
/// emoji/başlık/açıklama eşlemesi — hem kompakt kart (`home_screen.dart`)
/// hem seçim sheet'i (`home_quick_module_picker_sheet.dart`) BURADAN okur ki
/// iki yerde aynı eşleme birbirinden bağımsız SÜRÜKLENMESİN.
String homeQuickModuleEmoji(HomeQuickModule module) => switch (module) {
  HomeQuickModule.water => '💧',
  HomeQuickModule.goal => '🚩',
  HomeQuickModule.dream => '🌙',
  HomeQuickModule.gratitude => '❤️',
  HomeQuickModule.mood => '🙂',
  HomeQuickModule.manifest => '✨',
  HomeQuickModule.money => '💰',
  HomeQuickModule.focus => '⏱️',
};

/// Kompakt kartın kendi başlığı — Su/Hedef için (mockup'tan beri) KISA ad
/// ("Su"/"Hedef"), diğer modüller zaten kısa olan kendi tek adını kullanır.
String homeQuickModuleCardTitle(HomeQuickModule module, AppLocalizations l10n) => switch (module) {
  HomeQuickModule.water => l10n.homeWaterWidgetTitle,
  HomeQuickModule.goal => l10n.homeGoalWidgetTitle,
  HomeQuickModule.dream => l10n.dreamJournalTooltip,
  HomeQuickModule.gratitude => l10n.gratitudeSettingsTitle,
  HomeQuickModule.mood => l10n.moodSettingsTitle,
  HomeQuickModule.manifest => l10n.manifestSettingsTitle,
  HomeQuickModule.money => l10n.moneyScreenTitle,
  HomeQuickModule.focus => l10n.focusTimerTooltip,
};

/// Seçim sheet'indeki satır başlığı — Su/Hedef için TAM ad (`modules_menu_
/// sheet.dart`'taki diğer modüllerle aynı uzunlukta görünsün diye), diğerleri
/// kart başlığıyla aynı.
String homeQuickModulePickerTitle(HomeQuickModule module, AppLocalizations l10n) => switch (module) {
  HomeQuickModule.water => l10n.waterSettingsTitle,
  HomeQuickModule.goal => l10n.tabGoalTracking,
  _ => homeQuickModuleCardTitle(module, l10n),
};

/// Seçim sheet'indeki satırın alt açıklaması. Hedef'in `modules_menu_sheet.
/// dart`'taki diğer modüllerin sahip olduğu bir açıklama metni karşılığı YOK
/// — bu yüzden `null` döner (satırda yalnızca başlık gösterilir).
String? homeQuickModuleDescription(HomeQuickModule module, AppLocalizations l10n) => switch (module) {
  HomeQuickModule.water => l10n.waterModuleDescription,
  HomeQuickModule.goal => null,
  HomeQuickModule.dream => l10n.dreamModuleDescription,
  HomeQuickModule.gratitude => l10n.gratitudeModuleDescription,
  HomeQuickModule.mood => l10n.moodModuleDescription,
  HomeQuickModule.manifest => l10n.manifestModuleDescription,
  HomeQuickModule.money => l10n.moneyModuleDescription,
  HomeQuickModule.focus => l10n.focusModuleDescription,
};
