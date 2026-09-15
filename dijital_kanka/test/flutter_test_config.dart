import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Tüm test paketi için TEK SEFERLİK kurulum — Flutter bu dosyayı (varsa)
/// `test/` altındaki HER testten önce otomatik çalıştırır, ayrıca hiçbir
/// yerde import edilmesi GEREKMEZ.
///
/// 2026 — Zibo'nun yeni "Çizgi Roman Çıkartması" tipografisi (`main.dart`
/// `_buildTextTheme`, Baloo 2 + Nunito) artık uygulamanın GLOBAL temasının
/// bir parçası, yani `DijitalKankaApp`/`RootScreen` pump'layan HEMEN HEMEN
/// HER widget testi `google_fonts`'a değiyor — eskiden bu sadece paylaşım
/// kartı testlerinde elle ayarlanan `allowRuntimeFetching = false`'u artık
/// BURADA, tek noktadan, tüm paket için kapatıyoruz (aksi halde her test
/// çalışma zamanında gerçek bir font indirmeyi DENER — testte ağ yok,
/// bu da yavaşlık/flake'e yol açar).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
