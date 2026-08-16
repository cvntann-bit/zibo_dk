// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — bir kostümün
// poz setindeki her PNG'nin şeffaf-olmayan içerik sınır kutusunu ölçer, o
// SETTEKİ en büyük içerik yüksekliğini hedef alıp diğer pozları bu hedefe
// göre YENİDEN ÖLÇEKLEYİP orijinal kanvas boyutunda (1408x768) ortalanmış
// olarak geri yazar. Amaç: aynı kostümün farklı pozları arasında karakterin
// GÖRÜNEN boyutunun tutarlı olması (bkz. CLAUDE.md "Zibo Poz/Animasyon
// Sistemi" — kullanıcı "pozdan kaynaklı biri diğerinden büyük/küçük
// olabilir, matematiksel bir şekilde aynı ölçüde olsun" diye bildirdi).
//
// Orijinal dosyaların YEDEĞİ `tool/pose_originals_backup/` altında duruyor
// (pubspec assets kapsamı DIŞINDA, uygulamaya dahil edilmiyor) — bu betik
// hedef PNG'lerin ÜZERİNE YAZAR, geri dönmek gerekirse oradan kopyalanabilir.
//
// Kullanım: dart run tool/normalize_pose_sizes.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;

const _poseSets = <List<String>>[
  [
    'assets/images/zibo_df_pose1.png',
    'assets/images/zibo_df_pose2.png',
    'assets/images/zibo_df_pose3.png',
    'assets/images/zibo_df_pose4.png',
    'assets/images/zibo_df_pose5.png',
  ],
  [
    'assets/images/zibo_sporcu_pose1.png',
    'assets/images/zibo_sporcu_pose2.png',
    'assets/images/zibo_sporcu_pose3.png',
    'assets/images/zibo_sporcu_pose4.png',
  ],
  [
    'assets/images/zibo_rapci_pose1.png',
    'assets/images/zibo_rapci_pose2.png',
    'assets/images/zibo_rapci_pose3.png',
    'assets/images/zibo_rapci_pose4.png',
  ],
  [
    'assets/images/zibo_punk_pose1.png',
    'assets/images/zibo_punk_pose2.png',
  ],
];

class _Content {
  _Content(this.image, this.left, this.top, this.right, this.bottom);
  final img.Image image;
  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left + 1;
  int get height => bottom - top + 1;
}

_Content _measure(img.Image image) {
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
  return _Content(image, minX, minY, maxX, maxY);
}

void main() {
  for (final set in _poseSets) {
    final decoded = <String, img.Image>{};
    final contents = <String, _Content>{};

    for (final path in set) {
      final image = img.decodePng(File(path).readAsBytesSync())!;
      decoded[path] = image;
      contents[path] = _measure(image);
    }

    final targetHeight = contents.values.map((c) => c.height).reduce(
      (a, b) => a > b ? a : b,
    );

    stdout.writeln('Set: ${set.first.split('/').last.split('_pose').first} '
        '(hedef içerik yüksekliği: $targetHeight px)');

    for (final path in set) {
      final image = decoded[path]!;
      final content = contents[path]!;
      final scale = targetHeight / content.height;

      final cropped = img.copyCrop(
        image,
        x: content.left,
        y: content.top,
        width: content.width,
        height: content.height,
      );

      final resized = (scale - 1.0).abs() < 0.001
          ? cropped
          : img.copyResize(
              cropped,
              height: targetHeight,
              width: (content.width * scale).round(),
              interpolation: img.Interpolation.cubic,
            );

      final canvas = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4,
      );
      // img.Image varsayılan olarak opak siyah dolu geliyor — tamamen
      // şeffaf bir tuval için her pikseli elle sıfırlamak gerekiyor.
      canvas.clear(img.ColorRgba8(0, 0, 0, 0));

      final destX = ((canvas.width - resized.width) / 2).round();
      final destY = ((canvas.height - resized.height) / 2).round();
      img.compositeImage(canvas, resized, dstX: destX, dstY: destY);

      File(path).writeAsBytesSync(img.encodePng(canvas));
      stdout.writeln(
        '  ${path.split('/').last}: içerik ${content.width}x${content.height} '
        '-> ölçek ${scale.toStringAsFixed(3)}x -> '
        '${resized.width}x${resized.height} @ ($destX,$destY)',
      );
    }
  }
}
