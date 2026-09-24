import 'dart:ui' show Locale;

/// Manifest süsleme editörünün çerçeveleri (onaylı mockup:
/// https://claude.ai/artifact/21kf1TZT3sDKqgrpkc1Pew). [id]'ler KALICI —
/// premium olanların sahipliği `ManifestDecorProvider`'da bu id'yle saklanır.
enum ManifestFrame {
  none('none'),
  polaroid('polaroid'),
  film('film'),
  washi('washi'),
  gold('gold', price: 250),
  stars('stars', price: 250);

  const ManifestFrame(this.id, {this.price = 0});

  final String id;

  /// 0 → ücretsiz. Premium çerçeveler Zibo Coin ile BİR KEZ açılır
  /// (kullanıcı kararı 2026-09-24).
  final int price;

  bool get isPremium => price > 0;
}

/// Editörde herkese açık Zibo sticker pozları. Kostümlü Zibo sticker'ları
/// ayrıca `costumes` listesinden, YALNIZCA sahip olunan kostümler için açılır.
const freeZiboStickerAssets = [
  'assets/images/zibo_df_pose3.webp',
  'assets/images/zibo_df_pose1.webp',
  'assets/images/zibo_df_pose2.webp',
  'assets/images/zibo_df_pose4.webp',
  'assets/images/zibo_df_pose5.webp',
];

const manifestEmojiStickers = ['✨', '💛', '⭐', '🌙', '🌈', '🦋', '🍀'];

/// Editörün "Yazı" sekmesindeki hazır olumlamalar — içerik havuzu deseni
/// (`xTr/xEn/xEs` + `xForLocale`, üç dil BİREBİR aynı uzunlukta).
const manifestAffirmationsTr = [
  'Oluyor ✨',
  'Hak ediyorum',
  'Evrene güveniyorum',
  'Bu benim yılım',
  'Bolluk bana akıyor',
];

const manifestAffirmationsEn = [
  "It's happening ✨",
  'I deserve it',
  'I trust the universe',
  'This is my year',
  'Abundance flows to me',
];

const manifestAffirmationsEs = [
  'Está pasando ✨',
  'Me lo merezco',
  'Confío en el universo',
  'Este es mi año',
  'La abundancia fluye hacia mí',
];

List<String> manifestAffirmationsForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return manifestAffirmationsEn;
    case 'es':
      return manifestAffirmationsEs;
    default:
      return manifestAffirmationsTr;
  }
}
