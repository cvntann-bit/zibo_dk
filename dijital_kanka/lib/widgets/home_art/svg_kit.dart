/// Zibo'nun Evi çizimlerinin ortak SVG yardımcıları — `docs/home_studio/
/// index.html` taslağındaki `mix/grad/pat/shine/handle/feet/shadow`
/// fonksiyonlarının birebir Dart karşılığı (docs/zibo_world_roadmap.md
/// Faz 2). Çizimler SVG metni olarak üretilir ve `flutter_svg` ile
/// boyanır; böylece taslakla aynı koordinatlar ve renkler korunur.
///
/// Bir sahne için TEK [SvgKit] kullanılır: degrade ve desen tanımları
/// [defs]'e birikir, kimlikleri sahne içinde benzersizdir.
class SvgKit {
  final List<String> _defs = [];
  int _uid = 0;
  bool _softShadow = false;

  String get defs => '${_softShadow ? _shadowDef : ''}${_defs.join()}';

  /// Taslaktaki `filter="url(#soft)"` bulanık gölge flutter_svg'de yok —
  /// yerine kenarı yumuşak radyal degrade.
  static const _shadowDef =
      '<radialGradient id="soft"><stop offset="0" stop-color="#3A1F0A" stop-opacity="1"/>'
      '<stop offset=".55" stop-color="#3A1F0A" stop-opacity=".8"/>'
      '<stop offset="1" stop-color="#3A1F0A" stop-opacity="0"/></radialGradient>';

  void addDef(String def) => _defs.add(def);

  /// [hex]'i beyaza ([amt] > 0) ya da siyaha ([amt] < 0) doğru karıştırır.
  static String mix(String hex, double amt) {
    final n = int.parse(hex.substring(1, 7), radix: 16);
    final t = amt > 0 ? 255 : 0;
    final a = amt.abs();
    String f(int v) => (v + (t - v) * a).round().toRadixString(16).padLeft(2, '0');
    return '#${f((n >> 16) & 255)}${f((n >> 8) & 255)}${f(n & 255)}'.toUpperCase();
  }

  static String hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// 8 haneli (#RRGGBBAA) rengi `stop-color` + `stop-opacity`'ye böler.
  static String _stop(String offset, String color) {
    if (color.length == 9) {
      final alpha = int.parse(color.substring(7), radix: 16) / 255;
      return '<stop offset="$offset" stop-color="${color.substring(0, 7)}" stop-opacity="${alpha.toStringAsFixed(3)}"/>';
    }
    return '<stop offset="$offset" stop-color="$color"/>';
  }

  String grad(String a, String b, [bool horizontal = false]) {
    final id = 'g${++_uid}';
    _defs.add(
      '<linearGradient id="$id" x1="0" y1="0" x2="${horizontal ? 1 : 0}" y2="${horizontal ? 0 : 1}">'
      '${_stop('0', a)}${_stop('1', b)}</linearGradient>',
    );
    return 'url(#$id)';
  }

  /// Çok duraklı doğrusal gradyan (eşit aralıklı); [diagonal] sol üstten sağ alta.
  String gradStops(List<String> colors, {bool horizontal = false, bool diagonal = false}) {
    final id = 'g${++_uid}';
    final n = colors.length - 1;
    _defs.add(
      '<linearGradient id="$id" x1="0" y1="0" x2="${horizontal || diagonal ? 1 : 0}" y2="${horizontal ? 0 : 1}">'
      '${[for (var i = 0; i <= n; i++) _stop((i / n).toStringAsFixed(3), colors[i])].join()}</linearGradient>',
    );
    return 'url(#$id)';
  }

  /// Taslaktaki `<pattern>` dolgusunun karşılığı: [body] döşemesi
  /// ([w]×[h], kökü 0,0 — `patternUnits="userSpaceOnUse"` gibi) alanı
  /// kaplayacak kadar tekrarlanır ve alana kırpılır. flutter_svg `<pattern>`'i
  /// web'de hiç çizmiyor (arka katmanın tamamı boş kalıyordu), bu yüzden
  /// döşeme elle yapılır. [clip] verilmezse alan dikdörtgendir; verilirse
  /// kırpma şekli (ör. `<path d="…"/>`).
  String tiled(String body, num w, num h, {required num x, required num y, required num width, required num height, String? clip}) {
    final id = ++_uid;
    _defs.add('<clipPath id="c$id">${clip ?? '<rect x="$x" y="$y" width="$width" height="$height"/>'}</clipPath>');
    _defs.add('<g id="t$id">$body</g>');
    final out = StringBuffer('<g clip-path="url(#c$id)">');
    for (var ty = (y / h).floor() * h; ty < y + height; ty += h) {
      for (var tx = (x / w).floor() * w; tx < x + width; tx += w) {
        out.write('<use href="#t$id" x="$tx" y="$ty"/>');
      }
    }
    out.write('</g>');
    return out.toString();
  }

  String chrome() => grad('#FFFFFF', '#8E96A3');

  String shine(num x, num y, num w, num h, num r, [num o = .35]) =>
      '<rect x="$x" y="$y" width="$w" height="$h" rx="$r" fill="#fff" opacity="$o"/>';

  String handle(num x, num y, num w, num h) =>
      '<rect x="$x" y="$y" width="$w" height="$h" rx="${(w < h ? w : h) / 2}" fill="${chrome()}" stroke="#6E7682" stroke-width="2"/>';

  String feet(num a, num b, num y) =>
      '<rect x="$a" y="$y" width="26" height="20" rx="8" fill="#5E5043"/><rect x="$b" y="$y" width="26" height="20" rx="8" fill="#5E5043"/>';

  /// Eşya altındaki yumuşak gölge (taslak: ry 16, bulanıklık 9, opaklık .26).
  String shadow(num cx, num cy, num rx) => softEllipse(cx, cy, rx, 16, .26);

  /// Bulanık elips: bulanıklığın taşmasını karşılamak için yarıçaplar
  /// büyütülür, kenar degradeyle sönümlenir.
  String softEllipse(num cx, num cy, num rx, num ry, num opacity) {
    _softShadow = true;
    return '<ellipse cx="$cx" cy="$cy" rx="${rx + 12}" ry="${ry + 12}" fill="url(#soft)" opacity="$opacity"/>';
  }
}
