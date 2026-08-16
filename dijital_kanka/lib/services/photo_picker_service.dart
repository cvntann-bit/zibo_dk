import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Galeriden fotoğraf seçme + kalıcı yerel depolama sorumluluğunun soyut
/// arayüzü — `AdService`/`ShareService` ile aynı desen: hem `image_picker`
/// hem `path_provider` platform kanalı kullandığı için `flutter test`
/// ortamında gerçek implementasyona erişilemez, bu yüzden bunu kullanan
/// ekranlar (Manifest Günlüğü, Profil) bu servisi constructor'dan alır ve
/// testte sahte bir implementasyon enjekte edilir.
///
/// Başlangıçta yalnızca Manifest Günlüğü için yazılmıştı (`ManifestPhotoService`
/// adıyla) — Profil'in kendi fotoğrafı için de AYNI ihtiyaç ortaya çıkınca
/// (galeriden seç + kalıcı depola) jenerik bir isimle burada birleştirildi;
/// davranışta hiçbir değişiklik yok.
abstract class PhotoPickerService {
  const PhotoPickerService();

  /// Galeriden bir fotoğraf seçtirir. Kullanıcı seçim yapmadan vazgeçerse
  /// `null` döner. Dönen yol GEÇİCİDİR (`image_picker`'ın önbellek dizini) —
  /// kalıcı hale getirmek için [saveToPermanentStorage] çağrılmalı.
  Future<String?> pickFromGallery();

  /// [sourcePath]'teki (geçici) fotoğrafı uygulamanın kendi belge dizinine
  /// kopyalar ve YENİ kalıcı dosya yolunu döner — kalıcı olmayan bir yolu
  /// kayıtlarda saklamak, işletim sistemi önbelleği temizlediğinde
  /// fotoğrafın kaybolmasına yol açardı.
  Future<String> saveToPermanentStorage(String sourcePath);

  /// Artık kullanılmayan bir fotoğrafı diskten siler (best-effort — dosya
  /// zaten yoksa veya silinemezse sessizce başarısız olur). Bir günün
  /// fotoğrafı aynı gün içinde yenisiyle değiştirildiğinde eski dosyanın
  /// diskte öksüz kalmaması için kullanılır.
  Future<void> deletePhoto(String path);
}

/// Gerçek implementasyon: `image_picker` ile galeri seçimi, `path_provider`
/// ile uygulamanın belge dizini altında `app_photos/` klasörüne kalıcı
/// kopyalama (Manifest günlüğü VE Profil fotoğrafı bu TEK klasörü paylaşır —
/// dosya adları zaman damgalı olduğu için çakışma riski yok).
class ImagePickerPhotoService extends PhotoPickerService {
  const ImagePickerPhotoService();

  @override
  Future<String?> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return picked?.path;
  }

  @override
  Future<String> saveToPermanentStorage(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/app_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final dotIndex = sourcePath.lastIndexOf('.');
    final extension = dotIndex == -1 ? '.jpg' : sourcePath.substring(dotIndex);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final destPath = '${photosDir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  @override
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort temizlik — silme başarısız olsa da uygulama akışını
      // bozmamalı.
    }
  }
}
