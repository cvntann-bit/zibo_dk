import '../l10n/app_localizations.dart';

/// Bir ana ekran widget'ının o an göstermesi gereken içerik — bkz.
/// CLAUDE.md "Ana Ekran Widget'ları" bölümü. [progress] `null` ise widget
/// ilerleme çubuğunu GİZLER (yalnızca Hedef Takibi/Su Takibi/Günlük Giriş
/// Ödülleri gibi doğal bir "X/Y" oranı olan modüllerde dolduruluyor).
class ZiboWidgetStatus {
  const ZiboWidgetStatus({required this.primary, required this.secondary, this.progress});

  final String primary;
  final String secondary;
  final int? progress;
}

int _percent(num done, num total) {
  if (total <= 0) return 0;
  return ((done / total) * 100).round().clamp(0, 100);
}

/// Aşağıdaki fonksiyonların HEPSİ saf (yan etkisiz) — provider
/// nesnelerinin KENDİSİNİ değil, o an ihtiyaç duydukları birkaç ilkel
/// değeri alıyor; bu sayede `flutter test`'te gerçek bir widget/provider
/// kurmadan doğrudan test edilebiliyorlar (bkz.
/// `test/widget_status_test.dart`).
///
/// **2026 güncellemesi** — beş "basit günlük/checkbox" widget'ının
/// (Hedef Takibi/Rüya Günlüğü/Şükran Günlüğü/Ruh Hali Takibi/Manifest
/// Günlüğü) durum fonksiyonları (`goalsWidgetStatus`, `gratitudeWidgetStatus`,
/// `moodWidgetStatus`, `manifestWidgetStatus`, `dreamWidgetStatus`) BURADAN
/// KOMPLE KALDIRILDI — kullanıcı isteğiyle, bu widget'ların kendisi
/// kaldırıldığı için (bkz. `widget_module.dart` başındaki not). Bu dört
/// provider'ın verileri artık kaybolmuyor, `profile_stats.dart` üzerinden
/// [ZiboWidgetModule.profileStats] carousel'ine besleniyor.
ZiboWidgetStatus waterWidgetStatus(
  AppLocalizations l10n, {
  required int todayCount,
  required int goalUnitCount,
  required String unitLabel,
}) {
  return ZiboWidgetStatus(
    primary: '$todayCount/$goalUnitCount',
    secondary: l10n.widgetWaterHint(unitLabel),
    progress: _percent(todayCount, goalUnitCount),
  );
}

ZiboWidgetStatus gratitudeWidgetStatus(AppLocalizations l10n, {required bool isTodayComplete}) {
  return ZiboWidgetStatus(
    primary: isTodayComplete ? '✓' : '—',
    secondary: isTodayComplete ? l10n.widgetGratitudeDoneHint : l10n.widgetGratitudeEmptyHint,
  );
}

ZiboWidgetStatus moodWidgetStatus(AppLocalizations l10n, {required String? todayMoodEmoji}) {
  if (todayMoodEmoji == null) {
    return ZiboWidgetStatus(primary: '—', secondary: l10n.widgetMoodEmptyHint);
  }
  return ZiboWidgetStatus(primary: todayMoodEmoji, secondary: l10n.widgetMoodSetHint);
}

ZiboWidgetStatus manifestWidgetStatus(AppLocalizations l10n, {required int entriesToday}) {
  return ZiboWidgetStatus(
    primary: '$entriesToday',
    secondary: entriesToday > 0 ? l10n.widgetManifestActiveHint : l10n.widgetManifestEmptyHint,
  );
}

ZiboWidgetStatus dreamWidgetStatus(AppLocalizations l10n, {required int totalDreams}) {
  return ZiboWidgetStatus(
    primary: '$totalDreams',
    secondary: totalDreams > 0 ? l10n.widgetDreamActiveHint : l10n.widgetDreamEmptyHint,
  );
}

ZiboWidgetStatus moneyWidgetStatus(AppLocalizations l10n, {required String formattedNetAmount}) {
  return ZiboWidgetStatus(primary: formattedNetAmount, secondary: l10n.widgetMoneyHint);
}

ZiboWidgetStatus dailyRewardsWidgetStatus(
  AppLocalizations l10n, {
  required int todayIndex,
  required int daysPerCycle,
  required bool isTodayClaimed,
}) {
  // `todayIndex` teorik olarak (bkz. DailyRewardsProvider) geçici bir
  // güvenilir-zaman anomalisinde döngü dışına taşabilir — widget'ın asla
  // "Gün 19/7" gibi anlamsız bir şey GÖSTERMEMESİ için 0..daysPerCycle-1
  // aralığına kırpılıyor (provider'ın kendi `reconcileForToday`'i zaten
  // bunu düzeltiyor, bu yalnızca EK bir güvenlik ağı).
  final safeIndex = todayIndex.clamp(0, daysPerCycle - 1);
  return ZiboWidgetStatus(
    primary: l10n.widgetDailyRewardsPrimary(safeIndex + 1),
    secondary: isTodayClaimed
        ? l10n.widgetDailyRewardsClaimedHint
        : l10n.widgetDailyRewardsAvailableHint,
    progress: _percent(safeIndex + 1, daysPerCycle),
  );
}

/// "Zibo'nun Sözü" widget'ı (bkz. `widget_motivation.xml`) — [quote] ZATEN
/// seçilmiş/kişiselleştirilmiş (bkz. `HomeWidgetSyncCoordinator._syncMotivation`,
/// hitap tercihi UYGULANMIŞ hâliyle) hazır bir metin; bu fonksiyon yalnızca
/// diğer sekiziyle AYNI `ZiboWidgetStatus` şekline SARIYOR (`secondary` bu
/// widget'ta kullanılmıyor, boş — karakter görseli + söz metni zaten
/// kendi başına yeterli, `progress` de yok, bir "ilerleme" kavramı taşımıyor).
ZiboWidgetStatus motivationWidgetStatus(AppLocalizations l10n, {required String quote}) {
  return ZiboWidgetStatus(primary: quote, secondary: '');
}
