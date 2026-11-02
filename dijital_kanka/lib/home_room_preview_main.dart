import 'package:flutter/material.dart';

import 'data/home_catalog.dart';
import 'models/home_item.dart';
import 'widgets/home_art/room_view.dart';

/// Geliştirme önizlemesi (Firebase'siz): dört oda, üstte başlangıç takımıyla,
/// altta her kategorinin SON eşyasıyla — kodla çizilen odaları taslakla
/// (docs/home_studio/index.html) yan yana karşılaştırmak için.
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF222222),
        body: SingleChildScrollView(child: Column(children: [row(false), row(true)])),
      ),
    );
  }
}
