// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — TÜM kostüm
// poz setlerini (df/sporcu/rapci/punk + asker/gladyator/hippi/hoca/korsan/
// zombi/altin/elmas) TEK bir GLOBAL hedef içerik yüksekliğine göre kırpıp
// ölçekler. Önceki sürümden (normalize_pose_sizes.dart + crop_pose_
// content.dart) FARKI: o ikisi yalnızca AYNI kostümün KENDİ pozları
// arasında tutarlılık sağlıyordu (her set kendi yerel maksimumuna göre); bu
// betik TÜM kostümler arasında da tutarlı olsun diye TEK bir global hedef
// kullanıyor — kullanıcı "bir kostümden diğerine geçildiğinde Zibo'nun
// boyutu ani şekilde büyüyüp küçülmesin" diye bildirdi.
//
// Süreç, her dosya için: (1) şeffaf-olmayan içerik sınır kutusunu ölç,
// (2) küçük bir pay (%3) ile kırp, (3) `targetHeight`e göre oranlı
// ölçekle (yükseklik TAM targetHeight, genişlik doğal en-boy oranına göre
// serbest — bkz. ZiboAnimatedImage'ın `height:` ile render etmesi), (4)
// PNG olarak geri yaz.
//
// Orijinal (işlenmemiş) dosyaların yedeği `tool/pose_originals_backup/`
// altında duruyor (pubspec assets kapsamı DIŞINDA) — bu betik hedef
// PNG'lerin ÜZERİNE YAZAR.
//
// Kullanım: dart run tool/process_all_poses.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;
const _marginFraction = 0.03;

// Ölçüm sonucunda bulunan gerçek global maksimum (bkz.
// measure_pose_bounds.dart çıktısı) — elle sabitlendi ki her çalıştırmada
// önceki turun ÇIKTISI (artık daha büyük olan, zaten işlenmiş dosyalar)
// yanlışlıkla yeni "maksimum" sanılıp sürekli büyümeye devam etmesin.
const _targetHeight = 763;

const _sets = <String, List<String>>{
  'df': ['pose1', 'pose2', 'pose3', 'pose4', 'pose5'],
  'sporcu': ['pose1', 'pose2', 'pose3', 'pose4'],
  'rapci': ['pose1', 'pose2', 'pose3', 'pose4'],
  'punk': ['pose1', 'pose2'],
  'asker': ['pose1', 'pose2', 'pose3'],
  'gladyator': ['pose1', 'pose2', 'pose3', 'pose4'],
  'hippi': ['pose1', 'pose2', 'pose3', 'pose4'],
  'hoca': ['pose1', 'pose2', 'pose3'],
  'korsan': ['pose1', 'pose2', 'pose3', 'pose4'],
  'zombi': ['pose1', 'pose2', 'pose3'],
  'altin': ['pose1', 'pose2', 'pose3'],
  'elmas': ['pose1', 'pose2', 'pose3'],
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

    // Hedef, kırpılmış (paylı) yüksekliğe göre hesaplanıyor ki tüm
    // görsellerin NİHAİ (kaydedilen) yüksekliği birebir eşit olsun.
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
