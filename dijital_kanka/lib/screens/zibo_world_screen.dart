import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/zibo_world_lines.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../providers/events_provider.dart';
import '../providers/home_needs_provider.dart';
import '../widgets/sticker_style.dart';
import 'events_screen.dart';
import 'game_hall_screen.dart';
import 'home_house_screen.dart';
import 'home_room_screen.dart';

/// Alt bardaki 2. sekme — Zibo Dünyası (docs/zibo_world.md). Oyun Salonu
/// sekmesinin yerini aldı.
///
/// Giriş ekranı kullanıcının ürettiği görsellerle (docs/zibo_images_needed.md,
/// 2026-11-03): gökyüzü + çayır arka planı, patikadaki beş alanda binalar.
/// **Eve dokununca** [HomeHouseScreen] (2×2 oda), **Oyun Salonu'na** dokununca
/// [GameHallPage], Etkinlikler'e dokununca [EventsScreen] açılır; Sıralama ve
/// Arkadaşlar 1.19.0'a kadar kilitli (soluk + kilit). Gökyüzünde el sallayan
/// Zibo, konuşma balonuyla en düşük ihtiyacını söyler (dokununca o oda açılır).
///
/// Sahne görselin oranında (1440×2580) çizilir, genişlik en çok 600 dp;
/// yerleşim görselin kesirleriyle (fx, fy) — bina konumları arka plandaki
/// alanlara göre ölçüldü. İhtiyaçlar zamanla düştüğü için sekme görünürken
/// dakikada bir yenilenir — `IndexedStack` için [isActive] korumalı.
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

class _ZiboWorldScreenState extends State<ZiboWorldScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(ZiboWorldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _syncTimer();
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
    super.dispose();
  }

  void _comingSoon() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.gameHallComingSoon)));
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  String _roomTitle(AppLocalizations l10n, HomeRoom room) => switch (room) {
    HomeRoom.kitchen => l10n.worldRoomKitchen,
    HomeRoom.bath => l10n.worldRoomBath,
    HomeRoom.bedroom => l10n.worldRoomBedroom,
    HomeRoom.living => l10n.worldRoomLiving,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needs = context.watch<HomeNeedsProvider>();
    final events = context.watch<EventsProvider>();
    final want = needs.lowest;
    final asking = needs.percent(want) < 70;
    final now = DateTime.now();
    final line = ziboWorldLineForLocale(Localizations.localeOf(context), asking ? want : null, now.day * 24 + now.hour);
    final pose = needs.percent(want) < 30 ? 'pout' : 'wave';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(0.0, 600.0);
        final h = w / _sceneAspect;
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

        final ziboH = h * .22;
        return DecoratedBox(
          // Sahne kenarlarında (tablet) gökyüzünden çimene geçen zemin.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8ECDF0), Color(0xFFCFE9F7), Color(0xFF7DC45A), Color(0xFF5DA845)],
              stops: [0, .4, .42, 1],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Center(
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: Image.asset('assets/images/world/world_bg.webp', fit: BoxFit.fill)),
                    // Gökyüzünde Zibo + konuşma balonu.
                    Positioned(
                      left: w * .05,
                      top: h * .14,
                      height: ziboH,
                      child: Image.asset('assets/images/home/zibo_$pose.webp', fit: BoxFit.contain),
                    ),
                    Positioned(
                      left: w * .38,
                      right: w * .05,
                      top: h * .17,
                      child: _SpeechBubble(
                        text: line,
                        onTap: asking
                            ? () => _push(HomeRoomScreen(room: want.room, title: _roomTitle(l10n, want.room)))
                            : () => _push(const HomeHouseScreen()),
                      ),
                    ),
                    building(_friends, l10n.worldDoorFriends, _comingSoon, locked: true, labelAbove: true),
                    building(_leaderboard, l10n.worldDoorLeaderboard, _comingSoon, locked: true, labelAbove: true),
                    building(_events, l10n.worldDoorEvents, () => _push(const EventsScreen()), badge: events.openableCount),
                    building(_games, l10n.tabGameHall, () => _push(const GameHallPage())),
                    building(_home, l10n.worldHouseSign, () => _push(const HomeHouseScreen())),
                    ...labels,
                  ],
                ),
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

/// Gökyüzündeki Zibo'nun konuşma balonu (sol altta Zibo'ya bakan kuyruk).
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18)),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.25, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
