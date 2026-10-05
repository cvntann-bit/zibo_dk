import 'package:flutter/material.dart';

// Odak Sayacı sayfasında Zibo'nun konuşma balonunda otomatik olarak dönen
// sözlerin havuzu (bkz. gratitude_quotes.dart/water_quotes.dart'taki aynı
// yaklaşım). Üç dilde de samimi tonu koruyan, birebir değil doğal çeviriler —
// ilerlemeye/seçili moda tepki VERMİYOR, her zaman jenerik.
const focusQuotesTr = <String>[
  'Kanka 25 dakika, tek bir işe. Hazır mısın?',
  'Telefonu bir kenara bırak, şimdi sıra odaklanmada.',
  'Kanka küçük bir süre bile büyük bir işi bitirebilir.',
  'Tek seferde tek iş — bugün onu dene.',
  'Kanka dikkatini dağıtan her şeyi bir kenara koy, başlayalım.',
  'Bir sayaç kur, gerisini zihnine bırak.',
  'Kanka bugün neye gerçekten odaklanman gerekiyor?',
  'Kısa bir odaklanma bile günü değiştirebilir.',
  'Kanka şimdi tam zamanı, ertelemeden başla.',
  'Zihnini tek bir şeye ver, gerisi bekleyebilir.',
  'Kanka en zor kısım başlamak, gerisi kolay geliyor.',
  'Bir seansta ne kadar ilerleyebileceğine şaşıracaksın.',
  'Kanka bildirimleri kapat, sadece işine bak.',
  'Odaklanmak bir kas gibi, her seansta güçleniyor.',
  'Kanka bugün kendine sessiz bir zaman ayır.',
  'Sayaç çalışırken tek görevin o an elindeki iş.',
  'Kanka küçük adımlar büyük işleri bitirir.',
  'Şimdi başla, mükemmel anı beklemene gerek yok.',
  'Kanka odaklandığın her dakika sana kalıyor.',
  'Bir görev, tam dikkat — bugünkü hedefin bu olsun.',
];

const focusQuotesEn = <String>[
  'Buddy, 25 minutes, one task. Ready?',
  'Set the phone aside — it\'s focus time now.',
  'Buddy, even a short stretch of time can finish a big job.',
  'One task at a time — give it a try today.',
  'Buddy, clear away the distractions and let\'s begin.',
  'Set a timer and let your mind do the rest.',
  'Buddy, what actually needs your focus today?',
  'Even a short focus session can change your day.',
  'Buddy, now\'s the time — start without putting it off.',
  'Give your mind to one thing, everything else can wait.',
  'Buddy, starting is the hardest part, the rest gets easier.',
  'You\'ll be surprised how far one session can take you.',
  'Buddy, turn off the notifications and just work.',
  'Focus is like a muscle — it gets stronger every session.',
  'Buddy, carve out some quiet time for yourself today.',
  'While the timer runs, your only job is what\'s in front of you.',
  'Buddy, small steps finish big tasks.',
  'Start now, you don\'t need the perfect moment.',
  'Buddy, every minute you focus stays with you.',
  'One task, full attention — make that today\'s goal.',
];

const focusQuotesEs = <String>[
  'Amigo, 25 minutos, una sola tarea. ¿Listo?',
  'Deja el teléfono a un lado, ahora toca concentrarse.',
  'Amigo, hasta un rato corto puede terminar un trabajo grande.',
  'Una tarea a la vez, pruébalo hoy.',
  'Amigo, aparta todo lo que te distraiga y empecemos.',
  'Pon un temporizador y deja que tu mente haga el resto.',
  'Amigo, ¿en qué necesitas enfocarte de verdad hoy?',
  'Incluso una sesión corta de enfoque puede cambiar tu día.',
  'Amigo, ahora es el momento, empieza sin postergarlo.',
  'Dale tu atención a una sola cosa, lo demás puede esperar.',
  'Amigo, empezar es lo más difícil, después se hace fácil.',
  'Te sorprenderá cuánto puedes avanzar en una sola sesión.',
  'Amigo, apaga las notificaciones y concéntrate en tu trabajo.',
  'El enfoque es como un músculo, se fortalece con cada sesión.',
  'Amigo, resérvate hoy un momento de calma.',
  'Mientras corre el temporizador, tu única tarea es la que tienes delante.',
  'Amigo, los pasos pequeños terminan trabajos grandes.',
  'Empieza ahora, no necesitas el momento perfecto.',
  'Amigo, cada minuto que te enfocas se queda contigo.',
  'Una tarea, atención completa — que ese sea tu objetivo de hoy.',
];

/// Kullanıcının seçtiği dile (bkz. `LocaleProvider`) göre söz havuzu —
/// desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
List<String> focusQuotesForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => focusQuotesEn,
  'es' => focusQuotesEs,
  _ => focusQuotesTr,
};
