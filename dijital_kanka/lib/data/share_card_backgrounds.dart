import 'package:flutter/material.dart';

/// Paylaşım kartında seçilebilecek tek bir gradyan arka plan ön ayarı.
/// [label] yalnızca swatch'ın erişilebilirlik (ekran okuyucu) etiketi için
/// kullanılır — zibo_messages.dart/money_quotes.dart'taki içerik havuzlarıyla
/// aynı gerekçeyle ARB'ye taşınmadı (bkz. CLAUDE.md "Yerelleştirme").
class ShareCardBackground {
  const ShareCardBackground({
    required this.id,
    required this.label,
    required this.gradient,
  });

  final String id;
  final String label;
  final LinearGradient gradient;
}

/// Kullanıcının serbestçe renk seçmesi yerine, logo/metin kontrastını her
/// zaman koruyan, elle seçilmiş bir gradyan listesi. İlk ikisi uygulamanın
/// kendi bal/hardal paletiyle uyumlu; geri kalanı kişiselleştirme için canlı
/// alternatifler.
final shareCardBackgrounds = <ShareCardBackground>[
  const ShareCardBackground(
    id: 'espresso',
    label: 'Gece Kahvesi',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF231F19), Color(0xFF4A3620)],
    ),
  ),
  const ShareCardBackground(
    id: 'honey',
    label: 'Bal',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFCB7A), Color(0xFFA9711F)],
    ),
  ),
  const ShareCardBackground(
    id: 'sunset',
    label: 'Gün Batımı',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
    ),
  ),
  const ShareCardBackground(
    id: 'ocean',
    label: 'Okyanus',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    ),
  ),
  const ShareCardBackground(
    id: 'berry',
    label: 'Üzüm',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC94B4B), Color(0xFF4B134F)],
    ),
  ),
  const ShareCardBackground(
    id: 'forest',
    label: 'Orman',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
    ),
  ),
  const ShareCardBackground(
    id: 'peach',
    label: 'Şeftali',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFAFBD), Color(0xFFFFC3A0)],
    ),
  ),
  const ShareCardBackground(
    id: 'midnight',
    label: 'Gece Mavisi',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ),
  ),
];
