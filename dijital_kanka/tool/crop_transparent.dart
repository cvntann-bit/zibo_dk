// Tek seferlik yardımcı betik: remove_bg.dart ile şeffaflaştırılmış bir PNG
// dosyasını, içeriğin gerçek sınırlarına göre kırpar. Kaynak fotoğrafın
// etrafındaki geniş boş kenarlar olmadan, "width" olarak verilen değer
// doğrudan görselin görünen boyutuna karşılık gelsin diye gerekli.
// `dart run tool/crop_transparent.dart <dosya_yolu>` ile elle çalıştırılır.

import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: dart run tool/crop_transparent.dart <dosya_yolu>');
    exit(1);
  }
  final path = args[0];
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes)!;

  var minX = image.width, maxX = 0, minY = image.height, maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  final boxWidth = maxX - minX + 1;
  final boxHeight = maxY - minY + 1;
  final padX = (boxWidth * 0.04).round();
  final padY = (boxHeight * 0.02).round();

  final cropX = (minX - padX).clamp(0, image.width - 1);
  final cropY = (minY - padY).clamp(0, image.height - 1);
  final cropW = (boxWidth + padX * 2).clamp(1, image.width - cropX);
  final cropH = (boxHeight + padY * 2).clamp(1, image.height - cropY);

  final cropped = img.copyCrop(
    image,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );

  File(path).writeAsBytesSync(img.encodePng(cropped));
  // ignore: avoid_print
  print(
    'Kırpıldı: ${image.width}x${image.height} -> ${cropped.width}x${cropped.height}',
  );
}
