// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — normalize
// edilmiş poz PNG'lerini (bkz. normalize_pose_sizes.dart, aynı setteki
// tüm pozlar zaten AYNI içerik yüksekliğine sahip) 1408x768'lik geniş,
// çoğunlukla boş kanvastan kurtarıp yalnızca karakterin gerçek sınır
// kutusuna (+ küçük bir pay) SIKI kırpar.
//
// Neden gerekli: `Image.asset(width: X)` yalnızca `width` verildiğinde
// yüksekliği görselin KENDİ (tüm kanvasa göre) en-boy oranından hesaplıyor.
// Kanvasın büyük kısmı şeffaf olduğu için (içerik genişliği kanvasın
// yalnızca ~%30-40'ı), verilen bir `width` değerinde render edilen
// KARAKTER, kutunun kendisinden çok daha küçük kalıyordu — kullanıcının
// "widget'ın width'ini büyüttüm ama karakter hâlâ küçük" bildirdiği tam
// olarak buydu. Bu betikten sonra `ZiboAnimatedImage` `width` yerine
// `height` ile render ediyor (bkz. o dosya) — kırpılmış görsellerin
// AYNI SETTEKİ hepsi zaten eşit yükseklikte olduğu için, sabit bir
// `height` vermek pozlar arasında dikey bir sıçrama yaratmadan (yalnızca
// doğal genişlik farkına izin vererek) karakteri kutuyu DOLDURACAK
// şekilde büyütüyor.
//
// Kullanım: dart run tool/crop_pose_content.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _alphaThreshold = 10;
// Kırpılan kutunun her kenarına eklenen küçük şeffaf pay (kesilmiş gibi
// görünmesin diye) — hedef yüksekliğin bir kesri.
const _marginFraction = 0.03;

const _poseFiles = <String>[
  'assets/images/zibo_df_pose1.png',
  'assets/images/zibo_df_pose2.png',
  'assets/images/zibo_df_pose3.png',
  'assets/images/zibo_df_pose4.png',
  'assets/images/zibo_df_pose5.png',
  'assets/images/zibo_sporcu_pose1.png',
  'assets/images/zibo_sporcu_pose2.png',
  'assets/images/zibo_sporcu_pose3.png',
  'assets/images/zibo_sporcu_pose4.png',
  'assets/images/zibo_rapci_pose1.png',
  'assets/images/zibo_rapci_pose2.png',
  'assets/images/zibo_rapci_pose3.png',
  'assets/images/zibo_rapci_pose4.png',
  'assets/images/zibo_punk_pose1.png',
  'assets/images/zibo_punk_pose2.png',
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
  for (final path in _poseFiles) {
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
    stdout.writeln(
      '${path.split('/').last}: ${image.width}x${image.height} -> '
      '${cropped.width}x${cropped.height}',
    );
  }
}
