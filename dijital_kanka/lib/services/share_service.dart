import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
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

  /// 2026 yeni özellik (Davet Et/referral) — yalnızca DÜZ METİN paylaşır,
  /// hiçbir görsel/dosya YOK. `ZiboShareSheet`'in `RenderRepaintBoundary.
  /// toImage()` ile bir PNG oluşturup [shareImageBytes]'ı çağırdığı akıştan
  /// FARKLI, çok daha basit bir yol — davet kodu/linki gibi salt metin
  /// içeriklerinin WhatsApp/Instagram'a tek tıkla gönderilmesi için.
  Future<void> shareText(String text);
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
    // **2026 bug düzeltmesi — Crashlytics'te en büyük tekrarlayan hata
    // (58 olay/6 kullanıcı, TÜM sürümlerde): `_File.length` →
    // `PathNotFoundException: Cannot retrieve length of file`.**
    // Kök neden: `XFile.fromData(bytes, ...)` (path'siz) verildiğinde,
    // `share_plus`'ın Android tarafı (`MethodChannelShare._getFile`) bizim
    // yerimize bytes'ı KENDİ SEÇTİĞİ bir geçici (cache) dosyaya yazıp o
    // path'ten yeni bir `XFile` üretiyor — plugin'in kendi kod yorumu
    // AÇIKÇA "the system will automatically delete files in this
    // TemporaryDirectory as disk space is needed elsewhere on the device"
    // diyor; bu dosya paylaşım TAMAMLANMADAN silinirse sonraki bir okuma/
    // uzunluk kontrolü `PathNotFoundException` fırlatıyor — ve bu, bizim
    // `ZiboShareSheet._share()`'deki try/catch'in DIŞINDA (plugin'in kendi
    // iç async akışında) gerçekleştiği için Crashlytics'e kadar sızıyordu.
    // **Düzeltme:** bytes'ı `share_plus`'ın belirsiz iç mekanizmasına
    // bırakmak yerine dosyayı BİZ, önceden bilinen bir path'e yazıp GERÇEK
    // path'li bir `XFile` veriyoruz — bu, `_getFile()`'ın riskli path'siz
    // fallback dalını (dolayısıyla o dalın kendi ayrı temp-dosya yazma/
    // okuma zamanlamasını) TAMAMEN atlıyor. Dosya BİLEREK SİLİNMİYOR
    // (share_plus'ın kendi dosyalarını da hiç silmediği gibi) — erken
    // silmek, paylaşım hedef uygulamaya (WhatsApp vb.) devrederken hâlâ
    // dosyayı okuyor olabileceği için AYNI türden bir yarış koşulu
    // yaratırdı; OS zaten cache dizinini kendi zamanlamasında temizliyor.
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/zibo_share_${DateTime.now().microsecondsSinceEpoch}.png';
    await File(path).writeAsBytes(bytes);
    final file = XFile(path, mimeType: 'image/png', name: fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        text: text,
      ),
    );
  }

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
