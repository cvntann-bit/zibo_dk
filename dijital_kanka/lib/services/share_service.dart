import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Bir görseli cihazın native paylaşım menüsüne göndermekten sorumlu
/// servisin soyut arayüzü. `flutter test` gerçek `share_plus` platform
/// channel çağrısını yapamayacağı (MissingPluginException fırlatır) için bu
/// soyutlama var — testler sahte bir implementasyon enjekte eder, tıpkı
/// [AdService]/[PurchaseService] deseninde olduğu gibi.
abstract class ShareService {
  const ShareService();

  /// [bytes] (PNG) içeriğini native paylaşım sayfasına gönderir. [fileName]
  /// paylaşılan dosyanın adı, [text] ise (destekleyen uygulamalarda, ör.
  /// WhatsApp) görselle birlikte gönderilecek altyazı metnidir.
  Future<void> shareImageBytes(
    Uint8List bytes, {
    required String fileName,
    String? text,
  });
}

/// `share_plus` paketiyle gerçek native paylaşım sayfasını açan
/// implementasyon.
class SharePlusService extends ShareService {
  const SharePlusService();

  @override
  Future<void> shareImageBytes(
    Uint8List bytes, {
    required String fileName,
    String? text,
  }) async {
    final file = XFile.fromData(bytes, mimeType: 'image/png', name: fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        // XFile.fromData'nın name'i web dışındaki platformlarda cross_file
        // tarafından yok sayılır; dosya adının her yerde doğru gitmesi için
        // ayrıca fileNameOverrides veriliyor.
        fileNameOverrides: [fileName],
        text: text,
      ),
    );
  }
}
