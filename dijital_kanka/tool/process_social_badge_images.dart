// Rozet Sistemi — Sosyal/Paylaşım Rozetleri görsellerini kaynak klasörden
// (kullanıcının masaüstündeki 'rozetler/sosyal paylaşım rozetleri') okuyup
// `assets/images/`e kopyalar — `process_badge_images.dart` ailesindeki AYNI
// "gerçek boyutuna göre yeniden ölçekle" deseni, yalnızca kaynak klasör
// farklı. Dosya adları AYNEN korunuyor (kullanıcının açık isteği).
//
// Kullanım: `dart run tool/process_social_badge_images.dart`
import 'dart:io';

import 'package:image/image.dart' as img;

const _targetLongEdge = 512;

const _sourceDir =
    r'C:\Users\MONSTER\OneDrive\Masaüstü\rozetler\sosyal paylaşım rozetleri';
const _destDir = 'assets/images';

void main() {
  final source = Directory(_sourceDir);
  if (!source.existsSync()) {
    stderr.writeln('Kaynak klasör bulunamadı: $_sourceDir');
    exit(1);
  }
  for (final entity in source.listSync()) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.png')) {
      continue;
    }
    final bytes = entity.readAsBytesSync();
    final image = img.decodePng(bytes);
    if (image == null) {
      stderr.writeln('Çözülemedi: ${entity.path}');
      continue;
    }
    final resized = image.width >= image.height
        ? img.copyResize(image, width: _targetLongEdge)
        : img.copyResize(image, height: _targetLongEdge);
    final fileName = entity.path.split(Platform.pathSeparator).last;
    final destPath = '$_destDir/$fileName';
    File(destPath).writeAsBytesSync(img.encodePng(resized));
    print(
      'Kopyalandı: $fileName (${image.width}x${image.height} → '
      '${resized.width}x${resized.height})',
    );
  }
}
