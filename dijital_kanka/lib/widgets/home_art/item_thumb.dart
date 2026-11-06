import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/costume_rarity.dart';
import '../../models/home_item.dart';
import 'furniture_art.dart';
import 'surface_art.dart';
import 'svg_kit.dart';
import 'luxe_art.dart';

/// Dekor mağazasında eşyanın küçük resmi — taslaktaki `thumb()` ve
/// `tileSvg()` (docs/home_studio/index.html, docs/zibo_world_roadmap.md Faz 5).
class HomeItemThumb extends StatelessWidget {
  const HomeItemThumb({super.key, required this.kind, required this.item, this.size = 64});

  final HomeCategoryKind kind;
  final HomeItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kind == HomeCategoryKind.swatch) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Color(item.color ?? 0xFFFFE7B0), borderRadius: BorderRadius.circular(12)),
      );
    }
    if (kind == HomeCategoryKind.furniture && item.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFFF4DE), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.block_rounded, color: Color(0xFFB8A58A)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SvgPicture.string(_svg(), width: size, height: size, fit: BoxFit.contain),
    );
  }

  String _svg() {
    final k = SvgKit();
    final c = item.color == null ? '#FFFFFF' : SvgKit.hex(item.color!);
    final c2 = item.color2 == null ? '#FFFFFF' : SvgKit.hex(item.color2!);
    final style = item.style ?? 'duz';
    String body;
    var viewBox = '0 0 160 160';
    switch (kind) {
      case HomeCategoryKind.wallpaper:
        const base = '#FFE7B0';
        body = '<rect width="160" height="160" fill="$base"/>'
            '${style == 'duz' ? '' : k.tiled((wallArt[style] ?? wallArt['duz']!)(SvgKit.mix(base, -.14)), 80, 80, x: 0, y: 0, width: 160, height: 160)}';
      case HomeCategoryKind.floor:
        body = floorLayer(k, style, c, c2, y: 0, height: 160, width: 160);
      case HomeCategoryKind.tile:
        body = tileLayer(k, style, c, c2, y: 0, height: 160, width: 160);
      case HomeCategoryKind.blanket || HomeCategoryKind.cloth:
        if (style == 'none') {
          body = '<rect width="160" height="160" fill="#FFF4DE"/>';
        } else if (style == 'duz') {
          body = '<rect width="160" height="160" fill="$c"/>';
        } else {
          body = k.tiled(
            '<rect width="80" height="80" fill="$c"/>${(wallArt[style] ?? wallArt['duz']!)(c2)}',
            80,
            80,
            x: 0,
            y: 0,
            width: 160,
            height: 160,
          );
        }
      case HomeCategoryKind.furniture || HomeCategoryKind.swatch:
        viewBox = furnitureViewBox[style] ?? luxeViewBox[style] ?? '-10 -10 220 220';
        body = (furnitureArt[style] ?? furnitureArt['none']!)(k, c, '');
        // Yataklar taslaktaki gibi düz mavi yorganla gösterilir.
        if (style.startsWith('bed')) body += blanket(k, 'duz', '#8ED0F2', '#8ED0F2');
    }
    return '<svg viewBox="$viewBox" xmlns="http://www.w3.org/2000/svg"><defs>${k.defs}</defs>$body</svg>';
  }
}

/// Fiyattan nadirlik (kostümlerle aynı renk dili, `RarityStyle`). Başlangıç
/// (ücretsiz) eşyaların kademesi yok.
CostumeRarity? homeItemRarity(int price) {
  if (price <= 0) return null;
  if (price <= 100) return CostumeRarity.common;
  if (price <= 250) return CostumeRarity.rare;
  if (price <= 500) return CostumeRarity.epic;
  if (price <= 1000) return CostumeRarity.legendary;
  return CostumeRarity.mythic;
}

/// Taslaktaki `VB` — her çizimin küçük resimde kadrajı.
const furnitureViewBox = <String, String>{
  'retroFridge': '-20 -10 280 500', 'twinFridge': '-20 -10 300 540', 'miniFridge': '-30 -20 250 400',
  'stove': '-20 -10 290 320', 'counter': '-20 -10 240 320', 'table': '-10 -10 300 340', 'chair': '-10 -10 200 330',
  'clawTub': '-10 -20 480 290', 'boxTub': '-10 -20 480 290', 'roundTub': '-10 -20 480 290', 'sink': '-20 -50 240 360',
  'mirrorOval': '-10 -10 200 240', 'mirrorRect': '-10 -10 200 240', 'mirrorArch': '-10 -10 200 240', 'towel': '-20 -20 230 230',
  'bedClassic': '0 -10 500 450', 'bedCloud': '0 -10 500 450', 'bedCanopy': '-10 -270 520 710', 'nightstand': '-10 -20 150 200',
  'lampCone': '0 -10 150 190', 'lampMushroom': '0 -10 150 190', 'lampMoon': '0 -10 150 190', 'lampStar': '0 -10 150 190',
  'wardrobe': '-10 -20 230 470', 'rugOval': '-10 -40 440 190', 'rugRound': '-10 -40 440 190', 'rugStar': '-10 -40 440 190',
  'teddy': '-10 -10 160 220', 'ball': '-10 -10 160 160', 'rocket': '-20 -10 160 190', 'lights': '0 0 880 90',
  'frame': '-10 -10 260 200', 'bookShelf': '0 -10 270 150', 'sofaClassic': '-10 -10 490 330', 'sofaRound': '-10 -10 490 330',
  'sofaTufted': '-20 -10 510 330', 'tvRetro': '-10 -10 260 220', 'tvFlat': '-10 -10 270 210', 'tvBig': '-30 -10 350 220',
  'tvStand': '-10 -10 280 200', 'floorLampCone': '-20 -10 180 540', 'floorLampGlobe': '-20 -10 180 540',
  'floorLampArc': '-20 -10 300 540', 'coffeeRound': '-10 -10 320 150', 'coffeeRect': '-10 -10 320 150',
  'coffeeGlass': '-10 -10 320 150', 'monstera': '0 0 220 320', 'cactusPot': '0 0 200 320', 'aquarium': '-10 30 220 290',
  'wallClock': '-10 -10 180 180', 'pouf': '-10 0 200 150', 'beanbag': '-10 0 230 170',
  'tableSquare': '-10 -10 300 340', 'stool': '-10 120 200 200', 'pendantDome': '0 60 180 170', 'pendantGlobe': '0 60 180 200',
  'pendantCage': '0 60 180 200', 'jarShelf': '-10 0 216 120', 'plateRack': '-10 20 220 120', 'potSet': '-10 -10 190 150',
  'coffeeMaker': '-10 -10 160 160', 'fruitBowl': '-10 10 180 140', 'mixer': '-10 -10 150 160',
  'sinkCabinet': '-20 -50 240 360', 'shampooShelf': '-10 -10 190 90', 'towelBasket': '-10 -30 190 110',
  'plantShelf': '-10 -10 190 90', 'bathMatOval': '-10 -10 420 120', 'bathMatRect': '0 0 400 120', 'bathMatCloud': '0 0 420 120',
  'duck': '-10 -10 110 80', 'toyBoat': '-10 -20 120 100',
  'soapBar': '-6 0 102 60', 'soapHeart': '-6 -4 102 64', 'soapStar': '-6 -4 102 64', 'soapCloud': '-6 0 102 60',
  'soapDuck': '-6 -6 102 76',
  'xmasTree': '0 -4 200 328', 'snowman': '0 -16 200 336', 'giftBoxes': '0 10 200 154',
};
