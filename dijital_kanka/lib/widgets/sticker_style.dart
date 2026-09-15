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
/// çizen dairesel buton. Ana Sayfa'nın konuşma balonu köşesindeki paylaş/
/// favori/özel-mesaj butonları ile RootScreen AppBar'ındaki mağaza/ayarlar/
/// kupa ikonları bunu paylaşır.
class StickerCircleButton extends StatelessWidget {
  const StickerCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 36,
    this.iconSize = 18,
    this.borderWidth = 2.5,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = backgroundColor ?? colorScheme.primary;
    final fg = iconColor ?? colorScheme.onPrimary;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(2, 2))],
      ),
      child: Material(
        color: fill,
        shape: CircleBorder(
          side: BorderSide(color: kStickerOutline, width: borderWidth),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
