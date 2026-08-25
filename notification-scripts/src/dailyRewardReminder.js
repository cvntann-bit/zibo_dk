// 3. GÜNLÜK ÖDÜL HATIRLATMASI — SAATTE BİR çalışan bir GitHub Actions
// çalıştırması, her kullanıcının KENDİ yerel saati 15:00 olduğunda gönderir
// (bkz. .github/workflows/daily-reward-reminder.yml, TARGET_LOCAL_HOURS
// aşağıda).
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
//
// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu (Kolombiya'daki bir test
// kullanıcısı sabah 4'te bildirim aldı): gönderim artık sabit Europe/Istanbul
// saatine göre DEĞİL, `userLocalHour`/`userDateKey` (bkz. common.js) ile
// kullanıcının KENDİ saat dilimine göre yapılıyor.

const { db, fetchAllUsers, sendToUser, getLanguageCode, userLocalHour, userDateKey } = require('./common');
const { daily_reward: DAILY_REWARD_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [15];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users.filter((u) => TARGET_LOCAL_HOURS.includes(userLocalHour(u, now)));
  console.log(`${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte.`);

  await Promise.all(
    eligible.map(async (user) => {
      const dateKey = userDateKey(user, now);
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
