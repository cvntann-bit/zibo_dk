// 1. GÜNLÜK MOTİVASYON — 09:00-10:45 (Europe/Istanbul) penceresinde 15
// dakikada bir tetiklenen bir GitHub Actions cron'u tarafından çağrılır
// (bkz. .github/workflows/daily-motivation.yml). Her kullanıcı kendi
// rastgele dilimine denk geldiğinde günde YALNIZCA BİR KEZ bildirim alır.

const { istanbulDateKey, istanbulMinutesOfDay, pickSlot, fetchAllUsers, sendToUser } = require('./common');

// Ana Sayfa'nın Türkçe söz havuzundan küçük, bağımsız bir örnek (bkz.
// lib/data/zibo_messages.dart — tam havuz 279 söz; burada sunucu tarafında
// tam havuzla senkron tutmak yerine küçük, temsili bir alt küme kullanılıyor).
const MOTIVATION_QUOTES = [
  'Kanka bugün küçük bir adım at, yeter.',
  'Kanka dünden daha güçlüsün, biliyorsun değil mi?',
  'Kanka bugün de yanındayım, hadi başlayalım.',
  'Kanka en zor kısım başlamak, gerisi kolay.',
  'Kanka bugün kendine bir teşekkür borçlusun.',
  'Kanka pes etmek yok, bir adım daha!',
  'Kanka bugün de harika bir gün olacak, inan buna.',
  'Kanka küçük ilerlemeler büyük değişimlere dönüşür.',
];

const SLOT_COUNT = 8; // 09:00-10:45 arası 15 dk'lık 8 dilim.
const WINDOW_START_MINUTE = 9 * 60; // 09:00

async function main() {
  const now = new Date();
  const dateKey = istanbulDateKey(now);
  const minutesOfDay = istanbulMinutesOfDay(now);
  const currentSlot = Math.floor((minutesOfDay - WINDOW_START_MINUTE) / 15);
  if (currentSlot < 0 || currentSlot >= SLOT_COUNT) {
    console.log(`Pencere dışı (minutesOfDay=${minutesOfDay}), gönderim yapılmadı.`);
    return;
  }

  const users = await fetchAllUsers();
  const quote = MOTIVATION_QUOTES[Math.floor(Math.random() * MOTIVATION_QUOTES.length)];
  const eligible = users.filter((u) => pickSlot(u.uid, dateKey, SLOT_COUNT) === currentSlot);
  console.log(`Dilim ${currentSlot}/${SLOT_COUNT} — ${eligible.length}/${users.length} kullanıcı uygun.`);

  await Promise.all(eligible.map((u) => sendToUser(u, 'daily_motivation', 'Zibo', quote)));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
