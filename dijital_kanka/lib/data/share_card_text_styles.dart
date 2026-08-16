import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paylaşım kartında seçilebilecek tek bir yazı stili ön ayarı. [label]
/// yalnızca erişilebilirlik etiketi için kullanılır (bkz.
/// share_card_backgrounds.dart'taki aynı gerekçe — ARB'ye taşınmadı).
class ShareCardTextStyle {
  const ShareCardTextStyle({
    required this.id,
    required this.label,
    required this.style,
  });

  final String id;
  final String label;
  final TextStyle style;
}

const _white = Colors.white;
// Zibo logosuyla aynı sıcak altın tonu — arka planı ne olursa olsun kartın
// kendi kimliğiyle uyumlu kalsın diye.
const _gold = Color(0xFFF0C868);

/// Kart metninin arkasındaki yarı saydam panel her stille aynı olduğu için
/// (bkz. ZiboShareCard) yazı tipi + renk kombinasyonu, herhangi bir gradyan
/// arka planla eşleşse de her zaman okunabilir kalacak şekilde seçildi.
final shareCardTextStyles = <ShareCardTextStyle>[
  ShareCardTextStyle(
    id: 'classic',
    label: 'Klasik',
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      color: _white,
      height: 1.3,
    ),
  ),
  ShareCardTextStyle(
    id: 'bubble',
    label: 'Zibo Baloncuk',
    style: GoogleFonts.fredoka(
      fontWeight: FontWeight.w600,
      color: _gold,
      height: 1.3,
    ),
  ),
  ShareCardTextStyle(
    id: 'handwritten',
    label: 'El Yazısı',
    style: GoogleFonts.caveat(
      fontWeight: FontWeight.w700,
      color: _white,
      height: 1.2,
    ),
  ),
  ShareCardTextStyle(
    id: 'typewriter',
    label: 'Daktilo',
    style: GoogleFonts.specialElite(color: _gold, height: 1.4),
  ),
  ShareCardTextStyle(
    id: 'elegant',
    label: 'Zarif',
    style: GoogleFonts.playfairDisplay(
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      color: _white,
      height: 1.3,
    ),
  ),
];
