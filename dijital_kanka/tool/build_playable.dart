// tool/playable_template.html içindeki {{POSE1}} {{POSE3}} {{POSE5}} {{COIN}}
// yer tutucularını tool/playable_assets.txt'teki data-URI'lerle değiştirip
// ../playable_ad/zibo_playable.html üretir (yüklemeye hazır, tek dosya).
//
// Çalıştır: dart run tool/build_playable.dart
import 'dart:io';

void main() {
  final assetsRaw = File('tool/playable_assets.txt').readAsStringSync();
  final map = <String, String>{};
  final blocks = assetsRaw.split(RegExp(r'^--- ', multiLine: true));
  for (final b in blocks) {
    final line = b.trimLeft();
    if (line.isEmpty) continue;
    final name = line.split(' ').first.trim(); // df_pose1 / coin
    final uri = RegExp(r'data:image/png;base64,[A-Za-z0-9+/=]+').firstMatch(b)?.group(0);
    if (uri == null) continue;
    map[name] = uri;
  }

  String need(String k) {
    final v = map[k];
    if (v == null) {
      stderr.writeln('EKSİK asset: $k — önce dart run tool/prep_playable_assets.dart');
      exit(1);
    }
    return v;
  }

  var html = File('tool/playable_template.html').readAsStringSync()
      .replaceAll('{{POSE1}}', need('df_pose1'))
      .replaceAll('{{POSE3}}', need('df_pose3'))
      .replaceAll('{{POSE5}}', need('df_pose5'))
      .replaceAll('{{COIN}}', need('coin'));

  final outDir = Directory('../playable_ad');
  if (!outDir.existsSync()) outDir.createSync();
  final out = File('${outDir.path}/zibo_playable.html');
  out.writeAsStringSync(html);
  stdout.writeln('Yazıldı: ${out.absolute.path}  (${(html.length / 1024).toStringAsFixed(0)} KB)');
}
