import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/zibo_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../models/goal.dart';
import '../models/money_entry.dart';
import '../models/water_entry.dart';
import '../providers/currency_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
import '../utils/address_term.dart';
import '../utils/currency_format.dart';
import '../utils/profile_stats.dart';
import '../utils/widget_module.dart';
import '../utils/widget_status.dart';
import 'home_widget_service.dart';

/// Beş modülün (Su Takibi/Para ve Birikim/Günlük Giriş Ödülleri/"Zibo'nun
/// Sözü"/"İstatistiklerim") ana ekran widget'larını GÜNCEL tutan tek
/// koordinatör — bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü. Hiçbir
/// provider'ın constructor'ına dokunulmadan (dosyaları invaziv şekilde
/// değiştirmek yerine) her provider'a DIŞARIDAN bir `addListener` ekleyip,
/// ilgili provider değiştiğinde SADECE o modülün widget'ını yeniden
/// hesaplayıp [HomeWidgetService.pushStatus]/[HomeWidgetService.pushCarousel]
/// ile native tarafa gönderiyor — `CostumeProvider.reconcileGoalUnlocks`'ın
/// "constructor'dan değil, parametre olarak al" felsefesiyle AYNI gerekçe:
/// bu obje diğer provider'lara KALICI bağımlı değil, yalnızca onları
/// dinliyor.
///
/// **2026 güncellemesi — beş "basit günlük/checkbox" widget'ı (Hedef
/// Takibi/Rüya Günlüğü/Şükran Günlüğü/Ruh Hali Takibi/Manifest Günlüğü)
/// TAMAMEN KALDIRILDI.** `goals`/`gratitude`/`manifest` provider'ları
/// KENDİ widget'larını kaybetti ama listede KALDI — artık yalnızca
/// [_syncProfileStats]'ın `ProfileStats.compute(...)` girdisi olarak
/// kullanılıyorlar (bkz. altta). `dream`/`mood` provider'ları ise HİÇBİR
/// widget'a artık katkı vermiyor — `ProfileStats.compute()` bu ikisini
/// GEREKTİRMİYOR (bkz. o fonksiyonun imzası), bu yüzden alanları/parametreleri
/// TAMAMEN kaldırıldı.
///
/// `RootScreen`'in `initState`'inde BİR KEZ oluşturulup [syncAll] ile ilk
/// senkronizasyon yapılıyor, `dispose()`'da TÜM listener'lar temizleniyor.
///
/// **"Zibo'nun Sözü" ([_syncMotivation]) VE "İstatistiklerim"
/// ([_syncProfileStats]) widget'ları diğer üçünden FARKLI davranıyor** —
/// ikisinin de KENDİ tek bir provider'ı yok (birden fazla provider'ın
/// birleşimine dayanıyorlar), bu yüzden [syncAll] her çağrıldığında
/// (uygulama açılışı + dil değişimi — `RootScreen`'in zaten kurduğu AYNI
/// tetikleyiciler) yeniden hesaplanıyorlar. Diğer üç widget'ın listener'ları
/// `syncAll()`'ı TETİKLEMİYOR (bkz. yukarıdaki mimari notu), bu yüzden bu
/// ikisi zaten gürültüsüz/ölçülü bir sıklıkta tazeleniyor.
class HomeWidgetSyncCoordinator {
  HomeWidgetSyncCoordinator({
    required this.context,
    required this.service,
    required this.trustedTime,
    required this.goals,
    required this.water,
    required this.gratitude,
    required this.manifest,
    required this.money,
    required this.currency,
    required this.dailyRewards,
    required this.profile,
    Random? random,
  }) : _random = random ?? Random() {
    water.addListener(_syncWater);
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

  /// Artık kendi widget'ı YOK — yalnızca [_syncProfileStats]'ın
  /// `ProfileStats.compute(...)` girdisi.
  final GoalsProvider goals;
  final WaterProvider water;

  /// Artık kendi widget'ı YOK — yalnızca [_syncProfileStats]'ın
  /// `ProfileStats.compute(...)` girdisi.
  final GratitudeProvider gratitude;

  /// Artık kendi widget'ı YOK — yalnızca [_syncProfileStats]'ın
  /// `ProfileStats.compute(...)` girdisi.
  final ManifestProvider manifest;
  final MoneyProvider money;
  final CurrencyProvider currency;
  final DailyRewardsProvider dailyRewards;

  /// "Zibo'nun Sözü" widget'ının hitap tercihini (bkz. [applyAddressTerm])
  /// okumak için — bu provider'a bir `addListener` EKLENMEDİ (bkz. sınıf
  /// dokümantasyonu), yalnızca [_syncMotivation] çalıştığında AN'lık olarak
  /// okunuyor.
  final ProfileProvider profile;

  /// Testte deterministik bir söz seçimi enjekte edebilmek için (`CoinProvider`'ın
  /// Şans Çarkı'ndaki AYNI "enjekte edilebilir Random" deseni).
  final Random _random;

  /// "Zibo'nun Sözü" carousel'inin bir turda kaç FARKLI söz taşıyacağı —
  /// her biri `ViewFlipper`'da 3 dakika (`widget_motivation.xml`'deki
  /// `flipInterval`) gösterildiği için 8 söz ~24 dakikalık bir tam döngü
  /// yapıyor, uygulama her açılışta/dil değişiminde yeniden karıştırıyor.
  static const _motivationQuoteCount = 8;

  DateTime get _today => Goal.dateOnly(trustedTime.now());

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// Uygulama açılışında VE bir dil değişiminde (bkz. `RootScreen`'in
  /// `LocaleProvider`'ı ayrıca dinleyip bunu çağırması) TÜM widget'ları
  /// BİR KEZDE günceller.
  void syncAll() {
    _syncWater();
    _syncMoney();
    _syncDailyRewards();
    _syncMotivation();
    _syncProfileStats();
  }

  void dispose() {
    water.removeListener(_syncWater);
    money.removeListener(_syncMoney);
    currency.removeListener(_syncMoney);
    dailyRewards.removeListener(_syncDailyRewards);
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

  void _syncMoney() {
    final now = trustedTime.now();
    bool isThisMonth(DateTime d) => d.year == now.year && d.month == now.month;
    // **2026 güncellemesi — çoklu para birimi.** Widget'ın "bu ayki net
    // tutar" özeti hâlâ TEK bir sayı olmak ZORUNDA (RemoteViews'ın basit
    // metin alanı) — otomatik kur çevirisi YAPMAMAK için (kullanıcının açık
    // isteği, bkz. `MoneyCategoryCard`/`MoneyTrendChart`'taki AYNI karar)
    // yalnızca o ANKİ SEÇİLİ global para birimindeki (`currency.
    // currencyCode`) kayıtlar toplanıyor — BAŞKA para birimindeki kayıtlar
    // bu TEK widget metriğinde sessizce dışarıda kalıyor (kartlardaki/
    // grafikteki asıl çoklu-para-birimi deneyimi bundan ETKİLENMİYOR).
    double sumThisMonth(MoneyCategory category) => money
        .entriesFor(category)
        .where((e) => isThisMonth(e.date) && e.currencyCode == currency.currencyCode)
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

  void _syncMotivation() {
    final locale = Localizations.localeOf(context);
    final pool = [...ziboMessagesForLocale(locale)]..shuffle(_random);
    final count = min(_motivationQuoteCount, pool.length);
    final items = pool
        .take(count)
        .map((raw) => CarouselItem(value: applyAddressTerm(raw, profile.addressTerm, locale)))
        .toList();
    unawaited(
      service.pushCarousel(ZiboWidgetModule.motivation, title: _l10n.widgetTitleMotivation, items: items),
    );
  }

  void _syncProfileStats() {
    final stats = ProfileStats.compute(
      money: money,
      gratitude: gratitude,
      manifest: manifest,
      goals: goals,
      water: water,
      now: trustedTime.now(),
    );
    final items = stats
        .map(
          (stat) => CarouselItem(
            label: _profileStatTitle(stat.category),
            value: stat.hasData ? '${stat.score.toStringAsFixed(1)}/10' : '—',
            progress: stat.hasData ? (stat.score / 10 * 100).round() : null,
            hasData: stat.hasData,
          ),
        )
        .toList();
    unawaited(
      service.pushCarousel(ZiboWidgetModule.profileStats, title: _l10n.widgetTitleProfileStats, items: items),
    );
  }

  /// `lib/widgets/profile_stat_card.dart`'taki AYNI id→ARB-getter eşlemesi —
  /// Profil ekranıyla BİREBİR aynı kategori başlıkları, ayrı bir çeviri
  /// SETİ eklenmedi.
  String _profileStatTitle(ProfileStatCategory category) {
    switch (category) {
      case ProfileStatCategory.money:
        return _l10n.profileStatMoneyTitle;
      case ProfileStatCategory.gratitudeManifest:
        return _l10n.profileStatGratitudeManifestTitle;
      case ProfileStatCategory.consistency:
        return _l10n.profileStatConsistencyTitle;
      case ProfileStatCategory.selfCareHealth:
        return _l10n.profileStatSelfCareTitle;
    }
  }
}
