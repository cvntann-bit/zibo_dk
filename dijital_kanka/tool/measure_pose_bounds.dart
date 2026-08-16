// Tek seferlik ölçüm betiği (uygulamaya dahil değil) — her poz PNG'sinin
// şeffaf OLMAYAN (alfa > eşik) içerik sınır kutusunu ölçüp karakterin
// gerçek görünen boyutunun pozlar arasında ne kadar farklılaştığını
// raporlar. `dart run tool/measure_pose_bounds.dart` ile çalıştırılır.

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;

class _Bounds {
  _Bounds(this.file, this.canvasW, this.canvasH, this.left, this.top, this.right, this.bottom);
  final String file;
  final int canvasW;
  final int canvasH;
  final int left;
  final int top;
  final int right;
  final int bottom;

  int get contentW => right - left + 1;
  int get contentH => bottom - top + 1;
}

_Bounds? _measure(String path) {
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) return null;

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
  if (maxX < 0) return null;
  return _Bounds(path, image.width, image.height, minX, minY, maxX, maxY);
}

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

void main(List<String> args) {
  final files = args.isNotEmpty
      ? args
      : [
          for (final entry in _sets.entries)
            for (final pose in entry.value)
              'assets/images/zibo_${entry.key}_$pose.png',
        ];

  var globalMaxH = 0;
  for (final f in files) {
    final b = _measure(f);
    if (b == null) {
      stdout.writeln('$f: EMPTY/UNREADABLE');
      continue;
    }
    if (b.contentH > globalMaxH) globalMaxH = b.contentH;
    stdout.writeln(
      '${b.file}: canvas=${b.canvasW}x${b.canvasH} '
      'content=${b.contentW}x${b.contentH} '
      'left=${b.left} top=${b.top} right=${b.right} bottom=${b.bottom}',
    );
  }
  stdout.writeln('--- GLOBAL MAX CONTENT HEIGHT: $globalMaxH ---');
}
