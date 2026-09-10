// Tek seferlik: Playable reklam için Zibo görsellerini küçültüp base64 PNG
// olarak `tool/playable_assets.txt`'e yazar. Playable HTML'i bu base64
// stringlerini gömüyor (ad-network webview'ı DIŞ kaynak yükleyemez).
//
// Çalıştır: dart run tool/prep_playable_assets.dart
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const jobs = <String, int>{
    // dosya (assets/images/ altında)      -> hedef yükseklik (px)
    'zibo_df_pose1.png': 300, // yorgun / düşünen
    'zibo_df_pose3.png': 300, // neşeli
    'zibo_df_pose5.png': 320, // kutlama
    'zibo_coin.png': 110,
  };

  final out = StringBuffer();
  for (final entry in jobs.entries) {
    final src = File('assets/images/${entry.key}');
    if (!src.existsSync()) {
      stderr.writeln('YOK: ${src.path}');
      continue;
    }
    final decoded = img.decodeImage(src.readAsBytesSync())!;
    final resized = img.copyResize(
      decoded,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    // NOT: `img.quantize` bu 3D render'ların ALFA kanalını bozuyordu
    // (siyah kutu) — bkz. tool/CLAUDE.md "baked-in siyah" tuzağı. Sadece
    // yeniden boyutlandırıp maksimum sıkıştırmayla PNG yazıyoruz; ~400 KB
    // toplam base64 bir playable için fazlasıyla küçük.
    final png = img.encodePng(resized, level: 9);
    final b64 = base64Encode(png);
    final key = entry.key.replaceAll('.png', '').replaceAll('zibo_', '');
    out.writeln('--- $key (${resized.width}x${resized.height}, ${png.length ~/ 1024} KB png, ${b64.length ~/ 1024} KB b64) ---');
    out.writeln('data:image/png;base64,$b64');
    out.writeln();
  }
  File('tool/playable_assets.txt').writeAsStringSync(out.toString());
  stdout.writeln('Yazıldı: tool/playable_assets.txt');
}
