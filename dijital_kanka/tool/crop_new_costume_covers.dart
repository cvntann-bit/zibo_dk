// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — YENİ kostüm
// paketinin ("pose" ibaresi OLMAYAN) 5 vitrin/kapak dosyasını, mevcut
// kostüm vitrin görsellerinin (zibo_hippi.png, zibo_altin.png vb. — ölçüldü,
// içerik/kanvas yükseklik oranı ~%95.6-96.1) AYNI sıkı kırpma kuralına göre
// işler. Poz PNG'lerinden FARKLI olarak TEK bir global piksel hedefine
// ölçeklenmiyor — her vitrin görseli `CostumeCard`'da `height: 92` SABİT bir
// kutuda gösteriliyor, kutunun neredeyse TAMAMINI içerik doldurduğu sürece
// (mevcut kostümlerdeki gibi) kartlar arası görsel boyut tutarlılığı
// otomatik sağlanıyor — ayrı bir mutlak piksel hizalamasına gerek yok.
//
// Kullanım: dart run tool/crop_new_costume_covers.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;
const _marginFraction = 0.02;

const _files = [
  'assets/images/zibo_gentleman.png',
  'assets/images/zibo_king.png',
  'assets/images/zibo_astronot.png',
  'assets/images/zibo_cyborg.png',
  'assets/images/zibo_samurai.png',
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
    final margin = (b.height * _marginFraction).round();

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

    File(path).writeAsBytesSync(img.encodePng(cropped));
    final fillRatio = cropped.height / image.height;
    stdout.writeln(
      '${path.split('/').last}: kanvas ${image.width}x${image.height} -> '
      'kırpılmış ${cropped.width}x${cropped.height} '
      '(doluluk ${(fillRatio * 100).toStringAsFixed(1)}%)',
    );
  }
}
