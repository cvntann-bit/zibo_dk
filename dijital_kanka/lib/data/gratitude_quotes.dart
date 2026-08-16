import 'package:flutter/material.dart';

// Şükran Günlüğü sayfasında Zibo'nun konuşma balonunda otomatik olarak dönen
// sözlerin havuzu (bkz. dream_quotes.dart'taki aynı yaklaşım — gerçek bir
// içerik kaynağı hazır olana kadar uygulama içinde sabit). Üç dilde de
// samimi tonu koruyan, birebir değil doğal çeviriler.
const gratitudeQuotesTr = <String>[
  'Bugün küçük bir şey bile olsa, şükredecek bir şey bulabilirsin.',
  'Kanka mutluluk büyük şeylerde değil, fark ettiğin küçük anlarda.',
  'Bugün sana iyi gelen üç şeyi düşün, yazınca daha gerçek olur.',
  'Şükretmek, elindekini görmenin en kolay yolu.',
  'Kanka bugün kime/neye minnettarsın? Bir düşün bakalım.',
  'Küçük şükranlar zamanla büyük bir huzur biriktirir.',
  'Bugün zor geçse bile, içinde iyi bir an vardı mutlaka.',
  'Kanka şükran günlüğü, günü tersine çevirmenin küçük bir yolu.',
  'Bugün seni gülümseten bir şeyi unutmadan yaz.',
  'Elindekine bakmak, eksiğini unutturur bazen.',
];

const gratitudeQuotesEn = <String>[
  'Even something small today can be worth being grateful for.',
  "Buddy, happiness isn't in the big things — it's in the little moments you notice.",
  'Think of three things that felt good today — writing them down makes them real.',
  'Gratitude is the easiest way to see what you already have.',
  'Buddy, who or what are you grateful for today? Take a moment.',
  'Small gratitudes add up to a big peace over time.',
  'Even on a hard day, there was surely a good moment in there.',
  'Buddy, a gratitude journal is a small way to flip the day around.',
  "Write down something that made you smile today, before you forget.",
  'Looking at what you have sometimes makes you forget what you lack.',
];

const gratitudeQuotesEs = <String>[
  'Aunque sea algo pequeño, hoy seguro encuentras algo por lo que estar agradecido.',
  'Amigo, la felicidad no está en las cosas grandes, está en los pequeños momentos que notas.',
  'Piensa en tres cosas que te sentaron bien hoy — al escribirlas se vuelven más reales.',
  'Agradecer es la forma más fácil de ver lo que ya tienes.',
  'Amigo, ¿a quién o a qué le estás agradecido hoy? Piénsalo un momento.',
  'Los pequeños agradecimientos, con el tiempo, se convierten en una gran calma.',
  'Aunque el día haya sido difícil, seguro hubo un buen momento en algún lugar.',
  'Amigo, un diario de gratitud es una pequeña forma de darle la vuelta al día.',
  'Escribe algo que te hizo sonreír hoy, antes de que se te olvide.',
  'Mirar lo que tienes a veces hace que olvides lo que te falta.',
];

/// Kullanıcının seçtiği dile (bkz. `LocaleProvider`) göre söz havuzu —
/// desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
List<String> gratitudeQuotesForLocale(Locale locale) =>
    switch (locale.languageCode) {
      'en' => gratitudeQuotesEn,
      'es' => gratitudeQuotesEs,
      _ => gratitudeQuotesTr,
    };
