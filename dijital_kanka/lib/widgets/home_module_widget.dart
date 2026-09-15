import 'package:flutter/material.dart';

import 'sticker_style.dart';

/// Ana Sayfa'nın konuşma balonu ile alt bar arasına, "Çizgi Roman
/// Çıkartması" mockup'ında onaylanan iki mini kart (Su/Hedef) için ortak
/// görsel — bkz. `docs/theme_new.md` "Onaylanan: Ana Sayfa yerleşimi",
/// madde 7 ("YENİ" olarak işaretli özellik).
///
/// Kontur/gölge SABİT (bkz. `sticker_style.dart`); ilerleme çubuğunun
/// dolgusu ve "YENİ" rozeti aktif temanın `colorScheme.primary`'sinden
/// gelir — böylece kullanıcı Mağaza'dan farklı bir tema satın alırsa bu
/// kartlar da otomatik uyum sağlar.
class HomeModuleWidget extends StatelessWidget {
  const HomeModuleWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.progress,
    required this.subtitle,
    required this.newBadgeLabel,
    this.isNew = true,
  });

  final IconData icon;
  final String title;

  /// Ör. "5/8" — başlığın sağında, sayısal ilerleme.
  final String valueLabel;

  /// 0.0–1.0 arası, ilerleme çubuğunun dolu kısmı.
  final double progress;

  /// Çubuğun altındaki tek satırlık açıklama (ör. "3 bardak kaldı").
  final String subtitle;

  /// "YENİ" rozetinin metni — çağıran taraf `AppLocalizations`'tan geçirir
  /// (bu widget kendi başına l10n'e bağımlı olmasın diye).
  final String newBadgeLabel;

  /// Ana Sayfa'ya YENİ eklenen bu kartların üstüne, kullanıcı tanıdık
  /// gelene kadar bir "YENİ" rozeti eklenir.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: stickerDecoration(
              fill: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
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
                          Icon(icon, size: 15, color: colorScheme.onSurface),
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
          if (isNew)
            Positioned(
              top: -10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: stickerDecoration(
                  fill: colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                  borderWidth: 2,
                  shadowOffset: Offset.zero,
                ),
                child: Text(
                  newBadgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
