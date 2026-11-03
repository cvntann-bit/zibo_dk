import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/home_catalog.dart';
import 'l10n/app_localizations.dart';
import 'models/home_item.dart';
import 'providers/coin_provider.dart';
import 'providers/game_points_provider.dart';
import 'providers/games_config_provider.dart';
import 'providers/home_config_provider.dart';
import 'providers/home_decor_provider.dart';
import 'providers/home_needs_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/zibo_world_screen.dart';
import 'widgets/home_art/room_view.dart';

/// Geliştirme önizlemesi (Firebase'siz): solda telefon boyutunda Zibo Dünyası
/// giriş ekranı, sağda dört oda — üstte başlangıç takımıyla, altta her
/// kategorinin SON eşyasıyla. Kodla çizilen odaları ve evi taslaklarla
/// (docs/home_studio/, docs/zibo_world_prototype/) karşılaştırmak için.
/// Çalıştır: `flutter run -d web-server -t lib/home_room_preview_main.dart`.
void main() => runApp(const _Preview());

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    Map<String, HomeItem> pick(HomeRoomDef def, bool last) => {
      for (final c in def.categories) c.id: last ? c.items.last : (c.item(def.defaults[c.id] ?? '') ?? c.items.first),
    };
    Widget row(bool last) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final def in homeRooms)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: RoomView(scene: RoomSceneCache().get(def.room, pick(def, last)), semanticLabel: def.nameTr),
            ),
          ),
      ],
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeNeedsProvider()),
        ChangeNotifierProvider(create: (_) => HomeDecorProvider()),
        // Oda ekranı (bakım + dekor mağazası) için.
        ChangeNotifierProvider(create: (_) => HomeConfigProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CoinProvider(isSoundEnabled: () => false)..earnDailyLoginReward(2000)),
        ChangeNotifierProvider(create: (_) => GamePointsProvider()),
        ChangeNotifierProvider(create: (_) => GamesConfigProvider()),
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
        home: Scaffold(
          backgroundColor: const Color(0xFF222222),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 390,
                height: 820,
                child: Builder(
                  // Ekran genişliğine bakan kenar boşlukları telefon gibi hesaplansın.
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: const Size(390, 820)),
                    child: const ColoredBox(color: Color(0xFFFFF6E5), child: ZiboWorldScreen(isActive: true)),
                  ),
                ),
              ),
              Expanded(child: SingleChildScrollView(child: Column(children: [row(false), row(true)]))),
            ],
          ),
        ),
      ),
    );
  }
}
