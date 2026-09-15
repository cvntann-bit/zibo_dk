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

/// Mockup'ın `--gold-deep` değişkeni — bonus/vurgu metinleri gibi normal
/// altından biraz daha koyu bir ton gerektiren yerlerde (bkz. Mağaza'nın
/// coin paketi kartlarındaki "+N bonus" etiketi). Tema-bağımsız SABİT.
const kGoldDeep = Color(0xFFDC8F1E);

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

/// Ayarlar'dan başlayıp Rüya/Şükran/Ruh Hali/Su/Manifest/Para/Odak
/// modüllerinin HEPSİNİN paylaştığı "push ekranı" AppBar'ı — geri oku
/// ([StickerIconButton], gerçek `MaterialLocalizations` tooltip'iyle) +
/// Baloo2 başlık + 3px kalın alt çizgi. `RootScreen`'in sekmelerin
/// paylaştığı logo/coin/mağaza/ayarlar AppBar'ından BİLEREK FARKLI (bkz.
/// her modülün `docs/theme_new.md`'deki "sade push AppBar'ı" notu) —
/// `AppBar` gerçek türünü DEĞİŞTİRMEDEN (Scaffold.appBar için gereken
/// `PreferredSizeWidget` zaten `AppBar`'ın kendisi) sadece stilini/
/// leading'ini/alt çizgisini özelleştiren bir fabrika fonksiyonu.
PreferredSizeWidget plainStickerAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return AppBar(
    backgroundColor: colorScheme.surfaceContainerLowest,
    leadingWidth: 62,
    titleSpacing: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: StickerIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          backgroundColor: colorScheme.surfaceContainerLowest,
          iconColor: kStickerOutline,
          size: 34,
          iconSize: 16,
          borderRadius: null,
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: [FontVariation('wght', 800)],
        fontSize: 18,
      ),
    ),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(3),
      child: Container(height: 3, color: kStickerOutline),
    ),
  );
}

/// Bir satırı; sol tarafta altın (veya özel) dolgulu emoji dairesi, ortada
/// başlık+alt metin, sağda köşeli ">" (›) butonuyla gösteren paylaşılan
/// kart — Profil'in "Zibo ile Bağın"/"İstatistiklerim" satırları, Kostüm
/// Dolabı üst satırı gibi TEKRARLANAN satır deseninin tek kaynağı (bkz.
/// `docs/theme_new.md` "Onaylanan: Profil sekmesi"). [onTap] `null` ise
/// (ör. Odak Süresi satırı) sağdaki köşeli ok da otomatik gizlenir — mockup
/// bu durumda oku TAMAMEN kaldırıyor, dokunulamaz olduğunu ima ediyor.
class StickerRowCard extends StatelessWidget {
  const StickerRowCard({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
    this.iconBackground,
    this.trailingChild,
  });

  final String emoji;
  final String title;
  final String? subtitle;

  /// [subtitle]'ın tek-satır `Text`'i YETMEDİĞİNDE (ör. Rüya Günlüğü'nün
  /// tarih + koşullu italik ruh-hali notu iki satırı) tam kontrol veren
  /// alternatif — verilirse [subtitle] YOK SAYILIR.
  final Widget? subtitleWidget;
  final VoidCallback? onTap;

  /// Varsayılan altın (`colorScheme.primary`) — Google bağlama satırı gibi
  /// istisnalar için override edilebilir (mockup'ta beyaz zeminli).
  final Color? iconBackground;

  /// Sağ kenara, ok yerine/yanına EK bir widget (ör. Kostüm Dolabı'nın alt
  /// satırındaki yatay önizleme şeridi kartın GÖVDESİNE ait, bu alana değil
  /// — bu alan yalnızca tek-satırlık satırlar için).
  final Widget? trailingChild;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);

    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: radius,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: stickerCircleDecoration(
              fill: iconBackground ?? colorScheme.primary,
              borderWidth: 2.5,
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 2),
                  subtitleWidget!,
                ] else if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingChild != null) trailingChild!,
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: kStickerOutline, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '›',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(borderRadius: radius, onTap: onTap),
          ),
        ),
      ],
    );
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

/// Bir çocuğun ALT kenarına kesikli (dashed) tek bir çizgi çizer — Profil'in
/// isim alanı mockup'ta `border-bottom:2.5px dashed` kullanıyor (tam bir
/// dashed dikdörtgen DEĞİL, yalnızca alt çizgi) — bu yüzden
/// [DashedStickerButton]'ın köşeli-dikdörtgen [_DashedBorderPainter]'ından
/// AYRI, daha basit düz-çizgi bir painter.
class DashedUnderline extends StatelessWidget {
  const DashedUnderline({
    super.key,
    required this.child,
    this.color = kStickerOutline,
    this.strokeWidth = 2.5,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedLinePainter(color: color, strokeWidth: strokeWidth),
      child: child,
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const dashWidth = 6.0;
    const dashGap = 5.0;
    final y = size.height - strokeWidth / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dashWidth).clamp(0, size.width), y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Mağaza'nın "Sahip olunan"/"Giyili"/"Aktif" rozetleri — mockup'ın
/// `.status-pill` (bkz. `docs/theme_new.md` "Onaylanan: Mağaza" bölümleri).
/// [filled] `false` = beyaz zemin ("Sahip olunan"), `true` = altın zemin
/// ("Giyili"/"Aktif").
class StickerStatusPill extends StatelessWidget {
  const StickerStatusPill({super.key, required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? colorScheme.primary : colorScheme.surfaceContainerLowest,
        border: Border.all(color: kStickerOutline, width: 2.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✓',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: filled ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          // `label` KENDİ Text widget'ı olarak KALIYOR (checkmark'la aynı
          // string'e BİRLEŞTİRİLMİYOR) — `widget_test.dart`'ın birçok yeri
          // `find.text('Sahip olunan')`/`find.text('Giyili')`/`find.text(
          // 'Aktif')` ile TAM eşleşme arıyor (bkz. o dosyadaki satırlar).
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: filled ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mağaza'daki tüm "Satın Al"/"İzle" butonlarının paylaştığı sticker stili —
/// bilerek gerçek [FilledButton]'ı DEĞİŞTİRMİYOR (yalnızca `style:` ve bir
/// dış gölge sarmalayıcısı ekliyor) çünkü `widget_test.dart`'ın onlarca yeri
/// `find.byType(FilledButton)` ile bu butonu ARIYOR — sıfırdan özel bir
/// widget yazmak o testlerin hepsini kırardı.
ButtonStyle stickerFilledButtonStyle(
  BuildContext context, {
  double radius = 10,
  double fontSize = 12.5,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
    disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.7),
    side: const BorderSide(color: kStickerOutline, width: 2.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 10),
    textStyle: TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: const [FontVariation('wght', 700)],
      fontSize: fontSize,
    ),
  );
}

/// [stickerFilledButtonStyle] ile stillenen bir butonun (veya herhangi bir
/// çocuğun) ALTINA sticker'ın düz ofsetli gölgesini ekler — `FilledButton`'ın
/// kendi `elevation`'ı BULANIK bir Material gölgesi ürettiği için (bkz.
/// `stickerFilledButtonStyle`'daki `elevation:0`), gerçek "kesilmiş sticker"
/// hissi bu ayrı, düz `BoxShadow` ile sağlanıyor.
Widget stickerButtonShadow({required Widget child, double radius = 10}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(2, 2))],
    ),
    child: child,
  );
}
