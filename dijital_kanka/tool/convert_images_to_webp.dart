// Tek seferlik görsel işleme betiği — `assets/images/` altındaki PNG'leri
// KAYIPSIZ (lossless VP8L) WebP'ye çevirir. Play Console'un "Bit eşlem
// resim optimizasyonu" önerisine karşılık (bkz. android/CLAUDE.md).
//
// `image` paketinin `encodeWebP`'si VP8L (lossless) formatını kullanıyor —
// renk kuantizasyonu YOK, bu yüzden tool/CLAUDE.md'deki "img.quantize()
// alfa kanalını bozar" hatasıyla AYNI risk sınıfında DEĞİL. Yine de proje
// konvansiyonuna uyarak her dosya için piksel-piksel (r/g/b/a) doğrulama
// yapıyor — yalnızca TAM eşleşme + daha küçük dosya boyutu varsa orijinal
// PNG silinip yerine .webp yazılıyor.
//
// `zibo_app_icon.png` KASITLI olarak HARİÇ tutuldu — `flutter_launcher_icons`
// (bkz. pubspec.yaml `image_path`) kaynak görseli, WebP desteği doğrulanmadan
// dokunulmadı.
//
// Kullanım: dart run tool/convert_images_to_webp.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _excluded = {'zibo_app_icon.png'};

void main() {
  final dir = Directory('assets/images');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.toLowerCase().endsWith('.png') &&
                !_excluded.contains(f.path.split(Platform.pathSeparator).last),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var totalPngBytes = 0;
  var totalWebpBytes = 0;
  var converted = 0;
  var failed = 0;

  for (final file in files) {
    final pngBytes = file.readAsBytesSync();
    final original = img.decodePng(pngBytes);
    if (original == null) {
      stdout.writeln('${file.path}: PNG decode edilemedi, atlandı.');
      failed++;
      continue;
    }

    final webpBytes = img.encodeWebP(original);
    final reDecoded = img.decodeWebP(webpBytes);

    final identical =
        reDecoded != null &&
        reDecoded.width == original.width &&
        reDecoded.height == original.height &&
        _pixelsIdentical(original, reDecoded);

    if (!identical) {
      stdout.writeln('${file.path}: PİKSEL DOĞRULAMASI BAŞARISIZ — atlandı.');
      failed++;
      continue;
    }

    if (webpBytes.length >= pngBytes.length) {
      stdout.writeln(
        '${file.path}: WebP daha büyük/eşit (${pngBytes.length} -> '
        '${webpBytes.length}), PNG olarak bırakıldı.',
      );
      continue;
    }

    final webpPath = file.path.replaceAll(RegExp(r'\.png$'), '.webp');
    File(webpPath).writeAsBytesSync(webpBytes);
    file.deleteSync();

    totalPngBytes += pngBytes.length;
    totalWebpBytes += webpBytes.length;
    converted++;

    final pct = (100 * (1 - webpBytes.length / pngBytes.length))
        .toStringAsFixed(1);
    stdout.writeln(
      '${file.path}: ${pngBytes.length} -> ${webpBytes.length} (-$pct%)',
    );
  }

  stdout.writeln('---');
  stdout.writeln(
    '$converted dönüştürüldü, $failed başarısız/atlandı. '
    'Toplam: ${(totalPngBytes / 1024 / 1024).toStringAsFixed(1)}MB -> '
    '${(totalWebpBytes / 1024 / 1024).toStringAsFixed(1)}MB',
  );
}

bool _pixelsIdentical(img.Image a, img.Image b) {
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      if (pa.r != pb.r || pa.g != pb.g || pa.b != pb.b || pa.a != pb.a) {
        return false;
      }
    }
  }
  return true;
}
