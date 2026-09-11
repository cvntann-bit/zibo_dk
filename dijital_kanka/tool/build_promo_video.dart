// tool/promo_template.html içindeki {{LOGO}} {{HIPPI}} ... yer tutucularını
// tool/promo_assets.txt'teki data-URI'lerle değiştirip
// ../promo_video/zibo_promo.html üretir (tarayıcıda aç, ekran kaydet).
//
// Çalıştır: dart run tool/build_promo_video.dart
import 'dart:io';

void main() {
  final assetsRaw = File('tool/promo_assets.txt').readAsStringSync();
  final map = <String, String>{};
  final blocks = assetsRaw.split(RegExp(r'^--- ', multiLine: true));
  for (final b in blocks) {
    final line = b.trimLeft();
    if (line.isEmpty) continue;
    final name = line.split(' ').first.trim();
    final uri = RegExp(r'data:image/png;base64,[A-Za-z0-9+/=]+').firstMatch(b)?.group(0);
    if (uri == null) continue;
    map[name] = uri;
  }

  String need(String k) {
    final v = map[k];
    if (v == null) {
      stderr.writeln('EKSİK asset: $k — önce dart run tool/prep_promo_assets.dart');
      exit(1);
    }
    return v;
  }

  const placeholders = {
    'LOGO': 'logo_new',
    'HIPPI': 'hippi',
    'ASKER': 'asker',
    'PUNK': 'punk',
    'SAMURAI': 'samurai',
    'GLADYATOR': 'gladyator',
    'KORSAN': 'korsan',
    'ASTRONOT': 'astronot',
    'KING': 'king',
    'ALTIN': 'altin',
    'ELMAS': 'elmas',
  };

  var html = File('tool/promo_template.html').readAsStringSync();
  placeholders.forEach((tag, assetKey) {
    html = html.replaceAll('{{$tag}}', need(assetKey));
  });

  final outDir = Directory('../promo_video');
  if (!outDir.existsSync()) outDir.createSync();
  final out = File('${outDir.path}/zibo_promo.html');
  out.writeAsStringSync(html);
  stdout.writeln('Yazıldı: ${out.absolute.path}  (${(html.length / 1024 / 1024).toStringAsFixed(2)} MB)');
}
