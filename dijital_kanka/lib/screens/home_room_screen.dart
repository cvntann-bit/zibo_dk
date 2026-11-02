import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/home_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../providers/home_decor_provider.dart';
import '../utils/adaptive.dart';
import '../widgets/home_art/room_view.dart';
import '../widgets/home_art/svg_kit.dart';
import '../widgets/sticker_style.dart';

/// Zibo Dünyası'nda bir oda (docs/zibo_world_roadmap.md Faz 2). Oda
/// takılı eşyalarla çizilir; alttaki seçiciyle eşyalar DENENİR — deneme
/// kaydedilmez, satın alma Faz 5'te (dekor mağazası) gelir.
class HomeRoomScreen extends StatefulWidget {
  const HomeRoomScreen({super.key, required this.room, required this.title});

  final HomeRoom room;
  final String title;

  @override
  State<HomeRoomScreen> createState() => _HomeRoomScreenState();
}

class _HomeRoomScreenState extends State<HomeRoomScreen> {
  final _cache = RoomSceneCache();
  final Map<String, String> _preview = {};
  late String _category = HomeDecorProvider.roomDef(widget.room).categories.first.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final decor = context.watch<HomeDecorProvider>();
    final def = HomeDecorProvider.roomDef(widget.room);
    final items = {
      for (final c in def.categories) c.id: c.item(_preview[c.id] ?? decor.equipped(widget.room, c.id)) ?? decor.equippedItem(widget.room, c.id),
    };
    final soap = homeSoaps.firstWhere((s) => s.id == decor.selectedSoap, orElse: () => homeSoaps.first);
    final scene = _cache.get(widget.room, items, soapColor: SvgKit.hex(soap.bar ?? 0xFFFF9FBF));
    final category = def.category(_category)!;
    final hPad = Adaptive.horizontalPadding(context, maxWidth: 560, minPadding: 16);

    return Scaffold(
      appBar: plainStickerAppBar(context, title: widget.title),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kStickerOutline, width: 3),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: RoomView(scene: scene, semanticLabel: widget.title),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: def.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = def.categories[i];
                return ChoiceChip(
                  label: Text(c.nameTr),
                  selected: c.id == _category,
                  onSelected: (_) => setState(() => _category = c.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in category.items)
                ChoiceChip(
                  avatar: item.color == null
                      ? null
                      : CircleAvatar(backgroundColor: Color(item.color!), radius: 8),
                  label: Text(item.nameTr),
                  selected: items[category.id]?.id == item.id,
                  onSelected: (_) => setState(() {
                    if (decor.equipped(widget.room, category.id) == item.id) {
                      _preview.remove(category.id);
                    } else {
                      _preview[category.id] = item.id;
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.worldRoomPreviewHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
