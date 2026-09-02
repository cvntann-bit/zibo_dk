// Tek seferlik yardımcı betik: `remove_bg.dart`'ın AYNI flood-fill +
// feather deseni, ama BEYAZ değil SİYAH bir stüdyo arka planı için —
// kullanıcının verdiği bazı rozet PNG'leri (ör. `yilmaz_efsanevi_rozet.png`)
// şeffaf DEĞİL, düz SİYAH bir kare tuval üzerinde geldi (üretici araç
// muhtemelen "transparent" yerine "black" arka plan varsayımıyla dışa
// aktarmış). Kenarlardan başlayan bir flood-fill ile bu siyah alanı şeffaf
// yapıp kenarlarda kademeli saydamlık (feather) uyguluyor — karakterin
// üzerindeki koyu tonlar (varsa) kenara bağlı olmadığı için etkilenmez.
//
// Kullanım: dart run tool/remove_black_bg.dart <dosya_yolu>

import 'dart:io';

import 'package:image/image.dart' as img;

const _fullThreshold = 12; // Bundan koyu pikseller: tam arka plan (siyah).
const _featherCeiling = 90; // Bundan açık pikseller: tamamen opak kalır.

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: dart run tool/remove_black_bg.dart <dosya_yolu>');
    exit(1);
  }
  final path = args[0];
  final bytes = File(path).readAsBytesSync();
  var image = img.decodePng(bytes);
  if (image == null) {
    stderr.writeln('PNG decode edilemedi: $path');
    exit(1);
  }
  image = image.convert(numChannels: 4);

  final width = image.width;
  final height = image.height;
  final isBackground = List.generate(height, (_) => List.filled(width, false));

  bool looksLikeBackground(int x, int y) {
    final p = image!.getPixel(x, y);
    return p.r <= _fullThreshold &&
        p.g <= _fullThreshold &&
        p.b <= _fullThreshold;
  }

  final stack = <List<int>>[];

  void seed(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    if (isBackground[y][x]) return;
    if (!looksLikeBackground(x, y)) return;
    isBackground[y][x] = true;
    stack.add([x, y]);
  }

  for (var x = 0; x < width; x++) {
    seed(x, 0);
    seed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    seed(0, y);
    seed(width - 1, y);
  }

  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    final x = cur[0], y = cur[1];
    final p = image.getPixel(x, y);
    image.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 0);
    seed(x + 1, y);
    seed(x - 1, y);
    seed(x, y + 1);
    seed(x, y - 1);
  }

  // Sert kenarları yumuşatmak için arka plana komşu piksellere kademeli
  // (feather) saydamlık uygula — `remove_bg.dart`'ın AYNI mantığı, yalnızca
  // "beyazlık" yerine "koyuluk" ölçülüyor ve dekontaminasyon siyaha doğru
  // (255 yerine 0'a) yapılıyor.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (isBackground[y][x]) continue;
      final touchesBackground = (x > 0 && isBackground[y][x - 1]) ||
          (x < width - 1 && isBackground[y][x + 1]) ||
          (y > 0 && isBackground[y - 1][x]) ||
          (y < height - 1 && isBackground[y + 1][x]);
      if (!touchesBackground) continue;

      final p = image.getPixel(x, y);
      final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
      final darkness = [r, g, b].reduce((a, b) => a > b ? a : b);
      if (darkness < _featherCeiling) {
        final t = (_featherCeiling - darkness) / (_featherCeiling - _fullThreshold);
        final alpha = (255 * (1 - t)).clamp(0, 255).round();
        if (t < 0.98) {
          final decR = (r / (1 - t)).clamp(0, 255).round();
          final decG = (g / (1 - t)).clamp(0, 255).round();
          final decB = (b / (1 - t)).clamp(0, 255).round();
          image.setPixelRgba(x, y, decR, decG, decB, alpha);
        } else {
          image.setPixelRgba(x, y, r, g, b, alpha);
        }
      }
    }
  }

  File(path).writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Tamamlandı: $path (${width}x$height)');
}
