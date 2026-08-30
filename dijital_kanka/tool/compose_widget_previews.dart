// `lib/widget_preview_generator_main.dart`'ın gerçek cihazda ürettiği
// (doğru font/emoji ile ama DÜZ gradyan arka planlı, logosuz) 5×2 temel
// PNG'nin ÜZERİNE Zibo logosunu bindiren, GEREKTİĞİNDE YENİDEN
// ÇALIŞTIRILABİLEN ikinci-aşama betiği (`dart:io`'nun cihazda PROJE
// KLASÖRÜNE erişememesi yüzünden logo cihaz tarafında eklenemedi, bkz. o
// dosyanın dokümantasyonundaki TAM iş akışı). Girdi = o dosyanın ürettiği
// 10 PNG'nin `android/app/src/main/res/drawable(-night)-nodpi/`'ye ZATEN
// kopyalanmış hâli, çıktı = AYNI dosyaların ÜZERİNE yazılan, logo eklenmiş
// nihai hâli.
//
// **2026 güncellemesi — Z-doku katmanı KALDIRILDI.** İlk sürüm burada
// Zibo'nun "Z" harfinden türeyen, rastgele dağılmış + blurlanmış bir doku
// katmanını da bindiriyordu (bkz. `widget_background.xml`'deki AYNI geri
// alma notu) — kullanıcı gerçek cihazda görüp "çok kötü duruyor,
// kaldıralım" diyerek reddetti. Betik artık YALNIZCA logoyu bindiriyor.
//
// Kullanım: dart run tool/compose_widget_previews.dart

import 'dart:io';

import 'package:image/image.dart' as img;

/// `compositeImage`'ın `opacity` parametresi YOK (yalnızca `blend`/`mask`) —
/// bindirmeden ÖNCE kaynağın kendi alfa kanalını elle çarpıp azaltmak.
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

Future<void> _compose(String baseDir) async {
  final logo = await img.decodePngFile(
    'android/app/src/main/res/drawable-nodpi/widget_zibo_logo.png',
  );

  for (final name in _names) {
    final path = '$baseDir/$name.png';
    final base = await img.decodePngFile(path);
    if (base == null) {
      stdout.writeln('ATLANDI (bulunamadı): $path');
      continue;
    }

    // Zibo logosunu sağ-alt köşeye, kartın yüksekliğinin ~%20'si
    // genişlikte, %50 opaklıkla yerleştir.
    final logoWidth = (base.height * 0.2).round();
    final logoScale = logoWidth / logo!.width;
    final logoResized = img.copyResize(
      logo,
      width: logoWidth,
      height: (logo.height * logoScale).round(),
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
  await _compose('android/app/src/main/res/drawable-nodpi');
  await _compose('android/app/src/main/res/drawable-night-nodpi');
}
