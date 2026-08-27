// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — "Kurucu
// Üye" rozeti için basit, programatik bir PLACEHOLDER görsel üretir (bkz.
// CLAUDE.md "Davet Et"/"Kurucu Üye" bölümü — kullanıcı isteği: "şimdilik
// basit bir placeholder görsel kullan... asıl özel tasarımı ben ilerde
// hazırlayıp ekleyeceğim"). Bu ortamda harici bir görsel üretim aracı YOK,
// ama proje zaten `image` paketini (dev_dependency) tam olarak bu tür
// tek-seferlik görsel betikleri için kullanıyor (bkz. `remove_bg.dart`/
// `clean_app_icon.dart` emsali) — burada da aynı desen: altın/hardal
// renkli, ortasında beş köşeli bir yıldız olan basit bir dairesel rozet,
// şeffaf arka plan üzerine.
//
// Kullanıcı kendi tasarımını hazırladığında yalnızca `assets/images/
// founder_badge.png`'yi (AYNI dosya adıyla) üzerine yazması yeterli — kodda
// (`lib/data/founder_badge.dart`) HİÇBİR değişiklik gerekmez.
//
// Kullanım: dart run tool/generate_founder_badge_placeholder.dart

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _outputPath = 'assets/images/founder_badge.png';
const _size = 512;

// `zibo_share_card.dart`'taki DOKÜMANTE EDİLMİŞ "Zibo'nun altın tonu"
// (`0xFFF0C868`) ile AYNI — projenin geri kalanıyla paletçe tutarlı olsun
// diye rastgele bir altın seçilmedi.
final _gold = img.ColorRgba8(0xF0, 0xC8, 0x68, 255);
final _goldRim = img.ColorRgba8(0xB8, 0x86, 0x0B, 255); // koyu altın kenarlık
final _cream = img.ColorRgba8(0xFF, 0xF8, 0xE8, 255); // yıldız rengi

/// Merkezi [cx],[cy], dış yarıçapı [outerR], iç yarıçapı [innerR] olan
/// standart beş köşeli bir yıldızın 10 köşesini (dış/iç dönüşümlü) döner —
/// ilk köşe TAM YUKARI baksın diye -90°'den başlıyor.
List<img.Point> _starPoints(double cx, double cy, double outerR, double innerR) {
  final points = <img.Point>[];
  for (var i = 0; i < 10; i++) {
    final angle = (-pi / 2) + (i * pi / 5);
    final r = i.isEven ? outerR : innerR;
    points.add(img.Point(cx + r * cos(angle), cy + r * sin(angle)));
  }
  return points;
}

void main() {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  // Varsayılan olarak tüm pikseller şeffaf (alpha=0) başlıyor — ayrıca bir
  // "temizleme" adımına gerek yok.

  final center = _size / 2;

  // Dış altın kenarlık (biraz daha büyük, koyu tonda) + üstüne asıl altın
  // dolgu — bu ikisi birlikte ince bir "rim" (kenarlık) efekti veriyor.
  img.fillCircle(
    image,
    x: center.round(),
    y: center.round(),
    radius: (center * 0.92).round(),
    color: _goldRim,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: center.round(),
    y: center.round(),
    radius: (center * 0.84).round(),
    color: _gold,
    antialias: true,
  );

  // Ortadaki yıldız.
  img.fillPolygon(
    image,
    vertices: _starPoints(center, center, center * 0.46, center * 0.19),
    color: _cream,
  );

  File(_outputPath).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Kurucu Üye rozeti placeholder\'ı üretildi: $_outputPath');
}
