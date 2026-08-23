// 4 bildirim türünün TR/EN/ES içerikleri — tek yerde. Kullanıcı raporu: bildirimler
// kullanıcının seçtiği arayüz dilinden BAĞIMSIZ, her zaman Türkçe gidiyordu (bkz.
// common.js'teki YENİ `getLanguageCode(uid)` — `users/{uid}/state/languageCode`'u okuyup
// `tr`/`en`/`es` döner). Çeviriler burada BİREBİR çeviri değil, `lib/data/zibo_messages.dart`
// ile AYNI felsefeyle (Zibo'nun sıcak/samimi tonu, "Kanka"/"Buddy"/"Amigo" hitabı) uyarlandı.

// Günlük Motivasyon — Ana Sayfa'nın söz havuzundan küçük, bağımsız bir örnek (bkz.
// dailyMotivation.js'teki asıl yorum — sunucu tarafında tam 279'luk havuzla senkron
// tutulmuyor, küçük temsili bir alt küme kullanılıyor). Üç dil de BİREBİR AYNI sayıda (8) söz
// içeriyor ki `getLanguageCode` hangi dili dönerse dönsün aynı çeşitlilikte seçim yapılabilsin.
const daily_motivation = {
  tr: [
    'Kanka bugün küçük bir adım at, yeter.',
    'Kanka dünden daha güçlüsün, biliyorsun değil mi?',
    'Kanka bugün de yanındayım, hadi başlayalım.',
    'Kanka en zor kısım başlamak, gerisi kolay.',
    'Kanka bugün kendine bir teşekkür borçlusun.',
    'Kanka pes etmek yok, bir adım daha!',
    'Kanka bugün de harika bir gün olacak, inan buna.',
    'Kanka küçük ilerlemeler büyük değişimlere dönüşür.',
  ],
  en: [
    'Buddy, take one small step today, that\'s all it takes.',
    'Buddy, you\'re stronger than yesterday, you know that right?',
    'Buddy, I\'m right here with you today, let\'s get started.',
    'Buddy, starting is the hardest part, the rest is easy.',
    'Buddy, you owe yourself a thank-you today.',
    'Buddy, no giving up, just one more step!',
    'Buddy, today\'s going to be a great day, believe it.',
    'Buddy, small progress adds up to big change.',
  ],
  es: [
    'Amigo, da un pequeño paso hoy, con eso basta.',
    'Amigo, eres más fuerte que ayer, ¿lo sabías?',
    'Amigo, hoy también estoy contigo, empecemos.',
    'Amigo, lo más difícil es empezar, el resto es fácil.',
    'Amigo, hoy te debes un gracias a ti mismo.',
    'Amigo, nada de rendirse, ¡un paso más!',
    'Amigo, hoy va a ser un gran día, créelo.',
    'Amigo, los pequeños avances se convierten en grandes cambios.',
  ],
};

const streak_reminder = {
  tr: 'Serini kaçırmak üzeresin! Bugünü işaretlemeyi unutma kanka.',
  en: 'You\'re about to lose your streak! Don\'t forget to check off today, buddy.',
  es: '¡Estás a punto de perder tu racha! No olvides marcar el día de hoy, amigo.',
};

const daily_reward = {
  tr: 'Bugünün ödülünü almadın! Günlük Giriş Ödülü seni bekliyor.',
  en: 'You haven\'t claimed today\'s reward yet! Your Daily Login Reward is waiting.',
  es: '¡Todavía no reclamaste el premio de hoy! Tu Recompensa Diaria te está esperando.',
};

const re_engagement = {
  tr: 'Seni özledim kanka, bir bakıver ne yaptığına 🧡',
  en: 'I miss you buddy, come take a look at what you\'ve been up to 🧡',
  es: 'Te extraño amigo, ven a ver qué has estado haciendo 🧡',
};

const water_reminder = {
  tr: 'Suyunu içtin mi kanka? Hemen bir bardak iç, hedefine bir adım daha yaklaş! 💧',
  en: 'Did you drink your water, buddy? Have a glass now, one step closer to your goal! 💧',
  es: '¿Tomaste agua, amigo? Bebe un vaso ahora, un paso más cerca de tu meta! 💧',
};

module.exports = {
  daily_motivation,
  streak_reminder,
  daily_reward,
  re_engagement,
  water_reminder,
};
