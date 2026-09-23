import 'package:flutter/material.dart' show Locale;

/// Paywall'ın konuşma balonunda dönüşümlü gösterilen kısa teşvik cümleleri
/// — diğer TÜM söz havuzlarıyla (bkz. `lib/l10n/CLAUDE.md` "ARB'ye ait
/// OLMAYAN metinler") AYNI desen: üç dil BİREBİR aynı uzunlukta, index
/// tabanlı seçim. `PaywallScreen` bir `Timer.periodic` ile döngüsel olarak
/// ilerletir (ör. `manifest_journal_screen.dart`'ın `_showNewQuote`'uyla
/// AYNI "birkaç saniyede bir yeni söz" deseni).
const paywallQuotesTr = [
  'Pro ile birlikte çok daha fazlasını keşfedelim!',
  'Bu adımı birlikte atalım, Kanka!',
  'Zibo Pro ile her gün biraz daha güçlüsün.',
  'Hazırsan, bir sonraki seviyeye geçelim!',
];

const paywallQuotesEn = [
  "Let's discover so much more together with Pro!",
  "Let's take this step together, buddy!",
  'With Zibo Pro, you get a little stronger every day.',
  "If you're ready, let's level up!",
];

const paywallQuotesEs = [
  '¡Descubramos mucho más juntos con Pro!',
  '¡Demos este paso juntos, amigo!',
  'Con Zibo Pro, te haces un poco más fuerte cada día.',
  '¡Si estás listo, subamos de nivel!',
];

List<String> paywallQuotesForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return paywallQuotesEn;
    case 'es':
      return paywallQuotesEs;
    default:
      return paywallQuotesTr;
  }
}
