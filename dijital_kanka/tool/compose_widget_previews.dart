// `lib/widget_preview_generator_main.dart`'ın gerçek cihazda ürettiği
// (doğru font/emoji ile ama DÜZ gradyan arka planlı, logosuz) 5×2 temel
// PNG'nin ÜZERİNE Z-doku katmanını + Zibo logosunu bindiren, GEREKTİĞİNDE
// YENİDEN ÇALIŞTIRILABİLEN ikinci-aşama betiği (`dart:io`'nun cihazda
// PROJE KLASÖRÜNE erişememesi yüzünden ikisi de cihaz tarafında
// eklenemedi, bkz. o dosyanın dokümantasyonundaki TAM iş akışı). Girdi =
// o dosyanın ürettiği 10 PNG'nin `android/app/src/main/res/drawable
// (-night)-nodpi/`'ye ZATEN kopyalanmış hâli, çıktı = AYNI dosyaların
// ÜZERİNE yazılan, doku+logo eklenmiş nihai hâli.
//
// Kullanım: dart run tool/compose_widget_previews.dart

import 'dart:io';

import 'package:image/image.dart' as img;

/// `compositeImage`'ın `opacity` parametresi YOK (yalnızca `blend`/`mask`) —
/// bindirmeden ÖNCE kaynağın kendi alfa kanalını elle çarpıp azaltmak,
/// `generate_widget_z_pattern.dart`'taki AYNI teknik.
void _scaleAlpha(img.Image image, double factor) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      pixel.a = (pixel.a * factor).round();
    }
  }
}

const _names = [
  'widget_preview_water',
  'widget_preview_money',
  'widget_preview_daily_rewards',
  'widget_preview_motivation',
  'widget_preview_profile_stats',
];

Future<void> _compose(String baseDir, String zTexturePath) async {
  final zTexture = img.decodePngFile(zTexturePath);
  final logo = img.decodePngFile(
    'android/app/src/main/res/drawable-nodpi/widget_zibo_logo.png',
  );
  final zTex = await zTexture;
  final logoImg = await logo;

  for (final name in _names) {
    final path = '$baseDir/$name.png';
    final base = await img.decodePngFile(path);
    if (base == null) {
      stdout.writeln('ATLANDI (bulunamadı): $path');
      continue;
    }

    // Z dokusunu kanvasa (cover-fit) ölçekleyip bindir — dokunun kendi
    // alfa kanalı ZATEN çok düşük (bkz. `generate_widget_z_pattern.dart`),
    // ek bir azaltmaya gerek YOK, olduğu gibi bindiriliyor.
    final texResized = img.copyResize(
      zTex!,
      width: base.width,
      height: base.height,
    );
    img.compositeImage(base, texResized, blend: img.BlendMode.alpha);

    // Zibo logosunu sağ-alt köşeye, kartın yüksekliğinin ~%20'si
    // genişlikte, %50 opaklıkla yerleştir.
    final logoWidth = (base.height * 0.2).round();
    final logoScale = logoWidth / logoImg!.width;
    final logoResized = img.copyResize(
      logoImg,
      width: logoWidth,
      height: (logoImg.height * logoScale).round(),
    );
    _scaleAlpha(logoResized, 0.5);
    final margin = (base.height * 0.07).round();
    img.compositeImage(
      base,
      logoResized,
      dstX: base.width - logoResized.width - margin,
      dstY: base.height - logoResized.height - margin,
      blend: img.BlendMode.alpha,
    );

    File(path).writeAsBytesSync(img.encodePng(base));
    stdout.writeln('Bileşik önizleme kaydedildi: $path');
  }
}

Future<void> main() async {
  await _compose(
    'android/app/src/main/res/drawable-nodpi',
    'android/app/src/main/res/drawable-nodpi/widget_zibo_z_pattern.png',
  );
  await _compose(
    'android/app/src/main/res/drawable-night-nodpi',
    'android/app/src/main/res/drawable-night-nodpi/widget_zibo_z_pattern.png',
  );
}
