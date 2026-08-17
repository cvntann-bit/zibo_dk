// 3. GÜNLÜK ÖDÜL HATIRLATMASI — her gün 15:00 (Europe/Istanbul) tetiklenir
// (bkz. .github/workflows/daily-reward-reminder.yml).
//
// BİLİNEN SINIRLAMA: Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
// mi" alanı YOK (bkz. CLAUDE.md "Şans Çarkı" — günlük çevirme sınırı
// bilinçli olarak yok), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
// (dailyRewards) claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.

const { db, istanbulDateKey, fetchAllUsers, sendToUser, getLanguageCode } = require('./common');
const { daily_reward: DAILY_REWARD_BODY } = require('./content');

async function main() {
  const dateKey = istanbulDateKey(new Date());
  const users = await fetchAllUsers();

  await Promise.all(
    users.map(async (user) => {
      const doc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('dailyRewards')
        .get();
      const claimedDates = (doc.exists && doc.data().claimedDates) || [];
      const claimedToday = claimedDates.some((d) => d.startsWith(dateKey));
      if (claimedToday) return;
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'daily_reward',
        'Zibo',
        DAILY_REWARD_BODY[lang] || DAILY_REWARD_BODY.tr,
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
