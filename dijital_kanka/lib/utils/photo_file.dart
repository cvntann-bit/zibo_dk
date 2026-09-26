import 'dart:io';

/// Fotoğraf dosyası GERÇEKTEN gösterilebilir mi: var VE boş değil.
///
/// Yalnızca `existsSync()` yetmiyordu — Crashlytics'te 1.13.0'da gerçek bir
/// kullanıcıda (Oppo, Android 11) `app_photos/` altındaki 0 baytlık bir
/// dosya her açılışta "is empty and cannot be loaded as an image" hatası
/// veriyordu (dosya var ama içi boş: galeride henüz inmemiş bir bulut
/// fotoğrafı ya da yarım kalmış kopya).
bool isReadablePhotoFile(String? path) {
  if (path == null) return false;
  try {
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  } catch (_) {
    return false;
  }
}

/// Dosya var ama 0 bayt mı — seçilen fotoğrafı kaydetmeden önce reddetmek
/// için. Var olmayan yol `false` (testlerdeki sahte yollar etkilenmesin).
bool isEmptyPhotoFile(String? path) {
  if (path == null) return false;
  try {
    final file = File(path);
    return file.existsSync() && file.lengthSync() == 0;
  } catch (_) {
    return false;
  }
}
