import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../models/home_need.dart';
import '../providers/home_decor_provider.dart';
import '../providers/home_needs_provider.dart';
import '../utils/adaptive.dart';
import '../widgets/sticker_style.dart';
import 'game_hall_screen.dart';

/// Alt bardaki 2. sekme — Zibo Dünyası (docs/zibo_world.md). Oyun Salonu
/// sekmesinin yerini aldı; oyunlar artık buradaki "Oyunlar" kapısından
/// [GameHallPage] ile açılır.
///
/// Faz 1 iskeleti (docs/zibo_world_roadmap.md): dört ihtiyaç göstergesi,
/// 2×2 ev kesiti (odalar takılı boya rengiyle; Zibo en düşük ihtiyacın
/// odasında) ve kapılar. Oda ekranları Faz 2–5'te gelir.
///
/// İhtiyaçlar zamanla düştüğü için sekme görünürken dakikada bir yenilenir —
/// `IndexedStack` sekmeyi hep kurulu tuttuğu için [isActive] korumalı.
class ZiboWorldScreen extends StatefulWidget {
  const ZiboWorldScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ZiboWorldScreen> createState() => _ZiboWorldScreenState();
}

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final needs = context.watch<HomeNeedsProvider>();
    final decor = context.watch<HomeDecorProvider>();
    final hPad = Adaptive.horizontalPadding(context, maxWidth: 720, minPadding: 16);
    final ziboRoom = needs.lowest.room;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 96),
      children: [
        Text(
          l10n.worldTitle,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontVariations: const [FontVariation('wght', 800)],
            fontSize: 28,
            height: 1.05,
            color: colorScheme.primary,
            shadows: const [Shadow(color: kStickerOutline, offset: Offset(2, 2))],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final need in HomeNeed.values)
              Expanded(child: _NeedRing(need: need, percent: needs.percent(need))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: stickerDecoration(
            fill: const Color(0xFFE9C38F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (final row in const [
                [HomeRoom.bedroom, HomeRoom.bath],
                [HomeRoom.living, HomeRoom.kitchen],
              ]) ...[
                Row(
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _RoomCard(
                          room: row[i],
                          wall: Color(decor.equippedItem(row[i], 'boya').color ?? 0xFFFFE7B0),
                          hasZibo: row[i] == ziboRoom,
                          onTap: _comingSoon,
                        ),
                      ),
                    ],
                  ],
                ),
                if (row.first == HomeRoom.bedroom) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: [
            _DoorButton(
              emoji: '🎮',
              label: l10n.worldDoorGames,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameHallPage())),
            ),
            _DoorButton(emoji: '🎉', label: l10n.worldDoorEvents, onTap: _comingSoon),
            _DoorButton(emoji: '🏆', label: l10n.worldDoorLeaderboard, onTap: _comingSoon, locked: true),
            _DoorButton(emoji: '👫', label: l10n.worldDoorFriends, onTap: _comingSoon, locked: true),
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

const _needEmoji = {HomeNeed.hunger: '🍎', HomeNeed.hygiene: '🫧', HomeNeed.energy: '🌙', HomeNeed.fun: '🎈'};

class _NeedRing extends StatelessWidget {
  const _NeedRing({required this.need, required this.percent});

  final HomeNeed need;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final color = percent >= 60
        ? const Color(0xFF3FB98A)
        : percent >= 30
        ? kGoldDeep
        : const Color(0xFFE2668F);
    final label = _needLabel(l10n, need);
    return Semantics(
      label: '$label %$percent',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 6,
                    color: color,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                Text(_needEmoji[need]!, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.wall, required this.hasZibo, required this.onTap});

  final HomeRoom room;
  final Color wall;
  final bool hasZibo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _roomLabel(l10n, room);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            height: 132,
            decoration: BoxDecoration(
              color: wall,
              border: Border.all(color: kStickerOutline, width: 2.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 6,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: [FontVariation('wght', 800)],
                      fontSize: 15,
                      color: kStickerOutline,
                    ),
                  ),
                ),
                if (hasZibo)
                  Positioned(
                    right: 6,
                    bottom: 4,
                    child: Image.asset('assets/images/zibo_df_pose4.webp', height: 84),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoorButton extends StatelessWidget {
  const _DoorButton({required this.emoji, required this.label, required this.onTap, this.locked = false});

  final String emoji;
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
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: stickerDecoration(
                fill: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 800)],
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (locked) Icon(Icons.lock_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
