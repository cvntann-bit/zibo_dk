// Taslaktaki `WALLS` / `TILES` / `FLOORS` desenleri (docs/home_studio/index.html)
// ve onlardan türeyen örtü/nevresim dolguları — docs/zibo_world_roadmap.md Faz 2.

import 'svg_kit.dart';

final Map<String, String Function(String c)> wallArt = {
  // Altın Saray (Pro): boyanın tonunda damask + altın noktalar.
  'damask': (c) =>
      '''<path d="M40 8c8 10 18 12 18 24 0 10-10 14-18 22-8-8-18-12-18-22 0-12 10-14 18-24z" fill="$c"/>'''
      '''<path d="M40 54v18M32 64h16" stroke="$c" stroke-width="4" stroke-linecap="round"/>'''
      '''<circle cx="0" cy="0" r="4" fill="#E2B64A"/><circle cx="80" cy="0" r="4" fill="#E2B64A"/><circle cx="0" cy="80" r="4" fill="#E2B64A"/><circle cx="80" cy="80" r="4" fill="#E2B64A"/>''',
  // Elmas (Pro+): elmas kafes + parıltı.
  'elmas': (c) =>
      '''<path d="M40 0L80 40L40 80L0 40z" fill="none" stroke="$c" stroke-width="3"/>'''
      '''<path d="M40 30l5 10-5 10-5-10z" fill="#FFFFFF" opacity=".85"/><path d="M0 0l3 5-3 5-3-5zM80 80l3 5-3 5-3-5z" fill="#FFFFFF" opacity=".7"/>''',
  'duz': (c) => '',
  'puan': (c) => '''<circle cx="20" cy="20" r="8" fill="$c"/><circle cx="60" cy="60" r="8" fill="$c"/>''',
  'cizgi': (c) => '''<rect x="0" y="0" width="30" height="80" fill="$c"/>''',
  'kare': (c) => '''<rect x="0" y="0" width="80" height="4" fill="$c"/><rect x="0" y="0" width="4" height="80" fill="$c"/><rect x="0" y="38" width="80" height="4" fill="$c"/><rect x="38" y="0" width="4" height="80" fill="$c"/>''',
  'yildiz': (c) => '''<path d="M40 14l7 15 16 2-12 11 3 16-14-8-14 8 3-16-12-11 16-2z" fill="$c"/>''',
  'cicek': (c) => '''<g fill="$c"><circle cx="40" cy="28" r="9"/><circle cx="52" cy="40" r="9"/><circle cx="40" cy="52" r="9"/><circle cx="28" cy="40" r="9"/></g><circle cx="40" cy="40" r="6" fill="#FFF8E1"/>''',
  'kalp': (c) => '''<path d="M40 58C20 44 14 34 18 26c4-8 16-9 22 0 6-9 18-8 22 0 4 8-2 18-22 32z" fill="$c"/>''',
  'bulut': (c) => '''<path d="M14 52a12 12 0 0 1 8-22 16 16 0 0 1 30-4 12 12 0 0 1 14 18 10 10 0 0 1-4 8z" fill="$c"/>''',
  'ay': (c) => '''<path d="M46 16a22 22 0 1 0 14 38 18 18 0 1 1-14-38z" fill="$c"/><circle cx="66" cy="20" r="3" fill="$c"/><circle cx="16" cy="66" r="2.5" fill="$c"/>''',
};

final Map<String, (int, int, String Function(String a, String b))> tileArt = {
  'karo': (60, 60, (a, l) => '''<rect width="60" height="60" fill="$a"/><rect width="60" height="3" fill="$l"/><rect width="3" height="60" fill="$l"/><rect x="8" y="8" width="16" height="5" rx="2" fill="#fff" opacity=".4"/>'''),
  'metro': (80, 40, (a, l) => '''<rect width="80" height="40" fill="$a"/><rect width="80" height="3" fill="$l"/><rect y="20" width="80" height="3" fill="$l"/><rect x="0" width="3" height="20" fill="$l"/><rect x="40" y="20" width="3" height="20" fill="$l"/>'''),
  'pul': (60, 40, (a, l) => '''<rect width="60" height="40" fill="$a"/><path d="M0 40a30 30 0 0 1 60 0M-30 20a30 30 0 0 1 60 0M30 20a30 30 0 0 1 60 0" fill="none" stroke="$l" stroke-width="3"/>'''),
  'kabarcik': (80, 80, (a, l) => '''<rect width="80" height="80" fill="$a"/><circle cx="20" cy="24" r="10" fill="none" stroke="$l" stroke-width="3"/><circle cx="58" cy="54" r="15" fill="none" stroke="$l" stroke-width="3"/><circle cx="62" cy="16" r="5" fill="$l"/>'''),
  'duz': (60, 60, (a, l) => '''<rect width="60" height="60" fill="$a"/>'''),
};

final Map<String, (int, int, String Function(String a, String b))> floorArt = {
  // Altın Saray (Pro): damarlı mermer, altın derz.
  'mermer': (160, 160, (a, b) => '''<rect width="160" height="160" fill="$a"/><path d="M0 40c30-10 50 20 80 6s50-30 80-10M20 160c10-40 40-50 70-60s50-10 70-40M0 110c20 0 30 10 50 4" fill="none" stroke="$b" stroke-width="3" opacity=".8"/><rect width="160" height="3" fill="#E2C77A"/><rect width="3" height="160" fill="#E2C77A"/>'''),
  // Elmas (Pro+): kristal karolar.
  'kristal': (120, 120, (a, b) => '''<rect width="120" height="120" fill="$a"/><path d="M0 0L60 60L0 120M120 0L60 60L120 120" fill="none" stroke="$b" stroke-width="3"/><path d="M60 60L0 0h120z" fill="#FFFFFF" opacity=".22"/><rect width="120" height="3" fill="$b"/><rect width="3" height="120" fill="$b"/><path d="M90 24l3 7 7 3-7 3-3 7-3-7-7-3 7-3z" fill="#FFFFFF" opacity=".9"/>'''),
  'ahsap': (240, 80, (a, b) => '''<rect width="240" height="80" fill="$a"/><rect y="38" width="240" height="4" fill="$b"/><rect y="78" width="240" height="4" fill="$b"/><rect x="70" width="4" height="38" fill="$b"/><rect x="180" y="42" width="4" height="38" fill="$b"/>'''),
  'karo': (120, 120, (a, b) => '''<rect width="120" height="120" fill="$a"/><rect width="120" height="5" fill="$b"/><rect width="5" height="120" fill="$b"/>'''),
  'dama': (160, 160, (a, b) => '''<rect width="160" height="160" fill="$a"/><rect width="80" height="80" fill="$b"/><rect x="80" y="80" width="80" height="80" fill="$b"/>'''),
  'balik': (80, 80, (a, b) => '''<rect width="80" height="80" fill="$a"/><path d="M0 40l40-40M40 80l40-40M0 0l40 40M40 40l40 40" stroke="$b" stroke-width="4"/>'''),
  'mozaik': (60, 60, (a, b) => '''<rect width="60" height="60" fill="$a"/><rect width="30" height="30" fill="$b"/><rect x="30" y="30" width="30" height="30" fill="$b"/><rect width="60" height="2" fill="#fff" opacity=".6"/><rect width="2" height="60" fill="#fff" opacity=".6"/><rect y="30" width="60" height="2" fill="#fff" opacity=".6"/><rect x="30" width="2" height="60" fill="#fff" opacity=".6"/>'''),
};

/// Duvar kağıdı katmanı (boyanın üstüne): boyanın biraz koyusu (gece
/// mavisinde açığı). Desensizse boş.
String wallpaperLayer(SvgKit k, String style, String wall, {num y = 0, required num height, num x = 0, num width = 900}) {
  final draw = wallArt[style];
  if (style == 'duz' || draw == null) return '';
  final x0 = _alignedStart(x, 80);
  return k.tiled(draw(SvgKit.mix(wall, wall == '#4B6C9E' ? .16 : -.1)), 80, 80, x: x0, y: y, width: width + x - x0, height: height);
}

/// Yana uzatılmış tuvalde desen 0'a hizalı kalsın: [x]'ten küçük ilk [w] katı.
num _alignedStart(num x, num w) => x >= 0 ? x : -((-x / w).ceil() * w);

/// Zemin deseni, verilen dikdörtgene döşenir.
String floorLayer(SvgKit k, String style, String a, String b, {required num y, required num height, num width = 900, num x = 0}) {
  final (w, h, draw) = floorArt[style] ?? floorArt['ahsap']!;
  final x0 = _alignedStart(x, w);
  return k.tiled(draw(a, b), w, h, x: x0, y: y, width: width + x - x0, height: height);
}

/// Fayans deseni, verilen dikdörtgene döşenir.
String tileLayer(SvgKit k, String style, String a, String l, {required num y, required num height, num width = 900, num x = 0}) {
  final (w, h, draw) = tileArt[style] ?? tileArt['duz']!;
  final x0 = _alignedStart(x, w);
  return k.tiled(draw(a, l), w, h, x: x0, y: y, width: width + x - x0, height: height);
}

String _fabric(String style, String a, String b) => '<rect width="80" height="80" fill="$a"/>${(wallArt[style] ?? wallArt['duz']!)(b)}';

/// Masa örtüsü (masanın üst kenarına oturur); 'none' = örtüsüz.
String cloth(SvgKit k, String style, String a, String b) {
  if (style == 'none') return '';
  const edge =
      'M-12 -6h304v44c-15 16-30 16-45 0-15 16-30 16-45 0-15 16-30 16-45 0-15 16-30 16-45 0-15 16-30 16-45 0-15 16-30 16-45 0-15 16-30 16-34 0z';
  return '${k.tiled(_fabric(style, a, b), 80, 80, x: -12, y: -6, width: 304, height: 62, clip: '<path d="$edge"/>')}'
      '<path d="$edge" fill="${k.grad('#FFFFFF33', '#00000018')}"/>';
}

/// Yorgan (yatağın önünde, Zibo'nun üstünde kalır).
String blanket(SvgKit k, String style, String a, String b) {
  const shape = 'M24 250h452v126a28 28 0 0 1-28 28H52a28 28 0 0 1-28-28z';
  final body = style == 'duz'
      ? '<path d="$shape" fill="$a"/>'
      : k.tiled(_fabric(style, a, b), 80, 80, x: 24, y: 250, width: 452, height: 154, clip: '<path d="$shape"/>');
  return '$body<path d="$shape" fill="${k.grad('#FFFFFF00', '#00000022')}"/>'
      '<rect x="20" y="236" width="460" height="44" rx="22" fill="${k.grad(SvgKit.mix(a, .35), SvgKit.mix(a, .1))}"/>${k.shine(40, 244, 220, 8, 4, .5)}';
}
