// Crashlytics 1.13.0 (Oppo, Android 11): `app_photos/` altındaki 0 baytlık
// dosya "is empty and cannot be loaded as an image" hatası veriyordu —
// boş dosya artık "fotoğraf yok" sayılır ve açılış temizliğinde düşer.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dijital_kanka/providers/manifest_provider.dart';
import 'package:dijital_kanka/utils/photo_file.dart';

void main() {
  late Directory dir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('zibo_photo_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('boş dosya okunamaz, dolu dosya okunur, olmayan dosya okunamaz', () {
    final empty = File('${dir.path}/empty.png')..writeAsBytesSync([]);
    final full = File('${dir.path}/full.png')..writeAsBytesSync([1, 2, 3]);

    expect(isReadablePhotoFile(empty.path), isFalse);
    expect(isEmptyPhotoFile(empty.path), isTrue);
    expect(isReadablePhotoFile(full.path), isTrue);
    expect(isEmptyPhotoFile(full.path), isFalse);
    expect(isReadablePhotoFile('${dir.path}/yok.png'), isFalse);
    expect(isEmptyPhotoFile('${dir.path}/yok.png'), isFalse);
    expect(isReadablePhotoFile(null), isFalse);
  });

  test('açılış temizliği boş fotoğraf dosyasına işaret eden kaydı "fotoğrafsız"a çevirir', () async {
    final empty = File('${dir.path}/empty.png')..writeAsBytesSync([]);
    final provider = ManifestProvider();
    await Future<void>.delayed(Duration.zero);
    provider.addEntry(photoPath: empty.path, intentionText: 'Deniz kenarı ev');

    provider.reconcileMissingPhotos();

    expect(provider.history.single.photoPath, isNull);
    expect(provider.history.single.intentionText, 'Deniz kenarı ev');
  });
}
