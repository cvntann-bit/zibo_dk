// Rozet Sistemi — Gizli/Eğlenceli Rozetler görsellerini kaynak klasörlerden
// okuyup `assets/images/`e kopyalar — `process_badge_images.dart` ailesindeki
// AYNI "gerçek boyutuna göre yeniden ölçekle" deseni. Bu kategori İKİ AYRI
// kaynak KLASÖRDEN besleniyor (kullanıcının kendi dosya organizasyonu):
// üç gerçek rozet görseli `rozetler/GizliEğlenceli Rozetler` ALT klasöründe,
// paylaşılan "gizem" görseli (`gizli_rozet.png`) ise bir üstteki `rozetler`
// klasöründe. Dosya adları AYNEN korunuyor (kullanıcının açık isteği).
//
// Kullanım: `dart run tool/process_hidden_badge_images.dart`
import 'dart:io';

import 'package:image/image.dart' as img;

const _targetLongEdge = 512;
const _destDir = 'assets/images';

const _sourceFiles = <String>[
  r'C:\Users\MONSTER\OneDrive\Masaüstü\rozetler\GizliEğlenceli Rozetler\gece_kusu_rozet.png',
  r'C:\Users\MONSTER\OneDrive\Masaüstü\rozetler\GizliEğlenceli Rozetler\erkenci_kus_rozet.png',
  r'C:\Users\MONSTER\OneDrive\Masaüstü\rozetler\GizliEğlenceli Rozetler\denge_ustasi_rozet.png',
  r'C:\Users\MONSTER\OneDrive\Masaüstü\rozetler\gizli_rozet.png',
];

void main() {
  for (final sourcePath in _sourceFiles) {
    final entity = File(sourcePath);
    if (!entity.existsSync()) {
      stderr.writeln('Kaynak dosya bulunamadı: $sourcePath');
      continue;
    }
    final bytes = entity.readAsBytesSync();
    final image = img.decodePng(bytes);
    if (image == null) {
      stderr.writeln('Çözülemedi: $sourcePath');
      continue;
    }
    final resized = image.width >= image.height
        ? img.copyResize(image, width: _targetLongEdge)
        : img.copyResize(image, height: _targetLongEdge);
    final fileName = sourcePath.split(Platform.pathSeparator).last;
    final destPath = '$_destDir/$fileName';
    File(destPath).writeAsBytesSync(img.encodePng(resized));
    print(
      'Kopyalandı: $fileName (${image.width}x${image.height} → '
      '${resized.width}x${resized.height})',
    );
  }
}
