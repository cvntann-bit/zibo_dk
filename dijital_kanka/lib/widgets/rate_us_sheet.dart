import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Uygulamanın Play Console paket adı — `notification_service.dart`'taki
/// (Android "kullanılmayan uygulama" ayarları intent'i) AYNI ham dize,
/// projede bu tek satırlık sabiti paylaşılan bir dosyaya çıkaracak kadar
/// tekrar YOK (bilinçli, küçük bir dublikasyon).
const _packageName = 'com.dijitalkanka.dijital_kanka';

/// **2026 yeni özellik — kullanıcı isteği (test geri bildirim raporunun
/// "Uygulama İçi Puanlama İstemi" maddesine karşılık, ama raporun önerdiği
/// düz metin yerine): "Zibo görsellerini kullanıp altta 5 yıldız seçme,
/// hangisine basarsa direkt Google Play Store'a yönlendirme."** Gerçek bir
/// puanlama backend'i YOK — `AdFreePromoSheet`/`showModulesMenuSheet` ile
/// AYNI `showModalBottomSheet` deseninde, TEK işlevi kullanıcıyı Play
/// Store'un KENDİ puanlama arayüzüne yönlendirmek. Hangi yıldıza (1-5)
/// dokunulursa dokunulsun SONUÇ AYNI — gerçek puanı Play Store'un kendisi
/// topluyor, burada sahte bir "puanı kaydet" mantığı İCAT EDİLMEDİ.
Future<void> showRateUsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _RateUsSheetContent(),
  );
}

class _RateUsSheetContent extends StatefulWidget {
  const _RateUsSheetContent();

  @override
  State<_RateUsSheetContent> createState() => _RateUsSheetContentState();
}

class _RateUsSheetContentState extends State<_RateUsSheetContent> {
  int _selectedStars = 0;

  Future<void> _selectStars(int count) async {
    setState(() => _selectedStars = count);
    // Kullanıcının seçtiği yıldız sayısının GERÇEKTEN dolduğunu görmesi
    // için kısa bir gecikme — anında yönlendirme "dokunuşum hiç
    // algılanmadı" hissi verirdi (bkz. Hedef Tamamlama Kutlaması'ndaki
    // AYNI "seçim önce görünsün, sonra devam et" felsefesi).
    await Future<void>.delayed(const Duration(milliseconds: 350));
    // `_openPlayStoreListing()` KASITLI OLARAK `await` EDİLMİYOR/beklenmiyor
    // — `launchUrl` platform kanalı çağrısı `flutter_test` ortamında (bu
    // codebase'in `settingsWebsite`/`settingsContactUs` gibi TÜM diğer
    // `url_launcher` tabanlı satırlarında ZATEN kabul edilen, bkz. o
    // testlerin yalnızca satır VARLIĞINI doğrulayıp asla TIKLAMADIĞI
    // convansiyon) kalıcı olarak ASILI kalabiliyor (ne çözülüyor ne
    // reddediyor) — bunu `await` etmek sheet'in KAPANMASINI sonsuza kadar
    // engellerdi. Sheet, kullanıcının Play Store'a GERÇEKTEN gittiğini
    // beklemeden hemen kapanıyor — yönlendirme arka planda devam ediyor.
    unawaited(_openPlayStoreListing());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPlayStoreListing() async {
    // ÖNCE Play Store uygulamasını DOĞRUDAN açmayı dene (`market:` şeması)
    // — tarayıcıya hiç uğramadan, en doğal/hızlı deneyim (AndroidManifest'in
    // `<queries>` bloğuna bu şema eklendi). Başarısız olursa (Play Store
    // kurulu değil, emülatör vb.) `https://play.google.com/...` web
    // adresine (zaten sorgulanabilir `https:` şeması) geri düşülüyor.
    final marketUri = Uri.parse('market://details?id=$_packageName');
    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (openedMarket) return;
    await launchUrl(
      Uri.https('play.google.com', '/store/apps/details', {'id': _packageName}),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/zibo_yeni.png',
              height: 130,
              semanticLabel: l10n.ziboImagePlaceholder,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.rateUsSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rateUsSheetSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    iconSize: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      star <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                      // Zibo'nun altın tonu — bkz. `ZiboShareCard`'daki AYNI
                      // marka rengi.
                      color: const Color(0xFFF0C868),
                    ),
                    tooltip: '$star',
                    onPressed: () => _selectStars(star),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
