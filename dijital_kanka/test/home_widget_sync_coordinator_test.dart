// HomeWidgetSyncCoordinator'ın gerçek provider'ları dinleyip doğru modülü,
// doğru içerikle `HomeWidgetService.pushStatus`/`pushCarousel`'a ilettiğini
// doğrudan (tam bir RootScreen kurmadan, sahte bir servisle) test eder —
// bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü. **2026 güncellemesi** — beş
// "basit günlük/checkbox" widget'ı kaldırıldı; goals/gratitude/manifest
// artık kendi widget'ları YOK, yalnızca `ProfileStats.compute(...)`'un
// girdisi (`_syncProfileStats`, YALNIZCA `syncAll()`'da tetikleniyor, ayrı
// bir listener YOK). Beş modülün TAMAMI (water/money/dailyRewards/
// motivation/profileStats) + genel "yalnızca ilgili modül güncellenir"
// garantisi kapsanıyor; içerik hesaplama mantığının kendisi zaten
// `widget_status_test.dart`'ta ayrıca ve tam test ediliyor.
//
// `HomeWidgetSyncCoordinator` yalnızca `AppLocalizations.of(context)` için
// bir `BuildContext`'e ihtiyaç duyuyor — bu yüzden `testWidgets` ile
// minimal bir `MaterialApp` pump'layıp gerçek bir `Localizations` ağacına
// sahip bir context yakalanıyor (düz `test()`'te sahte bir `BuildContext`
// bunu karşılayamaz, `Localizations.of` gerçek bir InheritedWidget
// bekliyor).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/zibo_messages.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/models/money_entry.dart';
import 'package:dijital_kanka/providers/currency_provider.dart';
import 'package:dijital_kanka/providers/daily_rewards_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/trusted_time_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/services/home_widget_service.dart';
import 'package:dijital_kanka/services/home_widget_sync_coordinator.dart';
import 'package:dijital_kanka/services/trusted_time_service.dart';
import 'package:dijital_kanka/utils/widget_module.dart';

class _FixedTimeService extends TrustedTimeService {
  _FixedTimeService(this.fixed);
  final DateTime fixed;

  @override
  Future<DateTime?> fetchNetworkTime() async => fixed;
}

class _RecordingHomeWidgetService implements HomeWidgetService {
  final List<(ZiboWidgetModule, String, String, String, int?)> statusCalls = [];
  final List<(ZiboWidgetModule, String, List<CarouselItem>)> carouselCalls = [];

  @override
  Future<void> pushStatus(
    ZiboWidgetModule module, {
    required String title,
    required String primary,
    required String secondary,
    int? progress,
  }) async {
    statusCalls.add((module, title, primary, secondary, progress));
  }

  @override
  Future<void> pushCarousel(
    ZiboWidgetModule module, {
    required String title,
    required List<CarouselItem> items,
  }) async {
    carouselCalls.add((module, title, items));
  }

  @override
  Future<bool> requestPin(ZiboWidgetModule module) async => true;
}

/// Bir testin ihtiyaç duyduğu her şeyi (sahte servis + provider'lar + gerçek
/// bir `Localizations` ağacına sahip `BuildContext` + kurulu koordinatör)
/// TEK çağrıda hazırlar.
class _Harness {
  _Harness({
    required this.service,
    required this.goals,
    required this.water,
    required this.gratitude,
    required this.manifest,
    required this.money,
    required this.currency,
    required this.dailyRewards,
    required this.profile,
    required this.coordinator,
  });

  final _RecordingHomeWidgetService service;
  final GoalsProvider goals;
  final WaterProvider water;
  final GratitudeProvider gratitude;
  final ManifestProvider manifest;
  final MoneyProvider money;
  final CurrencyProvider currency;
  final DailyRewardsProvider dailyRewards;
  final ProfileProvider profile;
  final HomeWidgetSyncCoordinator coordinator;
}

Future<_Harness> _buildHarness(WidgetTester tester, {Random? random}) async {
  final fixedNow = DateTime(2026, 1, 10);
  DateTime now() => fixedNow;

  final service = _RecordingHomeWidgetService();
  final trustedTime = TrustedTimeProvider(timeService: _FixedTimeService(fixedNow));
  final goals = GoalsProvider(now: now);
  final water = WaterProvider(now: now);
  final gratitude = GratitudeProvider(now: now);
  final manifest = ManifestProvider(now: now);
  final money = MoneyProvider(now: now);
  final currency = CurrencyProvider();
  final dailyRewards = DailyRewardsProvider(now: now);
  final profile = ProfileProvider(now: now);

  late BuildContext capturedContext;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  final coordinator = HomeWidgetSyncCoordinator(
    context: capturedContext,
    service: service,
    trustedTime: trustedTime,
    goals: goals,
    water: water,
    gratitude: gratitude,
    manifest: manifest,
    money: money,
    currency: currency,
    dailyRewards: dailyRewards,
    profile: profile,
    random: random,
  );

  return _Harness(
    service: service,
    goals: goals,
    water: water,
    gratitude: gratitude,
    manifest: manifest,
    money: money,
    currency: currency,
    dailyRewards: dailyRewards,
    profile: profile,
    coordinator: coordinator,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('syncAll TÜM beş modülü BİR KEZ günceller', (tester) async {
    final h = await _buildHarness(tester);
    h.coordinator.syncAll();
    final statusModules = h.service.statusCalls.map((c) => c.$1);
    final carouselModules = h.service.carouselCalls.map((c) => c.$1);
    final updatedModules = {...statusModules, ...carouselModules};
    expect(updatedModules, ZiboWidgetModule.values.toSet());
    h.coordinator.dispose();
  });

  testWidgets(
    'syncAll "Zibo\'nun Sözü" carousel\'ine havuzdan sekiz FARKLI söz gönderir',
    (tester) async {
      final h = await _buildHarness(tester);
      h.coordinator.syncAll();
      final call = h.service.carouselCalls.singleWhere((c) => c.$1 == ZiboWidgetModule.motivation);
      final locale = Localizations.localeOf(h.coordinator.context);
      final pool = ziboMessagesForLocale(locale);
      final values = call.$3.map((item) => item.value).toSet();
      expect(values, hasLength(8));
      // Varsayılan hitap tercihi ('Kanka') no-op olduğu için gönderilen
      // her söz havuzda BİREBİR bulunmalı.
      expect(values.every(pool.contains), isTrue);
      h.coordinator.dispose();
    },
  );

  testWidgets(
    'syncAll "İstatistiklerim" carousel\'ine dört kategoriyi gönderir, veri yoksa "—"/hasData false',
    (tester) async {
      final h = await _buildHarness(tester);
      h.coordinator.syncAll();
      final call = h.service.carouselCalls.singleWhere((c) => c.$1 == ZiboWidgetModule.profileStats);
      expect(call.$3, hasLength(4));
      for (final item in call.$3) {
        expect(item.hasData, isFalse);
        expect(item.value, '—');
        expect(item.progress, isNull);
        expect(item.label, isNotNull);
      }
      h.coordinator.dispose();
    },
  );

  testWidgets(
    'Kategoriye veri eklenip syncAll TEKRAR çağrılınca İstatistiklerim carousel\'i günceller',
    (tester) async {
      final h = await _buildHarness(tester);
      h.money.addEntry(MoneyCategory.saving, name: 'Birikim', amount: 500);
      h.coordinator.syncAll();
      final call = h.service.carouselCalls.lastWhere((c) => c.$1 == ZiboWidgetModule.profileStats);
      final moneyItem = call.$3.first; // ProfileStatCategory sırasında ilk = Para Yönetimi
      expect(moneyItem.hasData, isTrue);
      expect(moneyItem.value, contains('/10'));
      expect(moneyItem.progress, inInclusiveRange(0, 100));
      h.coordinator.dispose();
    },
  );

  testWidgets('WaterProvider değişince YALNIZCA Su Takibi widget\'ı güncellenir', (tester) async {
    final h = await _buildHarness(tester);
    h.service.statusCalls.clear();
    h.service.carouselCalls.clear();
    h.water.incrementUnit();
    expect(h.service.statusCalls, hasLength(1));
    expect(h.service.carouselCalls, isEmpty);
    expect(h.service.statusCalls.single.$1, ZiboWidgetModule.water);
    expect(h.service.statusCalls.single.$3, '1/8');
    h.coordinator.dispose();
  });

  testWidgets(
    'DailyRewardsProvider değişince YALNIZCA Günlük Giriş Ödülleri widget\'ı güncellenir',
    (tester) async {
      final h = await _buildHarness(tester);
      h.service.statusCalls.clear();
      h.service.carouselCalls.clear();
      h.dailyRewards.claimToday();
      expect(h.service.statusCalls, hasLength(1));
      expect(h.service.carouselCalls, isEmpty);
      expect(h.service.statusCalls.single.$1, ZiboWidgetModule.dailyRewards);
      h.coordinator.dispose();
    },
  );

  testWidgets('CurrencyProvider değişince Para ve Birikim widget\'ı güncellenir', (tester) async {
    final h = await _buildHarness(tester);
    h.service.statusCalls.clear();
    h.service.carouselCalls.clear();
    h.currency.setCurrencyCode('USD');
    expect(h.service.statusCalls, hasLength(1));
    expect(h.service.statusCalls.single.$1, ZiboWidgetModule.money);
    h.coordinator.dispose();
  });

  testWidgets(
    'GoalsProvider değişimi ARTIK hiçbir ANLIK widget güncellemesi tetiklemez (kendi widget\'ı yok)',
    (tester) async {
      final h = await _buildHarness(tester);
      h.service.statusCalls.clear();
      h.service.carouselCalls.clear();
      h.goals.addGoal('Kitap oku');
      expect(h.service.statusCalls, isEmpty);
      expect(h.service.carouselCalls, isEmpty);
      h.coordinator.dispose();
    },
  );

  testWidgets(
    'dispose() sonrası HİÇBİR provider değişikliği artık widget güncellemesi tetiklemez',
    (tester) async {
      final h = await _buildHarness(tester);
      h.coordinator.dispose();
      h.service.statusCalls.clear();
      h.service.carouselCalls.clear();
      h.water.incrementUnit();
      h.dailyRewards.claimToday();
      expect(h.service.statusCalls, isEmpty);
      expect(h.service.carouselCalls, isEmpty);
    },
  );
}
