// Tek seferlik görsel işleme betiği — `assets/images/` altındaki (zaten
// KAYIPSIZ WebP olan, bkz. convert_images_to_webp.dart) dosyaları KAYIPLI
// (lossy VP8) WebP'ye yeniden kodlar. Play Console app-size raporunda
// `assets/` klasörünün baskın boyut kaynağı olması üzerine (bkz.
// android/CLAUDE.md) — kayıpsız dönüşüm yalnızca ~%25 kazandırmıştı, kayıplı
// kodlama illüstrasyon/karakter sanatında tipik olarak %70-90 kazandırıyor.
//
// `image` paketinin `encodeWebP`'si YALNIZCA VP8L (lossless) yazabiliyor —
// paket içinde lossy VP8 encoder YOK (kaynağı okunarak doğrulandı). Bu yüzden
// gerçek kodlama Google'ın resmi `cwebp` aracına (libwebp) devrediliyor;
// `image` paketi yalnızca ÖNCESİ/SONRASI doğrulama için kullanılıyor.
//
// Önkoşul: `cwebp` PATH'te olmalı — `winget install Google.Libwebp` sonrası
// YENİ bir terminalde çalışır (PATH güncellemesi mevcut oturuma yansımaz).
// Alternatif: `CWEBP_PATH` ortam değişkenine tam .exe yolunu ver.
//
// Doğrulama (piksel-piksel eşitlik artık mümkün DEĞİL, kayıplı kodlama bu
// yüzden var) — her dosya için:
//   1. Boyutlar (width/height) birebir eşleşmeli.
//   2. Orijinalde TAM saydam olan (a=0) her piksel, yeni dosyada da a=0
//      olmalı — tool/CLAUDE.md'deki "baked-in siyah kare" bug sınıfını
//      (şeffaflığın bozulması) tekrar açmamak için sert bir kapı.
//   3. Saydam-olmayan pikseller için ortalama mutlak RGB farkı bir eşiğin
//      (varsayılan 12/255) altında kalmalı — kaba/bozuk kodlamaya karşı
//      sayısal güvenlik ağı (görsel kaliteyi garantilemez, yalnızca
//      "çöp çıktı" sınıfı hataları yakalar; nihai onay elle spot-check).
//
// Kullanım: dart run tool/convert_images_to_webp_lossy.dart [--quality=85]

import 'dart:io';
import 'package:image/image.dart' as img;

const _excluded = {'zibo_app_icon.png'};
const _maxMeanAbsDiff = 12.0;

void main(List<String> args) {
  final quality = _parseQuality(args);
  final cwebp = _locateCwebp();
  if (cwebp == null) {
    stderr.writeln(
      'cwebp bulunamadı. `winget install Google.Libwebp` sonrası YENİ bir '
      'terminalde çalıştır, ya da CWEBP_PATH ortam değişkenini tam .exe '
      'yoluna ayarla.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('cwebp: $cwebp (quality=$quality)');

  final dir = Directory('assets/images');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.toLowerCase().endsWith('.webp') &&
                !_excluded.contains(f.path.split(Platform.pathSeparator).last),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var totalBefore = 0;
  var totalAfter = 0;
  var converted = 0;
  var failed = 0;
  var skipped = 0;

  for (final file in files) {
    final originalBytes = file.readAsBytesSync();
    final original = img.decodeWebP(originalBytes);
    if (original == null) {
      stdout.writeln('${file.path}: mevcut WebP decode edilemedi, atlandı.');
      failed++;
      continue;
    }

    final tmpOut = File('${file.path}.lossy_tmp');
    final result = Process.runSync(cwebp, [
      '-q',
      '$quality',
      '-alpha_q',
      '100',
      '-m',
      '6',
      '-mt',
      '-quiet',
      file.path,
      '-o',
      tmpOut.path,
    ]);
    if (result.exitCode != 0 || !tmpOut.existsSync()) {
      stdout.writeln('${file.path}: cwebp başarısız — ${result.stderr}');
      failed++;
      if (tmpOut.existsSync()) tmpOut.deleteSync();
      continue;
    }

    final newBytes = tmpOut.readAsBytesSync();
    final reDecoded = img.decodeWebP(newBytes);
    final check = reDecoded == null
        ? _Check(false, 'yeniden decode edilemedi')
        : _verify(original, reDecoded);

    if (reDecoded == null || !check.ok) {
      stdout.writeln('${file.path}: DOĞRULAMA BAŞARISIZ — ${check.reason}');
      failed++;
      tmpOut.deleteSync();
      continue;
    }

    if (newBytes.length >= originalBytes.length) {
      stdout.writeln(
        '${file.path}: yeni dosya daha büyük/eşit '
        '(${originalBytes.length} -> ${newBytes.length}), bırakıldı.',
      );
      skipped++;
      tmpOut.deleteSync();
      continue;
    }

    tmpOut.renameSync(file.path);
    totalBefore += originalBytes.length;
    totalAfter += newBytes.length;
    converted++;

    final pct = (100 * (1 - newBytes.length / originalBytes.length))
        .toStringAsFixed(1);
    stdout.writeln(
      '${file.path}: ${originalBytes.length} -> ${newBytes.length} (-$pct%)',
    );
  }

  stdout.writeln('---');
  stdout.writeln(
    '$converted dönüştürüldü, $skipped atlandı (kazanç yok), $failed '
    'başarısız. Toplam: ${(totalBefore / 1024 / 1024).toStringAsFixed(1)}MB '
    '-> ${(totalAfter / 1024 / 1024).toStringAsFixed(1)}MB',
  );
}

class _Check {
  final bool ok;
  final String reason;
  _Check(this.ok, this.reason);
}

_Check _verify(img.Image original, img.Image reEncoded) {
  if (original.width != reEncoded.width ||
      original.height != reEncoded.height) {
    return _Check(false, 'boyut değişti');
  }
  var diffSum = 0.0;
  var opaqueCount = 0;
  for (var y = 0; y < original.height; y++) {
    for (var x = 0; x < original.width; x++) {
      final a = original.getPixel(x, y);
      final b = reEncoded.getPixel(x, y);
      if (a.a == 0) {
        if (b.a != 0) {
          return _Check(false, 'saydam piksel opak hale geldi ($x,$y)');
        }
        continue;
      }
      diffSum += (a.r - b.r).abs().toDouble() +
          (a.g - b.g).abs().toDouble() +
          (a.b - b.b).abs().toDouble();
      opaqueCount++;
    }
  }
  if (opaqueCount == 0) return _Check(true, '');
  final meanDiff = diffSum / (opaqueCount * 3);
  if (meanDiff > _maxMeanAbsDiff) {
    return _Check(
      false,
      'ortalama RGB farkı çok yüksek (${meanDiff.toStringAsFixed(1)})',
    );
  }
  return _Check(true, '');
}

int _parseQuality(List<String> args) {
  for (final a in args) {
    if (a.startsWith('--quality=')) {
      return int.tryParse(a.substring('--quality='.length)) ?? 85;
    }
  }
  return 85;
}

String? _locateCwebp() {
  final envPath = Platform.environment['CWEBP_PATH'];
  if (envPath != null && File(envPath).existsSync()) return envPath;

  if (_tryRun('cwebp')) return 'cwebp';

  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData != null) {
    final pkgRoot = Directory(
      '$localAppData/Microsoft/WinGet/Packages',
    );
    if (pkgRoot.existsSync()) {
      for (final entry in pkgRoot.listSync()) {
        if (entry is Directory && entry.path.contains('Libwebp')) {
          final found = entry
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('cwebp.exe'))
              .toList();
          if (found.isNotEmpty) return found.first.path;
        }
      }
    }
  }
  return null;
}

bool _tryRun(String exe) {
  try {
    final r = Process.runSync(exe, ['-version']);
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}
