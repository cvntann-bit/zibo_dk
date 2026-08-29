// Ana ekran widget'ları (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü) için
// gereken İKİ native (Android res/drawable-nodpi) görseli hazırlayan,
// `remove_bg.dart`/`clean_app_icon.dart` ile AYNI "dev-only, tek seferlik
// görsel işleme betiği" desenindeki bir yardımcı:
//
// 1. `widget_zibo_logo.png` — mevcut `zibo_splash_logo.png`'nin (zaten
//    küçültülmüş/şeffaf, splash ekranı için üretilmiş) OLDUĞU GİBİ bir
//    kopyası — widget kartlarının köşesinde soluk bir marka imzası olarak
//    kullanılıyor, ayrı bir işleme gerekmedi.
// 2. `widget_zibo_character.png` — `assets/images/zibo_yeni.png`nin
//    (773×975, zaten şeffaf/kırpılmış varsayılan Zibo görseli) widget
//    belleği için makul bir boyuta (yükseklik 420px) küçültülmüş hâli —
//    "Zibo'nun Sözü" motivasyon widget'ında kullanılıyor.
//
// Çalıştırma: dart run tool/prepare_widget_assets.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const logoSource = 'android/app/src/main/res/drawable-nodpi/zibo_splash_logo.png';
  const logoDest = 'android/app/src/main/res/drawable-nodpi/widget_zibo_logo.png';
  File(logoSource).copySync(logoDest);
  print('$logoDest yazıldı (kopya).');

  const characterSource = 'assets/images/zibo_yeni.png';
  const characterDest = 'android/app/src/main/res/drawable-nodpi/widget_zibo_character.png';
  final bytes = File(characterSource).readAsBytesSync();
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    stderr.writeln('HATA: $characterSource decode edilemedi.');
    exit(1);
  }
  const targetHeight = 420;
  final targetWidth = (decoded.width * targetHeight / decoded.height).round();
  final resized = img.copyResize(
    decoded,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.cubic,
  );
  File(characterDest).writeAsBytesSync(img.encodePng(resized));
  print('$characterDest yazıldı (${resized.width}x${resized.height}).');
}
