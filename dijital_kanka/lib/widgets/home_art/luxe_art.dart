// Abonelere özel dekor serileri (2026-11-06, docs/subscribe_model.md
// "Zibo Dünyası avantajları"): **Altın Saray** (Zibo Pro — krem, bordo
// kadife, altın süs, taç) ve **Elmas** (Zibo Pro+ — buz mavisi kristal,
// gökkuşağı yansıması, elmas). Ölçüler aynı kategorideki mevcut çizimlerle
// birebir (buzdolabı 240×470, küvet 460×240, yatak `bedBase`, kanepe
// back/front …) ki odadaki yerleşim değişmesin. Taslak sayfada YOK, yalnız
// burada çizilir (katalog: tool/generate_home_catalog.py `PRO_ITEMS`).
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'furniture_art.dart';
import 'svg_kit.dart';

String _gold(SvgKit k, [bool h = false]) => k.grad('#FFEDAE', '#C38A22', h);
const _goldLine = '#A8741E';

/// Gökkuşağı yansımalı kristal dolgu (köşegen).
String _iri(SvgKit k) => k.gradStops(const ['#FFE3F4', '#DCD3FF', '#C9F1FF', '#D4FFEE'], diagonal: true);

/// Dört köşeli parıltı.
String _spark(num x, num y, num s, [num o = .95]) =>
    '<path d="M$x ${y - s}Q$x $y ${x + s} ${y}Q$x $y $x ${y + s}Q$x $y ${x - s} ${y}Q$x $y $x ${y - s}z" fill="#FFFFFF" opacity="$o"/>';

/// 60×44 taç; (x, y) sol üst.
String _crown(SvgKit k, num x, num y, [num s = 1]) =>
    '<g transform="translate($x $y) scale($s)"><path d="M0 44L4 8l14 18L30 0l12 26L56 8l4 36z" fill="${_gold(k)}" stroke="$_goldLine" stroke-width="2.5" stroke-linejoin="round"/>'
    '<circle cx="30" cy="31" r="5" fill="#E2364B"/><circle cx="14" cy="35" r="3.5" fill="#3E7BE0"/><circle cx="46" cy="35" r="3.5" fill="#3E7BE0"/>'
    '<circle cx="4" cy="8" r="3.5" fill="#FFF3C4"/><circle cx="30" cy="1" r="4" fill="#FFF3C4"/><circle cx="56" cy="8" r="3.5" fill="#FFF3C4"/></g>';

/// 60×52 elmas; (cx, y) üst orta.
String _diamond(SvgKit k, num cx, num y, [num s = 1]) =>
    '<g transform="translate($cx $y) scale($s)"><path d="M-30 14L-16 0h32l14 14L0 52z" fill="${_iri(k)}" stroke="#7FB6D6" stroke-width="2.5" stroke-linejoin="round"/>'
    '<path d="M-30 14h60M-16 0l6 14L0 52M16 0l-6 14L0 52" fill="none" stroke="#FFFFFF" stroke-width="2" opacity=".9"/></g>';

/// Mum (fincan + mum + alev); (x, y) fincanın alt ortası.
String _candle(SvgKit k, num x, num y) =>
    '<circle cx="$x" cy="${y - 44}" r="11" fill="#FFE27A" opacity=".4"/>'
    '<rect x="${x - 8}" y="${y - 9}" width="16" height="10" rx="4" fill="${_gold(k)}"/><rect x="${x - 5}" y="${y - 37}" width="10" height="29" rx="3" fill="#FFF8EC"/>'
    '<path d="M$x ${y - 54}c6 8 7 14 0 17-7-3-6-9 0-17z" fill="#FFB238"/>';

/// Kristal damla; (x, y) üst.
String _drop(SvgKit k, num x, num y, [num s = 1]) =>
    '<path d="M$x ${y}l${7 * s} ${12 * s}-${7 * s} ${12 * s}-${7 * s}-${12 * s}z" fill="${_iri(k)}" stroke="#9CCBE2" stroke-width="1.5"/>';

final Map<String, FurnitureArt> luxeArt = {
  // --- Altın Saray (Pro) ---------------------------------------------------
  'royalFridge': (k, c, p) {
    final g = _gold(k);
    return '<rect x="38" y="462" width="26" height="20" rx="8" fill="$g"/><rect x="176" y="462" width="26" height="20" rx="8" fill="$g"/>'
        '<rect width="240" height="470" rx="60" fill="${k.grad(m(c, .3), m(c, -.12), true)}"/>'
        '<rect x="12" y="12" width="216" height="446" rx="50" fill="none" stroke="$g" stroke-width="7"/>'
        '<rect x="12" y="166" width="216" height="9" fill="$g"/>'
        '<rect x="188" y="74" width="16" height="68" rx="8" fill="$g"/><rect x="188" y="204" width="16" height="120" rx="8" fill="$g"/>'
        '${_crown(k, 90, 62)}'
        '<path d="M110 250l24 34-24 34-24-34z" fill="$g" stroke="$_goldLine" stroke-width="2"/><circle cx="110" cy="284" r="7" fill="#E2364B"/>'
        '${k.shine(30, 40, 16, 380, 8, .35)}';
  },
  'chandelierGold': (k, c, p) {
    final g = _gold(k);
    return '<circle cx="90" cy="160" r="96" fill="#FFE9A0" opacity=".2"/>'
        '<rect x="88" y="0" width="4" height="118" fill="#5E5043"/><circle cx="90" cy="120" r="9" fill="$g"/>'
        '<path d="M90 120v60" stroke="$g" stroke-width="9" stroke-linecap="round"/>'
        '<path d="M10 150q80 60 160 0" fill="none" stroke="$g" stroke-width="9" stroke-linecap="round"/>'
        '${[(10, 150), (50, 172), (90, 180), (130, 172), (170, 150)].map((e) => _candle(k, e.$1, e.$2)).join()}'
        '<ellipse cx="90" cy="186" rx="24" ry="11" fill="$g"/><path d="M90 194l9 15-9 13-9-13z" fill="#FFF8E0" stroke="#E5C77A" stroke-width="2"/>'
        '<path d="M30 164l5 9-5 8-5-8zM150 164l5 9-5 8-5-8z" fill="#FFF8E0" stroke="#E5C77A" stroke-width="2"/>';
  },
  'royalTub': (k, c, p) {
    final g = _gold(k);
    return '<path d="M60 222c-12 22-26 26-34 20 10-4 16-14 18-26z" fill="$g"/><path d="M400 222c12 22 26 26 34 20-10-4-16-14-18-26z" fill="$g"/>'
        '<path d="M14 34h432c0 110-40 196-120 200H134C54 230 14 144 14 34z" fill="${k.grad(m(c, .3), m(c, -.12), true)}"/>'
        '<path d="M50 104q90 44 180 0q90 44 180 0" fill="none" stroke="$g" stroke-width="7" stroke-linecap="round"/>'
        '${_crown(k, 200, 140)}'
        '<rect x="0" y="0" width="460" height="46" rx="23" fill="${_gold(k)}"/>${k.shine(18, 8, 260, 9, 4, .55)}${k.shine(40, 64, 22, 110, 11, .35)}';
  },
  'mirrorCrown': (k, c, p) {
    return '<ellipse cx="90" cy="122" rx="90" ry="102" fill="${_gold(k)}"/><ellipse cx="90" cy="122" rx="74" ry="86" fill="none" stroke="$_goldLine" stroke-width="2"/>'
        '<ellipse cx="90" cy="122" rx="68" ry="80" fill="${k.grad('#E9F8FF', '#9FD3EA')}"/>'
        '<path d="M44 92l40-36 10 10-40 36z" fill="#FFFFFF" opacity=".6"/>'
        '${_crown(k, 60, -16)}<circle cx="90" cy="218" r="8" fill="#E2364B" stroke="$_goldLine" stroke-width="2"/>';
  },
  'bedRoyal': (k, c, p) {
    final g = _gold(k);
    return bedBase(
      k,
      '<rect x="18" y="40" width="22" height="230" rx="11" fill="$g"/><rect x="460" y="40" width="22" height="230" rx="11" fill="$g"/>'
      '<path d="M30 250V90Q30 40 80 40h100Q250 -30 320 40h100q50 0 50 50v160z" fill="${k.grad(m(c, .16), m(c, -.2), true)}" stroke="$g" stroke-width="8"/>'
      '${[90, 140, 190].expand((y) => [96, 158, 220, 282, 344, 406].map((x) => '<circle cx="$x" cy="$y" r="6" fill="${m(c, -.32)}"/>')).join()}'
      '${_crown(k, 220, -40)}<circle cx="29" cy="40" r="12" fill="$g"/><circle cx="471" cy="40" r="12" fill="$g"/>',
      c,
    );
  },
  'wardrobeRoyal': (k, c, p) {
    final g = _gold(k);
    return '<rect x="16" y="420" width="26" height="22" rx="8" fill="$g"/><rect x="168" y="420" width="26" height="22" rx="8" fill="$g"/>'
        '<rect width="210" height="430" rx="30" fill="${k.grad(m(c, .26), m(c, -.12), true)}"/>'
        '<rect x="-10" y="-16" width="230" height="30" rx="14" fill="$g"/>${_crown(k, 75, -58)}'
        '<rect x="16" y="28" width="84" height="366" rx="20" fill="${m(c, .12)}" stroke="$g" stroke-width="5"/>'
        '<rect x="110" y="28" width="84" height="366" rx="20" fill="${m(c, .12)}" stroke="$g" stroke-width="5"/>'
        '<path d="M58 92l14 20-14 20-14-20zM152 92l14 20-14 20-14-20z" fill="$g"/>'
        '<circle cx="90" cy="220" r="7" fill="$g"/><circle cx="120" cy="220" r="7" fill="$g"/>${k.shine(28, 40, 12, 300, 6, .3)}';
  },
  'sofaThrone': (k, c, p) {
    final g = _gold(k);
    final back = '<path d="M24 200V50Q24 10 70 10h90Q235 -50 310 10h90q46 0 46 40v150z" fill="${k.grad(m(c, .18), m(c, -.18), true)}" stroke="$g" stroke-width="8"/>'
        '${[60, 110, 160].expand((y) => [84, 146, 208, 270, 332, 394].map((x) => '<circle cx="$x" cy="$y" r="6" fill="${m(c, -.32)}"/>')).join()}'
        '${_crown(k, 205, -62)}';
    final front = '<rect x="64" y="286" width="24" height="26" rx="8" fill="$g"/><rect x="382" y="286" width="24" height="26" rx="8" fill="$g"/>'
        '<rect x="40" y="186" width="390" height="104" rx="30" fill="${k.grad(m(c, .16), m(c, -.22))}"/><rect x="60" y="182" width="350" height="22" rx="11" fill="${m(c, .26)}"/>'
        '<rect x="40" y="274" width="390" height="9" rx="4" fill="$g"/>'
        '<rect x="0" y="96" width="78" height="196" rx="34" fill="${k.grad(m(c, .22), m(c, -.16), true)}"/><rect x="392" y="96" width="78" height="196" rx="34" fill="${k.grad(m(c, .22), m(c, -.16), true)}"/>'
        '<circle cx="39" cy="122" r="22" fill="none" stroke="$g" stroke-width="7"/><circle cx="431" cy="122" r="22" fill="none" stroke="$g" stroke-width="7"/>';
    return p == 'back' ? back : p == 'front' ? front : back + front;
  },
  'floorCandelabra': (k, c, p) {
    final g = _gold(k);
    return '<ellipse cx="70" cy="512" rx="54" ry="12" fill="$g"/><path d="M28 512q42-64 84 0z" fill="$g"/>'
        '<rect x="64" y="110" width="12" height="380" rx="6" fill="${_gold(k, true)}"/>'
        '<ellipse cx="70" cy="220" rx="13" ry="8" fill="$g"/><ellipse cx="70" cy="360" rx="13" ry="8" fill="$g"/>'
        '<path d="M70 132q-60 2-56-48M70 132q60 2 56-48" fill="none" stroke="$g" stroke-width="8" stroke-linecap="round"/>'
        '${_candle(k, 14, 88)}${_candle(k, 126, 88)}${_candle(k, 70, 112)}';
  },

  // --- Elmas (Pro+) --------------------------------------------------------
  'crystalFridge': (k, c, p) {
    return '<rect x="38" y="462" width="26" height="20" rx="8" fill="${k.chrome()}"/><rect x="176" y="462" width="26" height="20" rx="8" fill="${k.chrome()}"/>'
        '<rect width="240" height="470" rx="60" fill="${k.grad('#F7FDFF', m(c, -.1), true)}"/>'
        '<rect width="240" height="470" rx="60" fill="${_iri(k)}" opacity=".5"/>'
        '<path d="M22 70L110 24L66 160z" fill="#FFFFFF" opacity=".35"/><path d="M150 250L222 222L212 384z" fill="#FFFFFF" opacity=".28"/><path d="M28 330L92 300L72 440z" fill="#FFFFFF" opacity=".22"/>'
        '<rect x="12" y="166" width="216" height="8" fill="${k.chrome()}"/>'
        '<rect x="188" y="74" width="16" height="68" rx="8" fill="${k.chrome()}"/><rect x="188" y="204" width="16" height="120" rx="8" fill="${k.chrome()}"/>'
        '${_diamond(k, 120, 56)}${_spark(60, 220, 12)}${_spark(170, 420, 9)}${_spark(200, 40, 8)}';
  },
  'chandelierCrystal': (k, c, p) {
    const strands = [(26, 18), (46, 30), (68, 40), (90, 52), (112, 40), (134, 30), (154, 18)];
    return '<circle cx="90" cy="160" r="96" fill="#DDF6FF" opacity=".3"/>'
        '<rect x="88" y="0" width="4" height="112" fill="#5E5043"/><ellipse cx="90" cy="116" rx="26" ry="8" fill="${k.chrome()}"/>'
        '<ellipse cx="90" cy="134" rx="46" ry="9" fill="none" stroke="${k.chrome()}" stroke-width="5"/>'
        '<path d="M90 116L44 134M90 116L136 134M90 116v40" stroke="#B9C3CF" stroke-width="3"/>'
        '<ellipse cx="90" cy="156" rx="70" ry="12" fill="none" stroke="${k.chrome()}" stroke-width="6"/>'
        '${strands.map((e) => '<path d="M${e.$1} 160v${e.$2}" stroke="#C9D4DE" stroke-width="2"/>${_drop(k, e.$1, 160 + e.$2)}').join()}'
        '${_drop(k, 90, 214, 1.5)}${_spark(40, 130, 9)}${_spark(146, 120, 7)}${_spark(118, 200, 6)}';
  },
  'crystalTub': (k, c, p) {
    return '<ellipse cx="230" cy="250" rx="120" ry="12" fill="#9FC9DD"/>'
        '<path d="M20 30h420c10 120-70 210-210 210S10 150 20 30z" fill="${_iri(k)}"/>'
        '<path d="M20 30h420c10 120-70 210-210 210S10 150 20 30z" fill="${k.grad('#FFFFFF99', '#FFFFFF00')}"/>'
        '<path d="M230 232L62 52M230 232L130 46M230 232V46M230 232L330 46M230 232L398 52" stroke="#FFFFFF" stroke-width="4" opacity=".6"/>'
        '<rect x="0" y="0" width="460" height="46" rx="23" fill="${k.grad('#FFFFFF', '#BFE6F5')}"/>'
        '${List.generate(11, (i) => '<circle cx="${40 + i * 38}" cy="23" r="7" fill="${k.grad('#FFFFFF', '#E3D7F0')}"/>').join()}'
        '${_diamond(k, 230, 120, 1.1)}${_spark(90, 120, 12)}${_spark(380, 100, 10)}';
  },
  'mirrorDiamond': (k, c, p) {
    return '<path d="M90 0L180 110L90 220L0 110z" fill="${_iri(k)}" stroke="#8CC4E0" stroke-width="3" stroke-linejoin="round"/>'
        '<path d="M90 22L160 110L90 198L20 110z" fill="${k.grad('#F1FBFF', '#A9DCF0')}"/>'
        '<path d="M58 96l30-38 9 8-30 38z" fill="#FFFFFF" opacity=".7"/>${_spark(90, 0, 14)}${_spark(176, 110, 10)}${_spark(6, 112, 9)}';
  },
  'bedCrystal': (k, c, p) {
    return bedBase(
      k,
      '<path d="M30 250V110a80 80 0 0 1 80-80h280a80 80 0 0 1 80 80v140z" fill="${_iri(k)}" stroke="#8CC4E0" stroke-width="4"/>'
      '<path d="M60 90L150 50L110 200zM330 60L430 110L380 220z" fill="#FFFFFF" opacity=".3"/>'
      '${_diamond(k, 250, -30, 1.4)}${_spark(100, 70, 12)}${_spark(410, 170, 10)}${_spark(200, 160, 8)}',
      c,
    );
  },
  'wardrobeCrystal': (k, c, p) {
    return '<rect x="16" y="420" width="26" height="22" rx="8" fill="${k.chrome()}"/><rect x="168" y="420" width="26" height="22" rx="8" fill="${k.chrome()}"/>'
        '<rect width="210" height="430" rx="30" fill="${k.grad('#F7FDFF', m(c, -.08), true)}"/>'
        '<rect x="-10" y="-16" width="230" height="30" rx="14" fill="${k.grad('#FFFFFF', '#BFE6F5')}"/>${_diamond(k, 105, -62)}'
        '<rect x="16" y="28" width="84" height="366" rx="20" fill="${_iri(k)}"/><rect x="110" y="28" width="84" height="366" rx="20" fill="${_iri(k)}"/>'
        '<path d="M28 60l44-24 6 10-44 24zM122 60l44-24 6 10-44 24z" fill="#FFFFFF" opacity=".6"/>'
        '${_diamond(k, 90, 208, .3)}${_diamond(k, 120, 208, .3)}${_spark(60, 330, 10)}${_spark(160, 140, 8)}';
  },
  'sofaCrystal': (k, c, p) {
    final back = '<rect x="24" y="0" width="422" height="200" rx="70" fill="${k.grad('#F7FDFF', m(c, -.06), true)}"/>'
        '<rect x="24" y="0" width="422" height="200" rx="70" fill="${_iri(k)}" opacity=".55" stroke="#8CC4E0" stroke-width="5"/>'
        '${[(110, 70), (180, 100), (235, 60), (290, 100), (360, 70)].map((e) => _diamond(k, e.$1, e.$2, .32)).join()}'
        '${_spark(80, 40, 10)}${_spark(400, 150, 9)}';
    final front = '<rect x="64" y="286" width="24" height="26" rx="8" fill="${k.chrome()}"/><rect x="382" y="286" width="24" height="26" rx="8" fill="${k.chrome()}"/>'
        '<rect x="40" y="186" width="390" height="104" rx="40" fill="${k.grad('#FFFFFF', m(c, -.12))}"/><rect x="60" y="182" width="350" height="22" rx="11" fill="#FFFFFF" opacity=".85"/>'
        '<rect x="0" y="96" width="78" height="196" rx="39" fill="${_iri(k)}" stroke="#8CC4E0" stroke-width="4"/><rect x="392" y="96" width="78" height="196" rx="39" fill="${_iri(k)}" stroke="#8CC4E0" stroke-width="4"/>'
        '${_spark(39, 140, 9)}${_spark(431, 140, 9)}';
    return p == 'back' ? back : p == 'front' ? front : back + front;
  },
  'floorLampCrystal': (k, c, p) {
    return '<ellipse cx="70" cy="512" rx="54" ry="12" fill="#9AA3AE"/><rect x="64" y="150" width="12" height="362" rx="6" fill="${k.chrome()}"/>'
        '<circle cx="70" cy="100" r="86" fill="#E6F8FF" opacity=".45"/>'
        '<path d="M30 30h80l28 56-28 74H30L2 86z" fill="${_iri(k)}" stroke="#8CC4E0" stroke-width="3" stroke-linejoin="round"/>'
        '<path d="M2 86h136M30 30l12 56-12 74M110 30l-12 56 12 74M42 86h56" fill="none" stroke="#FFFFFF" stroke-width="2.5" opacity=".85"/>'
        '${_spark(26, 40, 10)}${_spark(124, 140, 8)}';
  },
};

/// Küçük resim kadrajları ([furnitureViewBox]'a eklenir).
const luxeViewBox = <String, String>{
  'royalFridge': '-20 -10 280 500', 'crystalFridge': '-20 -10 280 500',
  'chandelierGold': '-10 70 200 170', 'chandelierCrystal': '-10 70 200 170',
  'royalTub': '-10 -20 480 290', 'crystalTub': '-10 -20 480 290',
  'mirrorCrown': '-10 -26 200 262', 'mirrorDiamond': '-14 -16 208 252',
  'bedRoyal': '0 -60 500 500', 'bedCrystal': '0 -70 500 510',
  'wardrobeRoyal': '-20 -70 250 520', 'wardrobeCrystal': '-20 -76 250 526',
  'sofaThrone': '-10 -70 490 390', 'sofaCrystal': '-10 -10 490 330',
  'floorCandelabra': '-20 20 180 510', 'floorLampCrystal': '-20 0 180 530',
};
