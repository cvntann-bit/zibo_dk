// 4. GERİ KAZANMA — her gün 11:00 (Europe/Istanbul) tetiklenir (bkz.
// .github/workflows/re-engagement.yml). `lastActiveAt` 2 günden eski olan
// kullanıcılara Zibo'nun sıcak tonunda özel bir mesaj gönderilir.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.

const { fetchAllUsers, sendToUser, getLanguageCode } = require('./common');
const { re_engagement: RE_ENGAGEMENT_BODY } = require('./content');

async function main() {
  const twoDaysAgoMs = Date.now() - 2 * 24 * 60 * 60 * 1000;
  const users = await fetchAllUsers();

  const eligible = users.filter((u) => {
    if (!u.lastActiveAt) return false;
    // Firestore Timestamp (Admin SDK) -> Date.
    const lastActiveMs = u.lastActiveAt.toMillis
      ? u.lastActiveAt.toMillis()
      : new Date(u.lastActiveAt).getTime();
    return lastActiveMs < twoDaysAgoMs;
  });

  await Promise.all(
    eligible.map(async (u) => {
      const lang = await getLanguageCode(u.uid);
      await sendToUser(
        u,
        're_engagement',
        'Zibo',
        RE_ENGAGEMENT_BODY[lang] || RE_ENGAGEMENT_BODY.tr,
      );
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
