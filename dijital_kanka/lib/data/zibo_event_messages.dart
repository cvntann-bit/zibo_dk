import 'package:flutter/material.dart';

import '../utils/zibo_event_signal.dart';

/// Olay tetiklemeli özel Zibo mesajları — bkz. CLAUDE.md "Olay Tetiklemeli
/// Özel Mesajlar" bölümü. `motivation_pools.dart`'ın AYNI `xTr/En/Es` +
/// per-pool Türkçe geri düşüş deseni. **2026 güncellemesi — EN/ES havuzları
/// dolduruldu** (tester geri bildirimi: İspanyolca arayüzde olay mesajları
/// Türkçe beliriyordu). `eventMessagesForLocale` yine de her havuzu AYRI
/// AYRI kontrol edip boşsa Türkçe'ye düşüyor — ileride yeni bir olay türü
/// eklenip yalnızca TR'si yazılırsa güvenli kalsın diye.
///
/// **Bu havuzlar normal zaman/ruh hali havuzlarından TAMAMEN AYRI** —
/// `motivation_quote_selector.dart`'ın ağırlıklı seçimine hiç girmiyorlar,
/// yalnızca [pendingZiboEvent] BİR OLAY taşıdığında `HomeScreen.
/// _pickAndSetQuote()` tarafından DOĞRUDAN (rastgele ağırlıklandırma
/// ATLANARAK) kullanılıyorlar — bkz. o metodun dokümantasyonu.
const _goalCycleCompletedTr = <String>[
  'Yaptın! 7 gün boyunca hiç vazgeçmedin, bugün gerçekten gurur duyman gereken bir gün.',
  'Bir haftalık hedefini tamamladın — bu küçük bir şey değil, sen bunu başardın!',
  '7/7! Söz verdiğin şeyi tuttun, kendine bunu hatırlat.',
  'Bugün seninle çok gurur duyuyorum, bu döngüyü sonuna kadar taşıdın.',
  'Bir hedefi baştan sona tamamlamak cesaret ister — sen bunu gösterdin.',
  'Tebrikler! Bu hafta attığın her adım seni buraya getirdi.',
  'Vazgeçmeden 7 gün — bu senin disiplinin, unutma.',
  'Bugün kutlama günü! Hedefini tamamladın, kendine bir armağan hak ettin.',
  'Sen yaptın! Şimdi bu başarıyı bir sonrakine taşıma sırası.',
  'Bir döngüyü tamamlamak bile büyük bir adım, sen bunu yaptın Kanka.',
  'Bugün geriye dönüp bak: yedi gün önce başladığın yerden çok ileridesin.',
  'Harikaydın! Bu hedefi tamamladığın için gerçekten mutluyum.',
];

const _streakBrokenTr = <String>[
  'Bir gün kaçırmışsın, olsun — önemli olan pes etmemek. Bugün yeniden başlayalım.',
  'Herkesin böyle günleri olur, sen de istisna değilsin. Yarın diye bir şey var.',
  'Döngü sıfırlandı ama sen sıfırlanmadın — bugün yeni bir başlangıç.',
  'Bir gün atlamak seni tanımlamaz, devam etmen tanımlar.',
  'Kaçırdığın gün geçti, şimdi elindeki tek şey bugün — onu değerlendirelim mi?',
  'Kendine sert davranma, bir aksama her zaman toparlanabilir.',
  'Bazen hayat araya girer, bu normal. Bugün tekrar adım atmaya ne dersin?',
  'Bir düşüş bitiş değil, yalnızca kısa bir mola. Devam edelim.',
  'Seni suçlamıyorum Kanka, sadece hatırlatıyorum: yeniden başlamak her zaman mümkün.',
  'Döngü yeniden başladı, bu da yeni bir şans demek. Hazır mısın?',
  'Bir gün kaçırdın diye tüm çabaların boşa gitmedi, unutma.',
  'Bugün sıfırdan başlıyoruz ama sıfırdan güçlü bir şekilde.',
];

const _costumeOrThemeUnlockedTr = <String>[
  'Yeni bir görünüm kazandın! Nasıl duruyor, beğendin mi?',
  'Tebrikler, dolabına yeni bir parça eklendi!',
  'Bunu hak ettin — yeni stilinin tadını çıkar.',
  'Yepyeni bir Zibo karşında! Bu görünümü sana yakıştırdım.',
  'Yeni bir şey açtın, bu küçük bir kutlamayı hak ediyor.',
  'İşte bu! Koleksiyonun büyümeye devam ediyor.',
  'Yeni tarzını beğendim, sen ne düşünüyorsun?',
  'Bunu kazanmak için emek verdin, şimdi tadını çıkarma sırası.',
];

const _loginStreakBonusTr = <String>[
  'Vay be! Yedi gün boyunca beni hiç yalnız bırakmadın, bu gerçekten özel!',
  'Bugün büyük gün! Seri bonusun tam sana göre, harikasın!',
  'Bu ne kadar güzel bir seri! Seninle gurur duyuyorum, kutlamayı hak ettin!',
  'İnanılmazsın! Bu tempo ile devam edersen durduramayız seni!',
  'Büyük bonus, büyük başarı! Bugün gerçekten senin günün Kanka!',
  'Vay canına, bunu başardın! Seriyi bu şekilde sürdürmek kolay değil!',
  'Bugün kutlama zamanı! Bu seriyi hak ederek kazandın!',
  'Sen bir harikasın! Bu bonus tamamen senin emeğinin karşılığı!',
];

// İngilizce/İspanyolca uyarlamalar — `motivation_pools.dart`'ın AYNI
// felsefesi (kelimesi kelimesine çeviri değil, Zibo'nun sıcak/samimi tonunu
// o dilde doğal duracak şekilde koruyan bir uyarlama; 'Kanka' → 'buddy' /
// 'amigo'). TR havuzlarıyla BİREBİR aynı uzunlukta.
const _goalCycleCompletedEn = <String>[
  "You did it! Seven days straight without quitting — today is a day to be genuinely proud.",
  "You finished your week-long goal — that's no small thing, you made it happen!",
  "7/7! You kept the promise you made to yourself, remember that.",
  "I'm so proud of you today, you carried this cycle all the way through.",
  "Finishing a goal from start to end takes courage — and you showed it.",
  "Congrats! Every step you took this week brought you right here.",
  "Seven days without giving up — that's your discipline, don't forget it.",
  "Today's a day to celebrate! You finished your goal, you've earned a treat.",
  "You did it! Now it's time to carry that win into the next one.",
  "Finishing even one cycle is a big step, and you did it, buddy.",
  "Look back for a second: you're way ahead of where you started seven days ago.",
  "You were amazing! I'm genuinely happy you finished this goal.",
];
const _streakBrokenEn = <String>[
  "You missed a day, it's okay — what matters is not giving up. Let's start again today.",
  "Everyone has days like this, you're no exception. There's always tomorrow.",
  "The cycle reset, but you didn't — today is a fresh start.",
  "Skipping one day doesn't define you, continuing does.",
  "The day you missed is gone; all you've got now is today — shall we make it count?",
  "Don't be hard on yourself, a slip can always be recovered from.",
  "Sometimes life gets in the way, that's normal. How about taking a step again today?",
  "One stumble isn't the end, just a short break. Let's keep going.",
  "I'm not blaming you, buddy, just reminding you: starting over is always possible.",
  "The cycle started over, which means a new chance. Ready?",
  "Missing one day didn't waste all your effort, remember that.",
  "Today we start from zero, but from a strong zero.",
];
const _costumeOrThemeUnlockedEn = <String>[
  "You've got a new look! How does it feel, do you like it?",
  "Congrats, a new piece just landed in your closet!",
  "You earned this — enjoy your new style.",
  "A brand-new Zibo, right here! This look really suits you.",
  "You unlocked something new, and that deserves a little celebration.",
  "There it is! Your collection keeps growing.",
  "I like your new style, what do you think?",
  "You put in the work to earn this, now it's time to enjoy it.",
];
const _loginStreakBonusEn = <String>[
  "Wow! Seven days and you never left me alone — that's really special!",
  "Today's the big day! Your streak bonus is all yours, you're amazing!",
  "What a lovely streak! I'm proud of you, you've earned this celebration!",
  "You're incredible! Keep this pace up and there's no stopping you!",
  "Big bonus, big achievement! Today really is your day, buddy!",
  "Wow, you pulled it off! Keeping a streak going like this isn't easy!",
  "It's celebration time! You earned this streak fair and square!",
  "You're a marvel! This bonus is entirely the reward for your effort!",
];

const _goalCycleCompletedEs = <String>[
  "¡Lo lograste! Siete días seguidos sin rendirte — hoy es un día para estar de verdad orgulloso.",
  "Terminaste tu meta de una semana — eso no es poca cosa, ¡tú lo conseguiste!",
  "¡7/7! Cumpliste la promesa que te hiciste, recuérdalo.",
  "Estoy muy orgulloso de ti hoy, llevaste este ciclo hasta el final.",
  "Terminar una meta de principio a fin requiere valor — y tú lo demostraste.",
  "¡Felicidades! Cada paso que diste esta semana te trajo justo hasta aquí.",
  "Siete días sin rendirte — esa es tu disciplina, no lo olvides.",
  "¡Hoy es día de celebrar! Terminaste tu meta, te ganaste un premio.",
  "¡Lo hiciste! Ahora toca llevar ese logro al siguiente.",
  "Terminar aunque sea un ciclo es un gran paso, y tú lo hiciste, amigo.",
  "Mira atrás un momento: estás muy por delante de donde empezaste hace siete días.",
  "¡Estuviste increíble! De verdad me alegra que hayas terminado esta meta.",
];
const _streakBrokenEs = <String>[
  "Te saltaste un día, no pasa nada — lo importante es no rendirse. Empecemos de nuevo hoy.",
  "Todos tienen días así, tú no eres la excepción. Siempre hay un mañana.",
  "El ciclo se reinició, pero tú no — hoy es un nuevo comienzo.",
  "Saltarte un día no te define, seguir adelante sí.",
  "El día que perdiste ya pasó; ahora solo tienes hoy — ¿lo aprovechamos?",
  "No seas duro contigo, de un tropiezo siempre se puede recuperar.",
  "A veces la vida se cruza, es normal. ¿Qué tal si vuelves a dar un paso hoy?",
  "Una caída no es el final, solo una pausa corta. Sigamos.",
  "No te estoy culpando, amigo, solo te recuerdo: siempre se puede volver a empezar.",
  "El ciclo empezó de nuevo, y eso significa una nueva oportunidad. ¿Listo?",
  "Saltarte un día no echó a perder todo tu esfuerzo, recuérdalo.",
  "Hoy empezamos desde cero, pero desde un cero fuerte.",
];
const _costumeOrThemeUnlockedEs = <String>[
  "¡Tienes un nuevo look! ¿Cómo se siente, te gusta?",
  "¡Felicidades, acaba de llegar una nueva pieza a tu armario!",
  "Te lo ganaste — disfruta tu nuevo estilo.",
  "¡Un Zibo totalmente nuevo, aquí mismo! Este look te queda genial.",
  "Desbloqueaste algo nuevo, y eso merece una pequeña celebración.",
  "¡Ahí está! Tu colección sigue creciendo.",
  "Me gusta tu nuevo estilo, ¿tú qué opinas?",
  "Le pusiste esfuerzo para ganarte esto, ahora toca disfrutarlo.",
];
const _loginStreakBonusEs = <String>[
  "¡Guau! Siete días y nunca me dejaste solo — ¡eso es muy especial!",
  "¡Hoy es el gran día! Tu bono de racha es todo tuyo, ¡eres increíble!",
  "¡Qué racha tan bonita! Estoy orgulloso de ti, ¡te ganaste esta celebración!",
  "¡Eres increíble! Si sigues a este ritmo, no habrá quien te pare!",
  "¡Gran bono, gran logro! Hoy de verdad es tu día, ¡amigo!",
  "¡Guau, lo lograste! Mantener una racha así no es fácil!",
  "¡Es hora de celebrar! ¡Te ganaste esta racha con todo merecimiento!",
  "¡Eres una maravilla! ¡Este bono es completamente la recompensa de tu esfuerzo!",
];

/// [type] olayı için [locale]'e göre söz havuzunu döner — havuz o dilde
/// boşsa (bkz. dosya dokümantasyonu) Türkçe'ye düşer.
List<String> eventMessagesForLocale(ZiboEventType type, Locale locale) {
  final trList = _poolFor(type, 'tr');
  final localizedList = _poolFor(type, locale.languageCode);
  return localizedList.isEmpty ? trList : localizedList;
}

List<String> _poolFor(ZiboEventType type, String languageCode) {
  return switch (languageCode) {
    'en' => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedEn,
      ZiboEventType.streakBroken => _streakBrokenEn,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedEn,
      ZiboEventType.loginStreakBonus => _loginStreakBonusEn,
    },
    'es' => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedEs,
      ZiboEventType.streakBroken => _streakBrokenEs,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedEs,
      ZiboEventType.loginStreakBonus => _loginStreakBonusEs,
    },
    _ => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedTr,
      ZiboEventType.streakBroken => _streakBrokenTr,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedTr,
      ZiboEventType.loginStreakBonus => _loginStreakBonusTr,
    },
  };
}
