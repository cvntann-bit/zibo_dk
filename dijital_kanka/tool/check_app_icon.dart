// Tek seferlik inceleme betiği (uygulamaya dahil değil) — yeni uygulama
// ikonu zibo_app_icon.png'nin boyutunu, alfa kanalı olup olmadığını ve köşe
// piksellerinin rengini/opaklığını raporlar.

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/zibo_app_icon.png').readAsBytesSync();
  final image = img.decodePng(bytes)!;
  stdout.writeln('size: ${image.width}x${image.height}');
  stdout.writeln('hasAlpha: ${image.hasAlpha}');
  final corners = [
    [0, 0],
    [image.width - 1, 0],
    [0, image.height - 1],
    [image.width - 1, image.height - 1],
    [image.width ~/ 2, 5],
    [5, image.height ~/ 2],
  ];
  for (final c in corners) {
    final p = image.getPixel(c[0], c[1]);
    stdout.writeln('pixel at $c: r=${p.r} g=${p.g} b=${p.b} a=${p.a}');
  }
}
