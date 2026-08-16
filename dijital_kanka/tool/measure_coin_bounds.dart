// Tek seferlik ölçüm betiği (uygulamaya dahil değil) — Z Coin buton
// görsellerinin (mevcut + iki yeni tema varyantı) şeffaf OLMAYAN içerik
// sınır kutusunu ölçer. `dart run tool/measure_coin_bounds.dart` ile
// çalıştırılır.

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;

void main() {
  const files = [
    'assets/images/bottom_bar_z_coin.png',
    'assets/images/bottom_bar_z_coin_altintema.png',
    'assets/images/bottom_bar_z_coin_elmastema.png',
  ];

  for (final path in files) {
    final image = img.decodePng(File(path).readAsBytesSync())!;
    var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final a = image.getPixel(x, y).a;
        if (a > _alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    final contentW = maxX - minX + 1;
    final contentH = maxY - minY + 1;
    stdout.writeln(
      '${path.split('/').last}: canvas=${image.width}x${image.height} '
      'content=${contentW}x$contentH left=$minX top=$minY right=$maxX bottom=$maxY',
    );
  }
}
