// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — Altın/Elmas
// Z Coin buton tema görsellerini, MEVCUT `bottom_bar_z_coin.png` ile AYNI
// 374x374 kare tuvale (aynı içerik/tuval doluluk oranıyla) kırpıp ölçekler.
// Amaç: `ZFloatingButton` hangi tema görselini gösterirse göstersin, PNG'nin
// kendi kanvas boyutu HER ZAMAN 374x374 olduğu için Flutter'ın `Image`
// widget'ının iç ölçekleme davranışından bağımsız olarak buton boyutu SABİT
// kalır (bkz. costume_poses.dart'taki aynı "tek hedef tuval" yaklaşımı).
//
// Süreç, her yeni tema dosyası için: (1) şeffaf-olmayan içerik sınır
// kutusunu ölç, (2) küçük bir pay (%2) ile kırp, (3) referans
// (`bottom_bar_z_coin.png`) ile AYNI doluluk oranına (360/374 ≈ %96.3) göre
// ölçekle, (4) 374x374 şeffaf bir tuvalin TAM ortasına yapıştır, (5) PNG
// olarak geri yaz.
//
// Orijinal (işlenmemiş) dosyaların yedeği `tool/pose_originals_backup/`
// altında duruyor (pubspec assets kapsamı DIŞINDA).
//
// Kullanım: dart run tool/process_coin_theme.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;
const _marginFraction = 0.02;

// Referans bottom_bar_z_coin.png ölçümünden: canvas=374x374,
// content=360x359 -> doluluk oranı = 360/374.
const _canvasSize = 374;
const _fillRatio = 360 / 374;

const _files = [
  'assets/images/bottom_bar_z_coin_altintema.png',
  'assets/images/bottom_bar_z_coin_elmastema.png',
];

class _Bounds {
  _Bounds(this.left, this.top, this.right, this.bottom);
  final int left;
  final int top;
  final int right;
  final int bottom;
  int get width => right - left + 1;
  int get height => bottom - top + 1;
}

_Bounds _measure(img.Image image) {
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
  return _Bounds(minX, minY, maxX, maxY);
}

void main() {
  for (final path in _files) {
    final image = img.decodePng(File(path).readAsBytesSync())!;
    final b = _measure(image);
    final margin = (max(b.width, b.height) * _marginFraction).round();

    final cropLeft = (b.left - margin).clamp(0, image.width - 1);
    final cropTop = (b.top - margin).clamp(0, image.height - 1);
    final cropRight = (b.right + margin).clamp(0, image.width - 1);
    final cropBottom = (b.bottom + margin).clamp(0, image.height - 1);

    final cropped = img.copyCrop(
      image,
      x: cropLeft,
      y: cropTop,
      width: cropRight - cropLeft + 1,
      height: cropBottom - cropTop + 1,
    );

    // Referansla AYNI doluluk oranını elde etmek için hedef boyut: kırpılmış
    // içeriğin en uzun kenarı, (canvas * fillRatio)'ya eşitlensin.
    final targetLongSide = (_canvasSize * _fillRatio).round();
    final longSide = cropped.width > cropped.height
        ? cropped.width
        : cropped.height;
    final scale = targetLongSide / longSide;
    final resized = img.copyResize(
      cropped,
      width: (cropped.width * scale).round(),
      height: (cropped.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );

    final canvas = img.Image(
      width: _canvasSize,
      height: _canvasSize,
      numChannels: 4,
    );
    final offsetX = ((_canvasSize - resized.width) / 2).round();
    final offsetY = ((_canvasSize - resized.height) / 2).round();
    img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

    File(path).writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln(
      '${path.split('/').last}: içerik ${b.width}x${b.height} -> '
      'ölçek ${scale.toStringAsFixed(3)}x -> tuval ${canvas.width}x${canvas.height} '
      '(içerik ${resized.width}x${resized.height} @ $offsetX,$offsetY)',
    );
  }
}

int max(int a, int b) => a > b ? a : b;
