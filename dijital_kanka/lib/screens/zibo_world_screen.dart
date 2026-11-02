import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/home_catalog.dart';
import '../data/zibo_world_lines.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../models/home_need.dart';
import '../providers/home_decor_provider.dart';
import '../providers/home_needs_provider.dart';
import '../utils/adaptive.dart';
import '../widgets/home_art/room_art.dart';
import '../widgets/home_art/room_view.dart';
import '../widgets/home_art/svg_kit.dart';
import '../widgets/sticker_style.dart';
import 'game_hall_screen.dart';
import 'home_room_screen.dart';

/// Alt bardaki 2. sekme — Zibo Dünyası (docs/zibo_world.md). Oyun Salonu
/// sekmesinin yerini aldı; oyunlar buradaki "Oyunlar" kapısından
/// [GameHallPage] ile açılır.
///
/// Faz 3 giriş ekranı (docs/zibo_world_roadmap.md, taslak
/// `docs/zibo_world_prototype/`): üstte dört ihtiyaç halkası, ortada çatılı
/// ev kesiti (2×2 oda, takılı dekorla küçük çizimler), Zibo en düşük
/// ihtiyacın odasında ve konuşma balonuyla onu ister; sağda kapılar.
/// Halkaya, odaya ya da balona dokununca oda yakınlaşarak açılır.
///
/// İhtiyaçlar zamanla düştüğü için sekme görünürken dakikada bir yenilenir —
/// `IndexedStack` sekmeyi hep kurulu tuttuğu için [isActive] korumalı.
class ZiboWorldScreen extends StatefulWidget {
  const ZiboWorldScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ZiboWorldScreen> createState() => _ZiboWorldScreenState();
}

/// Taslaktaki oda sırası: üst sıra mutfak · banyo, alt sıra yatak · salon.
const _roomOrder = [HomeRoom.kitchen, HomeRoom.bath, HomeRoom.bedroom, HomeRoom.living];

class _ZiboWorldScreenState extends State<ZiboWorldScreen> {
  Timer? _timer;
  final _caches = {for (final r in HomeRoom.values) r: RoomSceneCache()};

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

  /// Oda, evdeki yerinden büyüyerek açılır (hareket azaltma açıksa düz geçiş).
  void _openRoom(HomeRoom room) {
    final l10n = AppLocalizations.of(context)!;
    final i = _roomOrder.indexOf(room);
    final from = Alignment(i.isEven ? -0.55 : 0.45, i < 2 ? -0.25 : 0.45);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => HomeRoomScreen(room: room, title: _roomLabel(l10n, room)),
        transitionsBuilder: (context, animation, _, child) {
          if (MediaQuery.of(context).disableAnimations) return child;
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.55, end: 1.0).animate(curved), alignment: from, child: child),
          );
        },
      ),
    );
  }

  RoomScene _scene(HomeDecorProvider decor, HomeRoom room, String pose) {
    final def = HomeDecorProvider.roomDef(room);
    final soap = homeSoaps.firstWhere((s) => s.id == decor.selectedSoap, orElse: () => homeSoaps.first);
    return _caches[room]!.get(
      room,
      {for (final c in def.categories) c.id: decor.equippedItem(room, c.id)},
      pose: pose,
      soapColor: SvgKit.hex(soap.bar ?? 0xFFFF9FBF),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needs = context.watch<HomeNeedsProvider>();
    final decor = context.watch<HomeDecorProvider>();
    final hPad = Adaptive.horizontalPadding(context, maxWidth: 640, minPadding: 12);
    final want = needs.lowest;
    final wantLevel = needs.percent(want);
    final asking = wantLevel < 70;
    final now = DateTime.now();
    final line = ziboWorldLineForLocale(Localizations.localeOf(context), asking ? want : null, now.day * 24 + now.hour);
    final pose = wantLevel < 30 ? 'pout' : 'happy';

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 96),
      children: [
        Row(
          children: [
            for (final need in HomeNeed.values)
              Expanded(
                child: _NeedRing(need: need, percent: needs.percent(need), onTap: () => _openRoom(need.room)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _House(
                sign: l10n.worldHouseSign,
                line: line,
                onBubbleTap: asking ? () => _openRoom(want.room) : null,
                rooms: [
                  for (final room in _roomOrder)
                    _HouseRoom(
                      room: room,
                      label: _roomLabel(l10n, room),
                      scene: _scene(decor, room, pose),
                      hasZibo: room == want.room,
                      onTap: () => _openRoom(room),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 68,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    _Door(
                      icon: _doorIcons['games']!,
                      label: l10n.worldDoorGames,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameHallPage())),
                    ),
                    const SizedBox(height: 10),
                    _Door(icon: _doorIcons['events']!, label: l10n.worldDoorEvents, onTap: _comingSoon),
                    const SizedBox(height: 10),
                    _Door(icon: _doorIcons['leaderboard']!, label: l10n.worldDoorLeaderboard, onTap: _comingSoon, locked: true),
                    const SizedBox(height: 10),
                    _Door(icon: _doorIcons['friends']!, label: l10n.worldDoorFriends, onTap: _comingSoon, locked: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Oyun Salonu, Zibo Dünyası'nın "Oyunlar" kapısından açılan sayfa olarak.
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

String _needLabel(AppLocalizations l10n, HomeNeed need) => switch (need) {
  HomeNeed.hunger => l10n.worldNeedHunger,
  HomeNeed.hygiene => l10n.worldNeedHygiene,
  HomeNeed.energy => l10n.worldNeedEnergy,
  HomeNeed.fun => l10n.worldNeedFun,
};

String _roomLabel(AppLocalizations l10n, HomeRoom room) => switch (room) {
  HomeRoom.kitchen => l10n.worldRoomKitchen,
  HomeRoom.bath => l10n.worldRoomBath,
  HomeRoom.bedroom => l10n.worldRoomBedroom,
  HomeRoom.living => l10n.worldRoomLiving,
};

// Taslaktaki halka ve kapı simgeleri (60×60 birim).
const _needColors = {
  HomeNeed.hunger: '#3E8E4E',
  HomeNeed.hygiene: '#3E9AD6',
  HomeNeed.energy: '#E0A12A',
  HomeNeed.fun: '#E0607A',
};
const _needIcons = {
  HomeNeed.hunger:
      '<circle cx="30" cy="34" r="16" fill="#F2564B"/><circle cx="25" cy="29" r="5" fill="#fff" opacity=".5"/><rect x="28" y="12" width="4" height="9" rx="2" fill="#7A4B2C"/><path d="M32 17c5-6 12-6 14-2-5 4-10 4-14 2z" fill="#55B868"/>',
  HomeNeed.hygiene:
      '<circle cx="24" cy="34" r="12" fill="#BFE6F5" stroke="#3E9AD6" stroke-width="3"/><circle cx="38" cy="24" r="8" fill="#BFE6F5" stroke="#3E9AD6" stroke-width="3"/><circle cx="40" cy="40" r="5" fill="#BFE6F5" stroke="#3E9AD6" stroke-width="3"/><circle cx="20" cy="30" r="3" fill="#fff"/>',
  HomeNeed.energy:
      '<path d="M38 14a18 18 0 1 0 10 30 15 15 0 1 1-10-30z" fill="#FFD64A" stroke="#E0A12A" stroke-width="2"/><circle cx="20" cy="18" r="2" fill="#E0A12A"/><circle cx="46" cy="16" r="1.6" fill="#E0A12A"/>',
  HomeNeed.fun:
      '<path d="M30 46C16 36 12 28 15 22c3-6 11-7 15 0 4-7 12-6 15 0 3 6-1 14-15 24z" fill="#F7A8BE" stroke="#E0607A" stroke-width="3"/>',
};
const _doorIcons = {
  'games':
      '<rect x="4" y="18" width="52" height="30" rx="15" fill="#7C5CD6" stroke="#14110C" stroke-width="3"/><rect x="14" y="30" width="14" height="5" rx="2" fill="#fff"/><rect x="18.5" y="25.5" width="5" height="14" rx="2" fill="#fff"/><circle cx="40" cy="29" r="3.5" fill="#FFD64A"/><circle cx="46" cy="35" r="3.5" fill="#F2705E"/>',
  'events':
      '<rect x="8" y="18" width="44" height="34" rx="6" fill="#F2705E" stroke="#14110C" stroke-width="3"/><rect x="4" y="12" width="52" height="12" rx="5" fill="#FF9F8F" stroke="#14110C" stroke-width="3"/><rect x="27" y="12" width="6" height="40" fill="#FFD64A"/><path d="M30 12c-8-12-20-6-12 0zm0 0c8-12 20-6 12 0z" fill="#FFD64A" stroke="#14110C" stroke-width="2.5"/>',
  'leaderboard':
      '<path d="M18 8h24v14a12 12 0 0 1-24 0z" fill="#FFD64A" stroke="#14110C" stroke-width="3"/><path d="M18 12H8c0 10 6 14 12 14M42 12h10c0 10-6 14-12 14" fill="none" stroke="#14110C" stroke-width="3"/><rect x="26" y="34" width="8" height="10" fill="#E0A12A"/><rect x="16" y="44" width="28" height="8" rx="3" fill="#C9772E" stroke="#14110C" stroke-width="3"/>',
  'friends':
      '<circle cx="22" cy="22" r="9" fill="#F7C49A" stroke="#14110C" stroke-width="3"/><circle cx="40" cy="24" r="8" fill="#F7C49A" stroke="#14110C" stroke-width="3"/><path d="M6 50c0-12 8-18 16-18s16 6 16 18z" fill="#7CC8F0" stroke="#14110C" stroke-width="3"/><path d="M30 50c0-10 6-16 11-16s13 6 13 16z" fill="#9FE3A8" stroke="#14110C" stroke-width="3"/>',
};

String _svg60(String body) => '<svg viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg">$body</svg>';

class _NeedRing extends StatelessWidget {
  const _NeedRing({required this.need, required this.percent, required this.onTap});

  final HomeNeed need;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final label = l10n.worldNeedPercent(_needLabel(l10n, need), percent);
    const len = 2 * 3.14159265 * 26;
    final ring =
        '<circle cx="30" cy="30" r="26" fill="#FFFDF7" stroke="#E7D9BE" stroke-width="6"/>'
        '${percent <= 0 ? '' : '<circle cx="30" cy="30" r="26" fill="none" stroke="${_needColors[need]}" stroke-width="6" stroke-linecap="round" stroke-dasharray="${(len * percent / 100).toStringAsFixed(1)} ${len.toStringAsFixed(1)}" transform="rotate(-90 30 30)"/>'}'
        '<g transform="translate(6 4) scale(.8)">${_needIcons[need]}</g>';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SvgPicture.string(_svg60(ring), width: 52, height: 52),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseRoom {
  const _HouseRoom({required this.room, required this.label, required this.scene, required this.hasZibo, required this.onTap});

  final HomeRoom room;
  final String label;
  final RoomScene scene;
  final bool hasZibo;
  final VoidCallback onTap;
}

/// Taslaktaki `houseSvg()`: 1000 birim genişlikte çatı, baca, tabela, duvar
/// çerçevesi ve çim; odalar çerçevenin içine 2×2 dizilir.
class _House extends StatelessWidget {
  const _House({required this.sign, required this.line, required this.onBubbleTap, required this.rooms});

  final String sign;
  final String line;
  final VoidCallback? onBubbleTap;
  final List<_HouseRoom> rooms;

  static const double _w = 1000;
  static const double _cw = 470;
  static const double _ch = 543; // 470 × 1040 / 900
  static const double _gx = 20;
  static const double _gy = 250;
  static const double _gap = 20;
  static const double _h = _gy + 2 * _ch + _gap + 40;

  static final String _frame =
      '<svg viewBox="0 0 1000 ${_h.toInt()}" xmlns="http://www.w3.org/2000/svg">'
      '<rect x="790" y="40" width="70" height="150" fill="#C46A4E" stroke="#14110C" stroke-width="8"/>'
      '<rect x="778" y="28" width="94" height="26" rx="6" fill="#9E5039" stroke="#14110C" stroke-width="8"/>'
      '<circle cx="830" cy="0" r="18" fill="#fff" opacity=".8"/><circle cx="850" cy="-30" r="12" fill="#fff" opacity=".6"/>'
      '<path d="M-10 ${(_gy - 4).toInt()}L500 30L1010 ${(_gy - 4).toInt()}z" fill="#E57B5C" stroke="#14110C" stroke-width="10" stroke-linejoin="round"/>'
      '<path d="M60 ${(_gy - 30).toInt()}L500 70L940 ${(_gy - 30).toInt()}" fill="none" stroke="#C9604A" stroke-width="10" stroke-linecap="round"/>'
      '<rect x="370" y="140" width="260" height="70" rx="20" fill="#FFF8EA" stroke="#14110C" stroke-width="7"/>'
      '<rect x="0" y="${(_gy - 8).toInt()}" width="1000" height="${(2 * _ch + _gap + 34).toInt()}" rx="16" fill="#8E5B3A" stroke="#14110C" stroke-width="10"/>'
      '<rect x="-20" y="${(_h - 22).toInt()}" width="1040" height="40" fill="#7CCB78" stroke="#14110C" stroke-width="8"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _w / _h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth / _w;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: SvgPicture.string(_frame, fit: BoxFit.fill)),
              Positioned(
                left: 370 * s,
                top: 140 * s,
                width: 260 * s,
                height: 70 * s,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        sign,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: 36 * s,
                          color: kStickerOutline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < rooms.length; i++)
                Positioned(
                  left: (_gx + (i % 2) * (_cw + _gap)) * s,
                  top: (_gy + (i ~/ 2) * (_ch + _gap)) * s,
                  width: _cw * s,
                  height: _ch * s,
                  child: Semantics(
                    button: true,
                    label: rooms[i].label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: rooms[i].onTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6 * s),
                        child: RoomThumb(scene: rooms[i].scene, showZibo: rooms[i].hasZibo),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: -4,
                child: Center(child: _Bubble(text: line, onTap: onBubbleTap)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Zibo'nun konuşma balonu (evin çatısının üstünde). İstek varsa dokununca
/// ilgili oda açılır.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.25, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({required this.icon, required this.label, required this.onTap, this.locked = false});

  final String icon;
  final String label;
  final VoidCallback onTap;

  /// Sıralama ve Arkadaşlar 1.18.0'a girmiyor (Faz 0 kararı) — soluk görünür.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(2, 5, 2, 6),
              decoration: stickerDecoration(fill: colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(18)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: SvgPicture.string(_svg60(icon), width: 36, height: 36)),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, height: 1.1, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  if (locked)
                    Positioned(top: -2, right: 2, child: Icon(Icons.lock_rounded, size: 14, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
