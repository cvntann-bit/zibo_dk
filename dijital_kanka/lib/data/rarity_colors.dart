import 'package:flutter/material.dart';

import '../models/costume_rarity.dart';

/// Nadirlik renklerinin TEK tanım yeri — mağaza kartı, gruplar, dolap, rozet
/// ödül penceresi vb. HEP buradan okur; başka bir yerde renk kodu yazılmaz.
///
/// Çerçeve renkleri (kullanıcının belirlediği):
///   Yaygın #9E9E9E (gri) · Nadir #2196F3 (mavi) · Epik #9C27B0 (mor)
///   Efsanevi #FFC107 (altın) · Mitik #FF6A00 (turuncu + hafif parlama)
///
/// Açık/koyu tema notu: çerçeve ve dolgu olarak renkler OLDUĞU GİBİ kullanılır
/// (hem krem hem koyu zeminde görünür). Metin olarak kullanıldığında ise
/// ([labelColor]) açık zeminde altın/turuncu/gri okunmaz → açık temada
/// koyulaştırılır, koyu temada aydınlatılır.
class RarityStyle {
  const RarityStyle._(this.color, {this.glow = false});

  /// Çerçeve / dolgu rengi.
  final Color color;

  /// Mitik kademede kartın etrafına hafif parlama (glow) eklenir.
  final bool glow;

  static const _common = RarityStyle._(Color(0xFF9E9E9E));
  static const _rare = RarityStyle._(Color(0xFF2196F3));
  static const _epic = RarityStyle._(Color(0xFF9C27B0));
  static const _legendary = RarityStyle._(Color(0xFFFFC107));
  static const _mythic = RarityStyle._(Color(0xFFFF6A00), glow: true);

  static RarityStyle of(CostumeRarity rarity) => switch (rarity) {
    CostumeRarity.common => _common,
    CostumeRarity.rare => _rare,
    CostumeRarity.epic => _epic,
    CostumeRarity.legendary => _legendary,
    CostumeRarity.mythic => _mythic,
  };

  /// Renkli bir dolgunun (ör. nadirlik etiketi) ÜZERİNDEKİ yazı rengi.
  ///
  /// Beyaz ile koyu mürekkep arasından GERÇEK kontrast oranı yüksek olan seçilir
  /// (`estimateBrightnessForColor` tahmini Nadir/mavide beyazı seçip 3.1:1'de kalıyordu).
  Color get onColor {
    const ink = Color(0xFF14110C);
    return _contrast(Colors.white, color) >= _contrast(ink, color)
        ? Colors.white
        : ink;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Nadirlik renginde YAZI gerektiğinde (düz zeminde) okunur ton. Açık temada
  /// koyulaştırılır (altın/turuncu/gri açık zeminde kontrastsız), koyu temada
  /// aydınlatılır (mor/mavi koyu zeminde kontrastsız).
  Color labelColor(Brightness brightness) {
    final hsl = HSLColor.fromColor(color);
    final lightness = brightness == Brightness.light
        ? hsl.lightness.clamp(0.0, 0.36)
        : hsl.lightness.clamp(0.62, 1.0);
    return hsl.withLightness(lightness.toDouble()).toColor();
  }

  /// Kart gölgeleri: Mitik'te renkli parlama; diğerlerinde boş.
  List<BoxShadow> get glowShadows => glow
      ? [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ]
      : const [];
}
