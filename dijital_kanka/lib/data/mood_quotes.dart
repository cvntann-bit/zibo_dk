import 'package:flutter/material.dart';

// Günlük Ruh Hali Takibi sayfasında Zibo'nun konuşma balonunda otomatik
// olarak dönen sözlerin havuzu (bkz. gratitude_quotes.dart'taki aynı
// yaklaşım). Üç dilde de samimi tonu koruyan, birebir değil doğal çeviriler.
const moodQuotesTr = <String>[
  'Bugün nasıl hissediyorsun kanka?',
  'Kanka bugünü bir emoji ile özetlesen hangisi olurdu?',
  'Ruh halini yazmak, onu anlamanın ilk adımı.',
  'Bugün kötüysen de olur, yarın başka bir gün.',
  'Kanka duygularını görmezden gelme, küçük bir işaretle bile olsa kaydet.',
  'Bugün kendine nasıl hissettiğini sormayı unutma.',
  'Her gün aynı hissetmek zorunda değilsin, bu normal.',
  'Kanka bir haftalık ruh haline bakmak bazen çok şey anlatır.',
  'Bugün iyiysen bunu da bir yere yazmaya değer.',
  'Duygularını takip etmek, kendine gösterdiğin bir özen.',
];

const moodQuotesEn = <String>[
  'How are you feeling today, buddy?',
  'Buddy, if you had to sum up today in one emoji, which would it be?',
  'Writing down your mood is the first step to understanding it.',
  "It's okay if today was bad — tomorrow's a different day.",
  "Buddy, don't ignore your feelings — log them, even with just a small mark.",
  "Don't forget to ask yourself how you're feeling today.",
  "You don't have to feel the same every day, that's normal.",
  'Buddy, looking back at a week of moods can sometimes tell you a lot.',
  'If today was good, that\'s worth writing down too.',
  'Tracking your feelings is a small act of care for yourself.',
];

const moodQuotesEs = <String>[
  '¿Cómo te sientes hoy, amigo?',
  'Amigo, si tuvieras que resumir el día de hoy en un emoji, ¿cuál sería?',
  'Escribir tu estado de ánimo es el primer paso para entenderlo.',
  'Está bien si hoy fue un mal día — mañana es otro día.',
  'Amigo, no ignores tus emociones — regístralas, aunque sea con una pequeña marca.',
  'No olvides preguntarte hoy cómo te sientes.',
  'No tienes que sentirte igual todos los días, es normal.',
  'Amigo, mirar el ánimo de toda una semana a veces dice mucho.',
  'Si hoy te sentiste bien, también vale la pena anotarlo.',
  'Hacer seguimiento de tus emociones es una forma de cuidarte.',
];

/// Kullanıcının seçtiği dile (bkz. `LocaleProvider`) göre söz havuzu —
/// desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
List<String> moodQuotesForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => moodQuotesEn,
  'es' => moodQuotesEs,
  _ => moodQuotesTr,
};
