// HomeWidgetSyncCoordinator'ın gerçek provider'ları dinleyip doğru modülü,
// doğru içerikle `HomeWidgetService.pushStatus`'a ilettiğini doğrudan
// (tam bir RootScreen kurmadan, sahte bir servisle) test eder — bkz.
// CLAUDE.md "Ana Ekran Widget'ları" bölümü. Sekiz modülün TAMAMI değil,
// temsili bir alt küme (goals/water/dailyRewards/currency) + genel
// "yalnızca ilgili modül güncellenir" garantisi kapsanıyor; içerik
// hesaplama mantığının kendisi zaten `widget_status_test.dart`'ta ayrıca
// ve tam olarak test ediliyor.
//
// `HomeWidgetSyncCoordinator` yalnızca `AppLocalizations.of(context)` için
// bir `BuildContext`'e ihtiyaç duyuyor — bu yüzden `testWidgets` ile
// minimal bir `MaterialApp` pump'layıp gerçek bir `Localizations` ağacına
// sahip bir context yakalanıyor (düz `test()`'te sahte bir `BuildContext`
// bunu karşılayamaz, `Localizations.of` gerçek bir InheritedWidget
// bekliyor).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/currency_provider.dart';
import 'package:dijital_kanka/providers/daily_rewards_provider.dart';
import 'package:dijital_kanka/providers/dream_journal_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/gratitude_provider.dart';
import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/providers/money_provider.dart';
import 'package:dijital_kanka/providers/mood_provider.dart';
import 'package:dijital_kanka/providers/trusted_time_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/services/home_widget_service.dart';
import 'package:dijital_kanka/services/home_widget_sync_coordinator.dart';
import 'package:dijital_kanka/services/trusted_time_service.dart';
import 'package:dijital_kanka/utils/widget_module.dart';

class _RecordingHomeWidgetService implements HomeWidgetService {
  final List<(ZiboWidgetModule, String, String, String, int?)> calls = [];

  @override
  Future<void> pushStatus(
    ZiboWidgetModule module, {
    required String title,
    required String primary,
    required String secondary,
    int? progress,
  }) async {
    calls.add((module, title, primary, secondary, progress));
  }

  @override
  Future<bool> requestPin(ZiboWidgetModule module) async => true;
}

class _FixedTimeService extends TrustedTimeService {
  _FixedTimeService(this.fixed);
  final DateTime fixed;

  @override
  Future<DateTime?> fetchNetworkTime() async => fixed;
}

/// Bir testin ihtiyaç duyduğu her şeyi (sahte servis + 9 provider + gerçek
/// bir `Localizations` ağacına sahip `BuildContext` + kurulu koordinatör)
/// TEK çağrıda hazırlar.
class _Harness {
  _Harness({
    required this.service,
    required this.goals,
    required this.water,
    required this.gratitude,
    required this.mood,
    required this.manifest,
    required this.dream,
    required this.money,
    required this.currency,
    required this.dailyRewards,
    required this.coordinator,
  });

  final _RecordingHomeWidgetService service;
  final GoalsProvider goals;
  final WaterProvider water;
  final GratitudeProvider gratitude;
  final MoodProvider mood;
  final ManifestProvider manifest;
  final DreamJournalProvider dream;
  final MoneyProvider money;
  final CurrencyProvider currency;
  final DailyRewardsProvider dailyRewards;
  final HomeWidgetSyncCoordinator coordinator;
}

Future<_Harness> _buildHarness(WidgetTester tester) async {
  final fixedNow = DateTime(2026, 1, 10);
  DateTime now() => fixedNow;

  final service = _RecordingHomeWidgetService();
  final trustedTime = TrustedTimeProvider(timeService: _FixedTimeService(fixedNow));
  final goals = GoalsProvider(now: now);
  final water = WaterProvider(now: now);
  final gratitude = GratitudeProvider(now: now);
  final mood = MoodProvider(now: now);
  final manifest = ManifestProvider(now: now);
  final dream = DreamJournalProvider();
  final money = MoneyProvider(now: now);
  final currency = CurrencyProvider();
  final dailyRewards = DailyRewardsProvider(now: now);

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
    mood: mood,
    manifest: manifest,
    dream: dream,
    money: money,
    currency: currency,
    dailyRewards: dailyRewards,
  );

  return _Harness(
    service: service,
    goals: goals,
    water: water,
    gratitude: gratitude,
    mood: mood,
    manifest: manifest,
    dream: dream,
    money: money,
    currency: currency,
    dailyRewards: dailyRewards,
    coordinator: coordinator,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('syncAll TÜM sekiz modülü BİR KEZ günceller', (tester) async {
    final h = await _buildHarness(tester);
    h.coordinator.syncAll();
    final updatedModules = h.service.calls.map((c) => c.$1).toSet();
    expect(updatedModules, ZiboWidgetModule.values.toSet());
    h.coordinator.dispose();
  });

  testWidgets('GoalsProvider değişince YALNIZCA Hedef Takibi widget\'ı güncellenir', (
    tester,
  ) async {
    final h = await _buildHarness(tester);
    h.service.calls.clear();
    h.goals.addGoal('Kitap oku');
    expect(h.service.calls, hasLength(1));
    expect(h.service.calls.single.$1, ZiboWidgetModule.goals);
    expect(h.service.calls.single.$3, '0/1'); // henüz işaretlenmedi
    h.coordinator.dispose();
  });

  testWidgets('Bir hedef bugün işaretlenince Hedef Takibi widget\'ı doğru oranı gösterir', (
    tester,
  ) async {
    final h = await _buildHarness(tester);
    h.goals.addGoal('Kitap oku');
    h.service.calls.clear();
    final id = h.goals.goals.single.id;
    h.goals.toggleToday(id);
    expect(h.service.calls.last.$1, ZiboWidgetModule.goals);
    expect(h.service.calls.last.$3, '1/1');
    expect(h.service.calls.last.$5, 100);
    h.coordinator.dispose();
  });

  testWidgets('WaterProvider değişince YALNIZCA Su Takibi widget\'ı güncellenir', (tester) async {
    final h = await _buildHarness(tester);
    h.service.calls.clear();
    h.water.incrementUnit();
    expect(h.service.calls, hasLength(1));
    expect(h.service.calls.single.$1, ZiboWidgetModule.water);
    expect(h.service.calls.single.$3, '1/8');
    h.coordinator.dispose();
  });

  testWidgets(
    'DailyRewardsProvider değişince YALNIZCA Günlük Giriş Ödülleri widget\'ı güncellenir',
    (tester) async {
      final h = await _buildHarness(tester);
      h.service.calls.clear();
      h.dailyRewards.claimToday();
      expect(h.service.calls, hasLength(1));
      expect(h.service.calls.single.$1, ZiboWidgetModule.dailyRewards);
      h.coordinator.dispose();
    },
  );

  testWidgets('CurrencyProvider değişince Para ve Birikim widget\'ı güncellenir', (tester) async {
    final h = await _buildHarness(tester);
    h.service.calls.clear();
    h.currency.setCurrencyCode('USD');
    expect(h.service.calls, hasLength(1));
    expect(h.service.calls.single.$1, ZiboWidgetModule.money);
    h.coordinator.dispose();
  });

  testWidgets(
    'dispose() sonrası HİÇBİR provider değişikliği artık widget güncellemesi tetiklemez',
    (tester) async {
      final h = await _buildHarness(tester);
      h.coordinator.dispose();
      h.service.calls.clear();
      h.water.incrementUnit();
      h.goals.addGoal('Test');
      h.dailyRewards.claimToday();
      expect(h.service.calls, isEmpty);
    },
  );
}
