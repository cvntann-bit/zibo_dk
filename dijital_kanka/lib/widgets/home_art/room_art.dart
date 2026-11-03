import '../../models/home_item.dart';
import 'furniture_art.dart';
import 'surface_art.dart';
import 'svg_kit.dart';

/// Zibo'nun duracağı yer: taslaktaki `zibo(pose, x, y, h)` — 900×1200
/// birimlik sahnede sol üst köşe ve yükseklik. Genişlik `h × 0.789`, görsel
/// bu kutuya ortalanarak sığdırılır.
class ZiboSpot {
  const ZiboSpot(this.pose, this.x, this.y, this.h);

  /// 'happy' | 'pout' | 'idle' (`assets/images/home/zibo_<pose>.webp`).
  final String pose;
  final double x;
  final double y;
  final double h;

  double get w => (h * 0.789).roundToDouble();
}

/// Bir odanın çizimi: Zibo'nun ARKASINDA ([back]) ve ÖNÜNDE ([front]) kalan
/// iki SVG. Küvetin önü, yorgan, kanepe oturağı gibi parçalar [front]'ta
/// olduğu için Zibo "içinde oturuyor" görünür (docs/zibo_home_art.md).
class RoomScene {
  const RoomScene({required this.back, required this.front, required this.zibo});

  final String back;
  final String front;
  final ZiboSpot zibo;
}

/// Seçili eşyayı verir (takılı olan ya da mağazada denenen).
typedef HomePick = HomeItem Function(String category);

const _floor = 800;

/// Taslaktaki `kitchenSvg / bathSvg / bedSvg / salonSvg` fonksiyonlarının
/// Dart karşılığı (docs/zibo_world_roadmap.md Faz 2). [care] bakım
/// modudur (besleme, banyo, uyku, oyun — Faz 4); dekor modunda Zibo odanın
/// önünde mutlu durur.
class RoomArt {
  RoomArt._(this.pick) : k = SvgKit();

  final HomePick pick;
  final SvgKit k;

  static RoomScene build(
    HomeRoom room,
    HomePick pick, {
    bool care = false,
    String pose = 'happy',
    String soapColor = '#FF9FBF',
    bool dark = false,
    String? foamFill,
    String foamStroke = '#CDEBF7',
  }) {
    final art = RoomArt._(pick);
    return switch (room) {
      HomeRoom.kitchen => art._kitchen(care, pose),
      HomeRoom.bath => art._bath(care, pose, soapColor, foamFill, foamStroke),
      HomeRoom.bedroom => art._bedroom(care, pose, dark),
      HomeRoom.living => art._living(care, pose),
    };
  }

  HomeItem _it(String cat) => pick(cat);
  String _style(String cat) => _it(cat).style ?? 'none';
  String _c(String cat) => _hex(_it(cat).color);
  String _c2(String cat) => _hex(_it(cat).color2);
  static String _hex(int? argb) => argb == null ? '#FFFFFF' : SvgKit.hex(argb);

  String _art(String style, String c, [String part = '']) => (furnitureArt[style] ?? furnitureArt['none']!)(k, c, part);

  String _draw(String cat, num x, num y, [String part = '']) {
    final style = _style(cat);
    if (style == 'none') return '';
    return '<g transform="translate($x $y)">${_art(style, _c(cat), part)}</g>';
  }

  String _wrap(String body) =>
      '<svg viewBox="0 0 900 1200" xmlns="http://www.w3.org/2000/svg"><defs>${k.defs}</defs>$body</svg>';

  RoomScene _scene(String back, String front, ZiboSpot zibo) =>
      RoomScene(back: _wrap(back), front: _wrap(front), zibo: zibo);

  /// Duvar boyası + isteğe bağlı duvar kağıdı + köşeden vuran ışık.
  String _walls(String lightPath, String lightOpacity, {bool wallpaper = true}) {
    final wall = _c('boya');
    return '<rect width="900" height="$_floor" fill="${k.grad(SvgKit.mix(wall, .2), SvgKit.mix(wall, -.05))}"/>'
        '${wallpaper ? wallpaperLayer(k, _style('desen'), wall, height: _floor) : ''}'
        '<path d="$lightPath" fill="#fff" opacity="$lightOpacity"/>';
  }

  String _floorBlock(String board1, String board2, String shade, {int board = 30}) =>
      '<rect y="${_floor - board}" width="900" height="$board" fill="${k.grad(board1, board2)}"/>'
      '${floorLayer(k, _style('zemin'), _c('zemin'), _c2('zemin'), y: _floor, height: 400)}'
      '<rect y="$_floor" width="900" height="400" fill="${k.grad(shade, '#00000000')}"/>';

  String _drape() {
    final curtain = _c('perde');
    return k.grad(SvgKit.mix(curtain, .15), SvgKit.mix(curtain, -.15));
  }

  RoomScene _kitchen(bool feeding, String pose) {
    final drape = _drape();
    final fridge = _style('buzdolabi');
    final fy = fridge == 'twinFridge' ? 322 : fridge == 'miniFridge' ? 472 : 362;
    final w = _style('duvar');
    final deco = w == 'none'
        ? ''
        : w == 'wallClock'
        ? _draw('duvar', 700, 300)
        : w == 'frame'
        ? _draw('duvar', 650, 290)
        : _draw('duvar', 674, w == 'plateRack' ? 310 : 330);
    final accH = const {'potSet': 136, 'coffeeMaker': 136, 'fruitBowl': 134, 'mixer': 144}[_style('tezgah')] ?? 0;
    final tx = feeding ? 315 : 584;
    final table =
        '${k.shadow(tx + 140, 1098, 150)}${_draw('masa', tx, 782)}'
        '<g transform="translate($tx 782)">${cloth(k, _style('ortu'), _c('ortu'), _c2('ortu'))}</g>';
    final back =
        '${_walls('M560 0h340v430z', '.2')}'
        '<g transform="translate(330 96)"><rect x="-16" y="-16" width="300" height="290" rx="30" fill="${k.grad('#FFF8EA', '#E2D3B8')}"/>'
        '<rect width="268" height="258" rx="18" fill="${k.grad('#8FD6F5', '#DDF4FB')}"/><circle cx="206" cy="66" r="36" fill="#FFD64A"/>'
        '<ellipse cx="74" cy="214" rx="96" ry="38" fill="#9FDB8E"/><ellipse cx="210" cy="226" rx="86" ry="30" fill="#7CCB78"/>'
        '<rect x="128" y="0" width="12" height="258" fill="#F4E8D2"/><rect y="118" width="268" height="12" fill="#F4E8D2"/>'
        '<path d="M-30 -24h110c-8 90-22 176-74 244h-36z" fill="$drape"/><path d="M298 -24h-110c8 90 22 176 74 244h36z" fill="$drape"/>'
        '<rect x="-44" y="-34" width="356" height="20" rx="10" fill="${k.grad('#D49A5C', '#A56F3B')}"/></g>'
        '$deco'
        '${_floorBlock('#FFF8EA', '#E2D3B8', '#00000022')}'
        '${k.shadow(160, 842, 140)}${_draw('buzdolabi', 40, fy)}${k.shadow(380, 842, 110)}${_draw('dolap', 284, 532)}'
        '${accH > 0 ? _draw('tezgah', 300, 540 - accH) : ''}${k.shadow(590, 842, 130)}${_draw('ocak', 490, 532)}'
        '${_draw('sarkit', feeding ? 365 : 634, 0)}'
        '${feeding ? '' : '${k.shadow(760, 1098, 150)}${_draw('sandalye', 700, 790)}$table${k.softEllipse(310, 1110, 170, 24, .3)}'}';
    final front = feeding
        ? '$table<ellipse cx="${tx + 140}" cy="792" rx="86" ry="18" fill="#FFFFFF" stroke="#D5DEE3" stroke-width="4"/>'
              '<ellipse cx="${tx + 140}" cy="790" rx="58" ry="10" fill="#EEF3F6"/>'
        : '';
    return _scene(back, front, feeding ? ZiboSpot(pose, 250, 420, 520) : ZiboSpot(pose, 104, 620, 500));
  }

  /// Gökkuşağı sabunun köpük renkleri.
  static const rainbow = ['#FFB3BA', '#FFDFBA', '#FFFFBA', '#BAFFC9', '#BAE1FF', '#E2C6FF'];

  RoomScene _bath(bool caring, String pose, String soapColor, String? foamFill, String foamStroke) {
    final dusC = _c('dus');
    final head = k.grad(SvgKit.mix(dusC, .45), SvgKit.mix(dusC, -.25));
    final toy = _style('oyuncak');
    final duck = toy == 'none' ? '' : _draw('oyuncak', 418, toy == 'toyBoat' ? 528 : 538);
    final plantStyle = _style('bitki');
    final plant = plantStyle == 'none' ? '' : '<g transform="translate(18 900) scale(.8)">${_art(plantStyle, _c('bitki'))}</g>';
    final dw = _style('duvar');
    final wallDeco = dw == 'none'
        ? ''
        : dw == 'lights'
        ? _draw('duvar', 10, 18)
        : '<g transform="translate(${dw == 'frame' ? 420 : 450} 96) scale(${dw == 'frame' ? .62 : .7})">${_art(dw, _c('duvar'))}</g>';
    final soapStyle = _style('sabun');
    final soap = soapStyle == 'none' ? '' : '<g transform="translate(765 528) scale(.62)">${_art(soapStyle, soapColor)}</g>';
    final tub = _draw('kuvet', 40, 590);
    final back =
        '${_walls('M600 0h300v380z', '.2', wallpaper: false)}'
        '${tileLayer(k, _style('fayans'), _c('fayans'), _c2('fayans'), y: 430, height: _floor - 430)}'
        '<rect y="420" width="900" height="18" rx="6" fill="${k.grad('#FFFFFF', '#D5DEE3')}"/>'
        '<g transform="translate(690 150)"><circle r="82" fill="${k.grad('#FFFFFF', '#CBD5DC')}"/><circle r="64" fill="${k.grad('#8FD6F5', '#E2F6FC')}"/>'
        '<circle cx="-18" cy="-14" r="16" fill="#fff" opacity=".7"/><circle cx="22" cy="20" r="9" fill="#fff" opacity=".6"/>'
        '<rect x="-64" y="-4" width="128" height="8" fill="#F1F4F6"/></g>'
        '<g><rect x="150" y="0" width="16" height="250" fill="${k.chrome()}"/>'
        '<path d="M110 250h96l-14 34h-68z" fill="$head" stroke="${SvgKit.mix(dusC, -.35)}" stroke-width="2"/>'
        '${[126, 146, 166, 186].map((x) => '<circle cx="$x" cy="292" r="4" fill="#7D8590"/>').join()}</g>'
        '${_draw('havlu', 300, 250)}${_draw('raf', 240, 470)}$wallDeco${_draw('ayna', 640, 240)}'
        '${_floorBlock('#FFFFFF', '#D5DEE3', '#00000020', board: 26)}'
        '${k.shadow(270, 842, 230)}${k.shadow(720, 842, 90)}${_draw('lavabo', 620, 540)}$soap'
        '${_draw('paspas', 410, 1052)}$plant'
        '${caring ? '' : '$tub$duck${k.softEllipse(610, 1112, 150, 20, .28)}'}';
    // Küvetin kenarında köpük (bakımda, yıkanırken). foamFill 'rainbow' = gökkuşağı.
    final foamTop = caring && foamFill != null
        ? List.generate(
            11,
            (i) =>
                '<circle cx="${70 + i * 40}" cy="${592 - (i % 2) * 10}" r="${26 + (i % 3) * 6}" '
                'fill="${foamFill == 'rainbow' ? rainbow[i % 6] : foamFill}" stroke="$foamStroke" stroke-width="3"/>',
          ).join()
        : '';
    return _scene(back, caring ? '$tub$foamTop$duck' : '', caring ? ZiboSpot(pose, 120, 330, 430) : ZiboSpot(pose, 450, 640, 470));
  }

  RoomScene _bedroom(bool caring, String pose, bool dark) {
    k.addDef(
      '<radialGradient id="glow"><stop offset="0" stop-color="#FFE9A0" stop-opacity=".6"/>'
      '<stop offset="1" stop-color="#FFE9A0" stop-opacity="0"/></radialGradient>',
    );
    final sky = dark
        ? '<rect width="240" height="250" rx="18" fill="${k.grad('#1B2A5C', '#3B4F8C')}"/>'
              '<path d="M190 40a30 30 0 1 0 22 52 24 24 0 1 1-22-52z" fill="#FFE9A0"/>'
              '${const [(40, 50), (90, 30), (140, 80), (60, 140), (170, 160), (110, 196)].map((e) => '<circle cx="${e.$1}" cy="${e.$2}" r="3.5" fill="#fff"/>').join()}'
        : '<rect width="240" height="250" rx="18" fill="${k.grad('#8FD6F5', '#DDF4FB')}"/><circle cx="180" cy="60" r="30" fill="#FFD64A"/>'
              '<ellipse cx="70" cy="214" rx="90" ry="34" fill="#9FDB8E"/>';
    final drape = _drape();
    final win =
        '<g transform="translate(520 110)"><rect x="-16" y="-16" width="272" height="282" rx="28" fill="${k.grad('#FFF8EA', '#E2D3B8')}"/>$sky'
        '<rect x="114" width="12" height="250" fill="#F4E8D2"/><rect y="118" width="240" height="12" fill="#F4E8D2"/>'
        '<path d="M-30 -24h100c-8 90-22 176-70 250h-30z" fill="$drape"/><path d="M270 -24h-100c8 90 22 176 70 250h30z" fill="$drape"/>'
        '<rect x="-44" y="-34" width="328" height="20" rx="10" fill="${k.grad('#D49A5C', '#A56F3B')}"/></g>';
    final s = _style('sus');
    final sus = s == 'lights'
        ? _draw('sus', 10, 18)
        : s == 'frame'
        ? _draw('sus', 150, 150)
        : s == 'bookShelf'
        ? _draw('sus', 140, 200)
        : '';
    final toyKind = _style('oyuncak');
    final toy = toyKind == 'none'
        ? ''
        : '<g transform="translate(40 ${toyKind == 'ball' ? 1010 : 960}) scale(.9)">${_art(toyKind, _c('oyuncak'))}</g>';
    final quilt = '<g transform="translate(20 400)">${blanket(k, _style('nevresim'), _c('nevresim'), _c2('nevresim'))}</g>';
    final night = dark ? '<rect width="900" height="1200" fill="#0B1435" opacity=".56"/><circle cx="577" cy="530" r="190" fill="url(#glow)"/>' : '';
    final back =
        '${_walls('M600 0h300v380z', '.18')}$win$sus'
        '${_floorBlock('#FFF8EA', '#E2D3B8', '#00000022')}'
        '${_draw('hali', 240, 1000)}'
        '${k.shadow(765, 846, 110)}${_draw('dolap', 660, 396)}${k.shadow(577, 836, 70)}${_draw('komodin', 512, 652)}${_draw('abajur', 502, 478)}'
        '${k.shadow(270, 840, 240)}${_draw('yatak', 20, 400)}'
        '${caring ? '' : '$quilt${k.softEllipse(600, 1112, 150, 20, .28)}'}';
    return _scene(
      back,
      '${caring ? quilt : ''}$toy$night',
      caring ? ZiboSpot(pose, 150, 410, 380) : ZiboSpot(pose, 420, 650, 460),
    );
  }

  RoomScene _living(bool caring, String pose) {
    final drape = _drape();
    final win =
        '<g transform="translate(600 100)"><rect x="-16" y="-16" width="262" height="262" rx="28" fill="${k.grad('#FFF8EA', '#E2D3B8')}"/>'
        '<rect width="230" height="230" rx="18" fill="${k.grad('#8FD6F5', '#DDF4FB')}"/><circle cx="170" cy="56" r="28" fill="#FFD64A"/>'
        '<ellipse cx="70" cy="200" rx="90" ry="34" fill="#9FDB8E"/><rect x="109" width="12" height="230" fill="#F4E8D2"/>'
        '<rect y="109" width="230" height="12" fill="#F4E8D2"/><path d="M-30 -24h90c-8 80-20 160-64 232h-26z" fill="$drape"/>'
        '<path d="M260 -24h-90c8 80 20 160 64 232h26z" fill="$drape"/>'
        '<rect x="-44" y="-34" width="318" height="20" rx="10" fill="${k.grad('#D49A5C', '#A56F3B')}"/></g>';
    final w = _style('duvar');
    final deco = w == 'lights'
        ? _draw('duvar', 10, 18)
        : w == 'frame'
        ? _draw('duvar', 180, 200)
        : w == 'wallClock'
        ? _draw('duvar', 220, 200)
        : w == 'bookShelf'
        ? _draw('duvar', 170, 260)
        : '';
    final tvStyle = _style('tv');
    final ty = 664 - (const {'tvRetro': 202, 'tvFlat': 194, 'tvBig': 202}[tvStyle] ?? 194);
    final tx = tvStyle == 'tvBig' ? 584 : 610;
    final (sx, sy, sw, sh, sr) = tvScreens[tvStyle] ?? tvScreens['tvFlat']!;
    final screen = '<rect x="${tx + sx}" y="${ty + sy}" width="$sw" height="$sh" rx="$sr" fill="#fff" opacity=".08"/>';
    final corner = _style('kose');
    final puf = _style('puf');
    final back =
        '${_walls('M560 0h340v400z', '.16')}$win$deco'
        '${_floorBlock('#FFF8EA', '#E2D3B8', '#00000022')}'
        '${_draw('hali', 230, 960)}${_draw('lambader', 6, 320)}'
        '${k.shadow(730, 846, 140)}${_draw('unite', 600, 664)}${_draw('tv', tx, ty)}$screen'
        '${k.shadow(300, 846, 250)}${_draw('kanepe', 70, 520, 'back')}';
    final front =
        '${_draw('kanepe', 70, 520, 'front')}'
        '${corner == 'none' ? '' : _draw('kose', 700, corner == 'aquarium' ? 880 : 860)}'
        '${k.shadow(380, 1060, 150)}${_draw('sehpa', 230, 940)}'
        '${puf == 'none' ? '' : _draw('puf', 560, puf == 'beanbag' ? 1010 : 1020)}';
    return _scene(back, front, ZiboSpot(pose, 190, 404, 400));
  }
}

/// TV ekranının çerçeve içindeki yeri (x, y, genişlik, yükseklik, köşe) —
/// salon bakımında oyun görüntüsü buraya oturur (Faz 4).
const Map<String, (int, int, int, int, int)> tvScreens = {
  'tvRetro': (22, 56, 150, 120, 28),
  'tvFlat': (10, 10, 230, 136, 10),
  'tvBig': (-10, 10, 310, 156, 10),
};
