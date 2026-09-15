import 'package:flutter/material.dart';

/// Zibo'nun yeni "Çizgi Roman Çıkartması" görsel diline (bkz.
/// `docs/theme_new.md`) ait paylaşılan yapı taşları: kalın, SABİT bir dış
/// kontur + bulanıksız/düz ofsetli bir "sticker" gölgesi. Bu iki öğe hangi
/// satın alınabilir tema aktif olursa olsun HİÇ değişmez — yalnızca dolgu
/// (fill) renkleri `ColorScheme` üzerinden gelmeye devam eder (bkz.
/// `theme_new.md` "Kritik kural — tema uyumluluğu" bölümü).
///
/// Ekranlar bu dosyadaki [kStickerOutline]/[stickerDecoration]'ı DOĞRUDAN
/// kullanabilir (ör. bir `Container`ın `decoration`'ı için) ya da hazır
/// [StickerCircleButton]'ı çoğaltabilir — yeni bir ekran restyle edilirken
/// kendi kontur/gölge sabitlerini ELLE tekrar yazmak YERİNE bunlar
/// kullanılmalı, aksi halde tonlar zamanla birbirinden sapar.
const kStickerOutline = Color(0xFF14110C);

/// "Kaçırıldı" gibi tek bir durum göstergesi için donuk/kahverengimsi sarı —
/// mockup'ın `--accent-muted` değişkeniyle birebir (bkz. `docs/theme_new.md`
/// "Onaylanan: Hedefler sekmesi" — 2026-09-15'te mavi/mercan yerine tek-vurgu
/// ailesinden bu ton kullanılmaya başlandı). Tema-bağımsız SABİT bir ton
/// (kostüm/tema rengine göre değişmez) — [kStickerOutline] ile AYNI gerekçe.
const kAccentMuted = Color(0xFFC9A46B);

/// Köşeli/yuvarlak bir dikdörtgen (kart, hap/pill, buton) için kalın kontur +
/// düz ofsetli gölge üreten paylaşılan dekorasyon. [fill] dışındaki her şey
/// SABİTTİR — [fill] çağıran taraftan (genelde `colorScheme`'den) gelmeli.
BoxDecoration stickerDecoration({
  required Color fill,
  BorderRadius? borderRadius,
  double borderWidth = 3,
  Offset shadowOffset = const Offset(4, 4),
  Color outline = kStickerOutline,
}) {
  return BoxDecoration(
    color: fill,
    borderRadius: borderRadius ?? BorderRadius.circular(20),
    border: Border.all(color: outline, width: borderWidth),
    // BoxShadow'un varsayılan blurRadius'u 0 — bu satır KASITLI olarak
    // blur EKLEMİYOR, klasik Material gölgesinden farklı, "kesilmiş
    // sticker" hissi veren düz bir kopya üretiyor.
    boxShadow: [BoxShadow(color: outline, offset: shadowOffset)],
  );
}

/// Dairesel bir buton/rozet için AYNI kontur+gölge dilini üreten dekorasyon.
BoxDecoration stickerCircleDecoration({
  required Color fill,
  double borderWidth = 2.5,
  Offset shadowOffset = const Offset(2, 2),
  Color outline = kStickerOutline,
}) {
  return BoxDecoration(
    color: fill,
    shape: BoxShape.circle,
    border: Border.all(color: outline, width: borderWidth),
    boxShadow: [BoxShadow(color: outline, offset: shadowOffset)],
  );
}

/// `IconButton.filled` ile AYNI kullanım biçimini (ikon + `onPressed` +
/// `tooltip`) korurken, çıktıyı kalın kontur + düz ofsetli sticker gölgesiyle
/// çizen buton. Onaylanan Ana Sayfa mockup'ında ([docs/theme_new.md]) bu
/// butonların HİÇBİRİ tam daire DEĞİL — hafif yuvarlatılmış kare
/// ("squircle", `.icon-btn` 30x30/radius 9, `.mini-btn` 26x26/radius 8,
/// `.nav-badge` 36x36/radius 10) — [borderRadius] bu yüzden `null`
/// (tam daire) yerine VARSAYILAN olarak sağlanmalı; yalnızca gerçekten
/// dairesel bir öğe (ör. Z butonu, ayrı olarak [stickerCircleDecoration]
/// kullanıyor) için `null` bırakılır.
class StickerIconButton extends StatelessWidget {
  const StickerIconButton({
    super.key,
    this.icon,
    this.emoji,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 36,
    this.iconSize = 18,
    this.borderWidth = 2.5,
    this.borderRadius = 10,
  }) : assert(
         (icon == null) != (emoji == null),
         'icon veya emoji tam olarak birinden biri sağlanmalı',
       );

  /// Mockup'ta bazı butonlar (`.icon-btn`) Material ikon, bazıları
  /// (`.mini-btn`/`.nav-badge`/`.corner-btn`) emoji kullanıyor — bu yüzden
  /// [icon]/[emoji] karşılıklı dışlayıcı: TAM OLARAK biri sağlanmalı.
  final IconData? icon;
  final String? emoji;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderWidth;

  /// `null` verilirse tam daire (`CircleBorder`), aksi halde bu değerde
  /// yuvarlatılmış köşeli bir kare (`RoundedRectangleBorder`).
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = backgroundColor ?? colorScheme.primary;
    final fg = iconColor ?? colorScheme.onPrimary;
    final radius = borderRadius;

    final shape = radius == null
        ? CircleBorder(side: BorderSide(color: kStickerOutline, width: borderWidth))
        : RoundedRectangleBorder(
            side: BorderSide(color: kStickerOutline, width: borderWidth),
            borderRadius: BorderRadius.circular(radius),
          );
    final decorationShape = radius == null ? BoxShape.circle : BoxShape.rectangle;
    final decorationRadius = radius == null ? null : BorderRadius.circular(radius);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: decorationShape,
        borderRadius: decorationRadius,
        boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(2, 2))],
      ),
      child: Material(
        color: fill,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: iconSize, color: fg)
                  : Text(emoji!, style: TextStyle(fontSize: iconSize, height: 1)),
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Bir listeye yeni öğe eklemek için kesikli (dashed) konturlu, "buraya yeni
/// bir şey eklenir" hissi veren buton — mockup'ta Hedefler sekmesinin
/// `.add-goal` butonu (bkz. `docs/theme_new.md`). Düz `stickerDecoration`'dan
/// FARKLI olarak SABİT kontur `BoxDecoration.border` ile çizilemediği için
/// (Flutter'da dashed border yerleşik değil) bir [CustomPainter] kullanır.
class DashedStickerButton extends StatelessWidget {
  const DashedStickerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emoji = '➕',
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback onPressed;
  final String emoji;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: CustomPaint(
          painter: _DashedBorderPainter(borderRadius: borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.borderRadius,
    this.color = kStickerOutline,
    this.strokeWidth = 3,
    this.dashWidth = 6,
    this.dashGap = 5,
  });

  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    ).deflate(strokeWidth / 2);
    final outline = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashGap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
