import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/zibo_world_lines.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../providers/events_provider.dart';
import '../providers/home_needs_provider.dart';
import '../services/world_analytics.dart';
import '../widgets/sticker_style.dart';
import 'events_screen.dart';
import 'game_hall_screen.dart';
import 'home_room_screen.dart';

/// Alt bardaki 2. sekme — Zibo Dünyası (docs/zibo_world.md). Oyun Salonu
/// sekmesinin yerini aldı.
///
/// Giriş ekranı kullanıcının ürettiği görsellerle (docs/zibo_images_needed.md,
/// 2026-11-03): gökyüzü + çayır arka planı, patikadaki beş alanda binalar.
/// **Eve dokununca** tam ekran [HomeRoomScreen] salonda açılır, **Oyun Salonu'na** dokununca
/// [GameHallPage], Etkinlikler'e dokununca [EventsScreen] açılır; Sıralama ve
/// Arkadaşlar 1.19.0'a kadar kilitli (soluk + kilit). Gökyüzünde kodla çizilen
/// parlayan güneş ve yavaşça kayan bulutlar var (2026-11-06, Zibo görseli kalktı);
/// evin üstündeki konuşma balonu Zibo'nun en düşük ihtiyacını söyler (dokununca
/// o oda açılır; Zibo uyuyorsa ev yatak odasında açılır).
///
/// Sahne görselin oranında (1440×2580) çizilir, genişlik en çok 600 dp;
/// yerleşim görselin kesirleriyle (fx, fy) — bina konumları arka plandaki
/// alanlara göre ölçüldü. İhtiyaçlar zamanla düştüğü için sekme görünürken
/// dakikada bir yenilenir; gökyüzü animasyonu da yalnız sekme görünürken
/// döner — `IndexedStack` için [isActive] korumalı ("hareketi azalt" açıksa durur).
class ZiboWorldScreen extends StatefulWidget {
  const ZiboWorldScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ZiboWorldScreen> createState() => _ZiboWorldScreenState();
}

/// Bir binanın sahnedeki yeri: alt-orta noktası (fx, fyBottom) ve genişliği
/// (sahne genişliğinin kesri). Görselin oranı (h/w) yüksekliği verir.
class _Place {
  const _Place(this.asset, this.fx, this.fyBottom, this.width, this.aspect);

  final String asset;
  final double fx;
  final double fyBottom;
  final double width;
  final double aspect;
}

// Arka plandaki alanlar (uzaktan yakına): arka-sol, arka-sağ, orta-sol, orta-sağ, ön.
const _friends = _Place('world_friends', .273, .505, .23, 1024 / 967);
const _leaderboard = _Place('world_leaderboard', .776, .562, .24, 1024 / 884);
const _events = _Place('world_events', .240, .657, .29, 1024 / 951);
const _games = _Place('world_games', .770, .742, .30, 1024 / 821);
const _home = _Place('world_home', .464, .875, .38, 1024 / 809);

const _sceneAspect = 1440 / 2580;
// Gökyüzü katmanının alt sınırı ve evin çatısı (sahne yüksekliğinin kesri).
const _skyBottom = .36;
// Görseldeki ufuk çizgisi (gökyüzü → tepeler), kenar renkleri ölçülerek.
const _horizonY = .415;
const _homeRoofY = .625;

class _ZiboWorldScreenState extends State<ZiboWorldScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  // Gökyüzü: bir tur = bulutların ekranı bir kez geçmesi.
  late final AnimationController _sky = AnimationController(vsync: this, duration: const Duration(seconds: 120));

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(ZiboWorldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncTimer();
      _syncSky();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSky();
  }

  void _syncSky() {
    final run = widget.isActive && !MediaQuery.of(context).disableAnimations;
    if (run && !_sky.isAnimating) {
      _sky.repeat();
    } else if (!run && _sky.isAnimating) {
      _sky.stop();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!widget.isActive) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<HomeNeedsProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sky.dispose();
    super.dispose();
  }

  void _comingSoon(String place) {
    WorldAnalytics.log('world_locked_tap', {'place': place});
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.gameHallComingSoon)));
  }

  void _open(String place, String via, Widget page) {
    WorldAnalytics.log('world_place_open', {'place': place, 'via': via});
    _push(page);
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needs = context.watch<HomeNeedsProvider>();
    final events = context.watch<EventsProvider>();
    final want = needs.lowest;
    final asking = needs.percent(want) < 70;
    final now = DateTime.now();
    final line = ziboWorldLineForLocale(Localizations.localeOf(context), asking ? want : null, now.day * 24 + now.hour);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Yatay (tablet) ekranda sahne yüksekliğe sığar, kaydırma olmaz; dikeyde
        // genişliğe sığar (en çok 720) ve kaydırılır. Sahne ekrandan darsa iki
        // yan, görselin ufkuyla hizalı gökyüzü + tepeler + çimenle dolar ve
        // bulutlar boydan boya kayar (2026-11-07, tablet düzeltmesi).
        final screenW = constraints.maxWidth;
        final wide = screenW > constraints.maxHeight * .9;
        final h0 = wide ? constraints.maxHeight : screenW.clamp(0.0, 720.0) / _sceneAspect;
        final w = wide ? (h0 * _sceneAspect).clamp(0.0, screenW) : screenW.clamp(0.0, 720.0);
        final h = w / _sceneAspect;
        final framed = w < screenW - 1;
        final sceneLeft = (screenW - w) / 2;
        final labels = <Widget>[];
        // Arka sıradaki binaların etiketi üstlerine konur (alt kenarları öndeki binaların arkasında kalır).
        Widget building(_Place p, String label, VoidCallback onTap, {bool locked = false, int badge = 0, bool labelAbove = false}) {
          final bw = p.width * w;
          final bh = bw * p.aspect;
          final top = p.fyBottom * h - bh;
          labels.add(
            Positioned(
              left: p.fx * w - bw,
              width: bw * 2,
              top: labelAbove ? top - 18 : p.fyBottom * h - 6,
              child: Center(child: _Label(text: label, locked: locked, onTap: onTap)),
            ),
          );
          return Positioned(
            left: p.fx * w - bw / 2,
            top: top,
            width: bw,
            height: bh,
            child: _Building(asset: p.asset, label: label, onTap: onTap, locked: locked, badge: badge),
          );
        }

        final bg = Image.asset('assets/images/world/world_bg.webp', fit: BoxFit.fill);
        final sky = IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _SkyPainter(_sky, unit: w, sunX: framed ? (sceneLeft + w * .54) / screenW : null),
            ),
          ),
        );
        return ClipRect(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: wide ? 0 : 80),
            child: SizedBox(
              width: screenW,
              height: h + (wide ? 0 : 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Çerçeveli (tablet): yanlarda görselin ufkuyla hizalı manzara.
                  if (framed) Positioned.fill(child: CustomPaint(painter: _MeadowPainter(horizon: h * _horizonY))),
                  Positioned(
                    left: sceneLeft,
                    width: w,
                    top: 0,
                    height: h,
                    child: framed
                        // Görselin kenarları manzaraya yumuşakça karışsın.
                        ? ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                              stops: [0, .06, .94, 1],
                            ).createShader(rect),
                            child: bg,
                          )
                        : bg,
                  ),
                  // Gökyüzü: parlayan güneş + kayan bulutlar (çerçeveliyse boydan boya).
                  Positioned(left: 0, width: screenW, top: 0, height: h * _skyBottom, child: sky),
                  Positioned(
                    left: sceneLeft,
                    width: w,
                    top: 0,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                    building(_friends, l10n.worldDoorFriends, () => _comingSoon('friends'), locked: true, labelAbove: true),
                    building(_leaderboard, l10n.worldDoorLeaderboard, () => _comingSoon('leaderboard'), locked: true, labelAbove: true),
                    building(_events, l10n.worldDoorEvents, () => _open('events', 'building', const EventsScreen()), badge: events.openableCount),
                    building(_games, l10n.tabGameHall, () => _open('games', 'building', const GameHallPage())),
                    building(_home, l10n.worldHouseSign, () => _open('home', 'building', const HomeRoomScreen())),
                    // Evden seslenen Zibo: balon evin çatısının üstünde, kuyruğu eve bakar.
                    Positioned(
                      left: w * .26,
                      right: w * .26,
                      top: h * _homeRoofY,
                      child: FractionalTranslation(
                        translation: const Offset(0, -1),
                        child: Center(
                          child: _SpeechBubble(
                            text: line,
                            onTap: () => _open('home', 'bubble', HomeRoomScreen(initialRoom: asking ? want.room : HomeRoom.living)),
                          ),
                        ),
                      ),
                    ),
                    ...labels,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Oyun Salonu, Zibo Dünyası'ndaki Oyun Salonu binasından açılan sayfa olarak.
class GameHallPage extends StatelessWidget {
  const GameHallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: plainStickerAppBar(context, title: l10n.tabGameHall),
      body: const GameHallScreen(),
    );
  }
}

/// Dokunulabilir bina: görsel + altında ad etiketi; basılıyken hafif küçülür.
/// Kilitliyse soluk ve kilitli; [badge] > 0 ise kırmızı sayı.
class _Building extends StatefulWidget {
  const _Building({required this.asset, required this.label, required this.onTap, this.locked = false, this.badge = 0});

  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool locked;
  final int badge;

  @override
  State<_Building> createState() => _BuildingState();
}

class _BuildingState extends State<_Building> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: widget.badge > 0 ? '${widget.label} (${widget.badge})' : widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !reduceMotion ? .94 : 1,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: widget.locked ? .55 : 1,
                  child: Image.asset('assets/images/world/${widget.asset}.webp', fit: BoxFit.contain),
                ),
              ),
              if (widget.badge > 0)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2463A),
                      border: Border.all(color: kStickerOutline, width: 2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Binanın ad etiketi (kilitliyse kilit simgeli). Etiketler binaların üstünde
/// ayrı katmanda çizilir; dokununca binayla aynı şeyi açar.
class _Label extends StatelessWidget {
  const _Label({required this.text, required this.locked, required this.onTap});

  final String text;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 3),
              ],
              Text(text, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evdeki Zibo'nun konuşma balonu (altta eve bakan kuyruk).
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18)),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.25, color: colorScheme.onSurface),
              ),
            ),
            CustomPaint(size: const Size(20, 11), painter: _TailPainter(colorScheme.surfaceContainerLowest)),
          ],
        ),
      ),
    );
  }
}

/// Konuşma balonunun aşağı bakan kuyruğu.
class _TailPainter extends CustomPainter {
  _TailPainter(this.fill);

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
  bool shouldRepaint(_TailPainter old) => old.fill != fill;
}

/// Bir bulutun yolu: dikey konum ve boy (gökyüzü katmanının kesri), hız
/// (bir turda ekranı kaç kez geçtiği) ve başlangıç kayması.
class _Cloud {
  const _Cloud(this.fy, this.size, this.speed, this.phase, this.opacity);

  final double fy;
  final double size;
  final int speed;
  final double phase;
  final double opacity;
}

// Uzaktakiler küçük, yavaş ve soluk; yakındakiler büyük ve hızlı.
const _clouds = [
  _Cloud(.20, .15, 1, .10, .80),
  _Cloud(.52, .12, 1, .62, .70),
  _Cloud(.36, .22, 2, .35, .95),
  _Cloud(.72, .17, 2, .85, .85),
  _Cloud(.10, .19, 3, .55, .90),
];

/// Gökyüzü: sol üstte parlayan, ışınları yavaşça dönen güneş ve soldan sağa
/// kayan çizgi film bulutları (sticker konturlu). [t] 0..1 döngüsü.
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t, {this.unit, this.sunX}) : super(repaint: t);

  final Animation<double> t;

  /// Bulut ve güneş boyunun ölçüsü (sahne genişliği); null = tuval genişliği.
  final double? unit;

  /// Güneşin yatay yeri (tuval genişliğinin kesri); null = .54.
  final double? sunX;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    _sun(canvas, size, v);
    for (final c in _clouds) {
      final u = unit ?? size.width;
      final cw = u * c.size * 1.9;
      // Ekranın solundan girer, sağından çıkar; sonra başa sarar.
      final x = ((v * c.speed + c.phase) % 1) * (size.width + cw * 2) - cw;
      _cloud(canvas, Offset(x, size.height * c.fy), u * c.size, c.opacity);
    }
  }

  void _sun(Canvas canvas, Size size, double v) {
    final r = (unit ?? size.width) * .085;
    final c = Offset(size.width * (sunX ?? .54), size.height * .31);
    final pulse = 1 + math.sin(v * math.pi * 2 * 12) * .04;
    // Hale.
    canvas.drawCircle(
      c,
      r * 2.4 * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x80FFF3B0), Color(0x00FFF3B0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 2.4 * pulse)),
    );
    // Dönen ışınlar.
    final ray = Paint()
      ..color = const Color(0xFFFFC93C)
      ..style = PaintingStyle.fill;
    final rayLine = Paint()
      ..color = kStickerOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(v * math.pi * 2 * 2);
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 2 / 10;
      final inner = r * 1.18, outer = r * (i.isEven ? 1.62 : 1.45), half = .17;
      final path = Path()
        ..moveTo(math.cos(a - half) * inner, math.sin(a - half) * inner)
        ..lineTo(math.cos(a) * outer, math.sin(a) * outer)
        ..lineTo(math.cos(a + half) * inner, math.sin(a + half) * inner)
        ..close();
      canvas.drawPath(path, ray);
      canvas.drawPath(path, rayLine);
    }
    canvas.restore();
    // Gövde.
    final body = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.35),
          colors: [Color(0xFFFFF6B8), Color(0xFFFFD447), Color(0xFFFFB627)],
          stops: [0, .55, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = kStickerOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Parıltı.
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * .38, -r * .42), width: r * .42, height: r * .24),
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  void _cloud(Canvas canvas, Offset center, double w, double opacity) {
    // Altı düz, üstü kabarık: üç tepe + taban.
    final h = w * .42;
    final base = Rect.fromCenter(center: center + Offset(0, h * .18), width: w * 1.7, height: h * .62);
    final shape = Path()
      ..addRRect(RRect.fromRectAndRadius(base, Radius.circular(h * .31)))
      ..addOval(Rect.fromCircle(center: center + Offset(-w * .42, h * .05), radius: h * .38))
      ..addOval(Rect.fromCircle(center: center + Offset(0, -h * .2), radius: h * .55))
      ..addOval(Rect.fromCircle(center: center + Offset(w * .42, h * .02), radius: h * .42));
    final merged = Path.combine(PathOperation.union, shape, Path());
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawPath(merged.shift(Offset(0, h * .12)), Paint()..color = const Color(0x22427AA1));
    canvas.drawPath(merged, Paint()..color = Colors.white);
    canvas.drawPath(
      merged,
      Paint()
        ..color = const Color(0xFF9CC7E4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

/// Tablette sahnenin yanları: görselin ufkuyla hizalı gökyüzü, iki sıra yumuşak
/// tepe ve aşağı doğru koyulaşan çimen (renkler world_bg kenarlarından ölçüldü).
class _MeadowPainter extends CustomPainter {
  _MeadowPainter({required this.horizon});

  final double horizon;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon + 2),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FCEF1), Color(0xFFB3DDF5), Color(0xFFE0F3FD)],
          stops: [0, .5, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );
    Path hills(double base, double amp, double period, double phase) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, base);
      for (var x = 0.0; x <= w; x += 8) {
        path.lineTo(x, base - amp * (0.5 + 0.5 * math.sin(x / period + phase)));
      }
      return path
        ..lineTo(w, size.height)
        ..close();
    }

    canvas.drawPath(hills(horizon + 14, 22, 120, 1.3), Paint()..color = const Color(0xFFA6CF5D));
    canvas.drawPath(
      hills(horizon + 40, 18, 90, 4.1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8BBE4A), Color(0xFF6EA831), Color(0xFF4F8A2C), Color(0xFF3A712C)],
          stops: [0, .25, .7, 1],
        ).createShader(Rect.fromLTWH(0, horizon, w, size.height - horizon)),
    );
  }

  @override
  bool shouldRepaint(_MeadowPainter old) => old.horizon != horizon;
}
