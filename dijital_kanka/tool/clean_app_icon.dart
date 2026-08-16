// Tek seferlik görsel işleme betiği (uygulamaya dahil değil) — yeni
// uygulama ikonu zibo_app_icon.png'nin dört köşesindeki OPAK BEYAZ kare
// tuvali (1024x1024, yuvarlatılmış köşeli mavi ikon tasarımının DIŞINDA
// kalan alan) şeffaf yapar. Basit bir global "beyazı şeffaf yap" eşiklemesi
// KULLANILMADI — ikonun İÇİNDE de (Zibo'nun atleti, "ZibO" yazısının
// parlak vurguları) beyaza yakın tonlar var, bunları yanlışlıkla
// şeffaflaştırmamak için dört köşeden başlayan bir FLOOD FILL (BFS)
// kullanılıyor: yalnızca köşelerle BAĞLANTILI (4-yönlü komşu) beyaz
// piksel bölgesi şeffaflaştırılıyor, ikonun kendi içindeki İZOLE beyaz
// alanlara hiç dokunulmuyor.
//
// Orijinal dosyanın yedeği tool/pose_originals_backup/zibo_app_icon.png
// altında duruyor.
//
// Kullanım: dart run tool/clean_app_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const _whiteThreshold = 245; // r/g/b bu değerin üzerindeyse "beyaz" sayılır
const _path = 'assets/images/zibo_app_icon.png';

bool _isWhite(img.Pixel p) =>
    p.r >= _whiteThreshold && p.g >= _whiteThreshold && p.b >= _whiteThreshold;

void main() {
  final image = img.decodePng(File(_path).readAsBytesSync())!;
  final w = image.width;
  final h = image.height;

  final visited = List.generate(h, (_) => List.filled(w, false));
  final queue = <List<int>>[];

  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    if (visited[y][x]) return;
    if (!_isWhite(image.getPixel(x, y))) return;
    visited[y][x] = true;
    queue.add([x, y]);
  }

  // Dört köşeden başla.
  seed(0, 0);
  seed(w - 1, 0);
  seed(0, h - 1);
  seed(w - 1, h - 1);

  var cleared = 0;
  while (queue.isNotEmpty) {
    final cur = queue.removeLast();
    final x = cur[0], y = cur[1];
    image.setPixelRgba(x, y, 255, 255, 255, 0);
    cleared++;
    seed(x + 1, y);
    seed(x - 1, y);
    seed(x, y + 1);
    seed(x, y - 1);
  }

  File(_path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Şeffaflaştırılan piksel sayısı: $cleared / ${w * h}');
}
