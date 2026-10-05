import 'package:flutter/material.dart';

// Rüya Günlüğü sayfasında Zibo'nun konuşma balonunda otomatik olarak dönen
// sözlerin havuzu — gerçek bir içerik kaynağı (backend/CMS) hazır olana
// kadar uygulama içinde sabit olarak tutulur (bkz. zibo_messages.dart'taki
// aynı yaklaşım). Üç dilde de "kanka"/"buddy"/"amigo" sıcaklığını koruyan,
// birebir değil doğal çeviriler — bkz. [dreamQuotesForLocale].
const dreamQuotesTr = <String>[
  'Rüyalar bazen kafamızın attığı notlardır, yaz bakalım bugün ne gördün.',
  'Kanka unutmadan yaz, rüyalar sabah kahvesiyle birlikte uçup gidiyor.',
  'Bugün gördüğün rüya belki de aklının sana bir mektubudur.',
  'Garip bir rüya mı gördün? Yazınca daha bir anlam kazanır.',
  'Kanka rüya günlüğü tutmak, kendinle sohbet etmenin bir yolu.',
  'Bugün gördüğün rüyayı yazmazsan yarın hatırlaman zor olur.',
  'Rüyalar bazen korkularımızı, bazen umutlarımızı fısıldar.',
  'Kanka o rüyadaki detayı unutmadan hemen buraya not et.',
  'Bir rüya, uyanıkken söyleyemediğin şeyleri söyler bazen.',
  'Bugün ne gördüysen yaz, ileride okuyunca gülümseyeceksin.',
];

const dreamQuotesEn = <String>[
  'Dreams are sometimes notes your mind jots down — write down what you saw today.',
  "Buddy, write it down before you forget — dreams fly away with the morning coffee.",
  "Today's dream might just be a letter from your own mind.",
  'Had a weird dream? Writing it down gives it more meaning.',
  'Buddy, keeping a dream journal is a way of talking to yourself.',
  "If you don't write down today's dream, you'll struggle to remember it tomorrow.",
  'Dreams sometimes whisper our fears, sometimes our hopes.',
  'Buddy, jot down that detail from the dream before it slips away.',
  "A dream sometimes says the things you can't say while awake.",
  "Write down whatever you saw today — you'll smile reading it later.",
];

const dreamQuotesEs = <String>[
  'Los sueños a veces son notas que apunta tu mente — anota qué viste hoy.',
  'Amigo, anótalo antes de que se te olvide, los sueños se van volando con el café de la mañana.',
  'El sueño de hoy quizás sea una carta que te escribe tu propia mente.',
  '¿Tuviste un sueño raro? Al escribirlo cobra más sentido.',
  'Amigo, llevar un diario de sueños es una forma de hablar contigo mismo.',
  'Si no escribes el sueño de hoy, mañana te costará recordarlo.',
  'Los sueños a veces susurran nuestros miedos, a veces nuestras esperanzas.',
  'Amigo, anota ese detalle del sueño antes de que se te escape.',
  'Un sueño a veces dice las cosas que no puedes decir despierto.',
  'Escribe lo que hayas soñado hoy — más adelante sonreirás al leerlo.',
];

/// Kullanıcının seçtiği dile (bkz. `LocaleProvider`) göre söz havuzu —
/// desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
List<String> dreamQuotesForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => dreamQuotesEn,
  'es' => dreamQuotesEs,
  _ => dreamQuotesTr,
};
