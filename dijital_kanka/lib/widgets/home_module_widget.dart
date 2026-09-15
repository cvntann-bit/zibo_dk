import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'sticker_style.dart';

/// Ana Sayfa'nın konuşma balonu ile alt bar arasına, "Çizgi Roman
/// Çıkartması" mockup'ında onaylanan iki mini kart (Su/Hedef) için ortak
/// görsel — bkz. `docs/theme_new.md` "Onaylanan: Ana Sayfa yerleşimi".
///
/// Kontur/gölge SABİT (bkz. `sticker_style.dart`); ilerleme çubuğunun
/// dolgusu aktif temanın `colorScheme.primary`'sinden gelir — böylece
/// kullanıcı Mağaza'dan farklı bir tema satın alırsa bu kartlar da otomatik
/// uyum sağlar. Kart tıklanabilir — [onTap] ilgili modülü (Su Takibi/Hedef
/// Takibi) açar.
class HomeModuleWidget extends StatelessWidget {
  const HomeModuleWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.valueLabel,
    required this.progress,
    required this.subtitle,
    required this.onTap,
    this.onEditTap,
  });

  /// Mockup'ta bu kartların ikonu emoji (💧/🚩) — bkz. `sticker_style.dart`
  /// `StickerIconButton`'daki AYNI emoji tercihi.
  final String emoji;
  final String title;

  /// Ör. "5/8" — başlığın sağında, sayısal ilerleme.
  final String valueLabel;

  /// 0.0–1.0 arası, ilerleme çubuğunun dolu kısmı.
  final double progress;

  /// Çubuğun altındaki tek satırlık açıklama (ör. "3 bardak kaldı").
  final String subtitle;

  /// Karta dokununca ilgili modülü açar (bkz. `home_screen.dart`).
  final VoidCallback onTap;

  /// Verilirse kartın sağ üst köşesine küçük bir kalem rozeti eklenir —
  /// kullanıcının bu slotta hangi modülün gösterileceğini değiştirmesini
  /// sağlayan seçim sheet'ini açar (bkz. `home_quick_module_picker_sheet.
  /// dart`'taki `showHomeQuickModulePicker`). `null` ise rozet hiç
  /// gösterilmez.
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(16);

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: stickerDecoration(
              fill: colorScheme.surfaceContainerLowest,
              borderRadius: borderRadius,
              borderWidth: 3,
              shadowOffset: const Offset(3, 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      valueLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      border: Border.all(color: kStickerOutline, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: ColoredBox(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Sticker Container'ın KENDİ dolgusu OPAK olduğu için InkWell'in
          // dalga efekti altında görünmez kalır — bu yüzden dokunma alanı
          // ayrı, şeffaf bir Material katmanı olarak ÜSTÜNE ekleniyor
          // (dalga efekti böylece kartın üstünde görünür kalıyor).
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(borderRadius: borderRadius, onTap: onTap),
            ),
          ),
          if (onEditTap != null)
            Positioned(
              top: -6,
              right: -6,
              child: StickerIconButton(
                icon: Icons.edit_rounded,
                onPressed: onEditTap,
                size: 26,
                iconSize: 14,
                tooltip: AppLocalizations.of(context)!.homeQuickWidgetEditTooltip,
              ),
            ),
        ],
      ),
    );
  }
}
