// 3. GÜNLÜK ÖDÜL HATIRLATMASI — her gün 15:00 (Europe/Istanbul) tetiklenir
// (bkz. .github/workflows/daily-reward-reminder.yml).
//
// BİLİNEN SINIRLAMA: Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
// mi" alanı YOK (bkz. CLAUDE.md "Şans Çarkı" — günlük çevirme sınırı
// bilinçli olarak yok), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
// (dailyRewards) claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.

const { db, istanbulDateKey, fetchAllUsers, sendToUser } = require('./common');

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
      await sendToUser(
        user,
        'daily_reward',
        'Zibo',
        'Bugünün ödülünü almadın! Günlük Giriş Ödülü seni bekliyor.',
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
