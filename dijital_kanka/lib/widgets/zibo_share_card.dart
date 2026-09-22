import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/subscription_provider.dart';

/// "Zibonu Paylaş" için 9:16 (Instagram/TikTok Hikaye oranı) paylaşım kartı.
/// Hem canlı önizleme olarak hem de [RenderRepaintBoundary.toImage] ile PNG'ye
/// çevrilecek gerçek içerik olarak kullanılır — bu yüzden boyutu sabit
/// (mantıksal 450×800), ekrana göre değişmez; önizlemede küçük görünmesi
/// gerekiyorsa çağıran taraf bunu bir `FittedBox` içine alır (yakalanan
/// görüntünün çözünürlüğünü etkilemez).
///
/// **2026 güncellemesi — uzun (çok satırlı) mesajlarda satırlar üst üste
/// biniyordu:** Kart başlangıçta yalnızca Ana Sayfa'daki KISA (tek cümlelik)
/// Zibo sözlerini paylaşmak için tasarlanmıştı (360×640, sabit 36pt punto,
/// 220px'lik bir metin paneli). Profil > "Profil Kartını Paylaş" özelliği
/// aynı bileşeni bağ seviyesi + 4 istatistik puanını içeren ÇOK satırlı
/// (7 satıra kadar) bir özet metniyle çağırmaya başlayınca, bu dar alana
/// sığdırmak için `FittedBox`'ın uyguladığı agresif küçültme metni
/// okunamayacak kadar sıkıştırıp satırların görsel olarak üst üste binmiş
/// gibi görünmesine yol açtı. **Çözüm iki parçalı:** (1) kart hem geniş hem
/// yüksek yönde %25 büyütüldü (360×640 → 450×800, ORAN KORUNARAK — hâlâ tam
/// 9:16), metin paneline ayrılan dikey alan 220px'ten 480px'e çıkarıldı;
/// (2) taban punto artık mesajın uzunluğuna göre seçiliyor (bkz.
/// [_baseFontSize]) — tek satırlık kısa sözler hâlâ göz alıcı 36pt'te
/// kalırken, çok satırlı özetler baştan daha ölçülü bir puntoyla
/// (26pt) başlıyor ve neredeyse hiç küçültme gerektirmiyor. `FittedBox`
/// yine de beklenmedik derecede uzun bir metne karşı bir güvenlik ağı
/// olarak duruyor.
class ZiboShareCard extends StatelessWidget {
  const ZiboShareCard({
    super.key,
    required this.message,
    required this.gradient,
    required this.textStyle,
  });

  final String message;
  final Gradient gradient;

  /// Rengi de içerir (bkz. share_card_text_styles.dart) — arka plan gradyanı
  /// ne olursa olsun okunabilir kalması, sabit bir renge değil, metnin
  /// arkasındaki yarı saydam panele güveniyor.
  final TextStyle textStyle;

  static const double width = 450;
  static const double height = 800;
  // Kartın yan boşlukları (32) + ortadaki panelin kendi iç boşlukları (28)
  // çıkarılınca metne kalan gerçek genişlik.
  static const double _panelTextWidth = width - 2 * 32 - 2 * 28;

  /// Çok satırlı (ör. Profil Kartı özeti) mesajlar, tek satırlık Zibo
  /// sözlerinden çok daha fazla dikey yer kapladığı için daha ölçülü bir
  /// taban puntoyla başlıyor — bkz. sınıfın "2026 güncellemesi" notu.
  static double _baseFontSize(String message) =>
      message.contains('\n') ? 26 : 36;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Faz 5 (C3) — Zibo Pro/Pro+ filigranı, RepaintBoundary ile yakalanan
    // BU widget ağacına eklenmeli (ZiboShareSheet'e DEĞİL) — aksi halde
    // oluşturulan PNG'de görünmez. Free kullanıcıda kart AYNEN kalır.
    final isPro = context.watch<SubscriptionProvider>().isPro;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 32,
              child: Image.asset(
                'assets/images/zibo_logo_new.webp',
                width: 100,
                semanticLabel: l10n.ziboImagePlaceholder,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: DecoratedBox(
                  // Arka plan rengi/deseni ne olursa olsun metnin okunabilir
                  // kalması için ortada yarı saydam koyu bir panel.
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    child: SizedBox(
                      width: _panelTextWidth,
                      height: 480,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: _panelTextWidth,
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontSize: _baseFontSize(message),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Kartın kimliğini pekiştiren küçük, şık bir etiket — kullanıcı
            // isteğiyle eklendi ("kartın en altına küçük ve şık şekilde
            // '#ziboapp' etiketi").
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: Text(
                  '#ziboapp',
                  style: textStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textStyle.color?.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
            if (isPro)
              Positioned(
                top: 16,
                right: 16,
                child: Image.asset(
                  'assets/images/pro_watermark.png',
                  width: 48,
                  height: 48,
                  semanticLabel: l10n.shareCardProWatermarkSemanticLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
