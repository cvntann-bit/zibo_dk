// Tek seferlik yardımcı betik: tek parça bir çarkıfelek görselini (dış
// çerçeve + ok + merkez buton + dilimler hepsi tek PNG'de), merkezden olan
// uzaklığa (yarıçap) göre iki katmana ayırır:
//   - "_disk.png": yalnızca ödül dilimlerinin olduğu dönen halka.
//   - "_frame.png": geri kalan her şey (dış süslü çerçeve + ok işaretçi +
//     merkezdeki "Reklam İzle ve Çevir" hub'ı) — bu döner disk'in içine
//     biraz taşacak şekilde kesiliyor ki disk döndüğünde kenar/merkezde
//     asla boşluk görünmesin (bir dairenin kendi merkezi etrafında dönüşü
//     kendi siluetini değiştirmediği için bu örtüşme tamamen güvenli).
//
// Kullanım: dart run tool/split_wheel_layers.dart <dosya_yolu>
// Çıktı, aynı klasöre <ad>_disk.png ve <ad>_frame.png olarak yazılır.
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

// Ölçülen sınırlar: hub/dilim geçişi ~%34-36, dilim/çerçeve geçişi ~%79-82.
// Örtüşme payı için biraz genişletildi (bkz. yukarıdaki açıklama).
const _diskInnerFraction = 0.30;
const _diskOuterFraction = 0.84;
const _frameHubFraction = 0.37; // frame bunun İÇİNDE kalanı (hub) tutar
const _frameRingFraction = 0.77; // frame bunun DIŞINDA kalanı (çerçeve) tutar
// Sert/tırtıklı kenar olmasın diye yumuşak geçiş — rFrac (0-1) ölçeğinde bir
// KESİR, piksel değil (maxR ~660px için bu yaklaşık 4px'e denk gelir).
const _featherFrac = 0.006;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Kullanım: dart run tool/split_wheel_layers.dart <dosya_yolu>',
    );
    exit(1);
  }
  final path = args[0];
  final original = img.decodePng(File(path).readAsBytesSync())!;

  // Önce şeffaf olmayan içeriğin sınır kutusunu bul, kareye tamamla (merkez
  // hesaplaması için genişlik=yükseklik olması gerekiyor).
  var minX = original.width, maxX = 0, minY = original.height, maxY = 0;
  for (var y = 0; y < original.height; y++) {
    for (var x = 0; x < original.width; x++) {
      if (original.getPixel(x, y).a > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final boxW = maxX - minX + 1;
  final boxH = maxY - minY + 1;
  final side = max(boxW, boxH);
  final cropX = (minX - (side - boxW) / 2).round().clamp(0, original.width - side);
  final cropY = (minY - (side - boxH) / 2).round().clamp(0, original.height - side);

  final square = img.copyCrop(
    original,
    x: cropX,
    y: cropY,
    width: side,
    height: side,
  );

  final cx = square.width / 2;
  final cy = square.height / 2;
  final maxR = min(square.width, square.height) / 2;

  final disk = img.Image.from(square);
  final frame = img.Image.from(square);

  // r, [innerEdge, outerEdge] arasındaysa 1.0 (tam opak); kenarlarda
  // _featherFrac genişliğinde yumuşuyor; dışındaysa 0.0.
  double bandAlpha(double r, double innerEdge, double outerEdge) {
    if (r < innerEdge - _featherFrac || r > outerEdge + _featherFrac) return 0;
    if (r >= innerEdge && r <= outerEdge) return 1;
    if (r < innerEdge) return (r - (innerEdge - _featherFrac)) / _featherFrac;
    return 1 - (r - outerEdge) / _featherFrac;
  }

  // r <= edge ise 1.0, r > edge ise 0.0 (feather'lı).
  double innerDiscAlpha(double r, double edge) {
    if (r <= edge - _featherFrac) return 1;
    if (r >= edge + _featherFrac) return 0;
    return 1 - (r - (edge - _featherFrac)) / (2 * _featherFrac);
  }

  // r >= edge ise 1.0, r < edge ise 0.0 (feather'lı).
  double outerRingAlpha(double r, double edge) {
    if (r >= edge + _featherFrac) return 1;
    if (r <= edge - _featherFrac) return 0;
    return (r - (edge - _featherFrac)) / (2 * _featherFrac);
  }

  for (var y = 0; y < square.height; y++) {
    for (var x = 0; x < square.width; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final r = sqrt(dx * dx + dy * dy);
      final rFrac = r / maxR;

      final p = square.getPixel(x, y);
      final baseAlpha = p.a / 255.0;

      final diskA = bandAlpha(rFrac, _diskInnerFraction, _diskOuterFraction);
      disk.setPixelRgba(
        x,
        y,
        p.r.toInt(),
        p.g.toInt(),
        p.b.toInt(),
        (baseAlpha * diskA * 255).round().clamp(0, 255),
      );

      final frameA = max(
        innerDiscAlpha(rFrac, _frameHubFraction),
        outerRingAlpha(rFrac, _frameRingFraction),
      );
      frame.setPixelRgba(
        x,
        y,
        p.r.toInt(),
        p.g.toInt(),
        p.b.toInt(),
        (baseAlpha * frameA * 255).round().clamp(0, 255),
      );
    }
  }

  final base = path.substring(0, path.length - '.png'.length);
  File('${base}_disk.png').writeAsBytesSync(img.encodePng(disk));
  File('${base}_frame.png').writeAsBytesSync(img.encodePng(frame));
  // ignore: avoid_print
  print(
    'Bölündü: ${square.width}x${square.height} -> '
    '${base}_disk.png + ${base}_frame.png',
  );
}
