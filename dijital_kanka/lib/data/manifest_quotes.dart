import 'package:flutter/material.dart';

// Manifest Günlüğü sayfasında Zibo'nun konuşma balonunda otomatik olarak
// dönen sözlerin havuzu (bkz. water_quotes.dart'taki aynı yaklaşım). Üç
// dilde de samimi tonu koruyan, birebir değil doğal çeviriler.
const manifestQuotesTr = <String>[
  'Bugün ne manifest ediyorsun kanka?',
  'Hayalini yazmak, ona ilk adımı atmaktır.',
  'Kanka bir fotoğraf seç, niyetini ona bağla.',
  'Bugün neye inanıyorsan, ona bir adım daha yaklaşırsın.',
  'Vizyon panon büyüdükçe, hayallerin de büyür.',
  'Kanka bugünkü niyetin yarının gerçeği olabilir.',
  'Küçük bir cümle, büyük bir hayalin başlangıcı olabilir.',
  'Bugün kendine ne diliyorsun, onu buraya yaz.',
  'Kanka her gün bir tuğla, vizyon panon kendi yükselir.',
  'Hayal etmek ücretsiz, ona inanmak cesaret ister.',
  'Bugün bir fotoğraf, bir niyet — geleceğine bir mektup.',
  'Kanka geçmiş vizyonlarına bak, ne kadar yol katettin gör.',
  'İnandığın şey, peşinden gittiğin şey olur.',
  'Bugün kendine bir hayal hediye et.',
  'Kanka manifest etmek, önce inanmakla başlar.',
];

const manifestQuotesEn = <String>[
  'What are you manifesting today, buddy?',
  'Writing down a dream is the first step toward it.',
  'Buddy, pick a photo and tie your intention to it.',
  "Whatever you believe today, you get one step closer to it.",
  'As your vision board grows, so do your dreams.',
  "Buddy, today's intention could be tomorrow's reality.",
  'One small sentence can be the start of a big dream.',
  'Write down here what you wish for yourself today.',
  "Buddy, one brick a day and your vision board builds itself.",
  "Dreaming is free, believing in it takes courage.",
  'A photo and an intention today — a letter to your future.',
  "Buddy, look back at your past visions, see how far you've come.",
  'What you believe becomes what you chase.',
  'Gift yourself a dream today.',
  'Buddy, manifesting starts with believing first.',
];

const manifestQuotesEs = <String>[
  '¿Qué estás manifestando hoy, amigo?',
  'Escribir un sueño es el primer paso hacia él.',
  'Amigo, elige una foto y átale tu intención.',
  'Lo que creas hoy, te acerca un paso más a ello.',
  'Mientras tu tablero de visión crece, también crecen tus sueños.',
  'Amigo, la intención de hoy puede ser la realidad de mañana.',
  'Una frase pequeña puede ser el inicio de un gran sueño.',
  'Escribe aquí lo que deseas para ti hoy.',
  'Amigo, un ladrillo al día y tu tablero de visión se construye solo.',
  'Soñar es gratis, creer en ello requiere valentía.',
  'Una foto y una intención hoy — una carta a tu futuro.',
  'Amigo, mira tus visiones pasadas y ve cuánto has avanzado.',
  'Lo que crees se convierte en lo que persigues.',
  'Regálate un sueño hoy.',
  'Amigo, manifestar empieza por creer primero.',
];

/// Kullanıcının seçtiği dile (bkz. `LocaleProvider`) göre söz havuzu —
/// desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
List<String> manifestQuotesForLocale(Locale locale) =>
    switch (locale.languageCode) {
      'en' => manifestQuotesEn,
      'es' => manifestQuotesEs,
      _ => manifestQuotesTr,
    };
