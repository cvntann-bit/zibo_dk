import 'dart:ui' show Locale;

/// Manifest süsleme editörünün çerçeveleri (onaylı mockup'lar:
/// https://claude.ai/artifact/21kf1TZT3sDKqgrpkc1Pew ilk 6,
/// https://claude.ai/artifact/7NbtXQqxnpiHbbEq5ZLT5p sonraki 10). [id]'ler
/// KALICI — premium olanların sahipliği `ManifestDecorProvider`'da bu id'yle
/// saklanır. Sıra = tepsideki sıra (önce ücretsizler).
enum ManifestFrame {
  none('none'),
  polaroid('polaroid'),
  film('film'),
  washi('washi'),
  hearts('hearts'),
  notebook('notebook'),
  album('album'),
  pop('pop'),
  stamp('stamp'),
  gold('gold', price: 250),
  stars('stars', price: 250),
  floral('floral', price: 250),
  neon('neon', price: 300),
  night('night', price: 300),
  zibo('zibo', price: 350),
  royal('royal', price: 400);

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

/// Sticker sekmesindeki emoji grupları (başlıklı, kullanıcı onayı).
enum ManifestEmojiGroup {
  luck(['✨', '🌟', '💫', '⭐', '🔮', '🧿', '🍀', '🌠', '🕯️']),
  love(['💛', '❤️', '💕', '💖', '🥰', '😍', '🤍']),
  nature(['🌸', '🌻', '🌷', '🌈', '🌙', '☀️', '🦋', '🌊', '🌿']),
  goals(['🏆', '🎯', '💪', '🚀', '💰', '💎', '🏡', '✈️', '🎓', '📚']),
  party(['🎉', '🥳', '🎁', '🎈', '🍾', '🙌', '🔥']);

  const ManifestEmojiGroup(this.emojis);

  final List<String> emojis;
}

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

/// Kolaj kutusu — tuvale göre 0..1 kesirli dikdörtgen; [rotationDeg] yalnızca
/// Polaroid Duvarı'nda.
class CollageSlot {
  const CollageSlot(this.left, this.top, this.width, this.height, {this.rotationDeg = 0});

  final double left;
  final double top;
  final double width;
  final double height;
  final double rotationDeg;
}

/// Kolaj şablonları (onaylı mockup: https://claude.ai/artifact/D6AbNAeHSW4NCCVMnmakkD).
/// Hepsi ücretsiz. Izgara şablonlarında kutular arası boşluğu editör ekler.
enum CollageTemplate {
  twoStacked([CollageSlot(0, 0, 1, 0.5), CollageSlot(0, 0.5, 1, 0.5)]),
  twoSide([CollageSlot(0, 0, 0.5, 1), CollageSlot(0.5, 0, 0.5, 1)]),
  three([CollageSlot(0, 0, 1, 0.56), CollageSlot(0, 0.56, 0.5, 0.44), CollageSlot(0.5, 0.56, 0.5, 0.44)]),
  four([
    CollageSlot(0, 0, 0.5, 0.5),
    CollageSlot(0.5, 0, 0.5, 0.5),
    CollageSlot(0, 0.5, 0.5, 0.5),
    CollageSlot(0.5, 0.5, 0.5, 0.5),
  ]),
  six([
    CollageSlot(0, 0, 0.5, 1 / 3),
    CollageSlot(0.5, 0, 0.5, 1 / 3),
    CollageSlot(0, 1 / 3, 0.5, 1 / 3),
    CollageSlot(0.5, 1 / 3, 0.5, 1 / 3),
    CollageSlot(0, 2 / 3, 0.5, 1 / 3),
    CollageSlot(0.5, 2 / 3, 0.5, 1 / 3),
  ]),
  polaroidWall([
    CollageSlot(0.06, 0.05, 0.52, 0.40, rotationDeg: -6),
    CollageSlot(0.44, 0.16, 0.50, 0.38, rotationDeg: 5),
    CollageSlot(0.08, 0.52, 0.48, 0.38, rotationDeg: 4),
    CollageSlot(0.46, 0.56, 0.46, 0.36, rotationDeg: -5),
  ], isPolaroid: true);

  const CollageTemplate(this.slots, {this.isPolaroid = false});

  final List<CollageSlot> slots;
  final bool isPolaroid;

  static int get maxSlots => 6;
}

enum CollageBackground { cream, honey, gold, night, dots }
