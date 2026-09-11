// Tanıtım videosu (özellik + kostüm showcase) için görselleri küçültüp
// base64 PNG olarak tool/promo_assets.txt'e yazar.
// Çalıştır: dart run tool/prep_promo_assets.dart
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const jobs = <String, int>{
    'zibo_logo_new.png': 240,
    'zibo_hippi.png': 380,
    'zibo_asker.png': 380,
    'zibo_punk.png': 380,
    'zibo_samurai.png': 380,
    'zibo_gladyator.png': 380,
    'zibo_korsan.png': 380,
    'zibo_astronot.png': 380,
    'zibo_king.png': 380,
    'zibo_altin.png': 380,
    'zibo_elmas.png': 380,
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
    // NOT: `img.quantize` bu 3D render'ların alfa kanalını bozuyor (siyah
    // kutu) — bkz. tool/CLAUDE.md + prep_playable_assets.dart'taki AYNI
    // ders. Sadece resize + max-level PNG.
    final png = img.encodePng(resized, level: 9);
    final b64 = base64Encode(png);
    final key = entry.key.replaceAll('.png', '').replaceAll('zibo_', '');
    out.writeln('--- $key (${resized.width}x${resized.height}, ${png.length ~/ 1024} KB) ---');
    out.writeln('data:image/png;base64,$b64');
    out.writeln();
  }
  File('tool/promo_assets.txt').writeAsStringSync(out.toString());
  stdout.writeln('Yazıldı: tool/promo_assets.txt');
}
