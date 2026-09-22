// HomeScreen'in `pendingZiboEvent` (bkz. `utils/zibo_event_signal.dart`)
// bir olay taşıdığında, normal zaman/ruh hali ağırlıklı seçimi BAYPAS EDİP
// doğrudan o olayın özel havuzundan bir mesaj gösterdiğini VE olayı
// ANINDA TÜKETTİĞİNİ (bir daha göstermediğini) doğrular —
// `home_screen_sound_test.dart`'taki "bağımsız test uygulaması" deseniyle
// AYNI. `home_screen_rapid_tap_test.dart` ile AYNI gerekçeyle
// `pendingZiboEvent` GLOBAL bir sinyal olduğu için `setUp`'ta sıfırlanıyor
// — aksi halde bu dosyanın testleri BİRBİRİNİ (veya aynı test ikilisinde
// SONRA çalışan başka bir dosyayı) kirletebilirdi.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/data/zibo_event_messages.dart';
import 'package:dijital_kanka/l10n/app_localizations.dart';
import 'package:dijital_kanka/providers/ad_free_provider.dart';
import 'package:dijital_kanka/providers/app_theme_provider.dart';
import 'package:dijital_kanka/providers/coin_provider.dart';
import 'package:dijital_kanka/providers/costume_provider.dart';
import 'package:dijital_kanka/providers/custom_messages_provider.dart';
import 'package:dijital_kanka/providers/favorite_quotes_provider.dart';
import 'package:dijital_kanka/providers/goals_provider.dart';
import 'package:dijital_kanka/providers/home_quick_widgets_provider.dart';
import 'package:dijital_kanka/providers/mood_provider.dart';
import 'package:dijital_kanka/providers/profile_provider.dart';
import 'package:dijital_kanka/providers/sound_effects_provider.dart';
import 'package:dijital_kanka/providers/subscription_provider.dart';
import 'package:dijital_kanka/providers/theme_provider.dart';
import 'package:dijital_kanka/providers/water_provider.dart';
import 'package:dijital_kanka/providers/zibo_pose_provider.dart';
import 'package:dijital_kanka/screens/home_screen.dart';
import 'package:dijital_kanka/services/sound_effects_service.dart';
import 'package:dijital_kanka/utils/zibo_event_signal.dart';
import 'package:dijital_kanka/widgets/speech_bubble.dart';

Widget _buildTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AdFreeProvider()),
      ChangeNotifierProvider(create: (_) => AppThemeProvider()),
      ChangeNotifierProvider(create: (_) => CoinProvider()),
      ChangeNotifierProvider(create: (_) => CostumeProvider()),
      ChangeNotifierProvider(create: (_) => CustomMessagesProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteQuotesProvider()),
      ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ChangeNotifierProvider(create: (_) => HomeQuickWidgetsProvider()),
      ChangeNotifierProvider(create: (_) => MoodProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => SoundEffectsProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => WaterProvider()),
      ChangeNotifierProvider(create: (_) => ZiboPoseProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(soundEffectsService: FakeSoundEffectsService()),
    ),
  );
}

String _currentHomeMessage(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(of: find.byType(SpeechBubble), matching: find.byType(Text)),
      )
      .data!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingZiboEvent.value = null;
  });

  testWidgets(
    'Ana Sayfa AÇILMADAN ÖNCE kuyruğa alınan bir olay, İLK karede kendi '
    'özel havuzundan bir mesaj gösterir VE anında tüketilir',
    (tester) async {
      pendingZiboEvent.value = ZiboEventType.goalCycleCompleted;
      await tester.pumpWidget(_buildTestApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      final pool = eventMessagesForLocale(
        ZiboEventType.goalCycleCompleted,
        const Locale('tr'),
      );
      expect(pool, contains(_currentHomeMessage(tester)));
      expect(pendingZiboEvent.value, isNull);
    },
  );

  testWidgets(
    'Ana Sayfa ZATEN AÇIKKEN kuyruğa alınan bir olay, dokunmaya GEREK '
    'KALMADAN otomatik olarak gösterilir',
    (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      pendingZiboEvent.value = ZiboEventType.streakBroken;
      await tester.pumpAndSettle();

      final pool = eventMessagesForLocale(
        ZiboEventType.streakBroken,
        const Locale('tr'),
      );
      expect(pool, contains(_currentHomeMessage(tester)));
      expect(pendingZiboEvent.value, isNull);
    },
  );

  testWidgets(
    'Olay tüketildikten SONRA Zibo\'ya dokunmak normal (olay havuzu '
    'DIŞINDAKİ) bir söze döner',
    (tester) async {
      pendingZiboEvent.value = ZiboEventType.costumeOrThemeUnlocked;
      await tester.pumpWidget(_buildTestApp());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      final eventPool = eventMessagesForLocale(
        ZiboEventType.costumeOrThemeUnlocked,
        const Locale('tr'),
      );
      expect(eventPool, contains(_currentHomeMessage(tester)));

      await tester.tap(find.byKey(const Key('ziboCharacterImage')));
      await tester.pumpAndSettle();

      expect(eventPool, isNot(contains(_currentHomeMessage(tester))));
    },
  );
}
