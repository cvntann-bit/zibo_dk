// Tek seferlik görsel işleme betiği (uygulamaya dahil değil, `remove_bg.dart`/
// `generate_founder_badge_placeholder.dart` ile AYNI desen) — ana ekran
// widget'larının arka planına eklenen, rastgele dağılmış + ağır blurlanmış
// "Z" harfi dokusunu üretir (bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü,
// kullanıcı isteği: "arka plan çok amatör duruyor, Zibo ikonundaki Z harfini
// arka plana bolca random koyup iyice blurlayıp öyle bir tasarım
// düşünebilirsin").
//
// "Z" harfleri FONT/BitmapFont'a hiç gerek kalmadan, saf geometriyle
// çiziliyor — bir Z zaten yalnızca üç doğru parçasından (üst yatay çizgi,
// çapraz, alt yatay çizgi) oluşuyor; her harf kendi yerel [-s/2, s/2]
// koordinat sisteminde tanımlanıp rastgele bir açıyla döndürülüp rastgele
// bir kanvas noktasına taşınıyor.
//
// **Alfa/opaklık kontrolü — İKİ AŞAMALI, kasıtlı olarak dolaylı:** `drawLine`
// çağrılarının KENDİSİ TAM OPAK (alpha=255) çiziliyor — `image` paketinin
// `drawLine`/`thickness` birleşiminin KISMİ alfa değerlerini güvenilir
// şekilde blend ETMEDİĞİ (üst üste binen/tek başına duran çizgiler ilk
// denemede neredeyse AYNI, tam opak yoğunlukta çıktı — beklenmedik bir
// davranıştı) elle görsel karşılaştırmayla YAKALANDI. **Çözüm:** önce TÜM
// harfler tam opak çizilip blurlanıyor (bu, blur'un kendisinin doğal
// olarak yumuşak bir opaklık düşüşü YARATMASI için — kenarlar zaten
// blur sayesinde kademeli soluklaşıyor), SONRA bütün görselin alfa
// kanalı TEK bir çarpanla (`_finalAlphaScale`) aşağı çekiliyor — bu,
// nihai göze çarpma düzeyini `drawLine`'ın iç blend davranışından TAMAMEN
// BAĞIMSIZ, öngörülebilir şekilde ayarlamayı sağlıyor.
//
// İKİ varyant üretiliyor — AÇIK ve KOYU tema için AYRI (colors.xml'deki
// `widget_card_gradient_start/end` çiftiyle AYNI ikili desen): açık temada
// koyu/espresso tonunda, koyu temada altın/krem tonunda — ikisi de kendi
// gradyan zemininin ÜZERİNDE yalnızca dokuyu zenginleştiren, "bolca ama
// zar zor sezilen" bir doku katmanı olacak şekilde ayarlandı.
//
// Kullanım: dart run tool/generate_widget_z_pattern.dart

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _size = 640;
const _zCount = 55;
const _blurRadius = 16;

/// Blur SONRASI, TÜM görsele uygulanan global alfa çarpanı — nihai en
/// yoğun (üst üste binen harflerin ortası) nokta bile bu sayede kabaca
/// 255*0.34 ≈ 87 (≈%34 opaklık) civarında kalıyor, tek başına duran bir
/// harf ise bunun çok altında (~%8-12) — "bolca ama zar zor sezilen"
/// hedefine göre elle ayarlanmış bir değer.
const _finalAlphaScale = 0.34;

// `main.dart`'taki `_espresso`/`_darkGold` sabitleriyle AYNI aile — widget
// arka planının GERÇEK tema renkleriyle tutarlı kalsın diye.
final _lightZColor = img.ColorRgba8(0x4A, 0x33, 0x18, 255); // koyu espresso
final _darkZColor = img.ColorRgba8(0xE3, 0xC1, 0x79, 255); // sıcak altın/krem

void _paintVariant({
  required String outputPath,
  required img.Color zColor,
  required int seed,
}) {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  final random = Random(seed);

  for (var i = 0; i < _zCount; i++) {
    final cx = random.nextDouble() * _size;
    final cy = random.nextDouble() * _size;
    final s = 30.0 + random.nextDouble() * 90.0; // harf boyutu
    final angle = random.nextDouble() * pi * 2;
    final thickness = (s * 0.11).round().clamp(2, 12);
    // Çizim aşamasında BİLEREK tam opak (bkz. dosya başındaki "İKİ
    // AŞAMALI" notu) — gerçek son opaklık `_finalAlphaScale` ile ayrıca
    // belirleniyor.
    final color = img.ColorRgba8(
      zColor.r.toInt(),
      zColor.g.toInt(),
      zColor.b.toInt(),
      255,
    );

    final local = <List<double>>[
      [-s / 2, -s / 2],
      [s / 2, -s / 2],
      [s / 2, -s / 2],
      [-s / 2, s / 2],
      [-s / 2, s / 2],
      [s / 2, s / 2],
    ];
    final cosA = cos(angle);
    final sinA = sin(angle);
    final pts = local
        .map(
          (p) => [
            cx + p[0] * cosA - p[1] * sinA,
            cy + p[0] * sinA + p[1] * cosA,
          ],
        )
        .toList();

    for (var seg = 0; seg < 3; seg++) {
      final p1 = pts[seg * 2];
      final p2 = pts[seg * 2 + 1];
      img.drawLine(
        image,
        x1: p1[0].round(),
        y1: p1[1].round(),
        x2: p2[0].round(),
        y2: p2[1].round(),
        color: color,
        thickness: thickness,
        antialias: true,
      );
    }
  }

  final blurred = img.gaussianBlur(image, radius: _blurRadius);
  for (var y = 0; y < blurred.height; y++) {
    for (var x = 0; x < blurred.width; x++) {
      final pixel = blurred.getPixel(x, y);
      pixel.a = (pixel.a * _finalAlphaScale).round();
    }
  }

  File(outputPath).writeAsBytesSync(img.encodePng(blurred));
  stdout.writeln('Z deseni üretildi: $outputPath');
}

void main() {
  Directory(
    'android/app/src/main/res/drawable-nodpi',
  ).createSync(recursive: true);
  Directory(
    'android/app/src/main/res/drawable-night-nodpi',
  ).createSync(recursive: true);
  _paintVariant(
    outputPath:
        'android/app/src/main/res/drawable-nodpi/widget_zibo_z_pattern.png',
    zColor: _lightZColor,
    seed: 7,
  );
  _paintVariant(
    outputPath:
        'android/app/src/main/res/drawable-night-nodpi/widget_zibo_z_pattern.png',
    zColor: _darkZColor,
    seed: 7,
  );
}
