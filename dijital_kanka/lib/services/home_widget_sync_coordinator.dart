import 'dart:async';

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../models/goal.dart';
import '../models/money_entry.dart';
import '../models/water_entry.dart';
import '../providers/currency_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../providers/dream_journal_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
import '../utils/currency_format.dart';
import '../utils/widget_module.dart';
import '../utils/widget_status.dart';
import 'home_widget_service.dart';

/// Sekiz modülün ana ekran widget'larını GÜNCEL tutan tek koordinatör —
/// bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü. Hiçbir provider'ın
/// constructor'ına dokunulmadan (8 dosyayı invaziv şekilde değiştirmek
/// yerine) her provider'a DIŞARIDAN bir `addListener` ekleyip, ilgili
/// provider değiştiğinde SADECE o modülün widget'ını yeniden hesaplayıp
/// [HomeWidgetService.pushStatus] ile native tarafa gönderiyor —
/// `CostumeProvider.reconcileGoalUnlocks`'ın "constructor'dan değil,
/// parametre olarak al" felsefesiyle AYNI gerekçe: bu obje diğer
/// provider'lara KALICI bağımlı değil, yalnızca onları dinliyor.
///
/// `RootScreen`'in `initState`'inde BİR KEZ oluşturulup [syncAll] ile ilk
/// senkronizasyon yapılıyor, `dispose()`'da TÜM listener'lar temizleniyor.
class HomeWidgetSyncCoordinator {
  HomeWidgetSyncCoordinator({
    required this.context,
    required this.service,
    required this.trustedTime,
    required this.goals,
    required this.water,
    required this.gratitude,
    required this.mood,
    required this.manifest,
    required this.dream,
    required this.money,
    required this.currency,
    required this.dailyRewards,
  }) {
    goals.addListener(_syncGoals);
    water.addListener(_syncWater);
    gratitude.addListener(_syncGratitude);
    mood.addListener(_syncMood);
    manifest.addListener(_syncManifest);
    dream.addListener(_syncDream);
    money.addListener(_syncMoney);
    currency.addListener(_syncMoney);
    dailyRewards.addListener(_syncDailyRewards);
  }

  /// `RootScreen`'in KENDİ, uygulama ömrü boyunca geçerli kalan context'i
  /// — her senkronizasyonda [AppLocalizations.of] TAZE olarak buradan
  /// okunuyor (önbelleklenmiyor) ki kullanıcı dil değiştirdikten SONRAKİ
  /// bir güncelleme de doğru dilde gitsin.
  final BuildContext context;
  final HomeWidgetService service;
  final TrustedTimeProvider trustedTime;
  final GoalsProvider goals;
  final WaterProvider water;
  final GratitudeProvider gratitude;
  final MoodProvider mood;
  final ManifestProvider manifest;
  final DreamJournalProvider dream;
  final MoneyProvider money;
  final CurrencyProvider currency;
  final DailyRewardsProvider dailyRewards;

  DateTime get _today => Goal.dateOnly(trustedTime.now());

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// Uygulama açılışında VE bir dil değişiminde (bkz. `RootScreen`'in
  /// `LocaleProvider`'ı ayrıca dinleyip bunu çağırması) TÜM widget'ları
  /// BİR KEZDE günceller.
  void syncAll() {
    _syncGoals();
    _syncWater();
    _syncGratitude();
    _syncMood();
    _syncManifest();
    _syncDream();
    _syncMoney();
    _syncDailyRewards();
  }

  void dispose() {
    goals.removeListener(_syncGoals);
    water.removeListener(_syncWater);
    gratitude.removeListener(_syncGratitude);
    mood.removeListener(_syncMood);
    manifest.removeListener(_syncManifest);
    dream.removeListener(_syncDream);
    money.removeListener(_syncMoney);
    currency.removeListener(_syncMoney);
    dailyRewards.removeListener(_syncDailyRewards);
  }

  void _syncGoals() {
    final today = _today;
    final doneToday = goals.goals.where((g) => g.completedDates.contains(today)).length;
    final status = goalsWidgetStatus(_l10n, doneToday: doneToday, totalGoals: goals.goals.length);
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.goals,
        title: _l10n.widgetTitleGoals,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncWater() {
    final unitLabel = water.unit == WaterUnit.glass ? _l10n.waterUnitGlass : _l10n.waterUnitBottle;
    final status = waterWidgetStatus(
      _l10n,
      todayCount: water.todayCount,
      goalUnitCount: water.goalUnitCount,
      unitLabel: unitLabel,
    );
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.water,
        title: _l10n.widgetTitleWater,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncGratitude() {
    final status = gratitudeWidgetStatus(_l10n, isTodayComplete: gratitude.isTodayComplete);
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.gratitude,
        title: _l10n.widgetTitleGratitude,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncMood() {
    final status = moodWidgetStatus(_l10n, todayMoodEmoji: mood.todayMood?.emoji);
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.mood,
        title: _l10n.widgetTitleMood,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncManifest() {
    final today = _today;
    final entriesToday = manifest.history
        .where((e) => Goal.dateOnly(e.date).isAtSameMomentAs(today))
        .length;
    final status = manifestWidgetStatus(_l10n, entriesToday: entriesToday);
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.manifest,
        title: _l10n.widgetTitleManifest,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncDream() {
    final status = dreamWidgetStatus(_l10n, totalDreams: dream.dreams.length);
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.dream,
        title: _l10n.widgetTitleDream,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncMoney() {
    final now = trustedTime.now();
    bool isThisMonth(DateTime d) => d.year == now.year && d.month == now.month;
    double sumThisMonth(MoneyCategory category) => money
        .entriesFor(category)
        .where((e) => isThisMonth(e.date))
        .fold(0.0, (total, e) => total + e.amount);
    final net =
        sumThisMonth(MoneyCategory.income) +
        sumThisMonth(MoneyCategory.saving) -
        sumThisMonth(MoneyCategory.expense);
    final status = moneyWidgetStatus(
      _l10n,
      formattedNetAmount: formatCurrencyAmount(net, currency.currencyCode),
    );
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.money,
        title: _l10n.widgetTitleMoney,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }

  void _syncDailyRewards() {
    final status = dailyRewardsWidgetStatus(
      _l10n,
      todayIndex: dailyRewards.todayIndex,
      daysPerCycle: CoinEconomy.dailyLoginRewards.length,
      isTodayClaimed: dailyRewards.isTodayClaimed,
    );
    unawaited(
      service.pushStatus(
        ZiboWidgetModule.dailyRewards,
        title: _l10n.widgetTitleDailyRewards,
        primary: status.primary,
        secondary: status.secondary,
        progress: status.progress,
      ),
    );
  }
}
