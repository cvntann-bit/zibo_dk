import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/home_item.dart';
import 'room_art.dart';

/// Bir odayı çizer: arka SVG → Zibo pozu → ön SVG (docs/zibo_world_roadmap.md
/// Faz 2). 900×1200 birimlik taslak sahnesi verilen genişliğe ölçeklenir.
/// Sahneyi her build'de yeniden üretmemek için [RoomSceneCache] kullan.
class RoomView extends StatelessWidget {
  const RoomView({super.key, required this.scene, this.semanticLabel, this.showZibo = true, this.ziboLift = 0});

  final RoomScene scene;
  final String? semanticLabel;

  /// Giriş ekranının ev kesitinde Zibo yalnızca bir odada görünür.
  final bool showZibo;

  /// Zibo'yu sahne biriminde yukarı kaldırır (yemek yerken zıplama).
  final double ziboLift;

  static const double sceneWidth = 900;
  static const double sceneHeight = 1200;

  @override
  Widget build(BuildContext context) {
    final zibo = scene.zibo;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: sceneWidth / sceneHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / sceneWidth;
            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SvgPicture.string(scene.back, fit: BoxFit.fill),
                  if (showZibo)
                    Positioned(
                      left: zibo.x * s,
                      top: (zibo.y - ziboLift) * s,
                      width: zibo.w * s,
                      height: zibo.h * s,
                      child: Image.asset('assets/images/home/zibo_${zibo.pose}.webp', fit: BoxFit.contain),
                    ),
                  SvgPicture.string(scene.front, fit: BoxFit.fill),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Aynı girdilerle sahneyi yeniden üretmez — eşya seçimi değişmedikçe SVG
/// metni (ve flutter_svg'nin ayrıştırma önbelleği) korunur.
class RoomSceneCache {
  String? _key;
  RoomScene? _scene;

  RoomScene get(
    HomeRoom room,
    Map<String, HomeItem> items, {
    bool care = false,
    String pose = 'happy',
    String soapColor = '#FF9FBF',
    bool dark = false,
    String? foamFill,
    String foamStroke = '#CDEBF7',
  }) {
    final key = [room.id, care, pose, soapColor, dark, foamFill, foamStroke, for (final e in items.entries) '${e.key}=${e.value.id}'].join('|');
    if (key != _key || _scene == null) {
      _key = key;
      _scene = RoomArt.build(
        room,
        (cat) => items[cat] ?? const HomeItem('yok', '', style: 'none', price: 0),
        care: care,
        pose: pose,
        soapColor: soapColor,
        dark: dark,
        foamFill: foamFill,
        foamStroke: foamStroke,
      );
    }
    return _scene!;
  }
}

/// Odanın ev kesitindeki küçük hali: taslaktaki gibi sahnenin y 120–1160
/// bandı (900×1040) gösterilir — tavanın ve zeminin ucu kırpılır.
class RoomThumb extends StatelessWidget {
  const RoomThumb({super.key, required this.scene, required this.showZibo});

  final RoomScene scene;
  final bool showZibo;

  static const double cropTop = 120;
  static const double cropHeight = 1040;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: RoomView.sceneWidth / cropHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final s = w / RoomView.sceneWidth;
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: w,
              maxWidth: w,
              minHeight: RoomView.sceneHeight * s,
              maxHeight: RoomView.sceneHeight * s,
              child: Transform.translate(
                offset: Offset(0, -cropTop * s),
                child: RoomView(scene: scene, showZibo: showZibo),
              ),
            ),
          );
        },
      ),
    );
  }
}
