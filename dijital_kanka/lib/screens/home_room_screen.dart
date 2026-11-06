import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/home_catalog.dart';
import '../data/rarity_colors.dart';
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
import '../widgets/home_art/care_fx.dart';
import '../widgets/home_art/item_thumb.dart';
import '../widgets/home_art/room_art.dart';
import '../widgets/home_art/room_view.dart';
import '../widgets/home_art/svg_kit.dart';
import '../widgets/sticker_style.dart';
import 'game_webview_screen.dart';

/// Zibo'nun Evi — tam ekran oda (docs/zibo_world.md düzenleme turu, 2026-11-03).
///
/// Oda çizimi tüm ekranı kaplar (duvar yukarı, zemin aşağı uzar —
/// [RoomScene.extraTop]/[RoomScene.extraBottom]). Üstte geri, oda adı ve
/// dört ihtiyaç çubuğu; altta ince panel: Bakım/Dekor, çipler ve sağa-sola
/// kayan tek sıra (yemekler, sabunlar, oyunlar ya da dekor eşyaları).
///
/// Odalar arası: sahneyi sağa/sola kaydır (ya da oda adındaki okları, ihtiyaç
/// çubuklarını kullan) → Zibo kaydırılan yöne zıplaya zıplaya çıkar, her
/// inişte ayağının altından toz kalkar, oda solarak değişir, Zibo karşı
/// taraftan zıplayarak gelir. Giriş ekranındaki eve dokununca salonda açılır.
///
/// **Bakım:** mutfakta besle, banyoda yıka, yatak odasında uyut (gerçek
/// zamanlı), salonda oyna (Faz 4). **Dekor:** eşyaları dene, sepeti al (Faz 5).
class HomeRoomScreen extends StatefulWidget {
  const HomeRoomScreen({super.key, this.initialRoom = HomeRoom.living});

  final HomeRoom initialRoom;

  @override
  State<HomeRoomScreen> createState() => _HomeRoomScreenState();
}

/// Kaydırma sırası (döngüsel): mutfak · salon · yatak odası · banyo.
const homeRoomOrder = [HomeRoom.kitchen, HomeRoom.living, HomeRoom.bedroom, HomeRoom.bath];

enum _BathPhase { dirty, foamy, wet, clean }

// Taslaktaki mutfak noktaları (bakım sahnesinde masa x=315).
const _plate = Offset(455, 760);
const _mouth = Offset(455, 623);
// Banyoda Zibo'nun gövdesi (sabun yalnız burada köpürür).
const _bathZibo = Rect.fromLTRB(130, 340, 450, 640);

// Geçiş: Zibo'nun zıplayarak kat ettiği yol (sahne birimi) ve zıplama yüksekliği.
const _hopDistance = 700.0;
const _hopHeight = 70.0;
// Zıplayan Zibo odanın zemininde yürür (yatak/kanepe/küvetin önünde): ayak çizgisi ve boyu.
const _hopFeetY = 1030.0;
const _hopSpriteH = 440.0;
// Salonda bu enerjinin altında "önce uyumam gerek" balonu çıkar.
const _tiredBelow = 50;

class _HomeRoomScreenState extends State<HomeRoomScreen> with TickerProviderStateMixin {
  // Zibo uyuyorsa ev nereden açılırsa açılsın yatak odasında, uyur hâlde açılır.
  late HomeRoom _room = context.read<HomeNeedsProvider>().isAsleep ? HomeRoom.bedroom : widget.initialRoom;
  final _cache = RoomSceneCache();
  final _fx = CareFx();
  final _rnd = math.Random();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  late final AnimationController _hop;
  bool _care = true;

  // Odalar arası geçiş.
  HomeRoom? _hopTarget;
  int _hopDir = -1; // ekranda Zibo'nun gittiği yön (-1 sol, +1 sağ)
  ZiboSpot? _hopFrom;
  bool _switched = false;
  double _lastHopT = 0;
  bool _swipeBlocked = false;

  // Alt panel gizlenebilir; uyurken oda değiştirmek yerine "önce uyandır" çıkar.
  bool _panelOpen = true;
  bool _wakePrompt = false;
  (int, HomeRoom?)? _pendingGo;
  Timer? _promptTimer;
  double _dragDx = 0;
  RoomScene? _lastScene;

  // Dekor deneme.
  final Map<String, String> _preview = {};
  late String _category = HomeDecorProvider.roomDef(_room).categories.first.id;

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

  // Salon.
  bool _justPlayed = false;
  // Enerji düşükken salonda "önce uyumam gerek" balonu (kapatılabilir).
  bool _tiredDismissed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
      ..addListener(_onHop)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _hopTarget = null;
            _hopFrom = null;
          });
        }
      });
    _fx.onShowerDone = () => setState(() => _phase = _BathPhase.wet);
    _enterRoom();
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _hop.dispose();
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
    if (!_fx.busy && _chew == 0 && _held == null && !_scrubbing && !_hop.isAnimating) _ticker.stop();
  }

  HomeNeed _needOf(HomeRoom room) => switch (room) {
    HomeRoom.kitchen => HomeNeed.hunger,
    HomeRoom.bath => HomeNeed.hygiene,
    HomeRoom.bedroom => HomeNeed.energy,
    HomeRoom.living => HomeNeed.fun,
  };

  String _roomName(AppLocalizations l10n, HomeRoom room) => switch (room) {
    HomeRoom.kitchen => l10n.worldRoomKitchen,
    HomeRoom.bath => l10n.worldRoomBath,
    HomeRoom.bedroom => l10n.worldRoomBedroom,
    HomeRoom.living => l10n.worldRoomLiving,
  };

  void _say(String text) => setState(() => _msg = text);

  // --- Odalar arası geçiş -----------------------------------------------------

  /// Odaya girerken ve çıkarken odaya özgü durum.
  void _enterRoom() {
    _preview.clear();
    _category = HomeDecorProvider.roomDef(_room).categories.first.id;
    _msg = null;
    _held = null;
    _chew = 0;
    _justPlayed = false;
    _tiredDismissed = false;
    _fx.clearBath();
    _phase = _BathPhase.clean;
    if (_room == HomeRoom.bath) {
      final h = context.read<HomeNeedsProvider>().percent(HomeNeed.hygiene);
      if (h < 95) {
        _phase = _BathPhase.dirty;
        _fx.dirty(((100 - h) / 100 * 12).ceil().clamp(3, 12));
      }
    }
  }

  /// [delta] +1 = sıradaki oda (Zibo sola gider), -1 = önceki oda (sağa).
  void _go(int delta, {HomeRoom? to}) {
    if (_hop.isAnimating || delta == 0) return;
    // Zibo uyurken odadan çıkılmaz: ortada "önce uyandır" belirir, ışık
    // açılınca istenen odaya geçilir.
    if (_room == HomeRoom.bedroom && context.read<HomeNeedsProvider>().isAsleep) {
      _promptTimer?.cancel();
      setState(() {
        _wakePrompt = true;
        _pendingGo = (delta, to);
      });
      _promptTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _wakePrompt = false);
      });
      return;
    }
    final i = homeRoomOrder.indexOf(_room);
    final target = to ?? homeRoomOrder[(i + delta) % homeRoomOrder.length];
    if (target == _room) return;
    HapticFeedback.selectionClick();
    final scene = _lastScene;
    setState(() {
      _hopTarget = target;
      _hopDir = delta > 0 ? -1 : 1;
      _hopFrom = scene?.zibo;
      _switched = false;
      _lastHopT = 0;
    });
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _room = target;
        _enterRoom();
        _hopTarget = null;
      });
      return;
    }
    if (scene != null) _fx.dust(_feet(scene.zibo, 0, 0));
    _hop.forward(from: 0);
    _wake();
  }

  /// "Önce uyandır" penceresindeki ışık: Zibo uyanır, ışık açılınca istenen odaya geçilir.
  void _wakeAndGo() {
    _promptTimer?.cancel();
    context.read<HomeNeedsProvider>().wake();
    final pending = _pendingGo;
    setState(() {
      _wakePrompt = false;
      _pendingGo = null;
    });
    if (pending == null) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _go(pending.$1, to: pending.$2);
    });
  }

  Offset _feet(ZiboSpot spot, double shift, double lift) => Offset(spot.x + spot.w / 2 + shift, _hopFeetY - lift);

  /// Zıplama karesinin konumu: (yatay kayma, yükseklik, opaklık, hangi kutu).
  (double, double, double, bool) _hopPose(double t) {
    if (t < .45) {
      final p = t / .45;
      return (_hopDir * _hopDistance * p, (math.sin(p * 2 * math.pi)).abs() * _hopHeight, p < .75 ? 1.0 : 1 - (p - .75) / .25, false);
    }
    if (t < .55) return (0.0, 0.0, 0.0, true);
    final p = (t - .55) / .45;
    return (-_hopDir * _hopDistance * (1 - p), (math.sin(p * 2 * math.pi)).abs() * _hopHeight, p < .25 ? p / .25 : 1.0, true);
  }

  void _onHop() {
    final t = _hop.value;
    if (!_switched && t >= .5) {
      _switched = true;
      setState(() {
        _room = _hopTarget!;
        _enterRoom();
      });
    }
    // İnişlerde toz: çıkışta yarı yolda, girişte yarı yolda ve sonunda.
    bool crossed(double at) => _lastHopT < at && t >= at;
    final from = _hopFrom;
    final to = _lastScene?.zibo;
    if (from != null && crossed(.225)) _fx.dust(_feet(from, _hopDir * _hopDistance * .5, 0));
    if (to != null && crossed(.775)) _fx.dust(_feet(to, -_hopDir * _hopDistance * .5, 0));
    if (to != null && t >= 1 && _lastHopT < 1) _fx.dust(_feet(to, 0, 0));
    _lastHopT = t;
  }

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

  bool get _canScrub => _phase == _BathPhase.dirty || _phase == _BathPhase.foamy;

  void _scrub(Offset p) {
    if (!_canScrub || !_bathZibo.contains(p)) return;
    final soap = _soap(context.read<HomeDecorProvider>());
    final rainbow = soap.foam == null;
    final fill = rainbow ? _color(RoomArt.rainbow[_rnd.nextInt(RoomArt.rainbow.length)]) : Color(soap.foam!);
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

  // --- Dekor mağazası (Faz 5) ------------------------------------------------

  String _key(String category, String itemId) => HomeDecorProvider.key(_room, category, itemId);

  /// Denenen ama sahip olunmayan eşyalar ve (abonelik indirimli) fiyatları.
  List<(String, HomeItem, int)> _cart(HomeDecorProvider decor) {
    final config = context.read<HomeConfigProvider>().config;
    final tier = context.read<SubscriptionProvider>().tier;
    final def = HomeDecorProvider.roomDef(_room);
    final cart = <(String, HomeItem, int)>[];
    for (final e in _preview.entries) {
      final item = def.category(e.key)?.item(e.value);
      if (item == null || decor.isOwned(_room, e.key, e.value)) continue;
      cart.add((e.key, item, config.priceFor(_key(e.key, e.value), item.price, tier)));
    }
    return cart;
  }

  void _tapItem(HomeDecorProvider decor, HomeCategory category, HomeItem item) {
    final l10n = AppLocalizations.of(context)!;
    final key = _key(category.id, item.id);
    final owned = decor.isOwned(_room, category.id, item.id);
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
        decor.equip(_room, category.id, item.id);
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
    final ok = context.read<CoinProvider>().spendOnHomeItem(itemKey: '${_room.id}:$keys', cost: total);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.insufficientCoins)));
      return;
    }
    for (final (category, item, _) in cart) {
      decor.markOwned(_room, category, item.id);
      decor.equip(_room, category, item.id);
    }
    setState(_preview.clear);
    messenger.showSnackBar(SnackBar(content: Text(l10n.shopBought)));
  }

  // --- Ortak ---------------------------------------------------------------

  static Color _color(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

  String _pose(HomeNeedsProvider needs) {
    if (!_care) return 'happy';
    final v = needs.percent(_needOf(_room));
    // Bakım pozları kullanıcının ürettiği görseller (docs/zibo_images_needed.md).
    return switch (_room) {
      HomeRoom.kitchen =>
        _chew > 0
            ? 'eat_chew'
            : v >= 100
            ? 'happy'
            : (_plateFood != null ? 'eat_open' : (v < 50 ? 'pout' : 'idle')),
      HomeRoom.bath => _phase == _BathPhase.clean ? 'bath_happy' : 'bath_pout',
      HomeRoom.bedroom => needs.isAsleep ? 'sleep' : (v >= 100 ? 'happy' : (v < 50 ? 'yawn' : 'idle')),
      HomeRoom.living =>
        _justPlayed || v >= 100
            ? 'happy'
            : _tired(needs)
            ? 'yawn'
            : (v < 50 ? 'pout' : 'play'),
    };
  }

  /// Salonda enerji yarının altındaysa Zibo yorgundur.
  bool _tired(HomeNeedsProvider needs) =>
      _room == HomeRoom.living && !needs.isAsleep && needs.percent(HomeNeed.energy) < _tiredBelow;

  /// Banyoda yıkanırken temizlik göstergesi adım adım dolar.
  int _bathShown(int v) {
    final shown = switch (_phase) {
      _BathPhase.dirty || _BathPhase.foamy => ((1 - _fx.dirt) * 70).round(),
      _BathPhase.wet => 85,
      _BathPhase.clean => 100,
    };
    return math.max(v, shown);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final decor = context.watch<HomeDecorProvider>();
    final needs = context.watch<HomeNeedsProvider>();
    final def = HomeDecorProvider.roomDef(_room);
    final items = {
      for (final c in def.categories) c.id: (_care ? null : c.item(_preview[c.id] ?? '')) ?? decor.equippedItem(_room, c.id),
    };
    final soap = _soap(decor);
    final asleep = needs.isAsleep;
    _fx.sleeping = _care && _room == HomeRoom.bedroom && asleep;
    if (_fx.sleeping) _wake();
    final foamy = _care && _room == HomeRoom.bath && _canScrub;
    _fx
      ..soapBar = Color(soap.bar ?? 0xFFFF9FBF)
      ..soapStroke = Color(soap.barStroke ?? 0xFFE2668F);
    final media = MediaQuery.of(context);
    final wall = Color(items['boya']?.color ?? 0xFFFFE7B0);
    final floor = Color(items['zemin']?.color ?? 0xFFD99A5B);

    return Scaffold(
      backgroundColor: wall,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: LayoutBuilder(
          builder: (context, c) {
            final s = math.min(c.maxWidth / 900, c.maxHeight / 1200);
            final stageW = 900 * s;
            final extra = math.max(0.0, c.maxHeight / s - 1200);
            final topUnits = (media.padding.top + 118) / s;
            final extraTop = math.min(extra, math.max(0.0, topUnits - 70));
            final scene = _cache.get(
              _room,
              items,
              care: _care,
              pose: _pose(needs),
              soapColor: SvgKit.hex(soap.bar ?? 0xFFFF9FBF),
              dark: _care && _room == HomeRoom.bedroom && asleep,
              foamFill: foamy ? (soap.foam == null ? 'rainbow' : SvgKit.hex(soap.foam!)) : null,
              foamStroke: SvgKit.hex(soap.foamStroke ?? 0xFFCDEBF7),
              extraTop: extraTop,
              extraBottom: extra - extraTop,
            );
            _lastScene = scene;
            final floorLine = ((800 + scene.extraTop) * s / c.maxHeight).clamp(0.0, 1.0);
            return DecoratedBox(
              // Geniş ekranda (tablet) sahnenin yanları: duvar ve zemin rengi.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [wall, wall, floor, floor],
                  stops: [0, floorLine, floorLine, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(left: (c.maxWidth - stageW) / 2, top: 0, width: stageW, bottom: 0, child: _stage(l10n, scene, s)),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: SafeArea(bottom: false, child: _topBar(l10n, needs)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _panelOpen
                            ? KeyedSubtree(key: const ValueKey('panel'), child: _bottomPanel(l10n, needs, decor, def, items))
                            : KeyedSubtree(key: const ValueKey('pill'), child: _collapsedPanel(l10n)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_wakePrompt,
                      child: AnimatedOpacity(
                        opacity: _wakePrompt ? 1 : 0,
                        duration: const Duration(milliseconds: 260),
                        child: Center(child: _wakeCard(l10n)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Sahne ---------------------------------------------------------------

  Widget _stage(AppLocalizations l10n, RoomScene scene, double s) {
    final kitchenCare = _care && _room == HomeRoom.kitchen;
    final bathCare = _care && _room == HomeRoom.bath;
    final showTired = _care && !_tiredDismissed && _tired(context.watch<HomeNeedsProvider>());
    Offset toScene(Offset local) => local / s - Offset(0, scene.extraTop);
    return GestureDetector(
      onHorizontalDragStart: (_) {
        _swipeBlocked = _held != null || _scrubbing;
        _dragDx = 0;
      },
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: (d) {
        if (_swipeBlocked) return;
        final v = d.velocity.pixelsPerSecond.dx;
        if (v.abs() < 250 && _dragDx.abs() < 70) return;
        // Parmak sola → Zibo sola gider, sağdaki (sıradaki) oda gelir.
        _go((v.abs() >= 250 ? v : _dragDx) < 0 ? 1 : -1);
      },
      child: Listener(
        onPointerDown: (e) {
          if (_hop.isAnimating) return;
          final p = toScene(e.localPosition);
          if (kitchenCare && _plateFood != null && (p - _plate).distance < 110) {
            setState(() {
              _held = p;
              _down = p;
            });
            _wake();
          } else if (bathCare && _canScrub && _bathZibo.contains(p)) {
            _scrubbing = true;
            _fx.soapAt = p;
            _scrub(p);
          }
        },
        onPointerMove: (e) {
          final p = toScene(e.localPosition);
          if (_held != null) {
            setState(() => _held = p);
          } else if (_scrubbing) {
            _fx.soapAt = p;
            _scrub(p);
          }
        },
        onPointerUp: (e) {
          final p = toScene(e.localPosition);
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
        child: AnimatedBuilder(
          animation: Listenable.merge([_frame, _hop]),
          builder: (context, _) {
            final hopping = _hopTarget != null;
            final lift = _chew > 0 ? math.sin(_chew / 5).abs() * 10 : 0.0;
            final food = _plateFood;
            final at = _held ?? _plate;
            final size = _held != null ? 120.0 : 104.0;
            final (shift, hopLift, hopOpacity, arriving) = hopping ? _hopPose(_hop.value) : (0.0, 0.0, 0.0, false);
            final spot = arriving ? scene.zibo : (_hopFrom ?? scene.zibo);
            const hopH = _hopSpriteH;
            const hopW = hopH * .789;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(_room),
                    child: RoomView(scene: scene, semanticLabel: _roomName(l10n, _room), ziboLift: lift, showZibo: !hopping),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: CareFxPainter(_fx, repaint: _frame, offsetY: scene.extraTop)),
                  ),
                ),
                if (hopping && hopOpacity > 0)
                  Positioned(
                    left: (spot.x + spot.w / 2 - hopW / 2 + shift) * s,
                    top: (_hopFeetY - hopH + scene.extraTop - hopLift) * s,
                    width: hopW * s,
                    height: hopH * s,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: hopOpacity.clamp(0.0, 1.0),
                        child: Image.asset('assets/images/home/zibo_happy.webp', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                if (showTired && !hopping)
                  Positioned(
                    left: 60 * s,
                    width: 580 * s,
                    top: (scene.zibo.y + scene.extraTop + 10) * s,
                    child: FractionalTranslation(
                      translation: const Offset(0, -1),
                      child: Center(child: _tiredBubble(l10n)),
                    ),
                  ),
                if (kitchenCare && food != null && !hopping)
                  Positioned(
                    left: (at.dx - size / 2) * s,
                    top: (at.dy + scene.extraTop - size / 2 - (_held != null ? 0 : 26)) * s,
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

  // --- Üst çubuk -------------------------------------------------------------

  Widget _topBar(AppLocalizations l10n, HomeNeedsProvider needs) {
    final colorScheme = Theme.of(context).colorScheme;
    final current = _needOf(_room);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              StickerIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                backgroundColor: colorScheme.surfaceContainerLowest,
                iconColor: colorScheme.onSurface,
                size: 38,
                iconSize: 18,
                borderRadius: null,
              ),
              const Spacer(),
              _RoomSwitcher(
                title: _roomName(l10n, _room),
                index: homeRoomOrder.indexOf(_room),
                count: homeRoomOrder.length,
                onPrev: () => _go(-1),
                onNext: () => _go(1),
              ),
              const Spacer(),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: stickerDecoration(
              fill: colorScheme.surfaceContainerLowest.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                for (final need in HomeNeed.values)
                  Expanded(
                    child: _NeedPill(
                      need: need,
                      label: _needLabel(l10n, need),
                      percent: need == HomeNeed.hygiene && _room == HomeRoom.bath && _care
                          ? _bathShown(needs.percent(need))
                          : needs.percent(need),
                      selected: need == current,
                      onTap: () {
                        final target = need.room;
                        final i = homeRoomOrder.indexOf(_room), j = homeRoomOrder.indexOf(target);
                        _go(j > i ? 1 : -1, to: target);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Alt panel -------------------------------------------------------------

  Widget _bottomPanel(
    AppLocalizations l10n,
    HomeNeedsProvider needs,
    HomeDecorProvider decor,
    HomeRoomDef def,
    Map<String, HomeItem> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final v = needs.percent(_needOf(_room));
    final cart = _care ? const <(String, HomeItem, int)>[] : _cart(decor);
    final total = cart.fold<int>(0, (n, e) => n + e.$3);
    final title = _care ? _careTitle(l10n, needs, v) : l10n.shopBalance(context.watch<CoinProvider>().balance);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kStickerOutline.withValues(alpha: .75), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tutamak: dokun ya da aşağı kaydır → panel gizlenir.
            Semantics(
              button: true,
              label: l10n.careHidePanel,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _panelOpen = false),
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 100) setState(() => _panelOpen = false);
                },
                child: SizedBox(
                  height: 18,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.careModeCare)),
                    ButtonSegment(value: false, label: Text(l10n.careModeDecor)),
                  ],
                  selected: {_care},
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onSelectionChanged: (sel) => setState(() {
                    _care = sel.first;
                    _preview.clear();
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 14, height: 1.15),
                  ),
                ),
              ],
            ),
            if (!_care && cart.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(_preview.clear),
                    tooltip: l10n.shopCancel,
                    icon: const Icon(Icons.undo_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _buyCart(decor),
                      child: Text(l10n.shopBuyRoom(total), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            ...(_care ? _careRows(l10n, needs, decor, v) : _decorRows(l10n, decor, def, items)),
          ],
        ),
      ),
    );
  }

  /// Gizlenmiş panel: altta küçük hap; dokununca ya da yukarı kaydırınca açılır.
  Widget _collapsedPanel(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Semantics(
          button: true,
          label: l10n.careShowPanel,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => setState(() => _panelOpen = true),
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -100) setState(() => _panelOpen = true);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: kStickerOutline.withValues(alpha: .75), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    _care ? l10n.careModeCare : l10n.careModeDecor,
                    style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Salonda yorgun Zibo'nun konuşma balonu: yatak odasına götürür ya da kapatılır.
  Widget _tiredBubble(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 10),
          decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.careTiredSleepFirst,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: 16,
                          height: 1.15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _tiredDismissed = true),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () => _go(1, to: HomeRoom.bedroom),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.bedtime_rounded, size: 18),
                label: Text(l10n.careTiredGoBed),
              ),
            ],
          ),
        ),
        // Zibo'ya bakan kuyruk.
        CustomPaint(size: const Size(22, 12), painter: _BubbleTail(colorScheme.surfaceContainerLowest)),
      ],
    );
  }

  /// Uyurken oda değiştirmeye çalışınca ortada solarak beliren pencere.
  Widget _wakeCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(22)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💤', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 6),
          Text(
            l10n.careWakeFirst,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 18, height: 1.15),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _wakeAndGo,
            icon: const Icon(Icons.light_mode_rounded),
            label: Text(l10n.careWakeLight),
          ),
        ],
      ),
    );
  }

  String _careTitle(AppLocalizations l10n, HomeNeedsProvider needs, int v) => switch (_room) {
    HomeRoom.kitchen => _msg ?? (v >= 100 ? l10n.careFeedTitleFull : v < 50 ? l10n.careFeedTitleHungry : l10n.careFeedTitleSome),
    HomeRoom.bath => _phase == _BathPhase.clean ? l10n.careBathTitleClean : l10n.careBathTitleDirty,
    HomeRoom.bedroom =>
      needs.isAsleep
          ? (v >= 100 ? l10n.careBedFull : l10n.careBedSleeping)
          : (v >= 100 ? l10n.careBedRested : (v < 50 ? l10n.careBedTired : l10n.careBedSome)),
    HomeRoom.living => v >= 100 ? l10n.carePlayHappy : v < 50 ? l10n.carePlayBored : l10n.carePlaySome,
  };

  /// Yatay kayan tek sıra.
  Widget _strip(List<Widget> children, {double height = 92}) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => children[i],
    ),
  );

  Widget _chips(List<(String, bool, VoidCallback)> chips) => SizedBox(
    height: 34,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: chips.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final (label, selected, onTap) = chips[i];
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    ),
  );

  List<Widget> _careRows(AppLocalizations l10n, HomeNeedsProvider needs, HomeDecorProvider decor, int v) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_room) {
      case HomeRoom.kitchen:
        final config = context.watch<HomeConfigProvider>().config;
        final freeLeft = needs.freeFoodsLeft;
        final groups = {
          'meyve': l10n.careFoodFruit,
          'yemek': l10n.careFoodMeal,
          'tatli': l10n.careFoodSweet,
          'icecek': l10n.careFoodDrink,
        };
        return [
          _chips([for (final g in groups.entries) (g.value, _foodGroup == g.key, () => setState(() => _foodGroup = g.key))]),
          const SizedBox(height: 6),
          _strip([
            for (final f in homeFoods.where((f) => f.group == _foodGroup))
              Builder(
                builder: (context) {
                  final price = config.foodPrice(f.id, f.price);
                  final tag = price > 0 ? '$price ZC' : (freeLeft > 0 ? '${l10n.careFeedFree} · $freeLeft' : l10n.careFeedTomorrow);
                  return _Tile(
                    semanticLabel: '${f.nameTr}, $tag',
                    onTap: () => _chooseFood(f),
                    image: _FoodImage(id: f.id),
                    title: f.nameTr,
                    tag: tag,
                    tagColor: price > 0 ? kGoldDeep : colorScheme.primary,
                  );
                },
              ),
          ]),
        ];
      case HomeRoom.bath:
        final tier = context.watch<SubscriptionProvider>().tier;
        final config = context.watch<HomeConfigProvider>().config;
        final dirt = _fx.dirt;
        final done = [_phase.index > 1 || (_phase == _BathPhase.foamy && dirt < .25), _phase.index >= 2, _phase.index >= 3];
        final steps = [l10n.careBathStep1, l10n.careBathStep2, l10n.careBathStep3];
        final current = done.indexOf(false);
        return [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    done[i] ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: done[i] ? const Color(0xFF3E8E4E) : colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  current < 0 ? '' : steps[current],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  child: Text(l10n.careBathShower),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _phase == _BathPhase.wet ? _towel : null,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  child: Text(l10n.careBathTowel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _strip(height: 64, [
            for (final sp in homeSoaps)
              ChoiceChip(
                avatar: CircleAvatar(
                  radius: 9,
                  backgroundColor: Color(sp.bar ?? 0xFFFF9FBF),
                  child: sp.foam == null ? const Text('🌈', style: TextStyle(fontSize: 9)) : null,
                ),
                label: Text(
                  decor.isSoapOwned(sp.id) ? sp.nameTr : '${sp.nameTr} · ${config.priceFor('soap:${sp.id}', sp.price, tier)} ZC',
                ),
                selected: decor.selectedSoap == sp.id,
                onSelected: (_) => _buyOrSelectSoap(sp),
              ),
          ]),
        ];
      case HomeRoom.bedroom:
        final asleep = needs.isAsleep;
        return [
          FilledButton.icon(
            onPressed: () => asleep ? needs.wake() : needs.startSleep(),
            icon: Icon(asleep ? Icons.light_mode_rounded : Icons.bedtime_rounded),
            label: Text(asleep ? l10n.careBedWake : l10n.careBedSleep),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.careBedNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ];
      case HomeRoom.living:
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
          _strip([
            for (final (id, name) in games)
              Opacity(
                opacity: config.isEnabled(id) ? 1 : .5,
                child: _Tile(
                  semanticLabel: name,
                  onTap: config.isEnabled(id) ? () => _play(id, name) : null,
                  image: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/game_${id}_thumb.webp', fit: BoxFit.cover),
                  ),
                  title: name,
                ),
              ),
          ]),
        ];
    }
  }

  List<Widget> _decorRows(AppLocalizations l10n, HomeDecorProvider decor, HomeRoomDef def, Map<String, HomeItem> items) {
    final config = context.watch<HomeConfigProvider>().config;
    final sub = context.watch<SubscriptionProvider>();
    final now = DateTime.now();
    final category = def.category(_category)!;
    return [
      _chips([
        for (final c in def.categories)
          (
            _preview.containsKey(c.id) && !decor.isOwned(_room, c.id, _preview[c.id]!) ? '${c.nameTr} •' : c.nameTr,
            c.id == _category,
            () => setState(() => _category = c.id),
          ),
      ]),
      const SizedBox(height: 6),
      _strip(height: 112, [
        for (final item in category.items)
          if (decor.isOwned(_room, category.id, item.id) ||
              (!item.eventOnly && config.isOnSale(_key(category.id, item.id), now)))
            _ShopTile(
              category: category,
              item: item,
              selected: items[category.id]?.id == item.id,
              equipped: decor.equipped(_room, category.id) == item.id,
              owned: decor.isOwned(_room, category.id, item.id),
              price: config.priceFor(_key(category.id, item.id), item.price, sub.tier),
              proOnly: config.isProOnly(_key(category.id, item.id)),
              limited: config.isLimited(_key(category.id, item.id)),
              onTap: () => _tapItem(decor, category, item),
            ),
      ]),
    ];
  }
}

String _needLabel(AppLocalizations l10n, HomeNeed need) => switch (need) {
  HomeNeed.hunger => l10n.worldNeedHunger,
  HomeNeed.hygiene => l10n.worldNeedHygiene,
  HomeNeed.energy => l10n.worldNeedEnergy,
  HomeNeed.fun => l10n.worldNeedFun,
};

const _needEmoji = {HomeNeed.hunger: '🍎', HomeNeed.hygiene: '🫧', HomeNeed.energy: '🌙', HomeNeed.fun: '🎈'};
const _needColors = {
  HomeNeed.hunger: [Color(0xFF9FE3A8), Color(0xFF3E8E4E)],
  HomeNeed.hygiene: [Color(0xFFBFE6F5), Color(0xFF3E9AD6)],
  HomeNeed.energy: [Color(0xFFFFE07A), Color(0xFFF3B23C)],
  HomeNeed.fun: [Color(0xFFFFB7C8), Color(0xFFF2705E)],
};

/// Üstte oda adı, iki yanında oklar ve sıra noktaları.
class _RoomSwitcher extends StatelessWidget {
  const _RoomSwitcher({required this.title, required this.index, required this.count, required this.onPrev, required this.onNext});

  final String title;
  final int index;
  final int count;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
      decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            visualDensity: VisualDensity.compact,
            tooltip: '◀',
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 17, height: 1.1)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: i == index ? 14 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == index ? colorScheme.primary : colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            visualDensity: VisualDensity.compact,
            tooltip: '▶',
          ),
        ],
      ),
    );
  }
}

/// Üst şeritte bir ihtiyaç: simge, ince çubuk, yüzde. Bulunulan odanınki vurgulu.
class _NeedPill extends StatelessWidget {
  const _NeedPill({required this.need, required this.label, required this.percent, required this.selected, required this.onTap});

  final HomeNeed need;
  final String label;
  final int percent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label %$percent',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(_needEmoji[need]!, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('%$percent', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, height: 1.1)),
                    const SizedBox(height: 2),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: kStickerOutline, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (percent / 100).clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: _needColors[need]!))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alt sıradaki küçük kart (yemek, oyun).
class _Tile extends StatelessWidget {
  const _Tile({required this.semanticLabel, required this.onTap, required this.image, required this.title, this.tag, this.tagColor});

  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget image;
  final String title;
  final String? tag;
  final Color? tagColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 76,
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              border: Border.all(color: kStickerOutline, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SizedBox(width: 46, height: 46, child: image),
                const SizedBox(height: 2),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                if (tag != null)
                  Text(
                    tag!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: tagColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            width: 84,
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
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
                    HomeItemThumb(kind: category.kind, item: item, size: 50),
                    if (badge.isNotEmpty) Positioned(top: -4, right: -4, child: Text(badge, style: const TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.nameTr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                Text(
                  tag,
                  maxLines: 1,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: owned || equipped ? colorScheme.primary : kGoldDeep),
                ),
                if (rarity != null && !owned)
                  Text(
                    rarity.localizedName(l10n),
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 8, color: style!.labelColor(Theme.of(context).brightness)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

/// Konuşma balonunun aşağı bakan kuyruğu (sticker çerçeveli).
class _BubbleTail extends CustomPainter {
  _BubbleTail(this.fill);

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, -2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -2);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = kStickerOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubbleTail old) => old.fill != fill;
}
