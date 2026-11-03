import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/home_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../models/home_need.dart';
import '../providers/coin_provider.dart';
import '../providers/game_points_provider.dart';
import '../providers/games_config_provider.dart';
import '../providers/home_config_provider.dart';
import '../providers/home_decor_provider.dart';
import '../providers/home_needs_provider.dart';
import '../providers/subscription_provider.dart';
import '../data/rarity_colors.dart';
import '../widgets/home_art/care_fx.dart';
import '../widgets/home_art/item_thumb.dart';
import '../widgets/home_art/room_art.dart';
import '../widgets/home_art/room_view.dart';
import '../widgets/home_art/svg_kit.dart';
import '../widgets/sticker_style.dart';
import 'game_webview_screen.dart';

/// Zibo Dünyası'nda bir oda (docs/zibo_world_roadmap.md Faz 2 + Faz 4).
///
/// **Bakım** (varsayılan): odanın bakım oyunu — mutfakta besle, banyoda
/// yıka, yatak odasında uyut (gerçek zamanlı), salonda oyna. Taslak:
/// `docs/home_studio/index.html` bakım modu. İhtiyaçlar [HomeNeedsProvider]'a,
/// harcamalar [CoinProvider]'a yazılır.
///
/// **Dekor:** eşyalar DENENİR — deneme kaydedilmez, satın alma Faz 5.
///
/// Sahne üstte sabit (sürükleme listeyi kaydırmasın), panel altta kayar.
class HomeRoomScreen extends StatefulWidget {
  const HomeRoomScreen({super.key, required this.room, required this.title});

  final HomeRoom room;
  final String title;

  @override
  State<HomeRoomScreen> createState() => _HomeRoomScreenState();
}

enum _BathPhase { dirty, foamy, wet, clean }

// Taslaktaki mutfak noktaları (bakım sahnesinde masa x=315).
const _plate = Offset(455, 760);
const _mouth = Offset(455, 623);
// Banyoda Zibo'nun gövdesi (sabun yalnız burada köpürür).
const _bathZibo = Rect.fromLTRB(130, 340, 450, 640);

class _HomeRoomScreenState extends State<HomeRoomScreen> with SingleTickerProviderStateMixin {
  final _cache = RoomSceneCache();
  final _fx = CareFx();
  final _rnd = math.Random();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  bool _care = true;

  // Dekor deneme.
  final Map<String, String> _preview = {};
  late String _category = HomeDecorProvider.roomDef(widget.room).categories.first.id;

  // Mutfak.
  String _foodGroup = 'meyve';
  String? _plateFood;
  Offset? _held;
  Offset? _down;
  int _chew = 0;
  String? _msg;

  // Banyo.
  _BathPhase _phase = _BathPhase.clean;
  bool _scrubbing = false;
  bool _bathReady = false;

  // Salon.
  bool _justPlayed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _fx.onShowerDone = () => setState(() => _phase = _BathPhase.wet);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bathReady || widget.room != HomeRoom.bath) return;
    _bathReady = true;
    final h = context.read<HomeNeedsProvider>().percent(HomeNeed.hygiene);
    if (h < 95) {
      _phase = _BathPhase.dirty;
      _fx.dirty(((100 - h) / 100 * 12).ceil().clamp(3, 12));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _wake() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    _fx.step();
    if (_chew > 0) {
      _chew--;
      if (_chew == 0) setState(() {});
    }
    // Uyurken enerji göstergesi saniyede bir tazelenir.
    if (_fx.sleeping && _frame.value % 60 == 0) context.read<HomeNeedsProvider>().refresh();
    _frame.value++;
    if (!_fx.busy && _chew == 0 && _held == null && !_scrubbing) _ticker.stop();
  }

  HomeNeed get _need => switch (widget.room) {
    HomeRoom.kitchen => HomeNeed.hunger,
    HomeRoom.bath => HomeNeed.hygiene,
    HomeRoom.bedroom => HomeNeed.energy,
    HomeRoom.living => HomeNeed.fun,
  };

  void _say(String text) => setState(() => _msg = text);

  // --- Mutfak --------------------------------------------------------------

  void _chooseFood(HomeFood food) {
    final l10n = AppLocalizations.of(context)!;
    final needs = context.read<HomeNeedsProvider>();
    if (_chew > 0) return;
    if (_plateFood != null) return _say(l10n.careFeedPlateFirst);
    if (needs.percent(HomeNeed.hunger) >= 100) return _say(l10n.careFeedFullMsg);
    final price = context.read<HomeConfigProvider>().config.foodPrice(food.id, food.price);
    if (price > 0) {
      if (!context.read<CoinProvider>().spendOnFood(foodId: food.id, cost: price)) return _say(l10n.insufficientCoins);
    } else if (!needs.useFreeFood()) {
      return _say(l10n.careFeedNoFree);
    }
    setState(() {
      _plateFood = food.id;
      _held = null;
      _msg = l10n.careFeedHint;
    });
  }

  void _eat() {
    final l10n = AppLocalizations.of(context)!;
    final needs = context.read<HomeNeedsProvider>();
    final food = homeFoods.firstWhere((f) => f.id == _plateFood);
    needs.add(HomeNeed.hunger, food.hunger.toDouble());
    _fx.eat(_mouth);
    setState(() {
      _plateFood = null;
      _held = null;
      _chew = 70;
      _msg = needs.percent(HomeNeed.hunger) >= 100 ? l10n.careFeedThanks : l10n.careFeedYum;
    });
    _wake();
  }

  // --- Banyo ---------------------------------------------------------------

  HomeSoap _soap(HomeDecorProvider decor) =>
      homeSoaps.firstWhere((s) => s.id == decor.selectedSoap, orElse: () => homeSoaps.first);

  void _scrub(Offset p) {
    if (_phase != _BathPhase.dirty && _phase != _BathPhase.foamy) return;
    if (!_bathZibo.contains(p)) return;
    final soap = _soap(context.read<HomeDecorProvider>());
    final rainbow = soap.foam == null;
    final fill = rainbow
        ? _color(RoomArt.rainbow[_rnd.nextInt(RoomArt.rainbow.length)])
        : Color(soap.foam!);
    final wasRinseReady = _fx.dirt < .25;
    _fx.scrub(p, fill, Color(soap.foamStroke ?? 0xFFCDEBF7));
    // Panel (adımlar, duş düğmesi) yalnız eşik geçilince yeniden kurulur.
    if (_phase == _BathPhase.dirty || wasRinseReady != (_fx.dirt < .25)) {
      setState(() => _phase = _BathPhase.foamy);
    }
    _wake();
  }

  void _towel() {
    _fx.towel();
    context.read<HomeNeedsProvider>().add(HomeNeed.hygiene, 100);
    setState(() => _phase = _BathPhase.clean);
    _wake();
  }

  Future<void> _buyOrSelectSoap(HomeSoap soap) async {
    final l10n = AppLocalizations.of(context)!;
    final decor = context.read<HomeDecorProvider>();
    if (!decor.isSoapOwned(soap.id)) {
      final tier = context.read<SubscriptionProvider>().tier;
      final price = context.read<HomeConfigProvider>().config.priceFor('soap:${soap.id}', soap.price, tier);
      if (!context.read<CoinProvider>().spendOnSoap(soapId: soap.id, cost: price)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.insufficientCoins)));
        return;
      }
      decor.markSoapOwned(soap.id);
    }
    decor.selectSoap(soap.id);
  }

  // --- Salon ---------------------------------------------------------------

  Future<void> _play(String gameId, String title) async {
    final points = context.read<GamePointsProvider>();
    final needs = context.read<HomeNeedsProvider>();
    final before = points.totalEarned;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameWebViewScreen(gameId: gameId, title: title)));
    if (!mounted) return;
    final gained = points.totalEarned - before;
    if (gained > 0) {
      needs.add(HomeNeed.fun, 25);
      _fx.pop('+$gained ★');
      setState(() => _justPlayed = true);
      _wake();
    }
  }

  // --- Ortak ---------------------------------------------------------------

  static Color _color(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

  /// Sahne koordinatı (900×1200) ↔ ekran.
  Offset _toScene(Offset local, double s) => local / s;

  String _pose(HomeNeedsProvider needs) {
    if (!_care) return 'happy';
    final v = needs.percent(_need);
    return switch (widget.room) {
      HomeRoom.kitchen => _chew > 0 || v >= 100 ? 'happy' : (v < 50 ? 'pout' : 'idle'),
      HomeRoom.bath => _phase == _BathPhase.clean ? 'happy' : 'pout',
      HomeRoom.bedroom => needs.isAsleep ? 'idle' : (v >= 100 ? 'happy' : 'pout'),
      HomeRoom.living => _justPlayed || v >= 100 ? 'happy' : (v < 50 ? 'pout' : 'idle'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final decor = context.watch<HomeDecorProvider>();
    final needs = context.watch<HomeNeedsProvider>();
    final def = HomeDecorProvider.roomDef(widget.room);
    final items = {
      for (final c in def.categories)
        c.id: (_care ? null : c.item(_preview[c.id] ?? '')) ?? decor.equippedItem(widget.room, c.id),
    };
    final soap = _soap(decor);
    final asleep = needs.isAsleep;
    _fx.sleeping = _care && widget.room == HomeRoom.bedroom && asleep;
    if (_fx.sleeping) _wake();
    final foamy = _care && widget.room == HomeRoom.bath && (_phase == _BathPhase.dirty || _phase == _BathPhase.foamy);
    final scene = _cache.get(
      widget.room,
      items,
      care: _care,
      pose: _pose(needs),
      soapColor: SvgKit.hex(soap.bar ?? 0xFFFF9FBF),
      dark: _care && widget.room == HomeRoom.bedroom && asleep,
      foamFill: foamy ? (soap.foam == null ? 'rainbow' : SvgKit.hex(soap.foam!)) : null,
      foamStroke: SvgKit.hex(soap.foamStroke ?? 0xFFCDEBF7),
    );
    _fx
      ..soapBar = Color(soap.bar ?? 0xFFFF9FBF)
      ..soapStroke = Color(soap.barStroke ?? 0xFFE2668F);

    return Scaffold(
      appBar: plainStickerAppBar(context, title: widget.title),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Sahne en fazla ekran yüksekliğinin ~%52'si; panel altta kayar.
          final stageW = (constraints.maxHeight * 0.52 * 900 / 1200).clamp(0.0, constraints.maxWidth - 24);
          return Column(
            children: [
              const SizedBox(height: 10),
              Center(child: SizedBox(width: stageW, child: _stage(scene, stageW / 900))),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.careModeCare)),
                    ButtonSegment(value: false, label: Text(l10n.careModeDecor)),
                  ],
                  selected: {_care},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() => _care = v.first),
                ),
              ),
              if (!_care) _shopBar(l10n, decor),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: _care ? _carePanel(l10n, needs, decor) : _decorPanel(l10n, decor, def, items),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stage(RoomScene scene, double s) {
    final kitchenCare = _care && widget.room == HomeRoom.kitchen;
    final bathCare = _care && widget.room == HomeRoom.bath;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kStickerOutline, width: 3),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Listener(
        onPointerDown: (e) {
          final p = _toScene(e.localPosition, s);
          if (kitchenCare && _plateFood != null && (p - _plate).distance < 110) {
            setState(() {
              _held = p;
              _down = p;
            });
            _wake();
          } else if (bathCare) {
            _scrubbing = true;
            _fx.soapAt = p;
            _scrub(p);
          }
        },
        onPointerMove: (e) {
          final p = _toScene(e.localPosition, s);
          if (_held != null) {
            setState(() => _held = p);
          } else if (_scrubbing) {
            _fx.soapAt = p;
            _scrub(p);
          }
        },
        onPointerUp: (e) {
          final p = _toScene(e.localPosition, s);
          if (_held != null) {
            final tapped = _down != null && (p - _down!).distance < 12;
            if (tapped || (p - _mouth).distance < 130) {
              _eat();
            } else {
              setState(() => _held = null);
            }
          }
          if (_scrubbing) setState(() {}); // temizlik göstergesi güncellensin
          _scrubbing = false;
          _fx.soapAt = null;
        },
        onPointerCancel: (_) {
          setState(() => _held = null);
          _scrubbing = false;
          _fx.soapAt = null;
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _frame,
          builder: (context, _, child) {
            final lift = _chew > 0 ? math.sin(_chew / 5).abs() * 10 : 0.0;
            final food = _plateFood;
            final at = _held ?? _plate;
            final size = _held != null ? 120.0 : 104.0;
            return Stack(
              children: [
                RoomView(scene: scene, semanticLabel: widget.title, ziboLift: lift),
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: CareFxPainter(_fx, repaint: _frame)))),
                if (kitchenCare && food != null)
                  Positioned(
                    left: (at.dx - size / 2) * s,
                    top: (at.dy - size / 2 - (_held != null ? 0 : 26)) * s,
                    width: size * s,
                    height: size * s,
                    child: IgnorePointer(child: _FoodImage(id: food)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 18, height: 1.15),
    ),
  );

  Widget _meter(AppLocalizations l10n, HomeNeed need, int percent, List<Color> colors) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.worldNeedPercent(_needLabel(l10n, need), percent),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(color: kStickerOutline, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  List<Widget> _carePanel(AppLocalizations l10n, HomeNeedsProvider needs, HomeDecorProvider decor) {
    final v = needs.percent(_need);
    return switch (widget.room) {
      HomeRoom.kitchen => _kitchenPanel(l10n, needs, v),
      HomeRoom.bath => _bathPanel(l10n, decor, v),
      HomeRoom.bedroom => _bedPanel(l10n, needs, v),
      HomeRoom.living => _livingPanel(l10n, v),
    };
  }

  List<Widget> _kitchenPanel(AppLocalizations l10n, HomeNeedsProvider needs, int v) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = context.watch<HomeConfigProvider>().config;
    final freeLeft = needs.freeFoodsLeft;
    final groups = {
      'meyve': l10n.careFoodFruit,
      'yemek': l10n.careFoodMeal,
      'tatli': l10n.careFoodSweet,
      'icecek': l10n.careFoodDrink,
    };
    return [
      _title(_msg ?? (v >= 100 ? l10n.careFeedTitleFull : v < 50 ? l10n.careFeedTitleHungry : l10n.careFeedTitleSome)),
      _meter(l10n, HomeNeed.hunger, v, const [Color(0xFF9FE3A8), Color(0xFF3E8E4E)]),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final g in groups.entries)
            ChoiceChip(label: Text(g.value), selected: _foodGroup == g.key, onSelected: (_) => setState(() => _foodGroup = g.key)),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in homeFoods.where((f) => f.group == _foodGroup))
            Builder(
              builder: (context) {
                final price = config.foodPrice(f.id, f.price);
                final tag = price > 0 ? '$price ZC' : (freeLeft > 0 ? '${l10n.careFeedFree} · $freeLeft' : l10n.careFeedTomorrow);
                return Semantics(
                  button: true,
                  label: '${f.nameTr}, $tag',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _chooseFood(f),
                    child: Ink(
                      width: 92,
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                      decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          SizedBox(width: 56, height: 56, child: _FoodImage(id: f.id)),
                          Text(
                            f.nameTr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                          Text(
                            tag,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              color: price > 0 ? kGoldDeep : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ];
  }

  List<Widget> _bathPanel(AppLocalizations l10n, HomeDecorProvider decor, int v) {
    final colorScheme = Theme.of(context).colorScheme;
    final tier = context.watch<SubscriptionProvider>().tier;
    final config = context.watch<HomeConfigProvider>().config;
    final dirt = _fx.dirt;
    final shown = switch (_phase) {
      _BathPhase.dirty || _BathPhase.foamy => ((1 - dirt) * 70).round(),
      _BathPhase.wet => 85,
      _BathPhase.clean => 100,
    };
    final done = [
      _phase.index > 1 || (_phase == _BathPhase.foamy && dirt < .25),
      _phase.index >= 2,
      _phase.index >= 3,
    ];
    final steps = [l10n.careBathStep1, l10n.careBathStep2, l10n.careBathStep3];
    return [
      _title(_phase == _BathPhase.clean ? l10n.careBathTitleClean : l10n.careBathTitleDirty),
      _meter(l10n, HomeNeed.hygiene, v > shown ? v : shown, const [Color(0xFFBFE6F5), Color(0xFF3E9AD6)]),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                done[i] ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: done[i] ? const Color(0xFF3E8E4E) : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(steps[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ],
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _phase == _BathPhase.foamy && dirt < .25 && _fx.shower == 0
                  ? () {
                      _fx.startShower();
                      _wake();
                      setState(() {});
                    }
                  : null,
              child: Text(l10n.careBathShower),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(onPressed: _phase == _BathPhase.wet ? _towel : null, child: Text(l10n.careBathTowel)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(l10n.careBathSoap, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurfaceVariant)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final sp in homeSoaps)
            ChoiceChip(
              avatar: CircleAvatar(
                radius: 8,
                backgroundColor: Color(sp.bar ?? 0xFFFF9FBF),
                child: sp.foam == null ? const Text('🌈', style: TextStyle(fontSize: 9)) : null,
              ),
              label: Text(
                decor.isSoapOwned(sp.id) ? sp.nameTr : '${sp.nameTr} · ${config.priceFor('soap:${sp.id}', sp.price, tier)} ZC',
              ),
              selected: decor.selectedSoap == sp.id,
              onSelected: (_) => _buyOrSelectSoap(sp),
            ),
        ],
      ),
    ];
  }

  List<Widget> _bedPanel(AppLocalizations l10n, HomeNeedsProvider needs, int v) {
    final colorScheme = Theme.of(context).colorScheme;
    final asleep = needs.isAsleep;
    return [
      _title(
        asleep
            ? (v >= 100 ? l10n.careBedFull : l10n.careBedSleeping)
            : (v >= 100 ? l10n.careBedRested : l10n.careBedTired),
      ),
      _meter(l10n, HomeNeed.energy, v, const [Color(0xFFFFE07A), Color(0xFFF3B23C)]),
      FilledButton.icon(
        onPressed: () => asleep ? needs.wake() : needs.startSleep(),
        icon: Icon(asleep ? Icons.light_mode_rounded : Icons.bedtime_rounded),
        label: Text(asleep ? l10n.careBedWake : l10n.careBedSleep),
      ),
      const SizedBox(height: 10),
      Text(l10n.careBedNote, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.onSurfaceVariant)),
    ];
  }

  List<Widget> _livingPanel(AppLocalizations l10n, int v) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = context.watch<GamesConfigProvider>().config;
    final games = [
      ('kule', l10n.gameNameKule),
      ('hafiza', l10n.gameNameHafiza),
      ('2048', l10n.gameName2048),
      ('yakala', l10n.gameNameYakala),
      ('tren', l10n.gameNameTren),
      ('tugla', l10n.gameNameTugla),
      ('zipla', l10n.gameNameZipla),
    ];
    return [
      _title(v >= 100 ? l10n.carePlayHappy : v < 50 ? l10n.carePlayBored : l10n.carePlaySome),
      _meter(l10n, HomeNeed.fun, v, const [Color(0xFFFFB7C8), Color(0xFFF2705E)]),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (id, name) in games)
            Opacity(
              opacity: config.isEnabled(id) ? 1 : .5,
              child: Semantics(
                button: config.isEnabled(id),
                label: name,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: config.isEnabled(id) ? () => _play(id, name) : null,
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            border: Border.all(color: kStickerOutline, width: 2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset('assets/images/game_${id}_thumb.webp', fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(l10n.carePlayHint, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.onSurfaceVariant)),
    ];
  }

  // --- Dekor mağazası (Faz 5) ------------------------------------------------

  String _key(String category, String itemId) => HomeDecorProvider.key(widget.room, category, itemId);

  /// Denenen ama sahip olunmayan eşyalar ve (abonelik indirimli) fiyatları.
  List<(String, HomeItem, int)> _cart(HomeDecorProvider decor) {
    final config = context.read<HomeConfigProvider>().config;
    final tier = context.read<SubscriptionProvider>().tier;
    final def = HomeDecorProvider.roomDef(widget.room);
    final cart = <(String, HomeItem, int)>[];
    for (final e in _preview.entries) {
      final item = def.category(e.key)?.item(e.value);
      if (item == null || decor.isOwned(widget.room, e.key, e.value)) continue;
      cart.add((e.key, item, config.priceFor(_key(e.key, e.value), item.price, tier)));
    }
    return cart;
  }

  void _tapItem(HomeDecorProvider decor, HomeCategory category, HomeItem item) {
    final l10n = AppLocalizations.of(context)!;
    final key = _key(category.id, item.id);
    final owned = decor.isOwned(widget.room, category.id, item.id);
    final config = context.read<HomeConfigProvider>().config;
    if (!owned && config.isProOnly(key) && !context.read<SubscriptionProvider>().isPro) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shopProOnlyMsg)));
      return;
    }
    setState(() {
      if (owned) {
        // Sahip olunan eşya hemen takılır (ücretsiz).
        decor.equip(widget.room, category.id, item.id);
        _preview.remove(category.id);
      } else {
        _preview[category.id] = item.id;
      }
    });
  }

  void _buyCart(HomeDecorProvider decor) {
    final l10n = AppLocalizations.of(context)!;
    final cart = _cart(decor);
    if (cart.isEmpty) return;
    final total = cart.fold<int>(0, (n, e) => n + e.$3);
    final keys = [for (final e in cart) '${e.$1}:${e.$2.id}'].join(',');
    final ok = context.read<CoinProvider>().spendOnHomeItem(itemKey: '${widget.room.id}:$keys', cost: total);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.insufficientCoins)));
      return;
    }
    for (final (category, item, _) in cart) {
      decor.markOwned(widget.room, category, item.id);
      decor.equip(widget.room, category, item.id);
    }
    setState(_preview.clear);
    messenger.showSnackBar(SnackBar(content: Text(l10n.shopBought)));
  }

  /// Dekor modunda listenin üstünde sabit duran bakiye + sepet çubuğu (aşağıdaki
  /// bir eşya denenince de "Odadakileri al" görünür kalsın).
  Widget _shopBar(AppLocalizations l10n, HomeDecorProvider decor) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = context.watch<CoinProvider>().balance;
    final cart = _cart(decor);
    final total = cart.fold<int>(0, (n, e) => n + e.$3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: Text(
              l10n.shopBalance(balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (cart.isNotEmpty)
            IconButton(
              onPressed: () => setState(_preview.clear),
              tooltip: l10n.shopCancel,
              icon: const Icon(Icons.undo_rounded),
            ),
          Flexible(
            flex: 3,
            child: FilledButton(
              onPressed: cart.isEmpty ? null : () => _buyCart(decor),
              child: Text(
                cart.isEmpty ? l10n.shopRoomDone : l10n.shopBuyRoom(total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _decorPanel(AppLocalizations l10n, HomeDecorProvider decor, HomeRoomDef def, Map<String, HomeItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = context.watch<HomeConfigProvider>().config;
    final sub = context.watch<SubscriptionProvider>();
    final now = DateTime.now();
    final category = def.category(_category)!;
    return [
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: def.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final c = def.categories[i];
            final trying = _preview.containsKey(c.id) && !decor.isOwned(widget.room, c.id, _preview[c.id]!);
            return ChoiceChip(
              label: Text(trying ? '${c.nameTr} •' : c.nameTr),
              selected: c.id == _category,
              onSelected: (_) => setState(() => _category = c.id),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in category.items)
            if (decor.isOwned(widget.room, category.id, item.id) ||
                (!item.eventOnly && config.isOnSale(_key(category.id, item.id), now)))
              _ShopTile(
                category: category,
                item: item,
                selected: items[category.id]?.id == item.id,
                equipped: decor.equipped(widget.room, category.id) == item.id,
                owned: decor.isOwned(widget.room, category.id, item.id),
                price: config.priceFor(_key(category.id, item.id), item.price, sub.tier),
                proOnly: config.isProOnly(_key(category.id, item.id)),
                limited: config.isLimited(_key(category.id, item.id)),
                onTap: () => _tapItem(decor, category, item),
              ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        l10n.shopHint,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    ];
  }
}

/// Mağazada bir eşya: küçük resim (nadirlik çerçeveli), ad, durum/fiyat.
class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.category,
    required this.item,
    required this.selected,
    required this.equipped,
    required this.owned,
    required this.price,
    required this.proOnly,
    required this.limited,
    required this.onTap,
  });

  final HomeCategory category;
  final HomeItem item;
  final bool selected;
  final bool equipped;
  final bool owned;
  final int price;
  final bool proOnly;
  final bool limited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final rarity = homeItemRarity(item.price);
    final style = rarity == null ? null : RarityStyle.of(rarity);
    final tag = equipped
        ? l10n.shopEquipped
        : owned
        ? l10n.shopOwned
        : '$price ZC';
    final badge = [if (proOnly) '👑', if (limited) '⏳'].join(' ');
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.nameTr}, $tag',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 96,
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: selected ? kStickerOutline : (style?.color ?? colorScheme.outlineVariant),
              width: selected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: style?.glowShadows,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  HomeItemThumb(kind: category.kind, item: item),
                  if (badge.isNotEmpty) Positioned(top: -4, right: -4, child: Text(badge, style: const TextStyle(fontSize: 13))),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.nameTr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
              Text(
                tag,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: owned || equipped ? colorScheme.primary : kGoldDeep,
                ),
              ),
              if (rarity != null && !owned)
                Text(
                  rarity.localizedName(l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    color: style!.labelColor(Theme.of(context).brightness),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _needLabel(AppLocalizations l10n, HomeNeed need) => switch (need) {
  HomeNeed.hunger => l10n.worldNeedHunger,
  HomeNeed.hygiene => l10n.worldNeedHygiene,
  HomeNeed.energy => l10n.worldNeedEnergy,
  HomeNeed.fun => l10n.worldNeedFun,
};

/// Yemek görseli: Fluent Emoji (MIT, `assets/images/home/food/`); simit ve
/// churros kütüphanede yok, taslaktaki gibi kodla çizilir.
class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.id});

  final String id;

  static final _drawn = {
    'simit':
        '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><circle cx="60" cy="60" r="38" fill="none" stroke="#C9772E" stroke-width="26"/>'
        '<circle cx="60" cy="60" r="38" fill="none" stroke="#E39A4C" stroke-width="14"/>'
        '${const [(30, 40), (50, 26), (76, 28), (92, 50), (88, 78), (64, 94), (38, 88), (26, 64), (44, 34), (84, 64)].map((e) => '<ellipse cx="${e.$1}" cy="${e.$2}" rx="3" ry="2" fill="#FFF3D1"/>').join()}</svg>',
    'churros':
        '<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><path d="M30 110l14-86M54 110l6-92M80 110l-4-88" stroke="#C9772E" stroke-width="18" stroke-linecap="round"/>'
        '<path d="M30 110l14-86M54 110l6-92M80 110l-4-88" stroke="#E7A35A" stroke-width="7" stroke-linecap="round" stroke-dasharray="6 6"/>'
        '<path d="M20 80h80l-10 34H30z" fill="#F2564B"/><path d="M28 92h64" stroke="#fff" stroke-width="5"/></svg>',
  };

  @override
  Widget build(BuildContext context) {
    final svg = _drawn[id];
    if (svg != null) return SvgPicture.string(svg, fit: BoxFit.contain);
    return Image.asset('assets/images/home/food/$id.webp', fit: BoxFit.contain);
  }
}
