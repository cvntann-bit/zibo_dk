// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — YENİ kostüm
// paketinin (Centilmen/Kral/Astronot/Siborg/Samuray) poz PNG'lerini
// `tool/process_all_poses.dart` ile AYNI GLOBAL hedef içerik yüksekliğine
// (763px, mevcut 12 kostümün tamamı bu değere göre işlendi) kırpıp
// ölçekler — kullanıcı isteği: "tüm görsellerin boyut/ölçek tutarlılığını
// koru", yani bu 5 yeni kostümün pozları da eskilerle BİREBİR aynı nihai
// yükseklikte olmalı.
//
// Süreç, her dosya için: (1) şeffaf-olmayan içerik sınır kutusunu ölç,
// (2) küçük bir pay (%3) ile kırp, (3) `targetHeight`e göre oranlı
// ölçekle (yükseklik TAM 763px, genişlik doğal en-boy oranına göre
// serbest), (4) PNG olarak geri yaz.
//
// Orijinal (işlenmemiş) dosyaların yedeği `tool/pose_originals_backup/`
// altında duruyor (pubspec assets kapsamı DIŞINDA).
//
// Kullanım: dart run tool/process_new_costume_poses.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;
const _marginFraction = 0.03;
const _targetHeight = 763; // bkz. process_all_poses.dart — AYNI sabit.

const _sets = <String, List<String>>{
  'gentleman': ['pose1', 'pose2', 'pose3'],
  'king': ['pose1', 'pose2', 'pose3'],
  'astronot': ['pose1', 'pose2', 'pose3'],
  'cyborg': ['pose1', 'pose2'],
  'samurai': ['pose1', 'pose2'],
};

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
  final files = [
    for (final entry in _sets.entries)
      for (final pose in entry.value)
        'assets/images/zibo_${entry.key}_$pose.png',
  ];

  for (final path in files) {
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

    final scale = _targetHeight / cropped.height;
    final resized = (scale - 1.0).abs() < 0.001
        ? cropped
        : img.copyResize(
            cropped,
            height: _targetHeight,
            width: (cropped.width * scale).round(),
            interpolation: img.Interpolation.cubic,
          );

    File(path).writeAsBytesSync(img.encodePng(resized));
    stdout.writeln(
      '${path.split('/').last}: içerik ${b.width}x${b.height} -> '
      'ölçek ${scale.toStringAsFixed(3)}x -> ${resized.width}x${resized.height}',
    );
  }
}
