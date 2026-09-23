import 'package:flutter/material.dart' show Locale;

/// Paywall'daki Ücretsiz/Pro/Pro+ karşılaştırma tablosunun TEK satırı —
/// `docs/subscribe_model.md`'nin "Perk uygulama durumu" tablosuyla
/// ÇAPRAZ KONTROL edilmiş, GERÇEKTEN kodda uygulanmış ayrımlar (bkz. sınıf
/// dokümantasyonu, `paywall_screen.dart`). **Bilerek DIŞARIDA bırakılanlar**
/// (yanlış/yanıltıcı reklam riski taşıdıkları için): "Bildirim saatini
/// kişiselleştir" (Pro perk metni var ama hiç implement edilmedi) ve "Ayda 1
/// Pro'ya özel kostüm/tema" (Pro+ — kullanıcı kararıyla asla eklenmeyecek,
/// kapsam dışı).
class PaywallComparisonRow {
  const PaywallComparisonRow({
    required this.label,
    required this.free,
    required this.pro,
    required this.proPlus,
  });

  final String label;
  final String free;
  final String pro;
  final String proPlus;
}

const paywallComparisonRowsTr = [
  PaywallComparisonRow(
    label: 'Reklamsız kullanım',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Check-in coin çarpanı',
    free: '1x',
    pro: '1,5x',
    proPlus: '2x',
  ),
  PaywallComparisonRow(
    label: 'Aylık ücretsiz Streak Freeze',
    free: '0',
    pro: '1',
    proPlus: '3',
  ),
  PaywallComparisonRow(
    label: 'Şans Çarkı reklamsız + ekstra çevirme',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Modül geçmişi',
    free: '30 gün',
    pro: 'Sınırsız',
    proPlus: 'Sınırsız',
  ),
  PaywallComparisonRow(
    label: 'Özel profil çerçevesi',
    free: '✗',
    pro: 'Pro',
    proPlus: 'Pro+',
  ),
  PaywallComparisonRow(
    label: 'Ruh Hali & Para gelişmiş analiz',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Özel bildirim sesleri',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
];

const paywallComparisonRowsEn = [
  PaywallComparisonRow(
    label: 'Ad-free experience',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Check-in coin multiplier',
    free: '1x',
    pro: '1.5x',
    proPlus: '2x',
  ),
  PaywallComparisonRow(
    label: 'Free Streak Freezes per month',
    free: '0',
    pro: '1',
    proPlus: '3',
  ),
  PaywallComparisonRow(
    label: 'Ad-free Lucky Wheel + extra spin',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Module history',
    free: '30 days',
    pro: 'Unlimited',
    proPlus: 'Unlimited',
  ),
  PaywallComparisonRow(
    label: 'Custom profile frame',
    free: '✗',
    pro: 'Pro',
    proPlus: 'Pro+',
  ),
  PaywallComparisonRow(
    label: 'Advanced Mood & Money analytics',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Exclusive notification sounds',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
];

const paywallComparisonRowsEs = [
  PaywallComparisonRow(
    label: 'Uso sin anuncios',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Multiplicador de monedas al iniciar sesión',
    free: '1x',
    pro: '1,5x',
    proPlus: '2x',
  ),
  PaywallComparisonRow(
    label: 'Congelaciones de racha gratis al mes',
    free: '0',
    pro: '1',
    proPlus: '3',
  ),
  PaywallComparisonRow(
    label: 'Rueda de la Suerte sin anuncios + giro extra',
    free: '✗',
    pro: '✓',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Historial de módulos',
    free: '30 días',
    pro: 'Ilimitado',
    proPlus: 'Ilimitado',
  ),
  PaywallComparisonRow(
    label: 'Marco de perfil especial',
    free: '✗',
    pro: 'Pro',
    proPlus: 'Pro+',
  ),
  PaywallComparisonRow(
    label: 'Análisis avanzado de Ánimo y Dinero',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
  PaywallComparisonRow(
    label: 'Sonidos de notificación exclusivos',
    free: '✗',
    pro: '✗',
    proPlus: '✓',
  ),
];

List<PaywallComparisonRow> paywallComparisonRowsForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return paywallComparisonRowsEn;
    case 'es':
      return paywallComparisonRowsEs;
    default:
      return paywallComparisonRowsTr;
  }
}
